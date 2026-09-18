--[[
    fivem-strict-rp :: server/stalls.lua
    الأكشاك — عرض بضاعة · شراء · طلب توريد بمكافأة تلقائية.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local St = Stalls
local S = Supply

local Stalls_ = {}
local Orders  = {}
local function log(msg) print(('[fivem-strict-rp][stalls] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function getByCid(cid) return QBCore.Functions.GetPlayerByCitizenId(cid) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_stalls` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `owner` VARCHAR(50) NOT NULL,
        `type` VARCHAR(16) NOT NULL, `x` DOUBLE NOT NULL, `y` DOUBLE NOT NULL, `z` DOUBLE NOT NULL,
        `listings` LONGTEXT DEFAULT NULL, `earnings` BIGINT NOT NULL DEFAULT 0,
        `open` TINYINT(1) NOT NULL DEFAULT 1,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_stall_orders` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `stall_id` INT NOT NULL,
        `owner` VARCHAR(50) NOT NULL, `item` VARCHAR(32) NOT NULL, `qty` INT NOT NULL,
        `reward` BIGINT NOT NULL, `status` VARCHAR(12) NOT NULL DEFAULT 'open',
        `expires_at` INT NOT NULL, `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadAll()
    MySQL.query('SELECT * FROM srp_stalls', {}, function(rows)
        Stalls_ = {}
        for _, r in ipairs(rows or {}) do
            Stalls_[r.id] = { id = r.id, owner = r.owner, type = r.type, x = r.x, y = r.y, z = r.z,
                listings = json.decode(r.listings or '{}') or {}, earnings = r.earnings, open = r.open == 1 }
        end
    end)
    MySQL.query('SELECT * FROM srp_stall_orders WHERE status = "open"', {}, function(rows)
        Orders = {}
        for _, r in ipairs(rows or {}) do Orders[r.id] = r end
    end)
end

local function persistStall(id)
    local s = Stalls_[id]
    if not s then return end
    MySQL.query('UPDATE srp_stalls SET listings = ?, earnings = ?, open = ? WHERE id = ?',
        { json.encode(s.listings), s.earnings, s.open and 1 or 0, id })
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

RegisterNetEvent('srp:stalls:create', function(stallType, x, y, z)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local t = St.Types[stallType]
    if not t then return end
    local cid = Player.PlayerData.citizenid
    local count = 0
    for _, s in pairs(Stalls_) do if s.owner == cid then count = count + 1 end end
    if count >= St.Settings.maxStallsPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, St.Messages.full, 'error') return
    end
    MySQL.insert('INSERT INTO srp_stalls (owner, type, x, y, z) VALUES (?, ?, ?, ?, ?)',
        { cid, stallType, x, y, z }, function(id)
        Stalls_[id] = { id = id, owner = cid, type = stallType, x = x, y = y, z = z, listings = {}, earnings = 0, open = true }
        TriggerClientEvent('QBCore:Notify', src, ('فُتح %s'):format(t.label), 'success')
    end)
end)

RegisterNetEvent('srp:stalls:toggle', function(stallId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local s = Stalls_[stallId]
    if not s or s.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, St.Messages.notOwner, 'error') return
    end
    s.open = not s.open
    persistStall(stallId)
    TriggerClientEvent('QBCore:Notify', src, s.open and 'كشكك مفتوح.' or 'أُغلق الكشك.', 'inform')
end)

RegisterNetEvent('srp:stalls:list', function(stallId, item, qty, price)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local s = Stalls_[stallId]
    if not s or s.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, St.Messages.notOwner, 'error') return
    end
    qty = tonumber(qty) or 0
    price = tonumber(price) or 0
    if qty <= 0 or price <= 0 then return end
    if getQty(Player, item) < qty then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك هذه الكمية.', 'error') return
    end
    takeItem(Player, item, qty)
    s.listings[item] = { qty = (s.listings[item] and s.listings[item].qty or 0) + qty, price = price }
    persistStall(stallId)
    TriggerClientEvent('QBCore:Notify', src, ('عُرض %s × %s بسعر $%s'):format(item, qty, price), 'success')
end)

RegisterNetEvent('srp:stalls:buy', function(stallId, item, qty)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local s = Stalls_[stallId]
    if not s or not s.listings[item] then
        TriggerClientEvent('QBCore:Notify', src, 'العنصر غير معروض.', 'error') return
    end
    local listing = s.listings[item]
    qty = math.min(tonumber(qty) or 1, listing.qty)
    if qty <= 0 then return end
    local cost = listing.price * qty
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, St.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-stall-buy')
    giveItem(src, item, qty)
    local fee = math.floor(cost * St.Settings.platformFeePercent / 100)
    local net = cost - fee
    local owner = getByCid(s.owner)
    if owner then owner.Functions.AddMoney('bank', net, 'srp-stall-sale')
    else MySQL.query('UPDATE players SET bank = bank + ? WHERE citizenid = ?', { net, s.owner }) end
    s.earnings = s.earnings + net
    listing.qty = listing.qty - qty
    if listing.qty <= 0 then s.listings[item] = nil end
    persistStall(stallId)
    TriggerClientEvent('QBCore:Notify', src, ('اشتريت %s × %s بـ $%s'):format(item, qty, cost), 'success')
end)

RegisterNetEvent('srp:stalls:createOrder', function(stallId, item, qty, reward)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local s = Stalls_[stallId]
    if not s or s.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, St.Messages.notOwner, 'error') return
    end
    qty = tonumber(qty) or 0
    reward = tonumber(reward) or 0
    if qty < St.Settings.minOrderQty or qty > St.Settings.maxOrderQty then
        TriggerClientEvent('QBCore:Notify', src, ('الكمية بين %s و %s'):format(St.Settings.minOrderQty, St.Settings.maxOrderQty), 'error') return
    end
    if reward <= 0 then return end
    local expires = os.time() + (St.Settings.orderExpireHours * 3600)
    MySQL.insert([[INSERT INTO srp_stall_orders (stall_id, owner, item, qty, reward, expires_at)
        VALUES (?, ?, ?, ?, ?, ?)]], { stallId, s.owner, item, qty, reward, expires }, function(id)
        Orders[id] = { id = id, stall_id = stallId, owner = s.owner, item = item, qty = qty, reward = reward, expires_at = expires, status = 'open' }
        TriggerClientEvent('QBCore:Notify', src, ('طُلب توريد: %s × %s (مكافأة $%s)'):format(item, qty, reward), 'success')
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', pid, ('طلب توريد متاح: %s × %s — $%s | اكتب /orders'):format(item, qty, reward), 'inform')
        end
    end)
end)

RegisterNetEvent('srp:stalls:fillOrder', function(orderId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local o = Orders[orderId]
    if not o or o.status ~= 'open' then
        TriggerClientEvent('QBCore:Notify', src, 'الطلب غير متاح.', 'error') return
    end
    if o.expires_at < os.time() then
        o.status = 'expired'
        MySQL.query('UPDATE srp_stall_orders SET status = "expired" WHERE id = ?', { orderId })
        TriggerClientEvent('QBCore:Notify', src, St.Messages.orderExpired, 'error') return
    end
    if getQty(Player, o.item) < o.qty then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك الكمية المطلوبة.', 'error') return
    end
    takeItem(Player, o.item, o.qty)
    Player.Functions.AddMoney('bank', o.reward, 'srp-stall-order')
    o.status = 'filled'
    MySQL.query('UPDATE srp_stall_orders SET status = "filled" WHERE id = ?', { orderId })
    local s = Stalls_[o.stall_id]
    if s then
        s.listings[o.item] = s.listings[o.item] or { qty = 0, price = 0 }
        s.listings[o.item].qty = s.listings[o.item].qty + o.qty
        persistStall(o.stall_id)
    end
    TriggerClientEvent('QBCore:Notify', src, ('وفّرت الطلب: %s × %s — ربحت $%s'):format(o.item, o.qty, o.reward), 'success')
    local owner = getByCid(o.owner)
    if owner then TriggerClientEvent('QBCore:Notify', owner.PlayerData.source, ('وصل طلب التوريد: %s × %s'):format(o.item, o.qty), 'success') end
end)

RegisterNetEvent('srp:stalls:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local nearby = {}
    local mine = {}
    for id, s in pairs(Stalls_) do
        local rec = { id = id, owner = s.owner, type = s.type, x = s.x, y = s.y, z = s.z, listings = s.listings, open = s.open, mine = s.owner == Player.PlayerData.citizenid }
        if s.owner == Player.PlayerData.citizenid then mine[#mine+1] = rec else nearby[#nearby+1] = rec end
    end
    TriggerClientEvent('srp:stalls:show', src, { nearby = nearby, mine = mine, types = St.Types })
end)

RegisterNetEvent('srp:stalls:requestOrders', function()
    local src = source
    local list = {}
    for _, o in pairs(Orders) do
        if o.status == 'open' and o.expires_at > os.time() then list[#list+1] = o end
    end
    TriggerClientEvent('srp:stalls:showOrders', src, list)
end)

CreateThread(function()
    ensureSchema()
    Wait(4500)
    loadAll()
    while true do
        Wait(30 * 60 * 1000)
        for id, o in pairs(Orders) do
            if o.status == 'open' and o.expires_at < os.time() then
                o.status = 'expired'
                MySQL.query('UPDATE srp_stall_orders SET status = "expired" WHERE id = ?', { id })
            end
        end
    end
end)

CreateThread(function() log('تم تحميل نظام الأكشاك.') end)
