-- Public server API: thin exports over RSGCore.Functions so other resources can call
-- exports['rsg-core']:GetPlayer(src) etc. without holding the whole core object.
-- Loaded last, so every function below already exists.

local exported = {
    -- players
    'GetPlayer', 'GetPlayerByCitizenId', 'GetOfflinePlayerByCitizenId', 'GetPlayerByLicense',
    'GetPlayerByAccount', 'GetPlayerByCharInfo', 'GetPlayers', 'GetRSGPlayers',
    'GetPlayersOnDuty', 'GetDutyCount', 'GetIdentifier', 'GetSource',
    -- permissions / access
    'HasPermission', 'AddPermission', 'RemovePermission', 'GetPermission', 'IsValidPermission',
    'IsWhitelisted', 'IsPlayerBanned', 'CanJoinClosed', 'SetServerClosed', 'Kick',
    -- items and notifications
    'CreateUseableItem', 'CanUseItem', 'UseItem', 'Notify',
    -- routing buckets
    'SetPlayerBucket', 'SetEntityBucket', 'GetPlayersInBucket', 'GetEntitiesInBucket',
    -- misc
    'AdminLog', 'AddPlayerMethod', 'AddPlayerField',
}

for i = 1, #exported do
    local name = exported[i]
    local fn = RSGCore.Functions[name]
    if type(fn) == 'function' then
        exports(name, fn)
    else
        print(('^3[rsg-core] api: RSGCore.Functions.%s is missing, export skipped^7'):format(name))
    end
end

-- Money helpers by server id: nil-safe, so callers don't need to fetch the player object first.
-- Return values match Player.Functions (false when the player is offline or the change is refused).

---@param src number
---@param moneytype string cash | gold | bank | bloodmoney
---@param amount number
---@param reason string?
---@return boolean
exports('AddMoney', function(src, moneytype, amount, reason)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.AddMoney(moneytype, amount, reason) and true or false
end)

---@return boolean
exports('RemoveMoney', function(src, moneytype, amount, reason)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.RemoveMoney(moneytype, amount, reason) and true or false
end)

---@return number
exports('GetMoney', function(src, moneytype)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return 0 end
    return Player.Functions.GetMoney(moneytype) or 0
end)

exports('GetMetaData', function(src, key)
    local Player = RSGCore.Functions.GetPlayer(src)
    return Player and Player.Functions.GetMetaData(key) or nil
end)

exports('SetMetaData', function(src, key, value)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or type(key) ~= 'string' then return false end
    Player.Functions.SetMetaData(key, value)
    return true
end)

-- Returns the player's current job table (name, label, payment, type, onduty, isboss, grade) or nil
exports('GetJob', function(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.job or nil
end)

exports('GetGang', function(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.gang or nil
end)
