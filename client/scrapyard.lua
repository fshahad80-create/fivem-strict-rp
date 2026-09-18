--[[
    fivem-strict-rp :: client/scrapyard.lua
    تشليح المركبات — مناطق · تفاعل · بيع · حمولة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local Sc = Scrapyard

local myWorker = {}
local myOutputs = {}
local myBag = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function getClosestVehicle()
    local coords = GetEntityCoords(PlayerPedId())
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 8.0, 0, 71)
    return veh
end

CreateThread(function()
    Wait(7000)
    for _, loc in ipairs(Sc.Locations) do
        local b = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(b, loc.blip.sprite) SetBlipColour(b, loc.blip.color) SetBlipScale(b, 1.0) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(loc.label) EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        for _, loc in ipairs(Sc.Locations) do
            local dist = #(coords - vector3(loc.x, loc.y, loc.z))
            if dist < loc.radius then
                sleep = 0
                local veh = getClosestVehicle()
                if veh ~= 0 then
                    DrawMarker(1, loc.x, loc.y, loc.z - 1.0, 0,0,0, 0,0,0, 2.0,2.0,1.0, 231,76,60,120, false, true, 2, false)
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لتشليح المركبة')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1500 then
                        lastAction = GetGameTimer()
                        local netId = VehToNet(veh)
                        TriggerServerEvent('srp:scrapyard:dismantle', netId, GetVehicleEngineHealth(veh), GetVehicleBodyHealth(veh))
                        startDismantleAnim()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function startDismantleAnim()
    local ped = PlayerPedId()
    RequestAnimDict("mini@repair")
    local t = 0
    while not HasAnimDictLoaded("mini@repair") and t < 50 do Wait(50) t = t + 1 end
    TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, 3000, 0, 0, false, false, false)
end

RegisterNetEvent('srp:scrapyard:show', function(worker, outputs, settings, bag)
    myWorker = worker; myOutputs = outputs; myBag = bag
    openMainMenu()
end)

function openMainMenu()
    local items = {
        { id = 'sell', title = 'بيع القطع', sub = 'استرداد قيمة القطع المفكّكة' },
        { id = 'bag',  title = 'حمولتي', sub = 'عرض القطع التي حصلت عليها' },
    }
    local foot = ('مستوى التشليح: %s · مركبات مفكّكة: %s'):format(myWorker.level or 1, myWorker.dismantled or 0)
    SendNUIMessage({ action = 'openModal', title = 'التشليح', items = items, foot = foot, callback = 'scrapyard' })
    SetNuiFocus(true, true)
end

function openSellMenu()
    local items = {}
    for key, def in pairs(myOutputs) do
        items[#items+1] = { id = 'sellitem:' .. key, title = ('بيع ' .. def.label), sub = ('$%s/وحدة'):format(def.value), price = def.value }
    end
    SendNUIMessage({ action = 'openModal', title = 'بيع القطع', items = items, foot = 'بيع كل ما تملك', callback = 'scrapyard' })
    SetNuiFocus(true, true)
end

function openBagMenu()
    local items = {}
    for key, data in pairs(myBag) do
        local def = myOutputs[key]
        if def then items[#items+1] = { id = 'noop', title = (def.label .. ' × ' .. (data.qty or 0)), sub = ('جودة: %s★'):format(data.quality or 3) } end
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'الحمولة فارغة', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'حمولتي', items = items, foot = '', callback = 'none' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'scrapyard' then
        if id == 'sell' then openSellMenu()
        elseif id == 'bag' then openBagMenu()
        elseif id:sub(1, 9) == 'sellitem:' then TriggerServerEvent('srp:scrapyard:sell', id:sub(10))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('scrapyard', function() TriggerServerEvent('srp:scrapyard:request') end, false)
RegisterCommand('salvage', function() TriggerServerEvent('srp:scrapyard:request') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام تشليح المركبات.')
