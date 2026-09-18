--[[
    fivem-strict-rp :: config/jobs.lua
    نظام الوظائف — 9 وظائف + مركز التوظيف.
    المبدأ: إنجاز فوري + بيع موارد.
]]

Jobs = {}

Jobs.Settings = {
    cooldownSeconds = 6,
    requireOnDuty   = true,
    autoPromote     = true,
    salesTaxPercent = 8,
    maxCarry        = 250,
}

Jobs.EmploymentCenter = {
    coords   = { x = -268.0, y = -957.0, z = 31.2 },
    radius   = 2.5,
    available = {
        "blacksmith", "carpenter", "miner", "garbage",
        "electrician", "water", "mechanic", "dealer",
    },
}

Jobs.List = {
    blacksmith = {
        label = "الحداد", icon = "🔨", resource = "iron_ingot",
        pickup = {
            { x = -608.0, y = -1602.0, z = 27.0, label = "مصنع الصهر" },
            { x = -580.0, y = -1750.0, z = 25.0, label = "ورشة الحدادة" },
        },
        sellPoint = { x = -560.0, y = -1830.0, z = 24.0 },
        instant   = { cash = 85, xp = 3 },
        sell      = { cash = 210 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "حدّاد", multiplier = 1.25, requirement = 40 },
            { name = "خبير", multiplier = 1.60, requirement = 120 },
            { name = "رئيس ورشة", multiplier = 2.00, requirement = 300 },
        },
    },
    carpenter = {
        label = "النجار", icon = "🪚", resource = "wood_plank",
        pickup = {
            { x = 1220.0, y = 1890.0, z = 78.0, label = "منشرة الأخشاب" },
            { x = 1090.0, y = 2020.0, z = 74.0, label = "ورشة النجارة" },
        },
        sellPoint = { x = 1055.0, y = 2100.0, z = 73.0 },
        instant   = { cash = 70, xp = 3 },
        sell      = { cash = 175 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "نجّار", multiplier = 1.25, requirement = 40 },
            { name = "خبير", multiplier = 1.60, requirement = 120 },
            { name = "رئيس ورشة", multiplier = 2.00, requirement = 300 },
        },
    },
    miner = {
        label = "المنجم", icon = "⛏️", resource = "raw_ore",
        pickup = {
            { x = 2950.0, y = 2750.0, z = 43.0, label = "المقلع الشمالي" },
            { x = -600.0, y = 2080.0, z = 130.0, label = "المقلع الجبلي" },
        },
        sellPoint = { x = 1085.0, y = -3195.0, z = 5.0 },
        instant   = { cash = 95, xp = 4 },
        sell      = { cash = 240 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "عامل منجم", multiplier = 1.25, requirement = 50 },
            { name = "خبير تعدين", multiplier = 1.65, requirement = 140 },
            { name = "مشرف مقلع", multiplier = 2.10, requirement = 320 },
        },
    },
    garbage = {
        label = "الزبال", icon = "🗑️", resource = "recyclables",
        pickup = {
            { x = -350.0, y = -1445.0, z = 30.0, label = "مكب المدينة" },
            { x = 780.0, y = -1950.0, z = 29.0, label = "مكب الميناء" },
        },
        sellPoint = { x = -330.0, y = -1520.0, z = 27.0 },
        instant   = { cash = 45, xp = 2 },
        sell      = { cash = 110 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "عامل نظافة", multiplier = 1.20, requirement = 35 },
            { name = "مشرف موقع", multiplier = 1.50, requirement = 110 },
        },
    },
    electrician = {
        label = "الكهربائي", icon = "⚡", resource = "circuit_part",
        pickup = {
            { x = 720.0, y = -1150.0, z = 24.0, label = "محطة الكهرباء" },
            { x = 1660.0, y = 2520.0, z = 45.0, label = "محوّل المدينة" },
        },
        sellPoint = { x = 700.0, y = -1080.0, z = 22.0 },
        instant   = { cash = 110, xp = 4 },
        sell      = { cash = 275 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "فنّي", multiplier = 1.30, requirement = 45 },
            { name = "مهندس", multiplier = 1.70, requirement = 150 },
            { name = "رئيس قسم", multiplier = 2.15, requirement = 340 },
        },
    },
    water = {
        label = "المياه", icon = "💧", resource = "water_tank",
        pickup = {
            { x = -1020.0, y = -2870.0, z = 13.0, label = "محطة التحلية" },
            { x = -950.0, y = -2950.0, z = 12.0, label = "خزان المدينة" },
        },
        sellPoint = { x = -1000.0, y = -2920.0, z = 12.0 },
        instant   = { cash = 80, xp = 3 },
        sell      = { cash = 195 },
        grades = {
            { name = "متدرّب", multiplier = 1.00, requirement = 0 },
            { name = "فنّي مياه", multiplier = 1.25, requirement = 40 },
            { name = "مهندس", multiplier = 1.60, requirement = 130 },
        },
    },
}

Jobs.Mechanic = {
    label = "الميكانيكي", icon = "🔧",
    job = "mechanic",
    garages = {
        { x = -340.0, y = -135.0, z = 39.0, label = "ورشة المدينة" },
        { x = 545.0, y = -180.0, z = 54.0, label = "ورشة الشمال" },
        { x = -1155.0, y = -2005.0, z = 13.0, label = "ورشة الميناء" },
    },
    services = {
        repair      = { label = "إصلاح كامل", price = 500,  duration = 12 },
        bodywork    = { label = "دهان وهيكل", price = 1200, duration = 20 },
        performance = { label = "تعديل أداء", price = 2500, duration = 30 },
        inspection  = { label = "فحص فني",    price = 150,  duration = 6  },
    },
    commissionPercent = 55,
    allowSelfRepair = false,
}

Jobs.Messages = {
    notHired       = "أنت غير مُعيَّن في هذه الوظيفة.",
    alreadyHired   = "أنت مُعيَّن مسبقاً.",
    hired          = "تم تعيينك: %s (الرتبة: %s)",
    onDuty         = "أنت الآن في الخدمة.",
    offDuty        = "أنت الآن خارج الخدمة.",
    taskComplete   = "أنجزت وحدة: +$%s",
    sold           = "بعت الموارد: +$%s (ضريبة $%s)",
    full           = "حمولتك ممتلئة — بِع مواردك أولاً.",
    promoted       = "ترقية! رتبتك الجديدة: %s",
    cooldown       = "انتظر قليلاً قبل الإنجاز التالي.",
    mechanicCalled = "تم استدعاء ميكانيكي إلى موقعك.",
    noMechanic     = "لا يوجد ميكانيكي متاح الآن.",
    repaired       = "تم إصلاح المركبة ($%s).",
}

return Jobs
