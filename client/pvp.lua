-- Keeps players hostile to each other while PVP is enabled.
-- Briefly switches to "respect" after pressing E (interact) / F so greeting or
-- interacting with another player doesn't start a fight, and while mounted/in a vehicle.

local RELATIONSHIP_HOSTILE = 3
local RELATIONSHIP_FRIENDLY = 1
local INTERACT_GRACE_MS = 3500
local REAPPLY_MS = 1000 -- re-apply periodically in case another script/game event resets it

local keyE = RSGShared.Keybinds['E']
local keyF = RSGShared.Keybinds['F']

local applied, lastApply = nil, 0

local function apply(relationship, now)
    if relationship == applied and now - lastApply < REAPPLY_MS then return end
    SetRelationshipBetweenGroups(relationship, `PLAYER`, `PLAYER`)
    if RSGCore.Config.Server.PVP then Citizen.InvokeNative(0xF808475FA571D823, true) end -- NetworkSetFriendlyFireOption
    applied, lastApply = relationship, now
end

CreateThread(function()
    local friendlyUntil = 0
    while true do
        local now = GetGameTimer()
        if not RSGCore.Config.Server.PVP then
            apply(RELATIONSHIP_FRIENDLY, now)
            Wait(1000)
        else
            -- key presses must be read every frame; the natives only run when the state changes
            if IsControlJustPressed(0, keyE) or IsControlJustPressed(0, keyF) then
                friendlyUntil = now + INTERACT_GRACE_MS
            end
            local friendly = now < friendlyUntil or IsPedOnMount(cache.ped) or IsPedInAnyVehicle(cache.ped, false)
            apply(friendly and RELATIONSHIP_FRIENDLY or RELATIONSHIP_HOSTILE, now)
            Wait(0)
        end
    end
end)
