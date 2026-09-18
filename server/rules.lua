--[[
    fivem-strict-rp :: server/rules.lua
    نظام قوانين RP + الإشراف — QBCore
]]

local QBCore = exports['qb-core']:GetCoreObject()
local R = Rules

local StaffPoints = {}
local ReportCooldown = {}

local function log(msg) print(('[fivem-strict-rp][rules] %s'):format(msg)) end
local function getCid(src)
    local P = QBCore.Functions.GetPlayer(src)
    return P and P.PlayerData.citizenid or nil
end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_reports` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `reporter` VARCHAR(50) NOT NULL, `reporter_name` VARCHAR(64) NOT NULL,
        `target` VARCHAR(50) DEFAULT NULL, `target_name` VARCHAR(64) DEFAULT NULL,
        `category` VARCHAR(32) NOT NULL, `message` TEXT NOT NULL,
        `status` ENUM('open','handled','dismissed') NOT NULL DEFAULT 'open',
        `handled_by` VARCHAR(50) DEFAULT NULL, `handled_note` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_staff_log` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `staff` VARCHAR(50) NOT NULL, `target` VARCHAR(50) NOT NULL,
        `action` VARCHAR(24) NOT NULL, `rule` VARCHAR(32) DEFAULT NULL,
        `reason` TEXT NOT NULL, `points` INT NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_target` (`target`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_staff_points` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `points` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadPoints(citizenid, cb)
    MySQL.query('SELECT points FROM srp_staff_points WHERE citizenid = ?', { citizenid }, function(rows)
        StaffPoints[citizenid] = (rows and rows[1] and rows[1].points) or 0
        if cb then cb(StaffPoints[citizenid]) end
    end)
end

local function persistPoints(citizenid, pts)
    MySQL.query([[INSERT INTO srp_staff_points (citizenid, points) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE points = VALUES(points)]], { citizenid, pts })
end

local function addStaffPoints(citizenid, amount)
    StaffPoints[citizenid] = (StaffPoints[citizenid] or 0) + amount
    persistPoints(citizenid, StaffPoints[citizenid])
    return StaffPoints[citizenid]
end

local function resolveEscalation(points)
    local result = nil
    for _, t in ipairs(R.Escalation.thresholds) do
        if points >= t.at then result = t end
    end
    return result
end

local function applyEscalation(src, citizenid)
    if not R.Enabled.autoEscalate then return end
    local escal = resolveEscalation(StaffPoints[citizenid] or 0)
    if not escal then return end
    if escal.action == "jail" then
        TriggerClientEvent('srp:penalties:jail', src, escal.jailMinutes or 30, escal.label)
    elseif escal.action == "ban" then
        local minutes = escal.banMinutes or 1440
        if QBCore.Functions.Ban then
            QBCore.Functions.Ban(citizenid, escal.label, minutes)
        else
            MySQL.insert('INSERT INTO bans (name, license, discord, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?)',
                { 'SRP-StaffEscalation', citizenid, nil, escal.label,
                  minutes == 0 and 2147483647 or (os.time() + minutes * 60), 'AutoEscalation' })
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then Player.Functions.Kick(escal.label) end
        end
    end
    TriggerClientEvent('QBCore:Notify', src, ('تصعيد: %s (نقاط %s)'):format(escal.label, StaffPoints[citizenid]), 'error')
end

RegisterNetEvent('srp:rules:report', function(category, targetSrc, message)
    local src = source
    if not R.Enabled.reports then return end
    if ReportCooldown[src] and (os.time() - ReportCooldown[src]) < R.Reports.cooldownSeconds then
        TriggerClientEvent('QBCore:Notify', src, R.Messages.reportCooldown, 'error') return
    end
    ReportCooldown[src] = os.time()
    local reporter = QBCore.Functions.GetPlayer(src)
    if not reporter then return end
    local target = targetSrc and QBCore.Functions.GetPlayer(tonumber(targetSrc)) or nil
    if R.Reports.requireActivePlayers and targetSrc and not target then
        TriggerClientEvent('QBCore:Notify', src, 'اللاعب غير متصل.', 'error') return
    end
    MySQL.insert([[INSERT INTO srp_reports (reporter, reporter_name, target, target_name, category, message)
        VALUES (?, ?, ?, ?, ?, ?)]],
        { reporter.PlayerData.citizenid, reporter.PlayerData.charinfo.firstname .. ' ' .. reporter.PlayerData.charinfo.lastname,
          target and target.PlayerData.citizenid or nil,
          target and (target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname) or nil,
          category or 'other', message or '' })
    TriggerClientEvent('QBCore:Notify', src, R.Messages.reportReceived, 'success')
    for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
        local P = QBCore.Functions.GetPlayer(pid)
        if P and QBCore.Functions.HasPermission(pid, 'admin') then
            TriggerClientEvent('QBCore:Notify', pid, 'تقرير جديد — اكتب /reports', 'inform')
        end
    end
end)

QBCore.Commands.Add('reports', 'عرض التقارير المعلقة', {}, false, function(source)
    MySQL.query('SELECT * FROM srp_reports WHERE status = "open" ORDER BY created ASC LIMIT 20', {}, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('QBCore:Notify', source, 'لا توجد تقارير معلقة.', 'primary') return
        end
        for _, r in ipairs(rows) do
            TriggerClientEvent('QBCore:Notify', source,
                ('#%s [%s] من %s ضد %s: %s'):format(r.id, r.category, r.reporter_name, r.target_name or '—', r.message), 'inform')
        end
    end)
end, 'admin')

