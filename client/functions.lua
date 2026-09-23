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

-- Prints to the client (F8) console. Previously this was sent to the server through an
-- unprotected net event, which let any client flood the server console.
function RSGCore.Debug(...)
    local out = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        out[i] = type(v) == 'table' and json.encode(v, { indent = true }) or tostring(v)
    end
    print(('[%s : DEBUG] %s'):format(GetInvokingResource() or GetCurrentResourceName(), table.concat(out, ' ')))
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
    if type(entity) ~= 'number' or not DoesEntityExist(entity) then return end
    if speed ~= nil and type(speed) ~= 'number' then return end
    speed = math.min(speed or 1.0, 5.0) -- speed was required before; nil caused an arithmetic error
    if not timeout or timeout > 5000 then timeout = 5000 end
    local ped = cache.ped
    local playerPos = GetEntityCoords(ped)
    local targetPos = GetEntityCoords(entity)
    local targetHeading = GetHeadingFromVector_2d(targetPos.x - playerPos.x, targetPos.y - playerPos.y)
    local endTime = GetGameTimer() + timeout
    while GetGameTimer() < endTime do
        local currentHeading = GetEntityHeading(ped)
        local diff = targetHeading - currentHeading
        -- normalise first, so e.g. 359 -> 1 degrees is treated as a 2 degree turn
        if diff < -180 then diff = diff + 360 elseif diff > 180 then diff = diff - 360 end
        if math.abs(diff) < 2 then break end
        local turnSpeed = speed + (2.5 - speed) * (1 - math.abs(diff) / 180)
        SetEntityHeading(ped, currentHeading + (diff > 0 and turnSpeed or -turnSpeed))
        Wait(0)
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
    local ped = cache.ped
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
    local ped = cache.ped
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
    local ped = cache.ped
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
    local ped = cache.ped
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
    local ped = cache.ped
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

-- Text drawing (RedM natives; the previous versions used GTA V natives that do not exist in RedM)

function RSGCore.Functions.DrawText(x, y, width, height, scale, r, g, b, a, text)
    SetTextScale(scale, scale)
    SetTextColor(r, g, b, a)
    SetTextFontForCurrentCommand(1)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), x - width / 2, y - height / 2 + 0.005)
end

function RSGCore.Functions.DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    local camDistance = #(GetGameplayCamCoord() - vector3(x, y, z))
    local scale = math.max(0.25, math.min(0.5, 200 / (GetGameplayCamFov() * camDistance) * 0.5))
    SetTextScale(0.0, scale)
    SetTextColor(255, 255, 255, 215)
    SetTextFontForCurrentCommand(1)
    SetTextCentre(true)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), screenX, screenY)
end

---@deprecated use lib.requestAnimDict from ox_lib
RSGCore.Functions.RequestAnimDict = lib.requestAnimDict

function RSGCore.Functions.GetClosestBone(entity, list)
    local playerCoords, bone, coords, distance = GetEntityCoords(cache.ped)
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
    local playerCoords = GetEntityCoords(cache.ped)
    return #(boneCoords - playerCoords)
end

function RSGCore.Functions.AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    local modelHash = type(model) == 'string' and joaat(model) or model
    local bone = GetPedBoneIndex(ped, boneId)
    lib.requestModel(modelHash)
    local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 1, not vertex and 2 or 0, 1)
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

function RSGCore.Functions.SpawnClear(coords, radius)
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(cache.ped)
    end
    radius = radius or 5.0
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(vehicle) - coords) <= radius then return false end
    end
    return true
end

---@deprecated use lib.requestAnimSet from ox_lib
RSGCore.Functions.LoadAnimSet = lib.requestAnimSet

---@deprecated use lib.requestNamedPtfxAsset from ox_lib
RSGCore.Functions.LoadParticleDictionary = lib.requestNamedPtfxAsset

---@deprecated use ParticleFx natives directly
function RSGCore.Functions.StartParticleAtCoord(dict, ptName, looped, coords, rot, scale, alpha, color, duration)
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)

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

function RSGCore.Functions.GetCardinalDirection(entity)
    entity = entity and DoesEntityExist(entity) and entity or cache.ped
    if DoesEntityExist(entity) then
        local heading = GetEntityHeading(entity)
        if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then
            return 'North'
        elseif (heading >= 45 and heading < 135) then
            return 'East'
        elseif (heading >= 135 and heading < 225) then
            return 'South'
        elseif (heading >= 225 and heading < 315) then
            return 'West'
        end
    else
        return 'Cardinal Direction Error'
    end
end

function RSGCore.Functions.GetCurrentTime()
    local obj = {}
    obj.min = GetClockMinutes()
    obj.hour = GetClockHours()
    -- previously midnight showed as 0 AM, 12 as AM, and formattedHour/formattedMin were sometimes nil
    obj.ampm = obj.hour < 12 and 'AM' or 'PM'
    obj.formattedHour = obj.hour % 12 == 0 and 12 or obj.hour % 12
    obj.formattedMin = ('%02d'):format(obj.min)
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

local notifyTypes = {
    primary = 'inform',
    inform  = 'inform',
    info    = 'inform',
    success = 'success',
    error   = 'error',
    warning = 'warning',
}

---@param title? string Optional notification title
---@param text string | table Notification text/description, or a full table of props
---@param notifyType? string 'primary', 'success', 'error', 'inform', 'warning'
---@param duration? number Duration in milliseconds (default: 5000)
---@param icon? string Optional FontAwesome or RedM icon string
function RSGCore.Functions.Notify(title, text, notifyType, duration, icon)
    if type(text) == 'table' then
        return lib.notify(text)
    end
    if type(title) == 'table' then
        return lib.notify(title)
    end

    -- legacy QB-style call: Notify(text, type, duration)
    if type(text) == 'string' and notifyTypes[text] and (notifyType == nil or type(notifyType) == 'number') then
        return lib.notify({ description = title, type = notifyTypes[text], duration = notifyType or 5000 })
    end

    lib.notify({
        title = title,
        description = text,
        type = notifyTypes[notifyType] or 'inform',
        duration = duration or 5000,
        icon = icon
    })
end
