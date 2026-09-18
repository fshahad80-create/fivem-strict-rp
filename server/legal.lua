--[[
    fivem-strict-rp :: server/legal.lua
    المحاماة والمحكمة + العقود — ترخيص · دعاوى · أحكام · عقود مزدوجة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local Lg = Legal

local Licenses  = {}
local Cases     = {}
local Contracts = {}

local function log(msg) print(('[fivem-strict-rp][legal] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function getByCid(cid) return QBCore.Functions.GetPlayerByCitizenId(cid) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_lawyer_licenses` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `expires_at` INT NOT NULL,
        `issued_by` VARCHAR(50) NOT NULL,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_cases` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `type` VARCHAR(24) NOT NULL,
        `plaintiff` VARCHAR(50) NOT NULL, `plaintiff_name` VARCHAR(64) NOT NULL,
        `defendant` VARCHAR(50) NOT NULL, `defendant_name` VARCHAR(64) NOT NULL,
        `title` VARCHAR(128) NOT NULL, `body` TEXT NOT NULL, `evidence` TEXT DEFAULT NULL,
        `status` VARCHAR(16) NOT NULL DEFAULT 'filed', `judge` VARCHAR(50) DEFAULT NULL,
        `verdict` VARCHAR(24) DEFAULT NULL, `sentence` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_contracts` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `title` VARCHAR(128) NOT NULL,
        `body` TEXT NOT NULL, `party1` VARCHAR(50) NOT NULL, `party2` VARCHAR(50) NOT NULL,
        `sig1` TINYINT(1) NOT NULL DEFAULT 0, `sig2` TINYINT(1) NOT NULL DEFAULT 0,
        `status` VARCHAR(16) NOT NULL DEFAULT 'pending', `expires_at` INT NOT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadLicense(cid, cb)
    MySQL.query('SELECT * FROM srp_lawyer_licenses WHERE citizenid = ?', { cid }, function(rows)
        local r = rows and rows[1]
        Licenses[cid] = r and r.expires_at or nil
        if cb then cb(Licenses[cid]) end
    end)
end

local function loadAll()
    MySQL.query('SELECT * FROM srp_cases ORDER BY created DESC LIMIT ?', { Lg.Settings.maxOpenCases }, function(rows)
        Cases = {}
        for _, r in ipairs(rows or {}) do Cases[r.id] = r end
    end)
    MySQL.query('SELECT * FROM srp_contracts WHERE status = "pending"', {}, function(rows)
        Contracts = {}
        for _, r in ipairs(rows or {}) do Contracts[r.id] = r end
    end)
end

local function isLawyer(cid) return Licenses[cid] and Licenses[cid] > os.time() end

RegisterNetEvent('srp:legal:issueLicense', function(targetSrc)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    if Player.PlayerData.job.name ~= Lg.Settings.judgeJob then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.notJudge, 'error') return
    end
    local cid = Target.PlayerData.citizenid
    if Target.Functions.GetMoney('bank') < Lg.Settings.lawyerLicenseFee then
        TriggerClientEvent('QBCore:Notify', src, 'اللاعب لا يملك رسوم الترخيص.', 'error') return
    end
    Target.Functions.RemoveMoney('bank', Lg.Settings.lawyerLicenseFee, 'srp-lawyer-license')
    local expiry = os.time() + (90 * 86400)
    MySQL.query([[INSERT INTO srp_lawyer_licenses (citizenid, expires_at, issued_by) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE expires_at = VALUES(expires_at), issued_by = VALUES(issued_by)]],
        { cid, expiry, Player.PlayerData.citizenid })
    Licenses[cid] = expiry
    TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), Lg.Messages.licenseIssued, 'success')
    TriggerClientEvent('QBCore:Notify', src, 'صدر ترخيص المحاماة.', 'success')
end)

RegisterNetEvent('srp:legal:fileCase', function(targetSrc, caseType, title, body)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    local cid = Player.PlayerData.citizenid
    if not isLawyer(cid) then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.notLawyer, 'error') return
    end
    local ctype = Lg.CaseTypes[caseType]
    if not ctype then return end
    if Player.Functions.GetMoney('bank') < Lg.Settings.lawsuitFee then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', Lg.Settings.lawsuitFee, 'srp-lawsuit-fee')
    local t = Target.PlayerData
    local pname = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local tname = t.charinfo.firstname .. ' ' .. t.charinfo.lastname
    MySQL.insert([[INSERT INTO srp_cases (type, plaintiff, plaintiff_name, defendant, defendant_name, title, body)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        { caseType, cid, pname, t.citizenid, tname, title or 'دعوى', body or '' }, function(id)
        TriggerClientEvent('QBCore:Notify', src, ('رُفعت الدعوى #%s ضد %s'):format(id, tname), 'success')
        TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('رُفعت ضدك دعوى #%s'):format(id), 'error')
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
            local P = getPlayer(pid)
            if P and P.PlayerData.job.name == Lg.Settings.judgeJob then
                TriggerClientEvent('QBCore:Notify', pid, ('دعوى جديدة #%s — ناجز'):format(id), 'inform')
            end
        end
    end)
end)

RegisterNetEvent('srp:legal:issueVerdict', function(caseId, verdictKey, fine, jailMonths)
    local src = source
    local Player = getPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Lg.Settings.judgeJob then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.notJudge, 'error') return
    end
    local verdict = Lg.Verdicts[verdictKey]
    if not verdict then return end
    fine = math.min(tonumber(fine) or 0, Lg.Sentencing.maxFine)
    jailMonths = math.min(tonumber(jailMonths) or 0, Lg.Sentencing.maxJailMonths)
    MySQL.query('SELECT * FROM srp_cases WHERE id = ?', { caseId }, function(rows)
        local case = rows and rows[1]
        if not case then return end
        local sentence = ('غرامة $%s · سجن %s شهر'):format(fine, jailMonths)
        MySQL.query([[UPDATE srp_cases SET status = "closed", judge = ?, verdict = ?, sentence = ? WHERE id = ?]],
            { Player.PlayerData.citizenid, verdictKey, sentence, caseId })
        local Def = getByCid(case.defendant)
        if Def then
            TriggerClientEvent('QBCore:Notify', Def.PlayerData.source, ('الحكم: %s — %s'):format(verdict.label, sentence), 'error')
            if verdict.canFine and fine > 0 then Def.Functions.RemoveMoney('bank', fine, 'srp-court-fine') end
            if verdict.canJail and jailMonths > 0 then
                TriggerClientEvent('srp:penalties:jail', Def.PlayerData.source, jailMonths * 60, 'حكم قضائي')
            end
        end
        local Pl = getByCid(case.plaintiff)
        if Pl then TriggerClientEvent('QBCore:Notify', Pl.PlayerData.source, ('صدر الحكم في دعواك: %s'):format(verdict.label), 'success') end
        TriggerClientEvent('QBCore:Notify', src, ('صدر الحكم #%s: %s'):format(caseId, verdict.label), 'success')
    end)
end)

