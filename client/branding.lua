--[[
    ══════════════════════════════════════════════════════════════
    الفرسان RP — طبقة ربط الهوية في العميل
    ══════════════════════════════════════════════════════════════
]]

local Branding = Branding

RegisterCommand('forsan', function()
    TriggerEvent('QBCore:Notify', ('⚔️ %s | %s'):format(Branding.Name, Branding.Tagline), 'primary')
end, false)

RegisterCommand('rules', function()
    TriggerEvent('QBCore:Notify', '📜 القوانين الكاملة في شاشة الدخول · /help للأوامر', 'inform')
end, false)

print(('[fivem-strict-rp][branding] ⚔️ %s — الهوية محمّلة'):format(Branding.Name))
