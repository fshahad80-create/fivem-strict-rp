--[[
    ══════════════════════════════════════════════════════════════
    الفرسان RP — تعريفات العناصر (Items)
    ══════════════════════════════════════════════════════════════
    ضع محتوى هذا الملف داخل: qb-core/shared/items.lua
    (أو أضِفه بعد جدول QBCore.Shared.Items الأصلي)

    ملاحظة: كل عنصر هنا يستخدمه نظام من أنظمة السيرفر الـ30.
    بدون هذه التعريفات، المخزون يظهر فاضي.
    ══════════════════════════════════════════════════════════════
]]

local ITEMS = {
    -- خامات المنجم
    iron_ore     = { name = "iron_ore",     label = "خام حديد",     weight = 500,  type = "item", image = "iron_ore.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "خام من المنجم — يُصهر عند الحداد" },
    copper_ore   = { name = "copper_ore",   label = "خام نحاس",     weight = 400,  type = "item", image = "copper_ore.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "خام من المنجم" },
    coal         = { name = "coal",         label = "فحم",          weight = 300,  type = "item", image = "coal.png",         unique = false, useable = false, shouldClose = false, combinable = nil, description = "وقود الصهر" },
    aluminum     = { name = "aluminum",     label = "ألمنيوم خام",  weight = 600,  type = "item", image = "aluminum.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "خام ألمنيوم" },
    crude_oil    = { name = "crude_oil",    label = "نفط خام",      weight = 600,  type = "item", image = "crude_oil.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "خام من حقل النفط" },
    raw_ore      = { name = "raw_ore",      label = "خام معدني",    weight = 500,  type = "item", image = "raw_ore.png",      unique = false, useable = false, shouldClose = false, combinable = nil, description = "خام عام" },
    -- أخشاب النجار
    wood_log     = { name = "wood_log",     label = "جذع خشب",      weight = 800,  type = "item", image = "wood_log.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "جذع خشب خام" },
    wood_plank   = { name = "wood_plank",   label = "لوح خشب",      weight = 500,  type = "item", image = "wood_plank.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "لوح مصنوع" },
    wood_pole    = { name = "wood_pole",    label = "عمود خشب",     weight = 450,  type = "item", image = "wood_pole.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "عمود خشبي" },
    -- مصنوعات الحداد
    engine_part    = { name = "engine_part",    label = "قطعة محرك",     weight = 800,  type = "item", image = "engine_part.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "قطعة غيار أصلية" },
    brake_pad      = { name = "brake_pad",      label = "فحمات فرامل",   weight = 400,  type = "item", image = "brake_pad.png",      unique = false, useable = false, shouldClose = false, combinable = nil, description = "فحمات فرامل" },
    suspension_kit = { name = "suspension_kit", label = "طقم تعليق",     weight = 1000, type = "item", image = "suspension_kit.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "طقم تعليق كامل" },
    tire           = { name = "tire",           label = "إطار",          weight = 1200, type = "item", image = "tire.png",           unique = false, useable = false, shouldClose = false, combinable = nil, description = "إطار مركبة" },
    repair_kit     = { name = "repair_kit",     label = "عدة إصلاح",     weight = 700,  type = "item", image = "repair_kit.png",     unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "عدة إصلاح مؤقتة" },
    welder_tool    = { name = "welder_tool",    label = "أداة لحام",     weight = 900,  type = "item", image = "welder_tool.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "أداة لحام" },
    wrench         = { name = "wrench",         label = "مفتاح صيانة",   weight = 300,  type = "item", image = "wrench.png",         unique = false, useable = false, shouldClose = false, combinable = nil, description = "مفتاح صيانة" },
    steel_plate    = { name = "steel_plate",    label = "صفيحة فولاذ",   weight = 1500, type = "item", image = "steel_plate.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "صفيحة فولاذ" },
    metal_beam     = { name = "metal_beam",     label = "عارضة معدنية",  weight = 1400, type = "item", image = "metal_beam.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "عارضة معدنية" },
    circuit_part   = { name = "circuit_part",   label = "قطعة إلكترونية", weight = 400, type = "item", image = "circuit_part.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "قطعة إلكترونية" },
    -- المحركات والقير
    engine_v6   = { name = "engine_v6",   label = "محرك V6",   weight = 4000, type = "item", image = "engine_v6.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "محرك V6" },
    engine_v8   = { name = "engine_v8",   label = "محرك V8",   weight = 5000, type = "item", image = "engine_v8.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "محرك V8" },
    engine_ls   = { name = "engine_ls",   label = "محرك LS",   weight = 5500, type = "item", image = "engine_ls.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "محرك LS" },
    engine_race = { name = "engine_race", label = "محرك Race", weight = 6000, type = "item", image = "engine_race.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "محرك سباق" },
    trans_standard = { name = "trans_standard", label = "قير عادي",  weight = 3500, type = "item", image = "trans_standard.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "ناقل حركة عادي" },
    trans_sport    = { name = "trans_sport",    label = "قير رياضي", weight = 4000, type = "item", image = "trans_sport.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "ناقل حركة رياضي" },
    trans_race     = { name = "trans_race",     label = "قير سباق",  weight = 4500, type = "item", image = "trans_race.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "ناقل حركة سباق" },
    -- قطع المحرك الداخلية
    camshaft     = { name = "camshaft",     label = "كامة (Cam)",  weight = 2000, type = "item", image = "camshaft.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "كامة محرك" },
    crankshaft   = { name = "crankshaft",   label = "عمود كرنك",   weight = 3000, type = "item", image = "crankshaft.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "عمود كرنك" },
    piston       = { name = "piston",       label = "بستم",         weight = 1800, type = "item", image = "piston.png",       unique = false, useable = false, shouldClose = false, combinable = nil, description = "بستم" },
    engine_block = { name = "engine_block", label = "بلوك محرك",   weight = 7000, type = "item", image = "engine_block.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "بلوك محرك" },
    turbocharger = { name = "turbocharger", label = "تيربو",        weight = 2500, type = "item", image = "turbocharger.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "شاحن توربيني" },
    -- دهان وتظليل
    paint_basic   = { name = "paint_basic",   label = "طلاء أساسي", weight = 1000, type = "item", image = "paint_basic.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "طلاء مركبة" },
    paint_premium = { name = "paint_premium", label = "طلاء فاخر",  weight = 1200, type = "item", image = "paint_premium.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "طلاء فاخر" },
    paint_custom  = { name = "paint_custom",  label = "طلاء مخصص",  weight = 1500, type = "item", image = "paint_custom.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "طلاء مخصص" },
    body_repair   = { name = "body_repair",   label = "عدة إصلاح بدن", weight = 2000, type = "item", image = "body_repair.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "إصلاح بدن المركبة" },
    tint_kit      = { name = "tint_kit",      label = "طقم تظليل",  weight = 800,  type = "item", image = "tint_kit.png",      unique = false, useable = true, shouldClose = true, combinable = nil, description = "تظليل نوافذ" },
    -- قطع استهلاكية
    oil_filter   = { name = "oil_filter",   label = "فلتر زيت",    weight = 200, type = "item", image = "oil_filter.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "فلتر زيت" },
    air_filter   = { name = "air_filter",   label = "فلتر هواء",   weight = 200, type = "item", image = "air_filter.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "فلتر هواء" },
    spark_plugs  = { name = "spark_plugs",  label = "بوجيهات",     weight = 300, type = "item", image = "spark_plugs.png",  unique = false, useable = false, shouldClose = false, combinable = nil, description = "بوجيهات" },
    engine_oil   = { name = "engine_oil",   label = "زيت محرك",    weight = 600, type = "item", image = "engine_oil.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "زيت محرك" },
    oil_5000     = { name = "oil_5000",     label = "زيت 5,000 كم", weight = 600, type = "item", image = "oil_5000.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "زيت يكفي 5000 كم" },
    oil_10000    = { name = "oil_10000",    label = "زيت 10,000 كم", weight = 700, type = "item", image = "oil_10000.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "زيت يكفي 10000 كم" },
    coolant      = { name = "coolant",      label = "سائل تبريد",  weight = 400, type = "item", image = "coolant.png",      unique = false, useable = true, shouldClose = true, combinable = nil, description = "سائل تبريد" },
    brake_fluid  = { name = "brake_fluid",  label = "سائل فرامل",  weight = 400, type = "item", image = "brake_fluid.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "سائل فرامل" },
    -- منتجات النفط
    refined_fuel = { name = "refined_fuel", label = "بنزين مكرر",  weight = 500, type = "item", image = "refined_fuel.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "بنزين مكرر" },
    diesel       = { name = "diesel",       label = "ديزل",         weight = 500, type = "item", image = "diesel.png",       unique = false, useable = false, shouldClose = false, combinable = nil, description = "ديزل" },
    propane      = { name = "propane",      label = "غاز بروبان",  weight = 400, type = "item", image = "propane.png",      unique = false, useable = false, shouldClose = false, combinable = nil, description = "غاز بروبان" },
    -- المحاصيل
    wheat    = { name = "wheat",    label = "قمح",    weight = 300, type = "item", image = "wheat.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "قمح" },
    tomato   = { name = "tomato",   label = "طماطم",  weight = 250, type = "item", image = "tomato.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "طماطم طازجة" },
    potato   = { name = "potato",   label = "بطاطس",  weight = 280, type = "item", image = "potato.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "بطاطس" },
    corn     = { name = "corn",     label = "ذرة",    weight = 300, type = "item", image = "corn.png",     unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "ذرة" },
    carrot   = { name = "carrot",   label = "جزر",    weight = 250, type = "item", image = "carrot.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "جزر" },
    onion    = { name = "onion",    label = "بصل",    weight = 260, type = "item", image = "onion.png",    unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "بصل" },
    coffee   = { name = "coffee",   label = "بن",     weight = 200, type = "item", image = "coffee.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "حبوب بن" },
    grape    = { name = "grape",    label = "عنب",    weight = 220, type = "item", image = "grape.png",    unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "عنب" },
    cotton   = { name = "cotton",   label = "قطن",    weight = 200, type = "item", image = "cotton.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "قطن خام" },
    hay      = { name = "hay",      label = "برسيم",  weight = 300, type = "item", image = "hay.png",      unique = false, useable = false, shouldClose = false, combinable = nil, description = "برسيم (علف)" },
    apple    = { name = "apple",    label = "تفاح",   weight = 200, type = "item", image = "apple.png",    unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "تفاح" },
    orange   = { name = "orange",   label = "برتقال", weight = 200, type = "item", image = "orange.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "برتقال" },
    olive    = { name = "olive",    label = "زيتون",  weight = 200, type = "item", image = "olive.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "زيتون" },
    -- منتجات المعمل
    flour   = { name = "flour",   label = "طحين",  weight = 500, type = "item", image = "flour.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "طحين" },
    bread   = { name = "bread",   label = "خبز",   weight = 400, type = "item", image = "bread.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "خبز" },
    oil     = { name = "oil",     label = "زيت",   weight = 400, type = "item", image = "oil.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "زيت طعام" },
    juice   = { name = "juice",   label = "عصير",  weight = 400, type = "item", image = "juice.png",   unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "عصير" },
    cheese  = { name = "cheese",  label = "جبن",   weight = 350, type = "item", image = "cheese.png",  unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "جبن" },
    jam     = { name = "jam",     label = "مربى",  weight = 350, type = "item", image = "jam.png",     unique = false, useable = true,  shouldClose = true,  combinable = nil, description = "مربى" },
    -- المواشي
    milk    = { name = "milk",    label = "حليب",   weight = 400, type = "item", image = "milk.png",    unique = false, useable = true, shouldClose = true, combinable = nil, description = "حليب طازج" },
    egg     = { name = "egg",     label = "بيض",    weight = 200, type = "item", image = "egg.png",     unique = false, useable = true, shouldClose = true, combinable = nil, description = "بيض" },
    wool    = { name = "wool",    label = "صوف",    weight = 300, type = "item", image = "wool.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "صوف" },
    honey   = { name = "honey",   label = "عسل",    weight = 300, type = "item", image = "honey.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "عسل طبيعي" },
    -- جلود ولحوم
    pelt_rabbit = { name = "pelt_rabbit", label = "جلد أرنب",   weight = 200, type = "item", image = "pelt_rabbit.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد أرنب" },
    pelt_deer   = { name = "pelt_deer",   label = "جلد غزال",   weight = 400, type = "item", image = "pelt_deer.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد غزال" },
    pelt_boar   = { name = "pelt_boar",   label = "جلد خنزير",  weight = 500, type = "item", image = "pelt_boar.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد خنزير بري" },
    pelt_wolf   = { name = "pelt_wolf",   label = "جلد ذئب",    weight = 500, type = "item", image = "pelt_wolf.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد ذئب" },
    pelt_cougar = { name = "pelt_cougar", label = "جلد أسد جبلي", weight = 600, type = "item", image = "pelt_cougar.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد أسد جبلي" },
    pelt_bear   = { name = "pelt_bear",   label = "جلد دبّ",    weight = 800, type = "item", image = "pelt_bear.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد دبّ" },
    pelt_cow    = { name = "pelt_cow",    label = "جلد بقرة",   weight = 700, type = "item", image = "pelt_cow.png",    unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد بقرة" },
    pelt_sheep  = { name = "pelt_sheep",  label = "جلد خروف",   weight = 600, type = "item", image = "pelt_sheep.png",  unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد خروف" },
    pelt_goat   = { name = "pelt_goat",   label = "جلد ماعز",   weight = 500, type = "item", image = "pelt_goat.png",   unique = false, useable = false, shouldClose = false, combinable = nil, description = "جلد ماعز" },
    feather     = { name = "feather",     label = "ريش",        weight = 100, type = "item", image = "feather.png",     unique = false, useable = false, shouldClose = false, combinable = nil, description = "ريش" },
    meat_small  = { name = "meat_small",  label = "لحم صغير",   weight = 300, type = "item", image = "meat_small.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "لحم صغير" },
    meat_medium = { name = "meat_medium", label = "لحم متوسط",  weight = 500, type = "item", image = "meat_medium.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "لحم متوسط" },
    meat_large  = { name = "meat_large",  label = "لحم كبير",   weight = 800, type = "item", image = "meat_large.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "لحم كبير" },
    -- أسماك الصيد
    sardine   = { name = "sardine",   label = "سردين",     weight = 300, type = "item", image = "sardine.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "سمكة" },
    bream     = { name = "bream",     label = "كنعد",      weight = 400, type = "item", image = "bream.png",     unique = false, useable = true, shouldClose = true, combinable = nil, description = "سمكة" },
    hamour    = { name = "hamour",    label = "هامور",     weight = 500, type = "item", image = "hamour.png",    unique = false, useable = true, shouldClose = true, combinable = nil, description = "سمكة" },
    shrimp    = { name = "shrimp",    label = "روبيان",    weight = 200, type = "item", image = "shrimp.png",    unique = false, useable = true, shouldClose = true, combinable = nil, description = "روبيان" },
    lobster   = { name = "lobster",   label = "كركند",     weight = 500, type = "item", image = "lobster.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "كركند" },
    tuna      = { name = "tuna",      label = "تونة",      weight = 600, type = "item", image = "tuna.png",      unique = false, useable = true, shouldClose = true, combinable = nil, description = "تونة" },
    swordfish = { name = "swordfish", label = "سمك سيف",   weight = 700, type = "item", image = "swordfish.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "سمك سيف" },
    shark     = { name = "shark",     label = "قرش صغير",  weight = 1200, type = "item", image = "shark.png",    unique = false, useable = true, shouldClose = true, combinable = nil, description = "قرش" },
    recyclables = { name = "recyclables", label = "مُعاد تدويره", weight = 400, type = "item", image = "recyclables.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "مواد قابلة للتدوير" },
    -- أدوات الصيد
    rod_basic   = { name = "rod_basic",   label = "سنارة عادية",       weight = 800, type = "item", image = "rod_basic.png",   unique = true, useable = false, shouldClose = false, combinable = nil, description = "سنارة صيد" },
    rod_pro     = { name = "rod_pro",     label = "سنارة احترافية",     weight = 900, type = "item", image = "rod_pro.png",     unique = true, useable = false, shouldClose = false, combinable = nil, description = "سنارة احترافية" },
    rod_master  = { name = "rod_master",  label = "سنارة الصياد الماهر", weight = 1000, type = "item", image = "rod_master.png", unique = true, useable = false, shouldClose = false, combinable = nil, description = "سنارة نادرة" },
    rifle_basic = { name = "rifle_basic", label = "بندقية صيد",         weight = 3000, type = "item", image = "rifle_basic.png", unique = true, useable = false, shouldClose = false, combinable = nil, description = "بندقية صيد" },
    rifle_pro   = { name = "rifle_pro",   label = "بندقية دقيقة",       weight = 3200, type = "item", image = "rifle_pro.png",   unique = true, useable = false, shouldClose = false, combinable = nil, description = "بندقية دقيقة" },
    rifle_master= { name = "rifle_master",label = "قناص الصيد",         weight = 3500, type = "item", image = "rifle_master.png", unique = true, useable = false, shouldClose = false, combinable = nil, description = "قناص صيد" },
    -- أدوات المزرعة
    hoe_basic  = { name = "hoe_basic",  label = "فأس عادي",          weight = 1500, type = "item", image = "hoe_basic.png",  unique = true, useable = false, shouldClose = false, combinable = nil, description = "أداة زراعة" },
    hoe_pro    = { name = "hoe_pro",    label = "فأس احترافي",        weight = 1600, type = "item", image = "hoe_pro.png",    unique = true, useable = false, shouldClose = false, combinable = nil, description = "أداة زراعة" },
    hoe_master = { name = "hoe_master", label = "فأس المزارع الماهر", weight = 1700, type = "item", image = "hoe_master.png", unique = true, useable = false, shouldClose = false, combinable = nil, description = "أداة زراعة نادرة" },
    -- صناديق ومخازن النجار
    crate_50  = { name = "crate_50",  label = "صندوق تخزين 50 كجم",  weight = 5000, type = "item", image = "crate_50.png",  unique = false, useable = true, shouldClose = true, combinable = nil, description = "صندوق تخزين" },
    crate_100 = { name = "crate_100", label = "صندوق تخزين 100 كجم", weight = 8000, type = "item", image = "crate_100.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "صندوق تخزين" },
    crate_150 = { name = "crate_150", label = "صندوق تخزين 150 كجم", weight = 11000, type = "item", image = "crate_150.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "صندوق تخزين" },
    crate_200 = { name = "crate_200", label = "صندوق تخزين 200 كجم", weight = 14000, type = "item", image = "crate_200.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "صندوق تخزين" },
    crafting_table = { name = "crafting_table", label = "طاولة تصنيع",  weight = 15000, type = "item", image = "crafting_table.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "طاولة تصنيع قابلة للوضع" },
    storage_shed   = { name = "storage_shed",   label = "مخزن خشبي",    weight = 20000, type = "item", image = "storage_shed.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "مخزن خشبي قابل للوضع" },
    stall_kit      = { name = "stall_kit",      label = "كشك بيع",       weight = 18000, type = "item", image = "stall_kit.png",      unique = false, useable = true, shouldClose = true, combinable = nil, description = "كشك بيع (يحتاج تصريح)" },
    wooden_fence   = { name = "wooden_fence",   label = "سياج خشبي",    weight = 3000,  type = "item", image = "wooden_fence.png",   unique = false, useable = true, shouldClose = true, combinable = nil, description = "سياج خشبي" },
    -- قطع التشليح
    glass  = { name = "glass",  label = "زجاج", weight = 200, type = "item", image = "glass.png",  unique = false, useable = false, shouldClose = false, combinable = nil, description = "زجاج مُشلَّح" },
    rubber = { name = "rubber", label = "مطاط", weight = 150, type = "item", image = "rubber.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "مطاط مُشلَّح" },
    -- أدوات عامة
    sandwich     = { name = "sandwich",     label = "ساندويتش",  weight = 200, type = "item", image = "sandwich.png",     unique = false, useable = true, shouldClose = true, combinable = nil, description = "طعام" },
    burger       = { name = "burger",       label = "برغر",       weight = 250, type = "item", image = "burger.png",       unique = false, useable = true, shouldClose = true, combinable = nil, description = "طعام" },
    water        = { name = "water",        label = "ماء",         weight = 300, type = "item", image = "water.png",        unique = false, useable = true, shouldClose = true, combinable = nil, description = "ماء" },
    energy_drink = { name = "energy_drink", label = "مشروب طاقة", weight = 250, type = "item", image = "energy_drink.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "مشروب منشّط" },
    gi_card      = { name = "gi_card",      label = "بطاقة هوية",  weight = 50,  type = "item", image = "gi_card.png",      unique = true,  useable = false, shouldClose = false, combinable = nil, description = "بطاقة هوية الشخصية" },
    permit_stall = { name = "permit_stall", label = "تصريح كشك",  weight = 100, type = "item", image = "permit_stall.png", unique = true,  useable = false, shouldClose = false, combinable = nil, description = "تصريح كشك ساري" },
    lawyer_license = { name = "lawyer_license", label = "ترخيص محاماة", weight = 100, type = "item", image = "lawyer_license.png", unique = true, useable = false, shouldClose = false, combinable = nil, description = "ترخيص محامي معتمد" },
    -- أسلحة وذخيرة
    weapon_pistol  = { name = "weapon_pistol",  label = "مسدس", weight = 1000, type = "weapon", image = "weapon_pistol.png",  unique = true, useable = false, shouldClose = false, combinable = nil, description = "مسدس 9مم" },
    pistol_ammo    = { name = "pistol_ammo",    label = "ذخيرة مسدس", weight = 200, type = "item", image = "pistol_ammo.png", unique = false, useable = false, shouldClose = false, combinable = nil, description = "ذخيرة" },
    -- أجهزة
    phone  = { name = "phone",  label = "جوال",  weight = 300, type = "item", image = "phone.png",  unique = true, useable = true, shouldClose = true, combinable = nil, description = "جهاز جوال" },
    tablet = { name = "tablet", label = "تابلت", weight = 700, type = "item", image = "tablet.png", unique = true, useable = true, shouldClose = true, combinable = nil, description = "جهاز تابلت" },
}

if QBCore and QBCore.Shared then
    for k, v in pairs(ITEMS) do
        QBCore.Shared.Items[k] = v
    end
end

return ITEMS
