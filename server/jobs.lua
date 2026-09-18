--[[
    fivem-strict-rp :: server/jobs.lua
    منطق نظام الوظائف — QBCore.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local J = Jobs

local Cooldown    = {}
local Progress    = {}
local Carried     = {}

local function log(msg) print(('[fivem-strict-rp][jobs] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_job_progress` (
        `citizenid` VARCHAR(50) NOT NULL, `job` VARCHAR(32) NOT NULL,
        `tasks` INT NOT NULL DEFAULT 0, `grade` INT NOT NULL DEFAULT 0,
        `sold` INT NOT NULL DEFAULT 0, `earned` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`citizenid`, `job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadProgress(citizenid, job, cb)
    MySQL.query('SELECT * FROM srp_job_progress WHERE citizenid = ? AND job = ?', { citizenid, job }, function(rows)
        local rec = rows and rows[1] or { tasks = 0, grade = 0, sold = 0, earned = 0 }
        Progress[citizenid] = Progress[citizenid] or {}
        Progress[citizenid][job] = { count = rec.tasks, grade = rec.grade, sold = rec.sold, earned = rec.earned }
        if cb then cb(Progress[citizenid][job]) end
    end)
end

local function saveProgress(citizenid, job)
    local p = Progress[citizenid] and Progress[citizenid][job]
    if not p then return end
    MySQL.query([[INSERT INTO srp_job_progress (citizenid, job, tasks, grade, sold, earned)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE tasks = VALUES(tasks), grade = VALUES(grade),
        sold = VALUES(sold), earned = VALUES(earned)]],
        { citizenid, job, p.count, p.grade, p.sold, p.earned })
end

local function getGrade(job, idx)
    local list = J.List[job] and J.List[job].grades
    if not list then return { name = "عامل", multiplier = 1.0 } end
    return list[math.min(idx + 1, #list)] or list[1]
end

local function tryPromote(src, citizenid, job)
    if not J.Settings.autoPromote then return end
    local p = Progress[citizenid][job]
    local grades = J.List[job].grades
    local nextIdx = p.grade + 1
    if grades[nextIdx + 1] and p.count >= grades[nextIdx + 1].requirement then
        p.grade = nextIdx
        saveProgress(citizenid, job)
        TriggerClientEvent('QBCore:Notify', src, ('ترقية! رتبتك الجديدة: %s'):format(grades[nextIdx + 1].name), 'success')
    end
end

RegisterNetEvent('srp:jobs:hire', function(job)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if not J.List[job] and job ~= 'mechanic' and job ~= 'dealer' then
        TriggerClientEvent('QBCore:Notify', src, 'وظيفة غير معروفة.', 'error') return
    end
    local citizenid = Player.PlayerData.citizenid
    Player.Functions.SetJob(job, 0)
    loadProgress(citizenid, job, function(p)
        TriggerClientEvent('QBCore:Notify', src,
            ('تم تعيينك: %s (الرتبة: %s)'):format(J.List[job] and J.List[job].label or job, getGrade(job, p.grade).name), 'success')
    end)
end)

RegisterNetEvent('srp:jobs:toggleDuty', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local duty = not Player.PlayerData.job.onduty
    Player.Functions.SetJobDuty(duty)
    TriggerClientEvent('QBCore:Notify', src, duty and 'أنت الآن في الخدمة.' or 'أنت الآن خارج الخدمة.', duty and 'success' or 'inform')
end)

RegisterNetEvent('srp:jobs:completeTask', function(job)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local def = J.List[job]
    if not def then return end
    if Player.PlayerData.job.name ~= job then
        TriggerClientEvent('QBCore:Notify', src, J.Messages.notHired, 'error') return
    end
    if J.Settings.requireOnDuty and not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    if Cooldown[src] and (os.time() - Cooldown[src]) < J.Settings.cooldownSeconds then
        TriggerClientEvent('QBCore:Notify', src, J.Messages.cooldown, 'error') return
    end
    Cooldown[src] = os.time()

    local citizenid = Player.PlayerData.citizenid
    Progress[citizenid] = Progress[citizenid] or {}
    Progress[citizenid][job] = Progress[citizenid][job] or { count = 0, grade = 0, sold = 0, earned = 0 }

    Carried[citizenid] = Carried[citizenid] or {}
    Carried[citizenid][job] = (Carried[citizenid][job] or 0) + 1
    if Carried[citizenid][job] > J.Settings.maxCarry then
        Carried[citizenid][job] = J.Settings.maxCarry
        TriggerClientEvent('QBCore:Notify', src, J.Messages.full, 'error') return
    end

    local grade = getGrade(job, Progress[citizenid][job].grade)
    local instantCash = math.floor(def.instant.cash * grade.multiplier)
    Player.Functions.AddMoney('cash', instantCash, 'srp-job-instant')

    Progress[citizenid][job].count = Progress[citizenid][job].count + 1
    Progress[citizenid][job].earned = Progress[citizenid][job].earned + instantCash
    saveProgress(citizenid, job)
    tryPromote(src, citizenid, job)

    TriggerClientEvent('QBCore:Notify', src,
        ('أنجزت وحدة: +$%s · المحمول: %s/%s'):format(instantCash, Carried[citizenid][job], J.Settings.maxCarry), 'success')
    TriggerClientEvent('srp:jobs:updateCarry', src, job, Carried[citizenid][job])
end)

RegisterNetEvent('srp:jobs:sell', function(job)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local def = J.List[job]
    if not def then return end
    local citizenid = Player.PlayerData.citizenid
    local qty = (Carried[citizenid] and Carried[citizenid][job]) or 0
    if qty <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك موارد لبيعها.', 'error') return
    end
    local grade = getGrade(job, Progress[citizenid] and Progress[citizenid][job] and Progress[citizenid][job].grade or 0)
    local gross = math.floor(def.sell.cash * qty * grade.multiplier)
    local tax = math.floor(gross * J.Settings.salesTaxPercent / 100)
    local net = gross - tax
    Player.Functions.AddMoney('bank', net, 'srp-job-sell')
    Carried[citizenid][job] = 0
    if Progress[citizenid] and Progress[citizenid][job] then
        Progress[citizenid][job].sold = Progress[citizenid][job].sold + qty
        Progress[citizenid][job].earned = Progress[citizenid][job].earned + net
        saveProgress(citizenid, job)
    end
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s موارد: +$%s (ضريبة $%s)'):format(qty, net, tax), 'success')
    TriggerClientEvent('srp:jobs:updateCarry', src, job, 0)
end)

RegisterNetEvent('srp:jobs:requestProgress', function(job)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    loadProgress(citizenid, job, function(p)
        TriggerClientEvent('srp:jobs:showProgress', src, job, p, getGrade(job, p.grade))
    end)
end)

QBCore.Commands.Add('jobs', 'عرض تقدّمك في وظيفتك', {}, false, function(source)
    local Player = getPlayer(source)
    if not Player then return end
    local job = Player.PlayerData.job.name
    local def = J.List[job]
    if not def then
        TriggerClientEvent('QBCore:Notify', source, 'وظيفتك الحالية لا تدعم التقدّم.', 'primary') return
    end
    local citizenid = Player.PlayerData.citizenid
    loadProgress(citizenid, job, function(p)
        local g = getGrade(job, p.grade)
        TriggerClientEvent('QBCore:Notify', source,
            ('%s — %s | إنجازات: %s | محمول: %s'):format(def.label, g.name, p.count, (Carried[citizenid] and Carried[citizenid][job]) or 0), 'primary')
    end)
end, 'user')

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local job = Player.PlayerData.job.name
    if J.List[job] then loadProgress(Player.PlayerData.citizenid, job) end
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل نظام الوظائف.')
end)