RegisterNetEvent('srp:legal:createContract', function(targetSrc, title, body)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    local cid = Player.PlayerData.citizenid
    local tcid = Target.PlayerData.citizenid
    if Player.Functions.GetMoney('bank') < Lg.Settings.contractFee then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', Lg.Settings.contractFee, 'srp-contract-fee')
    local expiry = os.time() + (Lg.Settings.contractExpireDays * 86400)
    MySQL.insert([[INSERT INTO srp_contracts (title, body, party1, party2, expires_at) VALUES (?, ?, ?, ?, ?)]],
        { title or 'عقد', body or '', cid, tcid, expiry }, function(id)
        TriggerClientEvent('QBCore:Notify', src, ('أُنشئ العقد #%s — وقّعه أولاً'):format(id), 'success')
        TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('عقد بانتظارك #%s'):format(id), 'inform')
    end)
end)

RegisterNetEvent('srp:legal:signContract', function(contractId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    MySQL.query('SELECT * FROM srp_contracts WHERE id = ?', { contractId }, function(rows)
        local c = rows and rows[1]
        if not c or c.status ~= 'pending' then
            TriggerClientEvent('QBCore:Notify', src, 'العقد غير موجود أو مغلق.', 'error') return
        end
        if c.expires_at < os.time() then
            MySQL.query('UPDATE srp_contracts SET status = "expired" WHERE id = ?', { contractId })
            TriggerClientEvent('QBCore:Notify', src, Lg.Messages.contractVoid, 'error') return
        end
        local isParty1 = c.party1 == cid
        local isParty2 = c.party2 == cid
        if not isParty1 and not isParty2 then
            TriggerClientEvent('QBCore:Notify', src, 'أنت لست طرفاً في العقد.', 'error') return
        end
        if isParty1 then MySQL.query('UPDATE srp_contracts SET sig1 = 1 WHERE id = ?', { contractId })
        else MySQL.query('UPDATE srp_contracts SET sig2 = 1 WHERE id = ?', { contractId }) end
        local sig1 = isParty1 and 1 or c.sig1
        local sig2 = isParty2 and 1 or c.sig2
        if sig1 == 1 and sig2 == 1 then
            MySQL.query('UPDATE srp_contracts SET status = "active" WHERE id = ?', { contractId })
            TriggerClientEvent('QBCore:Notify', src, Lg.Messages.contractDone, 'success')
            local other = getByCid(isParty1 and c.party2 or c.party1)
            if other then TriggerClientEvent('QBCore:Notify', other.PlayerData.source, Lg.Messages.contractDone, 'success') end
        else
            TriggerClientEvent('QBCore:Notify', src, Lg.Messages.contractSigned, 'success')
        end
    end)
end)

RegisterNetEvent('srp:legal:notaryService', function(serviceKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local svc = Lg.Sentencing.services[serviceKey]
    if not svc then return end
    if Player.Functions.GetMoney('bank') < svc.price then
        TriggerClientEvent('QBCore:Notify', src, Lg.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', svc.price, 'srp-notary')
    TriggerClientEvent('QBCore:Notify', src, ('%s — $%s'):format(svc.label, svc.price), 'success')
end)

RegisterNetEvent('srp:legal:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    loadLicense(cid, function(expiry)
        MySQL.query('SELECT * FROM srp_cases WHERE plaintiff = ? OR defendant = ? ORDER BY created DESC LIMIT 20',
            { cid, cid }, function(rows)
            TriggerClientEvent('srp:legal:show', src, {
                isLawyer = isLawyer(cid), licenseExpiry = Licenses[cid], cases = rows or [],
                caseTypes = Lg.CaseTypes, verdicts = Lg.Verdicts, services = Lg.Sentencing.services,
                job = Player.PlayerData.job.name,
            })
        end)
    end)
end)

RegisterNetEvent('srp:legal:requestOpenCases', function()
    local src = source
    local Player = getPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Lg.Settings.judgeJob then return end
    MySQL.query('SELECT * FROM srp_cases WHERE status = "filed" ORDER BY created ASC LIMIT 30', {}, function(rows)
        TriggerClientEvent('srp:legal:showOpenCases', src, rows or {})
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadLicense(Player.PlayerData.citizenid)
end)

CreateThread(function()
    ensureSchema()
    Wait(4000)
    loadAll()
    log('تم تحميل نظام المحاماة والمحكمة.')
end)
