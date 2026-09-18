--[[
    fivem-strict-rp :: server/land.lua
    منطق الأراضي: الملكية · التخصيص الإداري · البناء · البيع.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local L = Land

local Lands      = {}
local PlayerLand = {}

local function log(msg) print(('[fivem-strict-rp][land] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end
local function getPlayerByCid(cid) return QBCore.Functions.GetPlayerByCitizenId(cid) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_lands` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `owner` VARCHAR(50) NOT NULL,
        `x` DOUBLE NOT NULL, `y` DOUBLE NOT NULL, `z` DOUBLE NOT NULL,
        `radius` DOUBLE NOT NULL DEFAULT 20, `type` VARCHAR(24) NOT NULL DEFAULT 'residential',
        `shape` VARCHAR(16) NOT NULL DEFAULT 'circle', `structures` TEXT DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_owner` (`owner`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadLands()
    MySQL.query('SELECT * FROM srp_lands', {}, function(rows)
        Lands = {}
        for _, r in ipairs(rows or {}) do
            Lands[r.id] = {
                owner = r.owner, x = r.x, y = r.y, z = r.z,
                radius = r.radius, type = r.type, shape = r.shape,
                structures = json.decode(r.structures or '[]') or {},
            }
            PlayerLand[r.owner] = r.id
        end
        log(('حُمّلت %s أرض.'):format(#rows or 0))
    end)
end

local function persistStructures(landId)
    local land = Lands[landId]
    if not land then return end
    MySQL.query('UPDATE srp_lands SET structures = ? WHERE id = ?', { json.encode(land.structures), landId })
end

local function countOwned(cid)
    local n = 0
    for _, l in pairs(Lands) do if l.owner == cid then n = n + 1 end end
    return n
end

RegisterNetEvent('srp:land:grant', function(targetSrc, halfRadius, landType)
    local adminSrc = source
    local Admin = getPlayer(adminSrc)
    local Target = getPlayer(tonumber(targetSrc))
    if not Admin or not Target then return end
    if not QBCore.Functions.HasPermission(adminSrc, 'admin') then
        TriggerClientEvent('QBCore:Notify', adminSrc, 'صلاحية غير كافية.', 'error') return
    end
    local radius = tonumber(halfRadius) or 20
    if radius < L.Settings.minRadius or radius > L.Settings.maxRadius then
        TriggerClientEvent('QBCore:Notify', adminSrc, ('نصف القطر يجب أن يكون بين %s و %s.'):format(L.Settings.minRadius, L.Settings.maxRadius), 'error') return
    end
    landType = landType or 'residential'
    if not L.Types[landType] then
        TriggerClientEvent('QBCore:Notify', adminSrc, 'نوع أرض غير معروف.', 'error') return
    end
    local cid = Target.PlayerData.citizenid
    if countOwned(cid) >= L.Settings.maxOwnedPerPlayer then
        TriggerClientEvent('QBCore:Notify', adminSrc, 'اللاعب وصل للحد الأقصى من الأراضي.', 'error') return
    end
    local coords = GetEntityCoords(GetPlayerPed(tonumber(targetSrc)))
    MySQL.insert([[INSERT INTO srp_lands (owner, x, y, z, radius, type, shape, structures)
        VALUES (?, ?, ?, ?, ?, ?, ?, '[]')]],
        { cid, coords.x, coords.y, coords.z, radius, landType, L.Settings.defaultShape }, function(id)
        Lands[id] = { owner = cid, x = coords.x, y = coords.y, z = coords.z, radius = radius, type = landType, shape = L.Settings.defaultShape, structures = {} }
        PlayerLand[cid] = id
        TriggerClientEvent('QBCore:Notify', adminSrc, ('مُنحت الأرض للاعب (نصف القطر: %s م).'):format(radius), 'success')
        TriggerClientEvent('QBCore:Notify', tonumber(targetSrc), ('حصلت على أرض جديدة! نصف القطر %s م — استخدم /myland'):format(radius), 'success')
        TriggerClientEvent('srp:land:updateMine', tonumber(targetSrc), Lands[id], id)
    end)
end)

RegisterNetEvent('srp:land:revoke', function(landId)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    local land = Lands[landId]
    if not land then return end
    local owner = getPlayerByCid(land.owner)
    if owner then
        TriggerClientEvent('QBCore:Notify', owner.PlayerData.source, 'تم سحب أرضك.', 'error')
        TriggerClientEvent('srp:land:clearMine', owner.PlayerData.source)
    end
    MySQL.query('DELETE FROM srp_lands WHERE id = ?', { landId })
    Lands[landId] = nil
    PlayerLand[land.owner] = nil
    TriggerClientEvent('QBCore:Notify', src, 'تم سحب الأرض.', 'success')
end)

RegisterNetEvent('srp:land:build', function(structKey, bx, by, bz, rot)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local landId = PlayerLand[cid]
    local land = landId and Lands[landId]
    if not land or land.owner ~= cid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    local struct = L.Structures[structKey]
    if not struct then
        TriggerClientEvent('QBCore:Notify', src, 'منشأة غير معروفة.', 'error') return
    end
    local typeDef = L.Types[land.type]
    local allowed = false
    for _, k in ipairs(typeDef.buildAllow) do if k == structKey then allowed = true break end end
    if not allowed then
        TriggerClientEvent('QBCore:Notify', src, ('لا يمكن بناء %s في أرض %s.'):format(struct.label, typeDef.label), 'error') return
    end
    local dist = #(vector2(bx, by) - vector2(land.x, land.y))
    if dist > land.radius then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.outside, 'error') return
    end
    local count = 0
    for _, s in ipairs(land.structures) do if s.key == structKey then count = count + 1 end end
    if count >= struct.maxPerPlot then
        TriggerClientEvent('QBCore:Notify', src, ('وصلت للحد الأقصى من %s.'):format(struct.label), 'error') return
    end
    if Player.Functions.GetMoney('bank') < struct.cost then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.noMoney, 'error') return
    end
    Player.Functions.RemoveMoney('bank', struct.cost, 'srp-land-build')
    local entry = { key = structKey, x = bx, y = by, z = bz, rot = rot or 0.0 }
    land.structures[#land.structures + 1] = entry
    persistStructures(landId)
    TriggerClientEvent('QBCore:Notify', src, ('تم بناء %s ($%s).'):format(struct.label, struct.cost), 'success')
    TriggerClientEvent('srp:land:spawnStructure', src, entry, struct.model)
    if struct.farming then TriggerEvent('srp:farm:registerOwnership', src, landId) end
end)

RegisterNetEvent('srp:land:sell', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local landId = PlayerLand[cid]
    local land = landId and Lands[landId]
    if not land or land.owner ~= cid then
        TriggerClientEvent('QBCore:Notify', src, L.Messages.notOwner, 'error') return
    end
    local area = math.pi * land.radius * land.radius
    local value = math.floor(area * L.Settings.pricePerSqm * L.Settings.sellRefundPercent / 100)
    Player.Functions.AddMoney('bank', value, 'srp-land-sell')
    MySQL.query('DELETE FROM srp_lands WHERE id = ?', { landId })
    Lands[landId] = nil
    PlayerLand[cid] = nil
    TriggerClientEvent('srp:land:clearMine', src)
    TriggerClientEvent('QBCore:Notify', src, ('بعت أرضك بـ $%s.'):format(value), 'success')
end)

RegisterNetEvent('srp:land:requestMine', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    local landId = PlayerLand[cid]
    if not landId or not Lands[landId] then
        TriggerClientEvent('QBCore:Notify', src, 'لا تملك أرضاً. تواصل مع الإدارة.', 'inform') return
    end
    TriggerClientEvent('srp:land:updateMine', src, Lands[landId], landId)
end)

RegisterNetEvent('srp:land:requestAll', function()
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    local list = {}
    for id, l in pairs(Lands) do
        list[#list+1] = { id = id, owner = l.owner, type = l.type, radius = l.radius }
    end
    TriggerClientEvent('srp:land:showAll', src, list)
end)

QBCore.Commands.Add('giveplot', 'منح أرض للاعب', {
    { name = 'id', help = 'ID اللاعب' },
    { name = 'radius', help = 'نصف القطر (م)' },
    { name = 'type', help = 'النوع (اختياري)' },
}, false, function(source, args)
    TriggerEvent('srp:land:grant', source, args[1], args[2], args[3])
end, 'admin')

QBCore.Commands.Add('delplot', 'سحب أرض', { { name = 'landId' } }, false, function(source, args)
    TriggerEvent('srp:land:revoke', source, tonumber(args[1]))
end, 'admin')

QBCore.Commands.Add('listplots', 'عرض كل الأراضي', {}, false, function(source)
    TriggerEvent('srp:land:requestAll', source)
end, 'admin')

CreateThread(function()
    ensureSchema()
    Wait(3000)
    loadLands()
    log('تم تحميل نظام الأراضي.')
end)
