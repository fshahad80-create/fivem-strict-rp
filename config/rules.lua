--[[
    fivem-strict-rp :: config/rules.lua
    نظام قوانين RP + الإشراف — الإعدادات الكاملة.
]]

Rules = {}

Rules.Enabled = {
    reports      = true,
    staffActions = true,
    autoEscalate = true,
    requireReason = true,
}

Rules.List = {
    ["disrespect"]     = { weight = 15,  action = "warn", category = "behavior", label = "إهانة اللاعبين" },
    ["harassment"]     = { weight = 30,  action = "warn", category = "behavior", label = "تحرّش أو مضايقة" },
    ["discrimination"] = { weight = 50,  action = "ban",  category = "behavior", label = "تمييز/خطاب كراهية" },
    ["mic_spam"]       = { weight = 10,  action = "warn", category = "behavior", label = "إزعاج الصوت" },
    ["failrp"]         = { weight = 20,  action = "warn", category = "roleplay", label = "كسر الأداء" },
    ["metagaming"]     = { weight = 25,  action = "warn", category = "roleplay", label = "معلومة خارج الشخصية" },
    ["powergaming"]    = { weight = 25,  action = "warn", category = "roleplay", label = "فرض فعل مستحيل" },
    ["rvdm"]           = { weight = 45,  action = "jail", category = "roleplay", label = "قتل عشوائي بمركبة" },
    ["rdm"]            = { weight = 45,  action = "jail", category = "roleplay", label = "قتل عشوائي" },
    ["breaking_character"] = { weight = 20, action = "warn", category = "roleplay", label = "الخروج من الشخصية" },
    ["combatlog"]      = { weight = 35,  action = "jail", category = "roleplay", label = "خروج أثناء مواجهة" },
    ["exploiting"]     = { weight = 80,  action = "ban",  category = "exploit",  label = "استغلال ثغرة" },
    ["duping"]         = { weight = 100, action = "ban",  category = "exploit",  label = "تكرار/نسخ العناصر" },
    ["injecting"]      = { weight = 120, action = "ban",  category = "exploit",  label = "حقن/تعديل العميل" },
    ["illegal_gun"]    = { weight = 30,  action = "jail", category = "weapons",  label = "سلاح محظور" },
    ["corruption"]     = { weight = 60,  action = "ban",  category = "weapons",  label = "فساد (POLICE)" },
    ["cop_baiting"]    = { weight = 15,  action = "warn", category = "weapons",  label = "استفزاز الشرطة" },
}

Rules.Escalation = {
    thresholds = {
        { at = 30,  action = "warn",  label = "إنذار رسمي" },
        { at = 60,  action = "warn2", label = "إنذار مشدد" },
        { at = 90,  action = "jail",  label = "سجن إداري", jailMinutes = 30 },
        { at = 130, action = "ban",   label = "حظر", banMinutes = 1440 },
        { at = 180, action = "ban",   label = "حظر دائم", banMinutes = 0 },
    },
    decayPerWeek = 10,
    keepForever  = false,
}

Rules.Actions = {
    warn = { label = "إنذار",       requiresReason = true, notifies = true },
    jail = { label = "سجن إداري",   requiresReason = true, defaultMinutes = 30 },
    kick = { label = "طرد مؤقت",    requiresReason = true, defaultMinutes = 0 },
    ban  = { label = "حظر",         requiresReason = true, defaultMinutes = 1440 },
    note = { label = "ملاحظة سرية", requiresReason = true, notifies = false },
}

Rules.Reports = {
    cooldownSeconds = 120,
    maxOpenPerPlayer = 3,
    requireActivePlayers = true,
    categories = { "behavior", "roleplay", "exploit", "weapons", "other" },
}

Rules.Records = {
    keepForever    = true,
    maxQueryRows   = 100,
    discordWebhook = "",
}

Rules.Messages = {
    reportReceived = "تم استلام تقريرك. سيتعامل معه فريق الإشراف.",
    reportCooldown = "انتظر قبل رفع تقرير آخر.",
    staffWarned    = "تم توجيه إنذار لك: %s",
    staffJailed    = "سُجنت إدارياً %s دقيقة: %s",
    staffKicked    = "طُردت مؤقتاً: %s",
    staffBanned    = "حُظرت: %s (%s)",
    escalated      = "تصعيد: %s (نقاط الإشراف %s)",
}

return Rules
