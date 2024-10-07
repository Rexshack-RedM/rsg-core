RSGCore.Functions = {}

-- Callbacks

function RSGCore.Functions.CreateClientCallback(name, cb)
    RSGCore.ClientCallbacks[name] = cb
end

function RSGCore.Functions.TriggerClientCallback(name, cb, ...)
    if not RSGCore.ClientCallbacks[name] then return end
    RSGCore.ClientCallbacks[name](cb, ...)
end

function RSGCore.Functions.TriggerCallback(name, cb, ...)
    RSGCore.ServerCallbacks[name] = cb
    TriggerServerEvent('RSGCore:Server:TriggerCallback', name, ...)
end

function RSGCore.Debug(resource, obj, depth)
    TriggerServerEvent('RSGCore:DebugSomething', resource, obj, depth)
end

-- Player

function RSGCore.Functions.GetPlayerData(cb)
    if not cb then return RSGCore.PlayerData end
    cb(RSGCore.PlayerData)
end

function RSGCore.Functions.GetCoords(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

function RSGCore.Functions.HasItem(items, amount)
    return exports['rsg-inventory']:HasItem(items, amount)
end

---@param entity number - The entity to look at
---@param timeout number - The time in milliseconds before the function times out
---@param speed number - The speed at which the entity should turn
---@return number - The time at which the entity was looked at
function RSGCore.Functions.LookAtEntity(entity, timeout, speed)
    local involved = GetInvokingResource()
    if not DoesEntityExist(entity) then
        turnPromise:reject(involved .. ' :^1  Entity does not exist')
        return turnPromise.value
    end
    if not type(entity) == 'number' then
        turnPromise:reject(involved .. ' :^1  Entity must be a number')
        return turnPromise.value
    end
    if not type(speed) == 'number' then
        turnPromise:reject(involved .. ' :^1  Speed must be a number')
        return turnPromise.value
    end
    if speed > 5.0 then speed = 5.0 end
    if timeout > 5000 then timeout = 5000 end
    local ped = PlayerPedId()
    local playerPos = GetEntityCoords(ped)
    local targetPos = GetEntityCoords(entity)
    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y
    local targetHeading = GetHeadingFromVector_2d(dx, dy)
    local turnSpeed = speed
    local startTimeout = GetGameTimer()
    while true do
        local currentHeading = GetEntityHeading(ped)
        local diff = targetHeading - currentHeading
        if math.abs(diff) < 2 then
            break
        end
        if diff < -180 then
            diff = diff + 360
        elseif diff > 180 then
            diff = diff - 360
        end
        turnSpeed = speed + (2.5 - speed) * (1 - math.abs(diff) / 180)
        if diff > 0 then
            currentHeading = currentHeading + turnSpeed
        else
            currentHeading = currentHeading - turnSpeed
        end
        SetEntityHeading(ped, currentHeading)
        Wait(0)
        if (startTimeout + timeout) < GetGameTimer() then break end
    end
    SetEntityHeading(ped, targetHeading)
end

-- Function to run an animation
---@deprecated use lib.requestAnimDict from ox_lib, and the TaskPlayAnim and RemoveAnimDict natives directly
--- @param animDic string: The name of the animation dictionary
--- @param animName string - The name of the animation within the dictionary
--- @param duration number - The duration of the animation in milliseconds. -1 will play the animation indefinitely
--- @param upperbodyOnly boolean - If true, the animation will only affect the upper body of the ped
--- @return number - The timestamp indicating when the animation concluded. For animations set to loop indefinitely, this will still return the maximum duration of the animation.
function RSGCore.Functions.PlayAnim(animDict, animName, upperbodyOnly, duration)
    local flags = upperbodyOnly and 16 or 0
    local runTime = duration or -1
    lib.playAnim(cache.ped, animDict, animName, 8.0, 3.0, runTime, flags, 0.0, false, false, true)
end

function RSGCore.Functions.IsWearingGloves()
    local ped = PlayerPedId()
    local armIndex = GetPedDrawableVariation(ped, 3)
    local model = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then
        if RSGCore.Shared.MaleNoGloves[armIndex] then
            return false
        end
    else
        if RSGCore.Shared.FemaleNoGloves[armIndex] then
            return false
        end
    end
    return true
end

-- World Getters

function RSGCore.Functions.GetVehicles()
    return GetGamePool('CVehicle')
end

function RSGCore.Functions.GetObjects()
    return GetGamePool('CObject')
end

function RSGCore.Functions.GetPlayers()
    return GetActivePlayers()
end

function RSGCore.Functions.GetPlayersFromCoords(coords, distance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    distance = distance or 5
    local closePlayers = {}
    for _, player in ipairs(players) do
        local targetCoords = GetEntityCoords(GetPlayerPed(player))
        local targetdistance = #(targetCoords - coords)
        if targetdistance <= distance then
            closePlayers[#closePlayers + 1] = player
        end
    end
    return closePlayers
end

function RSGCore.Functions.GetClosestPlayer(coords)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local closestPlayers = RSGCore.Functions.GetPlayersFromCoords(coords)
    local closestDistance = -1
    local closestPlayer = -1
    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() and closestPlayers[i] ~= -1 then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function RSGCore.Functions.GetPeds(ignoreList)
    local pedPool = GetGamePool('CPed')
    local peds = {}
    local ignoreTable = {}
    ignoreList = ignoreList or {}
    for i = 1, #ignoreList do
        ignoreTable[ignoreList[i]] = true
    end
    for i = 1, #pedPool do
        if not ignoreTable[pedPool[i]] then
            peds[#peds + 1] = pedPool[i]
        end
    end
    return peds
end

function RSGCore.Functions.GetClosestPed(coords, ignoreList)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    ignoreList = ignoreList or {}
    local peds = RSGCore.Functions.GetPeds(ignoreList)
    local closestDistance = -1
    local closestPed = -1
    for i = 1, #peds, 1 do
        local pedCoords = GetEntityCoords(peds[i])
        local distance = #(pedCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestPed = peds[i]
            closestDistance = distance
        end
    end
    return closestPed, closestDistance
end

function RSGCore.Functions.GetClosestVehicle(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    return closestVehicle, closestDistance
end

function RSGCore.Functions.GetClosestObject(coords)
    local ped = PlayerPedId()
    local objects = GetGamePool('CObject')
    local closestDistance = -1
    local closestObject = -1
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    for i = 1, #objects, 1 do
        local objectCoords = GetEntityCoords(objects[i])
        local distance = #(objectCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestObject = objects[i]
            closestDistance = distance
        end
    end
    return closestObject, closestDistance
end

-- Vehicle

---@deprecated use lib.requestModel from ox_lib
RSGCore.Functions.LoadModel = lib.requestModel

---@deprecated use qbx.spawnVehicle from modules/lib.lua
---@param model string|number
---@param cb? fun(vehicle: number)
---@param coords? vector4 player position if not specified
---@param isnetworked? boolean defaults to true
---@param teleportInto boolean teleport player to driver seat if true
function RSGCore.Functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local playerCoords = GetEntityCoords(cache.ped)
    local combinedCoords = vec4(playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(cache.ped))
    coords = type(coords) == 'table' and vec4(coords.x, coords.y, coords.z, coords.w or combinedCoords.w) or coords or combinedCoords
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end

    isnetworked = isnetworked == nil or isnetworked
    lib.requestModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetModelAsNoLongerNeeded(model)
    if teleportInto then TaskWarpPedIntoVehicle(cache.ped, veh, -1) end
    if cb then cb(veh) end
end

function RSGCore.Functions.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function RSGCore.Functions.GetPlate(vehicle)
    if vehicle == 0 then return end
    return RSGCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
end

function RSGCore.Functions.GetVehicleLabel(vehicle)
    if vehicle == nil or vehicle == 0 then return end
    return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

function RSGCore.Functions.GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        if GetIsVehiclePrimaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
            colorPrimary = { r, g, b }
        end

        if GetIsVehicleSecondaryColourCustom(vehicle) then
            local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
            colorSecondary = { r, g, b }
        end

        local extras = {}
        for extraId = 0, 12 do
            if DoesExtraExist(vehicle, extraId) then
                local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
                extras[tostring(extraId)] = state
            end
        end

        local tireHealth = {}
        for i = 0, 3 do
            tireHealth[i] = GetVehicleWheelHealth(vehicle, i)
        end

        local tireBurstState = {}
        for i = 0, 5 do
            tireBurstState[i] = IsVehicleTyreBurst(vehicle, i, false)
        end

        local tireBurstCompletely = {}
        for i = 0, 5 do
            tireBurstCompletely[i] = IsVehicleTyreBurst(vehicle, i, true)
        end

        local windowStatus = {}
        for i = 0, 7 do
            windowStatus[i] = IsVehicleWindowIntact(vehicle, i) == 1
        end

        local doorStatus = {}
        for i = 0, 5 do
            doorStatus[i] = IsVehicleDoorDamaged(vehicle, i) == 1
        end

        return {
            model = GetEntityModel(vehicle),
            plate = RSGCore.Functions.GetPlate(vehicle),
            plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
            bodyHealth = RSGCore.Shared.Round(GetVehicleBodyHealth(vehicle), 0.1),
            engineHealth = RSGCore.Shared.Round(GetVehicleEngineHealth(vehicle), 0.1),
            tankHealth = RSGCore.Shared.Round(GetVehiclePetrolTankHealth(vehicle), 0.1),
            fuelLevel = RSGCore.Shared.Round(GetVehicleFuelLevel(vehicle), 0.1),
            dirtLevel = RSGCore.Shared.Round(GetVehicleDirtLevel(vehicle), 0.1),
            oilLevel = RSGCore.Shared.Round(GetVehicleOilLevel(vehicle), 0.1),
            color1 = colorPrimary,
            color2 = colorSecondary,
            pearlescentColor = pearlescentColor,
            dashboardColor = GetVehicleDashboardColour(vehicle),
            wheelColor = wheelColor,
            wheels = GetVehicleWheelType(vehicle),
            wheelSize = GetVehicleWheelSize(vehicle),
            wheelWidth = GetVehicleWheelWidth(vehicle),
            tireHealth = tireHealth,
            tireBurstState = tireBurstState,
            tireBurstCompletely = tireBurstCompletely,
            windowTint = GetVehicleWindowTint(vehicle),
            windowStatus = windowStatus,
            doorStatus = doorStatus,
        }
    else
        return
    end
end

function RSGCore.Functions.SetVehicleProperties(vehicle, props)
    if DoesEntityExist(vehicle) then
        if props.extras then
            for id, enabled in pairs(props.extras) do
                if enabled then
                    SetVehicleExtra(vehicle, tonumber(id), 0)
                else
                    SetVehicleExtra(vehicle, tonumber(id), 1)
                end
            end
        end

        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleModKit(vehicle, 0)
        if props.plate then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        if props.plateIndex then
            SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
        end
        if props.bodyHealth then
            SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
        end
        if props.engineHealth then
            SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
        end
        if props.tankHealth then
            SetVehiclePetrolTankHealth(vehicle, props.tankHealth)
        end
        if props.fuelLevel then
            SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        end
        if props.dirtLevel then
            SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
        end
        if props.oilLevel then
            SetVehicleOilLevel(vehicle, props.oilLevel)
        end
        if props.color1 then
            if type(props.color1) == 'number' then
                ClearVehicleCustomPrimaryColour(vehicle)
                SetVehicleColours(vehicle, props.color1, colorSecondary)
            else
                SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
            end
        end
        if props.color2 then
            if type(props.color2) == 'number' then
                ClearVehicleCustomSecondaryColour(vehicle)
                SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
            else
                SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
            end
        end
        if props.wheelColor then
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
        end
        if props.wheels then
            SetVehicleWheelType(vehicle, props.wheels)
        end
        if props.tireHealth then
            for wheelIndex, health in pairs(props.tireHealth) do
                SetVehicleWheelHealth(vehicle, wheelIndex, health)
            end
        end
        if props.tireBurstState then
            for wheelIndex, burstState in pairs(props.tireBurstState) do
                if burstState then
                    SetVehicleTyreBurst(vehicle, tonumber(wheelIndex), false, 1000.0)
                end
            end
        end
        if props.tireBurstCompletely then
            for wheelIndex, burstState in pairs(props.tireBurstCompletely) do
                if burstState then
                    SetVehicleTyreBurst(vehicle, tonumber(wheelIndex), true, 1000.0)
                end
            end
        end
        if props.windowTint then
            SetVehicleWindowTint(vehicle, props.windowTint)
        end
        if props.windowStatus then
            for windowIndex, smashWindow in pairs(props.windowStatus) do
                if not smashWindow then SmashVehicleWindow(vehicle, windowIndex) end
            end
        end
        if props.doorStatus then
            for doorIndex, breakDoor in pairs(props.doorStatus) do
                if breakDoor then
                    SetVehicleDoorBroken(vehicle, tonumber(doorIndex), true)
                end
            end
        end
    end
end

-- Unused

function RSGCore.Functions.DrawText(x, y, width, height, scale, r, g, b, a, text)
    -- Use local function instead
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x - width / 2, y - height / 2 + 0.005)
end

function RSGCore.Functions.DrawText3D(x, y, z, text)
    -- Use local function instead
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

---@deprecated use lib.requestAnimDict from ox_lib
RSGCore.Functions.RequestAnimDict = lib.requestAnimDict

function RSGCore.Functions.GetClosestBone(entity, list)
    local playerCoords, bone, coords, distance = GetEntityCoords(PlayerPedId())
    for _, element in pairs(list) do
        local boneCoords = GetWorldPositionOfEntityBone(entity, element.id or element)
        local boneDistance = #(playerCoords - boneCoords)
        if not coords then
            bone, coords, distance = element, boneCoords, boneDistance
        elseif distance > boneDistance then
            bone, coords, distance = element, boneCoords, boneDistance
        end
    end
    if not bone then
        bone = { id = GetEntityBoneIndexByName(entity, 'bodyshell'), type = 'remains', name = 'bodyshell' }
        coords = GetWorldPositionOfEntityBone(entity, bone.id)
        distance = #(coords - playerCoords)
    end
    return bone, coords, distance
end

function RSGCore.Functions.GetBoneDistance(entity, boneType, boneIndex)
    local bone
    if boneType == 1 then
        bone = GetPedBoneIndex(entity, boneIndex)
    else
        bone = GetEntityBoneIndexByName(entity, boneIndex)
    end
    local boneCoords = GetWorldPositionOfEntityBone(entity, bone)
    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(boneCoords - playerCoords)
end

function RSGCore.Functions.AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    local modelHash = type(model) == 'string' and joaat(model) or model
    local bone = GetPedBoneIndex(ped, boneId)
    RSGCore.Functions.LoadModel(modelHash)
    local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 1, not vertex and 2 or 0, 1)
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

function RSGCore.Functions.SpawnClear(coords, radius)
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(PlayerPedId())
    end
    local vehicles = GetGamePool('CVehicle')
    local closeVeh = {}
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if distance <= radius then
            closeVeh[#closeVeh + 1] = vehicles[i]
        end
    end
    if #closeVeh > 0 then return false end
    return true
end

---@deprecated use lib.requestAnimDict from ox_lib
RSGCore.Functions.LoadAnimSet = lib.requestAnimSet

---@deprecated use lib.requestNamedPtfxAsset from ox_lib
RSGCore.Functions.LoadParticleDictionary = lib.requestNamedPtfxAsset

---@deprecated use ParticleFx natives directly
function RSGCore.Functions.StartParticleAtCoord(dict, ptName, looped, coords, rot, scale, alpha, color, duration)    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)

    lib.requestNamedPtfxAsset(dict)
    UseParticleFxAssetNextCall(dict)
    SetPtfxAssetNextCall(dict)
    local particleHandle
    if looped then
        particleHandle = StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false, false)
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha or 10.0)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, false)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
    end
    return particleHandle
