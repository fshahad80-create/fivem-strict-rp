--[[
    fivem-strict-rp :: client/farms.lua
    جهة العميل للمزرعة: نقاط الزراعة/الحصاد + الواجهة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Businesses

local lastAction = 0
local myHarvest = {}
local localPlots = {}
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(6000)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local farm = B.Types.farm
        for idx, plot in ipairs(farm.plots) do
            local dist = #(coords - vector3(plot.x, plot.y, plot.z))
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, plot.x, plot.y, plot.z - 1.0, 0,0,0, 0,0,0, 1.4,1.4,0.8, 46,204,113,140, false, true, 2, false)
                if dist < 2.0 then
                    local state = localPlots[idx]
                    local label = state and 'اضغط ~INPUT_CONTEXT~ (مزروعة)' or 'اضغط ~INPUT_CONTEXT~ للزراعة'
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(label)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 800 then
                        lastAction = GetGameTimer()
                        if not state then openPlantMenu(idx) else TriggerServerEvent('srp:farm:harvest', idx) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openPlantMenu(plotIndex)
    local items = {}
    for key, crop in pairs(B.Farming.crops) do
        items[#items+1] = { id = 'plant:' .. plotIndex .. ':' .. key, title = crop.label, sub = ('ينمو %s دقيقة · محصول %s-%s'):format(crop.growMinutes, crop.yieldMin, crop.yieldMax), price = B.Farming.seedCost }
    end
    SendNUIMessage({ action = 'openModal', title = '🌱 اختر محصولاً', items = items, foot = 'ثمن البذرة: $' .. B.Farming.seedCost, callback = 'farm' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:farm:showPlots', function(plots, harvest)
    localPlots = plots or {}
    myHarvest = harvest or {}
    local items = {}
    for crop, qty in pairs(myHarvest) do
        if qty > 0 then
            local c = B.Farming.crops[crop]
            items[#items+1] = { id = 'sell:' .. crop, title = 'بيع ' .. (c and c.label or crop), sub = 'الكمية: ' .. qty, price = c and c.sellPrice or 0 }
        end
    end
    if #items == 0 then notify('لا محاصيل للبيع.', 'inform') return end
    SendNUIMessage({ action = 'openModal', title = '🌾 محاصيلك', items = items, foot = 'اختر محصولاً لبيعه', callback = 'farm' })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('srp:farm:updateHarvest', function(harvest) myHarvest = harvest or {} end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'farm' then
        local _, plotIndex, crop = id:match('^(%w+):(%d+):(%w+)$')
        if plotIndex and crop then
            TriggerServerEvent('srp:farm:plant', tonumber(plotIndex), crop)
        elseif id:sub(1, 5) == 'sell:' then
            TriggerServerEvent('srp:farm:sell', id:sub(6))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('farm', function() TriggerServerEvent('srp:farm:requestPlots') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام المزارع.')
