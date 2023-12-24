-- Event Handler

AddEventHandler('chatMessage', function(_, _, message)
    if string.sub(message, 1, 1) == '/' then
        CancelEvent()
        return
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if not RSGCore.Players[src] then return end
    local Player = RSGCore.Players[src]
    TriggerClientEvent('rsg-horses:client:FleeHorse', src)
    TriggerEvent('rsg-log:server:CreateLog', 'joinleave', 'Dropped', 'red', '**' .. GetPlayerName(src) .. '** (' .. Player.PlayerData.license .. ') left..' ..'\n **Reason:** ' .. reason)
    Player.Functions.Save()
    RSGCore.Player_Buckets[Player.PlayerData.license] = nil
    RSGCore.Players[src] = nil
end)

-- Player Connecting

local function onPlayerConnecting(name, _, deferrals)
    local src = source
    local license
    local identifiers = GetPlayerIdentifiers(src)
    deferrals.defer()

    -- Mandatory wait
    Wait(0)

    if RSGCore.Config.Server.Closed then
        if not IsPlayerAceAllowed(src, 'RSGadmin.join') then
            deferrals.done(RSGCore.Config.Server.ClosedReason)
        end
    end

    deferrals.update(string.format(Lang:t('info.checking_ban'), name))

    for _, v in pairs(identifiers) do
        if string.find(v, 'license') then
            license = v
            break
        end
    end

    -- Mandatory wait
    Wait(2500)

    deferrals.update(string.format(Lang:t('info.checking_whitelisted'), name))

    local isBanned, Reason = RSGCore.Functions.IsPlayerBanned(src)
    local isLicenseAlreadyInUse = RSGCore.Functions.IsLicenseInUse(license)
    local isWhitelist, whitelisted = RSGCore.Config.Server.Whitelist, RSGCore.Functions.IsWhitelisted(src)

    Wait(2500)

    deferrals.update(string.format(Lang:t('info.join_server'), name))

    if not license then
      deferrals.done(Lang:t('error.no_valid_license'))
    elseif isBanned then
        deferrals.done(Reason)
    elseif isLicenseAlreadyInUse and RSGCore.Config.Server.CheckDuplicateLicense then
        deferrals.done(Lang:t('error.duplicate_license'))
    elseif isWhitelist and not whitelisted then
      deferrals.done(Lang:t('error.not_whitelisted'))
    end

    deferrals.done()

    -- Add any additional defferals you may need!
end

AddEventHandler('playerConnecting', onPlayerConnecting)

-- Open & Close Server (prevents players from joining)

RegisterNetEvent('RSGCore:Server:CloseServer', function(reason)
    local src = source
    if RSGCore.Functions.HasPermission(src, 'admin') then
        reason = reason or 'No reason specified'
        RSGCore.Config.Server.Closed = true
        RSGCore.Config.Server.ClosedReason = reason
        for k in pairs(RSGCore.Players) do
            if not RSGCore.Functions.HasPermission(k, RSGCore.Config.Server.WhitelistPermission) then
                RSGCore.Functions.Kick(k, reason, nil, nil)
            end
        end
    else
        RSGCore.Functions.Kick(src, Lang:t("error.no_permission"), nil, nil)
    end
end)

RegisterNetEvent('RSGCore:Server:OpenServer', function()
    local src = source
    if RSGCore.Functions.HasPermission(src, 'admin') then
        RSGCore.Config.Server.Closed = false
    else
        RSGCore.Functions.Kick(src, Lang:t("error.no_permission"), nil, nil)
    end
end)

-- Callback Events --

-- Client Callback
RegisterNetEvent('RSGCore:Server:TriggerClientCallback', function(name, ...)
    if RSGCore.ClientCallbacks[name] then
        RSGCore.ClientCallbacks[name](...)
        RSGCore.ClientCallbacks[name] = nil
    end
end)