end

---@deprecated use ParticleFx natives directly
function RSGCore.Functions.StartParticleOnEntity(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration)
    lib.requestNamedPtfxAsset(dict)
    UseParticleFxAssetNextCall(dict)
    local particleHandle = nil
    ---@cast bone number
    local pedBoneIndex = bone and GetPedBoneIndex(entity, bone) or 0
    ---@cast bone string
    local nameBoneIndex = bone and GetEntityBoneIndexByName(entity, bone) or 0
    local entityType = GetEntityType(entity)
    local boneID = entityType == 1 and (pedBoneIndex ~= 0 and pedBoneIndex) or (looped and nameBoneIndex ~= 0 and nameBoneIndex)
    if looped then
        if boneID then
            particleHandle = StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            particleHandle = StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
        if evolution then
            SetParticleFxLoopedEvolution(particleHandle, evolution.name, evolution.amount, false)
        end
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, false)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        if boneID then
            StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
    end
    return particleHandle
end

function RSGCore.Functions.GetStreetNametAtCoords(coords)
    local streetname1, streetname2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return { main = GetStreetNameFromHashKey(streetname1), cross = GetStreetNameFromHashKey(streetname2) }
end

function RSGCore.Functions.GetZoneAtCoords(coords)
    return GetLabelText(GetNameOfZone(coords))
