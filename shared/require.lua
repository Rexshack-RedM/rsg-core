-- rsg-core module loader (replaces ox_lib's require)
--
-- In any resource:
--   shared_scripts { '@rsg-core/shared/require.lua', ... }
--
--   local clothing = require 'data.clothing'        -- <this resource>/data/clothing.lua
--   local cfg      = require 'shared.config'        -- or shared/config/init.lua
--   local other    = require '@rsg-inventory.shared.items' -- file from another started resource
--
-- Modules are cached per resource and side (client/server), like Lua's package.loaded.
-- A module that returns nothing is cached as true.

local currentResource = GetCurrentResourceName()
local loaded = package and package.loaded or {}
local loading = {}
local templates = { '%s.lua', '%s/init.lua' }

local function findFile(resource, path)
    for i = 1, #templates do
        local file = templates[i]:format(path)
        local src = LoadResourceFile(resource, file)
        if src then return src, file end
    end
end

local builtinRequire = require

---@param modname string
---@return any
function require(modname)
    if type(modname) ~= 'string' then
        error(('module name must be a string (received %s)'):format(type(modname)), 2)
    end

    local cached = loaded[modname]
    if cached ~= nil then return cached end
    if loading[modname] then
        error(('circular require of module \'%s\''):format(modname), 2)
    end

    local resource, path = currentResource, modname
    local ext, rest = modname:match('^@(.-)%.(.+)$')
    if ext then resource, path = ext, rest end
    path = path:gsub('%.', '/')

    local src, file = findFile(resource, path)
    if not src then
        -- let Lua's own require handle standard modules, if the runtime has one
        if builtinRequire and not ext then
            local ok, result = pcall(builtinRequire, modname)
            if ok then return result end
        end
        error(('module \'%s\' not found (looked for %s/%s.lua and %s/%s/init.lua)'):format(modname, resource, path, resource, path), 2)
    end

    local chunk, err = load(src, ('@@%s/%s'):format(resource, file), 't', _ENV)
    if not chunk then error(err, 2) end

    loading[modname] = true
    local ok, result = pcall(chunk, modname)
    loading[modname] = nil
    if not ok then error(result, 2) end

    if result == nil then result = true end
    loaded[modname] = result
    return result
end
