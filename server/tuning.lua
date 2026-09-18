--[[
    fivem-strict-rp :: server/tuning.lua
    الميكانيك العميق — بناء المكائن · البرمجة · الزيت · الداينو · التآكل
]]

local QBCore = exports['qb-core']:GetCoreObject()
local T = Tuning
local S = Supply

local Vehicles = {}
local function log(msg) print(('[fivem-strict-rp][tuning] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_vehicle_tuning` (
        `plate` VARCHAR(16) NOT NULL PRIMARY KEY, `engine` VARCHAR(24) NOT NULL DEFAULT 'stock',
        `sound` VARCHAR(24) NOT NULL DEFAULT 'stock', `chip` VARCHAR(24) NOT NULL DEFAULT 'stock',
        `oil_type` VARCHAR(24) NOT NULL DEFAULT 'oil_5000',
        `km_since_oil` DOUBLE NOT NULL DEFAULT 0, `odometer` DOUBLE NOT NULL DEFAULT 0,
        `wear` DOUBLE NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadVehicle(plate, cb)
    MySQL.query('SELECT * FROM srp_vehicle_tuning WHERE plate = ?', { plate }, function(rows)
        local r = rows and rows[1]
        Vehicles[plate] = {
            engine = r and r.engine or 'stock', sound = r and r.sound or 'stock',
            chip = r and r.chip or 'stock', oilType = r and r.oil_type or 'oil_5000',
            kmSinceOil = r and r.km_since_oil or 0, odometer = r and r.odometer or 0,
            wear = r and r.wear or 0,
        }
        if cb then cb(Vehicles[plate]) end
    end)
end

local function persist(plate)
    local v = Vehicles[plate]
    if not v then return end
    MySQL.query([[INSERT INTO srp_vehicle_tuning
        (plate, engine, sound, chip, oil_type, km_since_oil, odometer, wear)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE engine = VALUES(engine), sound = VALUES(sound),
        chip = VALUES(chip), oil_type = VALUES(oil_type), km_since_oil = VALUES(km_since_oil),
        odometer = VALUES(odometer), wear = VALUES(wear)]],
        { plate, v.engine, v.sound, v.chip, v.oilType, v.kmSinceOil, v.odometer, v.wear })
end

local function computeHp(plate)
    local v = Vehicles[plate]
    if not v then return 0, 0 end
    local eng = T.Engines[v.engine] or T.Engines.stock
    local chip = T.Chips[v.chip] or T.Chips.stock
    local wearFactor = 1.0
    if v.wear > 0 then wearFactor = math.max(0.5, 1.0 - (v.wear / 100)) end
    local hp = math.floor(eng.hp * chip.hpBonus * wearFactor)
    local torque = math.floor(eng.torque * chip.hpBonus * wearFactor)
    if hp > T.Settings.godmodeCap then hp = T.Settings.godmodeCap end
    return hp, torque
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
local function removeItem(Player, item, qty)
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty) end
end

RegisterNetEvent('srp:tuning:build', function(plate, engineKey, soundKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local eng = T.Engines[engineKey]
    if not eng then return end
    if T.Settings.requireMechanic and Player.PlayerData.job.name ~= 'mechanic' then
        TriggerClientEvent('QBCore:Notify', src, T.Messages.noMechanic, 'error') return
    end
    if T.Settings.requireOnDuty and not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    for item, need in pairs(eng.parts or {}) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, T.Messages.needParts, 'error') return
        end
    end
    local validSound = false
    for _, s in ipairs(eng.soundVariants) do if s == soundKey then validSound = true break end end
    if not validSound then soundKey = eng.soundVariants[1] end
    for item, need in pairs(eng.parts or {}) do removeItem(Player, item, need) end
    loadVehicle(plate, function(v)
        v.engine = engineKey
        v.sound = soundKey
        v.wear = 0
        v.kmSinceOil = 0
        persist(plate)
        local hp = select(1, computeHp(plate))
        TriggerClientEvent('srp:tuning:applyEngine', src, plate, engineKey, soundKey, hp)
        TriggerClientEvent('QBCore:Notify', src, ('تم بناء %s — الصوت: %s (%s حصان)'):format(eng.label, soundKey, hp), 'success')
    end)
end)

RegisterNetEvent('srp:tuning:chip', function(plate, chipKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local chip = T.Chips[chipKey]
    if not chip then return end
    if T.Settings.requireMechanic and Player.PlayerData.job.name ~= 'mechanic' then
        TriggerClientEvent('QBCore:Notify', src, T.Messages.noMechanic, 'error') return
    end
    loadVehicle(plate, function(v)
        v.chip = chipKey
        persist(plate)
        local hp = select(1, computeHp(plate))
        TriggerClientEvent('srp:tuning:applyEngine', src, plate, v.engine, v.sound, hp)
        TriggerClientEvent('QBCore:Notify', src, ('تم تطبيق %s (+%s%% قوة · استهلاك ×%s)'):format(chip.label, math.floor((chip.hpBonus - 1) * 100), chip.fuelMul), 'success')
    end)
end)

RegisterNetEvent('srp:tuning:changeOil', function(plate, oilKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local oil = T.Oil.types[oilKey]
    if not oil then return end
    loadVehicle(plate, function(v)
        v.oilType = oilKey
        v.kmSinceOil = 0
        v.wear = math.max(0, v.wear - 5)
        persist(plate)
        TriggerClientEvent('QBCore:Notify', src, ('تم تغيير %s (يكفي %s كم)'):format(oil.label, oil.durabilityKm), 'success')
    end)
end)

RegisterNetEvent('srp:tuning:dyno', function(plate)
    local src = source
    loadVehicle(plate, function(v)
        local hp, torque = computeHp(plate)
        local wearPct = math.max(0, math.floor(100 - v.wear))
        TriggerClientEvent('srp:tuning:dynoResult', src, {
            hp = hp, torque = torque, wear = wearPct,
            engine = v.engine, chip = v.chip, sound = v.sound,
            maxHp = T.Engines[v.engine] and T.Engines[v.engine].hp or 300,
        })
    end)
end)

RegisterNetEvent('srp:tuning:rebuild', function(plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    loadVehicle(plate, function(v)
        local cost = T.Maintenance.rebuildCost
        if Player.Functions.GetMoney('bank') < cost then
            TriggerClientEvent('QBCore:Notify', src, 'لا تملك المال الكافي ($' .. cost .. ').', 'error') return
        end
        Player.Functions.RemoveMoney('bank', cost, 'srp-tuning-rebuild')
        v.wear = math.max(0, v.wear - (100 * T.Maintenance.fullServiceRestore))
        persist(plate)
        TriggerClientEvent('QBCore:Notify', src, T.Messages.rebuilt, 'success')
    end)
end)

RegisterNetEvent('srp:tuning:updateKm', function(plate, kmDelta)
    local src = source
    local v = Vehicles[plate]
    if not v then
        loadVehicle(plate)
        return
    end
    kmDelta = tonumber(kmDelta) or 0
    if kmDelta <= 0 then return end
    v.odometer = v.odometer + kmDelta
    v.kmSinceOil = v.kmSinceOil + kmDelta
    local eng = T.Engines[v.engine] or T.Engines.stock
    local chip = T.Chips[v.chip] or T.Chips.stock
    local oil = T.Oil.types[v.oilType] or T.Oil.types.oil_5000
    local wearRate = T.Settings.baseWearPerKm * eng.wearRate * chip.wearMul
    if v.kmSinceOil > oil.durabilityKm then wearRate = wearRate * T.Oil.wearMulWhenOverdue end
    v.wear = math.min(100, v.wear + (wearRate * kmDelta))
    persist(plate)
    if v.kmSinceOil > oil.durabilityKm and math.random() < 0.1 then
        TriggerClientEvent('QBCore:Notify', src, T.Messages.overheating, 'error')
    end
    if v.wear > 70 and math.random() < 0.1 then
        TriggerClientEvent('QBCore:Notify', src, T.Messages.wornOut, 'error')
    end
end)

RegisterNetEvent('srp:tuning:request', function(plate)
    local src = source
    loadVehicle(plate, function(v)
        local hp, torque = computeHp(plate)
        TriggerClientEvent('srp:tuning:show', src, plate, v, {
            hp = hp, torque = torque, engines = T.Engines, chips = T.Chips, oils = T.Oil.types,
        })
    end)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل الميكانيك العميق.')
end)
