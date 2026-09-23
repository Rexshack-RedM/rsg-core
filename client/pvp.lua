-- Keeps players hostile to each other while PVP is enabled.
-- Briefly switches to "respect" after pressing E (interact) / F so greeting or
-- interacting with another player doesn't start a fight, and while mounted/in a vehicle.

local RELATIONSHIP_HOSTILE = 3
local RELATIONSHIP_FRIENDLY = 1
local INTERACT_GRACE_MS = 3500

local keyE = RSGShared.Keybinds['E']
local keyF = RSGShared.Keybinds['F']

CreateThread(function()
    local friendlyUntil = 0
    while true do
        if not RSGCore.Config.Server.PVP then
            SetRelationshipBetweenGroups(RELATIONSHIP_FRIENDLY, `PLAYER`, `PLAYER`)
            Wait(1000) -- previously the loop ran every frame even with PVP disabled
        else
            local now = GetGameTimer()
            if IsControlJustPressed(0, keyE) or IsControlJustPressed(0, keyF) then
                friendlyUntil = now + INTERACT_GRACE_MS
            end

            local friendly = now < friendlyUntil or IsPedOnMount(cache.ped) or IsPedInAnyVehicle(cache.ped, false)
            SetRelationshipBetweenGroups(friendly and RELATIONSHIP_FRIENDLY or RELATIONSHIP_HOSTILE, `PLAYER`, `PLAYER`)
            Citizen.InvokeNative(0xF808475FA571D823, true) -- NetworkSetFriendlyFireOption
            Wait(0)
        end
    end
end)
