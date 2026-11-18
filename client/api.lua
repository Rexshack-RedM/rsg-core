-- Public client API: exports over RSGCore.Functions for other resources.
local exported = {
    'GetPlayerData', 'HasItem', 'GetCoords', 'GetClosestPlayer', 'GetClosestPed', 'GetClosestVehicle',
    'GetClosestObject', 'GetPlayersFromCoords', 'PlayAnim', 'LookAtEntity', 'SpawnVehicle', 'DeleteVehicle',
    'GetGroundZCoord', 'GetCardinalDirection', 'GetCurrentTime',
    'TriggerCallback', 'AwaitCallback', 'CreateClientCallback',
}

for i = 1, #exported do
    local name = exported[i]
    local fn = RSGCore.Functions[name]
    if type(fn) == 'function' then
        exports(name, fn)
    else
        print(('^3[rsg-core] api: RSGCore.Functions.%s is missing, export skipped^7'):format(name))
    end
end
