--[[
    fivem-strict-rp :: client/legal.lua
    المحاماة والمحكمة + العقود — ناجز · لوحة القاضي · عقود · كاتب عدل.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local Lg = Legal

local myData = {}
local lastAction = 0
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

local function getClosestPlayer()
    local coords = GetEntityCoords(PlayerPedId())
    local closest, minDist = nil, 5.0
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            if DoesEntityExist(ped) then
                local dist = #(coords - GetEntityCoords(ped))
                if dist < minDist then minDist = dist; closest = GetPlayerServerId(player) end
            end
        end
    end
    return closest
end

CreateThread(function()
    Wait(7000)
    local c = Lg.Locations.court
    local b1 = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(b1, 419) SetBlipColour(b1, 5) SetBlipScale(b1, 1.0) SetBlipAsShortRange(b1, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('المحكمة') EndTextCommandSetBlipName(b1)
    local n = Lg.Locations.notary
    local b2 = AddBlipForCoord(n.x, n.y, n.z)
    SetBlipSprite(b2, 500) SetBlipColour(b2, 3) SetBlipScale(b2, 0.9) SetBlipAsShortRange(b2, true)
    BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName('الكاتب العدل') EndTextCommandSetBlipName(b2)
end)

CreateThread(function()
    Wait(7500)
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local c = Lg.Locations.court
        if #(coords - vector3(c.x, c.y, c.z)) < 30.0 then
            sleep = 0
            DrawMarker(1, c.x, c.y, c.z - 1.0, 0,0,0, 0,0,0, 1.6,1.6,0.9, 155,89,182,140, false, true, 2, false)
            if #(coords - vector3(c.x, c.y, c.z)) < 2.5 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ لفتح المحكمة')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                    lastAction = GetGameTimer()
                    TriggerServerEvent('srp:legal:request')
                end
            end
        end
        local n = Lg.Locations.notary
        if #(coords - vector3(n.x, n.y, n.z)) < 30.0 then
            sleep = 0
            if #(coords - vector3(n.x, n.y, n.z)) < 2.5 then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('اضغط ~INPUT_CONTEXT~ للكاتب العدل')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) and (GetGameTimer() - lastAction) > 1000 then
                    lastAction = GetGameTimer()
                    openNotaryMenu()
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('srp:legal:show', function(data)
    myData = data
    openMainMenu()
end)

function openMainMenu()
    local job = myData.job or ''
    local items = {
        { id = 'najiz',    title = 'ناجز — دعاوى', sub = 'رفع دعوى / متابعة قضاياي' },
        { id = 'contract', title = 'العقود', sub = 'إنشاء · توقيع مزدوج' },
        { id = 'notary',   title = 'الكاتب العدل', sub = 'توثيق · وكالة · شهادة' },
    }
    if job == Lg.Settings.judgeJob then
        items[#items+1] = { id = 'court', title = 'لوحة القاضي', sub = 'الدعاوى المفتوحة · إصدار أحكام' }
        items[#items+1] = { id = 'issuelicense', title = 'إصدار ترخيص محاماة', sub = 'على اللاعب القريب' }
    end
    local foot = myData.isLawyer and 'محامٍ معتمد' or 'غير معتمد كمحامٍ'
    SendNUIMessage({ action = 'openModal', title = 'العدالة والقضاء', items = items, foot = foot, callback = 'legal' })
    SetNuiFocus(true, true)
end

function openNajiz()
    local items = {
        { id = 'filecase', title = 'رفع دعوى جديدة', sub = 'على اللاعب القريب' },
        { id = 'mycases',  title = 'قضاياي', sub = 'الدعاوى المرفوعة ضدك أو منك' },
    }
    SendNUIMessage({ action = 'openModal', title = 'ناجز', items = items, foot = '', callback = 'legal' })
    SetNuiFocus(true, true)
end

function openCaseTypes()
    local items = {}
    for key, ct in pairs(myData.caseTypes or {}) do
        items[#items+1] = { id = 'docase:' .. key, title = (ct.icon .. ' ' .. ct.label), sub = '' }
    end
    SendNUIMessage({ action = 'openModal', title = 'نوع الدعوى', items = items, foot = 'على اللاعب القريب', callback = 'legal' })
    SetNuiFocus(true, true)
end

function openMyCases()
    local items = {}
    for _, c in ipairs(myData.cases or {}) do
        items[#items+1] = { id = 'noop', title = ('#%s %s'):format(c.id, c.title), sub = ('%s · حالة: %s'):format(c.type, c.status) }
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا قضايا', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'قضاياي', items = items, foot = '', callback = 'none' })
    SetNuiFocus(true, true)
end

function openNotaryMenu()
    local items = {}
    for key, s in pairs(Lg.Sentencing.services) do
        items[#items+1] = { id = 'notary:' .. key, title = s.label, sub = '', price = s.price }
    end
    SendNUIMessage({ action = 'openModal', title = 'الكاتب العدل', items = items, foot = '', callback = 'legal' })
    SetNuiFocus(true, true)
end

RegisterNetEvent('srp:legal:showOpenCases', function(rows)
    local items = {}
    for _, c in ipairs(rows) do
        items[#items+1] = { id = 'judgecase:' .. c.id, title = ('#%s %s'):format(c.id, c.title), sub = ('%s ضد %s'):format(c.plaintiff_name, c.defendant_name) }
    end
    if #items == 0 then items[#items+1] = { id = 'noop', title = 'لا دعاوى مفتوحة', sub = '' } end
    SendNUIMessage({ action = 'openModal', title = 'الدعاوى المفتوحة', items = items, foot = 'اختر دعوى للفصل فيها', callback = 'legal' })
    SetNuiFocus(true, true)
end

function openVerdictMenu(caseId)
    local items = {}
    for key, v in pairs(myData.verdicts) do
        items[#items+1] = { id = ('verdict:%s:%s'):format(caseId, key), title = (v.icon .. ' ' .. v.label), sub = '' }
    end
    SendNUIMessage({ action = 'openModal', title = 'إصدار حكم', items = items, foot = 'غرامة/سجن حسب نوع الحكم', callback = 'legal' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'legal' then
        if id == 'najiz' then openNajiz()
        elseif id == 'filecase' then openCaseTypes()
        elseif id == 'mycases' then openMyCases()
        elseif id == 'contract' then notify('استخدم: /contract [id] [عنوان]', 'inform')
        elseif id == 'notary' then openNotaryMenu()
        elseif id == 'court' then TriggerServerEvent('srp:legal:requestOpenCases')
        elseif id == 'issuelicense' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:legal:issueLicense', t) else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id:sub(1, 7) == 'docase:' then
            local t = getClosestPlayer()
            if t then TriggerServerEvent('srp:legal:fileCase', t, id:sub(8), 'دعوى جديدة', 'تفاصيل الدعوى') else notify('لا يوجد لاعب قريب.', 'error') end
        elseif id:sub(1, 10) == 'judgecase:' then openVerdictMenu(tonumber(id:sub(11)))
        elseif id:sub(1, 8) == 'verdict:' then
            local caseId, vkey = id:match('^verdict:(%d+):(.+)$')
            local fine = (vkey == 'guilty' or vkey == 'settled') and 20000 or 0
            local jail = (vkey == 'guilty') and 6 or 0
            TriggerServerEvent('srp:legal:issueVerdict', tonumber(caseId), vkey, fine, jail)
        elseif id:sub(1, 7) == 'notary:' then TriggerServerEvent('srp:legal:notaryService', id:sub(8))
        end
    end
    cb({ ok = true })
end)

RegisterCommand('legal', function() TriggerServerEvent('srp:legal:request') end, false)
RegisterCommand('najiz', function() TriggerServerEvent('srp:legal:request') end, false)
RegisterCommand('contract', function(source, args)
    local target = tonumber(args[1])
    local title = table.concat(args, ' ', 2)
    if target then TriggerServerEvent('srp:legal:createContract', target, title ~= '' and title or 'عقد', 'تفاصيل العقد') end
end, false)
RegisterCommand('sign', function(source, args)
    local id = tonumber(args[1])
    if id then TriggerServerEvent('srp:legal:signContract', id) end
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام المحاماة والمحكمة.')
