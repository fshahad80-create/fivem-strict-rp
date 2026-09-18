--[[
    fivem-strict-rp :: config/economy.lua
    نظام الاقتصاد الواقعي — الإعدادات الكاملة.
]]

Economy = {}

Economy.Enabled = {
    salaries  = true,
    taxes     = true,
    inflation = true,
    bills     = true,
    insurance = true,
    bonuses   = true,
}

Economy.Salary = {
    payIntervalMinutes = 30,
    requireOnDuty     = true,
    maxDailyIncome    = 12000,
    jobs = {
        police     = { label = "الشرطة", base = 450, bonus = { perArrest = 150, perFine = 50, maxBonusPerShift = 2500 }, grades = { [0] = 1.00, [1] = 1.20, [2] = 1.45, [3] = 1.75, [4] = 2.10 } },
        ambulance  = { label = "الإسعاف", base = 425, bonus = { perRevive = 200, perTreatment = 75, maxBonusPerShift = 2200 }, grades = { [0] = 1.00, [1] = 1.20, [2] = 1.45, [3] = 1.75, [4] = 2.10 } },
        mechanic   = { label = "الميكانيكي", base = 380, bonus = { perRepair = 100, maxBonusPerShift = 1800 }, grades = { [0] = 1.00, [1] = 1.15, [2] = 1.35, [3] = 1.60 } },
        taxi       = { label = "التاكسي", base = 300, bonus = { perRide = 60, maxBonusPerShift = 1500 }, grades = { [0] = 1.00, [1] = 1.15, [2] = 1.30 } },
        trucker    = { label = "سائق الشاحنات", base = 340, bonus = { perDelivery = 120, maxBonusPerShift = 2000 }, grades = { [0] = 1.00, [1] = 1.15, [2] = 1.35 } },
        fisher     = { label = "الصياد", base = 260, bonus = { perCatch = 40, maxBonusPerShift = 1400 }, grades = { [0] = 1.00, [1] = 1.15, [2] = 1.30 } },
        realestate = { label = "العقارات", base = 500, bonus = { perSale = 800, maxBonusPerShift = 5000 }, grades = { [0] = 1.00, [1] = 1.30, [2] = 1.65, [3] = 2.00 } },
        unemployed = { label = "بلا عمل", base = 60, bonus = {}, grades = { [0] = 1.00 } },
    },
}

Economy.Taxes = {
    income = {
        enabled = true,
        percent = 12,
        brackets = {
            { upTo = 2000,  percent = 8  },
            { upTo = 6000,  percent = 12 },
            { upTo = 12000, percent = 18 },
            { upTo = nil,   percent = 25 },
        },
    },
    property = {
        enabled = true,
        perPropertyPerDay = 50,
        perVehiclePerDay  = 15,
    },
    latePayment = {
        enabled = true,
        graceHours = 24,
        penaltyPercent = 25,
        offenseKey = "bill_default",
        maxEscalationPerDay = 3,
    },
}

Economy.Inflation = {
    enabled = true,
    baseline = 1.00,
    increasePerCycle = 0.002,
    cycleMinutes = 60,
    max = 1.60,
    affects = {
        storePrices = true,
        salaries    = false,
        bills       = true,
    },
    allowManualOverride = true,
}

Economy.Bills = {
    intervalMinutes = 240,
    types = {
        electricity = { label = "الكهرباء", base = 120, inflationAffected = true },
        water       = { label = "الماء",     base = 60,  inflationAffected = true },
        phone       = { label = "الهاتف",    base = 40,  inflationAffected = false },
        rent        = { label = "الإيجار",   base = 350, inflationAffected = true },
    },
    requirePropertyForHousing = true,
}

Economy.Insurance = {
    enabled = true,
    premiumBase = 300,
    premiumPerVehicleValue = 0.005,
    coverage = {
        repairPercent = 80,
        maxPayoutPerClaim = 20000,
    },
    revokeLicenseOnDefault = true,
    defaultOffenseKey = "insurance_fraud",
}

Economy.Limits = {
    minBankBalance = -5000,
    maxCash = 500000,
    maxBank = 5000000,
}

Economy.Messages = {
    salaryPaid  = "تم صرف راتبك: $%s (بعد ضريبة $%s)",
    taxCharged  = "قُيّدت عليك ضريبة: $%s (%s)",
    billIssued  = "فاتورة جديدة: %s — $%s",
    billPaid    = "تم سداد فاتورة: %s",
    billOverdue = "فاتورتك متأخرة: %s",
    inflationUp = "مؤشر التضخم ارتفع إلى %s%%",
    insuredNow  = "تأمينك ساري — تغطية %s%% من الإصلاح.",
}

return Economy
