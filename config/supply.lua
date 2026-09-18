--[[
    fivem-strict-rp :: config/supply.lua
    سلسلة التوريد: منجم → حداد → ميكانيكي (محركات + قطع داخلية + كام/تيربو/تظليل).
]]

Supply = {}

Supply.Settings = {
    enabled            = true,
    inventoryMode      = 'auto',
    salesTaxPercent    = 8,
    maxPerItem         = 500,
    smeltingFuelPerCraft = 1,
    maxConcurrentCrafts = 1,
}

Supply.Raw = {
    iron_ore   = { label = "خام حديد",   icon = "⛏️", baseValue = 45,  weight = 5, mineTime = 6 },
    copper_ore = { label = "خام نحاس",   icon = "🥉", baseValue = 60,  weight = 4, mineTime = 8 },
    coal       = { label = "فحم",         icon = "⚫", baseValue = 30,  weight = 3, mineTime = 4 },
    aluminum   = { label = "ألمنيوم خام", icon = "🔩", baseValue = 75,  weight = 6, mineTime = 9 },
}

Supply.Crafted = {
    engine_part    = { label = "قطعة محرك",    icon = "⚙️", baseValue = 380, weight = 8,  category = "parts" },
    brake_pad      = { label = "فحمات فرامل",  icon = "🛑", baseValue = 240, weight = 4,  category = "parts" },
    suspension_kit = { label = "طقم تعليق",    icon = "🔧", baseValue = 520, weight = 10, category = "parts" },
    tire           = { label = "إطار",          icon = "🛞", baseValue = 200, weight = 12, category = "parts" },
    repair_kit     = { label = "عدة إصلاح",    icon = "🧰", baseValue = 450, weight = 7,  category = "tools" },
    welder_tool    = { label = "أداة لحام",    icon = "🔥", baseValue = 600, weight = 9,  category = "tools" },
    wrench         = { label = "مفتاح صيانة",  icon = "🔩", baseValue = 150, weight = 3,  category = "tools" },
    steel_plate    = { label = "صفيحة فولاذ",  icon = "🪨", baseValue = 320, weight = 15, category = "materials" },
    metal_beam     = { label = "عارضة معدنية", icon = "🏗️", baseValue = 280, weight = 14, category = "materials" },
}

Supply.Recipes = {
    engine_part    = { label = "صناعة قطعة محرك",     icon = "⚙️", inputs = { iron_ore = 4, copper_ore = 2 }, fuel = 2, time = 12, output = "engine_part", outputQty = 1 },
    brake_pad      = { label = "صناعة فحمات فرامل",   icon = "🛑", inputs = { iron_ore = 3 }, fuel = 1, time = 8, output = "brake_pad", outputQty = 2 },
    suspension_kit = { label = "صناعة طقم تعليق",     icon = "🔧", inputs = { iron_ore = 5, aluminum = 2 }, fuel = 2, time = 16, output = "suspension_kit", outputQty = 1 },
    tire           = { label = "صناعة إطار",           icon = "🛞", inputs = { copper_ore = 1, coal = 2 }, fuel = 1, time = 6, output = "tire", outputQty = 2 },
    repair_kit     = { label = "صناعة عدة إصلاح",     icon = "🧰", inputs = { iron_ore = 3, copper_ore = 1 }, fuel = 1, time = 10, output = "repair_kit", outputQty = 1 },
    welder_tool    = { label = "صناعة أداة لحام",     icon = "🔥", inputs = { iron_ore = 4, copper_ore = 3 }, fuel = 2, time = 14, output = "welder_tool", outputQty = 1 },
    wrench         = { label = "صناعة مفتاح صيانة",   icon = "🔩", inputs = { iron_ore = 2 }, fuel = 1, time = 5, output = "wrench", outputQty = 2 },
    steel_plate    = { label = "صهر صفيحة فولاذ",     icon = "🪨", inputs = { iron_ore = 6, coal = 3 }, fuel = 3, time = 15, output = "steel_plate", outputQty = 1 },
    metal_beam     = { label = "تشكيل عارضة معدنية",  icon = "🏗️", inputs = { iron_ore = 5, aluminum = 1 }, fuel = 2, time = 13, output = "metal_beam", outputQty = 1 },
}

