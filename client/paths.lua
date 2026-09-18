--[[
    fivem-strict-rp :: client/paths.lua
    شجرة المسارات — واجهة الشجرة · فتح العقود · الألقاب.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local P = Paths

local myData = nil
local mySectors = {}
local myNodes = {}
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterNetEvent('srp:paths:show', function(data, sectors, nodes)
    myData = data; mySectors = sectors or {}; myNodes = nodes or {}
    local items = {}
    items[#items+1] = { id = 'summary', title = ('نقاطك: %s'):format(data.points or 0), sub = 'أنفقها على العقد' }
    for secKey, sec in pairs(mySectors) do
        local specLabels = {}
        for k, s in pairs(sec.specs) do specLabels[#specLabels+1] = s.label end
        items[#items+1] = { id = 'sector:' .. secKey, title = (sec.icon .. ' ' .. sec.label), sub = table.concat(specLabels, ' · ') }
    end
    if data.title then items[#items+1] = { id = 'title', title = ('لقبك: %s'):format(data.title), sub = 'لقب القمة الحالي' } end
    items[#items+1] = { id = 'respec', title = 'إعادة توزيع النقاط', sub = 'متاحة مرة كل 30 يوم' }
    SendNUIMessage({ action = 'openModal', title = 'شجرة المسارات', items = items, foot = 'اختر قطاعاً لعرض تخصصاته', callback = 'paths' })
    SetNuiFocus(true, true)
end)

local function levelFromXp(xp)
    local lvl, need, acc = 0, 500, 0
    while xp >= acc + need and lvl < P.Settings.maxLevelPerSpec do
        acc = acc + need; lvl = lvl + 1; need = math.floor(need * 1.25)
    end
    return lvl, xp - acc, need
end

local function openSector(secKey)
    local sec = mySectors[secKey]
    if not sec then return end
    local items = {}
    for specKey, spec in pairs(sec.specs) do
        local xp = (myData.xp and myData.xp[specKey]) or 0
        local lvl, cur, need = levelFromXp(xp)
        items[#items+1] = { id = 'spec:' .. specKey, title = (spec.icon .. ' ' .. spec.label),
            sub = ('مستوى %s · خبرة %s/%s'):format(lvl, math.floor(cur), need) }
    end
    SendNUIMessage({ action = 'openModal', title = (sec.icon .. ' ' .. sec.label), items = items, foot = ('لقب القطاع: %s'):format(sec.title), callback = 'paths' })
    SetNuiFocus(true, true)
end

local function openSpec(specKey)
    local nodes = myNodes[specKey]
    if not nodes then notify('لا توجد عقد لهذا التخصص بعد.', 'inform') return end
    local items = {}
    for idx, node in ipairs(nodes) do
        local unlocked = myData.nodes and myData.nodes[specKey] and myData.nodes[specKey][idx]
        local badge = node.badge and ' [شارة]' or ''
        items[#items+1] = { id = 'unlock:' .. specKey .. ':' .. idx,
            title = (node.label .. badge .. (unlocked and ' ✓' or '')),
            sub = ('مستوى %s مطلوب · التكلفة %s نقطة'):format(node.level, node.cost), disabled = unlocked and true or false }
    end
    SendNUIMessage({ action = 'openModal', title = ('عقد: ' .. specKey), items = items, foot = ('نقاطك: %s'):format(myData.points or 0), callback = 'paths' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'paths' then
        if id == 'summary' then notify(('نقاط المسارات: %s'):format(myData.points or 0), 'primary')
        elseif id == 'respec' then TriggerServerEvent('srp:paths:respec')
        elseif id == 'title' then notify(('لقبك: %s'):format(myData.title), 'primary')
        elseif id:sub(1, 7) == 'sector:' then openSector(id:sub(8))
        elseif id:sub(1, 5) == 'spec:' then openSpec(id:sub(6))
        elseif id:sub(1, 7) == 'unlock:' then
            local spec, idx = id:match('^unlock:(.-):(%d+)$')
            TriggerServerEvent('srp:paths:unlockNode', spec, tonumber(idx))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('paths', function() TriggerServerEvent('srp:paths:request') end, false)
RegisterCommand('skilltree', function() TriggerServerEvent('srp:paths:request') end, false)

local specByJob = {
    miner = 'mining', carpenter = 'woodcutting', blacksmith = 'smithing',
    fisher = 'sea_hunting', trucker = 'transport', police = 'security', ambulance = 'ems',
}
RegisterNetEvent('srp:jobs:skillXp', function(job, amount)
    local spec = specByJob[job]
    if spec then TriggerServerEvent('srp:paths:addXp', spec, amount or 5) end
end)

print('[fivem-strict-rp][client] تم تحميل شجرة المسارات.')
