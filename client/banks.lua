--[[
    fivem-strict-rp :: client/banks.lua
    البنوك — واجهة البطاقات · التحويل · القروض · الاستثمار.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Banks

local myAccount = nil
local function notify(msg, kind) TriggerEvent('QBCore:Notify', msg, kind or 'primary') end

RegisterNetEvent('srp:banks:show', function(a, data)
    myAccount = a
    data = data or {}
    local card = data.cards and data.cards[a.card]
    local items = {
        { id = 'cards',    title = 'البطاقات', sub = card and ('بطاقتك: ' .. card.label .. ' · كاش باك ' .. card.cashbackPercent .. '%') or '' },
        { id = 'transfer', title = 'تحويل', sub = ('رصيدك: $%s'):format(data.balance or 0) },
        { id = 'loans',    title = 'القروض', sub = ('قروض نشطة: %s'):format(#(a.loans or {})) },
        { id = 'invest',   title = 'الاستثمارات الخارجية', sub = 'آمن · متوازن · عالي المخاطرة' },
    }
    SendNUIMessage({ action = 'openModal', title = 'البنك', items = items, foot = ('رصيدك البنكي: $%s'):format(data.balance or 0), callback = 'bank' })
    SetNuiFocus(true, true)
end)

local function openCards()
    local items = {}
    for key, c in pairs(B.CardTiers) do
        items[#items+1] = { id = 'issuecard:' .. key, title = (c.icon .. ' ' .. c.label),
            sub = ('كاش باك %s%% · حد ائتماني $%s'):format(c.cashbackPercent, c.creditLimit), price = c.fee }
    end
    SendNUIMessage({ action = 'openModal', title = 'البطاقات', items = items, foot = 'اختر بطاقة', callback = 'bank' })
    SetNuiFocus(true, true)
end

local function openLoans()
    local items = {}
    for key, t in pairs(B.LoanTerms) do
        items[#items+1] = { id = 'takeloan:' .. key, title = t.label,
            sub = ('حد $%s · %s شهر · فائدة %s%%'):format(t.maxAmount, t.months, t.ratePercent) }
    end
    SendNUIMessage({ action = 'openModal', title = 'القروض', items = items, foot = 'اختر نوع القرض', callback = 'bank' })
    SetNuiFocus(true, true)
end

local function openInvest()
    local items = {}
    for key, inv in pairs(B.Investments) do
        items[#items+1] = { id = 'doinvest:' .. key, title = (inv.icon .. ' ' .. inv.label),
            sub = ('عائد %s%% إلى %s%% · مخاطرة %s%%'):format(math.floor(inv.returnMin * 100), math.floor(inv.returnMax * 100), inv.riskPercent) }
    end
    SendNUIMessage({ action = 'openModal', title = 'الاستثمارات', items = items, foot = 'المخاطرة مقابل العائد', callback = 'bank' })
    SetNuiFocus(true, true)
end

RegisterNUICallback('ui:select', function(data, cb)
    local id = data.id or ''
    local callback = data.callback or ''
    if callback == 'bank' then
        if id == 'cards' then openCards()
        elseif id == 'transfer' then notify('استخدم: /transfer [id] [مبلغ]', 'inform')
        elseif id == 'loans' then openLoans()
        elseif id == 'invest' then openInvest()
        elseif id:sub(1, 10) == 'issuecard:' then TriggerServerEvent('srp:banks:issueCard', id:sub(11))
        elseif id:sub(1, 9) == 'takeloan:' then TriggerServerEvent('srp:banks:takeLoan', id:sub(10))
        elseif id:sub(1, 9) == 'doinvest:' then notify(('استخدم: /invest %s [مبلغ]'):format(id:sub(10)), 'inform')
        end
    end
    cb({ ok = true })
end)

RegisterCommand('bank', function() TriggerServerEvent('srp:banks:request') end, false)
RegisterCommand('transfer', function(source, args) TriggerServerEvent('srp:banks:transfer', tonumber(args[1]), tonumber(args[2])) end, false)
RegisterCommand('invest', function(source, args)
    local invType = args[1]; local amount = tonumber(args[2])
    if invType and amount then TriggerServerEvent('srp:banks:invest', invType, amount) end
end, false)

print('[fivem-strict-rp][client] تم تحميل نظام البنوك المتقدم.')
