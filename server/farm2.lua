--[[
    fivem-strict-rp :: server/farm2.lua
    المزارع v1.7 الكاملة — فئات · جودة · أشجار · مواسم · معمل · صومعة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local F = Farm2
local S = Supply

local Farmers = {}
local CurrentSeason = "spring"
local SeasonStart = os.time()

local function log(msg) print(('[fivem-strict-rp][farm2] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_farm2` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
        `level` INT NOT NULL DEFAULT 1, `xp` BIGINT NOT NULL DEFAULT 0,
        `crops` LONGTEXT DEFAULT NULL, `trees` LONGTEXT DEFAULT NULL,
        `silo_level` INT NOT NULL DEFAULT 1, `silo_stock` LONGTEXT DEFAULT NULL,
        `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadFarmer(citizenid, cb)
    MySQL.query('SELECT * FROM srp_farm2 WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        Farmers[citizenid] = {
            level = r and r.level or 1, xp = r and r.xp or 0,
            crops = r and (json.decode(r.crops or '{}') or {}) or {},
            trees = r and (json.decode(r.trees or '[]') or {}) or [],
            siloLevel = r and r.silo_level or 1,
            siloStock = r and (json.decode(r.silo_stock or '{}') or {}) or {},
            earned = r and r.earned or 0,
        }
        if cb then cb(Farmers[citizenid]) end
    end)
end

local function persistFarmer(citizenid)
    local f = Farmers[citizenid]
    if not f then return end
    MySQL.query([[INSERT INTO srp_farm2 (citizenid, level, xp, crops, trees, silo_level, silo_stock, earned)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level), xp = VALUES(xp), crops = VALUES(crops),
        trees = VALUES(trees), silo_level = VALUES(silo_level), silo_stock = VALUES(silo_stock), earned = VALUES(earned)]],
        { citizenid, f.level, f.xp, json.encode(f.crops), json.encode(f.trees), f.siloLevel, json.encode(f.siloStock), f.earned })
end

local function isQbItem(item)
    if S.Settings.inventoryMode == 'internal' then return false end
    if S.Settings.inventoryMode == 'qbcore' then return true end
    return QBCore.Shared.Items[item] ~= nil
end
local function getQty(Player, item)
    if isQbItem(item) then
        local it = Player.Functions.GetItemByName(item)
        return it and it.amount or 0
    end
    return 0
end
local function giveItem(src, item, qty) TriggerEvent('srp:supply:giveItem', src, item, qty) end
local function takeItem(Player, item, qty)
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty) end
end

local function rollQuality(level)
    local minQ = math.min(5, 1 + math.floor(level / 10))
    local maxQ = math.min(5, 2 + math.floor(level / 8))
    return math.random(minQ, math.max(minQ, maxQ))
end
local QualityMult = { [1]=0.7, [2]=0.9, [3]=1.0, [4]=1.3, [5]=1.7 }

local function getSeason()
    local cycleSec = F.Settings.seasonCycleHours * 3600
    if os.time() - SeasonStart > cycleSec then
        SeasonStart = os.time()
        local keys = { "spring", "summer", "autumn", "winter" }
        local idx = 1
        for i, k in ipairs(keys) do if k == CurrentSeason then idx = i end end
        CurrentSeason = keys[(idx % #keys) + 1]
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', src, ('الموسم الآن: %s'):format(F.Seasons[CurrentSeason].label), 'inform')
        end
    end
    return F.Seasons[CurrentSeason]
end

RegisterNetEvent('srp:farm2:plant', function(plotIndex, cropKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local crop = nil
    for _, c in ipairs(F.Crops) do if c.key == cropKey then crop = c end end
    if not crop then return end
    Farmers[cid] = Farmers[cid] or { level = 1, xp = 0, crops = {}, trees = {}, siloLevel = 1, siloStock = {}, earned = 0 }
    local farmer = Farmers[cid]
    farmer.crops[plotIndex] = farmer.crops[plotIndex] or {}
    if crop.tier > math.ceil(farmer.level / 10) then
        TriggerClientEvent('QBCore:Notify', src, ('تحتاج مستوى %s لزراعة %s'):format((crop.tier - 1) * 10 + 1, crop.label), 'error') return
    end
    if farmer.crops[plotIndex].crop then
        TriggerClientEvent('QBCore:Notify', src, 'الأرض مزروعة بالفعل.', 'error') return
    end
    local seedCost = 15 * crop.tier
    if Player.Functions.GetMoney('cash') < seedCost then
        TriggerClientEvent('QBCore:Notify', src, F.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('cash', seedCost, 'srp-farm2-seed')
    local tier = F.CropTiers[crop.tier]
    local season = getSeason()
    local growTime = math.floor(tier.growMin / season.growMul)
    farmer.crops[plotIndex] = { crop = cropKey, plantedAt = os.time(), growTime = growTime, watered = false }
    persistFarmer(cid)
    TriggerClientEvent('QBCore:Notify', src, ('زرعت %s (ينمو خلال %s دقيقة)'):format(crop.label, growTime), 'success')
end)

RegisterNetEvent('srp:farm2:harvest', function(plotIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local farmer = Farmers[cid]
    if not farmer or not farmer.crops[plotIndex] or not farmer.crops[plotIndex].crop then
        TriggerClientEvent('QBCore:Notify', src, 'لا شيء لتحصده.', 'error') return
    end
    local plot = farmer.crops[plotIndex]
    local crop = nil
    for _, c in ipairs(F.Crops) do if c.key == plot.crop then crop = c end end
    if not crop then return end
    if (os.time() - plot.plantedAt) < (plot.growTime or 5) * 60 then
        local remaining = math.ceil((plot.growTime or 5) - (os.time() - plot.plantedAt) / 60)
        TriggerClientEvent('QBCore:Notify', src, ('لم ينضج — باقي %s دقيقة.'):format(remaining), 'inform') return
    end
    local tier = F.CropTiers[crop.tier]
    local quality = rollQuality(farmer.level)
    local qty = math.random(tier.yieldMin, tier.yieldMax)
    local season = getSeason()
    local value = math.floor(crop.sellPrice * QualityMult[quality] * season.priceMul) * qty
    giveItem(src, crop.key, qty)
    if crop.feed then giveItem(src, 'hay', qty) end
    farmer.xp = farmer.xp + F.Settings.xpPerHarvest
    local newLevel = math.min(F.Settings.maxLevel, 1 + math.floor(farmer.xp / 500))
    if newLevel > farmer.level then farmer.level = newLevel; TriggerClientEvent('QBCore:Notify', src, ('مستوى الفلاح: %s'):format(newLevel), 'success') end
    farmer.crops[plotIndex] = nil
    persistFarmer(cid)
    TriggerClientEvent('QBCore:Notify', src, ('حصدت %s × %s (%s★)'):format(crop.label, qty, quality), 'success')
end)

RegisterNetEvent('srp:farm2:plantTree', function(treeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local tree = F.Trees[treeKey]
    if not tree then return end
    if Player.Functions.GetMoney('bank') < tree.plantCost then
        TriggerClientEvent('QBCore:Notify', src, F.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', tree.plantCost, 'srp-farm2-tree')
    local cid = Player.PlayerData.citizenid
    Farmers[cid] = Farmers[cid] or { level = 1, xp = 0, crops = {}, trees = {}, siloLevel = 1, siloStock = {}, earned = 0 }
    table.insert(Farmers[cid].trees, { type = treeKey, plantedAt = os.time(), lastYield = 0 })
    persistFarmer(cid)
    TriggerClientEvent('QBCore:Notify', src, ('زرعت %s (حصاد متكرر)'):format(tree.label), 'success')
end)

RegisterNetEvent('srp:farm2:harvestTree', function(treeIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local farmer = Farmers[cid]
    if not farmer or not farmer.trees[treeIndex] then return end
    local t = farmer.trees[treeIndex]
    local tree = F.Trees[t.type]
    if not tree then return end
    local readyAt = t.lastYield > 0 and (t.lastYield + tree.regrowMin * 60) or (t.plantedAt + tree.firstYieldMin * 60)
    if os.time() < readyAt then
        local remaining = math.ceil((readyAt - os.time()) / 60)
        TriggerClientEvent('QBCore:Notify', src, ('الشجرة لم تنضج — باقي %s دقيقة.'):format(remaining), 'inform') return
    end
    giveItem(src, t.type, tree.yieldQty)
    t.lastYield = os.time()
    farmer.xp = farmer.xp + F.Settings.xpPerHarvest * 2
    persistFarmer(cid)
    TriggerClientEvent('QBCore:Notify', src, ('حصدت %s × %s'):format(tree.label, tree.yieldQty), 'success')
end)

RegisterNetEvent('srp:farm2:process', function(recipeKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local rec = F.Processing[recipeKey]
    if not rec then return end
    for item, need in pairs(rec.inputs) do
        if getQty(Player, item) < need then
            TriggerClientEvent('QBCore:Notify', src, ('تنقصك: %s × %s'):format(item, need), 'error') return
        end
    end
    for item, need in pairs(rec.inputs) do takeItem(Player, item, need) end
    giveItem(src, rec.output, rec.qty)
    TriggerClientEvent('QBCore:Notify', src, ('صنعت %s × %s'):format(rec.label, rec.qty), 'success')
end)

RegisterNetEvent('srp:farm2:upgradeSilo', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local farmer = Farmers[cid]
    if not farmer then return end
    local nextLevel = farmer.siloLevel + 1
    local cfg = F.Silo.levels[nextLevel]
    if not cfg then TriggerClientEvent('QBCore:Notify', src, 'الصومعة في أقصى مستوى.', 'inform') return end
    if Player.Functions.GetMoney('bank') < cfg.upgradeCost then TriggerClientEvent('QBCore:Notify', src, F.Messages.noMoney, 'error') return end
    Player.Functions.RemoveMoney('bank', cfg.upgradeCost, 'srp-farm2-silo')
    farmer.siloLevel = nextLevel
    persistFarmer(cid)
    TriggerClientEvent('QBCore:Notify', src, ('رُقّيت الصومعة للمستوى %s (سعة %s)'):format(nextLevel, cfg.capacity), 'success')
end)

CreateThread(function()
    while true do
        Wait(30 * 60 * 1000)
        for cid, farmer in pairs(Farmers) do
            for plotIdx, plot in pairs(farmer.crops) do
                if math.random(100) <= F.Settings.pestChancePercent then
                    local P = QBCore.Functions.GetPlayerByCitizenId(cid)
                    if P then TriggerClientEvent('QBCore:Notify', P.PlayerData.source, F.Messages.pestAttack, 'error') end
                    plot.plantedAt = plot.plantedAt - math.floor((plot.growTime or 5) * 60 * 0.2)
                end
            end
        end
    end
end)

RegisterNetEvent('srp:farm2:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    loadFarmer(cid, function(f)
        local season = getSeason()
        TriggerClientEvent('srp:farm2:show', src, f, {
            crops = F.Crops, tiers = F.CropTiers, trees = F.Trees,
            processing = F.Processing, season = CurrentSeason, seasonDef = season,
        })
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadFarmer(Player.PlayerData.citizenid)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل المزارع v1.7 الكاملة.')
end)
