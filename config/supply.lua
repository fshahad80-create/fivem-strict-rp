--[[
    fivem-strict-rp :: config/supply.lua
    سلسلة التوريد: منجم → حداد → ميكانيكي
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
