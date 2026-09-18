--[[
    fivem-strict-rp :: client/farm2.lua
    المزارع v1.7 — حقول · بستان · معمل · صومعة · مواسم.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local F = Farm2

local myFarm = {}
local farmData = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

CreateThread(function()
    Wait(7000)
    for _, p in ipairs(F.Locations.plots) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 85) SetBlipColour(b, 2) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('حقل — ' .. p.label) EndTextCommandSetBlipName(b)
    end
    for _, p in ipairs(F.Locations.trees) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 85) SetBlipColour(b, 3) SetBlipScale(b, 0.8) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('بستان — ' .. p.label) EndTextCommandSetBlipName(b)
    end
    local pr = F.Locations.processing
    local bp = AddBlipForCoord(pr.x, pr.y, pr.z)
    SetBlipSprite(bp, 478) SetBlipColour(bp, 5) SetBlipScale(bp, 0.9) SetBlipAsShortRange(bp, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('معمل المزرعة') EndTextCommandSetBlipName(bp)
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local function handlePoint(px, py, pz, helpText, fn)
            local dist = #(coords - vector3(px, py, pz))
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, px, py, pz - 1.0, 0,0,0, 0,0,0, 1.6,1.6,0.9, 46,204,113,140, false, true, 2, false)
                if dist < 2.0 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(helpText)
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 800 then
                        lastAction = GetGameTimer()
                        fn()
                    end
                end
            end
        end
        for idx, p in ipairs(F.Locations.plots) do
            handlePoint(p.x, p.y, p.z, 'اضغط ~INPUT_CONTEXT~ — ' .. p.label, function() openPlotMenu(idx) end)
        end
        for idx, p in ipairs(F.Locations.trees) do
            handlePoint(p.x, p.y, p.z, 'اضغط ~INPUT_CONTEXT~ — ' .. p.label, function() openTreeMenu() end)
        end
        local pr = F.Locations.processing
        handlePoint(pr.x, pr.y, pr.z, 'اضغط ~INPUT_CONTEXT~ — معمل التحويل', function() openProcessingMenu() end)
        local sl = F.Locations.silo
        handlePoint(sl.x, sl.y, sl.z, 'اضغط ~INPUT_CONTEXT~ — الصومعة', function() openSiloMenu() end)
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:farm2:show', function(f, data)
    myFarm = f; farmData = data
    openMainMenu()
end)

function openMainMenu()
    local level = myFarm.level or 1
    local xp = myFarm.xp or 0
    local season = farmData.seasonDef or { label = "?", icon = "?" }
    local items = {
        { id = 'plots',      title = 'الحقول', sub = 'زراعة وحصاد المحاصيل' },
        { id = 'trees',      title = 'البستان', sub = 'أشجار دائمة (حصاد متكرر)' },
        { id = 'processing', title = 'معمل التحويل', sub = 'حوّل المحاصيل لمنتجات أعلى قيمة' },
        { id = 'silo',       title = 'الصومعة', sub = ('المستوى %s'):format(myFarm.siloLevel or 1) },
        { id = 'tools',      title = 'أدوات زراعية', sub = 'ترفع الغلة والسرعة' },
    }
    local foot = ('مستوى الفلاح: %s · خبرة: %s · الموسم: %s %s'):format(level, xp, season.icon, season.label)
    SendNUIMessage({ action = 'openModal', title = 'المزرعة', items = items, foot = foot, callback = 'farm2' })
    SetNuiFocus(true, true)
end

function openPlotMenu(plotIndex)
    local plot = myFarm.crops and myFarm.crops[plotIndex]
    if plot and plot.crop then
        local crop = nil
        for _, c in ipairs(farmData.crops) do if c.key == plot.crop then crop = c end end
        local items = { { id = 'harvest:' .. plotIndex, title = ('حصاد %s'):format(crop and crop.label or ''), sub = 'إن كان ناضجاً' } }
        SendNUIMessage({ action = 'openModal', title = 'الحقل', items = items, foot = '', callback = 'farm2' })
    else
        openPlantMenu(plotIndex)
    end
    SetNuiFocus(true, true)
