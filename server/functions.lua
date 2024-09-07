RSGCore.Functions = {}
RSGCore.Player_Buckets = {}
RSGCore.Entity_Buckets = {}
RSGCore.UsableItems = {}

-- Getters
-- Get your player first and then trigger a function on them
-- ex: local player = RSGCore.Functions.GetPlayer(source)
-- ex: local example = player.Functions.functionname(parameter)

function RSGCore.Functions.GetCoords(entity)
    local coords = GetEntityCoords(entity, false)
    local heading = GetEntityHeading(entity)
    return vector4(coords.x, coords.y, coords.z, heading)
end

function RSGCore.Functions.GetIdentifier(source, idtype)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

function RSGCore.Functions.GetSource(identifier)
    for src, _ in pairs(RSGCore.Players) do
        local idens = GetPlayerIdentifiers(src)
        for _, id in pairs(idens) do
            if identifier == id then
                return src
            end
        end
    end
    return 0
end

function RSGCore.Functions.GetPlayer(source)
    if type(source) == 'number' then
        return RSGCore.Players[source]
    else
        return RSGCore.Players[RSGCore.Functions.GetSource(source)]
    end
end

function RSGCore.Functions.GetPlayerByCitizenId(citizenid)
    for src in pairs(RSGCore.Players) do
        if RSGCore.Players[src].PlayerData.citizenid == citizenid then
            return RSGCore.Players[src]
        end
    end
    return nil
end

function RSGCore.Functions.GetOfflinePlayerByCitizenId(citizenid)
    return RSGCore.Player.GetOfflinePlayer(citizenid)
end

