-- Transaction history (for tracing money problems and duplication reports) and character playtime.

Transactions = {}

local txConfig = RSGCore.Config.Transactions or { Enabled = true, RetentionDays = 30 }
local ptConfig = RSGCore.Config.Playtime or { Enabled = true }

local FLUSH_MS = 5000
local BATCH_SIZE = 100
local MAX_BUFFER = 5000
local buffer = {}

local function notify(src, text, kind)
    if src == 0 then return print(text) end
    TriggerClientEvent('RSGCore:Client:Notify', src, { title = text, type = kind or 'inform', duration = 7000 })
end

local function chatLine(src, text)
    if src == 0 then return print(text) end
    TriggerClientEvent('chat:addMessage', src, { args = { text } })
end

local function cut(text, max)
    text = tostring(text or '')
    if not utf8.len(text) then return text:sub(1, max) end
    local at = utf8.offset(text, max + 1)
    return at and text:sub(1, at - 1) or text
end

-- server id of an online player, or a citizen id
local function resolveCitizenId(value)
    local id = tonumber(value)
    local Target = id and RSGCore.Functions.GetPlayer(id)
    return Target and Target.PlayerData.citizenid or tostring(value):upper()
end

---amount is the changed amount ('set': the new value, 'items': signed difference from inventory movement)
function Transactions.Record(PlayerData, moneytype, operation, amount, balance, reason)
    if not txConfig.Enabled or not PlayerData or not PlayerData.citizenid or #buffer >= MAX_BUFFER then return end
    buffer[#buffer + 1] = {
        PlayerData.citizenid, tostring(moneytype), operation, tonumber(amount) or 0, tonumber(balance) or 0,
        cut(reason or 'unknown', 150), cut(GetInvokingResource() or 'rsg-core', 60), os.time(),
    }
end

local function flushTransactions()
    while #buffer > 0 do
        local count = math.min(#buffer, BATCH_SIZE)
        local marks, params, n = {}, {}, 0
        for i = 1, count do
            marks[i] = '(?, ?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?))'
            for c = 1, 8 do
                n = n + 1
                params[n] = buffer[i][c]
            end
        end
        local rest = {}
        for i = count + 1, #buffer do rest[#rest + 1] = buffer[i] end
        buffer = rest
        local ok, err = pcall(MySQL.insert, 'INSERT INTO rsg_transactions (citizenid, moneytype, operation, amount, balance, reason, resource, created) VALUES ' .. table.concat(marks, ', '), params)
        if not ok then print(('^1[rsg-core] could not write %d transaction(s): %s^7'):format(count, tostring(err))) end
    end
end

if txConfig.Enabled then
    CreateThread(function()
        while true do
            Wait(FLUSH_MS)
            flushTransactions()
        end
    end)

    if (txConfig.RetentionDays or 0) > 0 then
        CreateThread(function()
            Wait(30000)
            while true do
                local ok, err = pcall(MySQL.query.await, 'DELETE FROM rsg_transactions WHERE created < NOW() - INTERVAL ? DAY', { math.floor(txConfig.RetentionDays) })
                if not ok then print(('^1[rsg-core] transaction cleanup failed: %s^7'):format(tostring(err))) end
                Wait(24 * 60 * 60 * 1000)
            end
        end)
    end

    RSGCore.Commands.Add('transactions', locale('history.command'), {
        { name = 'target', help = locale('param.target') },
        { name = 'count', help = locale('param.count') },
    }, false, function(source, args)
        if not args[1] then return notify(source, locale('error.missing_args2'), 'error') end
        local citizenid = resolveCitizenId(args[1])
        local limit = math.max(1, math.min(30, math.floor(tonumber(args[2]) or 10)))
        flushTransactions()
        Wait(250)
        local rows = MySQL.query.await("SELECT moneytype, operation, amount, balance, reason, resource, DATE_FORMAT(created, '%d/%m %H:%i:%s') AS at FROM rsg_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT ?", { citizenid, limit }) or {}
        if #rows == 0 then return notify(source, locale('history.empty')) end
        for i = #rows, 1, -1 do
            local r = rows[i]
            chatLine(source, ('[%s] %s %s %s %s = %s | %s (%s)'):format(r.at, citizenid, r.operation, tostring(r.amount), r.moneytype, tostring(r.balance), r.reason, r.resource))
        end
        RSGCore.Functions.AdminLog(source, 'transactions', citizenid)
    end, 'admin')
end

-----------------------------------------------------------------------
-- Playtime
-----------------------------------------------------------------------

local sessions = {} -- [source] = { citizenid, since }

local function savePlaytime(src, ended)
    local session = sessions[src]
    if not session then return end
    local now = os.time()
    local seconds = now - session.since
    session.since = now
    if ended then sessions[src] = nil end
    if seconds <= 0 then return end
    local ok, err = pcall(MySQL.insert, 'INSERT INTO rsg_playtime (citizenid, seconds) VALUES (?, ?) ON DUPLICATE KEY UPDATE seconds = seconds + ?, last_seen = CURRENT_TIMESTAMP', { session.citizenid, seconds, seconds })
    if not ok then print(('^1[rsg-core] could not save playtime for %s: %s^7'):format(session.citizenid, tostring(err))) end
end

local function sessionList()
    local list = {}
    for src in pairs(sessions) do list[#list + 1] = src end
    return list
end

---Total seconds a character has played
---@param citizenid string
---@return number
local function getPlaytime(citizenid)
    if type(citizenid) ~= 'string' then return 0 end
    local total = tonumber(MySQL.scalar.await('SELECT seconds FROM rsg_playtime WHERE citizenid = ?', { citizenid })) or 0
    for _, session in pairs(sessions) do
        if session.citizenid == citizenid then total = total + (os.time() - session.since) end
    end
    return total
end

RSGCore.Functions.GetPlaytime = getPlaytime
exports('GetPlaytime', getPlaytime)

if ptConfig.Enabled then
    AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
        if (tonumber(source) or 0) > 0 then return end
        local src = Player.PlayerData.source
        savePlaytime(src, true)
        sessions[src] = { citizenid = Player.PlayerData.citizenid, since = os.time() }
    end)
    AddEventHandler('RSGCore:Server:OnPlayerUnload', function(src)
        if (tonumber(source) or 0) > 0 then return end
        savePlaytime(src, true)
    end)
    AddEventHandler('playerDropped', function() savePlaytime(source, true) end)

    CreateThread(function()
        while true do
            Wait(5 * 60 * 1000)
            for _, src in ipairs(sessionList()) do savePlaytime(src, false) end
        end
    end)

    RSGCore.Commands.Add('playtime', locale('playtime.command'), { { name = 'target', help = locale('param.target') } }, false, function(source, args)
        local citizenid
        if args[1] then
            -- looking up someone else is for admins
            if source > 0 and not RSGCore.Functions.HasPermission(source, 'admin') then
                return notify(source, locale('error.no_access'), 'error')
            end
            citizenid = resolveCitizenId(args[1])
        else
            local Player = source > 0 and RSGCore.Functions.GetPlayer(source)
            if not Player then return end
            citizenid = Player.PlayerData.citizenid
        end
        local total = getPlaytime(citizenid)
        notify(source, locale('playtime.result', citizenid, total // 3600, (total % 3600) // 60))
    end, 'user')
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    flushTransactions()
    for _, src in ipairs(sessionList()) do savePlaytime(src, true) end
end)