end

function openPlantMenu(plotIndex)
    local items = {}
    for _, c in ipairs(farmData.crops) do
        local tier = farmData.tiers[c.tier]
        items[#items+1] = { id = ('plantf:%s:%s'):format(plotIndex, c.key), title = (c.icon .. ' ' .. c.label),
            sub = ('الفئة %s · ينمو %s دقيقة'):format(c.tier, tier.growMin), price = 15 * c.tier }
    end
    SendNUIMessage({ action = 'openModal', title = 'اختر محصولاً', items = items, foot = 'الفئات الأعلى تحتاج مستوى أعلى', callback = 'farm2' })
    SetNuiFocus(true, true)
end

function openTreeMenu()
    local items = {}
    for key, t in pairs(farmData.trees) do
        items[#items+1] = { id = 'planttree:' .. key, title = (t.icon .. ' زراعة ' .. t.label),
            sub = ('حصاد كل %s دقيقة'):format(t.regrowMin), price = t.plantCost }
    end
    for idx, t in ipairs(myFarm.trees or {}) do
        local def = farmData.trees[t.type]
        items[#items+1] = { id = 'harvesttree:' .. idx, title = ('حصاد ' .. (def and def.label or '')), sub = 'اضغط للحصاد' }
    end
    SendNUIMessage({ action = 'openModal', title = 'البستان', items = items, foot = '', callback = 'farm2' })
    SetNuiFocus(true, true)
end

function openProcessingMenu()
    local items = {}
    for key, rec in pairs(farmData.processing) do
        local inputsStr = {}
        for item, need in pairs(rec.inputs) do inputsStr[#inputsStr+1] = ('%s×%s'):format(item, need) end
        items[#items+1] = { id = 'process:' .. key, title = (rec.icon .. ' ' .. rec.label),
            sub = 'المواد: ' .. table.concat(inputsStr, ' + '), price = rec.value }
    end
    SendNUIMessage({ action = 'openModal', title = 'معمل التحويل', items = items, foot = 'حوّل لمواد أعلى قيمة', callback = 'farm2' })
    SetNuiFocus(true, true)
end

function openSiloMenu()
    local items = { { id = 'upgradesilo', title = 'ترقية الصومعة', sub = ('الحالي: مستوى %s'):format(myFarm.siloLevel or 1) } }
    SendNUIMessage({ action = 'openModal', title = 'الصومعة', items = items, foot = 'ترفع سعة التخزين', callback = 'farm2' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'farm2' then
        if id == 'plots' then openPlotMenu(1)
        elseif id == 'trees' then openTreeMenu()
        elseif id == 'processing' then openProcessingMenu()
        elseif id == 'silo' then openSiloMenu()
        elseif id == 'tools' then notify('الأدوات تُشترى من متجر المزرعة.', 'inform')
        elseif id == 'upgradesilo' then TriggerServerEvent('srp:farm2:upgradeSilo')
        elseif id:sub(1, 8) == 'harvest:' then TriggerServerEvent('srp:farm2:harvest', tonumber(id:sub(9)))
        elseif id:sub(1, 7) == 'plantf:' then
            local plotIdx, cropKey = id:match('^plantf:(%d+):(.+)$')
            TriggerServerEvent('srp:farm2:plant', tonumber(plotIdx), cropKey)
        elseif id:sub(1, 10) == 'planttree:' then TriggerServerEvent('srp:farm2:plantTree', id:sub(11))
        elseif id:sub(1, 12) == 'harvesttree:' then TriggerServerEvent('srp:farm2:harvestTree', tonumber(id:sub(13)))
        elseif id:sub(1, 8) == 'process:' then TriggerServerEvent('srp:farm2:process', id:sub(9))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('farm2', function() TriggerServerEvent('srp:farm2:request') end, false)
RegisterCommand('agriculture', function() TriggerServerEvent('srp:farm2:request') end, false)

print('[fivem-strict-rp][client] تم تحميل المزارع v1.7 الكاملة.')
