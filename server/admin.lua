--[[
    fivem-strict-rp :: server/admin.lua
    تابلت الأدمن الشامل — 23 قسماً + 12 أداة ستاف.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local A = Admin

local function log(msg) print(('[fivem-strict-rp][admin] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function isAdmin(src) return QBCore.Functions.HasPermission(src, A.Settings.minPermission) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_admin_log` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `staff` VARCHAR(50) NOT NULL,
        `action` VARCHAR(48) NOT NULL, `target` VARCHAR(50) DEFAULT NULL,
        `detail` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_staff` (`staff`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function writeLog(src, action, target, detail)
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.insert('INSERT INTO srp_admin_log (staff, action, target, detail) VALUES (?, ?, ?, ?)',
        { Player.PlayerData.citizenid, action, target, detail })
end

RegisterNetEvent('srp:admin:open', function()
    local src = source
    if not isAdmin(src) then TriggerClientEvent('QBCore:Notify', src, A.Messages.noPermission, 'error') return end
    local Player = getPlayer(src)
    TriggerClientEvent('srp:admin:show', src, {
        sections = A.Sections, tools = A.QuickTools,
        playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
    })
end)

RegisterNetEvent('srp:admin:section', function(sectionKey)
    local src = source
    if not isAdmin(src) then return end
    if sectionKey == 'players' then
        local list = {}
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
            local P = getPlayer(pid)
            if P then
                list[#list+1] = { id = pid, name = P.PlayerData.charinfo.firstname .. ' ' .. P.PlayerData.charinfo.lastname,
                    job = P.PlayerData.job.label or P.PlayerData.job.name, bank = P.Functions.GetMoney('bank'), cash = P.Functions.GetMoney('cash') }
            end
        end
        TriggerClientEvent('srp:admin:showSection', src, 'players', list)
    elseif sectionKey == 'server' then
        TriggerClientEvent('srp:admin:showSection', src, 'server', { players = #QBCore.Functions.GetPlayers(), hostname = GetConvar('sv_hostname', 'SRP') })
    elseif sectionKey == 'penalties' then
        MySQL.query('SELECT * FROM srp_penalty_points ORDER BY points DESC LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'penalties', rows or {})
        end)
    elseif sectionKey == 'economy' then
        MySQL.query('SELECT * FROM srp_inflation WHERE id = 1', {}, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'economy', rows or {})
        end)
    elseif sectionKey == 'dealers' then
        MySQL.query('SELECT COUNT(*) AS c FROM player_vehicles', {}, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'dealers', rows or {})
        end)
    elseif sectionKey == 'businesses' then
        MySQL.query('SELECT type, COUNT(*) AS c FROM srp_businesses GROUP BY type', {}, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'businesses', rows or {})
        end)
    elseif sectionKey == 'families' then
        MySQL.query('SELECT * FROM srp_families ORDER BY treasury DESC LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'families', rows or {})
        end)
    elseif sectionKey == 'banks' then
        MySQL.query('SELECT * FROM srp_bank_loans WHERE remaining > 0 LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'banks', rows or {})
        end)
    elseif sectionKey == 'emergency' then
        MySQL.query('SELECT * FROM srp_warrants WHERE status = "active" LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'emergency', rows or {})
        end)
    elseif sectionKey == 'legal' then
        MySQL.query('SELECT * FROM srp_cases WHERE status = "filed" LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'legal', rows or {})
        end)
    elseif sectionKey == 'oil' then
        MySQL.query('SELECT * FROM srp_oil_stations', {}, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'oil', rows or {})
        end)
    elseif sectionKey == 'lands' then
        MySQL.query('SELECT * FROM srp_lands LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'lands', rows or {})
        end)
    elseif sectionKey == 'stalls' then
        MySQL.query('SELECT * FROM srp_stalls LIMIT ?', { A.Settings.maxResults }, function(rows)
            TriggerClientEvent('srp:admin:showSection', src, 'stalls', rows or {})
        end)
    else
        TriggerClientEvent('srp:admin:showSection', src, sectionKey, { note = 'قسم بدون بيانات مباشرة — استخدم أدوات الستاف' })
    end
end)

RegisterNetEvent('srp:admin:tool', function(tool, targetSrc, arg1, arg2)
    local src = source
    if not isAdmin(src) then return end
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if tool == 'goto' and Target then TriggerClientEvent('srp:admin:teleportTo', src, Target.PlayerData.source)
    elseif tool == 'bring' and Target then
        TriggerClientEvent('srp:admin:bringPlayer', src, Target.PlayerData.source)
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, 'تم إحضارك للإدارة.', 'inform')
    elseif tool == 'freeze' and Target then TriggerClientEvent('srp:admin:freeze', Target.PlayerData.source)
    elseif tool == 'revive' and Target then TriggerClientEvent('srp:admin:revive', Target.PlayerData.source)
    elseif tool == 'kick' and Target then Target.Functions.Kick(arg1 or 'طرد إداري')
    elseif tool == 'setjob' and Target then
        Target.Functions.SetJob(arg1 or 'unemployed', tonumber(arg2) or 0)
        TriggerClientEvent('QBCore:Notify', src, ('عُيّن %s كـ %s'):format(Target.PlayerData.citizenid, arg1), 'success')
    elseif tool == 'setmoney' and Target then
        Target.Functions.SetMoney(arg2 or 'bank', tonumber(arg1) or 0, 'srp-admin-setmoney')
        TriggerClientEvent('QBCore:Notify', src, ('ضُبط رصيد %s'):format(arg2 or 'bank'), 'success')
    elseif tool == 'noclip' then TriggerClientEvent('srp:admin:noclip', src)
    elseif tool == 'restart' then
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', pid, arg1 or 'تنبيه: رستارت قريب!', 'error')
        end
    end
    if A.Settings.logActions and Player then writeLog(src, tool, Target and Target.PlayerData.citizenid or nil, tostring(arg1)) end
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل تابلت الأدمن الشامل.')
end)
