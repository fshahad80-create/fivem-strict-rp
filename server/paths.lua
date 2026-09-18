--[[
    fivem-strict-rp :: server/paths.lua
    شجرة المسارات — خبرة · مستويات · نقاط · عقود · شارات · ألقاب.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local P = Paths

local Data = {}
local function log(msg) print(('[fivem-strict-rp][paths] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_paths` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `xp` TEXT DEFAULT NULL,
        `points` INT NOT NULL DEFAULT 0, `nodes` TEXT DEFAULT NULL, `badges` TEXT DEFAULT NULL,
        `title` VARCHAR(48) DEFAULT NULL, `last_daily` INT NOT NULL DEFAULT 0,
        `last_weekly` INT NOT NULL DEFAULT 0, `last_monthly` INT NOT NULL DEFAULT 0,
        `last_respec` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function blank()
    return { xp = {}, points = 0, nodes = {}, badges = {}, title = nil,
             lastDaily = 0, lastWeekly = 0, lastMonthly = 0, lastRespec = 0 }
end

local function load(citizenid, cb)
    MySQL.query('SELECT * FROM srp_paths WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        if not r then Data[citizenid] = blank()
        else
            Data[citizenid] = {
                xp = json.decode(r.xp or '{}') or {}, points = r.points or 0,
                nodes = json.decode(r.nodes or '{}') or {}, badges = json.decode(r.badges or '[]') or [],
                title = r.title, lastDaily = r.last_daily or 0, lastWeekly = r.last_weekly or 0,
                lastMonthly = r.last_monthly or 0, lastRespec = r.last_respec or 0,
            }
        end
        if cb then cb(Data[citizenid]) end
    end)
end

local function persist(citizenid)
    local d = Data[citizenid]
    if not d then return end
    MySQL.query([[INSERT INTO srp_paths
        (citizenid, xp, points, nodes, badges, title, last_daily, last_weekly, last_monthly, last_respec)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE xp = VALUES(xp), points = VALUES(points), nodes = VALUES(nodes),
        badges = VALUES(badges), title = VALUES(title), last_daily = VALUES(last_daily),
        last_weekly = VALUES(last_weekly), last_monthly = VALUES(last_monthly), last_respec = VALUES(last_respec)]],
        { citizenid, json.encode(d.xp), d.points, json.encode(d.nodes), json.encode(d.badges),
          d.title, d.lastDaily, d.lastWeekly, d.lastMonthly, d.lastRespec })
end

local function levelFromXp(xp)
    local lvl, need, acc = 0, 500, 0
    while xp >= acc + need and lvl < P.Settings.maxLevelPerSpec do
        acc = acc + need; lvl = lvl + 1; need = math.floor(need * 1.25)
    end
    return lvl, xp - acc, need
end

local function addXp(citizenid, spec, amount, src)
    local d = Data[citizenid]
    if not d or not amount or amount <= 0 then return end
    local oldLvl = levelFromXp(d.xp[spec] or 0)
    d.xp[spec] = (d.xp[spec] or 0) + amount
    local newLvl = levelFromXp(d.xp[spec])
    local pointsEarned = math.floor(d.xp[spec] / P.Settings.xpPerPoint) -
                         math.floor((d.xp[spec] - amount) / P.Settings.xpPerPoint)
    if pointsEarned > 0 then
        d.points = d.points + pointsEarned
        if src then TriggerClientEvent('QBCore:Notify', src, ('نقطة مسار جديدة! (المجموع: %s)'):format(d.points), 'success') end
    end
    if newLvl > oldLvl and src then
        TriggerClientEvent('QBCore:Notify', src, ('مستوى جديد في %s: %s'):format(spec, newLvl), 'success')
    end
    persist(citizenid)
end

local function grantTimedPoints(citizenid)
    local d = Data[citizenid]
    if not d then return end
    local now = os.time()
    if now - d.lastDaily > 86400 then d.points = d.points + P.Settings.dailyPoints; d.lastDaily = now end
    if now - d.lastWeekly > 604800 then d.points = d.points + P.Settings.weeklyPoints; d.lastWeekly = now end
    if now - d.lastMonthly > 2592000 then d.points = d.points + P.Settings.monthlyPoints; d.lastMonthly = now end
    persist(citizenid)
end

RegisterNetEvent('srp:paths:unlockNode', function(spec, nodeIdx)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local d = Data[cid]
    if not d then return end
    local nodes = P.Nodes[spec]
    if not nodes or not nodes[nodeIdx] then return end
    local node = nodes[nodeIdx]
    if d.nodes[spec] and d.nodes[spec][nodeIdx] then
        TriggerClientEvent('QBCore:Notify', src, 'هذه العقدة مفتوحة مسبقاً.', 'inform') return
    end
    local lvl = levelFromXp(d.xp[spec] or 0)
    if lvl < node.level then
        TriggerClientEvent('QBCore:Notify', src, ('تحتاج مستوى %s في %s.'):format(node.level, spec), 'error') return
    end
    if d.points < node.cost then
        TriggerClientEvent('QBCore:Notify', src, P.Messages.notEnoughPoints, 'error') return
    end
    d.points = d.points - node.cost
    d.nodes[spec] = d.nodes[spec] or {}
    d.nodes[spec][nodeIdx] = true
    if node.badge then
        table.insert(d.badges, node.badge)
        TriggerClientEvent('QBCore:Notify', src, ('شارة إتقان: %s'):format(node.label), 'success')
    end
    persist(cid)
    TriggerClientEvent('QBCore:Notify', src, ('فُتحت ميزة: %s'):format(node.label), 'success')
end)

RegisterNetEvent('srp:paths:equipTitle', function(sectorKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local d = Data[cid]
    if not d then return end
    local sector = P.Sectors[sectorKey]
    if not sector then return end
    local mastered = false
    for specKey in pairs(sector.specs) do
        local nodes = P.Nodes[specKey] or {}
        local last = nodes[#nodes]
        if last and d.nodes[specKey] and d.nodes[specKey][#nodes] then mastered = true break end
    end
    if not mastered then
        TriggerClientEvent('QBCore:Notify', src, 'تحتاج إتقان تخصص في هذا القطاع أولاً.', 'error') return
    end
    d.title = sector.title
    persist(cid)
    TriggerClientEvent('QBCore:Notify', src, ('لقبك: %s'):format(sector.title), 'success')
end)

RegisterNetEvent('srp:paths:respec', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local d = Data[cid]
    if not d then return end
    local cooldown = P.Settings.respecCooldownDays * 86400
    if os.time() - d.lastRespec < cooldown then
        local days = math.ceil((cooldown - (os.time() - d.lastRespec)) / 86400)
        TriggerClientEvent('QBCore:Notify', src, ('إعادة التوزيع متاحة بعد %s يوم.'):format(days), 'error') return
    end
    local refund = 0
    for spec, nodes in pairs(d.nodes) do
        for idx in pairs(nodes) do
            local node = (P.Nodes[spec] or {})[idx]
            if node then refund = refund + node.cost end
        end
    end
    d.points = d.points + refund
    d.nodes = {}
    d.lastRespec = os.time()
    persist(cid)
    TriggerClientEvent('QBCore:Notify', src, ('تم إعادة توزيع نقاطك (+%s نقطة).'):format(refund), 'success')
end)

exports('getBonus', function(citizenid, bonusType)
    local d = Data[citizenid]
    if not d then return 0 end
    local total = 0
    for spec, nodes in pairs(d.nodes) do
        local nodeList = P.Nodes[spec] or {}
        for idx in pairs(nodes) do
            local node = nodeList[idx]
            if node and node.bonus and node.bonus.type == bonusType then total = total + node.bonus.value end
        end
    end
    return total
end)

exports('hasBadge', function(citizenid, badge)
    local d = Data[citizenid]
    if not d then return false end
    for _, b in ipairs(d.badges) do if b == badge then return true end end
    return false
end)

RegisterNetEvent('srp:paths:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if not Data[cid] then
        load(cid, function(d)
            grantTimedPoints(cid)
            TriggerClientEvent('srp:paths:show', src, d, P.Sectors, P.Nodes)
        end)
        return
    end
    grantTimedPoints(cid)
    TriggerClientEvent('srp:paths:show', src, Data[cid], P.Sectors, P.Nodes)
end)

RegisterNetEvent('srp:paths:addXp', function(spec, amount)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    addXp(Player.PlayerData.citizenid, spec, amount, src)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    load(Player.PlayerData.citizenid, function() end)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل شجرة المسارات.')
end)
