--[[
    fivem-strict-rp :: server/assistant.lua
    المساعد الذكي — الإجابة على الأسئلة · المواقع · التلميحات · F3.
]]

local QBCore = exports['qb-core']:GetCoreObject()
local A = Assistant

local function log(msg) print(('[fivem-strict-rp][assistant] %s'):format(msg)) end
local function getPlayer(src) return QBCore.Functions.GetPlayer(src) end

local function findAnswer(question)
    if not question then return nil end
    local q = question:lower()
    local best, bestScore = nil, 0
    for _, entry in ipairs(A.Knowledge) do
        local score = 0
        for _, kw in ipairs(entry.keywords) do
            if q:find(kw:lower(), 1, true) then score = score + 1 end
        end
        if score > bestScore then bestScore = score; best = entry end
    end
    if bestScore > 0 then return best end
    return nil
end

QBCore.Commands.Add('ask', 'اسأل المساعد الذكي', { { name = 'question', help = 'سؤالك' } }, false,
function(source, args)
    local src = source
    local question = table.concat(args, ' ')
    if question == '' then
        TriggerClientEvent('QBCore:Notify', src, A.Messages.help, 'primary') return
    end
    if #question > A.Settings.maxQuestionLen then question = question:sub(1, A.Settings.maxQuestionLen) end
    local entry = findAnswer(question)
    if not entry then
        TriggerClientEvent('QBCore:Notify', src, A.Messages.noAnswer, 'error') return
    end
    TriggerClientEvent('QBCore:Notify', src, entry.answer, 'primary')
end, 'user')

RegisterNetEvent('srp:assistant:requestLocations', function()
    local src = source
    local list = {}
    for _, entry in ipairs(A.Knowledge) do
        if entry.location then
            list[#list+1] = { key = entry.location.key, label = entry.location.label,
                x = entry.location.x, y = entry.location.y, z = entry.location.z }
        end
    end
    TriggerClientEvent('srp:assistant:showLocations', src, list)
end)

RegisterNetEvent('srp:assistant:locate', function(key)
    local src = source
    for _, entry in ipairs(A.Knowledge) do
        if entry.location and entry.location.key == key then
            TriggerClientEvent('srp:assistant:setBlip', src, entry.location)
            TriggerClientEvent('QBCore:Notify', src, ('تم تحديد %s على خريطتك.'):format(entry.location.label), 'success')
            return
        end
    end
end)

RegisterNetEvent('srp:assistant:requestMenu', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end
    local pd = Player.PlayerData
    local info = {
        name = pd.charinfo.firstname .. ' ' .. pd.charinfo.lastname,
        job = pd.job.label or pd.job.name,
        cash = Player.Functions.GetMoney('cash'),
        bank = Player.Functions.GetMoney('bank'),
        quickQuestions = A.QuickQuestions,
        knowledge = {},
    }
    for _, entry in ipairs(A.Knowledge) do
        if entry.location then info.knowledge[#info.knowledge+1] = { label = entry.location.label, key = entry.location.key } end
    end
    TriggerClientEvent('srp:assistant:showMenu', src, info)
end)

CreateThread(function()
    if not A.Settings.tipsEnabled then return end
    Wait(30000)
    while true do
        Wait((A.Settings.tipIntervalSec or 180) * 1000)
        local tip = A.Tips[math.random(1, #A.Tips)]
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', src, tip, 'inform')
        end
    end
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    if not A.Settings.welcomeOnJoin then return end
    Wait(8000)
    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, A.Messages.welcome, 'primary')
end)

CreateThread(function() log('تم تحميل المساعد الذكي.') end)
