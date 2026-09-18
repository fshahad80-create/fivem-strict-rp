--[[
    fivem-strict-rp :: config/legal.lua
    نظام المحاماة والمحكمة + العقود
]]

Legal = {}

Legal.Settings = {
    enabled          = true,
    judgeJob         = "judge",
    lawyerJob        = "lawyer",
    lawyerLicenseFee = 75000,
    lawsuitFee       = 15000,
    contractFee      = 5000,
    trialDurationMin = 60,
    contractExpireDays = 30,
    maxOpenCases     = 20,
}

Legal.CaseTypes = {
    criminal   = { label = "دعوى جنائية",  icon = "⚖️", requiresEvidence = true },
    civil      = { label = "دعوى مدنية",   icon = "📋", requiresEvidence = false },
    commercial = { label = "دعوى تجارية",  icon = "💼", requiresEvidence = false },
    family     = { label = "دعوى أحوال",   icon = "👨‍👩‍👧", requiresEvidence = false },
    appeal     = { label = "استئناف",      icon = "📜", requiresEvidence = true },
}

Legal.Verdicts = {
    guilty    = { label = "إدانة",       icon = "🔴", canFine = true, canJail = true },
    innocent  = { label = "براءة",       icon = "🟢", canFine = false, canJail = false },
    settled   = { label = "صلح",         icon = "🤝", canFine = true, canJail = false },
    dismissed = { label = "شطب الدعوى",  icon = "⚪", canFine = false, canJail = false },
}

Legal.Sentencing = {
    maxFine = 500000,
    maxJailMonths = 60,
    services = {
        notary    = { label = "توثيق عقد",      price = 5000 },
        powerOfAttorney = { label = "وكالة",    price = 8000 },
        certificate = { label = "شهادة رسمية",  price = 3000 },
    },
}

Legal.Locations = {
    court  = { x = 213.0, y = -1002.0, z = 30.0, label = "المحكمة" },
    notary = { x = 150.0, y = -1040.0, z = 29.0, label = "الكاتب العدل" },
}

Legal.Messages = {
    licenseIssued  = "صدر ترخيص المحاماة (صالح 90 يوم)",
    caseFiled      = "رُفعت الدعوى #%s ضد %s",
    caseAssigned   = "أُسندت الدعوى #%s للقاضي",
    verdictIssued  = "الحكم في #%s: %s",
    contractSigned = "وُقّع العقد من الطرف الأول — بانتظار الطرف الثاني",
    contractDone   = "العقد مكتمل التوقيع",
    contractVoid   = "العقد باطل (لم يُوقّع من الطرفين)",
    notLawyer      = "أنت لست محامياً معتمداً.",
    notJudge       = "أنت لست قاضياً.",
    needEvidence   = "هذا النوع يحتاج أدلة.",
    noMoney        = "لا تملك المال الكافي.",
}

return Legal
