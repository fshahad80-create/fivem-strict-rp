--[[
    fivem-strict-rp :: config/land.lua
    نظام الأراضي (Land / Plots) — الستاف يمنح أرضاً، اللاعب يبني ويزرع.
]]

Land = {}

Land.Settings = {
    enabled            = true,
    maxOwnedPerPlayer  = 2,
    maxRadius          = 60.0,
    minRadius          = 8.0,
    pricePerSqm        = 45,
    sellRefundPercent  = 60,
    enforceBoundary    = false,
    reportTrespass     = false,
    defaultShape       = 'circle',
}

Land.Structures = {
    fence     = { label = "سياج",      icon = "🚧", cost = 5000,  radius = 2.0, model = "prop_fncwood_14a", maxPerPlot = 20 },
    wall      = { label = "سور",       icon = "🧱", cost = 12000, radius = 3.0, model = "prop_fncsec_01",   maxPerPlot = 10 },
    storage   = { label = "مخزن",      icon = "📦", cost = 45000, radius = 4.0, model = "prop_roadcone02a", maxPerPlot = 3, storageSlots = 20 },
    farm_plot = { label = "أرض زراعة", icon = "🌾", cost = 8000,  radius = 3.0, model = nil,               maxPerPlot = 8, farming = true },
    gate      = { label = "بوّابة",     icon = "🚪", cost = 20000, radius = 2.5, model = "prop_gate_prison_01", maxPerPlot = 2 },
}

Land.Types = {
    residential = { label = "سكنية",  color = 3, buildAllow = { "fence", "wall", "storage", "gate" } },
    farm        = { label = "زراعية",  color = 2, buildAllow = { "fence", "farm_plot", "storage" } },
    commercial  = { label = "تجارية",  color = 5, buildAllow = { "wall", "storage", "gate" } },
    industrial  = { label = "صناعية",  color = 6, buildAllow = { "wall", "storage", "fence", "gate" } },
}

Land.Messages = {
    granted       = "مُنحت الأرض للاعب (نصف القطر: %s م).",
    revoked       = "تم سحب الأرض.",
    notOwner      = "أنت لا تملك هذه الأرض.",
    maxOwned      = "وصلت للحد الأقصى من الأراضي.",
    ownerNotified = "حصلت على أرض جديدة! (نصف القطر: %s م)",
    built         = "تم بناء %s ($%s).",
    noMoney       = "لا تملك المال الكافي.",
    outside       = "لا يمكنك البناء خارج أرضك.",
    occupied      = "المكان مشغول — ابحث عن مساحة فارغة.",
    limitReached  = "وصلت للحد الأقصى من %s في هذه الأرض.",
    sold          = "بعت أرضك بـ $%s.",
    saved         = "تم حفظ الأرض.",
    usage         = "الاستخدام: /giveplot [id] [radius] [type] — الأنواع: residential, farm, commercial, industrial",
}

return Land
