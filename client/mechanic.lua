--[[
    fivem-strict-rp :: client/mechanic.lua
    جهة العميل للميكانيك: ورشة + تصنيع المحركات والقطع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local M = Jobs.Mechanic

local lastAction = 0
local activeRoute = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(4500)
    for _, g in ipairs(M.garages) do
        local b = AddBlipForCoord(g.x, g.y, g.z)
        SetBlipSprite(b, 446) SetBlipColour(b, 5) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(g.label)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, g in ipairs(M.garages) do
            local dist = #(coords - vector3(g.x, g.y, g.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, g.x, g.y, g.z - 1.0, 0,0,0, 0,0,0, 1.5,1.5,0.9, 230,126,34,140, false, true, 2, false)
                if dist < 2.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لخدمات الورشة')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:mechanic:requestGarages')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:mechanic:showGarages', function(garages, services)
    local items = {}
    for key, s in pairs(services) do
        items[#items+1] = { id = key, title = s.label, sub = ('مدة: %s دقيقة'):format(s.duration or 0), price = s.price }
    end
    items[#items+1] = { id = 'craftmenu', title = 'تصنيع قطع ومحركات', sub = 'محركات V6/V8/LS/Race · قير · دهان · قطع استهلاكية' }
    SendNUIMessage({ action = 'openModal', title = 'ورشة الميكانيك', items = items, foot = 'اختر خدمة أو تصنيعاً', callback = 'mechanic' })
    SetNuiFocus(true, true)
end)

local function openMechCraftMenu()
    local S = Supply
    local items = {}
    for key, rec in pairs(S.MechanicRecipes or {}) do
        local inputsStr = {}
        for item, n in pairs(rec.inputs) do
            local nm = (S.Raw[item] and S.Raw[item].label) or (S.Crafted[item] and S.Crafted[item].label) or item
            inputsStr[#inputsStr+1] = ('%s×%s'):format(nm, n)
        end
        local toolsStr = ''
        if rec.tools then
            for tool, n in pairs(rec.tools) do
                toolsStr = ' | أداة: ' .. ((S.Crafted[tool] and S.Crafted[tool].label) or tool) .. '×' .. n
            end
        end
        items[#items+1] = {
            id = 'mechcraft:' .. key,
            title = (rec.icon .. ' ' .. rec.label) .. (rec.tier and (' [T' .. rec.tier .. ']') or ''),
            sub = 'المواد: ' .. table.concat(inputsStr, ' + ') .. toolsStr,
        }
    end
    SendNUIMessage({ action = 'openModal', title = 'تصنيع الورشة', items = items, foot = 'اختر ما تريد تصنيعه', callback = 'mechanic' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:mechanic:doService', function(serviceKey, plate)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        local coords = GetEntityCoords(PlayerPedId())
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if veh == 0 then notify('لا توجد مركبة قريبة.', 'error') return end
    if serviceKey == 'repair' then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
    elseif serviceKey == 'bodywork' then
        SetVehicleDeformationFixed(veh)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
    elseif serviceKey == 'performance' then
        SetVehicleModKit(veh, 0)
        SetVehicleMod(veh, 11, 3, false)
        SetVehicleMod(veh, 12, 3, false)
        SetVehicleMod(veh, 13, 3, false)
    elseif serviceKey == 'inspection' then
        local engine = GetVehicleEngineHealth(veh)
        notify(('فحص: صحة المحرك %s%%'):format(math.floor(engine / 10)), 'primary')
    end
end)

RegisterNetEvent('srp:mechanic:incomingCall', function(callId, coords, callerName)
    notify(('استدعاء من %s — اكتب /acceptcall %s'):format(callerName, callId), 'inform')
end)

RegisterNetEvent('srp:mechanic:routeTo', function(coords)
    if activeRoute then RemoveBlip(activeRoute) end
    activeRoute = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(activeRoute, 1) SetBlipColour(activeRoute, 1)
    SetBlipRoute(activeRoute, true) SetBlipRouteColour(activeRoute, 1)
    notify('تم تحديد موقع العميل على الخريطة.', 'success')
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'service' then
        TriggerServerEvent('srp:mechanic:service', id, nil)
    elseif callback == 'mechanic' then
        if id == 'craftmenu' then
            openMechCraftMenu()
        elseif id:sub(1, 10) == 'mechcraft:' then
            TriggerServerEvent('srp:supply:craft', id:sub(11), true)
        else
            TriggerServerEvent('srp:mechanic:service', id, nil)
        end
    end
    cb({ ok = true })
end)

RegisterCommand('callmech', function() TriggerServerEvent('srp:mechanic:call') end, false)
RegisterCommand('acceptcall', function(source, args)
    local id = tonumber(args[1])
    if id then TriggerServerEvent('srp:mechanic:acceptCall', id) end
end, false)
RegisterCommand('service', function(source, args)
    local key = args[1]
    if not key then notify('حدد الخدمة (repair/bodywork/performance/inspection).', 'error') return end
    TriggerServerEvent('srp:mechanic:service', key, nil)
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الميكانيك.')
