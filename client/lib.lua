-- rsg-core client helpers (replaces ox_lib cache / request* / playAnim)

-- cache: kept up to date every 100ms
cache = {
    resource = GetCurrentResourceName(),
    playerId = PlayerId(),
    serverId = GetPlayerServerId(PlayerId()),
    ped = PlayerPedId(),
    mount = false,
    vehicle = false,
}

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        cache.ped = ped
        cache.playerId = PlayerId()
        local mount = GetMount(ped)
        cache.mount = (mount and mount ~= 0) and mount or false
        local veh = GetVehiclePedIsIn(ped, false)
        cache.vehicle = (veh and veh ~= 0) and veh or false
        Wait(100)
    end
end)

local function waitFor(check, name, timeout)
    timeout = timeout or 10000
    local start = GetGameTimer()
    while not check() do
        if GetGameTimer() - start > timeout then
            error(('[rsg-core] failed to load "%s" after %dms'):format(tostring(name), timeout), 3)
        end
        Wait(0)
    end
end

---Load a model (hash or name). Errors after timeout. Returns the hash.
function RSGCore.Functions.RequestModel(model, timeout)
    local hash = type(model) == 'number' and model or joaat(model)
    if HasModelLoaded(hash) then return hash end
    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        error(('[rsg-core] invalid model "%s"'):format(tostring(model)), 2)
    end
    RequestModel(hash, false)
    waitFor(function() return HasModelLoaded(hash) end, model, timeout)
    return hash
end

function RSGCore.Functions.RequestAnimDict(dict, timeout)
    if HasAnimDictLoaded(dict) then return dict end
    if not DoesAnimDictExist(dict) then
        error(('[rsg-core] invalid anim dict "%s"'):format(tostring(dict)), 2)
    end
    RequestAnimDict(dict)
    waitFor(function() return HasAnimDictLoaded(dict) end, dict, timeout)
    return dict
end

function RSGCore.Functions.RequestAnimSet(set, timeout)
    if HasAnimSetLoaded(set) then return set end
    RequestAnimSet(set)
    waitFor(function() return HasAnimSetLoaded(set) end, set, timeout)
    return set
end

function RSGCore.Functions.RequestNamedPtfxAsset(asset, timeout)
    local hash = type(asset) == 'number' and asset or joaat(asset)
    if HasNamedPtfxAssetLoaded(hash) then return asset end
    RequestNamedPtfxAsset(hash)
    waitFor(function() return HasNamedPtfxAssetLoaded(hash) end, asset, timeout)
    return asset
end

---Play an animation (same arguments as lib.playAnim). Loads the dict and releases it afterwards.
function RSGCore.Functions.PlayAnimOnPed(ped, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)
    RSGCore.Functions.RequestAnimDict(dict)
    TaskPlayAnim(ped, dict, name, blendIn or 8.0, blendOut or -8.0, duration or -1, flag or 0, rate or 0.0, lockX or false, lockY or false, lockZ or false)
    RemoveAnimDict(dict)
end

function RSGCore.Functions.RequestStreamedTextureDict(dict, timeout)
    if HasStreamedTextureDictLoaded(dict) then return dict end
    RequestStreamedTextureDict(dict, false)
    waitFor(function() return HasStreamedTextureDictLoaded(dict) end, dict, timeout)
    return dict
end

---------------------------------------------------------------- raycast (replaces lib.raycast)

local function rotToDirection(rot)
    local x, z = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(x))
    return vec3(-math.sin(z) * c, math.cos(z) * c, math.sin(x))
end

---Shape-test between two points. Yields until the result is ready (call from a thread).
---@param from vector3
---@param to vector3
---@param flags? number   shape-test flags (default 511 = everything)
---@param ignore? number  4 = ignore glass/see-through, 7 = ignore all (default 4)
---@return boolean hit, number entityHit, vector3 endCoords, vector3 surfaceNormal
function RSGCore.Functions.Raycast(from, to, flags, ignore)
    local handle = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags or 511, cache.ped, ignore or 4)

    while true do
        local status, hit, endCoords, normal, entity = GetShapeTestResult(handle)
        if status ~= 1 then
            hit = hit == true or hit == 1
            return hit, entity or 0, hit and endCoords or to, normal
        end
        Wait(0)
    end
end

---Raycast from the gameplay camera forward (same returns as lib.raycast.fromCamera).
---@param flags? number
---@param ignore? number
---@param distance? number default 10.0
function RSGCore.Functions.RaycastCamera(flags, ignore, distance)
    local from = GetGameplayCamCoord()
    local to = from + rotToDirection(GetGameplayCamRot(2)) * (distance or 10.0)
    return RSGCore.Functions.Raycast(from, to, flags, ignore)
end

---------------------------------------------------------------- nearby entities (replaces lib.getNearby*)

local function nearby(pool, key, coords, maxDistance, filter)
    local out, n = {}, 0
    local list = GetGamePool(pool)
    for i = 1, #list do
        local e = list[i]
        if not filter or filter(e) then
            local c = GetEntityCoords(e)
            local d = #(coords - c)
            if d <= maxDistance then
                n += 1
                out[n] = { [key] = e, coords = c, distance = d }
            end
        end
    end
    return out
end

---Non-player peds within maxDistance: { { ped, coords, distance } }
function RSGCore.Functions.GetNearbyPeds(coords, maxDistance)
    return nearby('CPed', 'ped', coords, maxDistance or 2.0, function(e) return not IsPedAPlayer(e) end)
end

---Vehicles (wagons, carts, boats) within maxDistance. includePlayerVehicle defaults to false.
function RSGCore.Functions.GetNearbyVehicles(coords, maxDistance, includePlayerVehicle)
    local own = not includePlayerVehicle and cache.vehicle or nil
    return nearby('CVehicle', 'vehicle', coords, maxDistance or 2.0, own and function(e) return e ~= own end or nil)
end

---Objects within maxDistance: { { object, coords, distance } }
function RSGCore.Functions.GetNearbyObjects(coords, maxDistance)
    return nearby('CObject', 'object', coords, maxDistance or 2.0)
end

exports('RequestModel', RSGCore.Functions.RequestModel)
exports('RequestAnimDict', RSGCore.Functions.RequestAnimDict)
exports('RequestAnimSet', RSGCore.Functions.RequestAnimSet)
exports('RequestNamedPtfxAsset', RSGCore.Functions.RequestNamedPtfxAsset)
exports('RequestStreamedTextureDict', RSGCore.Functions.RequestStreamedTextureDict)
exports('Raycast', RSGCore.Functions.Raycast)
exports('RaycastCamera', RSGCore.Functions.RaycastCamera)
exports('GetNearbyPeds', RSGCore.Functions.GetNearbyPeds)
exports('GetNearbyVehicles', RSGCore.Functions.GetNearbyVehicles)
exports('GetNearbyObjects', RSGCore.Functions.GetNearbyObjects)
