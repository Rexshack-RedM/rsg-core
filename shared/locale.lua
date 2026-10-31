-- rsg-core locale system (replaces ox_lib 'locale')
--
-- Used by rsg-core itself AND shared with every other resource. In any resource:
--
--   shared_scripts { '@rsg-core/shared/locale.lua', ... }
--   files { 'locales/*.json' }
--
-- then call locale('key', ...) in client and server files. No lib.locale() call is needed.
-- The file runs inside the including resource, so it reads THAT resource's locales/*.json.
--
-- Language: convar 'rsg:locale' (falls back to 'ox:locale', then 'en').
-- Use setr in server.cfg so clients see the same language:  setr rsg:locale "en"
--
-- Compatible with ox_lib locale files:
--   * nested tables are flattened to dot keys  { "a": { "b": "x" } }  ->  locale('a.b')
--   * "${other.key}" inside a string is replaced with that key's text
-- Missing keys fall back to en.json, then to the key itself.

local resource = GetCurrentResourceName()
local strings, fallback = {}, {}

local function flatten(src, out, prefix)
    for k, v in pairs(src) do
        local key = prefix and (prefix .. '.' .. k) or tostring(k)
        if type(v) == 'table' then
            flatten(v, out, key)
        else
            out[key] = v
        end
    end
    return out
end

local function resolveRefs(dict)
    for k, v in pairs(dict) do
        if type(v) == 'string' and v:find('${', 1, true) then
            dict[k] = v:gsub('%${([%w_%.%-]+)}', function(ref)
                local r = dict[ref]
                return type(r) == 'string' and r or nil
            end)
        end
    end
    return dict
end

local function loadFile(lang)
    local raw = LoadResourceFile(resource, ('locales/%s.json'):format(lang))
    if not raw then return nil end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        print(('^1[%s] locales/%s.json is not valid JSON^7'):format(resource, lang))
        return nil
    end
    return resolveRefs(flatten(data, {}))
end

local function getLanguage()
    local lang = GetConvar('rsg:locale', '')
    if lang == '' then lang = GetConvar('ox:locale', 'en') end
    return lang
end

local function load()
    fallback = loadFile('en') or {}
    local lang = getLanguage()
    strings = (lang ~= 'en' and loadFile(lang)) or fallback
end

load()

---Get a translated string. Extra arguments are passed to string.format.
---Called with no key it returns the whole (flattened) dictionary.
---@param key? string
---@param ... any
---@return string|table
function locale(key, ...)
    if key == nil then return strings end
    local str = strings[key] or fallback[key]
    if type(str) ~= 'string' then return key end
    if select('#', ...) > 0 then
        local ok, out = pcall(string.format, str, ...)
        return ok and out or str
    end
    return str
end

---Returns the active language code
function GetLocaleLanguage()
    return getLanguage()
end

-- Resources still calling lib.locale() keep working without ox_lib loaded.
if lib == nil then
    lib = { locale = function() end }
end
