RSGCore.Functions = {}

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

-- Utility

function RSGCore.Functions.DrawText(x, y, width, height, scale, r, g, b, a, text)
    -- Use local function instead
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

function RSGCore.Functions.DrawText3D(x, y, z, text)
    -- Use local function instead
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function RSGCore.Functions.RequestAnimDict(animDict)
    if HasAnimDictLoaded(animDict) then return end
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
end

function RSGCore.Functions.PlayAnim(animDict, animName, upperbodyOnly, duration)
    local flags = upperbodyOnly and 16 or 0
    local runTime = duration or -1
    RSGCore.Functions.RequestAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, 1.0, runTime, flags, 0.0, false, false, true)
    RemoveAnimDict(animDict)
end

function RSGCore.Functions.LoadModel(model)
    if HasModelLoaded(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

function RSGCore.Functions.LoadAnimSet(animSet)
    if HasAnimSetLoaded(animSet) then return end
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do
        Wait(0)
    end
end

RegisterNUICallback('getNotifyConfig', function(_, cb)
    cb(RSGCore.Config.Notify)
end)

function RSGCore.Functions.Notify(text, texttype, length)
    if type(text) == "table" then
        local ttext = text.text or 'Placeholder'
        local caption = text.caption or 'Placeholder'
        texttype = texttype or 'primary'
        length = length or 5000
        SendNUIMessage({
            action = 'notify',
            type = texttype,
            length = length,
            text = ttext,
            caption = caption
        })
    else
        texttype = texttype or 'primary'
        length = length or 5000
        SendNUIMessage({
            action = 'notify',
            type = texttype,
            length = length,
            text = text
        })
    end
end

function RSGCore.Debug(resource, obj, depth)
    TriggerServerEvent('RSGCore:DebugSomething', resource, obj, depth)
end

-- Callback Functions --

-- Client Callback
function RSGCore.Functions.CreateClientCallback(name, cb)
    RSGCore.ClientCallbacks[name] = cb
end

function RSGCore.Functions.TriggerClientCallback(name, cb, ...)
    if not RSGCore.ClientCallbacks[name] then return end
    RSGCore.ClientCallbacks[name](cb, ...)
end

-- Server Callback
function RSGCore.Functions.TriggerCallback(name, cb, ...)
    RSGCore.ServerCallbacks[name] = cb
    TriggerServerEvent('RSGCore:Server:TriggerCallback', name, ...)
end

function RSGCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    if GetResourceState('progressbar') ~= 'started' then error('progressbar needs to be started in order for RSGCore.Functions.Progressbar to work') end
    exports['progressbar']:Progress({
        name = name:lower(),
        duration = duration,
        label = label,
        useWhileDead = useWhileDead,
        canCancel = canCancel,
        controlDisables = disableControls,
        animation = animation,
        prop = prop,
        propTwo = propTwo,
    }, function(cancelled)
        if not cancelled then
            if onFinish then
                onFinish()
            end
        else
            if onCancel then
                onCancel()
            end
        end
    end)
end

-- Getters

function RSGCore.Functions.GetVehicles()
    return GetGamePool('CVehicle')
end

function RSGCore.Functions.GetObjects()
    return GetGamePool('CObject')
end

function RSGCore.Functions.GetPlayers()
    return GetActivePlayers()
end

function RSGCore.Functions.GetPeds(ignoreList)
    local pedPool = GetGamePool('CPed')
    local peds = {}
    ignoreList = ignoreList or {}
    for i = 1, #pedPool, 1 do
        local found = false
        for j = 1, #ignoreList, 1 do
            if ignoreList[j] == pedPool[i] then
                found = true
            end
        end
        if not found then
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
    local ignoreList = ignoreList or {}
    local peds = RSGCore.Functions.GetPeds(ignoreList)
    local closestDistance = -1
    local closestPed = -1
    for i = 1, #peds, 1 do
        local pedCoords = GetEntityCoords(peds[i])
        local distance = #(pedCoords - coords)
        if peds[i] ~= ped then
            if closestDistance == -1 or closestDistance > distance then
                closestPed = peds[i]
                closestDistance = distance
            end
        end
    end
    return closestPed, closestDistance
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
    for _, player in pairs(players) do
        local target = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(target)
        local targetdistance = #(targetCoords - coords)
        if targetdistance <= distance then
            closePlayers[#closePlayers + 1] = player
        end
    end
    return closePlayers
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
        bone = {id = GetEntityBoneIndexByName(entity, "bodyshell"), type = "remains", name = "bodyshell"}
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
    local modelHash = type(model) == 'string' and GetHashKey(model) or model
    local bone = GetPedBoneIndex(ped, boneId)
    RSGCore.Functions.LoadModel(modelHash)
    local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, 1, 1, 0)
    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, 1, 1, 0, 1, not vertex and 2 or 0, 1)
    SetModelAsNoLongerNeeded(modelHash)
    return prop
