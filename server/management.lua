-- Ban management and in-game whitelist. Commands are ace restricted (admin) and also work from the console.

local PERMANENT = 2147483647
local UNITS = { m = 60, h = 3600, d = 86400, w = 604800 }

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

---'30m' | '12h' | '7d' | '2w' | 'perm' -> expiry timestamp
local function parseDuration(value)
    value = tostring(value or ''):lower()
    if value == 'perm' or value == 'permanent' then return PERMANENT end
    local number, unit = value:match('^(%d+)([mhdw])$')
    number = tonumber(number)
    if not number or number <= 0 then return nil end
    -- float maths: a huge number must cap at permanent, not overflow into an already expired ban
    return math.floor(math.min(PERMANENT, os.time() + number * 1.0 * UNITS[unit]))
end

local function adminName(src)
    return src == 0 and 'console' or cut(GetPlayerName(src) or 'unknown', 200)
end

local function insertBan(name, license, discord, ip, reason, expire, bannedby)
    return MySQL.insert.await('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { cut(name, 50), license, discord, ip, reason, expire, bannedby })
end

-- nobody may ban themselves; only the console or a god may ban an admin
local function isProtected(src, target)
    if src == target then return true end
    if src == 0 or RSGCore.Functions.HasPermission(src, 'god') then return false end
    return RSGCore.Functions.HasPermission(target, { 'god', 'admin' })
end

-- every connected client using a license, with or without a loaded character
local function connectedWithLicense(license)
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        local playerId = tonumber(id)
        if playerId and RSGCore.Functions.GetIdentifier(playerId, 'license') == license then
            list[#list + 1] = playerId
        end
    end
    return list
end

local function finishBan(src, banId, name, license, reason, expire)
    local expiry = os.date('%d/%m/%Y %H:%M', expire)
    for _, playerId in ipairs(connectedWithLicense(license)) do
        DropPlayer(playerId, locale('info.ban_message', reason, expiry))
    end
    RSGCore.Functions.AdminLog(src, 'ban', ('#%s %s until %s - %s'):format(tostring(banId), name, expire == PERMANENT and 'permanent' or expiry, reason))
    notify(src, locale('ban.done', name, tostring(banId)), 'success')
end

local function reasonFrom(args, from)
    local reason = table.concat(args, ' ', from)
    return reason ~= '' and cut(reason, 500) or locale('info.no_reason')
end

local banArgs = {
    { name = 'target', help = locale('param.target') },
    { name = 'duration', help = locale('param.duration') },
    { name = 'reason', help = locale('param.reason') },
}

RSGCore.Commands.Add('ban', locale('ban.command'), banArgs, false, function(source, args)
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then return notify(source, locale('error.not_online'), 'error') end
    local expire = parseDuration(args[2])
    if not expire then return notify(source, locale('ban.invalid_duration'), 'error') end
    if isProtected(source, target) then return notify(source, locale('ban.protected'), 'error') end
    local license = RSGCore.Functions.GetIdentifier(target, 'license')
    if not license then return notify(source, locale('error.no_valid_license'), 'error') end
    local name, reason = GetPlayerName(target), reasonFrom(args, 3)
    local banId = insertBan(name, license, RSGCore.Functions.GetIdentifier(target, 'discord'), RSGCore.Functions.GetIdentifier(target, 'ip'), reason, expire, adminName(source))
    if not banId then return notify(source, locale('error.database'), 'error') end
    finishBan(source, banId, name, license, reason, expire)
end, 'admin')

RSGCore.Commands.Add('offlineban', locale('ban.command_offline'), banArgs, false, function(source, args)
    local citizenid = tostring(args[1] or ''):upper()
    local row = MySQL.single.await('SELECT license, name FROM players WHERE citizenid = ?', { citizenid })
    if not row or not row.license then return notify(source, locale('ban.target_not_found'), 'error') end
    local expire = parseDuration(args[2])
    if not expire then return notify(source, locale('ban.invalid_duration'), 'error') end
    for _, playerId in ipairs(connectedWithLicense(row.license)) do
        if isProtected(source, playerId) then return notify(source, locale('ban.protected'), 'error') end
    end
    local name, reason = row.name or citizenid, reasonFrom(args, 3)
    local banId = insertBan(name, row.license, nil, nil, reason, expire, adminName(source))
    if not banId then return notify(source, locale('error.database'), 'error') end
    finishBan(source, banId, name, row.license, reason, expire)
end, 'admin')

RSGCore.Commands.Add('unban', locale('ban.command_unban'), { { name = 'id', help = locale('param.banid') } }, true, function(source, args)
    local banId = math.tointeger(tonumber(args[1]))
    local removed = banId and MySQL.update.await('DELETE FROM bans WHERE id = ?', { banId })
    if removed ~= 1 then return notify(source, locale('ban.not_found'), 'error') end
    RSGCore.Functions.AdminLog(source, 'unban', '#' .. banId)
    notify(source, locale('ban.unbanned', tostring(banId)), 'success')
end, 'admin')

RSGCore.Commands.Add('banlist', locale('ban.command_list'), { { name = 'search', help = locale('param.search') } }, false, function(source, args)
    local like = '%' .. table.concat(args, ' ') .. '%'
    local rows = MySQL.query.await('SELECT id, name, reason, expire, bannedby FROM bans WHERE expire > ? AND (name LIKE ? OR license LIKE ? OR reason LIKE ?) ORDER BY id DESC LIMIT 15', { os.time(), like, like, like }) or {}
    if #rows == 0 then return notify(source, locale('ban.list_empty')) end
    for _, r in ipairs(rows) do
        local expire = tonumber(r.expire) or 0
        chatLine(source, ('#%s %s | %s | %s | %s'):format(r.id, r.name or '?', expire >= PERMANENT and 'perm' or os.date('%d/%m/%Y %H:%M', expire), r.reason or '', r.bannedby or '?'))
    end
end, 'admin')

-----------------------------------------------------------------------
-- Whitelist (used when RSGConfig.Server.Whitelist = true)
-----------------------------------------------------------------------

-- server id (online) | license:xxxx | citizenid  ->  license, name
local function resolveLicense(value)
    value = tostring(value or '')
    local id = tonumber(value)
    if id then
        if not GetPlayerName(id) then return nil end
        return RSGCore.Functions.GetIdentifier(id, 'license'), GetPlayerName(id)
    end
    if value:lower():sub(1, 8) == 'license:' then
        value = value:lower()
        if not value:match('^license:%x+$') or #value > 60 then return nil end
        return value, nil
    end
    local row = MySQL.single.await('SELECT license, name FROM players WHERE citizenid = ?', { value:upper() })
    if row then return row.license, row.name end
    return nil
end

RSGCore.Commands.Add('whitelist', locale('whitelist.command'), {
    { name = 'action', help = locale('whitelist.usage') },
    { name = 'target', help = locale('whitelist.target') },
}, false, function(source, args)
    local action = tostring(args[1] or ''):lower()
    if action == 'list' then
        local rows = MySQL.query.await('SELECT license, name, added_by FROM rsg_whitelist ORDER BY created DESC LIMIT 30') or {}
        if #rows == 0 then return notify(source, locale('whitelist.empty')) end
        for _, r in ipairs(rows) do chatLine(source, ('%s | %s | %s'):format(r.name or '?', r.license, r.added_by or '?')) end
        return
    end
    if (action ~= 'add' and action ~= 'remove') or not args[2] then return notify(source, locale('whitelist.usage'), 'error') end
    local license, name = resolveLicense(args[2])
    if not license then return notify(source, locale('ban.target_not_found'), 'error') end
    if action == 'add' then
        local stored = name and cut(name, 100) or nil
        MySQL.query.await('INSERT INTO rsg_whitelist (license, name, added_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE added_by = ?',
            { license, stored or '?', cut(adminName(source), 100), cut(adminName(source), 100) })
        notify(source, locale('whitelist.added', name or license), 'success')
    else
        local removed = MySQL.update.await('DELETE FROM rsg_whitelist WHERE license = ?', { license })
        if (removed or 0) < 1 then return notify(source, locale('whitelist.not_listed'), 'error') end
        notify(source, locale('whitelist.removed', name or license), 'success')
    end
    RSGCore.Functions.AdminLog(source, 'whitelist ' .. action, license)
end, 'admin')
