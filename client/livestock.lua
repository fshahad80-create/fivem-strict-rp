--[[
    fivem-strict-rp :: client/livestock.lua
    المواشي — حظائر · شراء · إطعام · جمع · ذبح · تزاوج.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local L = Livestock

local myPens = {}
local myAnimals = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(7000)
    for _, p in ipairs(L.Pens) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 141) SetBlipColour(b, 5) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('حظيرة — ' .. p.label) EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        for _, p in ipairs(L.Pens) do
            local dist = #(coords - vector3(p.x, p.y, p.z))
            if dist < 30.0 then
                sleep = 0
                DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 2.0,2.0,0.9, 230,126,34,140, false, true, 2, false)
                if dist < 2.5 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح الحظيرة')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:livestock:request')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:livestock:show', function(list, animals, feed)
    myPens = list
    myAnimals = animals
    local items = {}
    for _, p in ipairs(list) do
        local sub
        if p.mine then sub = ('حظيرتك · %s حيوان'):format(#p.animals)
        elseif p.owner then sub = 'مملوكة'
        else sub = 'متاحة للشراء ($150,000)' end
        items[#items+1] = { id = 'pen:' .. p.id, title = ('حظيرة ' .. p.label), sub = sub }
    end
    SendNUIMessage({ action = 'openModal', title = 'الحظائر', items = items, foot = 'اختر حظيرة', callback = 'livestock' })
    SetNuiFocus(true, true)
end)

local function openPenMenu(penId, isMine)
    local items = {}
    if isMine then
        items[#items+1] = { id = 'feed:' .. penId,    title = 'إطعام المواشي', sub = 'يستهلك علفاً من جيبك' }
        items[#items+1] = { id = 'collect:' .. penId, title = 'جمع المنتجات', sub = 'حليب · بيض · عسل · صوف' }
        items[#items+1] = { id = 'buya:' .. penId,    title = 'شراء حيوان', sub = 'دجاجة · بقرة · خروف · ماعز · نحل' }
        items[#items+1] = { id = 'manage:' .. penId,  title = 'إدارة المواشي', sub = 'ذبح · تزاوج' }
    else
        items[#items+1] = { id = 'buypen:' .. penId, title = 'شراء الحظيرة', sub = '$150,000' }
    end
    SendNUIMessage({ action = 'openModal', title = 'الحظيرة', items = items, foot = '', callback = 'livestock' })
    SetNuiFocus(true, true)
end

local function openBuyAnimal(penId)
    local items = {}
    for key, a in pairs(myAnimals) do
        items[#items+1] = { id = ('bai:%s:%s'):format(penId, key), title = (a.icon .. ' ' .. a.label),
            sub = ('علف/دورة: $%s'):format(a.feedCost), price = a.buyPrice }
    end
    SendNUIMessage({ action = 'openModal', title = 'شراء حيوان', items = items, foot = 'اختر النوع', callback = 'livestock' })
    SetNuiFocus(true, true)
end

local function openManage(penId)
    local pen
    for _, p in ipairs(myPens) do if p.id == penId then pen = p end end
    if not pen then return end
    local items = {}
    for idx, a in ipairs(pen.animals) do
        local def = myAnimals[a.type]
        items[#items+1] = { id = ('slaughter:%s:%s'):format(penId, idx),
            title = (def and (def.icon .. ' ' .. def.label) or a.type) .. (' · صحة %s%%'):format(a.health), sub = 'اضغط للذبح' }
        if def and def.breed then
            items[#items+1] = { id = ('breed:%s:%s'):format(penId, idx),
                title = ('تزاوج ' .. (def.icon or '') .. ' ' .. (def.label or '')), sub = ('حالة صحية: %s%%'):format(a.health) }
        end
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا حيوانات', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'إدارة المواشي', items = items, foot = 'اختر إجراءً', callback = 'livestock' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'livestock' then
        if id:sub(1, 4) == 'pen:' then
            local penId = tonumber(id:sub(5))
            local isMine = false
            for _, p in ipairs(myPens) do if p.id == penId and p.mine then isMine = true end end
            openPenMenu(penId, isMine)
        elseif id:sub(1, 7) == 'buypen:' then TriggerServerEvent('srp:livestock:buyPen', tonumber(id:sub(8)))
        elseif id:sub(1, 5) == 'feed:' then TriggerServerEvent('srp:livestock:feed', tonumber(id:sub(6)))
        elseif id:sub(1, 8) == 'collect:' then TriggerServerEvent('srp:livestock:collect', tonumber(id:sub(9)))
        elseif id:sub(1, 5) == 'buya:' then openBuyAnimal(tonumber(id:sub(6)))
        elseif id:sub(1, 7) == 'manage:' then openManage(tonumber(id:sub(8)))
        elseif id:sub(1, 4) == 'bai:' then
            local penId, key = id:match('^bai:(.-):(.+)$')
            TriggerServerEvent('srp:livestock:buyAnimal', tonumber(penId), key)
        elseif id:sub(1, 10) == 'slaughter:' then
            local penId, idx = id:match('^slaughter:(.-):(%d+)$')
            TriggerServerEvent('srp:livestock:slaughter', tonumber(penId), tonumber(idx))
        elseif id:sub(1, 6) == 'breed:' then
            local penId, idx = id:match('^breed:(.-):(%d+)$')
            TriggerServerEvent('srp:livestock:breed', tonumber(penId), tonumber(idx))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('livestock', function() TriggerServerEvent('srp:livestock:request') end, false)
RegisterCommand('ranch', function() TriggerServerEvent('srp:livestock:request') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام المواشي.')
