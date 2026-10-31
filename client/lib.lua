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

exports('RequestModel', RSGCore.Functions.RequestModel)
exports('RequestAnimDict', RSGCore.Functions.RequestAnimDict)
exports('RequestAnimSet', RSGCore.Functions.RequestAnimSet)
exports('RequestNamedPtfxAsset', RSGCore.Functions.RequestNamedPtfxAsset)
