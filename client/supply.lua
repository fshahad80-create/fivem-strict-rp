--[[
    fivem-strict-rp :: client/supply.lua
    جهة العميل لسلسلة التوريد: نقاط التعدين/الصهر + الواجهة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local S = Supply

local myJob = nil
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function refreshJob()
    local pd = QBCore.Functions.GetPlayerData()
    myJob = pd.job and pd.job.name or nil
end
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job) myJob = job.name end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() refreshJob() end)

CreateThread(function()
    Wait(6000)
    for _, p in ipairs(S.Locations.mine.points) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 527) SetBlipColour(b, 5) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('منجم — ' .. p.label) EndTextCommandSetBlipName(b)
    end
    for _, p in ipairs(S.Locations.forge.points) do
        local b = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(b, 1) SetBlipColour(b, 1) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('حدادة — ' .. p.label) EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    Wait(6500)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        refreshJob()
        if myJob == 'miner' then
            for _, p in ipairs(S.Locations.mine.points) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.3,1.3,0.8, 230,126,34,140, false, true, 2, false)
                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ للاستخراج')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 4000 then
                            lastAction = GetGameTimer()
                            openMineMenu()
                        end
                    end
                end
            end
        end
        if myJob == 'blacksmith' then
            for _, p in ipairs(S.Locations.forge.points) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.3,1.3,0.8, 192,57,43,140, false, true, 2, false)
                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح وصفات التصنيع')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                            lastAction = GetGameTimer()
                            openForgeMenu()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

function openMineMenu()
    local items = {}
    for key, ore in pairs(S.Raw) do
        items[#items+1] = { id = 'mine:' .. key, title = (ore.icon .. ' ' .. ore.label), sub = ('قيمة بيع: $%s/وحدة'):format(ore.baseValue) }
    end
    SendNUIMessage({ action = 'openModal', title = '⛏️ استخراج الخام', items = items, foot = 'اختر نوع الخام', callback = 'supply' })
    SetNuiFocus(true, true)
end

function openForgeMenu()
    local items = {}
    for key, rec in pairs(S.Recipes) do
        local inputsStr = {}
        for item, n in pairs(rec.inputs) do
            local nm = (S.Raw[item] and S.Raw[item].label) or item
            inputsStr[#inputsStr+1] = ('%s×%s'):format(nm, n)
        end
        items[#items+1] = {
            id = 'craft:' .. key,
            title = (rec.icon .. ' ' .. rec.label),
            sub = 'المواد: ' .. table.concat(inputsStr, ' + ') .. (rec.fuel > 0 and (' | فحم×' .. rec.fuel) or ''),
        }
    end
    SendNUIMessage({ action = 'openModal', title = '🔨 وصفات التصنيع', items = items, foot = 'اختر وصفة', callback = 'supply' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:supply:showStock', function(stock, data)
    local items = {}
    for key, qty in pairs(stock) do
        local def = data.raw[key] or data.crafted[key]
        if def then
            items[#items+1] = {
                id = 'sell:' .. key,
                title = (def.icon .. ' ' .. def.label .. ' × ' .. qty),
                sub = ('قيمة البيع: $%s/وحدة'):format(def.baseValue),
            }
        end
    end
    if #items == 0 then notify('مخزونك فارغ.', 'inform') return end
    SendNUIMessage({ action = 'openModal', title = '📦 مخزونك', items = items, foot = 'اختر عنصراً لبيعه', callback = 'supply' })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'supply' then
        if id:sub(1, 5) == 'mine:' then
            TriggerServerEvent('srp:supply:mine', id:sub(6))
        elseif id:sub(1, 6) == 'craft:' then
            TriggerServerEvent('srp:supply:craft', id:sub(7))
        elseif id:sub(1, 5) == 'sell:' then
            local item = id:sub(6)
            if S.Raw[item] then TriggerServerEvent('srp:supply:sellRaw', item) else TriggerServerEvent('srp:supply:sellCrafted', item) end
        end
    end
    cb({ ok = true })
end)

RegisterCommand('stock', function() TriggerServerEvent('srp:supply:requestStock') end, false)

print('[fivem-strict-rp][client] تم تحميل سلسلة التوريد.')
