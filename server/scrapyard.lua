--[[
    fivem-strict-rp :: server/scrapyard.lua
    تشليح المركبات — تفكيك · جودة · مستوى · بيع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local Sc = Scrapyard
local S = Supply

local Cooldown = {}
local Workers  = {}
local Bags     = {}
local function log(msg) print(('[fivem-strict-rp][scrapyard] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_scrapyard` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
        `level` INT NOT NULL DEFAULT 1, `xp` BIGINT NOT NULL DEFAULT 0,
        `dismantled` INT NOT NULL DEFAULT 0, `earned` BIGINT NOT NULL DEFAULT 0,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadWorker(citizenid, cb)
    MySQL.query('SELECT * FROM srp_scrapyard WHERE citizenid = ?', { citizenid }, function(rows)
        local r = rows and rows[1]
        Workers[citizenid] = { level = r and r.level or 1, xp = r and r.xp or 0, dismantled = r and r.dismantled or 0, earned = r and r.earned or 0 }
        if cb then cb(Workers[citizenid]) end
    end)
end

local function persistWorker(citizenid)
    local w = Workers[citizenid]
    if not w then return end
    MySQL.query([[INSERT INTO srp_scrapyard (citizenid, level, xp, dismantled, earned) VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level), xp = VALUES(xp), dismantled = VALUES(dismantled), earned = VALUES(earned)]],
        { citizenid, w.level, w.xp, w.dismantled, w.earned })
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
    local cid = Player.PlayerData.citizenid
    return (Bags[cid] and Bags[cid][item] and Bags[cid][item].qty) or 0
end
local function giveItem(src, item, qty) TriggerEvent('srp:supply:giveItem', src, item, qty) end
local function takeItem(Player, item, qty)
    if isQbItem(item) then Player.Functions.RemoveItem(item, qty) end
end

local function qualityFromVehicle(engineHealth, bodyHealth)
    local avg = ((engineHealth or 0) + (bodyHealth or 0)) / 2
    if avg > 800 then return 5 elseif avg > 600 then return 4 elseif avg > 400 then return 3 elseif avg > 200 then return 2 else return 1 end
end
local QualityMult = { [1] = 0.6, [2] = 0.8, [3] = 1.0, [4] = 1.3, [5] = 1.6 }

RegisterNetEvent('srp:scrapyard:dismantle', function(netId, engineHealth, bodyHealth)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if Cooldown[src] and (os.time() - Cooldown[src]) < 10 then
        TriggerClientEvent('QBCore:Notify', src, Sc.Messages.cooldown, 'error') return
    end
    Cooldown[src] = os.time()
    Workers[cid] = Workers[cid] or { level = 1, xp = 0, dismantled = 0, earned = 0 }
    local worker = Workers[cid]
    local quality = qualityFromVehicle(engineHealth, bodyHealth)
    local minQ = math.min(5, 1 + math.floor(worker.level / 3))
    quality = math.max(quality, minQ)
    Bags[cid] = Bags[cid] or {}
    local gained = 0
    local totalValue = 0
    for item, def in pairs(Sc.Outputs) do
        local chance = def.chance + (worker.level * 2)
        if math.random(100) <= chance then
            local qty = math.random(def.qtyMin, def.qtyMax)
            local mult = QualityMult[quality] or 1.0
            qty = math.max(1, math.floor(qty * mult))
            giveItem(src, item, qty)
            gained = gained + 1
            totalValue = totalValue + (def.value * qty)
        end
    end
    local refund = math.floor(totalValue * Sc.Settings.valueRefundPercent / 100)
    if refund > 0 then Player.Functions.AddMoney('cash', math.min(refund, 5000), 'srp-scrapyard-refund') end
    worker.dismantled = worker.dismantled + 1
    worker.earned = worker.earned + refund
    worker.xp = worker.xp + Sc.Settings.xpPerDismantle
    local newLevel = math.min(5, 1 + math.floor(worker.xp / 300))
    if newLevel > worker.level then
        worker.level = newLevel
        TriggerClientEvent('QBCore:Notify', src, ('مستوى التشليح: %s'):format(newLevel), 'success')
    end
    persistWorker(cid)
    TriggerClientEvent('QBCore:Notify', src, ('فُكّكت المركبة — %s قطعة (جودة %s★)'):format(gained, quality), 'success')
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh ~= 0 and DoesEntityExist(veh) then DeleteEntity(veh) end
end)

RegisterNetEvent('srp:scrapyard:sell', function(itemKey, qty)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local def = Sc.Outputs[itemKey]
    if not def then return end
    qty = tonumber(qty) or getQty(Player, itemKey)
    if qty <= 0 or getQty(Player, itemKey) < qty then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه الكمية.', 'error') return
    end
    local gross = def.value * qty
    local tax = math.floor(gross * 0.08)
    local net = gross - tax
    takeItem(Player, itemKey, qty)
    Player.Functions.AddMoney('bank', net, 'srp-scrapyard-sell')
    TriggerClientEvent('QBCore:Notify', src, ('بيع %s × %s — $%s'):format(def.label, qty, net), 'success')
end)

local function sendData(src, cid)
    local bag = {}
    if Bags[cid] then for item, d in pairs(Bags[cid]) do bag[item] = d end end
    TriggerClientEvent('srp:scrapyard:show', src, Workers[cid] or { level = 1, xp = 0, dismantled = 0 }, Sc.Outputs, Sc.Settings, bag)
end

RegisterNetEvent('srp:scrapyard:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if not Workers[cid] then loadWorker(cid, function() sendData(src, cid) end) else sendData(src, cid) end
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    loadWorker(Player.PlayerData.citizenid, function() end)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل نظام تشليح المركبات.')
end)
