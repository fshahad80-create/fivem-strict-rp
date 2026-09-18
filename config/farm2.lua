--[[
    fivem-strict-rp :: config/farm2.lua
    المزارع v1.7 الكاملة — مواسم · جودة نجوم · أشجار دائمة · رشاشات · معمل.
]]

Farm2 = {}

Farm2.Settings = {
    enabled         = true,
    maxLevel        = 40,
    xpPerHarvest    = 12,
    seasonCycleHours = 24,
    sprinklerIntervalMin = 30,
    pestChancePercent = 8,
    weatherChancePercent = 6,
}

Farm2.CropTiers = {
    { tier = 1, label = "محاصيل سريعة",  growMin = 4,  yieldMin = 8,  yieldMax = 14, baseValue = 45 },
    { tier = 2, label = "محاصيل متوسطة", growMin = 8,  yieldMin = 6,  yieldMax = 11, baseValue = 90 },
    { tier = 3, label = "محاصيل بطيئة",  growMin = 14, yieldMin = 4,  yieldMax = 8,  baseValue = 180 },
    { tier = 4, label = "محاصيل نادرة",  growMin = 22, yieldMin = 2,  yieldMax = 5,  baseValue = 450 },
}

Farm2.Crops = {
    { key = "wheat",    label = "قمح",      icon = "🌾", tier = 1, sellPrice = 40 },
    { key = "tomato",   label = "طماطم",    icon = "🍅", tier = 1, sellPrice = 55 },
    { key = "potato",   label = "بطاطس",    icon = "🥔", tier = 1, sellPrice = 50 },
    { key = "hay",      label = "برسيم",    icon = "🌿", tier = 1, sellPrice = 35, feed = true },
    { key = "corn",     label = "ذرة",      icon = "🌽", tier = 2, sellPrice = 95, feed = true },
    { key = "carrot",   label = "جزر",      icon = "🥕", tier = 2, sellPrice = 85 },
    { key = "onion",    label = "بصل",      icon = "🧅", tier = 2, sellPrice = 80 },
    { key = "coffee",   label = "بن",       icon = "☕", tier = 3, sellPrice = 220 },
    { key = "grape",    label = "عنب",      icon = "🍇", tier = 3, sellPrice = 190 },
    { key = "cotton",   label = "قطن",      icon = "🌸", tier = 4, sellPrice = 480 },
    { key = "marijuana",label = "قنّب",     icon = "🌿", tier = 4, sellPrice = 700, illegal = true },
}

Farm2.Trees = {
    apple  = { label = "شجرة تفاح",  icon = "🍎", plantCost = 25000, firstYieldMin = 60, regrowMin = 30, yieldQty = 12, sellPrice = 70 },
    orange = { label = "شجرة برتقال", icon = "🍊", plantCost = 25000, firstYieldMin = 60, regrowMin = 30, yieldQty = 12, sellPrice = 75 },
    olive  = { label = "شجرة زيتون",  icon = "🫒", plantCost = 40000, firstYieldMin = 90, regrowMin = 45, yieldQty = 10, sellPrice = 130 },
}

Farm2.Seasons = {
    spring = { label = "الربيع", icon = "🌸", growMul = 1.20, priceMul = 1.00 },
    summer = { label = "الصيف",  icon = "☀️", growMul = 1.10, priceMul = 1.15 },
    autumn = { label = "الخريف", icon = "🍂", growMul = 1.00, priceMul = 1.30 },
    winter = { label = "الشتاء", icon = "❄️", growMul = 0.70, priceMul = 1.10 },
}

Farm2.Tools = {
    hoe_basic  = { label = "فأس عادي",       icon = "⛏️", tier = 1, yieldBonus = 0.00, speedBonus = 0.00, price = 3000 },
    hoe_pro    = { label = "فأس احترافي",    icon = "⛏️", tier = 2, yieldBonus = 0.15, speedBonus = 0.20, price = 18000 },
    hoe_master = { label = "فأس المزارع الماهر", icon = "⛏️", tier = 3, yieldBonus = 0.30, speedBonus = 0.35, price = 60000 },
}

Farm2.Processing = {
    flour  = { label = "طحين",  icon = "🌾", inputs = { wheat = 5 },          output = "flour",  qty = 2, value = 120 },
    bread  = { label = "خبز",   icon = "🍞", inputs = { wheat = 8, corn = 2 }, output = "bread",  qty = 3, value = 180 },
    oil    = { label = "زيت",   icon = "🫒", inputs = { olive = 6 },          output = "oil",    qty = 2, value = 220 },
    juice  = { label = "عصير",  icon = "🧃", inputs = { orange = 5 },         output = "juice",  qty = 3, value = 140 },
    cheese = { label = "جبن",   icon = "🧀", inputs = { milk = 4 },           output = "cheese", qty = 2, value = 200 },
    jam    = { label = "مربى",  icon = "🍯", inputs = { grape = 4 },          output = "jam",    qty = 2, value = 260 },
}

Farm2.Silo = {
    levels = {
        { level = 1, capacity = 500,  upgradeCost = 0 },
        { level = 2, capacity = 1500, upgradeCost = 50000 },
        { level = 3, capacity = 4000, upgradeCost = 150000 },
        { level = 4, capacity = 10000, upgradeCost = 400000 },
    },
}

Farm2.Locations = {
    plots = {
        { x = 2000.0, y = 4900.0, z = 41.0, label = "حقل 1" },
        { x = 2100.0, y = 5000.0, z = 41.0, label = "حقل 2" },
        { x = 1900.0, y = 4800.0, z = 41.0, label = "حقل 3" },
        { x = 2200.0, y = 4850.0, z = 41.0, label = "حقل 4" },
    },
    trees = {
        { x = 1950.0, y = 4950.0, z = 41.0, label = "بستان 1" },
        { x = 2150.0, y = 5050.0, z = 41.0, label = "بستان 2" },
    },
    processing = { x = 2050.0, y = 5100.0, z = 41.0, label = "معمل المزرعة" },
    silo       = { x = 1850.0, y = 4900.0, z = 41.0, label = "الصومعة" },
}

Farm2.Messages = {
    planted      = "زرعت %s (ينمو خلال %s دقيقة)",
    harvested    = "حصدت %s × %s (%s★) — القيمة $%s",
    sold         = "بعت %s بـ $%s",
    treeReady    = "الشجرة جاهزة للحصاد",
    processed    = "صنعت %s × %s",
    siloUpgraded = "رُقّيت الصومعة للمستوى %s",
    pestAttack   = "آفة هاجمت محصولك!",
    weatherEvent = "عاصفة/موجة حر أثرت على مزرعتك.",
    levelUp      = "مستوى الفلاح: %s",
    seasonChanged = "الموسم الآن: %s",
    noMoney      = "لا تملك المال الكافي.",
    noWater      = "المزرعة تحتاج ماء.",
}

return Farm2
