-- Death and kill events for the whole framework.
--   RSGCore:Server:OnPlayerDeath (victim, killer|nil, data)   every reported death
--   RSGCore:Server:OnPlayerKilled (victim, killer, data)      only confirmed player-vs-player kills
-- data = { weapon = hash, coords = vector3, confirmed = bool }
-- These are server-only events: clients cannot fire them, only RSGCore:Server:ReportDeath (validated below).
local cfg = RSGConfig.Death
if not cfg or not cfg.Enabled then return end

local lastReport = {} -- [src] = GetGameTimer() of the last accepted report
local lastDeath = {}  -- [src] = { killer, weapon, coords, time, confirmed }

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function resolveKiller(src, killer)
    if type(killer) ~= 'number' or killer ~= math.floor(killer) or killer <= 0 or killer == src then return nil end
    if not RSGCore.Players[killer] then return nil end
    if not RSGCore.Config.Server.PVP then return nil end
    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(killer) then return nil end

    local a, b = playerCoords(src), playerCoords(killer)
    if not a or not b or #(a - b) > cfg.MaxKillDistance then return nil end

    if cfg.RequireKillerConfirm then
        local ok, confirmed = pcall(RSGCore.Functions.AwaitClientCallback, 'RSGCore:Client:ConfirmKill', killer, cfg.ConfirmTimeout, src)
        if not ok or confirmed ~= true then return nil end
    end
    return killer
end

RegisterNetEvent('RSGCore:Server:ReportDeath', function(killer, weapon)
    local src = source
    if not RSGCore.Players[src] then return end

    local now = GetGameTimer()
    if lastReport[src] and now - lastReport[src] < cfg.MinSecondsBetween * 1000 then return end
    lastReport[src] = now

    if type(weapon) ~= 'number' or weapon ~= weapon then weapon = nil end
    local victimCoords = playerCoords(src)
    local killerSrc = resolveKiller(src, killer)

    local data = { weapon = weapon, coords = victimCoords, confirmed = killerSrc ~= nil }
    lastDeath[src] = { killer = killerSrc, weapon = weapon, coords = victimCoords, time = os.time(), confirmed = data.confirmed }

    TriggerEvent('RSGCore:Server:OnPlayerDeath', src, killerSrc, data)
    if killerSrc then TriggerEvent('RSGCore:Server:OnPlayerKilled', src, killerSrc, data) end
end)

-- Last accepted death of a player: { killer = serverId|nil, weapon, coords, time (os.time), confirmed }
exports('GetLastDeath', function(src) return lastDeath[src] end)

AddEventHandler('playerDropped', function()
    local src = source
    lastReport[src] = nil
    lastDeath[src] = nil
end)