Supply.MechanicRequirements = {
    repair      = { label = "إصلاح كامل",   parts = { engine_part = 1, repair_kit = 1 },  basePrice = 500 },
    bodywork    = { label = "دهان وهيكل",   parts = { steel_plate = 2, welder_tool = 1 }, basePrice = 1200 },
    performance = { label = "تعديل أداء",   parts = { engine_part = 2, suspension_kit = 1 }, basePrice = 2500 },
    brakes      = { label = "تغيير فرامل",  parts = { brake_pad = 2, wrench = 1 },     basePrice = 800 },
    tires       = { label = "تغيير إطارات", parts = { tire = 4 },                     basePrice = 600 },
}

-- تصنيع الميكانيكي
Supply.MechanicCrafted = {
    engine_v6   = { label = "محرك V6",   icon = "🔧", baseValue = 4500,  weight = 40, category = "engine", tier = 1 },
    engine_v8   = { label = "محرك V8",   icon = "🔧", baseValue = 8000,  weight = 50, category = "engine", tier = 2 },
    engine_ls   = { label = "محرك LS",   icon = "🔧", baseValue = 12000, weight = 55, category = "engine", tier = 3 },
    engine_race = { label = "محرك Race", icon = "🔧", baseValue = 20000, weight = 60, category = "engine", tier = 4 },
    trans_standard = { label = "قير عادي",  icon = "⚙️", baseValue = 3500,  weight = 35, category = "transmission", tier = 1 },
    trans_sport    = { label = "قير رياضي", icon = "⚙️", baseValue = 7000,  weight = 40, category = "transmission", tier = 2 },
    trans_race     = { label = "قير سباق",  icon = "⚙️", baseValue = 14000, weight = 45, category = "transmission", tier = 3 },
    paint_basic   = { label = "طلاء أساسي",    icon = "🎨", baseValue = 1200, weight = 10, category = "paint", tier = 1 },
    paint_premium = { label = "طلاء فاخر",     icon = "🎨", baseValue = 3000, weight = 12, category = "paint", tier = 2 },
    paint_custom  = { label = "طلاء مخصص",     icon = "🎨", baseValue = 6000, weight = 15, category = "paint", tier = 3 },
    body_repair   = { label = "عدة إصلاح بدن", icon = "🚗", baseValue = 2200, weight = 20, category = "body",  tier = 1 },
    oil_filter  = { label = "فلتر زيت",   icon = "🛢️", baseValue = 180, weight = 2, category = "consumable" },
    air_filter  = { label = "فلتر هواء",  icon = "🌬️", baseValue = 220, weight = 2, category = "consumable" },
    spark_plugs = { label = "بوجيهات",    icon = "🔌", baseValue = 340, weight = 3, category = "consumable" },
    engine_oil  = { label = "زيت محرك",   icon = "🛢️", baseValue = 400, weight = 6, category = "consumable" },
    coolant     = { label = "سائل تبريد", icon = "🧴", baseValue = 260, weight = 4, category = "consumable" },
    brake_fluid = { label = "سائل فرامل", icon = "🧴", baseValue = 300, weight = 4, category = "consumable" },
    camshaft     = { label = "كامة (Cam)", icon = "🌀", baseValue = 5200,  weight = 20, category = "internals", tier = 3 },
    crankshaft   = { label = "عمود كرنك",  icon = "🔩", baseValue = 6500,  weight = 30, category = "internals", tier = 3 },
    piston       = { label = "بستم",       icon = "🛞", baseValue = 3800,  weight = 18, category = "internals", tier = 2 },
    engine_block = { label = "بلوك محرك",  icon = "🧱", baseValue = 9000,  weight = 70, category = "internals", tier = 3 },
    turbocharger = { label = "تيربو",      icon = "💨", baseValue = 14000, weight = 25, category = "internals", tier = 4 },
    tint_kit     = { label = "طقم تظليل",  icon = "🌑", baseValue = 2800,  weight = 8,  category = "style",     tier = 1 },
}

