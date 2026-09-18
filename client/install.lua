--[[
    fivem-strict-rp :: client/install.lua
    جهة العميل للتركيب والتجميع: تأثير فعلي على المركبة + واجهات.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local I = Install
local S = Supply

local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function getClosestVehicle()
    local coords = GetEntityCoords(PlayerPedId())
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    return veh ~= 0 and veh or 0
end

local function getPlateOf(veh)
    return GetVehicleNumberPlateText(veh):gsub("%s+", "")
end

RegisterNetEvent('srp:install:applyEffect', function(plate, eff, install)
    if not eff then return end
    local veh = getClosestVehicle()
    if veh == 0 then notify('لا توجد مركبة قريبة.', 'error') return end
    SetVehicleModKit(veh, 0)
    if install then
        if eff.mod then
            for idx, val in pairs(eff.mod) do SetVehicleMod(veh, idx, val, false) end
        end
        if eff.turbo then SetVehicleHasBeenOwnedByPlayer(veh, true); ToggleVehicleMod(veh, 18, true) end
        if eff.engineHealth then
            local h = GetVehicleEngineHealth(veh)
            SetVehicleEngineHealth(veh, math.min(1000.0, h * eff.engineHealth))
        end
        if eff.tint then SetVehicleWindowTint(veh, eff.tint) end
        TriggerEvent('chat:addMessage', { args = { '[الورشة]', ('تم تركيب %s — الأداء تحسّن.'):format(eff.label) } })
    else
        if eff.mod then
            for idx, _ in pairs(eff.mod) do SetVehicleMod(veh, idx, -1, false) end
        end
        if eff.turbo then ToggleVehicleMod(veh, 18, false) end
        if eff.tint then SetVehicleWindowTint(veh, 0) end
    end
end)

local function openInstallMenu()
    local veh = getClosestVehicle()
    if veh == 0 then notify('لا توجد مركبة قريبة.', 'error') return end
    local plate = getPlateOf(veh)
    TriggerServerEvent('srp:install:requestInstallList', plate)
end

RegisterNetEvent('srp:install:showInstallList', function(plate, available)
    local items = {}
    for itemKey, qty in pairs(available) do
        local eff = I.Effects[itemKey]
        if eff and qty > 0 then
            items[#items+1] = {
                id = 'fit:' .. itemKey,
                title = (eff.label .. ' × ' .. qty),
                sub = ('الفئة: %s · +%s%% قوة'):format(eff.category, math.floor(((eff.power or 1) - 1) * 100)),
            }
        end
    end
    if #items == 0 then notify('لا تملك قطعاً قابلة للتركيب.', 'inform') return end
    SendNUIMessage({ action = 'openModal', title = 'تركيب قطعة — لوحة ' .. plate, items = items, foot = 'اختر قطعة للتركيب', callback = 'install:' .. plate })
    SetNuiFocus(true, true)
end)

local function openAssemblyMenu()
    local items = {}
    for key, rec in pairs(I.Assembly) do
        local partsStr = {}
        for item, n in pairs(rec.parts) do
            local nm = (S.MechanicCrafted[item] and S.MechanicCrafted[item].label)
                    or (S.Crafted[item] and S.Crafted[item].label) or item
            partsStr[#partsStr+1] = ('%s×%s'):format(nm, n)
        end
        items[#items+1] = {
            id = 'assemble:' .. key,
            title = (rec.icon .. ' ' .. rec.label),
            sub = 'الأجزاء: ' .. table.concat(partsStr, ' + '),
        }
    end
    SendNUIMessage({ action = 'openModal', title = 'تجميع المحركات والقير', items = items, foot = 'اختر ما تريد تجميعه من القطع', callback = 'assemble' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback:sub(1, 8) == 'install:' then
        local plate = callback:sub(9)
        if id:sub(1, 4) == 'fit:' then
            TriggerServerEvent('srp:install:fit', id:sub(5), plate)
        end
    elseif callback == 'assemble' then
        if id:sub(1, 9) == 'assemble:' then
            TriggerServerEvent('srp:install:assemble', id:sub(10))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('install', function() openInstallMenu() end, false)
RegisterCommand('assemble', function() openAssemblyMenu() end, false)
RegisterCommand('parts', function()
    local veh = getClosestVehicle()
    if veh == 0 then notify('لا توجد مركبة قريبة.', 'error') return end
    TriggerServerEvent('srp:install:requestFitted', getPlateOf(veh))
end, false)

RegisterNetEvent('srp:install:showFitted', function(plate, list, effects)
    if #list == 0 then notify('لا توجد قطع مركّبة على هذه المركبة.', 'inform') return end
    local items = {}
    for _, part in ipairs(list) do
        local eff = effects[part]
        items[#items+1] = { id = 'noop', title = (eff and eff.label or part), sub = (eff and eff.category or '') }
    end
    SendNUIMessage({ action = 'openModal', title = 'قطع مركّبة — ' .. plate, items = items, foot = 'القطع الحالية على المركبة', callback = 'none' })
    SetNuiFocus(true, true)
end)

print('[fivem-strict-rp][client] تم تحميل نظام التركيب والتجميع.')
