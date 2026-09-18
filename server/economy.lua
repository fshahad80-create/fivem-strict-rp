--[[
    fivem-strict-rp :: server/economy.lua
    منطق الاقتصاد الواقعي — QBCore
]]

local QBCore = exports['qb-core']:GetCoreObject()
local E = Economy

local InflationIndex = E.Inflation.baseline
local ShiftBonus     = {}
local DailyIncome    = {}

local function log(msg) print(('[fivem-strict-rp][economy] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_salary_log` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `job` VARCHAR(32) NOT NULL, `grade` INT NOT NULL, `gross` INT NOT NULL,
        `tax` INT NOT NULL, `net` INT NOT NULL, `bonus` INT NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_bills` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `type` VARCHAR(32) NOT NULL, `label` VARCHAR(64) NOT NULL, `amount` INT NOT NULL,
        `status` ENUM('unpaid','paid','overdue') NOT NULL DEFAULT 'unpaid',
        `due_at` INT NOT NULL, `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_cid` (`citizenid`), INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_inflation` (
        `id` INT NOT NULL PRIMARY KEY DEFAULT 1, `index_value` DECIMAL(6,4) NOT NULL DEFAULT 1.0000,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_insurance` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `premium` INT NOT NULL DEFAULT 0,
        `active` TINYINT(1) NOT NULL DEFAULT 1, `paid_until` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query('INSERT IGNORE INTO srp_inflation (id, index_value) VALUES (1, ?)', { E.Inflation.baseline })
end

local function loadInflation()
    MySQL.query('SELECT index_value FROM srp_inflation WHERE id = 1', {}, function(rows)
        if rows and rows[1] then InflationIndex = tonumber(rows[1].index_value) or E.Inflation.baseline end
    end)
end

local function persistInflation()
    MySQL.query('UPDATE srp_inflation SET index_value = ? WHERE id = 1', { InflationIndex })
end

local function inflatedPrice(base)
    if not E.Inflation.enabled then return base end
    return math.floor(base * InflationIndex)
end

local function incomeTaxPercent(gross)
    local t = E.Taxes.income
    if not t.enabled then return 0 end
    if t.brackets then
        for _, b in ipairs(t.brackets) do
            if b.upTo == nil or gross <= b.upTo then return b.percent end
        end
    end
    return t.percent or 0
end

local function computeSalaryTax(gross)
    local pct = incomeTaxPercent(gross)
    return math.floor(gross * pct / 100), pct
end

local function getJobSalaryData(Player)
    local jobName = Player.PlayerData.job.name
    local grade   = Player.PlayerData.job.grade.level or 0
    local cfg     = E.Salary.jobs[jobName] or E.Salary.jobs.unemployed
    local mult    = cfg.grades[grade] or cfg.grades[0] or 1.00
    return cfg, mult
end

local function paySalary(src)
    local Player = getPlayer(src)
    if not Player then return end
    if E.Salary.requireOnDuty and not Player.PlayerData.job.onduty then return end

    local citizenid = Player.PlayerData.citizenid
    local cfg, mult = getJobSalaryData(Player)
    local gross = math.floor(cfg.base * mult * (E.Inflation.affects.salaries and InflationIndex or 1.0))
    local tax, pct = computeSalaryTax(gross)

    local bonus = 0
    if E.Enabled.bonuses and ShiftBonus[citizenid] then
        local maxB = cfg.bonus and cfg.bonus.maxBonusPerShift or 0
        bonus = math.min(ShiftBonus[citizenid], maxB)
        ShiftBonus[citizenid] = 0
    end

    local today = os.date('%Y-%m-%d')
    DailyIncome[citizenid] = DailyIncome[citizenid] or { date = today, total = 0 }
    if DailyIncome[citizenid].date ~= today then DailyIncome[citizenid] = { date = today, total = 0 } end

    local net = math.max(0, gross - tax) + bonus
    if DailyIncome[citizenid].total + net > E.Salary.maxDailyIncome then
        net = math.max(0, E.Salary.maxDailyIncome - DailyIncome[citizenid].total)
    end
    DailyIncome[citizenid].total = DailyIncome[citizenid].total + net
    if net <= 0 then return end

    Player.Functions.AddMoney('bank', net, 'srp-salary')
    MySQL.insert([[INSERT INTO srp_salary_log (citizenid, job, grade, gross, tax, net, bonus)
        VALUES (?, ?, ?, ?, ?, ?, ?)]],
        { citizenid, Player.PlayerData.job.name, Player.PlayerData.job.grade.level, gross, tax, net, bonus })
    TriggerClientEvent('QBCore:Notify', src,
        ('راتبك: $%s (ضريبة $%s%s)'):format(net, tax, bonus > 0 and (' + بونص $' .. bonus) or ''), 'success')
end

RegisterNetEvent('srp:economy:addBonus', function(bonusType, amount)
    local Player = getPlayer(source)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    ShiftBonus[citizenid] = (ShiftBonus[citizenid] or 0) + (tonumber(amount) or 0)
end)

CreateThread(function()
    ensureSchema()
    Wait(3000)
    loadInflation()
    while true do
        Wait(E.Salary.payIntervalMinutes * 60 * 1000)
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do paySalary(src) end
    end
end)

local function issueBills(src)
    local Player = getPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    for _, billType in pairs(E.Bills.types) do
        local amount = inflatedPrice(billType.base)
        local dueAt = os.time() + (E.Taxes.latePayment.graceHours * 3600)
        MySQL.insert('INSERT INTO srp_bills (citizenid, type, label, amount, due_at) VALUES (?, ?, ?, ?, ?)',
            { citizenid, 'bill', billType.label, amount, dueAt })
        TriggerClientEvent('QBCore:Notify', src,
            ('فاتورة: %s — $%s (خلال %s ساعة)'):format(billType.label, amount, E.Taxes.latePayment.graceHours), 'inform')
    end
end

CreateThread(function()
    while true do
        Wait(E.Bills.intervalMinutes * 60 * 1000)
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do issueBills(src) end
    end
end)

CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        MySQL.query('SELECT * FROM srp_bills WHERE status = "unpaid" AND due_at < ?', { os.time() }, function(rows)
            for _, bill in ipairs(rows or {}) do
                local overdueAmount = math.floor(bill.amount * (1 + E.Taxes.latePayment.penaltyPercent / 100))
                MySQL.query('UPDATE srp_bills SET status = "overdue", amount = ? WHERE id = ?', { overdueAmount, bill.id })
                local Player = QBCore.Functions.GetPlayerByCitizenId(bill.citizenid)
                if Player then
                    Player.Functions.RemoveMoney('bank', overdueAmount, 'srp-bill-overdue')
                    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source,
                        ('فاتورة متأخرة: %s — غرامة $%s'):format(bill.label, overdueAmount), 'error')
                    if E.Taxes.latePayment.enabled then
                        TriggerEvent('srp:penalties:report', E.Taxes.latePayment.offenseKey, { officer = 'مصلحة الضرائب' })
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent('srp:economy:payBill', function(billId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    MySQL.query('SELECT * FROM srp_bills WHERE id = ? AND citizenid = ? AND status != "paid"', { billId, citizenid }, function(rows)
        local bill = rows and rows[1]
        if not bill then
            TriggerClientEvent('QBCore:Notify', src, 'الفاتورة غير موجودة أو مدفوعة.', 'error') return
        end
        if Player.Functions.GetMoney('bank') < bill.amount then
            TriggerClientEvent('QBCore:Notify', src, 'رصيدك البنكي لا يكفي.', 'error') return
        end
        Player.Functions.RemoveMoney('bank', bill.amount, 'srp-bill-paid')
        MySQL.query('UPDATE srp_bills SET status = "paid" WHERE id = ?', { bill.id })
        TriggerClientEvent('QBCore:Notify', src, ('تم سداد: %s'):format(bill.label), 'success')
    end)
end)

local function chargeInsurance()
    for _, src in ipairs(QBCore.Functions.GetPlayers()) do
        local Player = getPlayer(src)
        if Player then
            local premium = E.Insurance.premiumBase
            if Player.Functions.GetMoney('bank') >= premium then
                Player.Functions.RemoveMoney('bank', premium, 'srp-insurance')
            elseif E.Insurance.revokeLicenseOnDefault then
                TriggerEvent('srp:penalties:report', E.Insurance.defaultOffenseKey, { officer = 'شركة التأمين' })
            end
        end
    end
end

CreateThread(function()
    if not E.Enabled.insurance then return end
    while true do
        Wait(30 * 24 * 60 * 60 * 1000)
        chargeInsurance()
    end
end)

RegisterNetEvent('srp:economy:insuranceClaim', function(repairCost)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cost = tonumber(repairCost) or 0
    local coverage = E.Insurance.coverage.repairPercent
    local payout = math.min(math.floor(cost * coverage / 100), E.Insurance.coverage.maxPayoutPerClaim)
    if payout > 0 then
        Player.Functions.AddMoney('bank', payout, 'srp-insurance-claim')
        TriggerClientEvent('QBCore:Notify', src, ('التأمين غطّى $%s من الإصلاح.'):format(payout), 'success')
    end
end)

CreateThread(function()
    if not E.Enabled.inflation then return end
    while true do
        Wait(E.Inflation.cycleMinutes * 60 * 1000)
        if InflationIndex < E.Inflation.max then
            InflationIndex = math.min(E.Inflation.max, InflationIndex + E.Inflation.increasePerCycle)
            persistInflation()
            for _, src in ipairs(QBCore.Functions.GetPlayers()) do
                TriggerClientEvent('QBCore:Notify', src, ('مؤشر التضخم: %s%%'):format(math.floor(InflationIndex * 100)), 'inform')
            end
        end
    end
end)

QBCore.Commands.Add('inflation', 'عرض مؤشر التضخم الحالي', {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source, ('مؤشر التضخم: %s%%'):format(math.floor((InflationIndex or 1) * 100)), 'primary')
end, 'user')

QBCore.Commands.Add('setinflation', 'ضبط التضخم يدوياً', { { name = 'value', help = 'مثال 1.25' } }, false, function(source, args)
    if not E.Inflation.allowManualOverride then return end
    local v = tonumber(args[1])
    if not v or v < 1.0 or v > 3.0 then
        TriggerClientEvent('QBCore:Notify', source, 'قيمة غير صالحة (1.0 - 3.0).', 'error') return
    end
    InflationIndex = v
    persistInflation()
    TriggerClientEvent('QBCore:Notify', source, ('تم ضبط التضخم إلى %s%%'):format(math.floor(v * 100)), 'success')
end, 'admin')

QBCore.Commands.Add('bills', 'عرض فواتيرك غير المدفوعة', {}, false, function(source)
    local Player = getPlayer(source)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_bills WHERE citizenid = ? AND status != "paid" ORDER BY due_at ASC',
    { Player.PlayerData.citizenid }, function(rows)
        local list = {}
        for _, b in ipairs(rows or {}) do list[#list+1] = ('#%s %s — $%s'):format(b.id, b.label, b.amount) end
        TriggerClientEvent('QBCore:Notify', source, #list > 0 and table.concat(list, ' | ') or 'لا توجد فواتير مستحقة.', 'primary')
    end)
end, 'user')

log('تم تحميل نظام الاقتصاد الواقعي.')
