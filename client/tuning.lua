--[[
    fivem-strict-rp :: client/tuning.lua
    الميكانيك العميق — تطبيق المكينة · تتبع العداد · واجهات.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local T = Tuning

local lastPos = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function getClosestVehicle()
    local coords = GetEntityCoords(PlayerPedId())
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
    return veh ~= 0 and veh or 0
end
local function getPlateOf(veh) return GetVehicleNumberPlateText(veh):gsub("%s+", "") end

RegisterNetEvent('srp:tuning:applyEngine', function(plate, engineKey, soundKey, hp)
    local veh = getClosestVehicle()
    if veh == 0 then return end
    SetVehicleModKit(veh, 0)
    local modLevel = math.min(5, math.floor((hp or 300) / 250))
    SetVehicleMod(veh, 11, modLevel, false)
    SetVehicleMod(veh, 12, math.min(5, modLevel), false)
end)

CreateThread(function()
    Wait(6000)
    while true do
        Wait(3000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = getPlateOf(veh)
            local coords = GetEntityCoords(veh)
            if lastPos and plate == lastPos.plate then
                local dist = #(vector2(coords.x, coords.y) - vector2(lastPos.x, lastPos.y))
                local km = dist / 1000.0
                if km > 0 then TriggerServerEvent('srp:tuning:updateKm', plate, km) end
            end
            lastPos = { plate = plate, x = coords.x, y = coords.y }
        else
            lastPos = nil
        end
    end
end)

RegisterNetEvent('srp:tuning:show', function(plate, v, data)
    local items = {
        { id = 'buildmenu:' .. plate, title = 'بناء مكينة', sub = 'اختر نوع المكينة والصوت' },
        { id = 'chipmenu:' .. plate,  title = 'برمجة (قاطع)', sub = 'ترفع القوة مقابل استهلاك وتآكل' },
        { id = 'oilmenu:' .. plate,   title = 'تغيير زيت', sub = '5000 / 10000 كم' },
        { id = 'dyno:' .. plate,      title = 'داينو', sub = 'قياس القوة الحالية' },
        { id = 'rebuild:' .. plate,   title = 'صيانة شاملة', sub = 'تجديد المكينة' },
    }
    local cur = ('المكينة: %s · البرمجة: %s · الزيت منذ %s كم · العمر: %s%%'):format(
        (data.engines[v.engine] and data.engines[v.engine].label) or v.engine,
        (data.chips[v.chip] and data.chips[v.chip].label) or v.chip,
        math.floor(v.kmSinceOil), math.max(0, math.floor(100 - v.wear)))
    SendNUIMessage({ action = 'openModal', title = 'ورشة الأداء — ' .. plate, items = items, foot = cur, callback = 'tuning' })
    SetNuiFocus(true, true)
end)

local function openBuildMenu(plate)
    local items = {}
    for key, eng in pairs(T.Engines) do
        items[#items+1] = { id = 'dobuild:' .. plate .. ':' .. key, title = (eng.icon .. ' ' .. eng.label),
            sub = ('%s حصان · %s نيوتن · بناء %sث'):format(eng.hp, eng.torque, eng.buildTime), price = eng.buildCost }
    end
    SendNUIMessage({ action = 'openModal', title = 'بناء مكينة', items = items, foot = 'القطع تُخصم من مخزونك', callback = 'tuning' })
    SetNuiFocus(true, true)
end

local function openChipMenu(plate)
    local items = {}
    for key, chip in pairs(T.Chips) do
        items[#items+1] = { id = 'dochip:' .. plate .. ':' .. key, title = chip.label,
            sub = ('+%s%% قوة · استهلاك ×%s · تآكل ×%s'):format(math.floor((chip.hpBonus - 1) * 100), chip.fuelMul, chip.wearMul), price = chip.cost }
    end
    SendNUIMessage({ action = 'openModal', title = 'البرمجة', items = items, foot = 'البرمجة الأعلى = قوة أكبر وتآكل أسرع', callback = 'tuning' })
    SetNuiFocus(true, true)
end

local function openOilMenu(plate)
    local items = {}
    for key, oil in pairs(T.Oil.types) do
        items[#items+1] = { id = 'dooil:' .. plate .. ':' .. key, title = oil.label,
            sub = ('يكفي %s كم · حماية %s%%'):format(oil.durabilityKm, math.floor(oil.protection * 100)), price = oil.cost }
    end
    SendNUIMessage({ action = 'openModal', title = 'تغيير الزيت', items = items, foot = 'بدون زيت => حرارة وتآكل مضاعف', callback = 'tuning' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:tuning:dynoResult', function(res)
    SendNUIMessage({ action = 'openModal', title = 'نتيجة الداينو', items = {
        { id = 'noop', title = ('%s حصان'):format(res.hp), sub = 'القوة الفعلية' },
        { id = 'noop', title = ('%s نيوتن'):format(res.torque), sub = 'العزم' },
        { id = 'noop', title = ('%s%%'):format(res.wear), sub = 'عمر المكينة' },
    }, foot = ('المكينة: %s · البرمجة: %s'):format(res.engine, res.chip), callback = 'none' })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'tuning' then
        if id:sub(1, 10) == 'buildmenu:' then openBuildMenu(id:sub(11))
        elseif id:sub(1, 9) == 'chipmenu:' then openChipMenu(id:sub(10))
        elseif id:sub(1, 8) == 'oilmenu:' then openOilMenu(id:sub(9))
        elseif id:sub(1, 5) == 'dyno:' then TriggerServerEvent('srp:tuning:dyno', id:sub(6))
        elseif id:sub(1, 8) == 'rebuild:' then TriggerServerEvent('srp:tuning:rebuild', id:sub(9))
        elseif id:sub(1, 8) == 'dobuild:' then
            local plate, key = id:match('^dobuild:(.-):(.+)$')
            local eng = T.Engines[key]
            local sound = eng and eng.soundVariants[1] or 'stock'
            TriggerServerEvent('srp:tuning:build', plate, key, sound)
        elseif id:sub(1, 7) == 'dochip:' then
            local plate, key = id:match('^dochip:(.-):(.+)$')
            TriggerServerEvent('srp:tuning:chip', plate, key)
        elseif id:sub(1, 6) == 'dooil:' then
            local plate, key = id:match('^dooil:(.-):(.+)$')
            TriggerServerEvent('srp:tuning:changeOil', plate, key)
        end
    end
    cb({ ok = true })
end)

RegisterCommand('tuning', function()
    local veh = getClosestVehicle()
    if veh == 0 then notify('لا توجد مركبة قريبة.', 'error') return end
    TriggerServerEvent('srp:tuning:request', getPlateOf(veh))
end, false)

print('[fivem-strict-rp][client] تم تحميل الميكانيك العميق.')
