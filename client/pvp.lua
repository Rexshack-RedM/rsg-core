-- Keeps player-vs-player state in sync with the server.
-- PVP ON : players are hostile and friendly fire is on. Briefly switches to "respect"
--          after pressing E (interact) / F so greeting/interacting doesn't start a fight,
--          and while mounted/in a vehicle.
-- PVP OFF: players are friendly, friendly fire is off, players can't be damaged by the PLAYER group
--          (blocks fists/melee) and can't lock on to each other.
-- Everything is re-applied every second because the game (respawn, model change) and
-- other scripts can reset these natives.

local RELATIONSHIP_HATE = 5
local RELATIONSHIP_RESPECT = 1
local INTERACT_GRACE_MS = 3500
local REAPPLY_MS = 1000

local keyE = RSGShared.Keybinds['E']
local keyF = RSGShared.Keybinds['F']

local applied, appliedPvp, appliedPed, lastApply = nil, nil, nil, 0

-- server state wins (correct for late joiners); config is only the fallback
local function pvpEnabled()
    local state = GlobalState.pvp
    if state == nil then return RSGCore.Config.Server.PVP == true end
    return state == true
end

local function apply(relationship, pvp, now)
    local ped = cache.ped
    if relationship == applied and pvp == appliedPvp and ped == appliedPed and now - lastApply < REAPPLY_MS then return end
    SetRelationshipBetweenGroups(relationship, `PLAYER`, `PLAYER`)
    Citizen.InvokeNative(0xF808475FA571D823, pvp)           -- NetworkSetFriendlyFireOption
    Citizen.InvokeNative(0xB3B1CB349FF9C75D, ped, pvp, false) -- SetCanAttackFriendly
    -- friendly fire only covers weapons: this is what blocks fists/melee between players when PVP is off
    Citizen.InvokeNative(0x0EF1AFB18649E015, ped, pvp, `PLAYER`) -- SET_ENTITY_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP
    Citizen.InvokeNative(0x4A056257802DD3E5, cache.playerId, pvp) -- SET_LOCKON_TO_FRIENDLY_PLAYERS
    applied, appliedPvp, appliedPed, lastApply = relationship, pvp, ped, now
end

AddStateBagChangeHandler('pvp', 'global', function(_, _, value)
    RSGCore.Config.Server.PVP = value == true
    lastApply = 0 -- force immediate re-apply
end)

CreateThread(function()
    local friendlyUntil = 0
    while true do
        local now = GetGameTimer()
        if not pvpEnabled() then
            apply(RELATIONSHIP_RESPECT, false, now)
            Wait(1000)
        else
            if IsControlJustPressed(0, keyE) or IsControlJustPressed(0, keyF) then
                friendlyUntil = now + INTERACT_GRACE_MS
            end
            local friendly = now < friendlyUntil or IsPedOnMount(cache.ped) or IsPedInAnyVehicle(cache.ped, false)
            apply(friendly and RELATIONSHIP_RESPECT or RELATIONSHIP_HATE, true, now)
            Wait(0)
        end
    end
end)
