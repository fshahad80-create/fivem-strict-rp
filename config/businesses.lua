--[[
    fivem-strict-rp :: config/businesses.lua
    نظام الأعمال القابلة للشراء + المزارع + التوظيف
    أنواع: مزرعة · ورشة · محطة وقود · بنك · مصنع · بقالة
    نموذج الملكية: مالك + توظيف لاعبين بحصص ورواتب.
]]

Businesses = {}

Businesses.Settings = {
    payoutIntervalMinutes = 60,
    profitTaxPercent = 15,
    maintenancePercent = 20,
    maxOwnedPerPlayer = 3,
    allowTransfer = true,
    maxUpgradeLevel = 5,
    employeeSharePercent = 25,
}

Businesses.Types = {
    farm = {
        label = "مزرعة", icon = "🌾",
        buyPrice = 250000, baseIncome = 1200, maintenance = 250, capacity = 100,
        requiresWorker = true, interactive = true,
        jobs = { worker = { label = "عامل حقل", maxWorkers = 5, share = 20 } },
        upgrades = { [1]=1.00, [2]=1.35, [3]=1.75, [4]=2.25, [5]=3.00 },
        plots = {
            { x = 2000.0, y = 4900.0, z = 41.0, label = "حقل شمالي" },
            { x = 2100.0, y = 5000.0, z = 41.0, label = "حقل شرقي" },
            { x = 1900.0, y = 4800.0, z = 41.0, label = "حقل غربي" },
        },
    },
    workshop = {
        label = "ورشة", icon = "🔧",
        buyPrice = 400000, baseIncome = 2000, maintenance = 500, capacity = 5,
        jobs = {
            manager  = { label = "مدير ورشة", maxWorkers = 1, share = 15 },
            mechanic = { label = "ميكانيكي",  maxWorkers = 4, share = 55 },
        },
        upgrades = { [1]=1.00, [2]=1.40, [3]=1.85, [4]=2.40, [5]=3.20 },
    },
    gasstation = {
        label = "محطة وقود", icon = "⛽",
        buyPrice = 600000, baseIncome = 3000, maintenance = 800, capacity = 8,
        jobs = {
            cashier = { label = "أمين صندوق", maxWorkers = 3, share = 40 },
            manager = { label = "مدير محطة",  maxWorkers = 1, share = 15 },
        },
        upgrades = { [1]=1.00, [2]=1.30, [3]=1.65, [4]=2.10, [5]=2.80 },
    },
    bank = {
        label = "بنك", icon = "🏦",
        buyPrice = 1500000, baseIncome = 8000, maintenance = 2500, capacity = 20,
        jobs = {
            teller  = { label = "موظف حوالات", maxWorkers = 4, share = 45 },
            manager = { label = "مدير بنك",    maxWorkers = 2, share = 25 },
        },
        upgrades = { [1]=1.00, [2]=1.25, [3]=1.55, [4]=1.90, [5]=2.50 },
    },
    factory = {
        label = "مصنع", icon = "🏭",
        buyPrice = 1000000, baseIncome = 5000, maintenance = 1500, capacity = 15,
        jobs = {
            worker  = { label = "عامل خط إنتاج", maxWorkers = 8, share = 45 },
            foreman = { label = "مشرف",          maxWorkers = 2, share = 30 },
        },
        upgrades = { [1]=1.00, [2]=1.35, [3]=1.70, [4]=2.15, [5]=2.90 },
    },
    grocery = {
        label = "بقالة", icon = "🛒",
        buyPrice = 150000, baseIncome = 900, maintenance = 200, capacity = 4,
        jobs = {
            cashier     = { label = "بائع",       maxWorkers = 3, share = 50 },
            storekeeper = { label = "أمين مخزن", maxWorkers = 2, share = 40 },
        },
        upgrades = { [1]=1.00, [2]=1.35, [3]=1.75, [4]=2.20, [5]=2.95 },
    },
}

Businesses.Locations = {
    farm       = { x = 2050.0, y = 4950.0, z = 41.0 },
    workshop   = { x = -340.0, y = -135.0, z = 39.0 },
    gasstation = { x = 1207.0, y = -1402.0, z = 35.0 },
    bank       = { x = 150.0,  y = -1040.0, z = 29.0 },
    factory    = { x = 1100.0, y = -2000.0, z = 35.0 },
    grocery    = { x = 25.0,   y = -1347.0, z = 29.0 },
}

Businesses.Farming = {
    crops = {
        wheat  = { label = "قمح",   growMinutes = 5, yieldMin = 8,  yieldMax = 14, sellPrice = 55 },
        corn   = { label = "ذرة",   growMinutes = 7, yieldMin = 6,  yieldMax = 11, sellPrice = 80 },
        tomato = { label = "طماطم", growMinutes = 4, yieldMin = 10, yieldMax = 18, sellPrice = 40 },
    },
    seedCost = 15,
    maxPlantedPerPlot = 1,
    requiresWater = true,
}

Businesses.Messages = {
    purchased    = "اشتريت %s بـ $%s",
    sold         = "بعت %s بـ $%s",
    alreadyOwned = "أنت تملك هذا العمل مسبقاً.",
    maxOwned     = "وصلت للحد الأقصى من الأعمال.",
    notOwner     = "أنت لست مالك هذا العمل.",
    noMoney      = "لا تملك المال الكافي.",
    upgraded     = "تم ترقية %s إلى المستوى %s.",
    hired        = "تم توظيف %s في منصب %s.",
    fired        = "تم إنهاء عمل %s.",
    profitPaid   = "أرباح %s: +$%s (بعد ضريبة $%s وصيانة $%s)",
    workerPaid   = "راتبك من %s: +$%s",
    noWorkers    = "لا يوجد عاملون في هذا العمل.",
    planted      = "زرعت %s — ينمو خلال %s دقيقة.",
    harvested    = "حصَدت %s × %s",
    needWater    = "المزرعة تحتاج ماء أولاً.",
    plotBusy     = "هذه الأرض مزروعة بالفعل.",
}

return Businesses
