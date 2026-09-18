--[[
    fivem-strict-rp :: config/phone.lua
    نظام تطبيقات الجوال (LB Phone) — أبشر · ناجز · مدى · مزادي · أطلبني
]]

Phone = {}

Phone.Settings = {
    enabled       = true,
    openKey       = "F2",
    startBalance  = 0,
    medaFeePercent = 1,
    maxOrderText  = 240,
    defaultAuctionMin = 60,
    auctionFeePercent = 3,
}

Phone.Apps = {
    absher  = { label = "أبشر",   icon = "🛂", desc = "وثائقك · مخالفاتك · موقع مركبتك" },
    najiz   = { label = "ناجز",   icon = "⚖️", desc = "عقودك · قضاياك" },
    meda    = { label = "مدى",    icon = "💳", desc = "جهاز دفع المؤسسات" },
    mazadi  = { label = "مزادي",  icon = "🔨", desc = "مزادات الأعمال الحرة" },
    atlobni = { label = "أطلبني", icon = "📢", desc = "طلبات التوريد والعمل" },
}

Phone.DocumentTypes = {
    license   = { label = "رخصة قيادة", icon = "🪪" },
    weapon    = { label = "رخصة سلاح",  icon = "🔫" },
    business  = { label = "سجل تجاري",  icon = "🏢" },
    health    = { label = "تأمين صحي",  icon = "🏥" },
    residence = { label = "إقامة",      icon = "🏠" },
}

Phone.MedaServices = {
    createTerminal = { label = "تركيب جهاز دفع", cost = 15000 },
    linkBusiness   = { label = "ربط الجهاز بمؤسسة", cost = 0 },
    setAccount     = { label = "تعيين حساب الاستلام", cost = 0 },
}

Phone.AuctionCategories = {
    vehicles = { label = "مركبات",  icon = "🚗" },
    property = { label = "عقارات",  icon = "🏠" },
    business = { label = "أعمال",   icon = "💼" },
    items    = { label = "مقتنيات", icon = "📦" },
    services = { label = "خدمات",   icon = "🛠️" },
}

Phone.AtlobniSettings = {
    categories = {
        mining = { label = "تعدين", icon = "⛏️" },
        farm   = { label = "زراعة", icon = "🌾" },
        craft  = { label = "تصنيع", icon = "🔨" },
        haul   = { label = "نقل",   icon = "🚛" },
        misc   = { label = "عام",   icon = "📦" },
    },
    expireHours = 48,
}

Phone.Messages = {
    opened         = "فُتح الجوال",
    docIssued      = "صدرت وثيقة: %s",
    fineDisputed   = "رُفع اعتراض على مخالفة #%s",
    vehicleLocated = "موقع مركبتك محدد على الخريطة",
    medaLinked     = "ارتبط الجهاز بـ %s",
    auctionCreated = "أُنشئ مزاد: %s (يبدأ بـ $%s)",
    auctionBid     = "عرض $%s على مزاد %s",
    auctionWon     = "فزت بالمزاد: %s بـ $%s",
    orderCreated   = "أُنشئ طلب: %s",
    orderOffered   = "عرضك أُرسل على الطلب #%s",
    orderAccepted  = "قُبل عرضك على الطلب #%s",
    noMoney        = "لا تملك المال الكافي.",
    notOwner       = "هذا لك فقط كمؤسسة.",
}

return Phone
