--[[
    fivem-strict-rp :: config/carplay.lua
    نظام الكار بلاي والمركبات المتقدم + قيادة ذاتية (P) + تثبيت سرعة (N) + مانع مفتاح T
]]

Carplay = {}

Carplay.Settings = {
    enabled          = true,
    openKey          = "F4",
    volumeDefault    = 50,
    maxVolume        = 100,
    cameraDistance   = 6.0,
    engineImmobilize = false,
    radioStations    = 6,
}

-- القيادة الذاتية (مفتاح P)
Carplay.Autopilot = {
    enabled         = true,
    key             = "P",
    defaultSpeed    = 60,
    minSpeed        = 30,
    maxSpeed        = 120,
    scanDistance    = 30.0,
    brakeDistance   = 12.0,
    stopDistance    = 6.0,
    watchPeds       = true,
    watchVehicles   = true,
    obeyTraffic     = false,
    minEngineHealth = 250.0,
}

-- تثبيت السرعة (المفتاح N · الأسهم للتحكم بالسرعة)
Carplay.Cruise = {
    enabled        = true,
    key            = "N",
    incKey         = "UP",
    decKey         = "DOWN",
    defaultSpeed   = 80,
    minSpeed       = 20,
    maxSpeed       = 200,
    step           = 10,
    cancelOnBrake  = true,
    cancelOnImpact = true,
}

-- مانع انزلاق مفتاح T
Carplay.AntiSlip = {
    enabled          = true,
    blockedControl   = 74,
    onlyWhileDriving = true,
    drivingSpeedKmh  = 5,
    hardBlock        = true,
}

Carplay.Stations = {
    { id = 1, label = "أخبار",     freq = "90.1",  genre = "news" },
    { id = 2, label = "رياضة",     freq = "92.5",  genre = "sport" },
    { id = 3, label = "طرب",       freq = "95.3",  genre = "arabic" },
    { id = 4, label = "قرآن",      freq = "98.7",  genre = "quran" },
    { id = 5, label = "إلكترونية", freq = "101.2", genre = "edm" },
    { id = 6, label = "هيب هوب",   freq = "104.8", genre = "hiphop" },
}

Carplay.VehicleControls = {
    engine    = { label = "المحرك",        icon = "🔑" },
    radio     = { label = "الراديو",        icon = "📻" },
    nav       = { label = "الملاحة",       icon = "🗺️" },
    camera    = { label = "الكاميرا الخلفية", icon = "📹" },
    hazards   = { label = "الخطر",         icon = "⚠️" },
    lock      = { label = "قفل المركبة",   icon = "🔒" },
    autopilot = { label = "القيادة الذاتية", icon = "🤖" },
    cruise    = { label = "تثبيت السرعة",  icon = "🎯" },
}

Carplay.FuelTypes = {
    gasoline = { label = "بنزين", icon = "⛽" },
    diesel   = { label = "ديزل",  icon = "🛢️" },
    electric = { label = "كهرباء", icon = "🔌" },
}

Carplay.DealerExtras = {
    unlimitedSales   = true,
    rareStock        = true,
    instantDelivery  = true,
    arabicPlates     = true,
    colorChoice      = true,
    inspectOnTrade   = true,
}

Carplay.Messages = {
    opened       = "فُتح الكار بلاي",
    stationSet   = "المحطة: %s (%s)",
    volumeSet    = "الصوت: %s%%",
    navSet       = "الملاحة إلى: %s",
    hazardsOn    = "أُشغلت إشارات الخطر",
    hazardsOff   = "أُطفأت إشارات الخطر",
    lockChanged  = "تغيّر حالة القفل",
    noVehicle    = "أنت لست داخل مركبة.",
    engineToggle = "تغيّر حالة المحرك",
    autopilotOn  = "القيادة الذاتية مُفعّلة",
    autopilotOff = "أُلغيت القيادة الذاتية",
    cruiseOn     = "تثبيت السرعة مُفعّل",
    cruiseOff    = "أُلغى تثبيت السرعة",
}

return Carplay
