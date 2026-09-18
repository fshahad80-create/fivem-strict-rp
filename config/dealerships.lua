--[[
    fivem-strict-rp :: config/dealerships.lua
    نظام معارض السيارات — الإعدادات (مع الاستلام الفوري).
]]

Dealerships = {}

Dealerships.Settings = {
    purchaseTaxPercent = 10,
    salesCommissionPercent = 12,
    registrationFee = 350,
    requireOnDuty = true,
    maxOwnedVehicles = 8,
    -- الاستلام الفوري
    instantDelivery = true,
    deliveryPlateStyle = 'srp',
    giveKeysOnDelivery = true,
    deliveryTimeoutMs = 8000,
}

Dealerships.List = {
    city = {
        label = "معرض المدينة", job = "dealer",
        coords = { x = -56.0, y = -1098.0, z = 26.0 },
        spawn  = { x = -31.0, y = -1073.0, z = 28.0, h = 90.0 },
        blip   = { sprite = 326, color = 3 },
        categories = { "economy", "sedan", "suv" },
    },
    luxury = {
        label = "معرض الفخامة", job = "dealer",
        coords = { x = -818.0, y = -762.0, z = 22.0 },
        spawn  = { x = -790.0, y = -740.0, z = 24.0, h = 180.0 },
        blip   = { sprite = 326, color = 27 },
        categories = { "sports", "luxury" },
    },
    industrial = {
        label = "معرض الصناعي", job = "dealer",
        coords = { x = 1200.0, y = -1270.0, z = 35.0 },
        spawn  = { x = 1230.0, y = -1250.0, z = 36.0, h = 90.0 },
        blip   = { sprite = 326, color = 5 },
        categories = { "industrial", "utility" },
    },
}

Dealerships.Vehicles = {
    ["blista"]    = { model = "blista",    label = "Blista",    category = "economy",    price = 18000,  stock = nil },
    ["asea"]      = { model = "asea",      label = "Asea",      category = "economy",    price = 15000,  stock = nil },
    ["premier"]   = { model = "premier",   label = "Premier",   category = "sedan",      price = 28000,  stock = nil },
    ["seminole"]  = { model = "seminole",  label = "Seminole",  category = "suv",        price = 42000,  stock = 5 },
    ["granger"]   = { model = "granger",   label = "Granger",   category = "suv",        price = 55000,  stock = 4 },
    ["comet"]     = { model = "comet",     label = "Comet",     category = "sports",     price = 120000, stock = 3 },
    ["jester"]    = { model = "jester",    label = "Jester",    category = "sports",     price = 145000, stock = 2 },
    ["schafter"]  = { model = "schafter",  label = "Schafter",  category = "luxury",     price = 180000, stock = 2 },
    ["cognoscenti"] = { model = "cognoscenti", label = "Cognoscenti", category = "luxury", price = 220000, stock = 1 },
    ["mule"]      = { model = "mule",      label = "Mule",      category = "industrial", price = 90000,  stock = 3 },
    ["phantom"]   = { model = "phantom",   label = "Phantom",   category = "industrial", price = 250000, stock = 2 },
    ["towtruck"]  = { model = "towtruck",  label = "Tow Truck", category = "utility",    price = 65000,  stock = 4 },
    ["boxville"]  = { model = "boxville",  label = "Boxville",  category = "utility",    price = 48000,  stock = 5 },
}

Dealerships.DealerGrades = {
    { name = "متعاون",   commissionBonus = 0.00, requirement = 0 },
    { name = "بائع",     commissionBonus = 0.03, requirement = 5 },
    { name = "بائع أول",  commissionBonus = 0.06, requirement = 15 },
    { name = "مدير معرض", commissionBonus = 0.10, requirement = 40 },
}

Dealerships.Messages = {
    noMoney      = "لا تملك المال الكافي.",
    maxOwned     = "وصلت للحد الأقصى من المركبات.",
    outOfStock   = "هذه المركبة نفدت من المخزون.",
    purchased    = "تم شراء %s بـ $%s.",
    sold         = "تم بيع %s (عمولتك: $%s).",
    noVehicle    = "لا تملك هذه المركبة.",
    registered   = "تم تسجيل المركبة +$%s رسوم.",
}

return Dealerships
