-- rsg-core zones (replaces ox_lib lib.zones)
--
-- Runs inside the resource that includes it, so callbacks and zone data stay local:
--   client_scripts { '@rsg-core/client/zones.lua', ... }
--
--   local zone = zones.sphere({ coords = vec3(...), radius = 2.0, debug = false,
--       onEnter = function(self) end, onExit = function(self) end, inside = function(self) end })
--   zones.box({ coords = vec3(...), size = vec3(2, 2, 2), rotation = 45.0, ... })
--   zones.poly({ points = { vec3(...), vec3(...), vec3(...) }, thickness = 4.0, ... })
--   zone:contains(coords)  zone:remove()
--
-- Every zone gets: id, coords (centre), distance (player distance, updated while nearby),
-- insideZone. Any extra fields you pass (options, name, ...) are kept on the zone.
-- Global `Zones` (id -> zone) and `lib.zones` are provided for ox_lib-style code.

local zones = {}
local Zones = {}
local nextId = 0
local insideZones = {}

local UPDATE_INTERVAL = 300 -- ms between enter/exit checks
local NEAR_DISTANCE = 75.0  -- zones further than this skip the contains check

local DrawLine = DrawLine
local sin, cos, rad = math.sin, math.cos, math.rad

---@param p vector3 point relative to the zone centre
---@param heading number degrees
local function toLocal(p, heading)
    if heading == 0 then return p end
    local r = rad(-heading)
    local c, s = cos(r), sin(r)
    return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z)
end

local function headingOf(rotation)
    local t = type(rotation)
    if t == 'number' then return rotation end
    if (t == 'vector3' or t == 'vector4' or t == 'table') and rotation.z then return rotation.z end
    return 0.0
end

---------------------------------------------------------------- shapes

local function sphereContains(self, coords)
    return #(coords - self.coords) <= self.radius
end

local function boxContains(self, coords)
    local p = toLocal(coords - self.coords, self.heading)
    local h = self.half
    return p.x >= -h.x and p.x <= h.x and p.y >= -h.y and p.y <= h.y and p.z >= -h.z and p.z <= h.z
end

local function polyContains(self, coords)
    if coords.z < self.minZ or coords.z > self.maxZ then return false end

    local pts, inside = self.points, false
    local j = #pts
    local x, y = coords.x, coords.y

    for i = 1, #pts do
        local a, b = pts[i], pts[j]
        if (a.y > y) ~= (b.y > y) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x then
            inside = not inside
        end
        j = i
    end

    return inside
end

---------------------------------------------------------------- debug drawing

local function line(a, b, c)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, c[1], c[2], c[3], c[4])
end

local function drawBox(self)
    local h, c = self.half, self.debugColour
    local r = rad(self.heading)
    local cs, sn = cos(r), sin(r)
    local o = self.coords
    local corners = {}

    for i, d in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
        local x, y = d[1] * h.x, d[2] * h.y
        local wx, wy = o.x + x * cs - y * sn, o.y + x * sn + y * cs
        corners[i] = { vec3(wx, wy, o.z - h.z), vec3(wx, wy, o.z + h.z) }
    end

    for i = 1, 4 do
        local n = corners[i % 4 + 1]
        line(corners[i][1], n[1], c)
        line(corners[i][2], n[2], c)
        line(corners[i][1], corners[i][2], c)
    end
end

local function drawPoly(self)
    local pts, c = self.points, self.debugColour
    for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        local a1, b1 = vec3(a.x, a.y, self.minZ), vec3(b.x, b.y, self.minZ)
        local a2, b2 = vec3(a.x, a.y, self.maxZ), vec3(b.x, b.y, self.maxZ)
        line(a1, b1, c); line(a2, b2, c); line(a1, a2, c)
    end
end

local function drawSphere(self)
    local o, r, c = self.coords, self.radius, self.debugColour
    local steps = 16
    for ring = 0, 2 do
        local prev
        for i = 0, steps do
            local a = (i / steps) * math.pi * 2
            local p = ring == 0 and vec3(o.x + cos(a) * r, o.y + sin(a) * r, o.z)
                or ring == 1 and vec3(o.x + cos(a) * r, o.y, o.z + sin(a) * r)
                or vec3(o.x, o.y + cos(a) * r, o.z + sin(a) * r)
            if prev then line(prev, p, c) end
            prev = p
        end
    end
