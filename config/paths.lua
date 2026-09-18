--[[
    fivem-strict-rp :: config/paths.lua
    شجرة المسارات (Skill Tree) — 6 قطاعات · 13 تخصص · عقود · شارات · ألقاب.
]]

Paths = {}

Paths.Settings = {
    enabled = true,
    xpPerPoint = 10000,
    dailyPoints   = 1,
    weeklyPoints  = 3,
    monthlyPoints = 10,
    respecCooldownDays = 30,
    maxLevelPerSpec = 40,
}

Paths.Sectors = {
    industry = {
        label = "الصناعة والحرف", icon = "⚒️",
        specs = {
            mining      = { label = "التعدين", job = "miner", icon = "⛏️" },
            woodcutting = { label = "النجارة", job = "carpenter", icon = "🪚" },
            smithing    = { label = "الحدادة والتصنيع", job = "blacksmith", icon = "🔨" },
        },
        title = "كبير الحرفيين",
    },
    land_sea = {
        label = "الأرض والبحر", icon = "🌍",
        specs = {
            farming      = { label = "الزراعة", job = nil, icon = "🌾" },
            livestock    = { label = "المواشي", job = nil, icon = "🐄" },
            sea_hunting  = { label = "صيد البحر", job = "fisher", icon = "🐟" },
            land_hunting = { label = "صيد البر", job = nil, icon = "🦌" },
        },
        title = "شيخ البر والبحر",
    },
    logistics = {
        label = "اللوجستيك", icon = "🚚",
        specs = {
            transport = { label = "الطرق والنقل", job = "trucker", icon = "🚛" },
            oil       = { label = "النفط", job = "oilworker", icon = "🛢️" },
        },
        title = "ملك الطريق",
    },
    public_service = {
        label = "الخدمة العامة", icon = "🎖️",
        specs = {
            security = { label = "الأمن", job = "police", icon = "🛡️" },
            ems      = { label = "الإسعاف", job = "ambulance", icon = "🚑" },
        },
        title = "درع سُدير",
    },
    civil = {
        label = "المدني", icon = "🏙️",
        specs = {
            city_life = { label = "حياة المدينة", job = nil, icon = "🏙️" },
        },
        title = "من أعيان سُدير",
    },
    business = {
        label = "الأعمال", icon = "💼",
        specs = {
            trade   = { label = "التجارة", job = nil, icon = "🛒" },
            permits = { label = "التصاريح", job = nil, icon = "📜" },
        },
        title = "تاجر سُدير",
    },
}

Paths.Nodes = {
    mining = {
        { level = 5,  cost = 1, label = "حفر أسرع", bonus = { type = "mineSpeed", value = 0.15 } },
        { level = 10, cost = 2, label = "غلة +20%", bonus = { type = "mineYield", value = 0.20 } },
        { level = 20, cost = 3, label = "صهر أسرع", bonus = { type = "smeltSpeed", value = 0.25 } },
        { level = 30, cost = 4, label = "أدوات تدوم أطول", bonus = { type = "toolDurability", value = 0.50 } },
        { level = 40, cost = 5, label = "سيد المنجم", badge = "mining_master", bonus = { type = "exclusive", value = 1 } },
    },
    woodcutting = {
        { level = 5,  cost = 1, label = "قطع أسرع", bonus = { type = "chopSpeed", value = 0.15 } },
        { level = 10, cost = 2, label = "أخشاب +20%", bonus = { type = "woodYield", value = 0.20 } },
        { level = 20, cost = 3, label = "صناديق أكبر", bonus = { type = "storageBoost", value = 0.25 } },
        { level = 30, cost = 4, label = "خبرة إضافية", bonus = { type = "xpGain", value = 0.30 } },
        { level = 40, cost = 5, label = "سيد الغابة", badge = "wood_master", bonus = { type = "exclusive", value = 1 } },
    },
    smithing = {
        { level = 5,  cost = 1, label = "تصنيع أسرع", bonus = { type = "craftSpeed", value = 0.15 } },
        { level = 10, cost = 2, label = "جودة أعلى", bonus = { type = "craftQuality", value = 0.20 } },
        { level = 25, cost = 3, label = "بوابات ومفاتيح", bonus = { type = "gates", value = 1 } },
        { level = 35, cost = 4, label = "خصم على الرسوم", bonus = { type = "feeDiscount", value = 0.25 } },
        { level = 40, cost = 5, label = "كبير الصاغة", badge = "smith_master", unlocks = { "luxury_watch", "jeweled_crown" }, bonus = { type = "exclusive", value = 1 } },
    },
    farming = {
        { level = 5,  cost = 1, label = "غلة +15%", bonus = { type = "farmYield", value = 0.15 } },
        { level = 15, cost = 2, label = "نمو أسرع", bonus = { type = "growSpeed", value = 0.20 } },
        { level = 25, cost = 3, label = "حماية من الآفات", bonus = { type = "pestProtect", value = 0.50 } },
        { level = 40, cost = 5, label = "سيد الحقول", badge = "farm_master", bonus = { type = "exclusive", value = 1 } },
    },
    sea_hunting = {
        { level = 10, cost = 2, label = "صيد أوفر", bonus = { type = "fishYield", value = 0.25 } },
        { level = 25, cost = 3, label = "جودة الغنائم", bonus = { type = "lootQuality", value = 0.30 } },
        { level = 40, cost = 5, label = "سيد البحر", badge = "sea_master", bonus = { type = "exclusive", value = 1 } },
    },
    land_hunting = {
        { level = 10, cost = 2, label = "صيد أوفر", bonus = { type = "huntYield", value = 0.25 } },
        { level = 25, cost = 3, label = "جلود أفضل", bonus = { type = "peltQuality", value = 0.30 } },
        { level = 40, cost = 5, label = "وحش البراري", badge = "hunt_master", bonus = { type = "exclusive", value = 1 } },
    },
    oil = {
        { level = 10, cost = 2, label = "استخراج أوفر", bonus = { type = "oilYield", value = 0.25 } },
        { level = 25, cost = 3, label = "تكرير أسرع", bonus = { type = "refineSpeed", value = 0.30 } },
        { level = 40, cost = 5, label = "بارون النفط", badge = "oil_master", bonus = { type = "exclusive", value = 1 } },
    },
    trade = {
        { level = 10, cost = 2, label = "خصم شراء", bonus = { type = "buyDiscount", value = 0.10 } },
        { level = 25, cost = 3, label = "سعة حقيبة +", bonus = { type = "inventorySlots", value = 20 } },
        { level = 40, cost = 5, label = "عمدة السوق", badge = "trade_master", bonus = { type = "exclusive", value = 1 } },
    },
}

Paths.Messages = {
    xpGained    = "%s: +%s خبرة (%s/%s)",
    levelUp     = "مستوى جديد في %s: %s",
    pointEarned = "نقطة مسار جديدة! (المجموع: %s)",
    nodeUnlocked = "فُتحت ميزة: %s",
    badgeEarned = "شارة إتقان: %s",
    titleEquipped = "لقبك: %s",
    notEnoughPoints = "نقاط مسارك غير كافية.",
    levelLocked = "تحتاج مستوى %s في %s.",
    respecDone  = "تم إعادة توزيع نقاطك (%s نقطة).",
    respecCooldown = "إعادة التوزيع متاحة مرة كل %s يوم.",
    alreadyTitle = "لديك لقب قمة في هذا القطاع بالفعل.",
}

return Paths
