--[[
    fivem-strict-rp :: config/carpenter.lua
    النجار العميق (صناديق تخزين · طاولات تصنيع · أكشاك)
]]

Carpenter = {}

Carpenter.Settings = {
    enabled        = true,
    craftCooldown  = 8,
    craftXpPerItem = 6,
    maxLevel       = 30,
}

Carpenter.Materials = {
    wood_log   = { label = "جذع خشب",  icon = "🪵", value = 25 },
    wood_plank = { label = "لوح خشب",  icon = "🪚", value = 60 },
    wood_pole  = { label = "عمود خشب", icon = "🪝", value = 45 },
}

Carpenter.Recipes = {
    plank = { label = "تقطيع ألواح", icon = "🪚", time = 10, inputs = { wood_log = 3 }, output = "wood_plank", qty = 2 },
    pole  = { label = "تشكيل أعمدة", icon = "🪝", time = 8, inputs = { wood_log = 2 }, output = "wood_pole", qty = 3 },
    crate_50  = { label = "صندوق تخزين 50 كجم",  icon = "📦", time = 20, inputs = { wood_plank = 6, wood_pole = 2 }, output = "crate_50", qty = 1, storage = 50 },
    crate_100 = { label = "صندوق تخزين 100 كجم", icon = "📦", time = 30, inputs = { wood_plank = 12, wood_pole = 4 }, output = "crate_100", qty = 1, storage = 100 },
    crate_150 = { label = "صندوق تخزين 150 كجم", icon = "📦", time = 40, inputs = { wood_plank = 18, wood_pole = 6 }, output = "crate_150", qty = 1, storage = 150 },
    crate_200 = { label = "صندوق تخزين 200 كجم", icon = "📦", time = 55, inputs = { wood_plank = 25, wood_pole = 8 }, output = "crate_200", qty = 1, storage = 200 },
    crafting_table = { label = "طاولة تصنيع", icon = "🛠️", time = 45, inputs = { wood_plank = 15, wood_pole = 6 }, output = "crafting_table", qty = 1, placeable = true },
    stall = { label = "كشك بيع", icon = "🏪", time = 60, inputs = { wood_plank = 20, wood_pole = 10 }, output = "stall_kit", qty = 1, needsPermit = true, placeable = true },
    wooden_fence = { label = "سياج خشبي", icon = "🚧", time = 15, inputs = { wood_plank = 4, wood_pole = 2 }, output = "wooden_fence", qty = 2 },
    storage_shed = { label = "مخزن خشبي", icon = "🏠", time = 50, inputs = { wood_plank = 30, wood_pole = 12 }, output = "storage_shed", qty = 1, storage = 300, placeable = true },
}

Carpenter.Locations = {
    workshop = {
        label = "ورشة النجارة", job = "carpenter", icon = "🪚",
        points = {
            { x = 1220.0, y = 1890.0, z = 78.0, label = "منشرة الأخشاب" },
            { x = 1090.0, y = 2020.0, z = 74.0, label = "ورشة النجارة" },
        },
        sellPoint = { x = 1055.0, y = 2100.0, z = 73.0 },
    },
}

Carpenter.Permits = {
    stallPermit = { label = "تصريح كشك", cost = 50000, durationDays = 30 },
}

Carpenter.Messages = {
    crafted     = "صنعت %s × %s",
    noMaterials = "لا تملك المواد المطلوبة.",
    noPermit    = "تحتاج تصريح كشك أولاً (من المكتب الشعبي).",
    placed      = "تم وضع %s",
    sold        = "بعت %s بـ $%s",
    levelUp     = "مستوى النجار: %s",
}

return Carpenter
