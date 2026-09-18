--[[
    fivem-strict-rp :: server/supply.lua
    سلسلة التوريد: منجم → حداد → ميكانيكي.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local S = Supply

local Internal = {}
local Crafting = {}

local function log(msg) print(('[fivem-strict-rp][supply] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_supply_stock` (
        `citizenid` VARCHAR(50) NOT NULL, `item` VARCHAR(32) NOT NULL,
        `qty` INT NOT NULL DEFAULT 0, PRIMARY KEY (`citizenid`, `item`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_supply_log` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `citizenid` VARCHAR(50) NOT NULL,
        `action` VARCHAR(24) NOT NULL, `item` VARCHAR(32) NOT NULL,
        `qty` INT NOT NULL, `value` INT NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadStock(citizenid, cb)
    MySQL.query('SELECT item, qty FROM srp_supply_stock WHERE citizenid = ?', { citizenid }, function(rows)
        Internal[citizenid] = {}
        for _, r in ipairs(rows or {}) do Internal[citizenid][r.item] = r.qty end
        if cb then cb(Internal[citizenid]) end
    end)
end

local function persistItem(citizenid, item)
    local qty = (Internal[citizenid] and Internal[citizenid][item]) or 0
    MySQL.query([[INSERT INTO srp_supply_stock (citizenid, item, qty) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE qty = VALUES(qty)]], { citizenid, item, qty })
end

local function logAction(citizenid, action, item, qty, value)
    MySQL.insert('INSERT INTO srp_supply_log (citizenid, action, item, qty, value) VALUES (?, ?, ?, ?, ?)',
        { citizenid, action, item, qty, value or 0 })
end

local function isQbItem(item)
    if S.Settings.inventoryMode == 'internal' then return false end
    if S.Settings.inventoryMode == 'qbcore' then return true end
    return QBCore.Shared.Items[item] ~= nil
end

local function getQty(Player, item)
    local cid = Player.PlayerData.citizenid
    if isQbItem(item) then
        local it = Player.Functions.GetItemByName(item)
        return it and it.amount or 0
    end
    return (Internal[cid] and Internal[cid][item]) or 0
end

local function addItem(Player, item, qty)
    local cid = Player.PlayerData.citizenid
    if isQbItem(item) then Player.Functions.AddItem(item, qty)
    else
        Internal[cid] = Internal[cid] or {}
        Internal[cid][item] = (Internal[cid][item] or 0) + qty
        persistItem(cid, item)
    end
end

local function removeItem(Player, item, qty)
    local cid = Player.PlayerData.citizenid
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty)
    else
        Internal[cid] = Internal[cid] or {}
        Internal[cid][item] = math.max(0, (Internal[cid][item] or 0) - qty)
        persistItem(cid, item)
    end
end

RegisterNetEvent('srp:supply:mine', function(oreKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local ore = S.Raw[oreKey]
    if not ore then return end
    if Player.PlayerData.job.name ~= 'miner' then
        TriggerClientEvent('QBCore:Notify', src, 'هذه ليست وظيفتك.', 'error') return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    local qty = math.random(1, 3)
    addItem(Player, oreKey, qty)
    logAction(Player.PlayerData.citizenid, 'mine', oreKey, qty, ore.baseValue * qty)
    TriggerClientEvent('QBCore:Notify', src, ('استخرجت %s × %s'):format(ore.label, qty), 'success')
end)

RegisterNetEvent('srp:supply:sellRaw', function(oreKey, qty)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local ore = S.Raw[oreKey]
    if not ore then return end
    qty = tonumber(qty) or getQty(Player, oreKey)
    if qty <= 0 or getQty(Player, oreKey) < qty then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه الكمية.', 'error') return
    end
    local value = math.floor(ore.baseValue * qty * 0.7)
    removeItem(Player, oreKey, qty)
    Player.Functions.AddMoney('cash', value, 'srp-supply-raw')
    logAction(Player.PlayerData.citizenid, 'sell_raw', oreKey, qty, value)
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s × %s بـ $%s'):format(ore.label, qty, value), 'success')
end)

RegisterNetEvent('srp:supply:craft', function(recipeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local recipe = S.Recipes[recipeKey]
    if not recipe then return end
    if Player.PlayerData.job.name ~= 'blacksmith' then
        TriggerClientEvent('QBCore:Notify', src, 'هذه ليست وظيفتك.', 'error') return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    for item, need in pairs(recipe.inputs) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, 'لا تملك المواد المطلوبة.', 'error') return
        end
    end
    if recipe.fuel and recipe.fuel > 0 and getQty(Player, 'coal') < recipe.fuel then
        TriggerClientEvent('QBCore:Notify', src, 'تحتاج فحماً للصهر.', 'error') return
    end
    for item, need in pairs(recipe.inputs) do removeItem(Player, item, need) end
    if recipe.fuel and recipe.fuel > 0 then removeItem(Player, 'coal', recipe.fuel) end
    local cid = Player.PlayerData.citizenid
    Crafting[cid] = { recipe = recipeKey, finishAt = os.time() + recipe.time }
    TriggerClientEvent('QBCore:Notify', src, ('جاري التصنيع... (%s ثانية)'):format(recipe.time), 'inform')
    SetTimeout(recipe.time * 1000, function()
        local P = getPlayer(src)
        if not P then return end
        addItem(P, recipe.output, recipe.outputQty)
        logAction(cid, 'craft', recipe.output, recipe.outputQty, recipe.outputQty * (S.Crafted[recipe.output] and S.Crafted[recipe.output].baseValue or 0))
        TriggerClientEvent('QBCore:Notify', src, ('صنعت %s × %s'):format(recipe.label, recipe.outputQty), 'success')
        Crafting[cid] = nil
    end)
end)

RegisterNetEvent('srp:supply:sellCrafted', function(itemKey, qty)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local crafted = S.Crafted[itemKey]
    if not crafted then return end
    qty = tonumber(qty) or getQty(Player, itemKey)
    if qty <= 0 or getQty(Player, itemKey) < qty then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه الكمية.', 'error') return
    end
    local gross = crafted.baseValue * qty
    local tax = math.floor(gross * S.Settings.salesTaxPercent / 100)
    local net = gross - tax
    removeItem(Player, itemKey, qty)
    Player.Functions.AddMoney('bank', net, 'srp-supply-crafted')
    logAction(Player.PlayerData.citizenid, 'sell_crafted', itemKey, qty, net)
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s × %s بـ $%s (ضريبة $%s)'):format(crafted.label, qty, net, tax), 'success')
end)

RegisterNetEvent('srp:supply:mechanicRepair', function(serviceKey, targetSrc)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local req = S.MechanicRequirements[serviceKey]
    if not req then return end
    for item, need in pairs(req.parts) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, ('تنقصك قطع: %s'):format(item), 'error') return
        end
    end
    for item, need in pairs(req.parts) do removeItem(Player, item, need) end
    local commission = math.floor(req.basePrice * 0.55)
    Player.Functions.AddMoney('bank', commission, 'srp-mechanic-commission')
    logAction(Player.PlayerData.citizenid, 'repair_use', serviceKey, 1, commission)
    TriggerClientEvent('srp:mechanic:doService', src, serviceKey, nil)
    TriggerClientEvent('QBCore:Notify', src, ('تم الإصلاح باستهلاك القطع — عمولتك $%s'):format(commission), 'success')
end)

RegisterNetEvent('srp:supply:requestStock', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local combined = {}
    for k in pairs(S.Raw) do local q = getQty(Player, k); if q > 0 then combined[k] = q end end
    for k in pairs(S.Crafted) do local q = getQty(Player, k); if q > 0 then combined[k] = q end end
    TriggerClientEvent('srp:supply:showStock', src, combined, { raw = S.Raw, crafted = S.Crafted, recipes = S.Recipes, job = Player.PlayerData.job.name })
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadStock(Player.PlayerData.citizenid)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل سلسلة التوريد.')
end)
