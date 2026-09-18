--[[
    fivem-strict-rp :: server/hunting.lua
    صيد البحر والبر — أسماك وحيوانات · جودة · أدوات · بيع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local H = Hunting

local Cooldown = {}
local Tools    = {}
local Caught   = {}
local function log(msg) print(('[fivem-strict-rp][hunting] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_hunting` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
        `sea_tool` VARCHAR(24) DEFAULT NULL, `land_tool` VARCHAR(24) DEFAULT NULL,
        `total_caught` INT NOT NULL DEFAULT 0, `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadHunter(citizenid, cb)
    MySQL.query('SELECT * FROM srp_hunting WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        Tools[citizenid] = { sea = r and r.sea_tool or nil, land = r and r.land_tool or nil }
        if cb then cb(Tools[citizenid]) end
    end)
end

local function persistHunter(citizenid)
    local t = Tools[citizenid]
    if not t then return end
    MySQL.query([[INSERT INTO srp_hunting (citizenid, sea_tool, land_tool) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE sea_tool = VALUES(sea_tool), land_tool = VALUES(land_tool)]],
        { citizenid, t.sea, t.land })
end

local function pickByRarity(list)
    local total = 0
    for _, item in ipairs(list) do total = total + (H.RarityWeights[item.rarity] or 10) end
    local roll = math.random(1, total)
    local acc = 0
    for _, item in ipairs(list) do
        acc = acc + (H.RarityWeights[item.rarity] or 10)
        if roll <= acc then return item end
    end
    return list[1]
end

local function rollQuality(toolKey)
    local tool = toolKey and H.Tools[toolKey]
    local bonus = tool and tool.bonusQuality or 0
    local base = math.random(H.Settings.qualityMin, H.Settings.qualityMax)
    local boosted = math.floor(base + (bonus * H.Settings.qualityMax))
    return math.max(1, math.min(H.Settings.qualityMax, boosted))
end

RegisterNetEvent('srp:hunting:fish', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local tool = Tools[cid] and Tools[cid].sea
    if not tool then TriggerClientEvent('QBCore:Notify', src, H.Messages.noTool, 'error') return end
    if Cooldown[src] and (os.time() - Cooldown[src]) < H.Settings.catchCooldown then
        TriggerClientEvent('QBCore:Notify', src, 'انتظر قليلاً.', 'error') return
    end
    Cooldown[src] = os.time()
    local fish = pickByRarity(H.SeaCatch)
    local quality = rollQuality(tool)
    local toolDef = H.Tools[tool]
    local qty = 1 + (toolDef.bonusYield or 0)
    Caught[cid] = Caught[cid] or {}
    Caught[cid][fish.key] = Caught[cid][fish.key] or { qty = 0, quality = quality }
    Caught[cid][fish.key].qty = Caught[cid][fish.key].qty + qty
    Caught[cid][fish.key].quality = quality
    local value = math.floor(fish.baseValue * H.Settings.qualityMultipliers[quality])
    TriggerClientEvent('QBCore:Notify', src, ('اصطدت %s × %s (%s★) — القيمة $%s'):format(fish.label, qty, quality, value), 'success')
end)

RegisterNetEvent('srp:hunting:hunt', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local tool = Tools[cid] and Tools[cid].land
    if not tool then TriggerClientEvent('QBCore:Notify', src, H.Messages.noTool, 'error') return end
    if Cooldown[src] and (os.time() - Cooldown[src]) < H.Settings.catchCooldown then
        TriggerClientEvent('QBCore:Notify', src, 'انتظر قليلاً.', 'error') return
    end
    Cooldown[src] = os.time()
    local animal = pickByRarity(H.LandCatch)
    local quality = rollQuality(tool)
    Caught[cid] = Caught[cid] or {}
    Caught[cid][animal.key] = Caught[cid][animal.key] or { qty = 0, quality = quality }
    Caught[cid][animal.key].qty = Caught[cid][animal.key].qty + 1
    Caught[cid][animal.key].quality = quality
    if animal.pelt then TriggerEvent('srp:supply:giveItem', src, animal.pelt, 1) end
    if animal.meat then TriggerEvent('srp:supply:giveItem', src, animal.meat, 2) end
    TriggerClientEvent('QBCore:Notify', src, ('أصبت %s (%s★) — جلد ولحم'):format(animal.label, quality), 'success')
end)

RegisterNetEvent('srp:hunting:buyTool', function(toolKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local tool = H.Tools[toolKey]
    if not tool then return end
    if Player.Functions.GetMoney('bank') < tool.price then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك المال الكافي.', 'error') return
    end
    Player.Functions.RemoveMoney('bank', tool.price, 'srp-hunting-tool')
    local cid = Player.PlayerData.citizenid
    Tools[cid] = Tools[cid] or {}
    if toolKey:sub(1, 3) == 'rod' then Tools[cid].sea = toolKey else Tools[cid].land = toolKey end
    persistHunter(cid)
    TriggerClientEvent('QBCore:Notify', src, ('ترقية %s'):format(tool.label), 'success')
end)

RegisterNetEvent('srp:hunting:sell', function(sellType)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local bag = Caught[cid]
    if not bag then TriggerClientEvent('QBCore:Notify', src, H.Messages.noCatch, 'error') return end
    local multiplier = sellType == 'restaurant' and 1.3 or 1.0
    local total = 0
    local count = 0
    for key, data in pairs(bag) do
        local def = nil
        for _, f in ipairs(H.SeaCatch) do if f.key == key then def = f end end
        for _, a in ipairs(H.LandCatch) do if a.key == key then def = a end end
        if def then
            local value = def.baseValue * H.Settings.qualityMultipliers[data.quality] * data.qty
            total = total + math.floor(value * multiplier)
            count = count + data.qty
        end
    end
    if count == 0 then TriggerClientEvent('QBCore:Notify', src, H.Messages.noCatch, 'error') return end
    local tax = math.floor(total * 0.08)
    local net = total - tax
    Player.Functions.AddMoney('bank', net, 'srp-hunting-sell')
    Caught[cid] = {}
    MySQL.query('UPDATE srp_hunting SET earned = earned + ? WHERE citizenid = ?', { net, cid })
    TriggerClientEvent('QBCore:Notify', src, ('بعت %s غنيمة بـ $%s (ضريبة $%s)'):format(count, net, tax), 'success')
end)

RegisterNetEvent('srp:hunting:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    loadHunter(cid, function(t)
        TriggerClientEvent('srp:hunting:show', src, t, Caught[cid] or {}, H.Tools)
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadHunter(Player.PlayerData.citizenid)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل نظام صيد البحر والبر.')
end)
