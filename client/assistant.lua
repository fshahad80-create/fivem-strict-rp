--[[
    fivem-strict-rp :: client/assistant.lua
    المساعد الذكي — قائمة F3 · الشات · تحديد المواقع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local A = Assistant

local menuOpen = false
local placedBlips = {}
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterNetEvent('srp:assistant:showMenu', function(info)
    menuOpen = true
    SendNUIMessage({
        action = 'assistantMenu', name = info.name, job = info.job,
        cash = info.cash, bank = info.bank,
        questions = info.quickQuestions or {}, places = info.knowledge or {},
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('assistant:ask', function(data, cb)
    local q = data.question or ''
    if q ~= '' then ExecuteCommand('ask ' .. q) end
    cb({ ok = true })
end)

RegisterNUICallback('assistant:locate', function(data, cb)
    if data.key then TriggerServerEvent('srp:assistant:locate', data.key) end
    cb({ ok = true })
end)

RegisterNUICallback('assistant:close', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNetEvent('srp:assistant:setBlip', function(loc)
    local key = 'srp_assist_' .. (loc.key or loc.label)
    if placedBlips[key] then RemoveBlip(placedBlips[key]) end
    local b = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(b, 1) SetBlipColour(b, 5) SetBlipScale(b, 1.1) SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(loc.label or 'موقع')
    EndTextCommandSetBlipName(b)
    SetBlipRoute(b, true)
    SetBlipRouteColour(b, 5)
    placedBlips[key] = b
end)

RegisterNetEvent('srp:assistant:showLocations', function(list)
    local items = {}
    for _, l in ipairs(list) do
        items[#items+1] = { id = 'loc:' .. l.key, title = (l.label), sub = 'اضغط لتحديد الموقع على الخريطة' }
    end
    SendNUIMessage({ action = 'openModal', title = 'المواقع المهمة', items = items, foot = 'اختر موقعاً', callback = 'assistant' })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'assistant' and id:sub(1, 4) == 'loc:' then
        TriggerServerEvent('srp:assistant:locate', id:sub(5))
    end
    cb({ ok = true })
end)

RegisterCommand('locations', function() TriggerServerEvent('srp:assistant:requestLocations') end, false)
RegisterCommand('help', function() TriggerServerEvent('srp:assistant:requestMenu') end, false)
RegisterCommand('assistmenu', function() TriggerServerEvent('srp:assistant:requestMenu') end, false)
RegisterKeyMapping('assistmenu', 'قائمة المساعد F3', 'keyboard', 'F3')

print('[fivem-strict-rp][client] تم تحميل المساعد الذكي.')
