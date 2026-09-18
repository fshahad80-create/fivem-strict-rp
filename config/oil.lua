--[[
    fivem-strict-rp :: config/oil.lua
    نظام النفط (استخراج · تكرير · تسعير)
]]

Oil = {}

Oil.Settings = {
    enabled         = true,
    extractCooldown = 8,
    refineCooldown  = 12,
    refineCost      = 150,
    minPricePerLiter = 15,
    maxPricePerLiter = 60,
    defaultPricePerLiter = 25,
}

Oil.Resources = {
    crude_oil    = { label = "نفط خام",    icon = "🛢️", value = 90,  weight = 6 },
    refined_fuel = { label = "بنزين مكرر", icon = "⛽", value = 220, weight = 5 },
    diesel       = { label = "ديزل",       icon = "🛢️", value = 180, weight = 5 },
    propane      = { label = "غاز بروبان", icon = "🔥", value = 140, weight = 4 },
}

Oil.Recipes = {
    stage1 = {
        label = "تكرير أولي", icon = "⚙️", time = 15,
        inputs = { crude_oil = 5 }, output = "refined_fuel", outputQty = 2,
    },
    stage2 = {
        label = "تكرير نهائي (ديزل)", icon = "⚙️", time = 20,
        inputs = { crude_oil = 4, propane = 1 }, output = "diesel", outputQty = 3,
        bonusOutput = "propane", bonusQty = 1,
    },
    propane = {
        label = "فصل غاز بروبان", icon = "🔥", time = 12,
        inputs = { crude_oil = 3 }, output = "propane", outputQty = 2,
    },
}

Oil.Locations = {
    oilfield = {
        label = "حقل النفط", job = "oilworker", icon = "🛢️",
        points = {
            { x = 400.0,  y = 6400.0, z = 30.0, label = "بئر النفط - صحراء" },
            { x = 1500.0, y = 6300.0, z = 30.0, label = "بئر النفط - الشرق" },
        },
    },
    refinery = {
        label = "المصفاة", job = "oilworker", icon = "🏭",
        points = {
            { x = 2790.0, y = -1700.0, z = 10.0, label = "مصفاة الميناء" },
        },
        sellPoint = { x = 2800.0, y = -1600.0, z = 10.0 },
    },
}

Oil.Stations = {
    { id = 1, x = 1207.0, y = -1402.0, z = 35.0,  label = "محطة وسط المدينة", basePrice = 25 },
    { id = 2, x = 620.0,  y = 268.0,   z = 103.0, label = "محطة توكو",         basePrice = 25 },
    { id = 3, x = -70.0,  y = -1761.0, z = 29.0,  label = "محطة غروف",         basePrice = 25 },
    { id = 4, x = -526.0, y = -1211.0, z = 18.0,  label = "محطة الساحل",       basePrice = 25 },
}

Oil.Messages = {
    extracted    = "استخرجت %s × %s",
    refined      = "كرّرت: %s × %s",
    refuelStation = "زُوّدت المحطة بـ %s لتر ($%s)",
    priceSet     = "تم ضبط سعر اللتر: $%s",
    notOwner     = "أنت لست مالك المحطة.",
    needCrude    = "تحتاج نفطاً خاماً.",
    noMoney      = "لا تملك المال الكافي.",
    notOilworker = "هذه وظيفة عامل النفط.",
    stationLow   = "خزان المحطة منخفض — اطلب تزويداً.",
}

return Oil
