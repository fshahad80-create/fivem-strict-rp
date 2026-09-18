--[[
    fivem-strict-rp :: server/penalties.lua
    منطق نظام العقوبات التلقائية — QBCore
]]

local QBCore = exports['qb-core']:GetCoreObject()
local P = Penalties

local PlayerPoints  = {}
local PlayerHistory = {}
local WantedList    = {}
local PointsTick    = {}

local function log(msg)
    print(('[fivem-strict-rp][penalties] %s'):format(msg))
end

local function getIdentifier(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function calculateSentence(offenseKey, citizenid, opts)
    opts = opts or {}
    local off = P.Offenses[offenseKey]
    if not off then
        log(('مخالفة غير معروفة: %s'):format(tostring(offenseKey)))
        return nil
    end

    local prevCount = 0
    if PlayerHistory[citizenid] and PlayerHistory[citizenid][offenseKey] then
        prevCount = PlayerHistory[citizenid][offenseKey]
    end

    local multTable = P.Sentencing.escalationMultipliers
    local maxKey = 0
    for k in pairs(multTable) do if k > maxKey then maxKey = k end end
    local idx = math.min(prevCount, maxKey)
    local multiplier = multTable[idx] or 1.00

    if opts.cooperation then
        multiplier = multiplier * P.Sentencing.cooperationDiscount
    end

    return {
        points   = math.floor(off.points * multiplier),
        fine     = math.min(math.floor(off.fine * multiplier), P.Sentencing.maxFine),
        jail     = math.min(math.floor(off.jail * multiplier), P.Sentencing.maxJailMinutes),
        license  = off.license,
        label    = off.label,
        category = off.category,
    }
end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_penalty_points` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `points` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_criminal_records` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `offense` VARCHAR(64) NOT NULL, `label` VARCHAR(128) NOT NULL, `points` INT NOT NULL,
        `fine` INT NOT NULL, `jail` INT NOT NULL, `officer` VARCHAR(50) DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_wanted` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `level` INT NOT NULL DEFAULT 1,
        `offenses` TEXT DEFAULT NULL,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadPlayer(citizenid, cb)
    MySQL.query('SELECT points FROM srp_penalty_points WHERE citizenid = ?', { citizenid }, function(rows)
        PlayerPoints[citizenid] = (rows and rows[1] and rows[1].points) or 0
        MySQL.query('SELECT offense, COUNT(*) AS c FROM srp_criminal_records WHERE citizenid = ? GROUP BY offense',
        { citizenid }, function(hrows)
            local hist = {}
            for _, r in ipairs(hrows or {}) do hist[r.offense] = r.c end
            PlayerHistory[citizenid] = hist
            if cb then cb(PlayerPoints[citizenid]) end
        end)
    end)
end

local function persistPoints(citizenid, points)
    MySQL.query([[INSERT INTO srp_penalty_points (citizenid, points) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE points = VALUES(points)]], { citizenid, points })
end

local function persistRecord(citizenid, sentence, officer)
    MySQL.insert([[INSERT INTO srp_criminal_records (citizenid, offense, label, points, fine, jail, officer)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        { citizenid, sentence.offenseKey, sentence.label, sentence.points, sentence.fine, sentence.jail, officer })
end

local function addPoints(citizenid, amount)
    PlayerPoints[citizenid] = (PlayerPoints[citizenid] or 0) + amount
    persistPoints(citizenid, PlayerPoints[citizenid])
    return PlayerPoints[citizenid]
end

local function getPoints(citizenid) return PlayerPoints[citizenid] or 0 end

local function evaluateThreshold(points)
    local t = P.Points.thresholds
    if points >= t.banReview then return 'banReview' end
    if points >= t.heavyJail then return 'heavyJail' end
    if points >= t.jail      then return 'jail' end
    if points >= t.fine      then return 'fine' end
    if points >= t.warning   then return 'warning' end
    return 'none'
end

CreateThread(function()
    ensureSchema()
    while true do
        Wait(60 * 60 * 1000)
        if P.Points.decay.enabled then
            for citizenid, _ in pairs(PlayerPoints) do
                local cur = PlayerPoints[citizenid] or 0
                local nxt = math.max(P.Points.decay.minPoints, cur - P.Points.decay.amountPerHour)
                if nxt ~= cur then PlayerPoints[citizenid] = nxt; persistPoints(citizenid, nxt) end
            end
        end
    end
end)

local function revokeLicense(citizenid, licenseType)
    if not licenseType or not P.Enabled.licenseRevoke then return end
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then
        MySQL.query('UPDATE players SET license = ? WHERE citizenid = ?', { 'none', citizenid })
        return
    end
    local lic = Player.PlayerData.metadata['licences'] or {}
    lic[licenseType] = false
    Player.Functions.SetMetaData('licences', lic)
end

local function issueBan(citizenid, reason, duration)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    duration = duration or P.Bans.autoBanDuration
    if QBCore.Functions.Ban then
        QBCore.Functions.Ban(citizenid, reason, duration)
    else
        MySQL.insert('INSERT INTO bans (name, license, discord, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?)',
            { 'SRP-AutoBan', citizenid, nil, reason, duration == 0 and 2147483647 or (os.time() + duration * 60), 'AutoPenalty' })
        if Player then Player.Functions.Kick('تم حظرك: ' .. reason) end
    end
    if P.Records.discordWebhook ~= '' then
        PerformHttpRequest(P.Records.discordWebhook, function() end, 'POST',
            json.encode({ content = ('**حظر تلقائي** — %s | السبب: %s'):format(citizenid, reason) }),
            { ['Content-Type'] = 'application/json' })
    end
end

local function applySentence(src, sentence, opts)
    opts = opts or {}
    local citizenid = getIdentifier(src)
    if not citizenid then return end
    local Player = QBCore.Functions.GetPlayer(src)

    persistRecord(citizenid, sentence, opts.officer or 'System')
    PlayerHistory[citizenid] = PlayerHistory[citizenid] or {}
    PlayerHistory[citizenid][sentence.offenseKey] = (PlayerHistory[citizenid][sentence.offenseKey] or 0) + 1

    local newPoints = addPoints(citizenid, sentence.points)
    local decision = evaluateThreshold(newPoints)

    if sentence.fine > 0 and Player then
        local cash = Player.Functions.GetMoney('cash')
        local bank = Player.Functions.GetMoney('bank')
        if cash + bank >= sentence.fine then
            local fromBank = math.min(bank, sentence.fine)
            Player.Functions.RemoveMoney('bank', fromBank, 'srp-fine')
            local rest = sentence.fine - fromBank
            if rest > 0 then Player.Functions.RemoveMoney('cash', rest, 'srp-fine') end
        elseif P.Sentencing.communityServiceInsteadOfUnpaid then
            local unpaid = sentence.fine - (cash + bank)
            sentence.jail = sentence.jail + math.ceil(unpaid / 1000 * P.Sentencing.communityServiceMinutesPer1000)
        end
    end

    if sentence.jail > 0 then
        TriggerClientEvent('srp:penalties:jail', src, sentence.jail, sentence.label)
    end
    revokeLicense(citizenid, sentence.license)

    if decision == 'banReview' or newPoints >= P.Bans.autoBanAtPoints then
        issueBan(citizenid, 'تجاوز حد نقاط العقوبات (' .. newPoints .. ')', P.Bans.offenseBanDurations[sentence.offenseKey])
    elseif P.Bans.instantBanOffenses[sentence.offenseKey] then
        issueBan(citizenid, sentence.label, P.Bans.offenseBanDurations[sentence.offenseKey])
    end

    if Player then
        TriggerClientEvent('QBCore:Notify', src,
            ('تم الحكم: غرامة $%s · سجن %s دقيقة (%s)'):format(sentence.fine, sentence.jail, sentence.label), 'error')
    end
end

local function setWanted(citizenid, level, offenseKey)
    WantedList[citizenid] = WantedList[citizenid] or { level = 0, offenses = {}, updated = os.time() }
    local w = WantedList[citizenid]
    w.level = math.min(P.Wanted.maxWantedLevel, math.max(w.level, level))
    w.offenses[offenseKey] = true
    w.updated = os.time()
    MySQL.query([[INSERT INTO srp_wanted (citizenid, level, offenses) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level), offenses = VALUES(offenses)]],
        { citizenid, w.level, json.encode(w.offenses) })
    TriggerClientEvent('srp:penalties:wanted', -1, citizenid, w.level)
end

local function clearWanted(citizenid)
    WantedList[citizenid] = nil
    MySQL.query('DELETE FROM srp_wanted WHERE citizenid = ?', { citizenid })
    TriggerClientEvent('srp:penalties:wantedClear', -1, citizenid)
end

CreateThread(function()
    while true do
        Wait(P.Wanted.broadcastInterval * 1000)
        for citizenid, w in pairs(WantedList) do
            if os.time() - w.updated > P.Wanted.cooldownSeconds then
                clearWanted(citizenid)
            else
                local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                if Player then
                    local coords = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
                    TriggerClientEvent('srp:penalties:locate', -1, citizenid, coords)
                end
            end
        end
    end
end)

local function autoSentenceOnArrest(src, officerId)
    local citizenid = getIdentifier(src)
    if not citizenid or not WantedList[citizenid] then return end
    local w = WantedList[citizenid]
    local totalFine, totalJail, totalPoints = 0, 0, 0
    for offenseKey, _ in pairs(w.offenses) do
        local s = calculateSentence(offenseKey, citizenid, { cooperation = false })
        if s then
            totalFine = totalFine + s.fine
            totalJail = totalJail + s.jail
            totalPoints = totalPoints + s.points
        end
    end
    local sentence = {
        offenseKey = 'aggregate', label = 'مجموع الجرائم المسجّلة',
        fine = math.min(totalFine, P.Sentencing.maxFine),
        jail = math.min(totalJail, P.Sentencing.maxJailMinutes),
        points = totalPoints, license = nil,
    }
    applySentence(src, sentence, { officer = officerId })
    clearWanted(citizenid)
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local citizenid = Player.PlayerData.citizenid
    loadPlayer(citizenid, function(pts)
        PointsTick[citizenid] = os.time()
        if pts >= P.Points.thresholds.warning then
            Wait(3000)
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, ('لديك %s نقطة عقوبات مسجّلة.'):format(pts), 'inform')
        end
    end)
end)

RegisterNetEvent('srp:penalties:report', function(offenseKey, opts)
    local src = source
    local citizenid = getIdentifier(src)
    if not citizenid then return end
    opts = opts or {}
    local sentence = calculateSentence(offenseKey, citizenid, opts)
    if not sentence then return end
    sentence.offenseKey = offenseKey
    applySentence(src, sentence, { officer = opts.officer })
end)

RegisterNetEvent('srp:penalties:setWanted', function(targetSrc, level, offenseKey)
    local citizenid = getIdentifier(targetSrc)
    if not citizenid then return end
    setWanted(citizenid, level or 1, offenseKey or 'assault')
end)

RegisterNetEvent('srp:penalties:arrest', function(targetSrc)
    local officerId = getIdentifier(source) or 'Unknown'
    if P.Wanted.autoSentenceOnArrest then autoSentenceOnArrest(targetSrc, officerId) end
end)

QBCore.Commands.Add('points', 'عرض نقاط العقوبات للاعب', { { name = 'id', help = 'ID اللاعب' } }, false, function(source, args)
    local citizenid = getIdentifier(tonumber(args[1]) or source)
    if not citizenid then return end
    TriggerClientEvent('QBCore:Notify', source, ('نقاط العقوبات: %s'):format(getPoints(citizenid)), 'primary')
end, 'admin')

QBCore.Commands.Add('clearpoints', 'تصفير نقاط العقوبات', { { name = 'citizenid', help = 'citizenid اللاعب' } }, false, function(source, args)
    local cid = args[1]
    if not cid or cid == '' then return end
    PlayerPoints[cid] = 0
    persistPoints(cid, 0)
    TriggerClientEvent('QBCore:Notify', source, 'تم تصفير النقاط.', 'success')
end, 'admin')

QBCore.Commands.Add('record', 'عرض السجل الجنائي', { { name = 'id', help = 'ID اللاعب' } }, false, function(source, args)
    local citizenid = getIdentifier(tonumber(args[1]) or source)
    if not citizenid then return end
    MySQL.query('SELECT * FROM srp_criminal_records WHERE citizenid = ? ORDER BY created DESC LIMIT ?',
    { citizenid, P.Records.maxQueryRows }, function(rows)
        local list = {}
        for _, r in ipairs(rows or {}) do
            list[#list+1] = ('• %s — $%s / %sد (%s)'):format(r.label, r.fine, r.jail, r.created)
        end
        TriggerClientEvent('QBCore:Notify', source, ('السجل الجنائي (%s):\n%s'):format(#list, table.concat(list, '\n')), 'primary')
    end)
end, 'admin')

log('تم تحميل نظام العقوبات التلقائية.')
