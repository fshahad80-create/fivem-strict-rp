--[[
    fivem-strict-rp :: config/needs.lua
    نظام الاحتياجات والصحة والطقس — الإعدادات الكاملة.
]]

Needs = {}

Needs.Enabled = {
    hunger  = true,
    thirst  = true,
    energy  = true,
    hygiene = true,
    health  = true,
    weather = true,
    sync    = true,
}

Needs.Rates = {
    hunger  = { perMinute = 0.55 },
    thirst  = { perMinute = 0.75 },
    energy  = { perMinute = 0.40 },
    hygiene = { perMinute = 0.25 },
    health  = {
        drainWhenStarving   = 0.30,
        drainWhenDehydrated = 0.50,
        drainWhenExhausted  = 0.20,
    },
}

Needs.Thresholds = {
    hunger = {
        { at = 40, label = "جائع",     effect = "notify" },
        { at = 20, label = "جوع شديد", effect = "slowsprint", severity = 0.7 },
        { at = 5,  label = "تصمغ",     effect = "damage", dps = 2 },
    },
    thirst = {
        { at = 40, label = "عطشان",     effect = "notify" },
        { at = 20, label = "عطش شديد",  effect = "slowsprint", severity = 0.6 },
        { at = 5,  label = "تتضور",     effect = "damage", dps = 3 },
    },
    energy = {
        { at = 30, label = "متعب",       effect = "notify" },
        { at = 15, label = "إرهاق شديد", effect = "slowsprint", severity = 0.5 },
        { at = 5,  label = "إنهاك",      effect = "collapse" },
    },
    hygiene = {
        { at = 30, label = "متسخ",       effect = "notify" },
        { at = 10, label = "رائحتك سيئة", effect = "repulse", radius = 5.0 },
    },
}

Needs.Consumables = {
    food = {
        ["sandwich"]     = { hunger = 35, thirst = 5 },
        ["burger"]       = { hunger = 50, thirst = 8 },
        ["water"]        = { thirst = 40 },
        ["coffee"]       = { thirst = 25, energy = 15 },
        ["energy_drink"] = { thirst = 20, energy = 30 },
    },
    sleepPerMinute = 2.5,
}

Needs.Weather = {
    cycleMinutes = 20,
    presets = { "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST", "RAIN", "THUNDER", "SMOG", "FOGGY" },
    timeScale = 0.5,
    effects = {
        CLEAR      = { hunger = 1.0,  thirst = 1.0,  energy = 1.0 },
        EXTRASUNNY = { hunger = 1.0,  thirst = 1.35, energy = 1.1 },
        CLOUDS     = { hunger = 1.0,  thirst = 0.95, energy = 1.0 },
        OVERCAST   = { hunger = 1.05, thirst = 0.9,  energy = 1.05 },
        RAIN       = { hunger = 1.1,  thirst = 0.7,  energy = 1.25 },
        THUNDER    = { hunger = 1.15, thirst = 0.7,  energy = 1.4 },
        SMOG       = { hunger = 1.0,  thirst = 1.1,  energy = 1.15 },
        FOGGY      = { hunger = 1.0,  thirst = 0.95, energy = 1.05 },
    },
    harsh = {
        THUNDER    = { slowsprint = 0.85, extraEnergyDrain = 0.3 },
        RAIN       = { slowsprint = 0.90, extraEnergyDrain = 0.15 },
        EXTRASUNNY = { extraThirstDrain = 0.25 },
    },
}

Needs.Sync = {
    broadcastIntervalSeconds = 30,
    persistWeather = true,
}

Needs.Messages = {
    hungry     = "أنت جائع — كُل شيئاً.",
    thirsty    = "أنت عطشان — اشرب.",
    tired      = "أنت متعب — اذهب للنوم.",
    dirty      = "أنت بحاجة للاستحمام.",
    starving   = "جوع شديد! صحتك في خطر.",
    dehydrated = "عطش شديد! صحتك في خطر.",
    collapsed  = "أغمي عليك من الإرهاق.",
}

return Needs
