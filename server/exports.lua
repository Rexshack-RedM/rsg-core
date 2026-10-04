-- Add or change (a) method(s) in the RSGCore.Functions table
local function SetMethod(methodName, handler)
    if type(methodName) ~= 'string' then
        return false, 'invalid_method_name'
    end

    RSGCore.Functions[methodName] = handler

    TriggerEvent('RSGCore:Server:UpdateObject')

    return true, 'success'
end

RSGCore.Functions.SetMethod = SetMethod
exports('SetMethod', SetMethod)

-- Add or change (a) field(s) in the RSGCore table
local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then
        return false, 'invalid_field_name'
    end

    RSGCore[fieldName] = data

    TriggerEvent('RSGCore:Server:UpdateObject')

    return true, 'success'
end

RSGCore.Functions.SetField = SetField
exports('SetField', SetField)

-- Shared table (Jobs / Items / Gangs) management
-- Runtime changes are recorded so players joining later receive them too
-- (previously late joiners only had the static shared files and missed any AddJob/AddItem/... changes).

local sharedChanges = { Jobs = {}, Items = {}, Gangs = {} } -- [table][key] = value | false (removed)

local function recordChange(tableName, key, value)
    sharedChanges[tableName][key] = value == nil and false or value
end

local function sharedUpdated(tableName, key, value)
    recordChange(tableName, key, value)
    TriggerClientEvent('RSGCore:Client:OnSharedUpdate', -1, tableName, key, value)
    TriggerEvent('RSGCore:Server:UpdateObject')
    return true, 'success'
end

---@param tableName 'Jobs'|'Items'|'Gangs'
---@param prefix string error code prefix ('job', 'item', 'gang')
local function makeSharedApi(tableName, prefix)
    local api = {}
    local invalidName = ('invalid_%s_name'):format(prefix)
    local exists = ('%s_exists'):format(prefix)
    local notExists = ('%s_not_exists'):format(prefix)

    function api.add(name, data)
        if type(name) ~= 'string' then return false, invalidName end
        if RSGCore.Shared[tableName][name] then return false, exists end
        RSGCore.Shared[tableName][name] = data
        return sharedUpdated(tableName, name, data)
    end

    -- validates every entry first, so a failure no longer leaves a half-applied, unsynced batch
    function api.addMany(entries)
        if type(entries) ~= 'table' then return false, invalidName, nil end
        for name, data in pairs(entries) do
            if type(name) ~= 'string' then return false, invalidName, data end
            if RSGCore.Shared[tableName][name] then return false, exists, data end
        end
        for name, data in pairs(entries) do
            RSGCore.Shared[tableName][name] = data
            recordChange(tableName, name, data)
        end
        TriggerClientEvent('RSGCore:Client:OnSharedUpdateMultiple', -1, tableName, entries)
        TriggerEvent('RSGCore:Server:UpdateObject')
        return true, 'success', nil
    end

    function api.update(name, data)
        if type(name) ~= 'string' then return false, invalidName end
        if not RSGCore.Shared[tableName][name] then return false, notExists end
        RSGCore.Shared[tableName][name] = data
        return sharedUpdated(tableName, name, data)
    end

    function api.remove(name)
        if type(name) ~= 'string' then return false, invalidName end
        if not RSGCore.Shared[tableName][name] then return false, notExists end
        RSGCore.Shared[tableName][name] = nil
        return sharedUpdated(tableName, name, nil)
    end

    return api
end

local function register(name, fn)
    RSGCore.Functions[name] = fn
    exports(name, fn)
end

local jobs, items, gangs = makeSharedApi('Jobs', 'job'), makeSharedApi('Items', 'item'), makeSharedApi('Gangs', 'gang')

register('AddJob', jobs.add)
register('AddJobs', jobs.addMany)
register('UpdateJob', jobs.update)
register('RemoveJob', jobs.remove)

register('AddItem', items.add)
register('AddItems', items.addMany)
register('UpdateItem', items.update)
register('RemoveItem', items.remove)

register('AddGang', gangs.add)
register('AddGangs', gangs.addMany)
register('UpdateGang', gangs.update)
register('RemoveGang', gangs.remove)

-- send runtime shared changes to a player once their character is loaded
AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    for tableName, changes in pairs(sharedChanges) do
        if next(changes) then
            TriggerClientEvent('RSGCore:Client:OnSharedUpdateMultiple', src, tableName, changes)
        end
    end
end)

local resourceName = GetCurrentResourceName()
local function GetCoreVersion(InvokingResource)
    local resourceVersion = GetResourceMetadata(resourceName, 'version')
    if InvokingResource and InvokingResource ~= '' then
        print(('%s called rsgcore version check: %s'):format(InvokingResource or 'Unknown Resource', resourceVersion))
    end
    return resourceVersion
end

RSGCore.Functions.GetCoreVersion = GetCoreVersion
exports('GetCoreVersion', GetCoreVersion)

local function ExploitBan(playerId, origin)
    local name = GetPlayerName(playerId) or ('ID ' .. tostring(playerId))
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        name,
        RSGCore.Functions.GetIdentifier(playerId, 'license'),
        RSGCore.Functions.GetIdentifier(playerId, 'discord'),
        RSGCore.Functions.GetIdentifier(playerId, 'ip'),
        origin,
        2147483647,
        'Anti Cheat'
    })
    DropPlayer(playerId, locale('info.exploit_banned', RSGCore.Config.Server.Discord))
    TriggerEvent('rsg-log:server:CreateLog', 'anticheat', 'Anti-Cheat', 'red', name .. ' has been banned for exploiting ' .. origin, true)
end

exports('ExploitBan', ExploitBan)
