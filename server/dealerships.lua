--[[
    fivem-strict-rp :: server/dealerships.lua
    منطق معارض السيارات — QBCore.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local D = Dealerships

local Stock       = {}
local DealerSales = {}
local DealerGrade = {}

local function log(msg) print(('[fivem-strict-rp][dealerships] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_dealer_progress` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY, `sales` INT NOT NULL DEFAULT 0,
        `grade` INT NOT NULL DEFAULT 0, `earned` INT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadDealer(citizenid, cb)
    MySQL.query('SELECT * FROM srp_dealer_progress WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1] or { sales = 0, grade = 0, earned = 0 }
        DealerSales[citizenid] = r.sales
        DealerGrade[citizenid] = r.grade
        if cb then cb(r) end
    end)
end

local function saveDealer(citizenid)
    MySQL.query([[INSERT INTO srp_dealer_progress (citizenid, sales, grade, earned) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE sales = VALUES(sales), grade = VALUES(grade), earned = VALUES(earned)]],
        { citizenid, DealerSales[citizenid] or 0, DealerGrade[citizenid] or 0, 0 })
end

local function initStock()
    for model, v in pairs(D.Vehicles) do Stock[model] = v.stock end
end
local function stockAvailable(model)
    local s = Stock[model]
    return s == nil or s > 0
end
local function consumeStock(model)
    if Stock[model] ~= nil then Stock[model] = Stock[model] - 1 end
end

RegisterNetEvent('srp:dealership:buy', function(dealerKey, model)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local veh = D.Vehicles[model]
    if not veh then
        TriggerClientEvent('QBCore:Notify', src, 'مركبة غير معروفة.', 'error') return
    end
    if not stockAvailable(model) then
        TriggerClientEvent('QBCore:Notify', src, D.Messages.outOfStock, 'error') return
    end
    local total = math.floor(veh.price * (1 + D.Settings.purchaseTaxPercent / 100)) + D.Settings.registrationFee
    local cash = Player.Functions.GetMoney('cash')
    local bank = Player.Functions.GetMoney('bank')
    if cash + bank < total then
        TriggerClientEvent('QBCore:Notify', src, D.Messages.noMoney, 'error') return
    end
    if bank >= total then
        Player.Functions.RemoveMoney('bank', total, 'srp-vehicle-purchase')
    else
        Player.Functions.RemoveMoney('bank', bank, 'srp-vehicle-purchase')
        Player.Functions.RemoveMoney('cash', total - bank, 'srp-vehicle-purchase')
    end
    local plate = QBCore.Functions.GeneratePlate()
    MySQL.insert([[INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
        { Player.PlayerData.license, Player.PlayerData.citizenid, model, GetHashKey(model), '{}', plate, 'pillboxgarage', 1 })
    consumeStock(model)
    TriggerClientEvent('QBCore:Notify', src, ('تم شراء %s بـ $%s (تسجيل: $%s)'):format(veh.label, veh.price, D.Settings.registrationFee), 'success')
end)

RegisterNetEvent('srp:dealership:tradeIn', function(plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid }, function(rows)
        local row = rows and rows[1]
        if not row then
            TriggerClientEvent('QBCore:Notify', src, D.Messages.noVehicle, 'error') return
        end
        local veh = D.Vehicles[row.vehicle]
        local base = veh and veh.price or 10000
        local offer = math.floor(base * 0.5)
        Player.Functions.AddMoney('bank', offer, 'srp-vehicle-tradein')
        MySQL.query('DELETE FROM player_vehicles WHERE plate = ?', { plate })
        TriggerClientEvent('QBCore:Notify', src, ('استبدلت المركبة بـ $%s'):format(offer), 'success')
    end)
end)

RegisterNetEvent('srp:dealership:requestStock', function(dealerKey)
    local src = source
    local dealer = D.List[dealerKey]
    if not dealer then return end
    local list = {}
    for model, v in pairs(D.Vehicles) do
        for _, cat in ipairs(dealer.categories) do
            if v.category == cat and stockAvailable(model) then
                list[#list+1] = { model = model, label = v.label, price = v.price }
                break
            end
        end
    end
    TriggerClientEvent('srp:dealership:showStock', src, dealerKey, list)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadDealer(Player.PlayerData.citizenid)
end)

CreateThread(function()
    ensureSchema()
    initStock()
    log('تم تحميل نظام المعارض.')
end)
