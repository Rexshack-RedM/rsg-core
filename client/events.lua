-- Place Ped on ground properly
local function PlacePedOnGroundProperly(ped, coord)
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(coord.x, coord.y, coord.z)
    if found then
        SetEntityCoordsNoOffset(ped, coord.x, coord.y, groundz + normal.z, true)
    end
end

-- Player load and unload handling
-- New method for checking if logged in across all scripts (optional)
-- if LocalPlayer.state['isLoggedIn'] then
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    ShutdownLoadingScreenNui()
    LocalPlayer.state:set('isLoggedIn', true, false)
    -- player relationships / friendly fire are handled by the loop in client/pvp.lua
    if RSGConfig.Player.RevealMap then
        SetMinimapHideFow(true)
    end
    Citizen.InvokeNative(0x39363DFD04E91496, PlayerId(), true) -- enable mercy kill
    Citizen.InvokeNative(0x8899C244EBCF70DE, PlayerId(), 0.0) -- SetPlayerHealthRechargeMultiplier (takes a player, not a ped)
    Citizen.InvokeNative(0xDE1B1907A83A1550, PlayerPedId(), 0.0) -- SetHealthRechargeMultiplier
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('isLoggedIn', false, false)
end)

RegisterNetEvent('RSGCore:Client:PvpHasToggled', function(pvp_state)
    -- client/pvp.lua applies the natives on its next tick (and keeps them applied)
    RSGConfig.Server.PVP = pvp_state == true
    local on = RSGConfig.Server.PVP
    RSGCore.Functions.Notify({
        id = 'rsg_pvp_toggle',
        title = locale(on and 'info.pvp_on_title' or 'info.pvp_off_title'),
        description = locale(on and 'info.pvp_on' or 'info.pvp_off'),
        type = on and 'error' or 'success',
        icon = on and 'fa-solid fa-gun' or 'fa-solid fa-shield',
        duration = 8000,
    })
end)

-- Teleport Commands

-- /tpm safeguards: the destination is usually unstreamed, so the heightmap Z can be below the real ground.
-- We freeze the entity, stream the area in, probe for real ground from above, and only then place it.
-- On failure the player is returned to where they started instead of falling under the map.
local tpmBusy = false

local function RequestGroundAt(entity, x, y)
    local startZ = 1000.0
    local deadline = GetGameTimer() + 8000
    local z = startZ
    while GetGameTimer() < deadline do
        SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
        RequestCollisionAtCoord(x, y, z)
        SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
        Wait(0)
        local found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found and groundZ and groundZ > -150.0 then
            -- make sure collision is really there before trusting the value
            local tries = 0
            while not HasCollisionLoadedAroundEntity(entity) and tries < 50 do
                RequestCollisionAtCoord(x, y, groundZ)
                Wait(20)
                tries = tries + 1
            end
            return groundZ
        end
        z = z - 25.0
        if z < -100.0 then z = startZ end -- sweep again; the world may have streamed in meanwhile
    end
    return nil
end

