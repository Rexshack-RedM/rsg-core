-- rsg-core locale system (replaces ox_lib 'locale')
-- Language comes from the convar 'rsg:locale' (falls back to 'ox:locale', then 'en').
-- Missing keys fall back to en.json, then to the key itself.

local resource = GetCurrentResourceName()
local strings, fallback = {}, {}

local function loadFile(lang)
    local raw = LoadResourceFile(resource, ('locales/%s.json'):format(lang))
    if not raw then return nil end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then
        print(('^1[rsg-core] locales/%s.json is not valid JSON^7'):format(lang))
        return nil
    end
    return data
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
---@param key string
---@param ... any
---@return string
function locale(key, ...)
    local str = strings[key] or fallback[key]
    if not str then return key end
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