end

function RSGCore.Functions.GetCardinalDirection(entity)
    entity = DoesEntityExist(entity) and entity or PlayerPedId()
    if DoesEntityExist(entity) then
        local heading = GetEntityHeading(entity)
        if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then
            return 'North'
        elseif (heading >= 45 and heading < 135) then
            return 'West'
        elseif (heading >= 135 and heading < 225) then
            return 'South'
        elseif (heading >= 225 and heading < 315) then
            return 'East'
        end
    else
        return 'Cardinal Direction Error'
    end
end

function RSGCore.Functions.GetCurrentTime()
    local obj = {}
    obj.min = GetClockMinutes()
    obj.hour = GetClockHours()
    if obj.hour <= 12 then
        obj.ampm = 'AM'
    elseif obj.hour >= 13 then
        obj.ampm = 'PM'
        obj.formattedHour = obj.hour - 12
    end
    if obj.min <= 9 then
        obj.formattedMin = '0' .. obj.min
    end
    return obj
end

function RSGCore.Functions.GetGroundZCoord(coords)
    if not coords then return end

    local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, 0)
    if retval then
        return vector3(coords.x, coords.y, groundZ)
    else
        return coords
    end
end

function RSGCore.Functions.GetGroundHash(entity)
    local coords = GetEntityCoords(entity)
    local num = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 1, 1, entity, 7)
    local retval, success, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(num)
    return materialHash, entityHit, surfaceNormal, endCoords, success, retval
end
