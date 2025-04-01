-- Place Ped on ground properly
local function PlacePedOnGroundProperly(ped, coord)
    local x, y, z = table.unpack(coord)
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)

    if found then
        SetEntityCoordsNoOffset(ped, x, y, groundz + normal.z, true)
    end
end

-- Player load and unload handling
-- New method for checking if logged in across all scripts (optional)
-- if LocalPlayer.state['isLoggedIn'] then
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    ShutdownLoadingScreenNui()
    LocalPlayer.state:set('isLoggedIn', true, false)
    --if not RSGCore.Config.Server.PVP then return end
    --SetCanAttackFriendly(PlayerPedId(), true, false)
    --NetworkSetFriendlyFireOption(true)
    if RSGConfig.EnablePVP then
        Citizen.InvokeNative(0xF808475FA571D823, true)
        SetRelationshipBetweenGroups(5, `PLAYER`, `PLAYER`)
    end
    if RSGConfig.Player.RevealMap then
        SetMinimapHideFow(true)
    end
    Citizen.InvokeNative(0x39363DFD04E91496, PlayerId(), true) -- enable mercy kil
    Citizen.InvokeNative(0x8899C244EBCF70DE, PlayerPedId(), 0.0) -- SetPlayerHealthRechargeMultiplier
    Citizen.InvokeNative(0xDE1B1907A83A1550, PlayerPedId(), 0.0) -- SetHealthRechargeMultiplier
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('isLoggedIn', false, false)
end)

RegisterNetEvent('RSGCore:Client:PvpHasToggled', function(pvp_state)
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
    local coords = GetWaypointCoords()
    local groundZ = GetHeightmapBottomZForPosition(coords.x, coords.y)
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not IsWaypointActive() then
        lib.notify({ title = Lang:t("error.no_waypoint"), type = 'error', duration = 5000 })
        return
    end

    SetEntityCoords(cache.ped, coords.x, coords.y, groundZ + 3.0)
    PlacePedOnGroundProperly(cache.ped, coords)

    if cache.mount then
        SetEntityCoords(cache.mount, coords.x, coords.y, groundZ + 3.0)
        PlacePedOnGroundProperly(cache.mount, coords)
        Citizen.InvokeNative(0x028F76B6E78246EB, cache.ped, cache.mount, -1)
    end

    if vehicle then
        SetEntityCoords(vehicle, coords.x, coords.y, groundZ + 3.0)
        PlacePedOnGroundProperly(vehicle, coords)
        Citizen.InvokeNative(0x028F76B6E78246EB, cache.ped, vehicle, -1)
    end

    lib.notify({ title = Lang:t("success.teleported_waypoint"), type = 'success', duration = 5000 })
end)

-- Noclip Command
RegisterNetEvent('RSGCore:Command:ToggleNoClip', function()
    ExecuteCommand('txAdmin:menu:noClipToggle')
end)

-- Vehicle Commands

RegisterNetEvent('RSGCore:Command:SpawnVehicle', function(vehName)
    local ped = PlayerPedId()
    local hash = joaat(vehName)
    local veh = GetVehiclePedIsUsing(ped)
    if not IsModelInCdimage(hash) then return end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end

    if IsPedInAnyVehicle(ped) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end

    local vehicle = CreateVehicle(hash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 0.0)
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
        local vehicles = GetGamePool('CVehicle')
        for _, v in pairs(vehicles) do
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

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon.
RegisterNetEvent('RSGCore:Client:UseItem', function(item)
    RSGCore.Debug(string.format('%s triggered RSGCore:Client:UseItem by ID %s with the following data. This event is deprecated due to exploitation, and will be removed soon. Check qb-inventory for the right use on this event.', GetInvokingResource(), GetPlayerServerId(PlayerId())))
    RSGCore.Debug(item)
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
local function Draw3DText(coords, str)
    local onScreen, worldX, worldY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoord()
    local scale = 200 / (GetGameplayCamFov() * #(camCoords - coords))

    if onScreen then
        -- Set the text color using SetTextColor (RedM version)
        SetTextColor(255, 255, 255, 255) -- White color with full opacity

        -- Set the text scale (RedM requires slight adjustment)
        SetTextScale(0.0, 0.5 * scale) -- Adjust the scale values as needed

        -- Set the font to the desired font using SetTextFontForCurrentCommand
        SetTextFontForCurrentCommand(2) -- Use appropriate font ID here

        -- Center the text
        SetTextCentre(true)

        -- Create the text to be displayed using a variable string
        local varString = CreateVarString(10, "LITERAL_STRING", str)

        -- Display the text at the world coordinates (converted to screen coordinates)
        DisplayText(varString, worldX, worldY)
    end
end

RegisterNetEvent('RSGCore:Command:ShowMe3D', function(senderId, msg)
    local sender = GetPlayerFromServerId(senderId)
    CreateThread(function()
        local displayTime = 10000 + GetGameTimer()
        while displayTime > GetGameTimer() do
            local targetPed = GetPlayerPed(sender)
            local tCoords = GetEntityCoords(targetPed)
            Draw3DText(tCoords, msg)
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
