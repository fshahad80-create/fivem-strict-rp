--[[
    fivem-strict-rp :: config/livestock.lua
    نظام المواشي (تربية · إطعام · جمع · ذبح · تزاوج)
]]

Livestock = {}

Livestock.Settings = {
    enabled        = true,
    maxAnimals     = 20,
    feedIntervalMin = 120,
    healthDecayPerHour = 8,
    breedCooldownMin = 240,
    collectCooldownMin = 60,
    qualityMin = 1, qualityMax = 5,
    qualityMultipliers = { [1]=0.7, [2]=0.9, [3]=1.0, [4]=1.3, [5]=1.7 },
}

Livestock.Animals = {
    chicken = { label = "دجاجة", icon = "🐔", buyPrice = 300, feedCost = 20, products = { egg = { qty = 1, value = 25 } }, slaughter = { feather = 3, meat_small = 1 }, breed = true, breedTime = 20 },
    cow     = { label = "بقرة", icon = "🐄", buyPrice = 2500, feedCost = 60, products = { milk = { qty = 2, value = 90 } }, slaughter = { pelt_cow = 1, meat_large = 4 }, breed = true, breedTime = 45 },
    sheep   = { label = "خروف", icon = "🐑", buyPrice = 1800, feedCost = 45, products = { wool = { qty = 1, value = 120 } }, slaughter = { pelt_sheep = 1, meat_medium = 3 }, breed = true, breedTime = 40 },
    goat    = { label = "ماعز", icon = "🐐", buyPrice = 1200, feedCost = 35, products = { milk = { qty = 1, value = 70 } }, slaughter = { pelt_goat = 1, meat_medium = 2 }, breed = true, breedTime = 35 },
    bee     = { label = "خلية نحل", icon = "🐝", buyPrice = 1500, feedCost = 15, products = { honey = { qty = 2, value = 110 } }, slaughter = {}, breed = false },
}

Livestock.Feed = {
    hay   = { label = "برسيم", icon = "🌿", value = 15 },
    corn  = { label = "ذرة",   icon = "🌽", value = 20 },
    wheat = { label = "قمح",   icon = "🌾", value = 18 },
}

Livestock.Pens = {
    { id = 1, x = 2050.0, y = 4950.0, z = 41.0, label = "حظيرة المزرعة الرئيسية" },
    { id = 2, x = 2100.0, y = 5000.0, z = 41.0, label = "حظيرة شرقية" },
    { id = 3, x = 1900.0, y = 4800.0, z = 41.0, label = "حظيرة غربية" },
}

Livestock.Messages = {
    bought       = "اشتريت %s ($%s)",
    fed          = "أطعمت مواشيك (%s حيوان)",
    collected    = "جمعت %s × %s من %s",
    slaughtered  = "ذبحت %s — حصلت على %s",
    bred         = "وُلد %s جديد!",
    noFood       = "لا تملك علفاً كافياً.",
    penFull      = "الحظيرة ممتلئة.",
    needCare     = "مواشيك جائعة — أطعمها!",
    animalDied   = "مات حيوان من الجوع.",
    noMoney      = "لا تملك المال الكافي.",
    notOwner     = "أنت لست مالك الحظيرة.",
}

return Livestock
