--[[
    fivem-strict-rp :: config/admin.lua
    تابلت الأدمن الشامل — يجمع كل الأنظمة (29 نظاماً)
]]

Admin = {}

Admin.Settings = {
    enabled      = true,
    openKey      = "F10",
    openCommand  = "admin",
    minPermission = "admin",
    maxResults   = 30,
    logActions   = true,
}

Admin.Sections = {
    penalties  = { label = "العقوبات",     icon = "🚔", desc = "نقاط · سجلات · رخص · حظر" },
    economy    = { label = "الاقتصاد",     icon = "💰", desc = "تضخم · فواتير · مطبوعات" },
    needs      = { label = "الاحتياجات",   icon = "🍔", desc = "جوع · عطش · طاقة" },
    rules      = { label = "القوانين",     icon = "📜", desc = "تقارير · إنذارات · إجراءات" },
    jobs       = { label = "الوظائف",      icon = "💼", desc = "تعيين · ترقية · إحصائيات" },
    dealers    = { label = "المعارض",      icon = "🚗", desc = "مخزون · مبيعات · مركبات" },
    mechanic   = { label = "الميكانيك",    icon = "🔧", desc = "مكائن · برمجة · زيت" },
    businesses = { label = "الأعمال",      icon = "🏢", desc = "ملاك · أرباح · عاملين" },
    farms      = { label = "المزارع",      icon = "🌾", desc = "محاصيل · مواسم · صوامع" },
    lands      = { label = "الأراضي",      icon = "🏗️", desc = "تخصيص · بناء · ملكية" },
    supply     = { label = "سلسلة التوريد", icon = "🔗", desc = "مخزون · وصفات · تداول" },
    paths      = { label = "المسارات",     icon = "🌳", desc = "خبرة · نقاط · شارات" },
    families   = { label = "العوائل",      icon = "🏠", desc = "أعضاء · خزنة · مناطق" },
    banks      = { label = "البنوك",       icon = "🏦", desc = "قروض · استثمار · بطاقات" },
    emergency  = { label = "الأمن العام",  icon = "🛡️", desc = "مذكرات · تقارير · MDT" },
    oil        = { label = "النفط",        icon = "🛢️", desc = "محطات · مخزون · أسعار" },
    hunting    = { label = "الصيد",        icon = "🎣", desc = "غنائم · أدوات" },
    livestock  = { label = "المواشي",      icon = "🐄", desc = "حظائر · حيوانات" },
    legal      = { label = "القضاء",       icon = "⚖️", desc = "قضايا · عقود · محامين" },
    stalls     = { label = "الأكشاك",      icon = "🏪", desc = "معروضات · طلبات" },
    scrapyard  = { label = "التشليح",      icon = "♻️", desc = "مساحة · منتجات" },
    players    = { label = "اللاعبون",     icon = "👥", desc = "بحث · معلومات · أدوات" },
    server     = { label = "السيرفر",      icon = "🖥️", desc = "إحصائيات · أداء · وقت" },
}

Admin.QuickTools = {
    goto     = { label = "الانتقال للاعب",    icon = "📍", perm = "admin" },
    bring    = { label = "إحضار اللاعب",       icon = "🧲", perm = "admin" },
    freeze   = { label = "تجميد اللاعب",       icon = "🧊", perm = "admin" },
    revive   = { label = "إنعاش/علاج",         icon = "💚", perm = "admin" },
    kick     = { label = "طرد",                icon = "👢", perm = "admin" },
    setjob   = { label = "تعيين وظيفة",        icon = "💼", perm = "admin" },
    setmoney = { label = "ضبط الأموال",        icon = "💵", perm = "admin" },
    clearinv = { label = "تفريغ الجيب",         icon = "🗑️", perm = "god" },
    spectate = { label = "مراقبة",             icon = "👁️", perm = "admin" },
    skin     = { label = "تغيير المظهر",       icon = "🕴️", perm = "admin" },
    noclip   = { label = "النقل الحر (Noclip)", icon = "🕊️", perm = "admin" },
    restart  = { label = "تنبيه الرستارت",     icon = "🔄", perm = "god" },
}

Admin.Messages = {
    opened         = "فُتح تابلت الأدمن",
    noPermission   = "ليس لديك صلاحية.",
    actionDone     = "نُفّذ الإجراء",
    playerNotFound = "اللاعب غير موجود.",
}

return Admin
