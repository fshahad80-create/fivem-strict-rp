--[[
    fivem-strict-rp :: client/jobs.lua
    جهة العميل لنظام الوظائف: نقاط العمل + التفاعل.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local J = Jobs

local myJob = nil
local myCarry = 0
local lastAction = 0

local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function makeBlip(coords, label, sprite, color)
    local b = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(b, sprite or 1) SetBlipColour(b, color or 2) SetBlipScale(b, 0.9) SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(label) EndTextCommandSetBlipName(b)
end

local function refreshJob()
    local pd = QBCore.Functions.GetPlayerData()
    myJob = pd.job and pd.job.name or nil
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job) myJob = job.name end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() refreshJob() end)
RegisterNetEvent('srp:jobs:updateCarry', function(job, qty) if job == myJob then myCarry = qty end end)
RegisterNetEvent('srp:jobs:showProgress', function(job, p, grade)
    notify(('%s — %s | إنجازات: %s | بيع: %s | أرباح: $%s'):format(job, grade.name, p.count, p.sold, p.earned), 'primary')
end)

CreateThread(function()
    Wait(4000)
    local ec = J.EmploymentCenter
    makeBlip(ec.coords, 'مركز التوظيف', 407, 5)
    for key, def in pairs(J.List) do
        for _, p in ipairs(def.pickup) do makeBlip(p, def.label .. ' — ' .. p.label, 1, 2) end
        makeBlip(def.sellPoint, def.label .. ' — بيع', 500, 2)
    end
end)

CreateThread(function()
    Wait(5000)
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        refreshJob()
        if myJob and J.List[myJob] then
            local def = J.List[myJob]
            for _, p in ipairs(def.pickup) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0,0,0, 0,0,0, 1.2,1.2,0.8, 41,128,185,140, false, true, 2, false)
                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ للإنجاز')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > (J.Settings.cooldownSeconds * 1000) then
                            lastAction = GetGameTimer()
                            TriggerServerEvent('srp:jobs:completeTask', myJob)
                        end
                    end
                end
            end
            local sp = def.sellPoint
            local sdist = #(coords - vector3(sp.x, sp.y, sp.z))
            if sdist < 25.0 then
                sleep = 0
                DrawMarker(1, sp.x, sp.y, sp.z - 1.0, 0,0,0, 0,0,0, 1.2,1.2,0.8, 46,204,113,140, false, true, 2, false)
                if sdist < 1.8 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(('اضغط ~INPUT_CONTEXT~ لبيع الموارد (%s)'):format(myCarry))
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then TriggerServerEvent('srp:jobs:sell', myJob) end
                end
            end
        end
        local ec = J.EmploymentCenter
        local edist = #(coords - vector3(ec.coords.x, ec.coords.y, ec.coords.z))
        if edist < 25.0 then
            sleep = 0
            DrawMarker(1, ec.coords.x, ec.coords.y, ec.coords.z - 1.0, 0,0,0, 0,0,0, 1.5,1.5,0.8, 155,89,182,140, false, true, 2, false)
            if edist < 2.0 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح مركز التوظيف')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) then
                    notify('الوظائف المتاحة: ' .. table.concat(J.EmploymentCenter.available, ' / '), 'primary')
                    notify('استخدم /hire [job] لتقديم الطلب', 'inform')
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('hire', function(source, args)
    local job = args[1]
    if not job then notify('الوظائف المتاحة: ' .. table.concat(J.EmploymentCenter.available, ', '), 'primary') return end
    local valid = false
    for _, j in ipairs(J.EmploymentCenter.available) do if j == job then valid = true break end end
    if not valid then notify('وظيفة غير متاحة.', 'error') return end
    TriggerServerEvent('srp:jobs:hire', job)
end, false)

RegisterCommand('duty', function() TriggerServerEvent('srp:jobs:toggleDuty') end, false)

RegisterCommand('myjob', function()
    if myJob and J.List[myJob] then TriggerServerEvent('srp:jobs:requestProgress', myJob)
    else notify('لا وظيفة تقدّم حالياً.', 'inform') end
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الوظائف.')
