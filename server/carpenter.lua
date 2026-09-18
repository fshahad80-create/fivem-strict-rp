--[[
    fivem-strict-rp :: server/carpenter.lua
    النجار العميق — تصنيع · صناديق · طاولات · أكشاك · تصاريح.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local C = Carpenter
local S = Supply

local Cooldown = {}
local Levels   = {}
local Permits  = {}
local Placed   = {}
local function log(msg) print(('[fivem-strict-rp][carpenter] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_carpenter` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
        `level` INT NOT NULL DEFAULT 1, `xp` BIGINT NOT NULL DEFAULT 0,
        `permits` LONGTEXT DEFAULT NULL, `placed` LONGTEXT DEFAULT NULL,
        `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadCarp(citizenid, cb)
    MySQL.query('SELECT * FROM srp_carpenter WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        Levels[citizenid]  = { level = r and r.level or 1, xp = r and r.xp or 0 }
        Permits[citizenid] = r and (json.decode(r.permits or '{}') or {}) or {}
        Placed[citizenid]  = r and (json.decode(r.placed or '[]') or {}) or []
        if cb then cb() end
    end)
end

local function persistCarp(citizenid)
    MySQL.query([[INSERT INTO srp_carpenter (citizenid, level, xp, permits, placed) VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level), xp = VALUES(xp), permits = VALUES(permits), placed = VALUES(placed)]],
        { citizenid, Levels[citizenid] and Levels[citizenid].level or 1, Levels[citizenid] and Levels[citizenid].xp or 0,
          json.encode(Permits[citizenid] or {}), json.encode(Placed[citizenid] or {}) })
end

local function isQbItem(item)
    if S.Settings.inventoryMode == 'internal' then return false end
    if S.Settings.inventoryMode == 'qbcore' then return true end
    return QBCore.Shared.Items[item] ~= nil
end
local function getQty(Player, item)
    if isQbItem(item) then
        local it = Player.Functions.GetItemByName(item)
        return it and it.amount or 0
    end
    return 0
end
local function giveItem(src, item, qty) TriggerEvent('srp:supply:giveItem', src, item, qty) end
local function takeItem(Player, item, qty)
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty) end
end

RegisterNetEvent('srp:carpenter:craft', function(recipeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.name ~= 'carpenter' then
        TriggerClientEvent('QBCore:Notify', src, 'هذه وظيفة النجار.', 'error') return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    local rec = C.Recipes[recipeKey]
    if not rec then return end
    if Cooldown[src] and (os.time() - Cooldown[src]) < C.Settings.craftCooldown then
        TriggerClientEvent('QBCore:Notify', src, 'انتظر قليلاً.', 'error') return
    end
    local cid = Player.PlayerData.citizenid
    if rec.needsPermit then
        local permit = Permits[cid] and Permits[cid].stall
        if not permit or permit < os.time() then
            TriggerClientEvent('QBCore:Notify', src, C.Messages.noPermit, 'error') return
        end
    end
    for item, need in pairs(rec.inputs) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, C.Messages.noMaterials, 'error') return
        end
    end
    Cooldown[src] = os.time()
    for item, need in pairs(rec.inputs) do takeItem(Player, item, need) end
    TriggerClientEvent('QBCore:Notify', src, ('جاري التصنيع... (%s ثانية)'):format(rec.time), 'inform')
    SetTimeout(rec.time * 1000, function()
        giveItem(src, rec.output, rec.qty)
        Levels[cid] = Levels[cid] or { level = 1, xp = 0 }
        Levels[cid].xp = Levels[cid].xp + C.Settings.craftXpPerItem
        local newLevel = math.min(C.Settings.maxLevel, 1 + math.floor(Levels[cid].xp / 400))
        if newLevel > Levels[cid].level then
            Levels[cid].level = newLevel
            TriggerClientEvent('QBCore:Notify', src, ('مستوى النجار: %s'):format(newLevel), 'success')
        end
        persistCarp(cid)
        TriggerClientEvent('QBCore:Notify', src, ('صنعت %s × %s'):format(rec.label, rec.qty), 'success')
    end)
end)

RegisterNetEvent('srp:carpenter:place', function(itemKey, x, y, z, rot)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if getQty(Player, itemKey) < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذا العنصر.', 'error') return
    end
    takeItem(Player, itemKey, 1)
    Placed[cid] = Placed[cid] or {}
    table.insert(Placed[cid], { type = itemKey, x = x, y = y, z = z, rot = rot or 0.0 })
    persistCarp(cid)
    TriggerClientEvent('QBCore:Notify', src, ('وُضع %s'):format(itemKey), 'success')
    TriggerClientEvent('srp:carpenter:spawnPlaced', src, itemKey, x, y, z, rot)
end)

RegisterNetEvent('srp:carpenter:buyPermit', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local permit = C.Permits.stallPermit
    if Player.Functions.GetMoney('bank') < permit.cost then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك المال الكافي.', 'error') return
    end
    Player.Functions.RemoveMoney('bank', permit.cost, 'srp-carpenter-permit')
    local cid = Player.PlayerData.citizenid
    Permits[cid] = Permits[cid] or {}
    Permits[cid].stall = os.time() + (permit.durationDays * 86400)
    persistCarp(cid)
    TriggerClientEvent('QBCore:Notify', src, ('صدر %s (%s يوم)'):format(permit.label, permit.durationDays), 'success')
end)

RegisterNetEvent('srp:carpenter:sell', function(itemKey, qty)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local mats = C.Materials[itemKey]
    if not mats then return end
    qty = getQty(Player, itemKey)
    if qty < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه الكمية.', 'error') return
    end
    local gross = mats.value * qty
    local net = gross - math.floor(gross * 0.08)
    takeItem(Player, itemKey, qty)
    Player.Functions.AddMoney('bank', net, 'srp-carpenter-sell')
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s × %s بـ $%s'):format(mats.label, qty, net), 'success')
end)

local function sendData(src, cid)
    TriggerClientEvent('srp:carpenter:show', src, Levels[cid] or { level = 1, xp = 0 }, C.Recipes, C.Materials, Permits[cid] or {}, Placed[cid] or {})
end

RegisterNetEvent('srp:carpenter:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if not Levels[cid] then loadCarp(cid, function() sendData(src, cid) end) else sendData(src, cid) end
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadCarp(Player.PlayerData.citizenid, function() end)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل النجار العميق.')
end)
