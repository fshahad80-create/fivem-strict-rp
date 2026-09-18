--[[
    fivem-strict-rp :: config/emergency.lua
    نظام الأمن العام والإسعاف (Police / EMS / MDT)
]]

Emergency = {}

Emergency.Settings = {
    enabled        = true,
    policeJob      = "police",
    emsJob         = "ambulance",
    mdtEnabled     = true,
    bodycamEnabled = true,
    bodycamStorageHours = 72,
    fingerprintEnabled = true,
    radarEnabled   = true,
    radarFine      = 500,
}

Emergency.PoliceRanks = {
    [0] = { label = "مجنّد",      canIssueWarrant = false, canFingerprint = false },
    [1] = { label = "شرطي",       canIssueWarrant = false, canFingerprint = true },
    [2] = { label = "عريف",       canIssueWarrant = true,  canFingerprint = true },
    [3] = { label = "رقيب",       canIssueWarrant = true,  canFingerprint = true },
    [4] = { label = "ملازم",      canIssueWarrant = true,  canFingerprint = true },
    [5] = { label = "نقيب",       canIssueWarrant = true,  canFingerprint = true },
    [6] = { label = "رائد",       canIssueWarrant = true,  canFingerprint = true },
    [7] = { label = "عقيد",       canIssueWarrant = true,  canFingerprint = true },
    [8] = { label = "القائد العام", canIssueWarrant = true, canFingerprint = true },
}

Emergency.WarrantTypes = {
    search    = { label = "مذكرة تفتيش", icon = "🔍" },
    arrest    = { label = "مذكرة قبض",   icon = "🚔" },
    release   = { label = "أمر إفراج",   icon = "🔓" },
    subpoena  = { label = "أمر استدعاء", icon = "📜" },
}

Emergency.EMSServices = {
    checkup   = { label = "فحص شامل",    price = 0,    duration = 10 },
    treatment = { label = "علاج",         price = 400,  duration = 15 },
    revive    = { label = "إنعاش",        price = 1200, duration = 20 },
    surgery   = { label = "عملية جراحية", price = 5000, duration = 40 },
    transport = { label = "نقل للمستشفى", price = 800,  duration = 25 },
}

Emergency.Insurance = {
    enabled = true,
    plans = {
        basic = { label = "تأمين أساسي", premium = 2000, coveragePercent = 40 },
        full  = { label = "تأمين شامل",  premium = 6000, coveragePercent = 80 },
    },
}

Emergency.TrafficFines = {
    speeding    = { label = "سرعة زائدة",     amount = 500 },
    redlight    = { label = "تجاوز إشارة",     amount = 300 },
    noLicense   = { label = "قيادة بدون رخصة", amount = 800 },
    reckless    = { label = "قيادة متهورة",    amount = 1200 },
    illegalpark = { label = "وقوف مخالف",     amount = 200 },
}

Emergency.Radars = {
    { x = 240.0, y = -1060.0, z = 29.0, speedLimit = 80, heading = 0.0 },
    { x = -300.0, y = -850.0, z = 32.0, speedLimit = 60, heading = 180.0 },
    { x = 900.0, y = -2300.0, z = 30.0, speedLimit = 80, heading = 90.0 },
}

Emergency.Messages = {
    warrantIssued  = "صدرت %s ضد %s",
    warrantRevoked = "تم إلغاء المذكرة.",
    fingerprinted  = "تم تبصيم %s",
    bodycamOn      = "بودي كام يعمل.",
    bodycamOff     = "أُوقف بودي كام.",
    reportCreated  = "أُنشئ التقرير #%s",
    callDispatched = "أُرسل البلاغ للوحدات.",
    treated        = "تم العلاج ($%s)",
    noInsurance    = "لا تملك تأميناً — ستدفع كامل المبلغ.",
    insured        = "التأمين غطّى %s%% من التكلفة.",
    notPolice      = "هذا للشرطة فقط.",
    notEMS         = "هذا للإسعاف فقط.",
    needRank       = "رتبتك لا تسمح بهذا الإجراء.",
}

return Emergency
