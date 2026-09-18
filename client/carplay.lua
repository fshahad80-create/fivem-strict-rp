--[[
    fivem-strict-rp :: client/carplay.lua
    الكار بلاي + قيادة ذاتية + تثبيت سرعة + مانع مفتاح T.
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
RegisterKeyMapping('carplay', 'فتح الكار بلاي', 'keyboard', CP.Settings.openKey)

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

RegisterNetEvent('srp:carplay:statusUpdate', function(plate, status) SendNUIMessage({ action = 'carplayStatus', status = status }) end)

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
    elseif act == 'autopilot' then
        if autopilot then stopAutopilot() else startAutopilot() end
    elseif act == 'cruise' then
        toggleCruise()
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

-- ══════════════ القيادة الذاتية ══════════════
local AP = CP.Autopilot
local autopilot = false
local autopilotSpeed = AP.defaultSpeed

function startAutopilot()
    local veh = getCurrentVehicle()
    if veh == 0 then notify('أنت لست داخل مركبة.', 'error') return end
    if GetVehicleEngineHealth(veh) < AP.minEngineHealth then
        notify('حالة المركبة منخفضة — القيادة الذاتية غير متاحة.', 'error') return
    end
    autopilot = true
    notify('🤖 القيادة الذاتية مُفعّلة — السرعة ' .. autopilotSpeed .. ' كم/س', 'success')
end

function stopAutopilot(reason)
    if not autopilot then return end
    autopilot = false
    notify('أُلغيت القيادة الذاتية' .. (reason and (': ' .. reason) or ''), 'inform')
end

CreateThread(function()
    while true do
        local sleep = 500
        if autopilot then
            sleep = 100
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
                stopAutopilot('خرجت من المركبة')
            else
                local coords = GetEntityCoords(veh)
                local forward = GetEntityForwardVector(veh)
                local ahead = vector3(coords.x + forward.x * AP.scanDistance, coords.y + forward.y * AP.scanDistance, coords.z)
                local obstacleDist = AP.scanDistance
                if AP.watchVehicles then
                    local found = GetClosestVehicle(ahead.x, ahead.y, ahead.z, AP.scanDistance, 0, 71)
                    if found and found ~= 0 and found ~= veh then
                        obstacleDist = math.min(obstacleDist, #(coords - GetEntityCoords(found)))
                    end
                end
                if AP.watchPeds then
                    local _, ped2 = GetClosestPed(ahead.x, ahead.y, ahead.z, AP.scanDistance, false, false, -1, false)
                    if ped2 and ped2 ~= 0 and ped2 ~= ped then
                        obstacleDist = math.min(obstacleDist, #(coords - GetEntityCoords(ped2)))
                    end
                end
                local target = autopilotSpeed / 3.6
                if obstacleDist <= AP.stopDistance then
                    SetVehicleForwardSpeed(veh, 0.0)
                elseif obstacleDist <= AP.brakeDistance then
                    local factor = (obstacleDist - AP.stopDistance) / (AP.brakeDistance - AP.stopDistance)
                    SetVehicleForwardSpeed(veh, target * factor)
                else
                    SetVehicleForwardSpeed(veh, target)
                end
                if IsControlJustPressed(0, 72) then stopAutopilot('فرملة يدوية') end
            end
        end
        Wait(sleep)
    end
end)

-- ══════════════ تثبيت السرعة ══════════════
local CC = CP.Cruise
local cruise = false
local cruiseSpeed = CC.defaultSpeed

function toggleCruise()
    local veh = getCurrentVehicle()
    if veh == 0 then notify('أنت لست داخل مركبة.', 'error') return end
    cruise = not cruise
    if cruise then
        cruiseSpeed = math.max(CC.minSpeed, math.floor(GetEntitySpeed(veh) * 3.6))
        notify('🎯 تثبيت السرعة: ' .. cruiseSpeed .. ' كم/س', 'success')
    else
        notify('أُلغي تثبيت السرعة.', 'inform')
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        if cruise then
            sleep = 100
            local veh = getCurrentVehicle()
            if veh == 0 then
                cruise = false
            else
                local target = cruiseSpeed / 3.6
                if IsControlPressed(0, 71) then SetVehicleForwardSpeed(veh, target) end
                if IsControlJustPressed(0, 10) then cruiseSpeed = math.min(CC.maxSpeed, cruiseSpeed + CC.step) end
                if IsControlJustPressed(0, 11) then cruiseSpeed = math.max(CC.minSpeed, cruiseSpeed - CC.step) end
                if IsControlJustPressed(0, 72) then cruise = false; notify('أُلغي تثبيت السرعة (فرملة).', 'inform') end
            end
        end
        Wait(sleep)
    end
end)

-- ══════════════ مانع انزلاق مفتاح T ══════════════
CreateThread(function()
    while true do
        local sleep = 500
        local AS = CP.AntiSlip
        if AS and AS.enabled then
            local veh = getCurrentVehicle()
            if veh ~= 0 then
                local speedKmh = math.floor(GetEntitySpeed(veh) * 3.6)
                if (not AS.onlyWhileDriving) or speedKmh >= AS.drivingSpeedKmh then
                    sleep = 0
                    DisableControlAction(0, AS.blockedControl, true)
                    DisableControlAction(0, 246, true)
                    DisableControlAction(0, 245, true)
                end
            end
        end
        Wait(sleep)
    end
end)

-- ── أوامر + مفاتيح ──────────────────────────────────────────
RegisterCommand('autopilot', function()
    if autopilot then stopAutopilot() else startAutopilot() end
end, false)
if AP.enabled and AP.key then RegisterKeyMapping('autopilot', 'القيادة الذاتية', 'keyboard', AP.key) end

RegisterCommand('cruise', function() toggleCruise() end, false)
if CC.enabled and CC.key then RegisterKeyMapping('cruise', 'تثبيت السرعة', 'keyboard', CC.key) end

print('[fivem-strict-rp][client] تم تحميل نظام الكار بلاي.')