-- Server Callback
RegisterNetEvent('RSGCore:Server:TriggerCallback', function(name, ...)
    local src = source
    RSGCore.Functions.TriggerCallback(name, src, function(...)
        TriggerClientEvent('RSGCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

-- Player

RegisterNetEvent('RSGCore:UpdatePlayer', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local newHunger = Player.PlayerData.metadata['hunger'] - RSGCore.Config.Player.HungerRate
    local newThirst = Player.PlayerData.metadata['thirst'] - RSGCore.Config.Player.ThirstRate
    local newCleanliness = Player.PlayerData.metadata['cleanliness'] - RSGCore.Config.Player.CleanlinessRate
    if newHunger <= 0 then
        newHunger = 0
    end
    if newThirst <= 0 then
        newThirst = 0
    end
    if newCleanliness <= 0 then
        newCleanliness = 0
    end
    Player.Functions.SetMetaData('thirst', newThirst)
    Player.Functions.SetMetaData('hunger', newHunger)
    Player.Functions.SetMetaData('cleanliness', newCleanliness)
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst, newCleanliness)
    Player.Functions.Save()
end)

RegisterNetEvent('RSGCore:Server:SetMetaData', function(meta, data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if meta == 'hunger' or meta == 'thirst' or meta == 'cleanliness' then
        if data > 100 then
            data = 100
        end
    end
    Player.Functions.SetMetaData(meta, data)
    TriggerClientEvent('hud:client:UpdateNeeds', src, Player.PlayerData.metadata['hunger'], Player.PlayerData.metadata['thirst'], Player.PlayerData.metadata['cleanliness'])
end)

RegisterNetEvent('RSGCore:ToggleDuty', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.onduty then
        Player.Functions.SetJobDuty(false)
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('info.off_duty'))
    else
        Player.Functions.SetJobDuty(true)
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('info.on_duty'))
    end
    TriggerClientEvent('RSGCore:Client:SetDuty', src, Player.PlayerData.job.onduty)
end)

-- Items

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon.
RegisterNetEvent('RSGCore:Server:UseItem', function(item)
    print(string.format("%s triggered RSGCore:Server:UseItem by ID %s with the following data. This event is deprecated due to exploitation, and will be removed soon. Check qb-inventory for the right use on this event.", GetInvokingResource(), source))
    RSGCore.Debug(item)
end)

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon. function(itemName, amount, slot)
RegisterNetEvent('RSGCore:Server:RemoveItem', function(itemName, amount)
    local src = source
    print(string.format("%s triggered RSGCore:Server:RemoveItem by ID %s for %s %s. This event is deprecated due to exploitation, and will be removed soon. Adjust your events accordingly to do this server side with player functions.", GetInvokingResource(), src, amount, itemName))
end)

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon. function(itemName, amount, slot, info)
RegisterNetEvent('RSGCore:Server:AddItem', function(itemName, amount)
    local src = source
    print(string.format("%s triggered RSGCore:Server:AddItem by ID %s for %s %s. This event is deprecated due to exploitation, and will be removed soon. Adjust your events accordingly to do this server side with player functions.", GetInvokingResource(), src, amount, itemName))
end)

-- Non-Chat Command Calling (ex: rsg-adminmenu)

RegisterNetEvent('RSGCore:CallCommand', function(command, args)
    local src = source
    if not RSGCore.Commands.List[command] then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local hasPerm = RSGCore.Functions.HasPermission(src, "command."..RSGCore.Commands.List[command].name)
    if hasPerm then
        if RSGCore.Commands.List[command].argsrequired and #RSGCore.Commands.List[command].arguments ~= 0 and not args[#RSGCore.Commands.List[command].arguments] then
            TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.missing_args2'), 'error')
        else
            RSGCore.Commands.List[command].callback(src, args)
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.no_access'), 'error')
    end
end)

-- Use this for player vehicle spawning
-- Vehicle server-side spawning callback (netId)
-- use the netid on the client with the NetworkGetEntityFromNetworkId native
-- convert it to a vehicle via the NetToVeh native
RSGCore.Functions.CreateCallback('RSGCore:Server:SpawnVehicle', function(source, cb, model, coords, warp)
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
    cb(NetworkGetNetworkIdFromEntity(veh))
end)

-- Use this for long distance vehicle spawning
-- vehicle server-side spawning callback (netId)
-- use the netid on the client with the NetworkGetEntityFromNetworkId native
-- convert it to a vehicle via the NetToVeh native
RSGCore.Functions.CreateCallback('RSGCore:Server:CreateVehicle', function(source, cb, model, coords, warp)
    model = type(model) == 'string' and GetHashKey(model) or model
    if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
    local CreateAutomobile = GetHashKey("CREATE_AUTOMOBILE")
    local veh = Citizen.InvokeNative(CreateAutomobile, model, coords, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
    cb(NetworkGetNetworkIdFromEntity(veh))
end)
