--[[
    fivem-strict-rp :: server/branding.lua
    طبقة الهوية الموحّدة — ⚔️ الفرسان RP
    أمر /branding + حدث إشعار موحّد + ترحيب مبرند + تصدير الدوال.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local B = Branding

local function log(msg) print(('[fivem-strict-rp][branding] %s'):format(msg)) end

-- ── إشعار مبرند موحّد ──────────────────────────────────────
RegisterNetEvent('srp:notify', function(msg, kind)
    local src = source
    if not msg then return end
    TriggerClientEvent('QBCore:Notify', src, ('%s | %s'):format(B.Name, msg), kind or 'primary')
end)

-- ── ترحيب عند الدخول ───────────────────────────────────────
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    Wait(6000)
    TriggerClientEvent('QBCore:Notify', src, B.format(B.Messages.welcome), 'primary')
end)

-- ── أمر /branding ──────────────────────────────────────────
QBCore.Commands.Add('branding', 'عرض هوية المدينة', {}, false, function(source)
    local src = source
    TriggerClientEvent('QBCore:Notify', src, ('%s | %s'):format(B.Name, B.Tagline), 'primary')
    TriggerClientEvent('QBCore:Notify', src, ('ديسكورد: %s'):format(B.Discord), 'inform')
end, 'user')

QBCore.Commands.Add('setname', 'عرض اسم المدينة الحالي', {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source, ('المدينة: %s (%s)'):format(B.Name, B.NameEn), 'primary')
end, 'user')

-- ── دوال عامة مُصدَّرة ─────────────────────────────────────
exports('brandName', function() return B.Name end)
exports('brandFormat', function(text) return B.format(text) end)

CreateThread(function()
    log(('تم تحميل هوية المدينة: %s — %s'):format(B.Name, B.Tagline))
end)
