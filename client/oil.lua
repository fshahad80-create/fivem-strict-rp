--[[
    fivem-strict-rp :: client/oil.lua
    النفط — استخراج · تكرير · إدارة المحطات.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local O = Oil

local myJob = nil
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function refreshJob()
    local pd = QBCore.Functions.GetPlayerData()
    myJob = pd.job and pd.job.name or nil
end
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job) myJob = job.name end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() refreshJob() end)

CreateThread(function()
    Wait(6500)
    for _, p in ipairs(O.Locations.oilfield.points) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 436) SetBlipColour(b, 5) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('حقل نفط — ' .. p.label) EndTextCommandSetBlipName(b)
    end
    for _, p in ipairs(O.Locations.refinery.points) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 436) SetBlipColour(b, 1) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('مصفاة النفط') EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(7000)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        refreshJob()
        if myJob == 'oilworker' then
            for _, p in ipairs(O.Locations.oilfield.points) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.4,1.4,0.9, 44,62,80,140, false, true, 2, false)
                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لاستخراج النفط')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 6000 then
                            lastAction = GetGameTimer()
                            TriggerServerEvent('srp:oil:extract')
                        end
                    end
                end
            end
            for _, p in ipairs(O.Locations.refinery.points) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.4,1.4,0.9, 230,126,34,140, false, true, 2, false)
                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح التكرير')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                            lastAction = GetGameTimer()
                            openRefineMenu()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openRefineMenu()
    local items = {}
    for key, rec in pairs(O.Recipes) do
        local inputsStr = {}
        for item, n in pairs(rec.inputs) do
            local nm = (O.Resources[item] and O.Resources[item].label) or item
            inputsStr[#inputsStr+1] = ('%s×%s'):format(nm, n)
        end
        items[#items+1] = { id = 'refine:' .. key, title = (rec.icon .. ' ' .. rec.label),
            sub = 'المواد: ' .. table.concat(inputsStr, ' + '), price = O.Settings.refineCost }
    end
    SendNUIMessage({ action = 'openModal', title = 'التكرير', items = items, foot = ('تكلفة التكرير: $%s'):format(O.Settings.refineCost), callback = 'oil' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:oil:show', function(list)
    local items = {}
    for _, s in ipairs(list) do
        local sub
        if s.mine then sub = ('مملوكة لك · مخزون %s لتر · $%s/لتر'):format(s.stock, s.price)
        elseif s.owner then sub = ('مملوكة · مخزون %s لتر · $%s/لتر'):format(s.stock, s.price)
        else sub = 'متاحة للشراء ($500,000)' end
        items[#items+1] = { id = 'station:' .. s.id, title = ('محطة ' .. s.label), sub = sub }
    end
    SendNUIMessage({ action = 'openModal', title = 'محطات الوقود', items = items, foot = 'اختر محطة', callback = 'oil' })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'oil' then
        if id:sub(1, 7) == 'refine:' then TriggerServerEvent('srp:oil:refine', id:sub(8))
        elseif id:sub(1, 8) == 'station:' then TriggerServerEvent('srp:oil:request')
        elseif id:sub(1, 9) == 'refuelst:' then TriggerServerEvent('srp:oil:refuel', tonumber(id:sub(10)), 50)
        elseif id:sub(1, 9) == 'setprice:' then notify(('استخدم: /oilprice %s [سعر]'):format(id:sub(10)), 'inform')
        elseif id:sub(1, 5) == 'pump:' then TriggerServerEvent('srp:oil:pumpFuel', tonumber(id:sub(6)))
        elseif id:sub(1, 7) == 'buyst:' then TriggerServerEvent('srp:oil:buyStation', tonumber(id:sub(8)))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('oil', function() TriggerServerEvent('srp:oil:request') end, false)
RegisterCommand('oilprice', function(source, args) TriggerServerEvent('srp:oil:setPrice', tonumber(args[1]), tonumber(args[2])) end, false)

print('[fivem-strict-rp][client] تم تحميل نظام النفط.')
