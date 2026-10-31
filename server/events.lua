-- Event Handlers

AddEventHandler('chatMessage', function(_, _, message)
    if string.sub(message, 1, 1) == '/' then
        CancelEvent()
    end
end)

local lastSave = {} -- per-source timestamp of the last client-requested save
local lastDuty = {} -- per-source timestamp of the last duty toggle

AddEventHandler('playerDropped', function(reason)
    local src = source
    lastSave[src] = nil
    lastDuty[src] = nil
    local Player = RSGCore.Players[src]
    if not Player then return end
    TriggerEvent('rsg-log:server:CreateLog', 'joinleave', 'Dropped', 'red', ('**%s** (%s) left..\n **Reason:** %s'):format(GetPlayerName(src) or 'unknown', Player.PlayerData.license, reason))
    TriggerEvent('RSGCore:Server:PlayerDropped', Player)
    Player.Functions.Save()
    RSGCore.Player_Buckets[Player.PlayerData.license] = nil
    RSGCore.Players[src] = nil
end)

-- Database checks

local databaseConnected, bansTableExists = MySQL.ready == nil, MySQL.ready == nil
if MySQL.ready ~= nil then
    MySQL.ready(function()
        databaseConnected = true

        local DatabaseInfo = RSGCore.Functions.GetDatabaseInfo()
        if not DatabaseInfo or not DatabaseInfo.exists then return end

        local result = MySQL.query.await('SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = "bans";', { DatabaseInfo.database })
        bansTableExists = result and result[1] ~= nil

        local resultColumns = MySQL.query.await('SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = "players" AND COLUMN_NAME IN ("weight", "slots");', { DatabaseInfo.database })
        local columnsExist = {}
        for _, column in ipairs(resultColumns or {}) do
            columnsExist[column.COLUMN_NAME] = true
        end

        -- add each missing column individually (previously both were added if either was missing, which errors)
        if not columnsExist.weight then
            MySQL.query.await(('ALTER TABLE players ADD COLUMN weight INT DEFAULT %d;'):format(RSGCore.Config.Player.PlayerDefaults.weight))
            RSGCore.ShowSuccess(GetCurrentResourceName(), 'Added weight column to players table')
        end
        if not columnsExist.slots then
            MySQL.query.await(('ALTER TABLE players ADD COLUMN slots INT DEFAULT %d;'):format(RSGCore.Config.Player.PlayerDefaults.slots))
            RSGCore.ShowSuccess(GetCurrentResourceName(), 'Added slots column to players table')
        end
    end)
end

-- Player Connecting

local function onPlayerConnecting(name, _, deferrals)
    local src = source
    deferrals.defer()

    if RSGCore.Config.Server.Closed and not IsPlayerAceAllowed(src, 'rsgadmin.join') then
        return deferrals.done(RSGCore.Config.Server.ClosedReason)
    end

    if not databaseConnected then
        return deferrals.done(locale('error.connecting_database_error'))
    end

    if RSGCore.Config.Server.Whitelist then
        Wait(0)
        deferrals.update(locale('info.checking_whitelisted', name))
        if not RSGCore.Functions.IsWhitelisted(src) then
            return deferrals.done(locale('error.not_whitelisted'))
        end
    end

    Wait(0)
    deferrals.update(locale('info.checking_license', name))
    local license = RSGCore.Functions.GetIdentifier(src, 'license')

    if not license then
        return deferrals.done(locale('error.no_valid_license'))
    elseif RSGCore.Config.Server.CheckDuplicateLicense and RSGCore.Functions.IsLicenseInUse(license) then
        return deferrals.done(locale('error.duplicate_license'))
    end

    Wait(0)
    deferrals.update(locale('info.checking_ban', name))

    if not bansTableExists then
        return deferrals.done(locale('error.ban_table_not_found'))
    end

    local success, isBanned, reason = pcall(RSGCore.Functions.IsPlayerBanned, src)
    if not success then return deferrals.done(locale('error.connecting_database_error')) end
    if isBanned then return deferrals.done(reason) end

    Wait(0)
    deferrals.update(locale('info.join_server', name))
    deferrals.done()
end

AddEventHandler('playerConnecting', onPlayerConnecting)

-- Open & Close Server (prevents players from joining)

RegisterNetEvent('RSGCore:Server:CloseServer', function(reason)
    local src = source
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        return RSGCore.Functions.Kick(src, locale('error.no_permission'))
    end
    RSGCore.Functions.SetServerClosed(true, reason)
end)

RegisterNetEvent('RSGCore:Server:OpenServer', function()
    local src = source
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        return RSGCore.Functions.Kick(src, locale('error.no_permission'))
    end
    RSGCore.Functions.SetServerClosed(false)
end)

-- Callback Events --

-- Client Callback (response from a client to a server-initiated callback)
-- Callbacks are keyed per source so a client can only resolve its own pending callbacks
RegisterNetEvent('RSGCore:Server:TriggerClientCallback', function(name, ...)
    local key = RSGCore.Functions.ClientCallbackKey(source, name)
    local cb = RSGCore.ClientCallbacks[key]
    if not cb then return end
    RSGCore.ClientCallbacks[key] = nil
    cb(...)
end)

