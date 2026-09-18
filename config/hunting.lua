--[[
    fivem-strict-rp :: config/hunting.lua
    نظام صيد البحر والبر
]]

Hunting = {}

Hunting.Settings = {
    enabled        = true,
    catchCooldown  = 6,
    maxWeight      = 60,
    qualityMin     = 1,
    qualityMax     = 5,
    qualityMultipliers = { [1] = 0.7, [2] = 0.9, [3] = 1.0, [4] = 1.25, [5] = 1.6 },
}

Hunting.Tools = {
    rod_basic   = { label = "سنارة عادية",       icon = "🎣", tier = 1, bonusQuality = 0.00, bonusYield = 0, price = 5000 },
    rod_pro     = { label = "سنارة احترافية",     icon = "🎣", tier = 2, bonusQuality = 0.15, bonusYield = 1, price = 25000 },
    rod_master  = { label = "سنارة الصياد الماهر", icon = "🎣", tier = 3, bonusQuality = 0.30, bonusYield = 2, price = 80000 },
    rifle_basic = { label = "بندقية صيد",         icon = "🔫", tier = 1, bonusQuality = 0.00, bonusYield = 0, price = 8000 },
    rifle_pro   = { label = "بندقية دقيقة",       icon = "🔫", tier = 2, bonusQuality = 0.15, bonusYield = 1, price = 35000 },
    rifle_master= { label = "قناص الصيد",         icon = "🔫", tier = 3, bonusQuality = 0.30, bonusYield = 2, price = 100000 },
}

Hunting.SeaCatch = {
    { key = "sardine",  label = "سردين",   icon = "🐟", rarity = "common",    baseValue = 40,  weight = 1 },
    { key = "bream",    label = "كنعد",    icon = "🐟", rarity = "common",    baseValue = 70,  weight = 2 },
    { key = "hamour",   label = "هامور",   icon = "🐠", rarity = "uncommon",  baseValue = 150, weight = 3 },
    { key = "shrimp",   label = "روبيان",  icon = "🦐", rarity = "uncommon",  baseValue = 120, weight = 1 },
    { key = "lobster",  label = "كركند",   icon = "🦞", rarity = "rare",      baseValue = 400, weight = 3 },
    { key = "tuna",     label = "تونة",    icon = "🐟", rarity = "rare",      baseValue = 350, weight = 4 },
    { key = "swordfish",label = "سمك سيف", icon = "🐟", rarity = "epic",      baseValue = 700, weight = 5 },
    { key = "shark",    label = "قرش صغير", icon = "🦈", rarity = "legendary", baseValue = 1500, weight = 8 },
}

Hunting.LandCatch = {
    { key = "rabbit",  label = "أرنب",     icon = "🐇", rarity = "common",    baseValue = 50,  weight = 1, pelt = "pelt_rabbit",  meat = "meat_small" },
    { key = "bird",    label = "طائر",     icon = "🐦", rarity = "common",    baseValue = 60,  weight = 1, pelt = "feather",      meat = "meat_small" },
    { key = "deer",    label = "غزال",     icon = "🦌", rarity = "uncommon",  baseValue = 180, weight = 4, pelt = "pelt_deer",    meat = "meat_medium" },
    { key = "boar",    label = "خنزير بري", icon = "🐗", rarity = "rare",     baseValue = 320, weight = 6, pelt = "pelt_boar",    meat = "meat_medium" },
    { key = "wolf",    label = "ذئب",      icon = "🐺", rarity = "rare",      baseValue = 450, weight = 3, pelt = "pelt_wolf",    meat = "meat_medium" },
    { key = "cougar",  label = "أسد جبلي", icon = "🐆", rarity = "epic",     baseValue = 900, weight = 5, pelt = "pelt_cougar",  meat = "meat_large" },
    { key = "bear",    label = "دبّ",      icon = "🐻", rarity = "legendary", baseValue = 1800, weight = 9, pelt = "pelt_bear",    meat = "meat_large" },
}

Hunting.RarityWeights = {
    common = 45, uncommon = 28, rare = 18, epic = 7, legendary = 2,
}

Hunting.Locations = {
    sea = {
        label = "صيد البحر", icon = "🎣",
        zones = {
            { x = -1600.0, y = -1100.0, z = 2.0, label = "رصيف الميناء" },
            { x = 3400.0,  y = 3800.0,  z = 2.0, label = "شاطئ شمالي" },
        },
        sellPoint = { x = -1670.0, y = -1100.0, z = 3.0 },
        restaurantPoint = { x = 120.0, y = -1050.0, z = 29.0 },
    },
    land = {
        label = "صيد البر", icon = "🦌",
        zones = {
            { x = -1400.0, y = 4700.0, z = 150.0, label = "محمية الريف" },
            { x = 2800.0,  y = 6000.0, z = 30.0, label = "صحراء الصيد" },
        },
        sellPoint = { x = -1570.0, y = 4700.0, z = 150.0 },
    },
}

Hunting.Messages = {
    caught      = "اصطدت %s (%s★) — القيمة $%s",
    hunted      = "أصبت %s (%s★) — جلد ولحم",
    sold        = "بعت %s بـ $%s",
    noTool      = "تحتاج أداة صيد.",
    noCatch     = "لا تملك غنائم لبيعها.",
    weightFull  = "حمولتك ممتلئة.",
    toolRequired = "هذه الأداة لل%s فقط.",
    upgraded    = "ترقية %s",
}

return Hunting
