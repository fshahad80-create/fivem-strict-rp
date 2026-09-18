--[[
    fivem-strict-rp :: server/land_admin.lua
    أدوات الستاف للأراضي: تفاصيل · إحصائيات · سجل.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local L = Land

local function log(msg) print(('[fivem-strict-rp][land-admin] %s'):format(msg)) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_land_admin_log` (
        `id` INT AUTO_INCREMENT PRIMARY KEY, `staff` VARCHAR(50) NOT NULL,
        `action` VARCHAR(24) NOT NULL, `target` VARCHAR(50) DEFAULT NULL,
        `land_id` INT DEFAULT NULL, `detail` VARCHAR(255) DEFAULT NULL,
        `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, INDEX `idx_staff` (`staff`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function writeLog(staffCid, action, targetCid, landId, detail)
    MySQL.insert([[INSERT INTO srp_land_admin_log (staff, action, target, land_id, detail)
        VALUES (?, ?, ?, ?, ?)]], { staffCid, action, targetCid, landId, detail })
end

QBCore.Commands.Add('plotinfo', 'تفاصيل أرض', { { name = 'landId' } }, false, function(source, args)
    local landId = tonumber(args[1])
    if not landId then return end
    MySQL.query('SELECT * FROM srp_lands WHERE id = ?', { landId }, function(rows)
        local r = rows and rows[1]
        if not r then
            TriggerClientEvent('QBCore:Notify', source, 'أرض غير موجودة.', 'error') return
        end
        local structCount = 0
        local ok, list = pcall(json.decode, r.structures or '[]')
        if ok and type(list) == 'table' then structCount = #list end
        TriggerClientEvent('QBCore:Notify', source,
            ('أرض #%s — %s | مالك: %s | نصف القطر: %s | منشآت: %s'):format(r.id, r.type, r.owner, r.radius, structCount), 'primary')
    end)
end, 'admin')

QBCore.Commands.Add('landstats', 'إحصائيات الأراضي', {}, false, function(source)
    MySQL.query('SELECT type, COUNT(*) AS c, SUM(radius) AS totalRadius FROM srp_lands GROUP BY type', {}, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('QBCore:Notify', source, 'لا توجد أراضٍ مُوزّعة.', 'inform') return
        end
        for _, r in ipairs(rows) do
            TriggerClientEvent('QBCore:Notify', source,
                ('%s: %s أرض (مجموع نصف الأقطار %s)'):format(L.Types[r.type] and L.Types[r.type].label or r.type, r.c, r.totalRadius or 0), 'primary')
        end
    end)
end, 'admin')

RegisterNetEvent('srp:land:adminLog', function(action, targetCid, landId, detail)
    local src = source
    local staff = QBCore.Functions.GetPlayer(src)
    if not staff then return end
    writeLog(staff.PlayerData.citizenid, action, targetCid, landId, detail)
end)

CreateThread(function()
    ensureSchema()
    log('تم تحميل أدوات إدارة الأراضي.')
end)
