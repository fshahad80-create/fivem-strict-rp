--[[
    fivem-strict-rp :: client/emergency.lua
    الأمن العام والإسعاف — قوائم الأدوات · MDT · تنفيذ العلاج.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local E = Emergency

local myJob = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function refreshJob()
    local pd = QBCore.Functions.GetPlayerData()
    myJob = pd.job and pd.job.name or nil
end
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job) myJob = job.name end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() refreshJob() end)

local function getClosestPlayer()
    local coords = GetEntityCoords(PlayerPedId())
    local closest, minDist = nil, 4.0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local otherPed = GetPlayerPed(player)
            if DoesEntityExist(otherPed) then
                local dist = #(coords - GetEntityCoords(otherPed))
                if dist < minDist then minDist = dist; closest = GetPlayerServerId(player) end
            end
        end
    end
    return closest
end

local function openPoliceMenu()
    local items = {
        { id = 'warrant',     title = 'إصدار مذكرة', sub = 'تفتيش · قبض · استدعاء' },
        { id = 'fingerprint', title = 'تبصيم', sub = 'تبصيم اللاعب القريب' },
        { id = 'fine',        title = 'مخالفة مرورية', sub = 'تحرير مخالفة' },
        { id = 'bodycam',     title = 'بودي كام', sub = 'تشغيل / إيقاف' },
        { id = 'mdt',         title = 'MDT', sub = 'قاعدة بيانات الشرطة' },
        { id = 'report',      title = 'إنشاء تقرير', sub = 'تقرير حادثة' },
    }
    SendNUIMessage({ action = 'openModal', title = 'أدوات الأمن العام', items = items, foot = '', callback = 'emergency_police' })
    SetNuiFocus(true, true)
end

local function openEMSMenu()
    local items = {
        { id = 'treat',     title = 'علاج', sub = 'خدمات الإسعاف' },
        { id = 'insurance', title = 'التأمين الطبي', sub = 'شراء تأمين' },
        { id = 'report',    title = 'تقرير إصابة', sub = '' },
    }
    SendNUIMessage({ action = 'openModal', title = 'أدوات الإسعاف', items = items, foot = '', callback = 'emergency_ems' })
    SetNuiFocus(true, true)
end

local function openWarrantTypes()
    local items = {}
    for key, w in pairs(E.WarrantTypes) do items[#items+1] = { id = 'dowarrant:' .. key, title = (w.icon .. ' ' .. w.label), sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'نوع المذكرة', items = items, foot = 'على اللاعب القريب', callback = 'emergency_police' })
    SetNuiFocus(true, true)
end

local function openFineTypes()
    local items = {}
    for key, f in pairs(E.TrafficFines) do items[#items+1] = { id = 'dofine:' .. key, title = f.label, sub = '', price = f.amount } end
    SendNUIMessage({ action = 'openModal', title = 'نوع المخالفة', items = items, foot = 'على اللاعب القريب', callback = 'emergency_police' })
    SetNuiFocus(true, true)
end

local function openEMSServices()
    local items = {}
    for key, s in pairs(E.EMSServices) do items[#items+1] = { id = 'dotreat:' .. key, title = s.label, sub = ('المدة: %s دقيقة'):format(s.duration), price = s.price } end
    SendNUIMessage({ action = 'openModal', title = 'خدمة الإسعاف', items = items, foot = 'على اللاعب القريب', callback = 'emergency_ems' })
    SetNuiFocus(true, true)
end

local function openInsurancePlans()
    local items = {}
    for key, p in pairs(E.Insurance.plans) do items[#items+1] = { id = 'dobuyins:' .. key, title = p.label, sub = ('تغطية %s%%'):format(p.coveragePercent), price = p.premium } end
    SendNUIMessage({ action = 'openModal', title = 'التأمين الطبي', items = items, foot = '', callback = 'emergency_ems' })
    SetNuiFocus(true, true)
end

local function openMDT()
    local items = {
        { id = 'mdt:warrants', title = 'المذكرات النشطة', sub = '' },
        { id = 'mdt:reports',  title = 'التقارير', sub = '' },
        { id = 'mdt:fines',    title = 'المخالفات غير المدفوعة', sub = '' },
    }
    SendNUIMessage({ action = 'openModal', title = 'MDT', items = items, foot = 'قاعدة بيانات الأمن العام', callback = 'emergency_police' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:emergency:mdtResult', function(kind, rows)
    local items = {}
    if kind == 'warrants' then
        for _, w in ipairs(rows) do items[#items+1] = { id = 'noop', title = ('%s — %s'):format(w.type, w.target_name), sub = w.reason or '' } end
    elseif kind == 'reports' then
        for _, r in ipairs(rows) do items[#items+1] = { id = 'noop', title = ('#%s %s'):format(r.id, r.title), sub = ('%s · %s'):format(r.author_name, r.created) } end
    elseif kind == 'fines' then
        for _, f in ipairs(rows) do items[#items+1] = { id = 'noop', title = ('%s — $%s'):format(f.label, f.amount), sub = f.citizenid } end
    elseif kind == 'citizen' then
        for _, c in ipairs(rows) do items[#items+1] = { id = 'noop', title = 'البصمة: ' .. c.prints, sub = '' } end
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا نتائج', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'نتائج MDT', items = items, foot = '', callback = 'none' })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('srp:emergency:doTreat', function(medicSrc, targetSrc)
    local mySrc = GetPlayerServerId(PlayerId())
    if mySrc == tonumber(targetSrc) then
        local ped = PlayerPedId()
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)
        ClearPedBloodDamage(ped)
    end
end)

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'emergency_police' then
        if id == 'warrant' then openWarrantTypes()
        elseif id == 'fingerprint' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:emergency:fingerprint', t) else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id == 'fine' then openFineTypes()
        elseif id == 'bodycam' then TriggerServerEvent('srp:emergency:toggleBodycam')
        elseif id == 'mdt' then openMDT()
        elseif id == 'report' then notify('استخدم: /report [عنوان]', 'inform')
        elseif id:sub(1, 10) == 'dowarrant:' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:emergency:issueWarrant', t, id:sub(11), 'سبب غير محدد') else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id:sub(1, 8) == 'dofine:' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:emergency:issueFine', t, id:sub(9)) else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id:sub(1, 4) == 'mdt:' then TriggerServerEvent('srp:emergency:mdtQuery', id:sub(5))
        end
    elseif callback == 'emergency_ems' then
        if id == 'treat' then openEMSServices()
        elseif id == 'insurance' then openInsurancePlans()
        elseif id == 'report' then notify('استخدم: /report [عنوان]', 'inform')
        elseif id:sub(1, 8) == 'dotreat:' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:emergency:treat', t, id:sub(9)) else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id:sub(1, 9) == 'dobuyins:' then TriggerServerEvent('srp:emergency:buyInsurance', id:sub(10))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('pd', function() openPoliceMenu() end, false)
RegisterCommand('ems', function() openEMSMenu() end, false)
RegisterCommand('mdt', function() openMDT() end, false)
RegisterCommand('bodycam', function() TriggerServerEvent('srp:emergency:toggleBodycam') end, false)
RegisterCommand('report', function(source, args)
    local title = table.concat(args, ' ')
    if title ~= '' then TriggerServerEvent('srp:emergency:createReport', myJob == E.Settings.policeJob and 'police' or 'ems', title, 'تفاصيل التقرير', {}) end
end, false)
RegisterCommand('insure', function() TriggerServerEvent('srp:emergency:buyInsurance', 'basic') end, false)

print('[fivem-strict-rp][client] تم تحميل نظام الأمن العام والإسعاف.')
