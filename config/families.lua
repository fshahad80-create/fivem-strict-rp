--[[
    fivem-strict-rp :: config/families.lua
    نظام العوائل / القبائل
]]

Families = {}

Families.Settings = {
    enabled          = true,
    maxMembers       = 20,
    minMembersToWar  = 3,
    createFee        = 250000,
    ranks            = { "عضو", "قائد جناح", "قائد", "شريف" },
    treasuryEnabled  = true,
    maxTreasury      = 5000000,
    warEnabled       = true,
    warDurationMin   = 30,
    warCooldownMin   = 120,
    treasuryStealPercent = 40,
    zoneCaptureEnabled = true,
}

Families.Requirements = {
    createMinPlaytimeHours = 20,
    applyMinLevel          = 5,
}

Families.Headquarters = {
    { x = 1000.0, y = -2200.0, z = 30.0, label = "مقر العائلة - الميناء" },
    { x = -1500.0, y = -200.0, z = 48.0, label = "مقر العائلة - الريف" },
    { x = 240.0, y = 300.0, z = 105.0, label = "مقر العائلة - التلال" },
}

Families.Zones = {
    { key = "docks", label = "منطقة الميناء", x = 1100.0, y = -3000.0, z = 5.0,  radius = 120.0 },
    { key = "grove", label = "منطقة غروف",   x = 100.0,  y = -1900.0, z = 22.0, radius = 100.0 },
    { key = "sandy", label = "منطقة ساندي",  x = 1800.0, y = 3700.0,  z = 33.0, radius = 130.0 },
}

Families.Defaults = { color = 3, tier = 1 }

Families.Messages = {
    created      = "تأسست عائلتك: %s",
    joined       = "انضممت إلى %s.",
    left         = "غادرت العائلة.",
    invited      = "تم دعوتك إلى %s.",
    notInFamily  = "أنت لست في عائلة.",
    alreadyIn    = "أنت في عائلة بالفعل.",
    full         = "العائلة ممتلئة.",
    notLeader    = "هذا الأمر للقائد فقط.",
    treasuryAdd  = "أُضيف $%s لخزنة العائلة (المجموع: $%s).",
    treasuryTake = "سُحب $%s من الخزنة.",
    warDeclared  = "%s أعلنت الحرب على %s!",
    warWon       = "%s سيطرت على منطقة %s وسرقت $%s.",
    allyFormed   = "تحالف بين %s و %s.",
    hostileSet   = "عداوة بين %s و %s.",
    rankChanged  = "رتبتك الآن: %s",
    noMoney      = "لا تملك المال الكافي.",
    roleRequired = "رتبتك لا تسمح بهذا الإجراء.",
}

return Families
