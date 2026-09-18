--[[
    fivem-strict-rp :: client/needs.lua
    حلقة الاحتياجات على العميل + التأثيرات الفعلية.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local N = Needs

local state = { hunger = 100, thirst = 100, energy = 100, hygiene = 100, health = 100 }
local collapsed = false
local lastSync = 0
local weatherEffects = { hunger = 1.0, thirst = 1.0, energy = 1.0 }
local harshEffects = {}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function applyThresholdEffects()
    local cfg = N.Thresholds
    local function check(value, thresholds, key)
        for i = #thresholds, 1, -1 do
            local t = thresholds[i]
            if value <= t.at then
                if t.effect == 'notify' then
                    if math.random() < 0.02 then TriggerEvent('QBCore:Notify', N.Messages[key] or t.label, 'error') end
                elseif t.effect == 'slowsprint' then
                    SetRunSprintMultiplierForPlayer(PlayerId(), t.severity or 0.7)
                elseif t.effect == 'damage' then
                    local ped = PlayerPedId()
                    local h = GetEntityHealth(ped)
                    if h > 110 then SetEntityHealth(ped, h - math.ceil(t.dps)) end
                elseif t.effect == 'collapse' then
                    if not collapsed then
                        collapsed = true
                        TriggerEvent('QBCore:Notify', N.Messages.collapsed, 'error')
                        local ped = PlayerPedId()
                        SetPedToRagdoll(ped, 6000, 6000, 0, true, true, false)
                        Wait(6000)
                        collapsed = false
                    end
                end
                return
            end
        end
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    end

    if N.Enabled.hunger then check(state.hunger, cfg.hunger, 'hungry') end
    if N.Enabled.thirst then check(state.thirst, cfg.thirst, 'thirsty') end
    if N.Enabled.energy then check(state.energy, cfg.energy, 'tired') end
    if N.Enabled.hygiene then check(state.hygiene, cfg.hygiene, 'dirty') end
end

CreateThread(function()
    if not N.Enabled.hunger and not N.Enabled.thirst then return end
    Wait(5000)
    while true do
        Wait(60000)
        local ped = PlayerPedId()
        if ped ~= 0 and not IsPauseMenuActive() then
            if N.Enabled.hunger then
                state.hunger = clamp(state.hunger - N.Rates.hunger.perMinute * (weatherEffects.hunger or 1.0), 0, 100)
            end
            if N.Enabled.thirst then
                state.thirst = clamp(state.thirst - N.Rates.thirst.perMinute * (weatherEffects.thirst or 1.0), 0, 100)
            end
            if N.Enabled.energy then
                local energyRate = N.Rates.energy.perMinute * (weatherEffects.energy or 1.0)
                if harshEffects.extraEnergyDrain then energyRate = energyRate + harshEffects.extraEnergyDrain end
                state.energy = clamp(state.energy - energyRate, 0, 100)
            end
            if N.Enabled.hygiene then
                state.hygiene = clamp(state.hygiene - N.Rates.hygiene.perMinute, 0, 100)
            end
            if N.Enabled.health then
                local drain = 0
                if state.hunger <= 0 then drain = drain + N.Rates.health.drainWhenStarving end
                if state.thirst <= 0 then drain = drain + N.Rates.health.drainWhenDehydrated end
                if state.energy <= 0 then drain = drain + N.Rates.health.drainWhenExhausted end
                if drain > 0 then
                    state.health = clamp(state.health - drain, 0, 100)
                    local h = GetEntityHealth(ped)
                    if h > 105 then SetEntityHealth(ped, h - math.ceil(drain)) end
                end
            end
            applyThresholdEffects()
            SendNUIMessage({
                action = 'updateNeeds',
                hunger = math.floor(state.hunger), thirst = math.floor(state.thirst),
                energy = math.floor(state.energy), hygiene = math.floor(state.hygiene),
            })
            if os.time() - lastSync > 300 then
                lastSync = os.time()
                TriggerServerEvent('srp:needs:sync', {
                    hunger = math.floor(state.hunger), thirst = math.floor(state.thirst),
                    energy = math.floor(state.energy), hygiene = math.floor(state.hygiene),
                    health = math.floor(state.health),
                })
            end
        end
    end
end)

RegisterNetEvent('srp:needs:consume', function(item)
    local c = N.Consumables.food[item]
    if not c then return end
    if c.hunger then state.hunger = clamp(state.hunger + c.hunger, 0, 100) end
    if c.thirst then state.thirst = clamp(state.thirst + c.thirst, 0, 100) end
    if c.energy then state.energy = clamp(state.energy + c.energy, 0, 100) end
    TriggerEvent('QBCore:Notify', 'تم تناوله.', 'success')
end)

RegisterNetEvent('srp:needs:sleep', function(minutes)
    local m = tonumber(minutes) or 5
    state.energy = clamp(state.energy + (N.Consumables.sleepPerMinute * m), 0, 100)
    TriggerEvent('QBCore:Notify', 'استيقظت وأنت مرتاح.', 'success')
end)

RegisterNetEvent('srp:needs:weather', function(weather)
    weatherEffects = (N.Weather.effects[weather]) or weatherEffects
    harshEffects = (N.Weather.harsh[weather]) or {}
    if harshEffects.slowsprint then SetRunSprintMultiplierForPlayer(PlayerId(), harshEffects.slowsprint) end
    SendNUIMessage({ action = 'setWeather', weather = weather })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('srp:needs:request')
end)

RegisterNetEvent('srp:needs:apply', function(data)
    if not data then return end
    state.hunger  = data.hunger  or 100
    state.thirst  = data.thirst  or 100
    state.energy  = data.energy  or 100
    state.hygiene = data.hygiene or 100
    state.health  = data.health  or 100
end)

print('[fivem-strict-rp][client] تم تحميل نظام الاحتياجات.')
