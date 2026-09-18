--[[
    fivem-strict-rp :: config/banks.lua
    نظام البنوك المتقدم — بطاقات · قروض · استثمارات · تحويلات
]]

Banks = {}

Banks.Settings = {
    enabled           = true,
    accountFee        = 0,
    cardIssuanceFee   = 500,
    transferFeePercent = 1,
    maxLoansPerPlayer = 2,
    investMin         = 50000,
    investMax         = 2000000,
}

Banks.CardTiers = {
    classic  = { label = "بطاقة كلاسيك", icon = "💳", dailyWithdrawLimit = 100000,  cashbackPercent = 0.5, creditLimit = 0,      fee = 500 },
    gold     = { label = "بطاقة ذهبية",  icon = "🟡", dailyWithdrawLimit = 500000,  cashbackPercent = 1.5, creditLimit = 100000, fee = 25000 },
    platinum = { label = "بطاقة بلاتينية", icon = "⚪", dailyWithdrawLimit = 2000000, cashbackPercent = 3.0, creditLimit = 500000, fee = 100000 },
}

Banks.LoanTerms = {
    short = { label = "قرض قصير",  months = 1, ratePercent = 5,  maxAmount = 50000 },
    mid   = { label = "قرض متوسط", months = 3, ratePercent = 9,  maxAmount = 250000 },
    long  = { label = "قرض طويل",  months = 6, ratePercent = 14, maxAmount = 1000000 },
}

Banks.Investments = {
    safe       = { label = "استثمار آمن",           icon = "🟢", returnMin = 0.02,  returnMax = 0.05, riskPercent = 5,  cycleHours = 24 },
    balanced   = { label = "استثمار متوازن",         icon = "🟡", returnMin = -0.03, returnMax = 0.10, riskPercent = 25, cycleHours = 24 },
    aggressive = { label = "استثمار عالي المخاطرة", icon = "🔴", returnMin = -0.15, returnMax = 0.30, riskPercent = 60, cycleHours = 24 },
}

Banks.PartnerOffers = {
    enabled = true,
    example = { partnerType = "grocery", discountPercent = 10, durationDays = 7 },
}

Banks.Messages = {
    cardIssued   = "أُصدرت %s (كاش باك %s%%)",
    transferDone = "حُوّل $%s إلى %s (رسوم $%s)",
    loanApproved = "حُصل على قرض: $%s على %s شهر (فائدة %s%%)",
    loanRepaid   = "تم سداد القسط ($%s)",
    investPlaced = "استُثمر $%s في %s",
    investReturn = "عائد استثمارك: $%s (%s%%)",
    noMoney      = "لا تملك المال الكافي.",
    noCredit     = "حدك الائتماني غير كافٍ.",
    maxLoans     = "وصلت للحد الأقصى من القروض.",
    notOwner     = "هذا الأمر لمالك البنك.",
    cashback     = "كاش باك: +$%s",
}

return Banks
