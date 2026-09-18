--[[
    fivem-strict-rp :: client/carpenter.lua
    النجار — ورشة · تصنيع · وضع العناصر · تصاريح.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local C = Carpenter

local myLevel = {}
local myRecipes = {}
local myMaterials = {}
local myPermits = {}
local myPlaced = {}
local buildMode = false
local buildItem = nil
local lastAction = 0
local placedObjs = {}
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function spawnObj(model, x, y, z, rot)
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 60 do Wait(50) t = t + 1 end
    if not HasModelLoaded(model) then return end
    local obj = CreateObject(model, x, y, z, false, false, false)
    SetEntityHeading(obj, rot or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)
    placedObjs[#placedObjs + 1] = obj
end

RegisterNetEvent('srp:carpenter:spawnPlaced', function(itemKey, x, y, z, rot)
    local models = { crafting_table = "prop_tablesaw_01", crate_100 = "prop_crate_01a", storage_shed = "prop_shed_01", stall_kit = "prop_stall_01" }
    local model = models[itemKey]
    if model then spawnObj(model, x, y, z, rot) end
end)

CreateThread(function()
    Wait(7000)
    for _, p in ipairs(C.Locations.workshop.points) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 1) SetBlipColour(b, 2) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('نجارة — ' .. p.label) EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        for _, p in ipairs(C.Locations.workshop.points) do
            local dist = #(coords - vector3(p.x, p.y, p.z))
            if dist < 25.0 then
                sleep = 0
                DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.3,1.3,0.8, 230,126,34,140, false, true, 2, false)
                if dist < 1.8 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح وصفات النجارة')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                        lastAction = GetGameTimer()
                        TriggerServerEvent('srp:carpenter:request')
                    end
                end
            end
        end
        if buildMode and buildItem then
            sleep = 0
            local ped = PlayerPedId()
            local pc = GetEntityCoords(ped)
            local fwd = GetEntityForwardVector(ped)
            local bx, by, bz = pc.x + fwd.x * 3.0, pc.y + fwd.y * 3.0, pc.z
            local rot = GetEntityHeading(ped)
            DrawMarker(1, bx, by, bz - 1.0, 0,0,0, 0,0,0, 2.0,2.0,1.0, 46,204,113,150, false, true, 2, false)
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('ضع %s — ~INPUT_CONTEXT~ للتثبيت · ~INPUT_CELLPHONE_CANCEL~ للإلغاء'):format(buildItem))
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustReleased(0, 38) then
                TriggerServerEvent('srp:carpenter:place', buildItem, bx, by, bz, rot)
                buildMode = false; buildItem = nil
            end
            if IsControlJustReleased(0, 177) then
                buildMode = false; buildItem = nil
                notify('أُلغي الوضع.', 'inform')
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:carpenter:show', function(level, recipes, materials, permits, placed)
    myLevel = level; myRecipes = recipes; myMaterials = materials; myPermits = permits; myPlaced = placed
    openMainMenu()
end)

function openMainMenu()
    local items = {
        { id = 'craft',   title = 'وصفات التصنيع', sub = 'ألواح · صناديق · طاولات · أكشاك' },
        { id = 'permits', title = 'التصاريح', sub = 'تصريح كشك' },
        { id = 'sell',    title = 'بيع المواد الخام', sub = 'ألواح · أعمدة' },
    }
    local foot = ('مستوى النجار: %s · خبرة: %s'):format(myLevel.level or 1, myLevel.xp or 0)
    SendNUIMessage({ action = 'openModal', title = 'النجارة', items = items, foot = foot, callback = 'carpenter' })
    SetNuiFocus(true, true)
end

function openCraftMenu()
    local items = {}
    for key, rec in pairs(myRecipes) do
        local inputsStr = {}
        for item, need in pairs(rec.inputs) do inputsStr[#inputsStr+1] = ('%s×%s'):format(item, need) end
        local tag = rec.placeable and ' [قابل للوضع]' or (rec.storage and (' [تخزين ' .. rec.storage .. ']') or '')
        items[#items+1] = { id = 'craft:' .. key, title = (rec.icon .. ' ' .. rec.label .. tag), sub = 'المواد: ' .. table.concat(inputsStr, ' + ') }
    end
    SendNUIMessage({ action = 'openModal', title = 'وصفات التصنيع', items = items, foot = 'اختر وصفة', callback = 'carpenter' })
    SetNuiFocus(true, true)
end

function openSellMenu()
    local items = {}
    for key, m in pairs(myMaterials) do
        items[#items+1] = { id = 'sellm:' .. key, title = ('بيع ' .. m.label), sub = ('$%s/وحدة'):format(m.value), price = m.value }
    end
    SendNUIMessage({ action = 'openModal', title = 'بيع المواد', items = items, foot = 'بيع كل ما تملك', callback = 'carpenter' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'carpenter' then
        if id == 'craft' then openCraftMenu()
        elseif id == 'permits' then TriggerServerEvent('srp:carpenter:buyPermit')
        elseif id == 'sell' then openSellMenu()
        elseif id:sub(1, 6) == 'craft:' then
            local key = id:sub(7)
            local rec = myRecipes[key]
            TriggerServerEvent('srp:carpenter:craft', key)
            if rec and rec.placeable then notify(('يمكنك وضع %s بـ /place'):format(rec.label), 'inform') end
        elseif id:sub(1, 6) == 'sellm:' then TriggerServerEvent('srp:carpenter:sell', id:sub(7))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('carpenter', function() TriggerServerEvent('srp:carpenter:request') end, false)
RegisterCommand('place', function(source, args)
    local item = args[1]
    if item then buildItem = item; buildMode = true; notify('وضع البناء مُفعّل.', 'inform') end
end, false)

print('[fivem-strict-rp][client] تم تحميل النجار العميق.')
