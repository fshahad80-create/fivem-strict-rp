--[[
    fivem-strict-rp :: server/livestock.lua
    نظام المواشي — تربية · إطعام · جمع · ذبح · تزاوج.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local L = Livestock
local S = Supply

local Pens = {}
local function log(msg) print(('[fivem-strict-rp][livestock] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_livestock` (
        `pen_id` INT NOT NULL PRIMARY KEY, `owner` VARCHAR(50) DEFAULT NULL,
        `animals` LONGTEXT DEFAULT NULL, `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadPens()
    MySQL.query('SELECT * FROM srp_livestock', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            Pens[r.pen_id] = { owner = r.owner, animals = json.decode(r.animals or '[]') or {}, earned = r.earned }
        end
    end)
end

local function persistPen(penId)
    local p = Pens[penId]
    if not p then return end
    MySQL.query([[INSERT INTO srp_livestock (pen_id, owner, animals, earned) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE owner = VALUES(owner), animals = VALUES(animals), earned = VALUES(earned)]],
        { penId, p.owner, json.encode(p.animals), p.earned })
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

RegisterNetEvent('srp:livestock:buyPen', function(penId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    if Pens[penId] and Pens[penId].owner then
        TriggerClientEvent('QBCore:Notify', src, 'الحظيرة مملوكة مسبقاً.', 'error') return
    end
    local cost = 150000
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-livestock-pen')
    Pens[penId] = { owner = Player.PlayerData.citizenid, animals = {}, earned = 0 }
    persistPen(penId)
    TriggerClientEvent('QBCore:Notify', src, ('اشتريت الحظيرة بـ $%s'):format(cost), 'success')
end)

RegisterNetEvent('srp:livestock:buyAnimal', function(penId, animalKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local animal = L.Animals[animalKey]
    if not animal then return end
    local pen = Pens[penId]
    if not pen or pen.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    if #pen.animals >= L.Settings.maxAnimals then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.penFull, 'error') return
    end
    if Player.Functions.GetMoney('bank') < animal.buyPrice then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', animal.buyPrice, 'srp-livestock-buy')
    table.insert(pen.animals, { type = animalKey, health = 100, quality = math.random(1, 3), lastFed = os.time(), lastCollected = 0, lastBred = 0 })
    persistPen(penId)
    TriggerClientEvent('QBCore:Notify', src, ('اشتريت %s ($%s)'):format(animal.label, animal.buyPrice), 'success')
end)

RegisterNetEvent('srp:livestock:feed', function(penId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local pen = Pens[penId]
    if not pen or pen.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    if #pen.animals == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'لا توجد مواشٍ.', 'error') return
    end
    local needed = 0
    for _, a in ipairs(pen.animals) do
        local animal = L.Animals[a.type]
        if animal then needed = needed + animal.feedCost end
    end
    local feedUnits = math.ceil(needed / 15)
    local haveFeed = getQty(Player, 'hay') + getQty(Player, 'corn') + getQty(Player, 'wheat')
    if haveFeed < feedUnits then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.noFood, 'error') return
    end
    local remaining = feedUnits
    for _, f in ipairs({ 'hay', 'corn', 'wheat' }) do
        if remaining <= 0 then break end
        local q = getQty(Player, f)
        local take = math.min(q, remaining)
        if take > 0 then takeItem(Player, f, take); remaining = remaining - take end
    end
    for _, a in ipairs(pen.animals) do
        a.health = math.min(100, a.health + 40)
        a.lastFed = os.time()
    end
    persistPen(penId)
    TriggerClientEvent('QBCore:Notify', src, ('أطعمت %s حيوان'):format(#pen.animals), 'success')
end)

RegisterNetEvent('srp:livestock:collect', function(penId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local pen = Pens[penId]
    if not pen or pen.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    local cooldown = L.Settings.collectCooldownMin * 60
    local collected = {}
    for _, a in ipairs(pen.animals) do
        local animal = L.Animals[a.type]
        if animal and animal.products and (os.time() - (a.lastCollected or 0)) > cooldown then
            for item, prod in pairs(animal.products) do
                local mult = L.Settings.qualityMultipliers[a.quality] or 1.0
                local qty = math.max(1, math.floor(prod.qty * mult))
                giveItem(src, item, qty)
                collected[item] = (collected[item] or 0) + qty
            end
            a.lastCollected = os.time()
        end
    end
    persistPen(penId)
    local summary = {}
    for item, qty in pairs(collected) do summary[#summary+1] = ('%s×%s'):format(item, qty) end
    if #summary == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'لا منتجات جاهزة بعد.', 'inform')
    else
        TriggerClientEvent('QBCore:Notify', src, ('جمعت: %s'):format(table.concat(summary, ' · ')), 'success')
    end
end)

RegisterNetEvent('srp:livestock:slaughter', function(penId, animalIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local pen = Pens[penId]
    if not pen or pen.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    local a = pen.animals[animalIndex]
    if not a then return end
    local animal = L.Animals[a.type]
    if not animal then return end
    local gained = {}
    for item, qty in pairs(animal.slaughter or {}) do
        local mult = L.Settings.qualityMultipliers[a.quality] or 1.0
        local finalQty = math.max(1, math.floor(qty * mult))
        giveItem(src, item, finalQty)
        gained[#gained+1] = ('%s×%s'):format(item, finalQty)
    end
    table.remove(pen.animals, animalIndex)
    persistPen(penId)
    TriggerClientEvent('QBCore:Notify', src, ('ذبحت %s — %s'):format(animal.label, table.concat(gained, ' · ')), 'success')
end)

RegisterNetEvent('srp:livestock:breed', function(penId, animalIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local pen = Pens[penId]
    if not pen or pen.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    local a = pen.animals[animalIndex]
    if not a then return end
    local animal = L.Animals[a.type]
    if not animal or not animal.breed then
        TriggerClientEvent('QBCore:Notify', src, 'هذا الحيوان لا يتزاوج.', 'error') return
    end
    if a.health < 50 then
        TriggerClientEvent('QBCore:Notify', src, 'الحيوان ضعيف — أطعمه أولاً.', 'error') return
    end
    if os.time() - (a.lastBred or 0) < L.Settings.breedCooldownMin * 60 then
        TriggerClientEvent('QBCore:Notify', src, 'الحيوان في فترة راحة.', 'error') return
    end
    if #pen.animals >= L.Settings.maxAnimals then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.penFull, 'error') return
    end
    a.lastBred = os.time()
    table.insert(pen.animals, { type = a.type, health = 100, quality = math.random(1, 3), lastFed = os.time(), lastCollected = 0, lastBred = 0 })
    persistPen(penId)
    TriggerClientEvent('QBCore:Notify', src, ('وُلد %s جديد!'):format(animal.label), 'success')
end)

CreateThread(function()
    while true do
        Wait(60 * 60 * 1000)
        for penId, pen in pairs(Pens) do
            local changed = false
            for i = #pen.animals, 1, -1 do
                local a = pen.animals[i]
                local animal = L.Animals[a.type]
                if animal then
                    local hoursSinceFed = (os.time() - (a.lastFed or 0)) / 3600
                    if hoursSinceFed > (L.Settings.feedIntervalMin / 60) then
                        a.health = a.health - L.Settings.healthDecayPerHour
                        changed = true
                        if a.health <= 0 then
                            table.remove(pen.animals, i)
                            local owner = QBCore.Functions.GetPlayerByCitizenId(pen.owner)
                            if owner then TriggerClientEvent('QBCore:Notify', owner.PlayerData.source, L.Messages.animalDied, 'error') end
                        end
                    end
                end
            end
            if changed then persistPen(penId) end
        end
    end
end)

RegisterNetEvent('srp:livestock:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local list = {}
    for _, cfg in ipairs(L.Pens) do
        local p = Pens[cfg.id] or {}
        list[#list+1] = { id = cfg.id, label = cfg.label, owner = p.owner, animals = p.animals or {}, mine = p.owner == Player.PlayerData.citizenid }
    end
    TriggerClientEvent('srp:livestock:show', src, list, L.Animals, L.Feed)
end)

CreateThread(function()
    ensureSchema()
    Wait(3500)
    loadPens()
    log('تم تحميل نظام المواشي.')
end)
