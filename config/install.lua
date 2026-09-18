--[[
    fivem-strict-rp :: config/install.lua
    نظام التركيب والتجميع (Install / Assembly)
]]

Install = {}

Install.Settings = {
    enabled           = true,
    requireOnDuty     = true,
    paymentMode       = 'self',
    consumeOnInstall  = true,
    allowUninstall    = true,
    uninstallRefund   = 50,
    singlePerCategory = true,
}

Install.Effects = {
    engine_v6   = { label = "محرك V6",   category = "engine", mod = { [11] = 2, [12] = 1, [13] = 1 }, power = 1.10, speedMul = 1.05 },
    engine_v8   = { label = "محرك V8",   category = "engine", mod = { [11] = 3, [12] = 2, [13] = 2 }, power = 1.22, speedMul = 1.10 },
    engine_ls   = { label = "محرك LS",   category = "engine", mod = { [11] = 4, [12] = 3, [13] = 3 }, power = 1.38, speedMul = 1.16 },
    engine_race = { label = "محرك Race", category = "engine", mod = { [11] = 5, [12] = 4, [13] = 4 }, power = 1.55, speedMul = 1.24 },
    trans_standard = { label = "قير عادي",  category = "transmission", mod = { [13] = 1, [15] = 1 }, power = 1.00, speedMul = 1.00 },
    trans_sport    = { label = "قير رياضي", category = "transmission", mod = { [13] = 3, [15] = 3 }, power = 1.08, speedMul = 1.05 },
    trans_race     = { label = "قير سباق",  category = "transmission", mod = { [13] = 5, [15] = 5 }, power = 1.18, speedMul = 1.12 },
    turbocharger = { label = "تيربو", category = "turbo", mod = { [18] = 1 }, power = 1.20, speedMul = 1.10, turbo = true },
    camshaft     = { label = "كامة",      category = "internal", power = 1.12, speedMul = 1.04 },
    crankshaft   = { label = "عمود كرنك", category = "internal", power = 1.15, speedMul = 1.05 },
    piston       = { label = "بستم",      category = "internal", power = 1.10, speedMul = 1.03, perUnit = true },
    engine_block = { label = "بلوك محرك", category = "internal", engineHealth = 1.30, power = 1.05 },
    tint_kit = { label = "تظليل", category = "style", tint = 4 },
}

Install.Assembly = {
    engine_v6 = {
        label = "تجميع محرك V6", icon = "🔧", time = 25, category = "engine",
        parts = { engine_block = 1, piston = 6, crankshaft = 1, camshaft = 1 },
        tools = { welder_tool = 1 },
    },
    engine_v8 = {
        label = "تجميع محرك V8", icon = "🔧", time = 35, category = "engine",
        parts = { engine_block = 1, piston = 8, crankshaft = 1, camshaft = 2 },
        tools = { welder_tool = 1 },
    },
    engine_ls = {
        label = "تجميع محرك LS", icon = "🔧", time = 50, category = "engine",
        parts = { engine_block = 2, piston = 8, crankshaft = 2, camshaft = 2, turbocharger = 1 },
        tools = { welder_tool = 2 },
    },
    engine_race = {
        label = "تجميع محرك Race", icon = "🔧", time = 70, category = "engine",
        parts = { engine_block = 2, piston = 10, crankshaft = 2, camshaft = 4, turbocharger = 2 },
        tools = { welder_tool = 2 },
    },
    trans_standard = {
        label = "تجميع قير عادي", icon = "⚙️", time = 20, category = "transmission",
        parts = { engine_part = 4, metal_beam = 2 },
        tools = { welder_tool = 1 },
    },
    trans_sport = {
        label = "تجميع قير رياضي", icon = "⚙️", time = 30, category = "transmission",
        parts = { engine_part = 6, metal_beam = 3, piston = 2 },
        tools = { welder_tool = 1 },
    },
    trans_race = {
        label = "تجميع قير سباق", icon = "⚙️", time = 45, category = "transmission",
        parts = { engine_part = 10, metal_beam = 5, crankshaft = 1 },
        tools = { welder_tool = 2 },
    },
}

Install.Messages = {
    installed     = "تم تركيب %s — الأداء تحسّن.",
    uninstalled   = "تم إزالة %s (استرداد $%s).",
    assemb        = "تم تجميع %s بنجاح.",
    missingParts  = "تنقصك قطع للتجميع.",
    missingTools  = "تحتاج أداة لحام.",
    alreadyFitted = "هذه القطعة مركّبة مسبقاً.",
    noVehicle     = "لا توجد مركبة قريبة.",
    notOwner      = "أنت لست مالك هذه المركبة.",
    assembledOne  = "تحتاج تجميع القطع أولاً.",
}

return Install
