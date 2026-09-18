--[[
    fivem-strict-rp :: config/stalls.lua
    نظام الأكشاك (عرض بضاعة + طلب توريد)
]]

Stalls = {}

Stalls.Settings = {
    enabled            = true,
    maxStallsPerPlayer = 3,
    platformFeePercent = 5,
    orderExpireHours   = 24,
    minOrderQty        = 10,
    maxOrderQty        = 5000,
    permitCost         = 50000,
}

Stalls.Types = {
    goods  = { label = "كشك بضائع",  icon = "📦", maxItems = 10 },
    mining = { label = "كشك معادن",  icon = "⛏️", maxItems = 8 },
    farm   = { label = "كشك محاصيل", icon = "🌾", maxItems = 8 },
    misc   = { label = "كشك عام",    icon = "🏪", maxItems = 12 },
}

Stalls.Messages = {
    created      = "فُتح %s",
    closed       = "أُغلق الكشك.",
    noPermit     = "تحتاج تصريح كشك.",
    full         = "وصلت للحد الأقصى من الأكشاك.",
    listed       = "عُرض %s × %s بسعر $%s/وحدة",
    sold         = "بيع %s × %s — ربحت $%s",
    bought       = "اشتريت %s × %s بـ $%s",
    orderCreated = "طُلب توريد: %s × %s (مكافأة $%s)",
    orderFilled  = "وُفّر الطلب: %s × %s — ربحت $%s",
    orderExpired = "انتهت صلاحية الطلب.",
    notOwner     = "أنت لست مالك الكشك.",
    noStock      = "الكمية غير متوفرة.",
    noMoney      = "لا تملك المال الكافي.",
}

return Stalls
