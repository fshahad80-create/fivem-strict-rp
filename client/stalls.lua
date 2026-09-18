--[[
    fivem-strict-rp :: client/stalls.lua
    الأكشاك — عرض · شراء · إدارة · طلبات توريد.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local St = Stalls

local myData = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1500
        local coords = GetEntityCoords(PlayerPedId())
        for _, s in pairs(myData.nearby or {}) do
            local dist = #(coords - vector3(s.x, s.y, s.z))
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, s.x, s.y, s.z - 1.0, 0,0,0, 0,0,0, 1.8,1.8,0.9, 241,196,15,140, false, true, 2, false)
                if dist < 2.5 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح الكشك (' .. s.type .. ')')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        openBuyMenu(s)
                    end
                end
            end
        end
        for _, s in pairs(myData.mine or {}) do
            local dist = #(coords - vector3(s.x, s.y, s.z))
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, s.x, s.y, s.z - 1.0, 0,0,0, 0,0,0, 1.8,1.8,0.9, 46,204,113,140, false, true, 2, false)
                if dist < 2.5 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لإدارة كشكك')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        openManageMenu(s)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:stalls:show', function(data)
    myData = data
    local items = {
        { id = 'myStalls',  title = 'أكشاكي', sub = ('عدد: %s'):format(#(data.mine or {})) },
        { id = 'orders',    title = 'طلبات التوريد', sub = 'وفّر طلبات اللاعبين' },
        { id = 'openStall', title = 'فتح كشك جديد', sub = 'يحتاج تصريحاً من المكتب الشعبي' },
    }
    SendNUIMessage({ action = 'openModal', title = 'الأكشاك', items = items, foot = '', callback = 'stalls' })
    SetNuiFocus(true, true)
end)

function openBuyMenu(stall)
    local items = {}
    for item, listing in pairs(stall.listings or {}) do
        if listing.qty > 0 then
            items[#items+1] = { id = ('buyst:%s:%s'):format(stall.id, item), title = (item .. ' × ' .. listing.qty), sub = ('$%s/وحدة'):format(listing.price), price = listing.price }
        end
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'الكشك فارغ', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'بضاعة الكشك', items = items, foot = 'اضغط للشراء (وحدة واحدة)', callback = 'stalls' })
    SetNuiFocus(true, true)
end

function openManageMenu(stall)
    local items = {
        { id = 'addlisting:' .. stall.id,  title = 'عرض بضاعة', sub = 'اضبط المخزون على الكشك' },
        { id = 'createorder:' .. stall.id, title = 'طلب توريد', sub = 'اطلب بضاعة بمكافأة' },
        { id = 'toggle:' .. stall.id,      title = (stall.open and 'إغلاق الكشك' or 'فتح الكشك'), sub = '' },
    }
    SendNUIMessage({ action = 'openModal', title = 'إدارة الكشك', items = items, foot = '', callback = 'stalls' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:stalls:showOrders', function(list)
    local items = {}
    for _, o in ipairs(list) do
        items[#items+1] = { id = 'fillorder:' .. o.id, title = ('%s × %s'):format(o.item, o.qty), sub = ('مكافأة $%s'):format(o.reward), price = o.reward }
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا طلبات مفتوحة', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'طلبات التوريد', items = items, foot = 'وفّر الطلب وخذ المكافأة', callback = 'stalls' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'stalls' then
        if id == 'orders' then TriggerServerEvent('srp:stalls:requestOrders')
        elseif id == 'openStall' then
            local c = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('srp:stalls:create', 'goods', c.x, c.y, c.z)
        elseif id:sub(1, 11) == 'addlisting:' then notify('استخدم: /stalllist [item] [كمية] [سعر]', 'inform')
        elseif id:sub(1, 12) == 'createorder:' then notify('استخدم: /stallorder [item] [كمية] [مكافأة]', 'inform')
        elseif id:sub(1, 7) == 'toggle:' then TriggerServerEvent('srp:stalls:toggle', tonumber(id:sub(8)))
        elseif id:sub(1, 6) == 'buyst:' then
            local stallId, item = id:match('^buyst:(%d+):(.+)$')
            TriggerServerEvent('srp:stalls:buy', tonumber(stallId), item, 1)
        elseif id:sub(1, 10) == 'fillorder:' then TriggerServerEvent('srp:stalls:fillOrder', tonumber(id:sub(11)))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('stalls', function() TriggerServerEvent('srp:stalls:request') end, false)
RegisterCommand('orders', function() TriggerServerEvent('srp:stalls:requestOrders') end, false)
RegisterCommand('stalllist', function(source, args)
    if myData.mine and myData.mine[1] then
        TriggerServerEvent('srp:stalls:list', myData.mine[1].id, args[1], tonumber(args[2]), tonumber(args[3]))
    end
end, false)
RegisterCommand('stallorder', function(source, args)
    if myData.mine and myData.mine[1] then
        TriggerServerEvent('srp:stalls:createOrder', myData.mine[1].id, args[1], tonumber(args[2]), tonumber(args[3]))
    end
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الأكشاك.')
