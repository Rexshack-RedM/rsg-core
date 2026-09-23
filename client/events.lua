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
    if RSGConfig.Server.PVP then
        Citizen.InvokeNative(0xF808475FA571D823, true)
        SetRelationshipBetweenGroups(5, `PLAYER`, `PLAYER`)
    end
    if RSGConfig.Player.RevealMap then
        SetMinimapHideFow(true)
    end
    Citizen.InvokeNative(0x39363DFD04E91496, PlayerId(), true) -- enable mercy kill
    Citizen.InvokeNative(0x8899C244EBCF70DE, PlayerPedId(), 0.0) -- SetPlayerHealthRechargeMultiplier
    Citizen.InvokeNative(0xDE1B1907A83A1550, PlayerPedId(), 0.0) -- SetHealthRechargeMultiplier
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('isLoggedIn', false, false)
end)

RegisterNetEvent('RSGCore:Client:PvpHasToggled', function(pvp_state)
    RSGConfig.Server.PVP = pvp_state
    SetCanAttackFriendly(PlayerPedId(), pvp_state, false)
    NetworkSetFriendlyFireOption(pvp_state)
end)

-- Teleport Commands

RegisterNetEvent('RSGCore:Command:TeleportToPlayer', function(coords)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z) 
end)

RegisterNetEvent('RSGCore:Command:TeleportToCoords', function(x, y, z, h)
    SetEntityCoords(cache.ped, x, y, z) 
end)

RegisterNetEvent('RSGCore:Command:GoToMarker', function()
    if not IsWaypointActive() then
        lib.notify({ title = Lang:t('error.no_waypoint'), type = 'error', duration = 5000 })
        return
    end
    local coords = GetWaypointCoords()
    local groundZ = GetHeightmapBottomZForPosition(coords.x, coords.y)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    SetEntityCoords(cache.ped, coords.x, coords.y, groundZ + 3.0)
    PlacePedOnGroundProperly(cache.ped, coords)

    if cache.mount then
        SetEntityCoords(cache.mount, coords.x, coords.y, groundZ + 3.0)
        PlacePedOnGroundProperly(cache.mount, coords)
        Citizen.InvokeNative(0x028F76B6E78246EB, cache.ped, cache.mount, -1)
    end

    if vehicle ~= 0 then -- GetVehiclePedIsIn returns 0 (truthy in Lua) when not in a vehicle
        SetEntityCoords(vehicle, coords.x, coords.y, groundZ + 3.0)
        PlacePedOnGroundProperly(vehicle, coords)
        Citizen.InvokeNative(0x028F76B6E78246EB, cache.ped, vehicle, -1)
    end

    lib.notify({ title = Lang:t('success.teleported_waypoint'), type = 'success', duration = 5000 })
end)

-- Noclip Command
RegisterNetEvent('RSGCore:Command:ToggleNoClip', function()
    ExecuteCommand('txAdmin:menu:noClipToggle')
end)

-- Vehicle Commands

RegisterNetEvent('RSGCore:Command:SpawnVehicle', function(vehName)
    local ped = cache.ped
    local hash = joaat(vehName)
    if not IsModelInCdimage(hash) then
        return lib.notify({ title = Lang:t('error.invalid_model'), type = 'error', duration = 5000 })
    end
    lib.requestModel(hash) -- has a built-in timeout (the old loop could hang forever)

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
    local ped = cache.ped
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

-- Other stuff

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    RSGCore.PlayerData = val
end)

RegisterNetEvent('RSGCore:Player:UpdatePlayerData', function()
    TriggerServerEvent('RSGCore:UpdatePlayer')
end)

-- Callback Events --

-- Client Callback
RegisterNetEvent('RSGCore:Client:TriggerClientCallback', function(name, ...)
    RSGCore.Functions.TriggerClientCallback(name, function(...)
        TriggerServerEvent('RSGCore:Server:TriggerClientCallback', name, ...)
    end, ...)
end)

-- Server Callback
RegisterNetEvent('RSGCore:Client:TriggerCallback', function(name, ...)
    if RSGCore.ServerCallbacks[name] then
        RSGCore.ServerCallbacks[name](...)
        RSGCore.ServerCallbacks[name] = nil
    end
end)

-- Me command
local ME_DURATION = 10000
local ME_MAX_DISTANCE = 25.0

RegisterNetEvent('RSGCore:Command:ShowMe3D', function(senderId, msg)
    local sender = GetPlayerFromServerId(senderId)
    if sender == -1 then return end -- sender not in scope
    CreateThread(function()
        local endTime = GetGameTimer() + ME_DURATION
        while GetGameTimer() < endTime do
            local targetPed = GetPlayerPed(sender)
            if not DoesEntityExist(targetPed) then return end
            local tCoords = GetEntityCoords(targetPed)
            if #(GetEntityCoords(cache.ped) - tCoords) < ME_MAX_DISTANCE then
                RSGCore.Functions.DrawText3D(tCoords.x, tCoords.y, tCoords.z + 1.0, msg)
            end
            Wait(0)
        end
    end)
end)

-- Listen to Shared being updated
RegisterNetEvent('RSGCore:Client:OnSharedUpdate', function(tableName, key, value)
    RSGCore.Shared[tableName][key] = value
    TriggerEvent('RSGCore:Client:UpdateObject')
end)

RegisterNetEvent('RSGCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    for key, value in pairs(values) do
        RSGCore.Shared[tableName][key] = value
    end
    TriggerEvent('RSGCore:Client:UpdateObject')
end)

RegisterNetEvent('RSGCore:Client:SharedUpdate', function(table)
    RSGCore.Shared = table
end)

if RSGConfig.HidePlayerNames then
    CreateThread(function()
        while true do
            Wait(5000)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                SetPedPromptName(ped, "Stranger (" .. tostring(GetPlayerServerId(player)) .. ")")
            end
        end
    end)
end

-- csrf protection

local csrfToken = nil

local function GenerateCSRFToken() 
    local timeout = 500
    while csrfToken and timeout > 0 do
        timeout = timeout - 1
        Wait(0)
    end
    
    local token = tostring(math.random(100000, 999999)) .. GetGameTimer()
    csrfToken = token

    return token
end
exports('GenerateCSRFToken', GenerateCSRFToken)

RegisterNUICallback('validateCSRF', function(data, cb)
    if csrfToken and csrfToken == data.clientToken then
        csrfToken = nil
        cb({ valid = true })
    else
        TriggerServerEvent('RSGCore:Server:KickCSRF')
        cb({ valid = false })
    end
end)
