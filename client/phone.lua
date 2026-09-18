--[[
    fivem-strict-rp :: client/phone.lua
    تطبيقات الجوال — فتح F2 / /phone · واجهة موحّدة · blip موقع المركبة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local P = Phone

local phoneOpen = false
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterCommand('phone', function()
    if phoneOpen then
        phoneOpen = false
        SendNUIMessage({ action = 'phoneClose' })
        SetNuiFocus(false, false)
    else
        TriggerServerEvent('srp:phone:open')
    end
end, false)
RegisterKeyMapping('phone', 'فتح الجوال', 'keyboard', 'F2')

RegisterNetEvent('srp:phone:show', function(data)
    phoneOpen = true
    SendNUIMessage({ action = 'phoneOpen', apps = data.apps, cash = data.cash, bank = data.bank, charinfo = data.charinfo })
    SetNuiFocus(true, true)
end)

local vehBlip = nil
RegisterNetEvent('srp:phone:vehicleBlip', function(plate)
    local pool = GetGamePool and GetGamePool('CVehicle') or {}
    for _, veh in ipairs(pool) do
        local p = GetVehicleNumberPlateText(veh):gsub("%s+", "")
        if p:upper() == plate:upper() then
            if vehBlip then RemoveBlip(vehBlip) end
            vehBlip = AddBlipForEntity(veh)
            SetBlipSprite(vehBlip, 225) SetBlipColour(vehBlip, 3) SetBlipScale(vehBlip, 1.0) SetBlipAsShortRange(vehBlip, false)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('مركبتي: ' .. plate) EndTextCommandSetBlipName(vehBlip)
            return
        end
    end
    notify('المركبة ليست في الجوار.', 'inform')
end)

RegisterNetEvent('srp:phone:showDocs', function(rows, types) SendNUIMessage({ action = 'phonePanel', screen = 'absher_docs', rows = rows, types = types }) end)
RegisterNetEvent('srp:phone:showFines', function(rows) SendNUIMessage({ action = 'phonePanel', screen = 'absher_fines', rows = rows }) end)
RegisterNetEvent('srp:phone:showNajiz', function(contracts, cases) SendNUIMessage({ action = 'phonePanel', screen = 'najiz', contracts = contracts, cases = cases }) end)
RegisterNetEvent('srp:phone:showMeda', function(terminals) SendNUIMessage({ action = 'phonePanel', screen = 'meda', terminals = terminals }) end)
RegisterNetEvent('srp:phone:showAuctions', function(auctions) SendNUIMessage({ action = 'phonePanel', screen = 'mazadi', auctions = auctions }) end)
RegisterNetEvent('srp:phone:showOrders', function(orders) SendNUIMessage({ action = 'phonePanel', screen = 'atlebni', orders = orders }) end)

RegisterNUICallback('phone:action', function(data, cb)
    local app = data.app
    local act = data.action
    if app == 'absher' then
        if act == 'docs' then TriggerServerEvent('srp:phone:absherDocs')
        elseif act == 'fines' then TriggerServerEvent('srp:phone:absherFines')
        elseif act == 'locate' then TriggerServerEvent('srp:phone:locateVehicle', data.plate) end
    elseif app == 'najiz' then TriggerServerEvent('srp:phone:najizData')
    elseif app == 'meda' then
        if act == 'list' then TriggerServerEvent('srp:phone:medaData')
        elseif act == 'create' then TriggerServerEvent('srp:phone:createTerminal', data.name)
        elseif act == 'link' then TriggerServerEvent('srp:phone:linkTerminal', data.terminalId, data.businessName) end
    elseif app == 'mazadi' then
        if act == 'list' then TriggerServerEvent('srp:phone:auctionList')
        elseif act == 'create' then TriggerServerEvent('srp:phone:createAuction', data.title, data.category, data.startPrice)
        elseif act == 'bid' then TriggerServerEvent('srp:phone:bidAuction', data.auctionId, data.amount) end
    elseif app == 'atlebni' then
        if act == 'list' then TriggerServerEvent('srp:phone:orderList')
        elseif act == 'create' then TriggerServerEvent('srp:phone:createOrder', data.category, data.title, data.qty, data.budget)
        elseif act == 'offer' then TriggerServerEvent('srp:phone:offerOnOrder', data.orderId, data.price, data.note)
        elseif act == 'accept' then TriggerServerEvent('srp:phone:acceptOffer', data.orderId, data.offerIndex) end
    end
    cb({ ok = true })
end)

RegisterNUICallback('phone:dispute', function(data, cb)
    TriggerServerEvent('srp:phone:disputeFine', data.fineId)
    cb({ ok = true })
end)

RegisterNUICallback('phone:close', function(data, cb)
    phoneOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterCommand('absher', function() TriggerServerEvent('srp:phone:open'); TriggerServerEvent('srp:phone:absherDocs') end, false)
RegisterCommand('mazadi', function() TriggerServerEvent('srp:phone:auctionList') end, false)
RegisterCommand('atlebni', function() TriggerServerEvent('srp:phone:orderList') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام تطبيقات الجوال.')