function RSGCore.Functions.GetPlayers()
    local sources = {}
    for k in pairs(RSGCore.Players) do
        sources[#sources+1] = k
    end
    return sources
end

-- Will return an array of RSG Player class instances
-- unlike the GetPlayers() wrapper which only returns IDs
function RSGCore.Functions.GetRSGPlayers()
    return RSGCore.Players
end

--- Gets a list of all on duty players of a specified job and the number
function RSGCore.Functions.GetPlayersOnDuty(job)
    local players = {}
    local count = 0
    for src, Player in pairs(RSGCore.Players) do
        if Player.PlayerData.job.name == job then
            if Player.PlayerData.job.onduty then
                players[#players + 1] = src
                count += 1
            end
        end
    end
    return players, count
end

-- Returns only the amount of players on duty for the specified job
function RSGCore.Functions.GetDutyCount(job)
    local count = 0
    for _, Player in pairs(RSGCore.Players) do
        if Player.PlayerData.job.name == job then
            if Player.PlayerData.job.onduty then
                count += 1
            end
        end
    end
    return count
end

-- Routing buckets (Only touch if you know what you are doing)

-- Returns the objects related to buckets, first returned value is the player buckets, second one is entity buckets
function RSGCore.Functions.GetBucketObjects()
    return RSGCore.Player_Buckets, RSGCore.Entity_Buckets
end

-- Will set the provided player id / source into the provided bucket id
function RSGCore.Functions.SetPlayerBucket(source --[[ int ]], bucket --[[ int ]])
    if source and bucket then
        local plicense = RSGCore.Functions.GetIdentifier(source, 'license')
        SetPlayerRoutingBucket(source, bucket)
        RSGCore.Player_Buckets[plicense] = {id = source, bucket = bucket}
        return true
    else
        return false
    end
end

-- Will set any entity into the provided bucket, for example peds / vehicles / props / etc.
function RSGCore.Functions.SetEntityBucket(entity --[[ int ]], bucket --[[ int ]])
    if entity and bucket then
        SetEntityRoutingBucket(entity, bucket)
        RSGCore.Entity_Buckets[entity] = {id = entity, bucket = bucket}
        return true
    else
        return false
    end
end

-- Will return an array of all the player ids inside the current bucket
function RSGCore.Functions.GetPlayersInBucket(bucket --[[ int ]])
    local curr_bucket_pool = {}
    if RSGCore.Player_Buckets and next(RSGCore.Player_Buckets) then
        for _, v in pairs(RSGCore.Player_Buckets) do
            if v.bucket == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = v.id
            end
        end
        return curr_bucket_pool
    else
        return false
    end
end

-- Will return an array of all the entities inside the current bucket (not for player entities, use GetPlayersInBucket for that)
function RSGCore.Functions.GetEntitiesInBucket(bucket --[[ int ]])
    local curr_bucket_pool = {}
    if RSGCore.Entity_Buckets and next(RSGCore.Entity_Buckets) then
        for _, v in pairs(RSGCore.Entity_Buckets) do
            if v.bucket == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = v.id
            end
        end
        return curr_bucket_pool
    else
        return false
    end
end

-- Server side vehicle creation with optional callback
-- the CreateVehicle RPC still uses the client for creation so players must be near
function RSGCore.Functions.SpawnVehicle(source, model, coords, warp)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(ped) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        while GetVehiclePedIsIn(ped) ~= veh do
            Wait(0)
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    return veh
end

-- Server side vehicle creation with optional callback
-- the CreateAutomobile native is still experimental but doesn't use client for creation
-- doesn't work for all vehicles!
function RSGCore.Functions.CreateVehicle(source, model, coords, warp)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
    local CreateAutomobile = `CREATE_AUTOMOBILE`
    local veh = Citizen.InvokeNative(CreateAutomobile, model, coords, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
    return veh
end

-- Paychecks (standalone - don't touch)
function PaycheckInterval()
    if next(RSGCore.Players) then
        for _, Player in pairs(RSGCore.Players) do
            if Player then
                local payment = RSGShared.Jobs[Player.PlayerData.job.name]['grades'][tostring(Player.PlayerData.job.grade.level)].payment
                if not payment then payment = Player.PlayerData.job.payment end
                if Player.PlayerData.job and payment > 0 and (RSGShared.Jobs[Player.PlayerData.job.name].offDutyPay or Player.PlayerData.job.onduty) then
                    if RSGCore.Config.Money.PayCheckSociety then
                        local account = exports['rsg-bossmenu']:GetAccount(Player.PlayerData.job.name)
                        if account ~= 0 then -- Checks if player is employed by a society
                            if account < payment then -- Checks if company has enough money to pay society
                                TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, Lang:t('error.company_too_poor'), 'error')
                            else
                                Player.Functions.AddMoney(RSGConfig.Money.PayCheckBank, payment)
                                exports['rsg-bossmenu']:RemoveMoney(Player.PlayerData.job.name, payment)
                                TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, Lang:t('info.received_paycheck', {value = payment}))
                            end
                        else
                            Player.Functions.AddMoney(RSGConfig.Money.PayCheckBank, payment)
                            TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, Lang:t('info.received_paycheck', {value = payment}))
                        end
                    else
                        Player.Functions.AddMoney(RSGConfig.Money.PayCheckBank, payment)
                        TriggerClientEvent('RSGCore:Notify', Player.PlayerData.source, Lang:t('info.received_paycheck', {value = payment}))
                    end
                end
            end
        end
    end
    SetTimeout(RSGCore.Config.Money.PayCheckTimeOut * (60 * 1000), PaycheckInterval)
end

-- Callback Functions --

-- Client Callback
function RSGCore.Functions.TriggerClientCallback(name, source, cb, ...)
    RSGCore.ClientCallbacks[name] = cb
    TriggerClientEvent('RSGCore:Client:TriggerClientCallback', source, name, ...)
end

-- Server Callback
function RSGCore.Functions.CreateCallback(name, cb)
    RSGCore.ServerCallbacks[name] = cb
end

function RSGCore.Functions.TriggerCallback(name, source, cb, ...)
    if not RSGCore.ServerCallbacks[name] then return end
    RSGCore.ServerCallbacks[name](source, cb, ...)
end

-- Items

function RSGCore.Functions.CreateUseableItem(item, data)
    RSGCore.UsableItems[item] = data
end

function RSGCore.Functions.CanUseItem(item)
    return RSGCore.UsableItems[item]
end

function RSGCore.Functions.UseItem(source, item)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    exports['rsg-inventory']:UseItem(source, item)
end

-- Kick Player

function RSGCore.Functions.Kick(source, reason, setKickReason, deferrals)
    reason = '\n' .. reason .. '\n🔸 Check our Discord for further information: ' .. RSGCore.Config.Server.Discord
    if setKickReason then
        setKickReason(reason)
    end
    CreateThread(function()
        if deferrals then
            deferrals.update(reason)
            Wait(2500)
        end
        if source then
            DropPlayer(source, reason)
        end
        for _ = 0, 4 do
            while true do
                if source then
                    if GetPlayerPing(source) >= 0 then
                        break
                    end
                    Wait(100)
                    CreateThread(function()
                        DropPlayer(source, reason)
                    end)
                end
            end
            Wait(5000)
        end
    end)
end

-- Check if player is whitelisted, kept like this for backwards compatibility or future plans

function RSGCore.Functions.IsWhitelisted(source)
    if not RSGCore.Config.Server.Whitelist then return true end
    if RSGCore.Functions.HasPermission(source, RSGCore.Config.Server.WhitelistPermission) then return true end
    return false
end

-- Setting & Removing Permissions

function RSGCore.Functions.AddPermission(source, permission)
    if not IsPlayerAceAllowed(source, permission) then
        ExecuteCommand(('add_principal player.%s rsgcore.%s'):format(source, permission))
        RSGCore.Commands.Refresh(source)
    end
end

function RSGCore.Functions.RemovePermission(source, permission)
    if permission then
        if IsPlayerAceAllowed(source, permission) then
            ExecuteCommand(('remove_principal player.%s rsgcore.%s'):format(source, permission))
            RSGCore.Commands.Refresh(source)
        end
    else
        for _, v in pairs(RSGCore.Config.Server.Permissions) do
            if IsPlayerAceAllowed(source, v) then
                ExecuteCommand(('remove_principal player.%s rsgcore.%s'):format(source, v))
                RSGCore.Commands.Refresh(source)
            end
        end
    end
end

-- Checking for Permission Level

function RSGCore.Functions.HasPermission(source, permission)
    if type(permission) == "string" then
        if IsPlayerAceAllowed(source, permission) then return true end
    elseif type(permission) == "table" then
        for _, permLevel in pairs(permission) do
            if IsPlayerAceAllowed(source, permLevel) then return true end
        end
    end

    return false
end

function RSGCore.Functions.GetPermission(source)
    local src = source
    local perms = {}
    for _, v in pairs (RSGCore.Config.Server.Permissions) do
        if IsPlayerAceAllowed(src, v) then
            perms[v] = true
        end
    end
    return perms
end

-- Opt in or out of admin reports

function RSGCore.Functions.IsOptin(source)
    local license = RSGCore.Functions.GetIdentifier(source, 'license')
    if not license or not RSGCore.Functions.HasPermission(source, 'admin') then return false end
    local Player = RSGCore.Functions.GetPlayer(source)
    return Player.PlayerData.optin
end

function RSGCore.Functions.ToggleOptin(source)
    local license = RSGCore.Functions.GetIdentifier(source, 'license')
    if not license or not RSGCore.Functions.HasPermission(source, 'admin') then return end
    local Player = RSGCore.Functions.GetPlayer(source)
    Player.PlayerData.optin = not Player.PlayerData.optin
    Player.Functions.SetPlayerData('optin', Player.PlayerData.optin)
end

-- Check if player is banned

function RSGCore.Functions.IsPlayerBanned(source)
    local plicense = RSGCore.Functions.GetIdentifier(source, 'license')
    local result = MySQL.single.await('SELECT * FROM bans WHERE license = ?', { plicense })
    if not result then return false end
    if os.time() < result.expire then
        local timeTable = os.date('*t', tonumber(result.expire))
        return true, 'You have been banned from the server:\n' .. result.reason .. '\nYour ban expires ' .. timeTable.day .. '/' .. timeTable.month .. '/' .. timeTable.year .. ' ' .. timeTable.hour .. ':' .. timeTable.min .. '\n'
    else
        MySQL.query('DELETE FROM bans WHERE id = ?', { result.id })
    end
    return false
end

-- Check for duplicate license

function RSGCore.Functions.IsLicenseInUse(license)
    local players = GetPlayers()
    for _, player in pairs(players) do
        local identifiers = GetPlayerIdentifiers(player)
        for _, id in pairs(identifiers) do
            if string.find(id, 'license') then
                if id == license then
                    return true
                end
            end
        end
    end
    return false
end

-- Utility functions

function RSGCore.Functions.HasItem(source, items, amount)
    if GetResourceState('rsg-inventory') == 'missing' then return end
    return exports['rsg-inventory']:HasItem(source, items, amount)
end

function RSGCore.Functions.Notify(source, text, type, length)
    TriggerClientEvent('RSGCore:Notify', source, text, type, length)
end
