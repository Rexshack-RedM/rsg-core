-- Death reporting. The victim's client reports who killed it; the server validates the claim and the
-- killer's own client must confirm it before the server treats it as a player kill (see server/death.lua).
local cfg = RSGConfig.Death
if not cfg or not cfg.Enabled then return end

local N_SOURCE_OF_DEATH = 0x93C8B64DEB84728C -- GET_PED_SOURCE_OF_DEATH
local N_CAUSE_OF_DEATH = 0x16FFE42AB2D2DC59  -- GET_PED_CAUSE_OF_DEATH
local N_IS_PED_A_PLAYER = 0x12534C348C6CB68B -- IS_PED_A_PLAYER
local N_PLAYER_FROM_PED = 0x6C0E2E0125610278 -- NETWORK_GET_PLAYER_INDEX_FROM_PED

local function sourceOfDeath(ped)
    return Citizen.InvokeNative(N_SOURCE_OF_DEATH, ped, Citizen.ResultAsInteger())
end

-- Server id of the player who killed `ped`, or nil (NPC, animal, fall, unknown).
local function killerServerId(ped)
    local entity = sourceOfDeath(ped)
    if not entity or entity == 0 or entity == ped or not DoesEntityExist(entity) then return nil end
    if Citizen.InvokeNative(N_IS_PED_A_PLAYER, entity, Citizen.ResultAsInteger()) == 0 then return nil end
    local player = Citizen.InvokeNative(N_PLAYER_FROM_PED, entity, Citizen.ResultAsInteger())
    if not player or player < 0 then return nil end
    local sid = GetPlayerServerId(player)
    return sid and sid > 0 and sid or nil
end

CreateThread(function()
    local wasDead = false
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)
        if dead and not wasDead then
            wasDead = true
            local killer = killerServerId(ped)
            local weapon = Citizen.InvokeNative(N_CAUSE_OF_DEATH, ped, Citizen.ResultAsInteger())
            TriggerEvent('RSGCore:Client:OnPlayerDied', killer, weapon) -- local convenience event
            TriggerServerEvent('RSGCore:Server:ReportDeath', killer, weapon)
        elseif not dead and wasDead then
            wasDead = false
        end
        Wait(dead and 1000 or 250)
    end
end)

-- The server asks the (claimed) killer's client whether it really killed `victimServerId`.
RSGCore.Functions.CreateClientCallback('RSGCore:Client:ConfirmKill', function(cb, victimServerId)
    local player = GetPlayerFromServerId(tonumber(victimServerId) or -1)
    if not player or player < 0 then return cb(false) end
    local victimPed = GetPlayerPed(player)
    if not victimPed or victimPed == 0 or not IsEntityDead(victimPed) then return cb(false) end
    cb(sourceOfDeath(victimPed) == PlayerPedId())
end)
