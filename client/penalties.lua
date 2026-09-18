--[[
    fivem-strict-rp :: client/penalties.lua
    واجهة العقوبات للعميل: السجن + المطلوبون + الإشعارات.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local isJailed = false
local jailUntil = 0
local jailReason = ''
local jailCoords = vector3(1651.0, 2571.0, 45.5)
local wantedActive = false

local function startJail(minutes, reason)
    isJailed = true
    jailReason = reason or 'حكم قضائي'
    jailUntil = os.time() + (minutes * 60)
    DoScreenFadeOut(800)
    Wait(900)
    local ped = PlayerPedId()
    SetEntityCoords(ped, jailCoords.x, jailCoords.y, jailCoords.z, false, false, false, true)
    SetEntityHeading(ped, 90.0)
    Wait(500)
    DoScreenFadeIn(800)
    TriggerEvent('chat:addMessage', { args = { '[المحكمة]', ('تم سجنك %s دقيقة — السبب: %s'):format(minutes, jailReason) } })
end

local function endJail()
    isJailed = false
    jailUntil = 0
    local ped = PlayerPedId()
    SetEntityCoords(ped, 425.1, -979.5, 30.7, false, false, false, true)
    DoScreenFadeIn(600)
    SendNUIMessage({ action = 'jailEnd' })
    TriggerEvent('chat:addMessage', { args = { '[المحكمة]', 'تم الإفراج عنك. غادر المنطقة.' } })
end

RegisterNetEvent('srp:penalties:jail', function(minutes, reason)
    startJail(minutes, reason)
end)

CreateThread(function()
    while true do
        if isJailed then
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if #(coords - jailCoords) > 35.0 then
                SetEntityCoords(ped, jailCoords.x, jailCoords.y, jailCoords.z, false, false, false, true)
                TriggerEvent('chat:addMessage', { args = { '[المحكمة]', 'محاولة هروب! العقوبة تُمدد.' } })
                jailUntil = jailUntil + 60
            end
            local remaining = jailUntil - os.time()
            if remaining <= 0 then
                endJail()
            else
                SendNUIMessage({
                    action = 'jailCountdown',
                    time = ('%02d:%02d'):format(math.floor(remaining / 60), remaining % 60),
                    reason = jailReason,
                })
            end
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent('srp:penalties:wanted', function(citizenid, level)
    if QBCore.Functions.GetPlayerData().citizenid == citizenid then
        wantedActive = true
        TriggerEvent('chat:addMessage', { args = { '[الشرطة]', ('أنت مطلوب! مستوى %s — سلّم نفسك.'):format(level) } })
    end
end)

RegisterNetEvent('srp:penalties:wantedClear', function(citizenid)
    if QBCore.Functions.GetPlayerData().citizenid == citizenid then wantedActive = false end
end)

RegisterNetEvent('srp:penalties:locate', function(citizenid, coords)
    local pd = QBCore.Functions.GetPlayerData()
    if pd.job and (pd.job.name == 'police' or pd.job.name == 'ambulance') then
        local key = 'srp_wanted_blip_' .. citizenid
        if not DoesBlipExist(GlobalState[key]) then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, 161) SetBlipColour(blip, 1) SetBlipScale(blip, 1.2) SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('مطلوب: ' .. citizenid) EndTextCommandSetBlipName(blip)
            GlobalState[key] = blip
        else
            SetBlipCoords(GlobalState[key], coords.x, coords.y, coords.z)
        end
    end
end)

print('[fivem-strict-rp][client] تم تحميل واجهة العقوبات.')
