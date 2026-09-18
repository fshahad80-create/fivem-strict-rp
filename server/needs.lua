--[[
    fivem-strict-rp :: server/needs.lua
    سيرفر الاحتياجات والطقس: طقس حي + مزامنة + حفظ.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local N = Needs

local CurrentWeather = 'CLEAR'
local CurrentHour    = 12
local MinuteAccum    = 0

local function log(msg) print(('[fivem-strict-rp][needs] %s'):format(msg)) end

local function ensureSchema()
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_needs` (
        `citizenid` VARCHAR(50) NOT NULL PRIMARY KEY,
        `hunger` INT NOT NULL DEFAULT 100, `thirst` INT NOT NULL DEFAULT 100,
        `energy` INT NOT NULL DEFAULT 100, `hygiene` INT NOT NULL DEFAULT 100,
        `health` INT NOT NULL DEFAULT 100,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
    MySQL.query([[CREATE TABLE IF NOT EXISTS `srp_weather_state` (
        `id` INT NOT NULL PRIMARY KEY DEFAULT 1,
        `weather` VARCHAR(24) NOT NULL DEFAULT 'CLEAR',
        `hour` INT NOT NULL DEFAULT 12,
        `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local function loadWeather()
    MySQL.query('SELECT weather, hour FROM srp_weather_state WHERE id = 1', {}, function(rows)
        if rows and rows[1] then
            CurrentWeather = rows[1].weather or 'CLEAR'
            CurrentHour    = rows[1].hour or 12
        end
    end)
end

local function persistWeather()
    MySQL.query([[INSERT INTO srp_weather_state (id, weather, hour) VALUES (1, ?, ?)
        ON DUPLICATE KEY UPDATE weather = VALUES(weather), hour = VALUES(hour)]],
        { CurrentWeather, CurrentHour })
end

local function broadcastWeather()
    TriggerClientEvent('srp:needs:weather', -1, CurrentWeather)
    GlobalState.srp_weather = CurrentWeather
    GlobalState.srp_hour = CurrentHour
end

local function rotateWeather()
    if not N.Enabled.weather then return end
    local presets = N.Weather.presets
    local nxt = presets[math.random(1, #presets)]
    if nxt == CurrentWeather and #presets > 1 then nxt = presets[math.random(1, #presets)] end
    CurrentWeather = nxt
    persistWeather()
    broadcastWeather()
    log(('الطقس تغيّر إلى %s'):format(CurrentWeather))
end

CreateThread(function()
    ensureSchema()
    Wait(2000)
    if N.Sync.persistWeather then loadWeather() end
    Wait(2000)
    broadcastWeather()
    while true do
        Wait(N.Weather.cycleMinutes * 60 * 1000)
        if N.Enabled.weather then rotateWeather() end
    end
end)

CreateThread(function()
    while true do
        Wait(60 * 1000)
        MinuteAccum = MinuteAccum + N.Weather.timeScale
        if MinuteAccum >= 1 then
            CurrentHour = (CurrentHour + math.floor(MinuteAccum)) % 24
            MinuteAccum = MinuteAccum % 1
            broadcastWeather()
            if N.Sync.persistWeather then persistWeather() end
        end
    end
end)

RegisterNetEvent('srp:needs:sync', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not data then return end
    MySQL.query([[INSERT INTO srp_needs (citizenid, hunger, thirst, energy, hygiene, health)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE hunger = VALUES(hunger), thirst = VALUES(thirst),
        energy = VALUES(energy), hygiene = VALUES(hygiene), health = VALUES(health)]],
        { Player.PlayerData.citizenid, data.hunger or 100, data.thirst or 100,
          data.energy or 100, data.hygiene or 100, data.health or 100 })
end)

RegisterNetEvent('srp:needs:request', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_needs WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(rows)
        local data = (rows and rows[1]) or { hunger = 100, thirst = 100, energy = 100, hygiene = 100, health = 100 }
        TriggerClientEvent('srp:needs:apply', src, data)
        TriggerClientEvent('srp:needs:weather', src, CurrentWeather)
    end)
end)

QBCore.Commands.Add('needs', 'عرض احتياجاتك الحالية', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    MySQL.query('SELECT * FROM srp_needs WHERE citizenid = ?', { Player.PlayerData.citizenid }, function(rows)
        local r = (rows and rows[1]) or {}
        TriggerClientEvent('QBCore:Notify', source,
            ('جوع %s · عطش %s · طاقة %s · نظافة %s'):format(
                r.hunger or 100, r.thirst or 100, r.energy or 100, r.hygiene or 100), 'primary')
    end)
end, 'user')

QBCore.Commands.Add('setweather', 'ضبط الطقس يدوياً', { { name = 'weather', help = 'مثال RAIN' } }, false, function(source, args)
    local w = tostring(args[1] or ''):upper()
    local valid = false
    for _, p in ipairs(N.Weather.presets) do if p == w then valid = true break end end
    if not valid then
        TriggerClientEvent('QBCore:Notify', source, 'طقس غير صالح.', 'error') return
    end
    CurrentWeather = w
    persistWeather()
    broadcastWeather()
    TriggerClientEvent('QBCore:Notify', source, ('تم ضبط الطقس: %s'):format(w), 'success')
end, 'admin')

QBCore.Commands.Add('feed', 'إشباع احتياجات لاعب', { { name = 'id', help = 'ID اللاعب' } }, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then return end
    MySQL.query('UPDATE srp_needs SET hunger = 100, thirst = 100, energy = 100, hygiene = 100 WHERE citizenid = ?',
        { Player.PlayerData.citizenid })
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 'تم تجديد احتياجاتك.', 'success')
end, 'admin')

log('تم تحميل نظام الاحتياجات والطقس.')
