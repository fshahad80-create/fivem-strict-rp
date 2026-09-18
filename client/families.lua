--[[
    fivem-strict-rp :: client/families.lua
    العوائل — واجهة · شات · حروب · مناطق.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local F = Families

local myFamily = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterNetEvent('srp:families:show', function(data)
    myFamily = data
    local items = {
        { id = 'members', title = ('الأعضاء (%s)'):format(#data.members), sub = 'إدارة الأعضاء والرتب' },
        { id = 'treasury', title = ('الخزنة: $%s'):format(data.treasury), sub = 'إيداع / سحب / سرقة' },
        { id = 'wards', title = 'الحرب والتحالفات', sub = 'إعلان حرب أو تحالف' },
        { id = 'zones', title = 'مناطق النفوذ', sub = 'سيطرة على المناطق' },
        { id = 'leave', title = 'مغادرة العائلة', sub = '' },
    }
    local foot = ('العائلة: %s [%s] · رتبتك: %s'):format(data.name, data.tag, F.Settings.ranks[(data.rank or 0) + 1] or 'عضو')
    SendNUIMessage({ action = 'openModal', title = data.name, items = items, foot = foot, callback = 'family' })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('srp:families:none', function()
    local items = {
        { id = 'create', title = 'تأسيس عائلة', sub = ('التكلفة: $%s'):format(F.Settings.createFee) },
        { id = 'accept', title = 'قبول دعوة', sub = 'إن كانت لديك دعوة' },
    }
    SendNUIMessage({ action = 'openModal', title = 'العوائل', items = items, foot = 'أنت لست في عائلة', callback = 'family' })
    SetNuiFocus(true, true)
end)

local function openMembers()
    if not myFamily then return end
    local items = {}
    for _, m in ipairs(myFamily.members) do
        local status = m.online and '🟢 ' or ''
        items[#items+1] = { id = 'rank:' .. m.cid, title = (status .. m.name), sub = ('الرتبة: %s'):format(m.rankName) }
    end
    SendNUIMessage({ action = 'openModal', title = 'أعضاء العائلة', items = items, foot = 'اضغط على عضو لتغيير رتبته', callback = 'family' })
    SetNuiFocus(true, true)
end

local function openRankPicker(cid)
    local items = {}
    for idx, rn in ipairs(F.Settings.ranks) do
        items[#items+1] = { id = ('setrank:%s:%s'):format(cid, idx - 1), title = rn, sub = '' }
    end
    SendNUIMessage({ action = 'openModal', title = 'اختر الرتبة', items = items, foot = '', callback = 'family' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'family' then
        if id == 'members' then openMembers()
        elseif id == 'treasury' then notify(('الخزنة: $%s — استخدم /fdeposit و /fwithdraw'):format(myFamily and myFamily.treasury or 0), 'primary')
        elseif id == 'wards' then notify('استخدم /finvite للدعوة. الحروب عبر القائمة.', 'inform')
        elseif id == 'zones' then notify('اقترب من منطقة نفوذ واضغط E للسيطرة.', 'inform')
        elseif id == 'leave' then TriggerServerEvent('srp:families:leave')
        elseif id == 'create' then TriggerServerEvent('srp:families:create', 'عائلة جديدة', 'NEW')
        elseif id == 'accept' then TriggerServerEvent('srp:families:accept')
        elseif id:sub(1, 5) == 'rank:' then openRankPicker(id:sub(6))
        elseif id:sub(1, 8) == 'setrank:' then
            local cid, rank = id:match('^setrank:(.-):(%d+)$')
            TriggerServerEvent('srp:families:setRank', cid, tonumber(rank))
        end
    end
    cb({ ok = true })
end)

CreateThread(function()
    Wait(7000)
    while true do
        local sleep = 1000
        if myFamily then
            local coords = GetEntityCoords(PlayerPedId())
            for _, z in ipairs(F.Zones) do
                local dist = #(coords - vector3(z.x, z.y, z.z))
                if dist < z.radius + 20 then
                    sleep = 0
                    DrawMarker(1, z.x, z.y, z.z - 1.0, 0,0,0, 0,0,0, 3.0,3.0,1.0, 231,76,60,120, false, true, 2, false)
                    if dist < 8.0 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ للسيطرة على ' .. z.label)
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('srp:families:captureZone', z.key)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('family', function() TriggerServerEvent('srp:families:request') end, false)
RegisterCommand('f', function(source, args)
    local msg = table.concat(args, ' ')
    if msg ~= '' then TriggerServerEvent('srp:families:chat', msg) end
end, false)
RegisterCommand('fdeposit', function(source, args) TriggerServerEvent('srp:families:deposit', tonumber(args[1])) end, false)
RegisterCommand('fwithdraw', function(source, args) TriggerServerEvent('srp:families:withdraw', tonumber(args[1])) end, false)
RegisterCommand('finvite', function(source, args) TriggerServerEvent('srp:families:invite', tonumber(args[1])) end, false)
RegisterCommand('familyaccept', function() TriggerServerEvent('srp:families:accept') end, false)

RegisterNetEvent('srp:families:refresh', function() TriggerServerEvent('srp:families:request') end)

print('[fivem-strict-rp][client] تم تحميل نظام العوائل.')
