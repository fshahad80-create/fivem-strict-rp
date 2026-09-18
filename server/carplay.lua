--[[
    fivem-strict-rp :: server/carplay.lua
    الكار بلاي — جلسات · محطة · صوت · ملاحة · حالة مركبة.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local CP = Carplay

local Sessions = {}
local Players  = {}
local function log(msg) print(('[fivem-strict-rp][carplay] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

RegisterNetEvent('srp:carplay:open', function(plate, vehData)
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    plate = plate or ''
    Sessions[plate] = Sessions[plate] or { station = 1, volume = CP.Settings.volumeDefault, navTarget = nil }
    local sess = Sessions[plate]
    TriggerClientEvent('srp:carplay:show', src, {
        plate = plate, stations = CP.Stations, controls = CP.VehicleControls,
        session = sess, vehData = vehData or {}, dealerExtras = CP.DealerExtras,
    })
end)

RegisterNetEvent('srp:carplay:setStation', function(plate, stationId)
    local src = source
    local sess = Sessions[plate]
    if not sess then return end
    sess.station = stationId
    local station = nil
    for _, s in ipairs(CP.Stations) do if s.id == stationId then station = s end end
    if station then
        TriggerClientEvent('srp:carplay:stationChanged', src, station)
        TriggerClientEvent('QBCore:Notify', src, ('📻 المحطة: %s (%s)'):format(station.label, station.freq), 'success')
    end
end)

RegisterNetEvent('srp:carplay:setVolume', function(plate, volume)
    local src = source
    local sess = Sessions[plate]
    if not sess then return end
    local vol = math.max(0, math.min(CP.Settings.maxVolume, tonumber(volume) or 0))
    sess.volume = vol
    TriggerClientEvent('srp:carplay:volumeChanged', src, vol)
end)

RegisterNetEvent('srp:carplay:setNav', function(plate, x, y, z, label)
    local src = source
    local sess = Sessions[plate]
    if not sess then return end
    sess.navTarget = { x = x, y = y, z = z, label = label or 'الهدف' }
    TriggerClientEvent('srp:carplay:navChanged', src, sess.navTarget)
    TriggerClientEvent('QBCore:Notify', src, ('🗺️ الملاحة إلى: %s'):format(sess.navTarget.label), 'success')
end)

RegisterNetEvent('srp:carplay:setHazards', function(plate, state)
    local src = source
    TriggerClientEvent('srp:carplay:doHazards', src, state)
end)

RegisterNetEvent('srp:carplay:requestStatus', function(plate)
    local src = source
    MySQL.query('SELECT * FROM srp_vehicle_tuning WHERE plate = ?', { plate }, function(rows)
        local r = rows and rows[1]
        TriggerClientEvent('srp:carplay:statusUpdate', src, plate, {
            engine = r and r.engine or 'stock', chip = r and r.chip or 'stock',
            oilType = r and r.oil_type or 'oil_5000', kmSinceOil = r and r.km_since_oil or 0,
            odometer = r and r.odometer or 0, wear = r and r.wear or 0,
        })
    end)
end)

RegisterNetEvent('srp:carplay:dealerStats', function()
    local src = source
    local Player = getPlayer(src)
    if not Player or not QBCore.Functions.HasPermission(src, 'admin') then return end
    MySQL.query('SELECT COUNT(*) AS total FROM player_vehicles', {}, function(rows)
        local r = rows and rows[1] or {}
        TriggerClientEvent('QBCore:Notify', src, ('📊 المركبات المملوكة: %s'):format(r.total or 0), 'primary')
    end)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    Players[Player.PlayerData.citizenid] = Players[Player.PlayerData.citizenid] or { channel = 0, volume = 50 }
end)

CreateThread(function() log('تم تحميل نظام الكار بلاي.') end)