Supply.MechanicRecipes = {
    engine_v6   = { label = "تجميع محرك V6",   icon = "🔧", workshop = true, tier = 1, time = 40,
        inputs = { iron_ore = 10, steel_plate = 4, metal_beam = 2 }, tools = { welder_tool = 1 }, output = "engine_v6", outputQty = 1 },
    engine_v8   = { label = "تجميع محرك V8",   icon = "🔧", workshop = true, tier = 2, time = 60,
        inputs = { iron_ore = 16, steel_plate = 6, metal_beam = 4 }, tools = { welder_tool = 1 }, output = "engine_v8", outputQty = 1 },
    engine_ls   = { label = "تجميع محرك LS",   icon = "🔧", workshop = true, tier = 3, time = 90,
        inputs = { iron_ore = 22, aluminum = 8, steel_plate = 8, metal_beam = 5 }, tools = { welder_tool = 2 }, output = "engine_ls", outputQty = 1 },
    engine_race = { label = "تجميع محرك Race", icon = "🔧", workshop = true, tier = 4, time = 150,
        inputs = { iron_ore = 30, aluminum = 14, copper_ore = 10, steel_plate = 12, metal_beam = 8 }, tools = { welder_tool = 2 }, output = "engine_race", outputQty = 1 },
    trans_standard = { label = "تجميع قير عادي",  icon = "⚙️", workshop = true, tier = 1, time = 35,
        inputs = { iron_ore = 8, steel_plate = 3 }, tools = { welder_tool = 1 }, output = "trans_standard", outputQty = 1 },
    trans_sport    = { label = "تجميع قير رياضي", icon = "⚙️", workshop = true, tier = 2, time = 55,
        inputs = { iron_ore = 14, aluminum = 5, steel_plate = 5 }, tools = { welder_tool = 1 }, output = "trans_sport", outputQty = 1 },
    trans_race     = { label = "تجميع قير سباق",  icon = "⚙️", workshop = true, tier = 3, time = 100,
        inputs = { iron_ore = 20, aluminum = 9, copper_ore = 6, metal_beam = 4 }, tools = { welder_tool = 2 }, output = "trans_race", outputQty = 1 },
    paint_basic   = { label = "خلط طلاء أساسي", icon = "🎨", workshop = true, tier = 1, time = 20,
        inputs = { copper_ore = 2, coal = 2 }, output = "paint_basic", outputQty = 2 },
    paint_premium = { label = "خلط طلاء فاخر",  icon = "🎨", workshop = true, tier = 2, time = 35,
        inputs = { copper_ore = 5, aluminum = 2, coal = 3 }, output = "paint_premium", outputQty = 1 },
    paint_custom  = { label = "خلط طلاء مخصص",  icon = "🎨", workshop = true, tier = 3, time = 60,
        inputs = { copper_ore = 8, aluminum = 4, coal = 5 }, output = "paint_custom", outputQty = 1 },
    body_repair   = { label = "تجهيز عدة بدن",  icon = "🚗", workshop = true, tier = 1, time = 30,
        inputs = { steel_plate = 4, metal_beam = 2 }, tools = { welder_tool = 1 }, output = "body_repair", outputQty = 1 },
    oil_filter  = { label = "تجهيز فلتر زيت",   icon = "🛢️", workshop = true, tier = 1, time = 8,
        inputs = { iron_ore = 2, copper_ore = 1 }, output = "oil_filter", outputQty = 2 },
    air_filter  = { label = "تجهيز فلتر هواء",  icon = "🌬️", workshop = true, tier = 1, time = 8,
        inputs = { iron_ore = 1, copper_ore = 2 }, output = "air_filter", outputQty = 2 },
    spark_plugs = { label = "تجهيز بوجيهات",    icon = "🔌", workshop = true, tier = 1, time = 10,
        inputs = { copper_ore = 3 }, output = "spark_plugs", outputQty = 4 },
    engine_oil  = { label = "تعبئة زيت محرك",   icon = "🛢️", workshop = true, tier = 1, time = 12,
        inputs = { coal = 4, copper_ore = 1 }, output = "engine_oil", outputQty = 2 },
    coolant     = { label = "تحضير سائل تبريد", icon = "🧴", workshop = true, tier = 1, time = 10,
        inputs = { copper_ore = 1, coal = 3 }, output = "coolant", outputQty = 2 },
    brake_fluid = { label = "تحضير سائل فرامل", icon = "🧴", workshop = true, tier = 1, time = 10,
        inputs = { copper_ore = 2, coal = 2 }, output = "brake_fluid", outputQty = 2 },
    camshaft     = { label = "تجميع كامة (Cam)", icon = "🌀", workshop = true, tier = 3, time = 55,
        inputs = { iron_ore = 12, aluminum = 5, copper_ore = 4, steel_plate = 4 }, tools = { welder_tool = 1 }, output = "camshaft", outputQty = 1 },
    crankshaft   = { label = "تجميع عمود كرنك",  icon = "🔩", workshop = true, tier = 3, time = 70,
        inputs = { iron_ore = 18, aluminum = 6, steel_plate = 6, metal_beam = 3 }, tools = { welder_tool = 2 }, output = "crankshaft", outputQty = 1 },
    piston       = { label = "تجميع بستم",        icon = "🛞", workshop = true, tier = 2, time = 35,
        inputs = { iron_ore = 8, aluminum = 4, steel_plate = 2 }, tools = { welder_tool = 1 }, output = "piston", outputQty = 2 },
    engine_block = { label = "سبك بلوك محرك",    icon = "🧱", workshop = true, tier = 3, time = 80,
        inputs = { iron_ore = 24, aluminum = 10, steel_plate = 8, metal_beam = 6 }, tools = { welder_tool = 2 }, output = "engine_block", outputQty = 1 },
    turbocharger = { label = "تجميع تيربو",       icon = "💨", workshop = true, tier = 4, time = 110,
        inputs = { iron_ore = 20, aluminum = 12, copper_ore = 10, steel_plate = 10 }, tools = { welder_tool = 2 }, output = "turbocharger", outputQty = 1 },
    tint_kit     = { label = "تجهيز طقم تظليل",   icon = "🌑", workshop = true, tier = 1, time = 15,
        inputs = { copper_ore = 2, coal = 1 }, output = "tint_kit", outputQty = 1 },
}

