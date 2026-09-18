--[[
    fivem-strict-rp :: client/hunting.lua
    صيد البحر والبر — مناطق الصيد · الأدوات · البيع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local H = Hunting

local myTools = {}
local myCatch = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(7000)
    for _, z in ipairs(H.Locations.sea.zones) do
        local b = AddBlipForCoord(z.x, z.y, z.z)
        SetBlipSprite(b, 68) SetBlipColour(b, 3) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('صيد بحر — ' .. z.label) EndTextCommandSetBlipName(b)
    end
    for _, z in ipairs(H.Locations.land.zones) do
        local b = AddBlipForCoord(z.x, z.y, z.z)
        SetBlipSprite(b, 141) SetBlipColour(b, 2) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('صيد بر — ' .. z.label) EndTextCommandSetBlipName(b)
    end
    local sp = H.Locations.sea.sellPoint
    local b1 = AddBlipForCoord(sp.x, sp.y, sp.z)
    SetBlipSprite(b1, 500) SetBlipColour(b1, 2) SetBlipScale(b1, 0.9) SetBlipAsShortRange(b1, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('بيع الصيد (بوت)') EndTextCommandSetBlipName(b1)
    local rp = H.Locations.sea.restaurantPoint
    local b2 = AddBlipForCoord(rp.x, rp.y, rp.z)
    SetBlipSprite(b2, 500) SetBlipColour(b2, 5) SetBlipScale(b2, 0.9) SetBlipAsShortRange(b2, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('بيع الصيد (مطاعم)') EndTextCommandSetBlipName(b2)
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        for _, z in ipairs(H.Locations.sea.zones) do
            local dist = #(coords - vector3(z.x, z.y, z.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, z.x, z.y, z.z - 1.0, 0,0,0, 0,0,0, 1.6,1.6,0.9, 41,128,185,120, false, true, 2, false)
                if dist < 3.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لصيد السمك')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 3000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:hunting:fish')
                    end
                end
            end
        end
        for _, z in ipairs(H.Locations.land.zones) do
            local dist = #(coords - vector3(z.x, z.y, z.z))
            if dist < 35.0 then
                sleep = 0
                DrawMarker(1, z.x, z.y, z.z - 1.0, 0,0,0, 0,0,0, 1.8,1.8,0.9, 46,204,113,120, false, true, 2, false)
                if dist < 4.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ للصيد')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 3000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:hunting:hunt')
                    end
                end
            end
        end
        local sp = H.Locations.sea.sellPoint
        if #(coords - vector3(sp.x, sp.y, sp.z)) < 3.0 and IsControlJustReleased(0, 38) then
            sleep = 0
            TriggerServerEvent('srp:hunting:sell', 'bot')
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:hunting:show', function(tools, catch, allTools)
    myTools = tools or {}
    myCatch = catch or {}
    openHuntMenu()
end)

function openHuntMenu()
    local items = {
        { id = 'shop', title = 'متجر أدوات الصيد', sub = 'سنارة · بندقية (ترفع الجودة)' },
        { id = 'sell', title = 'بيع الغنائم', sub = 'السعر يرتفع مع الجودة' },
        { id = 'bag',  title = 'حمولتي', sub = 'عرض ما اصطدته' },
    }
    local seaTool = myTools.sea and (H.Tools[myTools.sea].label) or 'لا يوجد'
    local landTool = myTools.land and (H.Tools[myTools.land].label) or 'لا يوجد'
    SendNUIMessage({ action = 'openModal', title = 'الصيد', items = items,
        foot = ('سنارة: %s · بندقية: %s'):format(seaTool, landTool), callback = 'hunting' })
    SetNuiFocus(true, true)
end

local function openShop()
    local items = {}
    for key, t in pairs(H.Tools) do
        items[#items+1] = { id = 'buytool:' .. key, title = (t.icon .. ' ' .. t.label),
            sub = ('مستوى %s · جودة +%s%% · حجم +%s'):format(t.tier, math.floor(t.bonusQuality * 100), t.bonusYield), price = t.price }
    end
    SendNUIMessage({ action = 'openModal', title = 'متجر أدوات الصيد', items = items, foot = 'اختر أداة', callback = 'hunting' })
    SetNuiFocus(true, true)
end

local function openBag()
    local items = {}
    for key, data in pairs(myCatch) do
        local def = nil
        for _, f in ipairs(H.SeaCatch) do if f.key == key then def = f end end
        for _, a in ipairs(H.LandCatch) do if a.key == key then def = a end end
        if def then items[#items+1] = { id = 'noop', title = (def.icon .. ' ' .. def.label .. ' × ' .. data.qty), sub = ('الجودة: %s★'):format(data.quality) } end
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا شيء في الحمولة', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'حمولتي', items = items, foot = '', callback = 'none' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'hunting' then
        if id == 'shop' then openShop()
        elseif id == 'sell' then TriggerServerEvent('srp:hunting:sell', 'bot')
        elseif id == 'bag' then openBag()
        elseif id:sub(1, 8) == 'buytool:' then TriggerServerEvent('srp:hunting:buyTool', id:sub(9))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('hunt', function() TriggerServerEvent('srp:hunting:request') end, false)
RegisterCommand('fish', function() TriggerServerEvent('srp:hunting:fish') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام صيد البحر والبر.')