QBCore.Commands.Add('handlereport', 'إغلاق تقرير', { { name = 'id' }, { name = 'note', help = 'ملاحظة' } }, false, function(source, args)
    local id = tonumber(args[1])
    if not id then return end
    local note = table.concat(args, ' ', 2)
    local staff = getCid(source) or 'Staff'
    MySQL.query('UPDATE srp_reports SET status = "handled", handled_by = ?, handled_note = ? WHERE id = ?', { staff, note, id })
    TriggerClientEvent('QBCore:Notify', source, ('تم إغلاق التقرير #%s'):format(id), 'success')
end, 'admin')

local function logStaffAction(staffCid, targetCid, action, ruleKey, reason, points)
    MySQL.insert([[INSERT INTO srp_staff_log (staff, target, action, rule, reason, points)
        VALUES (?, ?, ?, ?, ?, ?)]], { staffCid, targetCid, action, ruleKey, reason, points })
    if R.Records.discordWebhook ~= '' then
        PerformHttpRequest(R.Records.discordWebhook, function() end, 'POST',
            json.encode({ content = ('**%s** — %s | القاعدة: %s | السبب: %s'):format(action, targetCid, ruleKey or '-', reason) }),
            { ['Content-Type'] = 'application/json' })
    end
end

local function takeAction(staffSrc, targetSrc, action, ruleKey, reason)
    if not R.Enabled.staffActions then return end
    if R.Enabled.requireReason and (not reason or reason == '') then
        TriggerClientEvent('QBCore:Notify', staffSrc, 'يجب تحديد سبب.', 'error') return
    end
    local target = QBCore.Functions.GetPlayer(tonumber(targetSrc))
    if not target then
        TriggerClientEvent('QBCore:Notify', staffSrc, 'اللاعب غير متصل.', 'error') return
    end
    local targetCid = target.PlayerData.citizenid
    local staffCid  = getCid(staffSrc) or 'Staff'
    local rule = ruleKey and R.List[ruleKey]
    local weight = rule and rule.weight or 10
    local newPoints = addStaffPoints(targetCid, weight)
    if action == 'warn' then
        TriggerClientEvent('QBCore:Notify', targetSrc, ('إنذار: %s'):format(reason), 'error')
    elseif action == 'jail' then
        TriggerClientEvent('srp:penalties:jail', targetSrc, 30, reason)
    elseif action == 'kick' then
        target.Functions.Kick(reason)
    elseif action == 'ban' then
        if QBCore.Functions.Ban then
            QBCore.Functions.Ban(targetCid, reason, 1440)
        else
            MySQL.insert('INSERT INTO bans (name, license, discord, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?)',
                { 'SRP-Staff', targetCid, nil, reason, os.time() + 86400, staffCid })
            target.Functions.Kick(reason)
        end
    end
    logStaffAction(staffCid, targetCid, action, ruleKey, reason, weight)
    TriggerClientEvent('QBCore:Notify', staffSrc,
        ('تم تنفيذ %s على %s (نقاط: %s)'):format(action, targetCid, newPoints), 'success')
    applyEscalation(targetSrc, targetCid)
end

QBCore.Commands.Add('warn', 'إنذار لاعب', { { name = 'id' }, { name = 'reason', help = 'السبب' } }, false,
    function(source, args) takeAction(source, args[1], 'warn', args[2], table.concat(args, ' ', 2)) end, 'admin')

QBCore.Commands.Add('kick', 'طرد لاعب', { { name = 'id' }, { name = 'reason' } }, false,
    function(source, args) takeAction(source, args[1], 'kick', args[2], table.concat(args, ' ', 2)) end, 'admin')

QBCore.Commands.Add('sjaill', 'سجن إداري (Staff)', { { name = 'id' }, { name = 'reason' } }, false,
    function(source, args) takeAction(source, args[1], 'jail', args[2], table.concat(args, ' ', 2)) end, 'admin')

QBCore.Commands.Add('ban', 'حظر لاعب', { { name = 'id' }, { name = 'reason' } }, false,
    function(source, args) takeAction(source, args[1], 'ban', args[2], table.concat(args, ' ', 2)) end, 'admin')

QBCore.Commands.Add('note', 'ملاحظة سرية', { { name = 'id' }, { name = 'text' } }, false,
    function(source, args) takeAction(source, args[1], 'note', args[2], table.concat(args, ' ', 2)) end, 'admin')

QBCore.Commands.Add('staffpoints', 'عرض نقاط الإشراف', { { name = 'id' } }, false, function(source, args)
    local cid = getCid(tonumber(args[1]) or source)
    if not cid then return end
    loadPoints(cid, function(pts)
        TriggerClientEvent('QBCore:Notify', source, ('نقاط الإشراف: %s'):format(pts), 'primary')
    end)
end, 'admin')

QBCore.Commands.Add('stafflog', 'سجل إجراءات لاعب', { { name = 'citizenid' } }, false, function(source, args)
    local cid = args[1]
    if not cid then return end
    MySQL.query('SELECT * FROM srp_staff_log WHERE target = ? ORDER BY created DESC LIMIT ?',
    { cid, R.Records.maxQueryRows }, function(rows)
        for _, r in ipairs(rows or {}) do
            TriggerClientEvent('QBCore:Notify', source, ('• %s — %s (%s)'):format(r.action, r.reason, r.created), 'inform')
        end
    end)
end, 'admin')

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadPoints(Player.PlayerData.citizenid)
end)

log('تم تحميل نظام القوانين والإشراف.')
