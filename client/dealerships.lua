--[[
    fivem-strict-rp :: client/dealerships.lua
    جهة العميل للمعارض: نقاط التفاعل + الشراء/الاستبدال.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local D = Dealerships

local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(4500)
    for key, dealer in pairs(D.List) do
        local b = AddBlipForCoord(dealer.coords.x, dealer.coords.y, dealer.coords.z)
        SetBlipSprite(b, dealer.blip.sprite) SetBlipColour(b, dealer.blip.color)
        SetBlipScale(b, 1.0) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(dealer.label)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for key, dealer in pairs(D.List) do
            local dist = #(coords - vector3(dealer.coords.x, dealer.coords.y, dealer.coords.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, dealer.coords.x, dealer.coords.y, dealer.coords.z - 1.0, 0,0,0, 0,0,0, 1.5,1.5,0.9, 241,196,15,140, false, true, 2, false)
                if dist < 2.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح المعرض')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:dealership:requestStock', key)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:dealership:showStock', function(dealerKey, list)
    if #list == 0 then notify('لا يوجد مخزون متاح.', 'inform') return end
    notify(('معرض %s — %s مركبة متاحة'):format(D.List[dealerKey].label, #list), 'primary')
    for _, v in ipairs(list) do
        notify(('%s : $%s — استخدم /buycar %s'):format(v.label, v.price, v.model), 'inform')
    end
end)

RegisterCommand('buycar', function(source, args)
    local model = args[1]
    if not model then notify('حدد موديل المركبة.', 'error') return end
    TriggerServerEvent('srp:dealership:buy', 'city', model)
end, false)

RegisterCommand('tradein', function(source, args)
    local plate = args[1]
    if not plate then notify('حدد اللوحة.', 'error') return end
    TriggerServerEvent('srp:dealership:tradeIn', plate)
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام المعارض.')
