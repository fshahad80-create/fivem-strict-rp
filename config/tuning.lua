--[[
    fivem-strict-rp :: config/tuning.lua
    الميكانيك العميق: داينو · بناء المكائن · البرمجة · الحرارة/التآكل
]]

Tuning = {}

Tuning.Settings = {
    enabled          = true,
    requireMechanic  = true,
    requireOnDuty    = true,
    godmodeCap       = 1500,
    baseWearPerKm    = 0.010,
    overheatThreshold = 110.0,
    maxEngineTemp    = 145.0,
}

Tuning.Engines = {
    stock  = { label = "مكينة أصلية", icon = "🔧", hp = 300,  torque = 220, weight = 1.00, soundVariants = { "stock", "sport" }, wearRate = 0.8, fuelMul = 1.00, buildCost = 15000,  buildTime = 60,  parts = { engine_v6 = 1 } },
    sport  = { label = "مكينة رياضية", icon = "🏎️", hp = 520,  torque = 380, weight = 0.98, soundVariants = { "sport", "turbo", "v8" }, wearRate = 1.1, fuelMul = 1.15, buildCost = 35000,  buildTime = 120, parts = { engine_v8 = 1, turbocharger = 1 } },
    racing = { label = "مكينة سباق", icon = "🏁", hp = 780,  torque = 540, weight = 0.95, soundVariants = { "race", "turbo", "v10" }, wearRate = 1.5, fuelMul = 1.35, buildCost = 70000,  buildTime = 200, parts = { engine_ls = 1, turbocharger = 2, crankshaft = 1 } },
    beast  = { label = "مكينة وحش", icon = "🔥", hp = 1150, torque = 780, weight = 0.92, soundVariants = { "beast", "turbo", "v12" }, wearRate = 2.2, fuelMul = 1.70, buildCost = 140000, buildTime = 320, parts = { engine_race = 1, turbocharger = 3, crankshaft = 2, camshaft = 2 } },
}

Tuning.Chips = {
    stock   = { label = "بدون برمجة",    hpBonus = 1.00, fuelMul = 1.00, wearMul = 1.00, cost = 0 },
    stage1  = { label = "برمجة مرحل 1",  hpBonus = 1.08, fuelMul = 1.10, wearMul = 1.25, cost = 12000 },
    stage2  = { label = "برمجة مرحل 2",  hpBonus = 1.18, fuelMul = 1.25, wearMul = 1.60, cost = 28000 },
    stage3  = { label = "برمجة مرحل 3",  hpBonus = 1.32, fuelMul = 1.45, wearMul = 2.10, cost = 55000 },
    extreme = { label = "برمجة قصوى",    hpBonus = 1.50, fuelMul = 1.80, wearMul = 3.00, cost = 95000 },
}

Tuning.Oil = {
    types = {
        oil_5000  = { label = "زيت 5,000 كم",  durabilityKm = 5000,  cost = 800,  protection = 0.85 },
        oil_10000 = { label = "زيت 10,000 كم", durabilityKm = 10000, cost = 1600, protection = 1.00 },
    },
    heatPerKmOverdue = 0.9,
    wearMulWhenOverdue = 2.5,
}

Tuning.Dyno = {
    cost = 1500,
    durationMs = 8000,
    rpmRange = { 1000, 8000 },
    degradedHpThreshold = 0.7,
}

Tuning.Maintenance = {
    recommendEveryKm = 2000,
    fullServiceCost = 5000,
    fullServiceRestore = 0.40,
    rebuildCost = 25000,
}

Tuning.Messages = {
    built       = "تم بناء %s — الصوت: %s",
    chipApplied = "تم تطبيق %s (+%s%% قوة، استهلاك ×%s)",
    oilChanged  = "تم تغيير %s (يكفي %s كم)",
    dynoResult  = "داينو: %s حصان · %s نيوتن · العمر %s%%",
    overheating = "المكينة تحترق! بدّل الزيت فوراً.",
    wornOut     = "المكينة متآكلة — تحتاج صيانة.",
    rebuilt     = "تم تجديد المكينة بالكامل.",
    noMechanic  = "هذه العملية تتطلب ميكانيكياً.",
    needParts   = "تنقصك قطع لبناء هذه المكينة.",
    notOwned    = "أنت لست مالك هذه المركبة.",
}

return Tuning
