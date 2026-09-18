--[[
    fivem-strict-rp :: client/admin.lua
    تابلت الأدمن — لوحة موحّدة · أدوات · نقل حر.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local A = Admin

local adminOpen = false
local frozen = false
local noclip = false
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterCommand('admin', function()
    if adminOpen then
        adminOpen = false
        SendNUIMessage({ action = 'adminClose' })
        SetNuiFocus(false, false)
    else
        TriggerServerEvent('srp:admin:open')
    end
end, false)
RegisterKeyMapping('admin', 'تابلت الأدمن', 'keyboard', 'F10')

RegisterNetEvent('srp:admin:show', function(data)
    adminOpen = true
    SendNUIMessage({ action = 'adminOpen', sections = data.sections, tools = data.tools, playerName = data.playerName })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('srp:admin:showSection', function(sectionKey, rows)
    SendNUIMessage({ action = 'adminSection', section = sectionKey, rows = rows })
end)

RegisterNetEvent('srp:admin:teleportTo', function(targetSrc)
    local Target = GetPlayerFromServerId(targetSrc)
    if Target == -1 then notify('اللاعب غير موجود.', 'error') return end
    local coords = GetEntityCoords(GetPlayerPed(Target))
    SetEntityCoords(PlayerPedId(), coords.x + 1.0, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent('srp:admin:bringPlayer', function(targetSrc) end)

RegisterNetEvent('srp:admin:freeze', function()
    frozen = not frozen
    FreezeEntityPosition(PlayerPedId(), frozen)
    notify(frozen and '🧊 جُمّدت.' or 'أُلغي التجميد.', 'inform')
end)

RegisterNetEvent('srp:admin:revive', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    notify('💚 تم العلاج.', 'success')
end)

RegisterNetEvent('srp:admin:noclip', function()
    noclip = not noclip
    local ped = PlayerPedId()
    SetEntityInvincible(ped, noclip)
    SetPlayerInvincible(PlayerId(), noclip)
    notify(noclip and '🕊️ النقل الحر مُفعّل.' or 'أُلغي النقل الحر.', 'inform')
end)

CreateThread(function()
    while true do
        local sleep = 500
        if noclip then
            sleep = 0
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local speed = 2.0
            if IsControlPressed(0, 21) then speed = 6.0 end
            local forward = GetEntityForwardVector(ped)
            local x, y, z = coords.x, coords.y, coords.z
            if IsControlPressed(0, 32) then x = x + forward.x * speed; y = y + forward.y * speed end
            if IsControlPressed(0, 33) then x = x - forward.x * speed; y = y - forward.y * speed end
            if IsControlPressed(0, 34) then x = x - forward.y * speed; y = y + forward.x * speed end
            if IsControlPressed(0, 35) then x = x + forward.y * speed; y = y - forward.x * speed end
            if IsControlPressed(0, 44) then z = z + speed end
            if IsControlPressed(0, 38) then z = z - speed end
            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
        end
        Wait(sleep)
    end
end)

RegisterNUICallback('admin:section', function(data, cb)
    TriggerServerEvent('srp:admin:section', data.section)
    cb({ ok = true })
end)

RegisterNUICallback('admin:tool', function(data, cb)
    TriggerServerEvent('srp:admin:tool', data.tool, data.targetSrc, data.arg1, data.arg2)
    cb({ ok = true })
end)

RegisterNUICallback('admin:close', function(data, cb)
    adminOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

print('[fivem-strict-rp][client] تم تحميل تابلت الأدمن.')
