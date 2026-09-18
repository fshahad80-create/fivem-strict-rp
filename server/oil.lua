--[[
    fivem-strict-rp :: server/oil.lua
    نظام النفط — استخراج · تكرير · محطات · تسعير.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local O = Oil
local S = Supply

local Cooldown = {}
local Stations = {}
local function log(msg) print(('[fivem-strict-rp][oil] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_oil_stations` (
        `id` INT NOT NULL PRIMARY KEY, `owner` VARCHAR(50) DEFAULT NULL,
        `stock` INT NOT NULL DEFAULT 0, `price` INT NOT NULL DEFAULT 25,
        `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadStations()
    MySQL.query('SELECT * FROM srp_oil_stations', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            Stations[r.id] = { owner = r.owner, stock = r.stock, price = r.price, earned = r.earned }
        end
    end)
end

local function persistStation(id)
    local s = Stations[id]
    if not s then return end
    MySQL.query([[INSERT INTO srp_oil_stations (id, owner, stock, price, earned) VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE owner = VALUES(owner), stock = VALUES(stock), price = VALUES(price), earned = VALUES(earned)]],
        { id, s.owner, s.stock, s.price, s.earned })
end

local function isQbItem(item)
    if S.Settings.inventoryMode == 'internal' then return false end
    if S.Settings.inventoryMode == 'qbcore' then return true end
    return QBCore.Shared.Items[item] ~= nil
end
local function getQty(Player, item)
    if isQbItem(item) then
        local it = Player.Functions.GetItemByName(item)
        return it and it.amount or 0
    end
    return 0
end
local function giveItem(src, item, qty) TriggerEvent('srp:supply:giveItem', src, item, qty) end
local function takeItem(Player, item, qty)
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty) end
end

RegisterNetEvent('srp:oil:extract', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.name ~= 'oilworker' then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.notOilworker, 'error') return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    if Cooldown[src] and (os.time() - Cooldown[src]) < O.Settings.extractCooldown then
        TriggerClientEvent('QBCore:Notify', src, 'انتظر قليلاً.', 'error') return
    end
    Cooldown[src] = os.time()
    local qty = math.random(2, 4)
    giveItem(src, 'crude_oil', qty)
    TriggerClientEvent('QBCore:Notify', src, ('استخرجت نفطاً خاماً × %s'):format(qty), 'success')
end)

RegisterNetEvent('srp:oil:refine', function(recipeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.name ~= 'oilworker' then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.notOilworker, 'error') return
    end
    local rec = O.Recipes[recipeKey]
    if not rec then return end
    for item, need in pairs(rec.inputs) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, ('تنقصك مواد: %s'):format(item), 'error') return
        end
    end
    if Player.Functions.GetMoney('cash') < O.Settings.refineCost then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('cash', O.Settings.refineCost, 'srp-oil-refine')
    for item, need in pairs(rec.inputs) do takeItem(Player, item, need) end
    TriggerClientEvent('QBCore:Notify', src, ('جاري التكرير... (%s ثانية)'):format(rec.time), 'inform')
    SetTimeout(rec.time * 1000, function()
        giveItem(src, rec.output, rec.outputQty)
        if rec.bonusOutput then giveItem(src, rec.bonusOutput, rec.bonusQty) end
        TriggerClientEvent('QBCore:Notify', src, ('كرّرت: %s × %s'):format(rec.output, rec.outputQty), 'success')
    end)
end)

RegisterNetEvent('srp:oil:buyStation', function(stationId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cfg = nil
    for _, s in ipairs(O.Stations) do if s.id == stationId then cfg = s end end
    if not cfg then return end
    if Stations[stationId] and Stations[stationId].owner then
        TriggerClientEvent('QBCore:Notify', src, 'المحطة مملوكة مسبقاً.', 'error') return
    end
    local cost = 500000
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-oil-station')
    Stations[stationId] = { owner = Player.PlayerData.citizenid, stock = 0, price = cfg.basePrice, earned = 0 }
    persistStation(stationId)
    TriggerClientEvent('QBCore:Notify', src, ('اشتريت %s بـ $%s'):format(cfg.label, cost), 'success')
end)

RegisterNetEvent('srp:oil:refuel', function(stationId, liters)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    liters = tonumber(liters) or 0
    if liters <= 0 then return end
    local station = Stations[stationId]
    if not station or station.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.notOwner, 'error') return
    end
    local haveFuel = getQty(Player, 'refined_fuel') + getQty(Player, 'diesel')
    if haveFuel < liters then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك وقوداً كافياً للتزويد.', 'error') return
    end
    local remaining = liters
    local rf = getQty(Player, 'refined_fuel')
    local take = math.min(rf, remaining)
    if take > 0 then takeItem(Player, 'refined_fuel', take); remaining = remaining - take end
    if remaining > 0 then takeItem(Player, 'diesel', remaining) end
    station.stock = station.stock + liters
    persistStation(stationId)
    TriggerClientEvent('QBCore:Notify', src, ('زُوّدت المحطة بـ %s لتر'):format(liters), 'success')
end)

RegisterNetEvent('srp:oil:setPrice', function(stationId, price)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    price = tonumber(price) or 0
    local station = Stations[stationId]
    if not station or station.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.notOwner, 'error') return
    end
    if price < O.Settings.minPricePerLiter or price > O.Settings.maxPricePerLiter then
        TriggerClientEvent('QBCore:Notify', src, ('السعر يجب أن يكون بين $%s و $%s'):format(O.Settings.minPricePerLiter, O.Settings.maxPricePerLiter), 'error') return
    end
    station.price = price
    persistStation(stationId)
    TriggerClientEvent('QBCore:Notify', src, ('تم ضبط سعر اللتر: $%s'):format(price), 'success')
end)

RegisterNetEvent('srp:oil:pumpFuel', function(stationId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local station = Stations[stationId]
    if not station then return end
    if station.stock < 10 then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.stationLow, 'error') return
    end
    local liters = 30
    local cost = math.floor(liters * station.price)
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, O.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-fuel')
    station.stock = station.stock - liters
    if station.owner then
        local owner = QBCore.Functions.GetPlayerByCitizenId(station.owner)
        local profit = math.floor(cost * 0.7)
        if owner then owner.Functions.AddMoney('bank', profit, 'srp-oil-profit')
        else MySQL.query('UPDATE players SET bank = bank + ? WHERE citizenid = ?', { profit, station.owner }) end
        station.earned = station.earned + profit
    end
    persistStation(stationId)
    TriggerClientEvent('QBCore:Notify', src, ('عُبّئت بـ %s لتر ($%s)'):format(liters, cost), 'success')
end)

RegisterNetEvent('srp:oil:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local list = {}
    for _, cfg in ipairs(O.Stations) do
        local s = Stations[cfg.id] or {}
        list[#list+1] = {
            id = cfg.id, label = cfg.label, owner = s.owner,
            stock = s.stock or 0, price = s.price or cfg.basePrice,
            mine = s.owner == Player.PlayerData.citizenid,
        }
    end
    TriggerClientEvent('srp:oil:show', src, list)
end)

CreateThread(function()
    ensureSchema()
    Wait(3500)
    loadStations()
    log('تم تحميل نظام النفط.')
end)
