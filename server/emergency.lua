--[[
    fivem-strict-rp :: server/emergency.lua
    الأمن العام والإسعاف — MDT · مذكرات · تبصيم · بودي كام · رادار · علاج · تأمين.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local E = Emergency

local bodycams = {}
local function log(msg) print(('[fivem-strict-rp][emergency] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_warrants` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `type` VARCHAR(24) NOT NULL,
        `target` VARCHAR(50) NOT NULL, `target_name` VARCHAR(64) NOT NULL,
        `reason` TEXT NOT NULL, `officer` VARCHAR(50) NOT NULL,
        `status` VARCHAR(12) NOT NULL DEFAULT 'active',
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_target` (`target`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_mdt_reports` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `kind` VARCHAR(16) NOT NULL,
        `author` VARCHAR(50) NOT NULL, `author_name` VARCHAR(64) NOT NULL,
        `title` VARCHAR(128) NOT NULL, `body` TEXT NOT NULL, `subjects` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_kind` (`kind`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_fingerprints` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `prints` TEXT NOT NULL,
        `booked_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_traffic_fines` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `type` VARCHAR(24) NOT NULL, `label` VARCHAR(48) NOT NULL, `amount` INT NOT NULL,
        `status` VARCHAR(12) NOT NULL DEFAULT 'unpaid', `officer` VARCHAR(50) NOT NULL,
        `dispute` TINYINT(1) NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_medical_insurance` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `plan` VARCHAR(16) NOT NULL,
        `paid_until` INT NOT NULL,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function isPolice(Player) return Player.PlayerData.job.name == E.Settings.policeJob end
local function isEMS(Player) return Player.PlayerData.job.name == E.Settings.emsJob end
local function policeRank(Player)
    local lvl = Player.PlayerData.job.grade.level or 0
    return E.PoliceRanks[lvl] or E.PoliceRanks[0]
end

RegisterNetEvent('srp:emergency:issueWarrant', function(targetSrc, wtype, reason)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    if not isPolice(Player) then TriggerClientEvent('QBCore:Notify', src, E.Messages.notPolice, 'error') return end
    if not policeRank(Player).canIssueWarrant then TriggerClientEvent('QBCore:Notify', src, E.Messages.needRank, 'error') return end
    local wt = E.WarrantTypes[wtype]
    if not wt then return end
    local t = Target.PlayerData
    local tname = t.charinfo.firstname .. ' ' .. t.charinfo.lastname
    MySQL.insert([[INSERT INTO srp_warrants (type, target, target_name, reason, officer)
        VALUES (?, ?, ?, ?, ?)]], { wtype, t.citizenid, tname, reason or '', Player.PlayerData.citizenid }, function(id)
        TriggerClientEvent('QBCore:Notify', src, ('صدرت %s ضد %s'):format(wt.label, tname), 'success')
        TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('صدرت بحقك %s: %s'):format(wt.label, reason or ''), 'error')
        if wtype == 'arrest' then TriggerEvent('srp:penalties:setWanted', tonumber(targetSrc), 2, 'assault') end
    end)
end)

RegisterNetEvent('srp:emergency:revokeWarrant', function(warrantId)
    local src = source
    local Player = getPlayer(src)
    if not Player or not isPolice(Player) then return end
    MySQL.query('UPDATE srp_warrants SET status = "revoked" WHERE id = ?', { warrantId })
    TriggerClientEvent('QBCore:Notify', src, E.Messages.warrantRevoked, 'success')
end)

RegisterNetEvent('srp:emergency:fingerprint', function(targetSrc)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    if not isPolice(Player) then TriggerClientEvent('QBCore:Notify', src, E.Messages.notPolice, 'error') return end
    if not policeRank(Player).canFingerprint then TriggerClientEvent('QBCore:Notify', src, E.Messages.needRank, 'error') return end
    local cid = Target.PlayerData.citizenid
    local prints = ('FP-%s-%s'):format(cid:sub(-6), math.random(1000, 9999))
    MySQL.query([[INSERT INTO srp_fingerprints (citizenid, prints) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE prints = VALUES(prints), booked_at = CURRENT_TIMESTAMP]], { cid, prints })
    local tname = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
    TriggerClientEvent('QBCore:Notify', src, ('تم تبصيم %s (البصمة: %s)'):format(tname, prints), 'success')
end)

RegisterNetEvent('srp:emergency:toggleBodycam', function()
    local src = source
    local Player = getPlayer(src)
    if not Player or not isPolice(Player) then return end
    bodycams[src] = not bodycams[src]
    TriggerClientEvent('QBCore:Notify', src, bodycams[src] and E.Messages.bodycamOn or E.Messages.bodycamOff, bodycams[src] and 'success' or 'inform')
end)

RegisterNetEvent('srp:emergency:createReport', function(kind, title, body, subjects)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if not (isPolice(Player) or isEMS(Player)) then return end
    local pd = Player.PlayerData
    local aname = pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname
    MySQL.insert([[INSERT INTO srp_mdt_reports (kind, author, author_name, title, body, subjects)
        VALUES (?, ?, ?, ?, ?, ?)]], { kind, pd.citizenid, aname, title, body, json.encode(subjects or {}) }, function(id)
        TriggerClientEvent('QBCore:Notify', src, ('أُنشئ التقرير #%s'):format(id), 'success')
    end)
end)

RegisterNetEvent('srp:emergency:issueFine', function(targetSrc, fineKey)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    if not isPolice(Player) then TriggerClientEvent('QBCore:Notify', src, E.Messages.notPolice, 'error') return end
    local fine = E.TrafficFines[fineKey]
    if not fine then return end
    local t = Target.PlayerData
    MySQL.insert('INSERT INTO srp_traffic_fines (citizenid, type, label, amount, officer) VALUES (?, ?, ?, ?, ?)',
        { t.citizenid, fineKey, fine.label, fine.amount, Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('مخالفة: %s — $%s'):format(fine.label, fine.amount), 'error')
    TriggerClientEvent('QBCore:Notify', src, ('حُررت مخالفة %s على %s'):format(fine.label, t.charinfo.firstname), 'success')
end)

RegisterNetEvent('srp:emergency:disputeFine', function(fineId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('UPDATE srp_traffic_fines SET dispute = 1 WHERE id = ? AND citizenid = ?', { fineId, Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', src, 'تم رفع اعتراضك — ستراجعه الأمن العام.', 'success')
end)

RegisterNetEvent('srp:emergency:reviewDispute', function(fineId, accept)
    local src = source
    local Player = getPlayer(src)
    if not Player or not isPolice(Player) then return end
    if accept then MySQL.query('UPDATE srp_traffic_fines SET status = "dismissed", dispute = 0 WHERE id = ?', { fineId })
    else MySQL.query('UPDATE srp_traffic_fines SET dispute = 0 WHERE id = ?', { fineId }) end
    TriggerClientEvent('QBCore:Notify', src, accept and 'قُبل الاعتراض' or 'رُفض الاعتراض', 'success')
end)

CreateThread(function()
    if not E.Settings.radarEnabled then return end
    while true do
        Wait(4000)
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do
            local ped = GetPlayerPed(src)
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local coords = GetEntityCoords(veh)
                local speed = GetEntitySpeed(veh) * 3.6
                for _, r in ipairs(E.Radars) do
                    if #(coords - vector3(r.x, r.y, r.z)) < 30.0 and speed > r.speedLimit then
                        local Player = getPlayer(src)
                        if Player then
                            Player.Functions.RemoveMoney('bank', E.Settings.radarFine, 'srp-radar-fine')
                            TriggerClientEvent('QBCore:Notify', src, ('رادار: تجاوزت السرعة (%s) — غرامة $%s'):format(math.floor(speed), E.Settings.radarFine), 'error')
                        end
                        break
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('srp:emergency:treat', function(targetSrc, serviceKey)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    if not isEMS(Player) then TriggerClientEvent('QBCore:Notify', src, E.Messages.notEMS, 'error') return end
    local svc = E.EMSServices[serviceKey]
    if not svc then return end
    local tcid = Target.PlayerData.citizenid
    MySQL.query('SELECT * FROM srp_medical_insurance WHERE citizenid = ? AND paid_until > ?', { tcid, os.time() }, function(rows)
        local ins = rows and rows[1]
        local cost = svc.price
        local covered = 0
        if ins then
            local plan = E.Insurance.plans[ins.plan]
            if plan then covered = math.floor(cost * plan.coveragePercent / 100); cost = cost - covered end
        end
        if cost > 0 then
            if Target.Functions.GetMoney('bank') >= cost then Target.Functions.RemoveMoney('bank', cost, 'srp-medical')
            elseif Target.Functions.GetMoney('cash') >= cost then Target.Functions.RemoveMoney('cash', cost, 'srp-medical') end
        end
        TriggerClientEvent('srp:emergency:doTreat', src, targetSrc, serviceKey)
        local commission = math.floor(svc.price * 0.4)
        Player.Functions.AddMoney('bank', commission, 'srp-ems-commission')
        local msg = ins and ('🛡️ التأمين غطّى $%s — دفعت $%s'):format(covered, cost) or ('💊 تم العلاج ($%s)'):format(cost)
        TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), msg, 'success')
    end)
end)

RegisterNetEvent('srp:emergency:buyInsurance', function(planKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local plan = E.Insurance.plans[planKey]
    if not plan then return end
    if Player.Functions.GetMoney('bank') < plan.premium then TriggerClientEvent('QBCore:Notify', src, 'لا تملك المال الكافي.', 'error') return end
    Player.Functions.RemoveMoney('bank', plan.premium, 'srp-insurance')
    local paidUntil = os.time() + (30 * 86400)
    MySQL.query([[INSERT INTO srp_medical_insurance (citizenid, plan, paid_until) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE plan = VALUES(plan), paid_until = VALUES(paid_until)]], { Player.PlayerData.citizenid, planKey, paidUntil })
    TriggerClientEvent('QBCore:Notify', src, ('اشتركت في %s'):format(plan.label), 'success')
end)

RegisterNetEvent('srp:emergency:mdtQuery', function(queryType, param)
    local src = source
    local Player = getPlayer(src)
    if not Player or not (isPolice(Player) or isEMS(Player)) then return end
    if queryType == 'warrants' then
        MySQL.query('SELECT * FROM srp_warrants WHERE status = "active" ORDER BY created DESC LIMIT 30', {}, function(rows)
            TriggerClientEvent('srp:emergency:mdtResult', src, 'warrants', rows or {})
        end)
    elseif queryType == 'reports' then
        MySQL.query('SELECT id, kind, author_name, title, created FROM srp_mdt_reports ORDER BY created DESC LIMIT 30', {}, function(rows)
            TriggerClientEvent('srp:emergency:mdtResult', src, 'reports', rows or {})
        end)
    elseif queryType == 'fines' then
        MySQL.query('SELECT * FROM srp_traffic_fines WHERE status = "unpaid" ORDER BY created DESC LIMIT 30', {}, function(rows)
            TriggerClientEvent('srp:emergency:mdtResult', src, 'fines', rows or {})
        end)
    elseif queryType == 'citizen' and param then
        MySQL.query('SELECT * FROM srp_fingerprints WHERE citizenid = ?', { param }, function(rows)
            TriggerClientEvent('srp:emergency:mdtResult', src, 'citizen', rows or {})
        end)
    end
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل نظام الأمن العام والإسعاف.')
end)
