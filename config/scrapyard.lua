--[[
    fivem-strict-rp :: config/scrapyard.lua
    نظام تشليح المركبات (تفكيك ⇒ قطع غيار + معادن)
]]

Scrapyard = {}

Scrapyard.Settings = {
    enabled            = true,
    baseSalvageFee     = 500,
    valueRefundPercent = 35,
    dismantleTime      = 20,
    minEngineHealth    = 0.0,
    blockOwnedVehicles = true,
    blockedClasses     = { 18 },
    xpPerDismantle     = 8,
}

Scrapyard.Locations = {
    { id = 1, label = "تشليح الميناء", x = 1120.0, y = -2100.0, z = 33.0, radius = 40.0, blip = { sprite = 380, color = 5 } },
    { id = 2, label = "تشليح الصناعية", x = 2000.0, y = -1750.0, z = 25.0, radius = 45.0, blip = { sprite = 380, color = 5 } },
}

Scrapyard.Outputs = {
    steel_plate    = { label = "صفيحة فولاذ",   icon = "🪨", chance = 60, qtyMin = 2, qtyMax = 5, value = 320 },
    engine_part    = { label = "قطعة محرك",     icon = "⚙️", chance = 35, qtyMin = 1, qtyMax = 3, value = 380 },
    brake_pad      = { label = "فحمات فرامل",   icon = "🛑", chance = 45, qtyMin = 2, qtyMax = 4, value = 240 },
    suspension_kit = { label = "طقم تعليق",     icon = "🔧", chance = 20, qtyMin = 1, qtyMax = 2, value = 520 },
    tire           = { label = "إطار",           icon = "🛞", chance = 50, qtyMin = 2, qtyMax = 4, value = 200 },
    circuit_part   = { label = "قطعة إلكترونية", icon = "🔌", chance = 25, qtyMin = 1, qtyMax = 3, value = 450 },
    metal_beam     = { label = "عارضة معدنية",   icon = "🏗️", chance = 30, qtyMin = 2, qtyMax = 4, value = 280 },
    engine_block   = { label = "بلوك محرك",      icon = "🧱", chance = 12, qtyMin = 1, qtyMax = 1, value = 9000 },
    turbocharger   = { label = "تيربو",          icon = "💨", chance = 8,  qtyMin = 1, qtyMax = 1, value = 14000 },
    glass          = { label = "زجاج",            icon = "🪟", chance = 40, qtyMin = 2, qtyMax = 6, value = 90 },
    rubber         = { label = "مطاط",            icon = "⚫", chance = 55, qtyMin = 3, qtyMax = 8, value = 60 },
}

Scrapyard.Tiers = {
    { level = 1, label = "عامل تشليح" },
    { level = 2, label = "فنّي تشليح" },
    { level = 3, label = "خبير تفكيك" },
}

Scrapyard.SellPoint = { x = 1120.0, y = -2120.0, z = 33.0 }

Scrapyard.Messages = {
    notInArea     = "لا توجد مركبة قريبة للتشليح.",
    ownedBlocked  = "لا يمكن تشليح مركبات اللاعبين المملوكة.",
    started       = "بدأ التشليح...",
    dismantled    = "فُكّكت المركبة — حصلت على %s قطعة",
    salvaged      = "تشليح %s — القيمة: $%s",
    soldItem      = "بيع %s × %s — $%s",
    noItems       = "لا تملك قطعاً للبيع.",
    levelUp       = "مستوى التشليح: %s",
    cooldown      = "انتظر قليلاً قبل تشليح مركبة أخرى.",
    upgrade       = "ترقية: %s",
    noMoney       = "لا تملك المال الكافي.",
}

return Scrapyard
