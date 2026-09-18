--[[
    fivem-strict-rp :: config/branding.lua
    هوية المدينة الموحّدة — ⚔️ الفرسان RP
    عدّل كل شيء من هنا — لا تعدّل ملفات السيرفر.
]]

Branding = {}

-- ── 1. هوية المدينة ─────────────────────────────────────────
Branding.Name       = "الفرسان RP"
Branding.NameEn     = "AL-FORSAN RP"
Branding.Tagline    = "حيث الشرف والمجد"
Branding.TaglineEn  = "Where Honor & Glory"
Branding.Icon       = "⚔️"
Branding.Prefix     = "⚔️ الفرسان RP"
Branding.Color      = "#d4af37"

-- ── 2. روابط ────────────────────────────────────────────────
Branding.Discord    = "https://discord.gg/forsan"
Branding.RulesUrl   = ""
Branding.Website    = ""

-- ── 3. أسماء الإشعارات المخصّصة ─────────────────────────────
Branding.NotifyStyles = {
    success = "نجاح",
    error   = "خطأ",
    inform  = "معلومة",
    primary = "الفرسان",
}

-- ── 4. رسائل الدخول والترحيب ────────────────────────────────
Branding.Messages = {
    welcome     = "👋 أهلاً بك في {name} — {tagline}",
    welcomeBack = "👋 عدت أخيراً إلى {name}",
    goodbye     = "وداعاً! ننتظرك في {name} ⚔️",
    serverName  = "مدينة {name}",
    help = "اكتب /help للقائمة · /ask للمساعد · {icon} {tagline}",
}

-- ── 5. تذييل موحّد ──────────────────────────────────────────
Branding.Footer = "⚔️ الفرسان RP — حيث الشرف والمجد"

-- ── 6. دالة تطبيق الهوية ────────────────────────────────────
function Branding.format(text)
    if not text then return "" end
    text = text:gsub("{name}",     Branding.Name)
    text = text:gsub("{tagline}",  Branding.Tagline)
    text = text:gsub("{icon}",     Branding.Icon)
    text = text:gsub("{discord}",  Branding.Discord)
    return text
end

return Branding
