--[[
    fivem-strict-rp :: server/mechanic.lua
    منطق نظام الميكانيك — QBCore.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local M = Jobs.Mechanic

local CalledMechanics = {}
local CallCounter = 0

local function log(msg) print(('[fivem-strict-rp][mechanic] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

RegisterNetEvent('srp:mechanic:call', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local coords = GetEntityCoords(GetPlayerPed(src))
    CallCounter = CallCounter + 1
    local callId = CallCounter
    CalledMechanics[callId] = { clientSrc = src, coords = coords, callerCid = Player.PlayerData.citizenid }
    local anyOnline = false
    for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
        local P = getPlayer(pid)
        if P and P.PlayerData.job.name == M.job then
            anyOnline = true
            TriggerClientEvent('srp:mechanic:incomingCall', pid, callId, coords,
                Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)
        end
    end
    TriggerClientEvent('QBCore:Notify', src, anyOnline and 'تم إرسال الاستدعاء للميكانيكيين.' or M.Messages.noMechanic, anyOnline and 'success' or 'error')
end)

RegisterNetEvent('srp:mechanic:acceptCall', function(callId)
    local src = source
    local Player = getPlayer(src)
    if not Player or not CalledMechanics[callId] then return end
    if Player.PlayerData.job.name ~= M.job then return end
    local call = CalledMechanics[callId]
    TriggerClientEvent('srp:mechanic:routeTo', src, call.coords)
    TriggerClientEvent('QBCore:Notify', call.clientSrc, 'ميكانيكي في الطريق إليك.', 'success')
end)

RegisterNetEvent('srp:mechanic:service', function(serviceKey, plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local service = M.services[serviceKey]
    if not service then return end
    local isMechanic = Player.PlayerData.job.name == M.job
    if not isMechanic then
        if not M.allowSelfRepair then
            TriggerClientEvent('QBCore:Notify', src, 'الخدمة تتطلب ميكانيكياً.', 'error') return
        end
        local cash = Player.Functions.GetMoney('cash')
        local bank = Player.Functions.GetMoney('bank')
        if cash + bank < service.price then
            TriggerClientEvent('QBCore:Notify', src, 'لا تملك المال الكافي ($' .. service.price .. ').', 'error') return
        end
        if bank >= service.price then
            Player.Functions.RemoveMoney('bank', service.price, 'srp-mechanic-service')
        else
            Player.Functions.RemoveMoney('bank', bank, 'srp-mechanic-service')
            Player.Functions.RemoveMoney('cash', service.price - bank, 'srp-mechanic-service')
        end
    else
        local commission = math.floor(service.price * M.commissionPercent / 100)
        Player.Functions.AddMoney('bank', commission, 'srp-mechanic-commission')
        TriggerClientEvent('QBCore:Notify', src, ('عمولتك: $%s'):format(commission), 'success')
        TriggerEvent('srp:economy:insuranceClaim', service.price)
    end
    TriggerClientEvent('srp:mechanic:doService', src, serviceKey, plate)
    TriggerClientEvent('QBCore:Notify', src, ('تم تنفيذ: %s'):format(service.label), 'success')
end)

RegisterNetEvent('srp:mechanic:requestGarages', function()
    TriggerClientEvent('srp:mechanic:showGarages', source, M.garages, M.services)
end)

CreateThread(function() log('تم تحميل نظام الميكانيك.') end)