-- Server Callback (legacy, keyed by name only - kept for resources that trigger it directly)
RegisterNetEvent('RSGCore:Server:TriggerCallback', function(name, ...)
    local src = source
    if type(name) ~= 'string' then return end
    RSGCore.Functions.TriggerCallback(name, src, function(...)
        TriggerClientEvent('RSGCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

-- Server Callback with a request id, so concurrent calls to the same callback each get their own response
RegisterNetEvent('RSGCore:Server:TriggerCallbackId', function(name, requestId, ...)
    local src = source
    if type(name) ~= 'string' or type(requestId) ~= 'number' then return end
    RSGCore.Functions.TriggerCallback(name, src, function(...)
        TriggerClientEvent('RSGCore:Client:TriggerCallbackId', src, requestId, ...)
    end, ...)
end)

-- Player

local SAVE_COOLDOWN = 30 -- seconds; prevents clients spamming database writes

RegisterNetEvent('RSGCore:UpdatePlayer', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local now = os.time()
    if lastSave[src] and now - lastSave[src] < SAVE_COOLDOWN then return end
    lastSave[src] = now
    Player.Functions.Save()
end)

RegisterNetEvent('RSGCore:Server:SetMetaData', function(meta, data)
    local src = source
    if type(meta) ~= 'string' or not RSGCore.Config.ClientWritableMetadata[meta] then return end
    if type(data) ~= 'number' then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData(meta, data)
end)

local DUTY_COOLDOWN_MS = 2000

RegisterNetEvent('RSGCore:ToggleDuty', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local now = GetGameTimer()
    if lastDuty[src] and now - lastDuty[src] < DUTY_COOLDOWN_MS then return end -- stops notify/log spam
    lastDuty[src] = now
    local onDuty = not Player.PlayerData.job.onduty
    Player.Functions.SetJobDuty(onDuty)
    TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale(onDuty and 'info.on_duty' or 'info.off_duty'), type = 'inform', duration = 5000 })
    TriggerEvent('RSGCore:Server:SetDuty', src, onDuty)
    TriggerClientEvent('RSGCore:Client:SetDuty', src, onDuty)
end)

-- Non-Chat Command Calling (ex: rsg-adminmenu)

RegisterNetEvent('RSGCore:CallCommand', function(command, args)
    local src = source
    if type(command) ~= 'string' then return end
    local cmd = RSGCore.Commands.List[command]
    if not cmd then return end
    if not RSGCore.Functions.GetPlayer(src) then return end
    args = type(args) == 'table' and args or {}

    -- 'user' commands have no ace (everyone may use them), so they were always refused here
    if cmd.permission ~= 'user' and not RSGCore.Functions.HasPermission(src, 'command.' .. cmd.name) then
        return TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('error.no_access'), type = 'error', duration = 5000 })
    end
    if cmd.argsrequired and #cmd.arguments ~= 0 and not args[#cmd.arguments] then
        return TriggerClientEvent('RSGCore:Client:Notify', src, { title = locale('error.missing_args2'), type = 'error', duration = 5000 })
    end
    cmd.callback(src, args)
end)

-- Vehicle server-side spawning callback (returns netId)
-- use NetworkGetEntityFromNetworkId / NetToVeh on the client
-- Restricted to models registered in RSGShared.Vehicles so clients cannot spawn arbitrary entities
local SPAWN_COOLDOWN_MS = 5000
local SPAWN_MAX_DISTANCE = 50.0
local lastSpawn = {}
AddEventHandler('playerDropped', function() lastSpawn[source] = nil end)

RSGCore.Functions.CreateCallback('RSGCore:Server:SpawnVehicle', function(source, cb, model, coords, warp)
    if not RSGCore.Functions.GetPlayer(source) then return cb(nil) end
    -- rate limit: stops a client flooding the world with networked vehicles
    local now = GetGameTimer()
    if lastSpawn[source] and now - lastSpawn[source] < SPAWN_COOLDOWN_MS then return cb(nil) end
    -- only allow spawning next to the player (previously any coords were accepted)
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    if coords ~= nil then
        if type(coords) ~= 'vector3' and type(coords) ~= 'vector4' and type(coords) ~= 'table' then return cb(nil) end
        local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
        if not x or not y or not z or #(pCoords - vector3(x, y, z)) > SPAWN_MAX_DISTANCE then return cb(nil) end
    end
    local hash = type(model) == 'string' and joaat(model) or model
    local allowed = false
    for _, v in pairs(RSGCore.Shared.Vehicles) do
        if v.hash == hash then allowed = true break end
    end
    if not allowed then return cb(nil) end
    lastSpawn[source] = now
    local veh = RSGCore.Functions.SpawnVehicle(source, hash, coords, warp)
    cb(veh and NetworkGetNetworkIdFromEntity(veh) or nil)
end)

RegisterNetEvent('RSGCore:Server:KickCSRF', function()
    DropPlayer(source, locale('error.csrf_failed'))
end)
