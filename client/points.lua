-- rsg-core points (replaces ox_lib lib.points)
--
-- Runs inside the resource that includes it, so callbacks and point data stay local:
--   client_scripts { '@rsg-core/client/points.lua', ... }
--
--   local point = points.new({
--       coords = vec3(...), distance = 50.0,
--       onEnter = function(self) end,   -- player came within `distance`
--       onExit  = function(self) end,   -- player left `distance`
--       nearby  = function(self) end,   -- every frame while within `distance`
--       -- any extra fields (model, seller, ...) are kept on the point
--   })
--   points.new(coords, distance, { onEnter = ... })   -- ox_lib positional form also works
--   point:remove()
--
-- Every point gets: id, coords, distance, currentDistance (while nearby), isClosest.
-- points.getAllPoints()  points.getNearbyPoints()  points.getClosestPoint()
-- Global `points` is set, and `lib.points` too when an ox_lib-style `lib` table exists.

local points = {}
local Points = {}      -- id -> point
local nearbyPoints = {}  -- id -> point (inside its distance)
local nextId = 0
local closestPoint

local UPDATE_INTERVAL = 300 -- ms between distance checks

local Point = {}
Point.__index = Point

function Point:remove()
    if Points[self.id] == nil then return end
    if nearbyPoints[self.id] then
        nearbyPoints[self.id] = nil
        if self.onExit then pcall(self.onExit, self) end
    end
    if closestPoint == self then closestPoint = nil end
    Points[self.id] = nil
end

local function toVec3(c)
    return vec3(c.x + 0.0, c.y + 0.0, c.z + 0.0)
end

---@param data table|vector3 options table, or coords for the positional form
---@param distance? number positional form only
---@param extra? table positional form only
function points.new(data, distance, extra)
    if type(data) ~= 'table' or data.x then
        local opts = extra or {}
        opts.coords, opts.distance = data, distance
        data = opts
    end
    assert(data.coords, 'rsg-core points.new: coords is required')
    assert(type(data.distance) == 'number' and data.distance > 0, 'rsg-core points.new: distance must be a positive number')

    nextId = nextId + 1
    data.id = nextId
    data.coords = toVec3(data.coords)
    data.isClosest = false
    data.remove = Point.remove
    Points[data.id] = setmetatable(data, Point)
    return data
end

function points.getAllPoints() return Points end

function points.getNearbyPoints()
    local out = {}
    for _, p in pairs(nearbyPoints) do out[#out + 1] = p end
    return out
end

function points.getClosestPoint() return closestPoint end

---------------------------------------------------------------- update loops

-- distance / enter / exit / closest
CreateThread(function()
    while true do
        if next(Points) then
            local coords = GetEntityCoords(PlayerPedId())
            local best, bestDist

            for id, p in pairs(Points) do
                local dist = #(coords - p.coords)
                local near = dist <= p.distance

                if near then
                    p.currentDistance = dist
                    if not bestDist or dist < bestDist then best, bestDist = p, dist end
                    if not nearbyPoints[id] then
                        nearbyPoints[id] = p
                        if p.onEnter then pcall(p.onEnter, p) end
                    end
                elseif nearbyPoints[id] then
                    nearbyPoints[id] = nil
                    p.currentDistance = nil
                    if p.onExit then pcall(p.onExit, p) end
                end
            end

            if closestPoint ~= best then
                if closestPoint then closestPoint.isClosest = false end
                if best then best.isClosest = true end
                closestPoint = best
            end
        end

        Wait(UPDATE_INTERVAL)
    end
end)

-- per-frame `nearby` callbacks (only while a nearby point has one)
CreateThread(function()
    while true do
        local busy = false
        for _, p in pairs(nearbyPoints) do
            if p.nearby then
                busy = true
                pcall(p.nearby, p)
            end
        end
        Wait(busy and 0 or 500)
    end
end)

-- points are local to the including resource; fire onExit when it stops
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, p in pairs(Points) do p:remove() end
end)

-- globals for ox_lib-style code
_ENV.points = points
if type(lib) == 'table' and rawget(lib, 'points') == nil then
    rawset(lib, 'points', points)
end
