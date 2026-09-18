--[[
    fivem-strict-rp :: client/penalties.lua
    جهة العميل لنظام العقوبات: السجن + المطلوبون + الإشعارات.
    • إحداثيات مركز التوقيف ونقطة الإفراج تُقرأ من Penalties.Jail (config).
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- إحداثيات قابلة للتعديل من config (مع قيمة افتراضية آمنة)
local JAIL   = (Penalties and Penalties.Jail) or {}
local jailCoords = vector3(
    JAIL.coords and JAIL.coords.x or 1651.0,
    JAIL.coords and JAIL.coords.y or 2571.0,
    JAIL.coords and JAIL.coords.z or 45.5)
local releaseCoords = vector3(
    JAIL.release and JAIL.release.x or 425.1,
    JAIL.release and JAIL.release.y or -979.5,
    JAIL.release and JAIL.release.z or 30.7)
local escapeRadius = JAIL.escapeRadius or 35.0
local escapePenaltyMinutes = JAIL.escapePenaltyMinutes or 1

local isJailed = false
local jailUntil = 0
local jailReason = ''

-- ── السجن ────────────────────────────────────────────────────
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
    SetEntityCoords(ped, releaseCoords.x, releaseCoords.y, releaseCoords.z, false, false, false, true)
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
            if #(coords - jailCoords) > escapeRadius then
                SetEntityCoords(ped, jailCoords.x, jailCoords.y, jailCoords.z, false, false, false, true)
                TriggerEvent('chat:addMessage', { args = { '[المحكمة]', 'محاولة هروب! العقوبة تُمدد.' } })
                jailUntil = jailUntil + (escapePenaltyMinutes * 60)
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
        TriggerEvent('chat:addMessage', { args = { '[الشرطة]', ('أنت مطلوب! مستوى %s — سلّم نفسك.'):format(level) } })
    end
end)

RegisterNetEvent('srp:penalties:wantedClear', function(citizenid)
    if QBCore.Functions.GetPlayerData().citizenid == citizenid then
        TriggerEvent('chat:addMessage', { args = { '[الشرطة]', 'لم تعد مطلوباً.' } })
    end
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