Supply.Locations = {
    mine = {
        label = "المنجم", job = "miner", icon = "⛏️",
        points = {
            { x = 2950.0, y = 2750.0, z = 43.0, label = "عروق الحديد" },
            { x = -600.0, y = 2080.0, z = 130.0, label = "المقلع الجبلي" },
        },
        sellPoint = { x = 1085.0, y = -3195.0, z = 5.0 },
    },
    forge = {
        label = "ورشة الحدادة", job = "blacksmith", icon = "🔨",
        points = {
            { x = -608.0, y = -1602.0, z = 27.0, label = "فرن الصهر" },
            { x = -580.0, y = -1750.0, z = 25.0, label = "سندان الحدادة" },
        },
        sellPoint = { x = -560.0, y = -1830.0, z = 24.0 },
    },
    workshop = {
        label = "ورشة الميكانيك", job = "mechanic", icon = "🔧",
        points = {
            { x = -340.0, y = -135.0, z = 39.0, label = "ورشة المدينة" },
            { x = 545.0, y = -180.0, z = 54.0, label = "ورشة الشمال" },
        },
    },
}

Supply.Messages = {
    mined         = "استخرجت %s × %s",
    crafted       = "صنعت %s × %s",
    noMaterials   = "لا تملك المواد المطلوبة.",
    noFuel        = "تحتاج فحماً للصهر.",
    inventoryFull = "مخزونك ممتلئ من هذا العنصر.",
    sold          = "بعت %s × %s بـ $%s",
    bought        = "اشتريت %s × %s بـ $%s",
    noParts       = "الميكانيكي لا يملك القطع المطلوبة للإصلاح.",
    repairDone    = "تم الإصلاح باستهلاك القطع من الورشة.",
    crafting      = "جاري التصنيع...",
    demand        = "الطلب مرتفع — اسحب موادك للورشة.",
}

return Supply
