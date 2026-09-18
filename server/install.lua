--[[
    fivem-strict-rp :: server/install.lua
    نظام التركيب والتجميع — مع دعم قطع التشليح (registerSalvagedPart / removeFromVehicle).
]]

local QBCore = exports['qb-core']:GetCoreObject()
local I = Install
local S = Supply

local Fitted = {}
local Perf   = {}
-- [citizenid] = { [itemKey] = quality } — القطع المُشلَّحة (من نظام التشليح)
local Salvaged = {}

local T_FITTED = 'srp_vehicle_parts'
local function log(msg) print(('[fivem-strict-rp][install] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_vehicle_parts` (
        `plate` VARCHAR(16) NOT NULL, `part` VARCHAR(32) NOT NULL,
        `category` VARCHAR(24) NOT NULL, `installed_by` VARCHAR(50) DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`plate`, `part`), INDEX `idx_plate` (`plate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadParts(plate, cb)
    MySQL.query('SELECT part, category FROM srp_vehicle_parts WHERE plate = ?', { plate }, function(rows)
        Fitted[plate] = Fitted[plate] or {}
        local list = {}
        for _, r in ipairs(rows or {}) do
            Fitted[plate][r.category] = r.part
            list[#list+1] = r.part
        end
        if cb then cb(list) end
    end)
end

local function persistPart(plate, part, category, byCid)
    MySQL.query([[INSERT INTO srp_vehicle_parts (plate, part, category, installed_by) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE part = VALUES(part), installed_by = VALUES(installed_by)]],
        { plate, part, category, byCid })
end

local function removePersist(plate, category)
    MySQL.query('DELETE FROM srp_vehicle_parts WHERE plate = ? AND category = ?', { plate, category })
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

RegisterNetEvent('srp:install:fit', function(itemKey, plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local eff = I.Effects[itemKey]
    if not eff then
        TriggerClientEvent('QBCore:Notify', src, 'قطعة غير معروفة.', 'error') return
    end
    if not plate or plate == '' then
        TriggerClientEvent('QBCore:Notify', src, I.Messages.noVehicle, 'error') return
    end
    Fitted[plate] = Fitted[plate] or {}
    if I.Settings.singlePerCategory and Fitted[plate][eff.category] then
        TriggerClientEvent('QBCore:Notify', src, I.Messages.alreadyFitted, 'error') return
    end
    if getQty(Player, itemKey) < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه القطعة.', 'error') return
    end
    if I.Settings.consumeOnInstall then removeItem(Player, itemKey, 1) end
    Fitted[plate][eff.category] = itemKey
    persistPart(plate, itemKey, eff.category, Player.PlayerData.citizenid)
    TriggerClientEvent('srp:install:applyEffect', src, plate, eff, true)
    TriggerClientEvent('QBCore:Notify', src, ('تم تركيب %s — الأداء تحسّن.'):format(eff.label), 'success')
end)

RegisterNetEvent('srp:install:remove', function(category, plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if not I.Settings.allowUninstall then return end
    Fitted[plate] = Fitted[plate] or {}
    local itemKey = Fitted[plate][category]
    if not itemKey then
        TriggerClientEvent('QBCore:Notify', src, 'لا توجد قطعة في هذه الفئة.', 'error') return
    end
    local eff = I.Effects[itemKey]
    Fitted[plate][category] = nil
    removePersist(plate, category)
    TriggerClientEvent('srp:install:applyEffect', src, plate, eff, false)
    TriggerClientEvent('QBCore:Notify', src, ('تم إزالة %s.'):format(eff and eff.label or category), 'success')
end)

-- ── تسجيل قطعة مُشلَّحة (يستدعيها نظام التشليح) ──────────────
RegisterNetEvent('srp:install:registerSalvagedPart', function(citizenid, item, quality)
    if not citizenid or not item then return end
    Salvaged[citizenid] = Salvaged[citizenid] or {}
    Salvaged[citizenid][item] = quality or 3
end)

-- ── إزالة قطعة من سيارة (يستدعيها نظام التشليح) ────────────
RegisterNetEvent('srp:install:removeFromVehicle', function(src, plate, category)
    if not src or not plate or not category then return end
    Fitted[plate] = Fitted[plate] or {}
    local itemKey = Fitted[plate][category]
    if not itemKey then return end
    local eff = I.Effects[itemKey]
    Fitted[plate][category] = nil
    removePersist(plate, category)
    TriggerClientEvent('srp:install:applyEffect', src, plate, eff, false)
end)

RegisterNetEvent('srp:install:assemble', function(recipeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local recipe = I.Assembly[recipeKey]
    if not recipe then return end
    if Player.PlayerData.job.name ~= 'mechanic' then
        TriggerClientEvent('QBCore:Notify', src, 'التجميع للميكانيكي فقط.', 'error') return
    end
    if not Player.PlayerData.job.onduty then
        TriggerClientEvent('QBCore:Notify', src, 'يجب أن تكون في الخدمة.', 'error') return
    end
    for item, need in pairs(recipe.parts) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, ('تنقصك: %s × %s'):format(item, need), 'error') return
        end
    end
    if recipe.tools then
        for tool, need in pairs(recipe.tools) do
            if getQty(Player, tool) < need then
                TriggerClientEvent('QBCore:Notify', src, I.Messages.missingTools, 'error') return
            end
        end
    end
    for item, need in pairs(recipe.parts) do removeItem(Player, item, need) end
    TriggerClientEvent('QBCore:Notify', src, ('جاري التجميع... (%s ثانية)'):format(recipe.time), 'inform')
    SetTimeout(recipe.time * 1000, function()
        local P = getPlayer(src)
        if not P then return end
        TriggerEvent('srp:supply:giveItem', src, recipeKey, 1)
        TriggerClientEvent('QBCore:Notify', src, ('تم تجميع %s بنجاح.'):format(recipe.label), 'success')
    end)
end)

RegisterNetEvent('srp:install:requestFitted', function(plate)
    local src = source
    loadParts(plate, function(list)
        TriggerClientEvent('srp:install:showFitted', src, plate, list, I.Effects)
    end)
end)

RegisterNetEvent('srp:install:requestInstallList', function(plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local available = {}
    for itemKey in pairs(I.Effects) do
        local q = getQty(Player, itemKey)
        if q > 0 then available[itemKey] = q end
    end
    TriggerClientEvent('srp:install:showInstallList', src, plate, available)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل نظام التركيب والتجميع.')
end)