-- Shared safe teleport used by /tp and /tpm. Moves the carrier (vehicle > mount > ped) so riders go with it.
-- z == nil: probe for real ground at x,y first. z given: freeze and wait for collision before placing.
-- On failure the player is returned to where they started.
local function SafeTeleport(x, y, z, h, successTitle)
    if tpmBusy then return end
    tpmBusy = true

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local mount = GetMount(ped)
    local entity = (vehicle ~= 0 and vehicle) or (mount and mount ~= 0 and mount) or ped
    local startCoords = GetEntityCoords(entity)

    FreezeEntityPosition(entity, true)
    SetEntityInvincible(ped, true)
    if entity ~= ped then SetEntityInvincible(entity, true) end

    local groundZ
    if z then
        groundZ = z
        SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
        RequestCollisionAtCoord(x, y, z)
        SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
        local deadline = GetGameTimer() + 5000
        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < deadline do
            RequestCollisionAtCoord(x, y, z)
            Wait(20)
        end
    else
        groundZ = RequestGroundAt(entity, x, y)
    end

    if groundZ then
        local placeZ = z and groundZ or (groundZ + 1.0)
        SetEntityCoordsNoOffset(entity, x, y, placeZ, false, false, false)
        if h then SetEntityHeading(entity, h + 0.0) end
        if not z then
            if entity ~= ped then PlacePedOnGroundProperly(ped, vector3(x, y, placeZ)) end
            PlacePedOnGroundProperly(entity, vector3(x, y, placeZ))
        end
        if mount and mount ~= 0 and entity == mount then
            Citizen.InvokeNative(0x028F76B6E78246EB, ped, mount, -1)
        elseif vehicle ~= 0 then
            Citizen.InvokeNative(0x028F76B6E78246EB, ped, vehicle, -1)
        end
    else
        SetEntityCoordsNoOffset(entity, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    end

    ClearFocus()
    Wait(250)
    FreezeEntityPosition(entity, false)
    SetEntityInvincible(ped, false)
    if entity ~= ped then SetEntityInvincible(entity, false) end

    if groundZ and not z then
        -- watchdog: if we still dropped below the ground, snap back up to the ground we found
        CreateThread(function()
            for _ = 1, 10 do
                Wait(300)
                local pos = GetEntityCoords(entity)
                if pos.z < groundZ - 5.0 then
                    SetEntityCoordsNoOffset(entity, x, y, groundZ + 1.5, false, false, false)
                end
            end
        end)
    end

    if groundZ then
        if successTitle then RSGCore.Functions.Notify({ title = successTitle, type = 'success', duration = 5000 }) end
    else
        RSGCore.Functions.Notify({ title = locale('error.tpm_no_ground'), type = 'error', duration = 6000 })
    end
    tpmBusy = false
end

RegisterNetEvent('RSGCore:Command:GoToMarker', function()
    if tpmBusy then return end
    if not IsWaypointActive() then
        RSGCore.Functions.Notify({ title = locale('error.no_waypoint'), type = 'error', duration = 5000 })
        return
    end
    local coords = GetWaypointCoords()
    SafeTeleport(coords.x, coords.y, nil, nil, locale('success.teleported_waypoint'))
end)

RegisterNetEvent('RSGCore:Command:TeleportToPlayer', function(coords)
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return end
    SafeTeleport(coords.x, coords.y, coords.z, nil)
end)

RegisterNetEvent('RSGCore:Command:TeleportToCoords', function(x, y, z, h)
    if type(x) ~= 'number' or type(y) ~= 'number' then return end
    SafeTeleport(x, y, type(z) == 'number' and z or nil, type(h) == 'number' and h or nil)
end)

-- Noclip Command
RegisterNetEvent('RSGCore:Command:ToggleNoClip', function()
    ExecuteCommand('txAdmin:menu:noClipToggle')
end)

-- Vehicle Commands

RegisterNetEvent('RSGCore:Command:SpawnVehicle', function(vehName)
    local ped = PlayerPedId()
    local hash = joaat(vehName)
    if not IsModelInCdimage(hash) then
        return RSGCore.Functions.Notify({ title = locale('error.invalid_model'), type = 'error', duration = 5000 })
    end
    RSGCore.Functions.RequestModel(hash) -- has a built-in timeout (the old loop could hang forever)

    local veh = GetVehiclePedIsUsing(ped)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end

    local vehicle = CreateVehicle(hash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('RSGCore:Command:DeleteVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsUsing(ped)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    else
        local pcoords = GetEntityCoords(ped)
        for _, v in ipairs(GetGamePool('CVehicle')) do
            if #(pcoords - GetEntityCoords(v)) <= 5.0 then
                SetEntityAsMissionEntity(v, true, true)
                DeleteVehicle(v)
            end
        end
    end
end)

-- Notify events
-- Preferred: TriggerClientEvent('RSGCore:Client:Notify', src, { title, description, type, duration, icon })
RegisterNetEvent('RSGCore:Client:Notify', function(...)
    RSGCore.Functions.Notify(...)
end)

-- Legacy: TriggerClientEvent('RSGCore:Notify', src, text, type, duration)
RegisterNetEvent('RSGCore:Notify', function(...)
    RSGCore.Functions.Notify(...)
end)

-- Other stuff

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    RSGCore.PlayerData = val
end)

-- Callback Events --

-- Client Callback
RegisterNetEvent('RSGCore:Client:TriggerClientCallback', function(name, requestId, ...)
    RSGCore.Functions.TriggerClientCallback(name, function(...)
        TriggerServerEvent('RSGCore:Server:TriggerClientCallback', requestId, ...)
    end, ...)
end)

-- Server Callback (keyed by request id)
RegisterNetEvent('RSGCore:Client:TriggerCallbackId', function(requestId, ...)
    local cb = RSGCore.PendingCallbacks[requestId]
    if not cb then return end
    RSGCore.PendingCallbacks[requestId] = nil
    cb(...)
end)

-- Me command
local ME_DURATION = 10000
local ME_MAX_DISTANCE = 25.0
local meToken = {} -- [senderId] = latest message number, so a new /me replaces the old one instead of overlapping

RegisterNetEvent('RSGCore:Command:ShowMe3D', function(senderId, msg)
    local sender = GetPlayerFromServerId(senderId)
    if sender == -1 then return end -- sender not in scope
    local token = (meToken[senderId] or 0) + 1
    meToken[senderId] = token
    CreateThread(function()
        local endTime = GetGameTimer() + ME_DURATION
        while meToken[senderId] == token and GetGameTimer() < endTime do
            local targetPed = GetPlayerPed(sender)
            if not DoesEntityExist(targetPed) then return end
            local tCoords = GetEntityCoords(targetPed)
            if #(GetEntityCoords(PlayerPedId()) - tCoords) < ME_MAX_DISTANCE then
                RSGCore.Functions.DrawText3D(tCoords.x, tCoords.y, tCoords.z + 1.0, msg)
            end
            Wait(0)
        end
    end)
end)

-- Listen to Shared being updated
RegisterNetEvent('RSGCore:Client:OnSharedUpdate', function(tableName, key, value)
    if not RSGCore.Shared[tableName] then return end
    RSGCore.Shared[tableName][key] = value
    TriggerEvent('RSGCore:Client:UpdateObject')
end)

RegisterNetEvent('RSGCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    if not RSGCore.Shared[tableName] then return end
    for key, value in pairs(values) do
        RSGCore.Shared[tableName][key] = value or nil -- false marks an entry removed at runtime
    end
    TriggerEvent('RSGCore:Client:UpdateObject')
end)

if RSGConfig.HidePlayerNames then
    CreateThread(function()
        while true do
            Wait(5000)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                SetPedPromptName(ped, locale('info.stranger', GetPlayerServerId(player)))
            end
        end
    end)
end

-- csrf protection

-- Note: this only protects NUI pages against replayed or mixed-up requests. It runs on the player's own
-- machine, so it is not a security boundary: servers must still validate every event.
local TOKEN_LIFETIME = 30000
local csrfTokens = {} -- [token] = expiry; several requests can be pending at once

local function hasPendingToken()
    local now = GetGameTimer()
    for token, expires in pairs(csrfTokens) do
        if expires < now then csrfTokens[token] = nil end
    end
    return next(csrfTokens) ~= nil
end

local function GenerateCSRFToken()
    local parts = {}
    for i = 1, 4 do parts[i] = ('%08x'):format(math.random(0, 0x7fffffff)) end
    local token = table.concat(parts)
    csrfTokens[token] = GetGameTimer() + TOKEN_LIFETIME
    return token
end
exports('GenerateCSRFToken', GenerateCSRFToken)

local csrfStrikes = 0
RegisterNUICallback('validateCSRF', function(data, cb)
    local pending = hasPendingToken()
    local token = type(data) == 'table' and data.clientToken
    if token and csrfTokens[token] then
        csrfTokens[token] = nil -- single use
        csrfStrikes = 0
        cb({ valid = true })
    elseif not pending then
        -- no token pending: a duplicate or late callback, not an attack. Reject it without kicking.
        cb({ valid = false })
    else
        -- a token is pending and the supplied one is wrong; only kick on repeated mismatches
        csrfStrikes = csrfStrikes + 1
        if csrfStrikes >= 2 then
            TriggerServerEvent('RSGCore:Server:KickCSRF')
        end
        cb({ valid = false })
    end
end)
