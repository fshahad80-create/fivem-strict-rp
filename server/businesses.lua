--[[
    fivem-strict-rp :: server/businesses.lua
    منطق الأعمال: الملكية · التوظيف · الأرباح الدورية · الترقية.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Businesses

local Owned      = {}
local PlayerBiz  = {}

local T_BIZ     = 'srp_businesses'
local T_WORKERS = 'srp_business_workers'

local function log(msg) print(('[fivem-strict-rp][businesses] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function getPlayerByCid(cid) return QBCore.Functions.GetPlayerByCitizenId(cid) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_businesses` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `type` VARCHAR(24) NOT NULL,
        `owner` VARCHAR(50) NOT NULL, `level` INT NOT NULL DEFAULT 1,
        `earned` BIGINT NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_owner` (`owner`), INDEX `idx_type` (`type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_business_workers` (
        `business_id` INT NOT NULL, `citizenid` VARCHAR(50) NOT NULL,
        `role` VARCHAR(32) NOT NULL, `wage_earned` BIGINT NOT NULL DEFAULT 0,
        `since` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`business_id`, `citizenid`), INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadAllBusinesses()
    MySQL.query('SELECT * FROM srp_businesses', {}, function(rows)
        Owned = {}
        for _, r in ipairs(rows or {}) do
            Owned[r.id] = { owner = r.owner, type = r.type, level = r.level, workers = {} }
            PlayerBiz[r.owner] = r.id
        end
        MySQL.query('SELECT * FROM srp_business_workers', {}, function(wrows)
            for _, w in ipairs(wrows or {}) do
                if Owned[w.business_id] then Owned[w.business_id].workers[w.citizenid] = w.role end
            end
            log(('حُمّلت %s منشأة.'):format(#rows or 0))
        end)
    end)
end

local function countOwned(cid)
    local n = 0
    for _, b in pairs(Owned) do if b.owner == cid then n = n + 1 end end
    return n
end

RegisterNetEvent('srp:business:buy', function(bizType)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local def = B.Types[bizType]
    if not def then TriggerClientEvent('QBCore:Notify', src, 'نوع منشأة غير معروف.', 'error') return end
    if countOwned(Player.PlayerData.citizenid) >= B.Settings.maxOwnedPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.maxOwned, 'error') return
    end
    if Player.Functions.GetMoney('bank') < def.buyPrice then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', def.buyPrice, 'srp-business-buy')
    MySQL.insert('INSERT INTO srp_businesses (type, owner, level) VALUES (?, ?, 1)',
        { bizType, Player.PlayerData.citizenid }, function(id)
        Owned[id] = { owner = Player.PlayerData.citizenid, type = bizType, level = 1, workers = {} }
        PlayerBiz[Player.PlayerData.citizenid] = id
        TriggerClientEvent('QBCore:Notify', src, ('اشتريت %s بـ $%s'):format(def.label, def.buyPrice), 'success')
        TriggerClientEvent('srp:business:refresh', src)
    end)
end)

RegisterNetEvent('srp:business:sell', function(bizId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local biz = Owned[bizId]
    if not biz or biz.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.notOwner, 'error') return
    end
    local def = B.Types[biz.type]
    local refund = math.floor(def.buyPrice * 0.6)
    Player.Functions.AddMoney('bank', refund, 'srp-business-sell')
    MySQL.query('DELETE FROM srp_businesses WHERE id = ?', { bizId })
    MySQL.query('DELETE FROM srp_business_workers WHERE business_id = ?', { bizId })
    Owned[bizId] = nil
    PlayerBiz[Player.PlayerData.citizenid] = nil
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s بـ $%s'):format(def.label, refund), 'success')
end)

RegisterNetEvent('srp:business:upgrade', function(bizId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local biz = Owned[bizId]
    if not biz or biz.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.notOwner, 'error') return
    end
    if biz.level >= B.Settings.maxUpgradeLevel then
        TriggerClientEvent('QBCore:Notify', src, 'العمل في أقصى مستوى.', 'inform') return
    end
    local def = B.Types[biz.type]
    local cost = math.floor(def.buyPrice * 0.35 * biz.level)
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-business-upgrade')
    biz.level = biz.level + 1
    MySQL.query('UPDATE srp_businesses SET level = ? WHERE id = ?', { biz.level, bizId })
    TriggerClientEvent('QBCore:Notify', src, ('تم ترقية %s إلى المستوى %s'):format(def.label, biz.level), 'success')
end)

RegisterNetEvent('srp:business:hire', function(bizId, targetSrc, role)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    local biz = Owned[bizId]
    if not biz or biz.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.notOwner, 'error') return
    end
    local def = B.Types[biz.type]
    if not def.jobs[role] then
        TriggerClientEvent('QBCore:Notify', src, 'منصب غير معروف.', 'error') return
    end
    local count = 0
    for _, r in pairs(biz.workers) do if r == role then count = count + 1 end end
    if count >= def.jobs[role].maxWorkers then
        TriggerClientEvent('QBCore:Notify', src, 'المنصب ممتلئ.', 'error') return
    end
    local cid = Target.PlayerData.citizenid
    biz.workers[cid] = role
    MySQL.query([[INSERT INTO srp_business_workers (business_id, citizenid, role) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE role = VALUES(role)]], { bizId, cid, role })
    TriggerClientEvent('QBCore:Notify', src, ('تم توظيف %s في منصب %s'):format(cid, def.jobs[role].label), 'success')
    TriggerClientEvent('QBCore:Notify', targetSrc, ('تم توظيفك في %s'):format(def.label), 'success')
end)

RegisterNetEvent('srp:business:fire', function(bizId, targetCid)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local biz = Owned[bizId]
    if not biz or biz.owner ~= Player.PlayerData.citizenid then return end
    biz.workers[targetCid] = nil
    MySQL.query('DELETE FROM srp_business_workers WHERE business_id = ? AND citizenid = ?', { bizId, targetCid })
    TriggerClientEvent('QBCore:Notify', src, 'تم إنهاء عمل العامل.', 'success')
end)

local function payoutAll()
    local S = B.Settings
    for bizId, biz in pairs(Owned) do
        local def = B.Types[biz.type]
        local mult = def.upgrades[biz.level] or 1.0
        local gross = math.floor(def.baseIncome * mult)
        local maintenance = def.maintenance + math.floor(gross * S.maintenancePercent / 100)
        local tax = math.floor(gross * S.profitTaxPercent / 100)
        local workerTotal = 0
        for cid, role in pairs(biz.workers) do
            local jobCfg = def.jobs[role]
            local share = (jobCfg and jobCfg.share or S.employeeSharePercent)
            local wage = math.floor(gross * share / 100)
            workerTotal = workerTotal + wage
            local WP = getPlayerByCid(cid)
            if WP then
                WP.Functions.AddMoney('bank', wage, 'srp-business-wage')
                TriggerClientEvent('QBCore:Notify', WP.PlayerData.source, ('راتبك من %s: +$%s'):format(def.label, wage), 'success')
            end
        end
        local ownerNet = gross - maintenance - tax - workerTotal
        if ownerNet < 0 then ownerNet = 0 end
        local OP = getPlayerByCid(biz.owner)
        if OP then
            OP.Functions.AddMoney('bank', ownerNet, 'srp-business-profit')
            TriggerClientEvent('QBCore:Notify', OP.PlayerData.source,
                ('أرباح %s: +$%s (صيانة $%s · ضريبة $%s)'):format(def.label, ownerNet, maintenance, tax), 'success')
        end
    end
end

CreateThread(function()
    ensureSchema()
    Wait(3000)
    loadAllBusinesses()
    while true do
        Wait(B.Settings.payoutIntervalMinutes * 60 * 1000)
        payoutAll()
    end
end)

RegisterNetEvent('srp:business:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local mine = {}
    for id, biz in pairs(Owned) do
        if biz.owner == Player.PlayerData.citizenid then
            mine[#mine+1] = { id = id, type = biz.type, level = biz.level, workers = biz.workers }
        end
    end
    TriggerClientEvent('srp:business:show', src, mine, B.Types)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadAllBusinesses()
end)

log('تم تحميل نظام الأعمال.')
