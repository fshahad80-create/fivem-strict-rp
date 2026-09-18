--[[
    fivem-strict-rp :: server/banks.lua
    البنوك المتقدم — بطاقات · تحويلات · قروض · استثمارات · عوائد يومية.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Banks

local Accounts = {}
local function log(msg) print(('[fivem-strict-rp][banks] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_bank_accounts` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `card` VARCHAR(16) NOT NULL DEFAULT 'classic',
        `credit_used` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_bank_loans` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `term` VARCHAR(16) NOT NULL, `principal` BIGINT NOT NULL,
        `remaining` BIGINT NOT NULL, `rate` INT NOT NULL, `months` INT NOT NULL,
        `paid` INT NOT NULL DEFAULT 0, `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_bank_invests` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `type` VARCHAR(16) NOT NULL, `amount` BIGINT NOT NULL,
        `placed_at` INT NOT NULL, `status` VARCHAR(12) NOT NULL DEFAULT 'active',
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadAccount(citizenid, cb)
    MySQL.query('SELECT * FROM srp_bank_accounts WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        Accounts[citizenid] = Accounts[citizenid] or { card = 'classic', creditUsed = 0, loans = {}, invests = {} }
        if r then
            Accounts[citizenid].card = r.card or 'classic'
            Accounts[citizenid].creditUsed = r.credit_used or 0
        end
        if cb then cb(Accounts[citizenid]) end
    end)
end

local function persistAccount(citizenid)
    local a = Accounts[citizenid]
    if not a then return end
    MySQL.query([[INSERT INTO srp_bank_accounts (citizenid, card, credit_used) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE card = VALUES(card), credit_used = VALUES(credit_used)]],
        { citizenid, a.card, a.creditUsed })
end

RegisterNetEvent('srp:banks:issueCard', function(tier)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local card = B.CardTiers[tier]
    if not card then return end
    local cid = Player.PlayerData.citizenid
    if Player.Functions.GetMoney('bank') < card.fee then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', card.fee, 'srp-bank-card')
    Accounts[cid] = Accounts[cid] or { card = tier, creditUsed = 0, loans = {}, invests = {} }
    Accounts[cid].card = tier
    persistAccount(cid)
    TriggerClientEvent('QBCore:Notify', src, ('أُصدرت %s (كاش باك %s%%)'):format(card.label, card.cashbackPercent), 'success')
end)

RegisterNetEvent('srp:banks:transfer', function(targetSrc, amount)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
    end
    local fee = math.floor(amount * B.Settings.transferFeePercent / 100)
    Player.Functions.RemoveMoney('bank', amount + fee, 'srp-bank-transfer')
    Target.Functions.AddMoney('bank', amount, 'srp-bank-transfer')
    local tname = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname
    TriggerClientEvent('QBCore:Notify', src, ('حُوّل $%s إلى %s (رسوم $%s)'):format(amount, tname, fee), 'success')
    TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('وصلك تحويل: $%s'):format(amount), 'success')
    local a = Accounts[Player.PlayerData.citizenid]
    local card = a and B.CardTiers[a.card]
    if card and card.cashbackPercent > 0 then
        local cb = math.floor(fee * card.cashbackPercent / 100)
        if cb > 0 then
            Player.Functions.AddMoney('bank', cb, 'srp-cashback')
            TriggerClientEvent('QBCore:Notify', src, ('كاش باك: +$%s'):format(cb), 'success')
        end
    end
end)

RegisterNetEvent('srp:banks:takeLoan', function(termKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local term = B.LoanTerms[termKey]
    if not term then return end
    local cid = Player.PlayerData.citizenid
    Accounts[cid] = Accounts[cid] or { card = 'classic', creditUsed = 0, loans = {}, invests = {} }
    local activeLoans = 0
    for _, l in ipairs(Accounts[cid].loans) do if not l.paid then activeLoans = activeLoans + 1 end end
    if activeLoans >= B.Settings.maxLoansPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.maxLoans, 'error') return
    end
    local total = math.floor(term.maxAmount * (1 + term.ratePercent / 100))
    local monthly = math.floor(total / term.months)
    MySQL.insert([[INSERT INTO srp_bank_loans (citizenid, term, principal, remaining, rate, months, paid)
        VALUES (?, ?, ?, ?, ?, ?, 0)]],
        { cid, termKey, term.maxAmount, total, term.ratePercent, term.months }, function(id)
        local loan = { id = id, principal = term.maxAmount, remaining = total, rate = term.ratePercent,
                       monthly = monthly, months = term.months, paid = 0, nextDue = os.time() + 7 * 86400 }
        table.insert(Accounts[cid].loans, loan)
        Player.Functions.AddMoney('bank', term.maxAmount, 'srp-loan')
        TriggerClientEvent('QBCore:Notify', src, ('حُصل على قرض: $%s على %s شهر (فائدة %s%%)'):format(term.maxAmount, term.months, term.ratePercent), 'success')
    end)
end)

RegisterNetEvent('srp:banks:repayLoan', function(loanId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local a = Accounts[cid]
    if not a then return end
    for _, loan in ipairs(a.loans) do
        if loan.id == loanId and not loan.paid then
            if Player.Functions.GetMoney('bank') < loan.monthly then
                TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
            end
            Player.Functions.RemoveMoney('bank', loan.monthly, 'srp-loan-repay')
            loan.remaining = loan.remaining - loan.monthly
            loan.paid = loan.paid + 1
            if loan.paid >= loan.months or loan.remaining <= 0 then loan.paid = true end
            MySQL.query('UPDATE srp_bank_loans SET remaining = ?, paid = ? WHERE id = ?',
                { math.max(0, loan.remaining), loan.paid, loanId })
            TriggerClientEvent('QBCore:Notify', src, ('تم سداد القسط ($%s)'):format(loan.monthly), 'success')
            return
        end
    end
end)

RegisterNetEvent('srp:banks:invest', function(invType, amount)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local inv = B.Investments[invType]
    if not inv then return end
    amount = tonumber(amount) or 0
    if amount < B.Settings.investMin or amount > B.Settings.investMax then
        TriggerClientEvent('QBCore:Notify', src, ('المبلغ يجب أن يكون بين $%s و $%s'):format(B.Settings.investMin, B.Settings.investMax), 'error') return
    end
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', amount, 'srp-invest')
    local cid = Player.PlayerData.citizenid
    MySQL.insert('INSERT INTO srp_bank_invests (citizenid, type, amount, placed_at) VALUES (?, ?, ?, ?)',
        { cid, invType, amount, os.time() })
    TriggerClientEvent('QBCore:Notify', src, ('استُثمر $%s في %s'):format(amount, inv.label), 'success')
end)

local function processDaily()
    MySQL.query('SELECT * FROM srp_bank_invests WHERE status = "active"', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            local inv = B.Investments[r.type]
            if inv and (os.time() - r.placed_at) >= inv.cycleHours * 3600 then
                local rate = inv.returnMin + math.random() * (inv.returnMax - inv.returnMin)
                local payout = math.floor(r.amount * (1 + rate))
                MySQL.query('UPDATE srp_bank_invests SET status = "paid" WHERE id = ?', { r.id })
                local P = QBCore.Functions.GetPlayerByCitizenId(r.citizenid)
                if P then
                    P.Functions.AddMoney('bank', payout, 'srp-invest-return')
                    TriggerClientEvent('QBCore:Notify', P.PlayerData.source, ('عائد استثمارك: $%s (%s%%)'):format(payout, math.floor(rate * 100)), 'success')
                end
            end
        end
    end)
end

CreateThread(function()
    ensureSchema()
    Wait(5000)
    while true do
        Wait(24 * 60 * 60 * 1000)
        processDaily()
    end
end)

RegisterNetEvent('srp:banks:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    loadAccount(cid, function(a)
        TriggerClientEvent('srp:banks:show', src, a, {
            cards = B.CardTiers, loans = B.LoanTerms, investments = B.Investments,
            balance = Player.Functions.GetMoney('bank'),
        })
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadAccount(Player.PlayerData.citizenid)
end)

CreateThread(function() log('تم تحميل نظام البنوك المتقدم.') end)
