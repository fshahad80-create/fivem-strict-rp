--[[
    fivem-strict-rp :: client/tablet.lua
    جهاز التابلت — واجهة موحّدة لكل الخدمات. يُفتح بـ /tablet أو F5.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Businesses
local J = Jobs

local tabletOpen = false

local function openTablet()
    if tabletOpen then return end
    tabletOpen = true
    local jobsList = {}
    for key, def in pairs(J and J.List or {}) do
        jobsList[#jobsList+1] = { id = key, label = def.label, icon = def.icon }
    end
    local bizList = {}
    for key, def in pairs(B and B.Types or {}) do
        bizList[#bizList+1] = { id = key, label = def.label, icon = def.icon, price = def.buyPrice }
    end
    local cropsList = {}
    for key, c in pairs((B and B.Farming and B.Farming.crops) or {}) do
        cropsList[#cropsList+1] = { id = key, label = c.label, grow = c.growMinutes, sell = c.sellPrice }
    end
    SendNUIMessage({ action = 'tabletOpen', jobs = jobsList, businesses = bizList, crops = cropsList })
    SetNuiFocus(true, true)
end

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SendNUIMessage({ action = 'tabletClose' })
    SetNuiFocus(false, false)
end

RegisterCommand('tablet', function() if tabletOpen then closeTablet() else openTablet() end end, false)
RegisterKeyMapping('tablet', 'فتح التابلت', 'keyboard', 'F5')

RegisterNUICallback('tablet:action', function(data, cb)
    local app = data.app
    local id = data.id
    if app == 'jobs' then TriggerServerEvent('srp:jobs:hire', id)
    elseif app == 'business' then TriggerServerEvent('srp:business:request')
    elseif app == 'farm' then TriggerServerEvent('srp:farm:requestPlots')
    elseif app == 'dealer' then TriggerServerEvent('srp:dealership:requestStock', id or 'city')
    elseif app == 'mechanic' then TriggerServerEvent('srp:mechanic:requestGarages')
    end
    cb({ ok = true })
end)

RegisterNUICallback('tablet:close', function(data, cb) closeTablet() cb({ ok = true }) end)

print('[fivem-strict-rp][client] تم تحميل التابلت.')