end

---------------------------------------------------------------- zone object

local Zone = {}
Zone.__index = Zone

function Zone:remove()
    if not Zones[self.id] then return end
    Zones[self.id] = nil
    if insideZones[self.id] then
        insideZones[self.id] = nil
        self.insideZone = false
        if self.onExit then pcall(self.onExit, self) end
    end
end

local function register(data, shape)
    nextId += 1
    data.id = nextId
    data.__type = shape
    data.distance = math.huge
    data.insideZone = false
    data.debugColour = data.debugColour or { 255, 42, 24, 180 }
    setmetatable(data, Zone)
    Zones[data.id] = data
    return data
end

local function toVec3(v)
    return vec3(v.x + 0.0, v.y + 0.0, (v.z or 0) + 0.0)
end

---@param data table { coords, radius = 2.0 }
function zones.sphere(data)
    data.coords = toVec3(data.coords)
    data.radius = (data.radius or 2.0) + 0.0
    data.contains = sphereContains
    data.draw = drawSphere
    return register(data, 'sphere')
end

---@param data table { coords, size = vec3(2,2,2), rotation = 0 }
function zones.box(data)
    data.coords = toVec3(data.coords)
    data.size = data.size and toVec3(data.size) or vec3(2.0, 2.0, 2.0)
    data.half = data.size / 2
    data.heading = headingOf(data.rotation) + 0.0
    data.contains = boxContains
    data.draw = drawBox
    return register(data, 'box')
end

---@param data table { points = vec3[], thickness = 4.0 }
function zones.poly(data)
    local pts, n = {}, #data.points
    local sx, sy, sz = 0.0, 0.0, 0.0
    for i = 1, n do
        local p = toVec3(data.points[i])
        pts[i] = p
        sx, sy, sz = sx + p.x, sy + p.y, sz + p.z
    end

    local thickness = (data.thickness or 4.0) + 0.0
    data.points = pts
    data.thickness = thickness
    data.coords = vec3(sx / n, sy / n, sz / n)
    data.minZ = data.coords.z - thickness / 2
    data.maxZ = data.coords.z + thickness / 2
    data.contains = polyContains
    data.draw = drawPoly
    return register(data, 'poly')
end

function zones.getAllZones() return Zones end

function zones.getCurrentZones()
    local out = {}
    for id in pairs(insideZones) do out[#out + 1] = Zones[id] end
    return out
end

function zones.getNearbyZones()
    local out = {}
    for _, z in pairs(Zones) do
        if z.distance <= NEAR_DISTANCE then out[#out + 1] = z end
    end
    return out
end

---------------------------------------------------------------- update loops

local function hasActive()
    return next(Zones) ~= nil
end

-- distance / enter / exit
CreateThread(function()
    while true do
        if hasActive() then
            local coords = GetEntityCoords(PlayerPedId())

            for id, z in pairs(Zones) do
                z.distance = #(coords - z.coords)
                local inside = z.distance <= NEAR_DISTANCE and z:contains(coords)

                if inside and not z.insideZone then
                    z.insideZone = true
                    insideZones[id] = true
                    if z.onEnter then pcall(z.onEnter, z) end
                elseif not inside and z.insideZone then
                    z.insideZone = false
                    insideZones[id] = nil
                    if z.onExit then pcall(z.onExit, z) end
                end
            end
        end

        Wait(UPDATE_INTERVAL)
    end
end)

-- per-frame: `inside` callbacks + debug drawing (only while something needs it)
CreateThread(function()
    while true do
        local busy = false

        for id, z in pairs(Zones) do
            if z.debug and z.distance <= NEAR_DISTANCE then
                busy = true
                z:draw()
            end
            if z.inside and insideZones[id] then
                busy = true
                pcall(z.inside, z)
            end
        end

        Wait(busy and 0 or 500)
    end
end)

-- globals for ox_lib-style code
_ENV.zones = zones
_ENV.Zones = Zones
if type(lib) == 'table' and rawget(lib, 'zones') == nil then
    rawset(lib, 'zones', zones)
end
