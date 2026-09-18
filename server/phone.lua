--[[
    fivem-strict-rp :: server/phone.lua
    تطبيقات الجوال — أبشر · ناجز · مدى · مزادي · أطلبني.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local P = Phone

local Wallets   = {}
local Auctions  = {}
local Orders    = {}
local function log(msg) print(('[fivem-strict-rp][phone] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function getByCid(cid) return QBCore.Functions.GetPlayerByCitizenId(cid) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_phone_docs` (
        `citizenid` VARCHAR(50) NOT NULL, `type` VARCHAR(24) NOT NULL,
        `issued` INT NOT NULL, `expires` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`citizenid`, `type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_phone_meda` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `owner` VARCHAR(50) NOT NULL,
        `name` VARCHAR(64) NOT NULL, `linked_to` VARCHAR(64) DEFAULT NULL,
        `balance` BIGINT NOT NULL DEFAULT 0,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_phone_auctions` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `owner` VARCHAR(50) NOT NULL,
        `title` VARCHAR(128) NOT NULL, `category` VARCHAR(24) NOT NULL,
        `start_price` BIGINT NOT NULL, `high_bid` BIGINT NOT NULL DEFAULT 0,
        `high_bidder` VARCHAR(50) DEFAULT NULL, `ends_at` INT NOT NULL,
        `status` VARCHAR(12) NOT NULL DEFAULT 'active',
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_phone_orders` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `owner` VARCHAR(50) NOT NULL,
        `owner_name` VARCHAR(64) NOT NULL, `category` VARCHAR(24) NOT NULL,
        `title` VARCHAR(128) NOT NULL, `qty` INT NOT NULL, `budget` BIGINT NOT NULL,
        `status` VARCHAR(12) NOT NULL DEFAULT 'open', `offers` LONGTEXT DEFAULT NULL,
        `expires_at` INT NOT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadAll()
    MySQL.query('SELECT * FROM srp_phone_meda', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            Wallets[r.owner] = Wallets[r.owner] or { terminals = {} }
            table.insert(Wallets[r.owner].terminals, { id = r.id, name = r.name, linkedTo = r.linked_to, balance = r.balance })
        end
    end)
    MySQL.query('SELECT * FROM srp_phone_auctions WHERE status = "active"', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            Auctions[r.id] = { id = r.id, owner = r.owner, title = r.title, category = r.category, startPrice = r.start_price, highBid = r.high_bid, highBidder = r.high_bidder, endsAt = r.ends_at, status = r.status }
        end
    end)
    MySQL.query('SELECT * FROM srp_phone_orders WHERE status = "open"', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            Orders[r.id] = { id = r.id, owner = r.owner, ownerName = r.owner_name, category = r.category, title = r.title, qty = r.qty, budget = r.budget, status = r.status, offers = json.decode(r.offers or '[]') or [], expiresAt = r.expires_at }
        end
    end)
end

RegisterNetEvent('srp:phone:open', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    TriggerClientEvent('srp:phone:show', src, {
        apps = P.Apps, docs = P.DocumentTypes, medaServices = P.MedaServices,
        categories = P.AuctionCategories, atlobniCats = P.AtlobniSettings.categories,
        cash = Player.Functions.GetMoney('cash'), bank = Player.Functions.GetMoney('bank'),
        charinfo = Player.PlayerData.charinfo,
    })
end)

-- أبشر
RegisterNetEvent('srp:phone:absherDocs', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_phone_docs WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(rows)
        TriggerClientEvent('srp:phone:showDocs', src, rows or {}, P.DocumentTypes)
    end)
end)

RegisterNetEvent('srp:phone:issueDoc', function(docType)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local dt = P.DocumentTypes[docType]
    if not dt then return end
    MySQL.query([[INSERT INTO srp_phone_docs (citizenid, type, issued, expires) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE issued = VALUES(issued), expires = VALUES(expires)]],
        { Player.PlayerData.citizenid, docType, os.time(), os.time() + (365 * 86400) })
    TriggerClientEvent('QBCore:Notify', src, ('صدرت وثيقة: %s'):format(dt.label), 'success')
end)

RegisterNetEvent('srp:phone:absherFines', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_traffic_fines WHERE citizenid = ? ORDER BY created DESC LIMIT 30', { Player.PlayerData.citizenid }, function(rows)
        TriggerClientEvent('srp:phone:showFines', src, rows or {})
    end)
end)

RegisterNetEvent('srp:phone:disputeFine', function(fineId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('UPDATE srp_traffic_fines SET dispute = 1 WHERE id = ? AND citizenid = ?', { fineId, Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', src, ('رُفع اعتراض على مخالفة #%s'):format(fineId), 'success')
end)

RegisterNetEvent('srp:phone:locateVehicle', function(plate)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', { plate, Player.PlayerData.citizenid }, function(rows)
        local r = rows and rows[1]
        if not r then
            TriggerClientEvent('QBCore:Notify', src, 'لم تُعثر على المركبة في سجلاتك.', 'error') return
        end
        TriggerClientEvent('srp:phone:vehicleBlip', src, plate)
        TriggerClientEvent('QBCore:Notify', src, '📍 حُدد موقع مركبتك على الخريطة', 'success')
    end)
end)

-- ناجز
RegisterNetEvent('srp:phone:najizData', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    MySQL.query('SELECT * FROM srp_contracts WHERE party1 = ? OR party2 = ? ORDER BY created DESC LIMIT 20', { cid, cid }, function(crows)
        MySQL.query('SELECT * FROM srp_cases WHERE plaintiff = ? OR defendant = ? ORDER BY created DESC LIMIT 20', { cid, cid }, function(krows)
            TriggerClientEvent('srp:phone:showNajiz', src, crows or {}, krows or {})
        end)
    end)
end)

-- مدى
RegisterNetEvent('srp:phone:createTerminal', function(name)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cost = P.MedaServices.createTerminal.cost
    if Player.Functions.GetMoney('bank') < cost then
        TriggerClientEvent('QBCore:Notify', src, P.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', cost, 'srp-meda-terminal')
    MySQL.insert('INSERT INTO srp_phone_meda (owner, name) VALUES (?, ?)', { Player.PlayerData.citizenid, name or 'جهاز دفع' }, function(id)
        Wallets[Player.PlayerData.citizenid] = Wallets[Player.PlayerData.citizenid] or { terminals = {} }
        table.insert(Wallets[Player.PlayerData.citizenid].terminals, { id = id, name = name or 'جهاز دفع', linkedTo = nil, balance = 0 })
        TriggerClientEvent('QBCore:Notify', src, '💳 رُكّب جهاز الدفع', 'success')
    end)
end)

RegisterNetEvent('srp:phone:linkTerminal', function(terminalId, businessName)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('UPDATE srp_phone_meda SET linked_to = ? WHERE id = ? AND owner = ?', { businessName, terminalId, Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', src, ('💳 ارتبط الجهاز بـ %s'):format(businessName), 'success')
end)

RegisterNetEvent('srp:phone:medaData', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_phone_meda WHERE owner = ?', { Player.PlayerData.citizenid }, function(rows)
        TriggerClientEvent('srp:phone:showMeda', src, rows or {})
    end)
end)

-- مزادي
RegisterNetEvent('srp:phone:createAuction', function(title, category, startPrice)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    startPrice = tonumber(startPrice) or 0
    if startPrice <= 0 then return end
    local endsAt = os.time() + (P.Settings.defaultAuctionMin * 60)
    MySQL.insert([[INSERT INTO srp_phone_auctions (owner, title, category, start_price, ends_at)
        VALUES (?, ?, ?, ?, ?)]], { Player.PlayerData.citizenid, title or 'مزاد', category or 'items', startPrice, endsAt }, function(id)
        Auctions[id] = { id = id, owner = Player.PlayerData.citizenid, title = title, category = category, startPrice = startPrice, highBid = 0, highBidder = nil, endsAt = endsAt, status = 'active' }
        TriggerClientEvent('QBCore:Notify', src, ('🔨 أُنشئ مزاد: %s'):format(title), 'success')
    end)
end)

RegisterNetEvent('srp:phone:bidAuction', function(auctionId, amount)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local a = Auctions[auctionId]
    if not a or a.status ~= 'active' then
        TriggerClientEvent('QBCore:Notify', src, 'المزاد مغلق.', 'error') return
    end
    if a.endsAt < os.time() then a.status = 'ended'; return end
    amount = tonumber(amount) or 0
    local minBid = math.max(a.startPrice, a.highBid + 1)
    if amount < minBid then
        TriggerClientEvent('QBCore:Notify', src, ('الحد الأدنى للمزايدة: $%s'):format(minBid), 'error') return
    end
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, P.Messages.noMoney, 'error') return
    end
    if a.highBidder then
        local prev = getByCid(a.highBidder)
        if prev then prev.Functions.AddMoney('bank', a.highBid, 'srp-auction-refund') end
    end
    Player.Functions.RemoveMoney('bank', amount, 'srp-auction-bid')
    a.highBid = amount
    a.highBidder = Player.PlayerData.citizenid
    a.endsAt = a.endsAt + 120
    MySQL.query('UPDATE srp_phone_auctions SET high_bid = ?, high_bidder = ?, ends_at = ? WHERE id = ?', { amount, a.highBidder, a.endsAt, auctionId })
    TriggerClientEvent('QBCore:Notify', src, ('💰 عرض $%s على %s'):format(amount, a.title), 'success')
end)

RegisterNetEvent('srp:phone:auctionList', function()
    local src = source
    MySQL.query('SELECT * FROM srp_phone_auctions WHERE status = "active" AND ends_at > ? ORDER BY ends_at ASC LIMIT 30', { os.time() }, function(rows)
        TriggerClientEvent('srp:phone:showAuctions', src, rows or {})
    end)
end)

CreateThread(function()
    while true do
        Wait(60 * 1000)
        for id, a in pairs(Auctions) do
            if a.status == 'active' and a.endsAt < os.time() then
                a.status = 'ended'
                MySQL.query('UPDATE srp_phone_auctions SET status = "ended" WHERE id = ?', { id })
                if a.highBidder then
                    local winner = getByCid(a.highBidder)
                    if winner then TriggerClientEvent('QBCore:Notify', winner.PlayerData.source, ('🏆 فزت بالمزاد: %s بـ $%s'):format(a.title, a.highBid), 'success') end
                    local fee = math.floor(a.highBid * P.Settings.auctionFeePercent / 100)
                    local net = a.highBid - fee
                    local owner = getByCid(a.owner)
                    if owner then owner.Functions.AddMoney('bank', net, 'srp-auction-sale')
                    else MySQL.query('UPDATE players SET bank = bank + ? WHERE citizenid = ?', { net, a.owner }) end
                end
            end
        end
    end
end)

-- أطلبني
RegisterNetEvent('srp:phone:createOrder', function(category, title, qty, budget)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    qty = tonumber(qty) or 0
    budget = tonumber(budget) or 0
    if qty <= 0 or budget <= 0 then return end
    local cid = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local expires = os.time() + (P.AtlobniSettings.expireHours * 3600)
    MySQL.insert([[INSERT INTO srp_phone_orders (owner, owner_name, category, title, qty, budget, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)]], { cid, name, category or 'misc', title or 'طلب', qty, budget, expires }, function(id)
        Orders[id] = { id = id, owner = cid, ownerName = name, category = category, title = title, qty = qty, budget = budget, status = 'open', offers = {}, expiresAt = expires }
        TriggerClientEvent('QBCore:Notify', src, ('📢 أُنشئ طلب: %s × %s'):format(title, qty), 'success')
        for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', pid, ('📢 طلب جديد في أطلبني: %s — اكتب /atlebni'):format(title), 'inform')
        end
    end)
end)

RegisterNetEvent('srp:phone:orderList', function()
    local src = source
    MySQL.query('SELECT * FROM srp_phone_orders WHERE status = "open" AND expires_at > ? ORDER BY created DESC LIMIT 30', { os.time() }, function(rows)
        local list = {}
        for _, r in ipairs(rows or {}) do
            list[#list+1] = { id = r.id, title = r.title, qty = r.qty, budget = r.budget, ownerName = r.owner_name, category = r.category, offers = json.decode(r.offers or '[]') or {} }
        end
        TriggerClientEvent('srp:phone:showOrders', src, list)
    end)
end)

RegisterNetEvent('srp:phone:offerOnOrder', function(orderId, price, note)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    price = tonumber(price) or 0
    if price <= 0 then return end
    MySQL.query('SELECT * FROM srp_phone_orders WHERE id = ?', { orderId }, function(rows)
        local r = rows and rows[1]
        if not r or r.status ~= 'open' then return end
        local offers = json.decode(r.offers or '[]') or []
        offers[#offers+1] = { by = Player.PlayerData.citizenid, name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, price = price, note = note or '', at = os.time() }
        MySQL.query('UPDATE srp_phone_orders SET offers = ? WHERE id = ?', { json.encode(offers), orderId })
        TriggerClientEvent('QBCore:Notify', src, ('عرضك أُرسل على الطلب #%s'):format(orderId), 'success')
        local owner = getByCid(r.owner)
        if owner then TriggerClientEvent('QBCore:Notify', owner.PlayerData.source, ('📩 عرض جديد ($%s) على طلبك #%s'):format(price, orderId), 'inform') end
    end)
end)

RegisterNetEvent('srp:phone:acceptOffer', function(orderId, offerIndex)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_phone_orders WHERE id = ?', { orderId }, function(rows)
        local r = rows and rows[1]
        if not r or r.owner ~= Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'هذا ليس طلبك.', 'error') return
        end
        local offers = json.decode(r.offers or '[]') or []
        local offer = offers[offerIndex]
        if not offer then return end
        MySQL.query('UPDATE srp_phone_orders SET status = "closed" WHERE id = ?', { orderId })
        TriggerClientEvent('QBCore:Notify', src, ('✅ قبلت عرض %s ($%s)'):format(offer.name, offer.price), 'success')
        local seller = getByCid(offer.by)
        if seller then TriggerClientEvent('QBCore:Notify', seller.PlayerData.source, ('✅ قُبل عرضك على الطلب #%s'):format(orderId), 'success') end
    end)
end)

CreateThread(function()
    ensureSchema()
    Wait(5000)
    loadAll()
    log('تم تحميل نظام تطبيقات الجوال.')
end)