end

-- Vehicle

function RSGCore.Functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local ped = PlayerPedId()
    model = type(model) == 'string' and GetHashKey(model) or model
    if not IsModelInCdimage(model) then return end
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    isnetworked = isnetworked == nil or isnetworked
    RSGCore.Functions.LoadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(model)
    if teleportInto then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
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

function RSGCore.Functions.GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        -- get vehicle stuff here
    else
        return
    end
end

function RSGCore.Functions.SetVehicleProperties(vehicle, props)
    if DoesEntityExist(vehicle) then
        -- set vehicle stuff here
    end
end

function RSGCore.Functions.LoadParticleDictionary(dictionary)
    if HasNamedPtfxAssetLoaded(dictionary) then return end
    RequestNamedPtfxAsset(dictionary)
    while not HasNamedPtfxAssetLoaded(dictionary) do
        Wait(0)
    end
end

function RSGCore.Functions.StartParticleAtCoord(dict, ptName, looped, coords, rot, scale, alpha, color, duration)
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(PlayerPedId())
    end
    RSGCore.Functions.LoadParticleDictionary(dict)
    UseParticleFxAssetNextCall(dict)
    SetPtfxAssetNextCall(dict)
    local particleHandle
    if looped then
        particleHandle = StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0)
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha or 10.0)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, 0)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 10.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0)
    end
    return particleHandle
end

function RSGCore.Functions.StartParticleOnEntity(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration)
    RSGCore.Functions.LoadParticleDictionary(dict)
    UseParticleFxAssetNextCall(dict)
    local particleHandle, boneID
    if bone and GetEntityType(entity) == 1 then
        boneID = GetPedBoneIndex(entity, bone)
    elseif bone then
        boneID = GetEntityBoneIndexByName(entity, bone)
    end
    if looped then
        if bone then
            particleHandle = StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale)
        else
            particleHandle = StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale)
        end
        if evolution then
            SetParticleFxLoopedEvolution(particleHandle, evolution.name, evolution.amount, false)
        end
        if color then
            SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        SetParticleFxLoopedAlpha(particleHandle, alpha)
        if duration then
            Wait(duration)
            StopParticleFxLooped(particleHandle, 0)
        end
    else
        SetParticleFxNonLoopedAlpha(alpha or 10.0)
        if color then
            SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        if bone then
            StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale)
        else
            StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale)
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
            return "North"
        elseif (heading >= 45 and heading < 135) then
            return "West"
        elseif (heading >= 135 and heading < 225) then
            return "South"
        elseif (heading >= 225 and heading < 315) then
            return "East"
        end
    else
        return "Cardinal Direction Error"
    end
end

function RSGCore.Functions.GetCurrentTime()
    local obj = {}
    obj.min = GetClockMinutes()
    obj.hour = GetClockHours()

    if obj.hour <= 12 then
        obj.ampm = "AM"
    elseif obj.hour >= 13 then
        obj.ampm = "PM"
        obj.formattedHour = obj.hour - 12
    end

    if obj.min <= 9 then
        obj.formattedMin = "0" .. obj.min
    end

    return obj
end

function RSGCore.Functions.GetGroundZCoord(coords)
    if not coords then return end

    local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, 0)
    if retval then
        return vector3(coords.x, coords.y, groundZ)
    else
        print('Couldn\'t find Ground Z Coordinates given 3D Coordinates')
        print(coords)
        return coords
    end
end
