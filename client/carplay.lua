--[[
    fivem-strict-rp :: client/carplay.lua
    الكار بلاي — واجهة · راديو · ملاحة · كاميرا خلفية · إشارات.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local CP = Carplay

local carplayOpen = false
local currentPlate = nil
local backCamActive = false
local currentBackCam = nil
local navBlip = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function getCurrentVehicle()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    return veh ~= 0 and veh or 0
end
local function getPlateOf(veh) return GetVehicleNumberPlateText(veh):gsub("%s+", "") end

RegisterCommand('carplay', function()
    if carplayOpen then
        carplayOpen = false
        SendNUIMessage({ action = 'carplayClose' })
        SetNuiFocus(false, false)
        return
    end
    local veh = getCurrentVehicle()
    if veh == 0 then notify(CP.Messages.noVehicle, 'error') return end
    local plate = getPlateOf(veh)
    currentPlate = plate
    TriggerServerEvent('srp:carplay:open', plate, {
        fuel = GetVehicleFuelLevel(veh), engineHealth = GetVehicleEngineHealth(veh),
        bodyHealth = GetVehicleBodyHealth(veh), speed = math.floor(GetEntitySpeed(veh) * 3.6),
    })
end, false)
RegisterKeyMapping('carplay', 'فتح الكار بلاي', 'keyboard', 'F4')

RegisterNetEvent('srp:carplay:show', function(data)
    carplayOpen = true
    SendNUIMessage({ action = 'carplayOpen', plate = data.plate, stations = data.stations,
        controls = data.controls, session = data.session, vehData = data.vehData })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('srp:carplay:stationChanged', function(station) SendNUIMessage({ action = 'carplayStation', station = station }) end)
RegisterNetEvent('srp:carplay:volumeChanged', function(volume) SendNUIMessage({ action = 'carplayVolume', volume = volume }) end)

RegisterNetEvent('srp:carplay:navChanged', function(target)
    if navBlip then RemoveBlip(navBlip) end
    navBlip = AddBlipForCoord(target.x, target.y, target.z)
    SetBlipSprite(navBlip, 1) SetBlipColour(navBlip, 5) SetBlipRoute(navBlip, true) SetBlipRouteColour(navBlip, 5)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(target.label) EndTextCommandSetBlipName(navBlip)
end)

RegisterNetEvent('srp:carplay:doHazards', function(state)
    local veh = getCurrentVehicle()
    if veh == 0 then return end
    SetVehicleIndicatorLights(veh, 0, state and true or false)
    SetVehicleIndicatorLights(veh, 1, state and true or false)
end)

RegisterNetEvent('srp:carplay:statusUpdate', function(plate, status)
    SendNUIMessage({ action = 'carplayStatus', status = status })
end)

RegisterNUICallback('carplay:cam', function(data, cb)
    backCamActive = not backCamActive
    if backCamActive then
        local veh = getCurrentVehicle()
        if veh ~= 0 then
            local coords = GetOffsetFromEntityInWorldCoords(veh, 0.0, -6.0, 2.0)
            local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamCoord(cam, coords.x, coords.y, coords.z)
            PointCamAtEntity(cam, veh, 0.0, 0.0, 0.0, true)
            SetCamActive(cam, true)
            RenderScriptCams(true, false, 500, true, true)
            currentBackCam = cam
            CreateThread(function()
                while backCamActive and DoesCamExist(currentBackCam) do
                    Wait(0)
                    local c = GetOffsetFromEntityInWorldCoords(veh, 0.0, -6.0, 2.0)
                    SetCamCoord(currentBackCam, c.x, c.y, c.z)
                    PointCamAtCoord(currentBackCam, coords.x, coords.y, coords.z)
                end
            end)
        end
    else
        if currentBackCam and DoesCamExist(currentBackCam) then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(currentBackCam, true)
            currentBackCam = nil
        end
    end
    cb({ ok = true })
end)

RegisterNUICallback('carplay:action', function(data, cb)
    local act = data.action
    local plate = currentPlate
    if act == 'station' then TriggerServerEvent('srp:carplay:setStation', plate, data.stationId)
    elseif act == 'volume' then TriggerServerEvent('srp:carplay:setVolume', plate, data.volume)
    elseif act == 'nav' then TriggerServerEvent('srp:carplay:setNav', plate, data.x, data.y, data.z, data.label)
    elseif act == 'hazards' then TriggerServerEvent('srp:carplay:setHazards', plate, data.state)
    elseif act == 'engine' then
        local veh = getCurrentVehicle()
        if veh ~= 0 then SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), false, true) end
    elseif act == 'lock' then
        local veh = getCurrentVehicle()
        if veh ~= 0 then
            local locked = GetVehicleDoorLockStatus(veh) == 2
            SetVehicleDoorsLocked(veh, locked and 1 or 2)
        end
    elseif act == 'status' then TriggerServerEvent('srp:carplay:requestStatus', plate) end
    cb({ ok = true })
end)

RegisterNUICallback('carplay:close', function(data, cb)
    carplayOpen = false
    SetNuiFocus(false, false)
    if backCamActive then
        backCamActive = false
        if currentBackCam and DoesCamExist(currentBackCam) then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(currentBackCam, true)
            currentBackCam = nil
        end
    end
    cb({ ok = true })
end)

print('[fivem-strict-rp][client] تم تحميل نظام الكار بلاي.')
