--[[
    fivem-strict-rp :: client/businesses.lua
    جهة العميل للأعمال: نقاط التفاعل + واجهة الملكية.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Businesses

local lastAction = 0
local myBusinesses = {}
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(5000)
    for bizType, loc in pairs(B.Locations) do
        local def = B.Types[bizType]
        local b = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(b, 478) SetBlipColour(b, 2) SetBlipScale(b, 1.0) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(def and def.label or bizType)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(5500)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for bizType, loc in pairs(B.Locations) do
            local dist = #(coords - vector3(loc.x, loc.y, loc.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, loc.x, loc.y, loc.z - 1.0, 0,0,0, 0,0,0, 1.6,1.6,0.9, 52,152,219,140, false, true, 2, false)
                if dist < 2.0 then
                    local def = B.Types[bizType]
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(('اضغط ~INPUT_CONTEXT~ — %s ($%s)'):format(def.label, def.buyPrice))
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        openBusinessMenu(bizType)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openBusinessMenu(bizType)
    local def = B.Types[bizType]
    local items = {
        { id = 'buy:' .. bizType, title = 'شراء ' .. def.label, sub = ('إيراد أساسي: $%s/دورة'):format(def.baseIncome), price = def.buyPrice },
        { id = 'manage', title = 'إدارة أعمالي', sub = 'العرض والترقية والتوظيف' },
    }
    SendNUIMessage({ action = 'openModal', title = def.icon .. ' ' .. def.label, items = items, foot = 'اختر إجراءً', callback = 'business' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:business:show', function(mine, types)
    myBusinesses = mine
    local items = {}
    for _, biz in ipairs(mine) do
        local def = types[biz.type]
        items[#items+1] = { id = 'manage:' .. biz.id, title = (def.icon .. ' ' .. def.label .. ' — مستوى ' .. biz.level), sub = ('ID: %s'):format(biz.id) }
    end
    if #items == 0 then notify('لم تملك أي منشأة بعد.', 'inform') return end
    SendNUIMessage({ action = 'openModal', title = 'أعمالي', items = items, foot = 'اختر منشأة لإدارتها', callback = 'business' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:business:refresh', function() TriggerServerEvent('srp:business:request') end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'business' then
        if id:sub(1, 4) == 'buy:' then
            TriggerServerEvent('srp:business:buy', id:sub(5))
        elseif id:sub(1, 7) == 'manage:' then
            local bizId = tonumber(id:sub(8))
            openManageMenu(bizId)
        elseif id:sub(1, 8) == 'upgrade:' then
            TriggerServerEvent('srp:business:upgrade', tonumber(id:sub(9)))
        elseif id:sub(1, 5) == 'sell:' then
            TriggerServerEvent('srp:business:sell', tonumber(id:sub(6)))
        end
    end
    cb({ ok = true })
end)

function openManageMenu(bizId)
    local items = {
        { id = 'upgrade:' .. bizId, title = 'ترقية المنشأة', sub = 'ترفع الدخل والسعة' },
        { id = 'sell:' .. bizId, title = 'بيع المنشأة', sub = 'استرداد 60% من السعر' },
    }
    SendNUIMessage({ action = 'openModal', title = 'إدارة المنشأة', items = items, foot = 'اختر إجراء', callback = 'business' })
    SetNuiFocus(true, true)
end

RegisterCommand('mybusiness', function() TriggerServerEvent('srp:business:request') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الأعمال.')
