--[[
    fivem-strict-rp :: server/farms.lua
    نظام المزرعة التفاعلي (بذور → نمو → حصاد → بيع).
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Businesses

local Plots = {}
local Harvest = {}
local OwnedFarms = {}

local function log(msg) print(('[fivem-strict-rp][farms] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_farm_plots` (
        `business_id` INT NOT NULL, `plot_index` INT NOT NULL,
        `crop` VARCHAR(24) NOT NULL, `planted_at` INT NOT NULL,
        `watered` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`business_id`, `plot_index`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadPlots()
    MySQL.query('SELECT * FROM srp_farm_plots', {}, function(rows)
        Plots = {}
        for _, r in ipairs(rows or {}) do
            Plots[r.business_id] = Plots[r.business_id] or {}
            Plots[r.business_id][r.plot_index] = { crop = r.crop, plantedAt = r.planted_at, watered = r.watered == 1 }
        end
    end)
end

RegisterNetEvent('srp:farm:registerOwnership', function(businessId)
    local Player = getPlayer(source)
    if not Player then return end
    OwnedFarms[Player.PlayerData.citizenid] = businessId
end)

local function getOwnedFarmId(cid) return OwnedFarms[cid] end

RegisterNetEvent('srp:farm:plant', function(plotIndex, crop)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local F = B.Farming
    local cropDef = F.crops[crop]
    if not cropDef then TriggerClientEvent('QBCore:Notify', src, 'محصول غير معروف.', 'error') return end
    local bizId = getOwnedFarmId(cid)
    if not bizId then TriggerClientEvent('QBCore:Notify', src, 'لا تملك مزرعة.', 'error') return end
    Plots[bizId] = Plots[bizId] or {}
    if Plots[bizId][plotIndex] then TriggerClientEvent('QBCore:Notify', src, B.Messages.plotBusy, 'error') return end
    if Player.Functions.GetMoney('cash') < F.seedCost then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك ثمن البذور ($' .. F.seedCost .. ').', 'error') return
    end
    Player.Functions.RemoveMoney('cash', F.seedCost, 'srp-farm-seed')
    local watered = not F.requiresWater
    Plots[bizId][plotIndex] = { crop = crop, plantedAt = os.time(), watered = watered }
    MySQL.query([[INSERT INTO srp_farm_plots (business_id, plot_index, crop, planted_at, watered)
        VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE crop = VALUES(crop), planted_at = VALUES(planted_at), watered = VALUES(watered)]],
        { bizId, plotIndex, crop, os.time(), watered and 1 or 0 })
    TriggerClientEvent('QBCore:Notify', src, ('زرعت %s — ينمو خلال %s دقيقة%s'):format(cropDef.label, cropDef.growMinutes, F.requiresWater and ' (يحتاج سقي)' or ''), 'success')
end)

RegisterNetEvent('srp:farm:water', function(plotIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local bizId = getOwnedFarmId(Player.PlayerData.citizenid)
    if not bizId or not Plots[bizId] or not Plots[bizId][plotIndex] then return end
    Plots[bizId][plotIndex].watered = true
    MySQL.query('UPDATE srp_farm_plots SET watered = 1 WHERE business_id = ? AND plot_index = ?', { bizId, plotIndex })
    TriggerClientEvent('QBCore:Notify', src, 'تم سقي الأرض.', 'success')
end)

RegisterNetEvent('srp:farm:harvest', function(plotIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local bizId = getOwnedFarmId(cid)
    if not bizId or not Plots[bizId] or not Plots[bizId][plotIndex] then
        TriggerClientEvent('QBCore:Notify', src, 'لا شيء لتحصده.', 'error') return
    end
    local plot = Plots[bizId][plotIndex]
    local cropDef = B.Farming.crops[plot.crop]
    if not cropDef then return end
    local elapsed = (os.time() - plot.plantedAt) / 60
    if elapsed < cropDef.growMinutes then
        local remaining = math.ceil(cropDef.growMinutes - elapsed)
        TriggerClientEvent('QBCore:Notify', src, ('لم ينضج بعد — باقي %s دقيقة.'):format(remaining), 'inform') return
    end
    if B.Farming.requiresWater and not plot.watered then
        TriggerClientEvent('QBCore:Notify', src, B.Messages.needWater, 'error') return
    end
    local qty = math.random(cropDef.yieldMin, cropDef.yieldMax)
    Harvest[cid] = Harvest[cid] or {}
    Harvest[cid][plot.crop] = (Harvest[cid][plot.crop] or 0) + qty
    Plots[bizId][plotIndex] = nil
    MySQL.query('DELETE FROM srp_farm_plots WHERE business_id = ? AND plot_index = ?', { bizId, plotIndex })
    TriggerClientEvent('QBCore:Notify', src, ('حصَدت %s × %s'):format(cropDef.label, qty), 'success')
    TriggerClientEvent('srp:farm:updateHarvest', src, Harvest[cid])
end)

RegisterNetEvent('srp:farm:sell', function(crop)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local cropDef = B.Farming.crops[crop]
    if not cropDef then return end
    local qty = (Harvest[cid] and Harvest[cid][crop]) or 0
    if qty <= 0 then TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذا المحصول.', 'error') return end
    local gross = cropDef.sellPrice * qty
    local tax = math.floor(gross * B.Settings.profitTaxPercent / 100)
    local net = gross - tax
    Player.Functions.AddMoney('bank', net, 'srp-farm-sell')
    Harvest[cid][crop] = 0
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s × %s: +$%s (ضريبة $%s)'):format(cropDef.label, qty, net, tax), 'success')
    TriggerClientEvent('srp:farm:updateHarvest', src, Harvest[cid])
end)

RegisterNetEvent('srp:farm:requestPlots', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local bizId = getOwnedFarmId(Player.PlayerData.citizenid)
    if not bizId then TriggerClientEvent('QBCore:Notify', src, 'لا تملك مزرعة.', 'error') return end
    local plots = Plots[bizId] or {}
    TriggerClientEvent('srp:farm:showPlots', src, plots, Harvest[Player.PlayerData.citizenid] or {})
end)

CreateThread(function()
    ensureSchema()
    Wait(3500)
    loadPlots()
    log('تم تحميل نظام المزارع.')
end)
