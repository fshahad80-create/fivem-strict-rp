--[[
    fivem-strict-rp :: client/land.lua
    جهة العميل للأراضي: عرض الحدود + البناء + الواجهة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local L = Land

local myLand = nil
local myLandId = nil
local buildMode = false
local buildKey = nil
local lastAction = 0
local spawnedStructures = {}

local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    while true do
        local sleep = 1000
        if myLand then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local center = vector3(myLand.x, myLand.y, myLand.z)
            local dist = #(coords - center)
            if dist < myLand.radius + 50.0 then
                sleep = 0
                local segs = 64
                for i = 0, segs - 1 do
                    local a1 = (i / segs) * 2 * math.pi
                    local a2 = ((i + 1) / segs) * 2 * math.pi
                    local x1 = myLand.x + math.cos(a1) * myLand.radius
                    local y1 = myLand.y + math.sin(a1) * myLand.radius
                    local x2 = myLand.x + math.cos(a2) * myLand.radius
                    local y2 = myLand.y + math.sin(a2) * myLand.radius
                    DrawLine(x1, y1, myLand.z - 0.9, x2, y2, myLand.z - 0.9, 46, 204, 113, 160)
                end
                local inside = dist <= myLand.radius
                if inside and (GetGameTimer() - lastAction) > 15000 then
                    lastAction = GetGameTimer()
                    notify('أنت داخل أرضك.', 'inform')
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        if buildMode and buildKey then
            sleep = 0
            local struct = L.Structures[buildKey]
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local bx = coords.x + forward.x * 3.0
            local by = coords.y + forward.y * 3.0
            local bz = coords.z
            local rot = GetEntityHeading(ped)
            local inside = #(vector2(bx, by) - vector2(myLand.x, myLand.y)) <= myLand.radius
            local col = inside and {46, 204, 113} or {231, 76, 60}
            DrawMarker(1, bx, by, bz - 1.0, 0,0,0, 0,0,0, struct.radius, struct.radius, 1.0,
                col[1], col[2], col[3], 160, false, true, 2, false)
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('وضع البناء: %s ($%s) — ~INPUT_CONTEXT~ للتثبيت · ~INPUT_CELLPHONE_CANCEL~ للإلغاء'):format(struct.label, struct.cost))
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustReleased(0, 38) then
                if inside then
                    TriggerServerEvent('srp:land:build', buildKey, bx, by, bz, rot)
                    buildMode = false
                    buildKey = nil
                else
                    notify(L.Messages.outside, 'error')
                end
            end
            if IsControlJustReleased(0, 177) then
                buildMode = false
                buildKey = nil
                notify('أُلغي وضع البناء.', 'inform')
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:land:spawnStructure', function(entry, model)
    if not model then return end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 60 do Wait(50) timeout = timeout + 1 end
    if not HasModelLoaded(model) then return end
    local obj = CreateObject(model, entry.x, entry.y, entry.z, false, false, false)
    SetEntityHeading(obj, entry.rot or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)
    spawnedStructures[#spawnedStructures + 1] = obj
end)

RegisterNetEvent('srp:land:updateMine', function(land, landId)
    myLand = land
    myLandId = landId
    if land.structures then
        for _, entry in ipairs(land.structures) do
            local struct = L.Structures[entry.key]
            if struct and struct.model then TriggerEvent('srp:land:spawnStructure', entry, struct.model) end
        end
    end
    notify(('أرضك: نوع %s · نصف القطر %s م'):format(land.type, land.radius), 'success')
end)

RegisterNetEvent('srp:land:clearMine', function()
    myLand = nil
    myLandId = nil
    for _, obj in ipairs(spawnedStructures) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    spawnedStructures = {}
end)

RegisterNetEvent('srp:land:showAll', function(list)
    local items = {}
    for _, l in ipairs(list) do
        items[#items+1] = { id = 'revoke:' .. l.id, title = ('أرض #%s (%s)'):format(l.id, l.type), sub = ('مالك: %s · نصف القطر %s'):format(l.owner, l.radius) }
    end
    if #items == 0 then notify('لا توجد أراضٍ.', 'inform') return end
    SendNUIMessage({ action = 'openModal', title = 'الأراضي', items = items, foot = 'اختر للسحب', callback = 'land' })
    SetNuiFocus(true, true)
end)

local function openLandMenu()
    if not myLand then
        notify('لا تملك أرضاً. تواصل مع الإدارة.', 'inform') return
    end
    local items = {}
    local typeDef = L.Types[myLand.type]
    for _, key in ipairs(typeDef.buildAllow) do
        local s = L.Structures[key]
        items[#items+1] = { id = 'build:' .. key, title = (s.icon .. ' بناء ' .. s.label), sub = ('التكلفة: $%s'):format(s.cost), price = s.cost }
    end
    items[#items+1] = { id = 'sellland', title = 'بيع الأرض', sub = 'استرداد جزئي' }
    SendNUIMessage({ action = 'openModal', title = 'أرضي — البناء', items = items, foot = 'اختر منشأة للبناء', callback = 'land' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'land' then
        if id:sub(1, 6) == 'build:' then
            buildKey = id:sub(7)
            buildMode = true
            notify('وضع البناء مُفعّل — اقترب من المكان المطلوب.', 'inform')
        elseif id == 'sellland' then
            TriggerServerEvent('srp:land:sell')
        elseif id:sub(1, 7) == 'revoke:' then
            TriggerServerEvent('srp:land:revoke', tonumber(id:sub(8)))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('myland', function() TriggerServerEvent('srp:land:requestMine') end, false)
RegisterCommand('build', function() openLandMenu() end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الأراضي.')
