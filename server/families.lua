--[[
    fivem-strict-rp :: server/families.lua
    نظام العوائل — إنشاء · أعضاء · رتب · خزنة · شات · حروب · مناطق.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local F = Families

local Families_   = {}
local PlayerFam   = {}
local PendingInvite = {}
local WarCooldown = {}
local ZoneOwner   = {}

local function log(msg) print(('[fivem-strict-rp][families] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_families` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `name` VARCHAR(48) NOT NULL,
        `tag` VARCHAR(8) NOT NULL, `leader` VARCHAR(50) NOT NULL,
        `treasury` BIGINT NOT NULL DEFAULT 0, `color` INT NOT NULL DEFAULT 3,
        `tier` INT NOT NULL DEFAULT 1, `allies` TEXT DEFAULT NULL, `hostiles` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_leader` (`leader`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_family_members` (
        `family_id` INT NOT NULL, `citizenid` VARCHAR(50) NOT NULL,
        `rank` INT NOT NULL DEFAULT 0, `joined` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`family_id`, `citizenid`), INDEX `idx_cid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_family_zones` (
        `zone_key` VARCHAR(24) NOT NULL PRIMARY KEY, `family_id` INT NOT NULL,
        `captured` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadAll(cb)
    MySQL.query('SELECT * FROM srp_families', {}, function(rows)
        Families_ = {}
        if not rows or #rows == 0 then if cb then cb() end return end
        local pending = #rows
        for _, r in ipairs(rows) do
            Families_[r.id] = {
                id = r.id, name = r.name, tag = r.tag, leader = r.leader,
                members = {}, treasury = r.treasury, color = r.color, tier = r.tier,
                allies = json.decode(r.allies or '[]') or {},
                hostiles = json.decode(r.hostiles or '[]') or {}, zones = {},
            }
            MySQL.query('SELECT citizenid, rank FROM srp_family_members WHERE family_id = ?', { r.id }, function(mrows)
                for _, m in ipairs(mrows or {}) do
                    Families_[r.id].members[m.citizenid] = m.rank
                    PlayerFam[m.citizenid] = r.id
                end
                pending = pending - 1
                if pending <= 0 and cb then cb() end
            end)
        end
    end)
    MySQL.query('SELECT * FROM srp_family_zones', {}, function(zrows)
        for _, z in ipairs(zrows or {}) do ZoneOwner[z.zone_key] = z.family_id end
    end)
end

local function persistFamily(famId)
    local f = Families_[famId]
    if not f then return end
    MySQL.query('UPDATE srp_families SET treasury = ?, allies = ?, hostiles = ?, tier = ? WHERE id = ?',
        { f.treasury, json.encode(f.allies), json.encode(f.hostiles), f.tier, famId })
end

local function isLeader(famId, cid)
    local f = Families_[famId]
    return f and (f.leader == cid or (f.members[cid] or 0) >= 3)
end

local function memberCount(famId)
    local n = 0
    for _ in pairs(Families_[famId] and Families_[famId].members or {}) do n = n + 1 end
    return n
end

RegisterNetEvent('srp:families:create', function(name, tag)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if PlayerFam[cid] then
        TriggerClientEvent('QBCore:Notify', src, F.Messages.alreadyIn, 'error') return
    end
    if not name or #name < 3 or #name > 32 then
        TriggerClientEvent('QBCore:Notify', src, 'اسم العائلة يجب أن يكون بين 3 و 32 حرفاً.', 'error') return
    end
    if Player.Functions.GetMoney('bank') < F.Settings.createFee then
        TriggerClientEvent('QBCore:Notify', src, F.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', F.Settings.createFee, 'srp-family-create')
    MySQL.insert('INSERT INTO srp_families (name, tag, leader, color) VALUES (?, ?, ?, ?)',
        { name, tag or name:sub(1, 4), cid, F.Defaults.color }, function(id)
        Families_[id] = { id = id, name = name, tag = tag or name:sub(1, 4), leader = cid,
            members = { [cid] = 3 }, treasury = 0, color = F.Defaults.color, tier = 1,
            allies = {}, hostiles = {}, zones = {} }
        PlayerFam[cid] = id
        MySQL.query('INSERT INTO srp_family_members (family_id, citizenid, rank) VALUES (?, ?, 3)', { id, cid })
        TriggerClientEvent('QBCore:Notify', src, ('تأسست عائلتك: %s'):format(name), 'success')
        TriggerClientEvent('srp:families:refresh', src)
    end)
end)

RegisterNetEvent('srp:families:invite', function(targetSrc)
    local src = source
    local Player = getPlayer(src)
    local Target = getPlayer(tonumber(targetSrc))
    if not Player or not Target then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId then TriggerClientEvent('QBCore:Notify', src, F.Messages.notInFamily, 'error') return end
    if not isLeader(famId, cid) then TriggerClientEvent('QBCore:Notify', src, F.Messages.notLeader, 'error') return end
    if memberCount(famId) >= F.Settings.maxMembers then TriggerClientEvent('QBCore:Notify', src, F.Messages.full, 'error') return end
    local tcid = Target.PlayerData.citizenid
    if PlayerFam[tcid] then TriggerClientEvent('QBCore:Notify', src, 'اللاعب في عائلة بالفعل.', 'error') return end
    PendingInvite[tcid] = famId
    TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('دعوة للانضمام إلى %s — اكتب /familyaccept'):format(Families_[famId].name), 'inform')
end)

RegisterNetEvent('srp:families:accept', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PendingInvite[cid]
    if not famId or not Families_[famId] then TriggerClientEvent('QBCore:Notify', src, 'لا توجد دعوة.', 'error') return end
    if memberCount(famId) >= F.Settings.maxMembers then TriggerClientEvent('QBCore:Notify', src, F.Messages.full, 'error') return end
    Families_[famId].members[cid] = 0
    PlayerFam[cid] = famId
    PendingInvite[cid] = nil
    MySQL.query('INSERT INTO srp_family_members (family_id, citizenid, rank) VALUES (?, ?, 0)', { famId, cid })
    TriggerClientEvent('QBCore:Notify', src, ('انضممت إلى %s.'):format(Families_[famId].name), 'success')
end)

RegisterNetEvent('srp:families:leave', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId then return end
    local f = Families_[famId]
    if f.leader == cid and memberCount(famId) > 1 then
        TriggerClientEvent('QBCore:Notify', src, 'سلّم القيادة أولاً.', 'error') return
    end
    f.members[cid] = nil
    PlayerFam[cid] = nil
    MySQL.query('DELETE FROM srp_family_members WHERE family_id = ? AND citizenid = ?', { famId, cid })
    TriggerClientEvent('QBCore:Notify', src, F.Messages.left, 'success')
end)

RegisterNetEvent('srp:families:deposit', function(amount)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    amount = tonumber(amount) or 0
    local famId = PlayerFam[Player.PlayerData.citizenid]
    if not famId or amount <= 0 then return end
    if Player.Functions.GetMoney('bank') < amount then TriggerClientEvent('QBCore:Notify', src, F.Messages.noMoney, 'error') return end
    Player.Functions.RemoveMoney('bank', amount, 'srp-family-deposit')
    local f = Families_[famId]
    f.treasury = math.min(F.Settings.maxTreasury, f.treasury + amount)
    persistFamily(famId)
    TriggerClientEvent('QBCore:Notify', src, ('أُضيف $%s لخزنة العائلة (المجموع: $%s).'):format(amount, f.treasury), 'success')
end)

RegisterNetEvent('srp:families:withdraw', function(amount)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    amount = tonumber(amount) or 0
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId or amount <= 0 then return end
    if not isLeader(famId, cid) then TriggerClientEvent('QBCore:Notify', src, F.Messages.roleRequired, 'error') return end
    local f = Families_[famId]
    if f.treasury < amount then TriggerClientEvent('QBCore:Notify', src, 'الخزنة لا تكفي.', 'error') return end
    f.treasury = f.treasury - amount
    Player.Functions.AddMoney('bank', amount, 'srp-family-withdraw')
    persistFamily(famId)
    TriggerClientEvent('QBCore:Notify', src, ('سُحب $%s من الخزنة.'):format(amount), 'success')
end)

RegisterNetEvent('srp:families:setRank', function(targetCid, rank)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId or not isLeader(famId, cid) then TriggerClientEvent('QBCore:Notify', src, F.Messages.notLeader, 'error') return end
    rank = tonumber(rank) or 0
    if not Families_[famId].members[targetCid] then return end
    if rank < 0 or rank > #F.Settings.ranks - 1 then return end
    Families_[famId].members[targetCid] = rank
    MySQL.query('UPDATE srp_family_members SET rank = ? WHERE family_id = ? AND citizenid = ?', { rank, famId, targetCid })
    local TP = QBCore.Functions.GetPlayerByCitizenId(targetCid)
    if TP then TriggerClientEvent('QBCore:Notify', TP.PlayerData.source, ('رتبتك الآن: %s'):format(F.Settings.ranks[rank + 1]), 'success') end
end)

RegisterNetEvent('srp:families:declareWar', function(targetFamId)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId or not isLeader(famId, cid) then TriggerClientEvent('QBCore:Notify', src, F.Messages.notLeader, 'error') return end
    if memberCount(famId) < F.Settings.minMembersToWar then
        TriggerClientEvent('QBCore:Notify', src, ('تحتاج %s أعضاء لشن حرب.'):format(F.Settings.minMembersToWar), 'error') return
    end
    local lastWar = WarCooldown[famId] or 0
    if os.time() - lastWar < F.Settings.warCooldownMin * 60 then
        TriggerClientEvent('QBCore:Notify', src, 'العائلة في فترة راحة من الحرب.', 'error') return
    end
    local target = Families_[targetFamId]
    if not target then return end
    table.insert(Families_[famId].hostiles, targetFamId)
    table.insert(target.hostiles, famId)
    WarCooldown[famId] = os.time()
    persistFamily(famId); persistFamily(targetFamId)
    for mcid in pairs(Families_[famId].members) do
        local P = QBCore.Functions.GetPlayerByCitizenId(mcid)
        if P then TriggerClientEvent('QBCore:Notify', P.PlayerData.source, ('أعلنتم الحرب على %s!'):format(target.name), 'error') end
    end
    for mcid in pairs(target.members) do
        local P = QBCore.Functions.GetPlayerByCitizenId(mcid)
        if P then TriggerClientEvent('QBCore:Notify', P.PlayerData.source, ('%s أعلنت الحرب عليكم!'):format(Families_[famId].name), 'error') end
    end
end)

RegisterNetEvent('srp:families:captureZone', function(zoneKey)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId then return end
    local fam = Families_[famId]
    local owner = ZoneOwner[zoneKey]
    local stolen = 0
    if owner and owner ~= famId then
        local ownerFam = Families_[owner]
        if ownerFam then
            stolen = math.floor(ownerFam.treasury * F.Settings.treasuryStealPercent / 100)
            ownerFam.treasury = ownerFam.treasury - stolen
            fam.treasury = math.min(F.Settings.maxTreasury, fam.treasury + stolen)
            persistFamily(owner); persistFamily(famId)
        end
    end
    ZoneOwner[zoneKey] = famId
    MySQL.query([[INSERT INTO srp_family_zones (zone_key, family_id) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE family_id = VALUES(family_id)]], { zoneKey, famId })
    local zoneLabel = zoneKey
    for _, z in ipairs(F.Zones) do if z.key == zoneKey then zoneLabel = z.label end end
    TriggerClientEvent('QBCore:Notify', src, ('سيطرت %s على %s%s'):format(fam.name, zoneLabel, stolen > 0 and (' وسرقت $' .. stolen) or ''), 'success')
end)

RegisterNetEvent('srp:families:chat', function(message)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId then return end
    local fam = Families_[famId]
    for mcid in pairs(fam.members) do
        local P = QBCore.Functions.GetPlayerByCitizenId(mcid)
        if P then
            TriggerClientEvent('chat:addMessage', P.PlayerData.source, {
                args = { ('[%s]'):format(fam.tag), message }, color = { fam.color * 40, 200, 200 },
            })
        end
    end
end)

RegisterNetEvent('srp:families:request', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local famId = PlayerFam[cid]
    if not famId then TriggerClientEvent('srp:families:none', src) return end
    local fam = Families_[famId]
    local memberList = {}
    for mcid, rank in pairs(fam.members) do
        local P = QBCore.Functions.GetPlayerByCitizenId(mcid)
        memberList[#memberList+1] = {
            cid = mcid,
            name = P and (P.PlayerData.charinfo.firstname .. ' ' .. P.PlayerData.charinfo.lastname) or mcid:sub(1, 8),
            rank = rank, rankName = F.Settings.ranks[rank + 1], online = P ~= nil,
        }
    end
    TriggerClientEvent('srp:families:show', src, {
        id = famId, name = fam.name, tag = fam.tag, treasury = fam.treasury,
        members = memberList, rank = fam.members[cid], isLeader = isLeader(famId, cid), zones = ZoneOwner,
    })
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function() loadAll() end)

CreateThread(function()
    ensureSchema()
    Wait(3000)
    loadAll()
    log('تم تحميل نظام العوائل.')
end)
