--[[
    fivem-strict-rp :: config/penalties.lua
    نظام العقوبات التلقائية — إعدادات كاملة قابلة للتعديل.
]]

Penalties = {}

Penalties.Enabled = {
    wanted          = true,
    autoSentencing  = true,
    bounties        = false,
    licenseRevoke   = true,
    escalation      = true,
}

Penalties.Points = {
    thresholds = {
        warning     = 10,
        fine        = 25,
        jail        = 45,
        heavyJail   = 70,
        banReview   = 100,
    },
    decay = {
        enabled       = true,
        amountPerHour = 2,
        minPoints     = 0,
    },
    resetAfterDays = 30,
}

Penalties.Offenses = {
    ["speeding_minor"]   = { points = 4,  fine = 250,   jail = 0,  category = "traffic",   license = nil,       label = "سرعة زائدة بسيطة" },
    ["speeding_major"]   = { points = 9,  fine = 750,   jail = 0,  category = "traffic",   license = nil,       label = "سرعة جنونية" },
    ["reckless_driving"] = { points = 12, fine = 1000,  jail = 0,  category = "traffic",   license = "driver",  label = "قيادة متهورة" },
    ["hit_and_run"]      = { points = 22, fine = 2500,  jail = 10, category = "traffic",   license = "driver",  label = "هروب بعد حادث" },
    ["assault"]          = { points = 18, fine = 3000,  jail = 15, category = "violent",   license = nil,       label = "اعتداء" },
    ["assault_leo"]      = { points = 35, fine = 6000,  jail = 30, category = "violent",   license = nil,       label = "اعتداء على عنصر أمن" },
    ["armed_robbery"]    = { points = 40, fine = 8000,  jail = 40, category = "violent",   license = nil,       label = "سطو مسلّح" },
    ["kidnapping"]       = { points = 55, fine = 12000, jail = 60, category = "violent",   license = nil,       label = "اختطاف" },
    ["murder"]           = { points = 80, fine = 20000, jail = 90, category = "violent",   license = "weapon",  label = "قتل" },
    ["illegal_firearm"]  = { points = 20, fine = 4000,  jail = 12, category = "weapons",   license = "weapon",  label = "حيازة سلاح غير مرخّص" },
    ["drug_possession"]  = { points = 16, fine = 3500,  jail = 10, category = "drugs",     license = nil,       label = "حيازة مواد" },
    ["drug_trafficking"] = { points = 45, fine = 15000, jail = 50, category = "drugs",     license = nil,       label = "ترويج مواد" },
    ["fail_rp"]          = { points = 10, fine = 1000,  jail = 0,  category = "rp",        license = nil,       label = "كسر قواعد الأداء (FailRP)" },
    ["metagaming"]       = { points = 12, fine = 1500,  jail = 0,  category = "rp",        license = nil,       label = "معلومة خارج الشخصية" },
    ["powergaming"]      = { points = 12, fine = 1500,  jail = 0,  category = "rp",        license = nil,       label = "فرض فعل مستحيل" },
    ["rvdm"]             = { points = 35, fine = 5000,  jail = 20, category = "rp",        license = nil,       label = "قتل عشوائي بمركبة" },
    ["combat_log"]       = { points = 30, fine = 4000,  jail = 25, category = "rp",        license = nil,       label = "خروج أثناء مواجهة" },
    ["tax_evasion"]      = { points = 20, fine = 3000,  jail = 10, category = "financial", license = nil,       label = "تهرب ضريبي" },
    ["bill_default"]     = { points = 12, fine = 1500,  jail = 0,  category = "financial", license = nil,       label = "تأخر في سداد الالتزامات" },
    ["insurance_fraud"]  = { points = 25, fine = 5000,  jail = 15, category = "financial", license = "driver",  label = "عدم سداد التأمين" },
}

Penalties.Sentencing = {
    escalationMultipliers = {
        [0] = 1.00,
        [1] = 1.25,
        [2] = 1.50,
        [3] = 1.75,
        [4] = 2.00,
    },
    maxFine        = 100000,
    maxJailMinutes = 180,
    cooperationDiscount = 0.75,
    communityServiceInsteadOfUnpaid = true,
    communityServiceMinutesPer1000 = 3,
}

Penalties.Bans = {
    autoBanAtPoints   = 120,
    autoBanDuration   = 0,
    instantBanOffenses = {},
    offenseBanDurations = {
        ["combat_log"] = 1440,
    },
}

Penalties.Wanted = {
    enabled          = true,
    minWantedLevel   = 1,
    maxWantedLevel   = 5,
    cooldownSeconds  = 600,
    broadcastInterval = 20,
    autoSentenceOnArrest = true,
}

Penalties.Records = {
    keepForever    = true,
    maxQueryRows   = 250,
    discordWebhook = "",
}

Penalties.Messages = {
    wanted         = "أنت مطلوب",
    arrested       = "تم توقيفك. جاري حساب العقوبة...",
    sentenced      = "تم الحكم: غرامة $%s · سجن %s دقيقة.",
    fineReceived   = "تم تغريمك $%s (%s).",
    licenseRevoked = "تم سحب رخصة: %s",
    banned         = "تم حظرك. السبب: %s",
    pointsWarning  = "نقاطك وصلت %s",
}

return Penalties
