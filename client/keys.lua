-- rsg-core key mappings: one helper for rebindable keys (RegisterKeyMapping + a +/- command pair).
-- Players rebind these in the game's key settings, so the key in your config is only the default.

local keys = {}      -- [name] = { press = fn, release = fn, owner = resource|nil, opts = {}, down = false }
local registered = {} -- [name] = true once the command pair and mapping exist (they can't be removed again)

local function canTrigger(entry)
    local opts = entry.opts
    if opts.requireLogin ~= false and not LocalPlayer.state.isLoggedIn then return false end
    if not opts.allowWhileNui and IsNuiFocused() then return false end
    if opts.canTrigger then
        local ok, result = pcall(opts.canTrigger)
        if not ok or not result then return false end
    end
    return true
end

local function call(fn, name)
    if not fn then return end
    local ok, err = pcall(fn)
    if not ok then
        print(('^1[rsg-core] key "%s" handler error: %s^7'):format(name, tostring(err)))
    end
end

---Register a rebindable key.
---@param name string unique id, becomes the command `+name` / `-name`
---@param description string text shown in the game's key settings (pass locale('...'))
---@param defaultKey string default key name, for example 'I', 'Z', '1', 'F5'
---@param onPress fun()|nil called when the key goes down
---@param onRelease fun()|nil called when the key goes up (only if the press was accepted)
---@param opts? { mapper?: string, requireLogin?: boolean, allowWhileNui?: boolean, canTrigger?: fun(): boolean }
---@return boolean ok
function RSGCore.Functions.RegisterKey(name, description, defaultKey, onPress, onRelease, opts)
    if type(name) ~= 'string' or name == '' or type(defaultKey) ~= 'string' then
        print('^1[rsg-core] RegisterKey needs a name and a default key^7')
        return false
    end

    -- handlers from a stopped resource are dropped (see onResourceStop), so a restart can register again
    keys[name] = {
        press = onPress,
        release = onRelease,
        owner = GetInvokingResource(),
        opts = opts or {},
        down = false,
    }

    if registered[name] then return true end
    registered[name] = true

    RegisterCommand('+' .. name, function()
        local entry = keys[name]
        if not entry or not canTrigger(entry) then return end
        entry.down = true
        call(entry.press, name)
    end, false)

    RegisterCommand('-' .. name, function()
        local entry = keys[name]
        if not entry or not entry.down then return end
        entry.down = false
        call(entry.release, name)
    end, false)

    RegisterKeyMapping('+' .. name, description or name, (opts and opts.mapper) or 'keyboard', defaultKey)
    return true
end

---Stop a key from doing anything (the mapping stays in the player's key settings until the next restart).
---@param name string
function RSGCore.Functions.UnregisterKey(name)
    keys[name] = nil
end

AddEventHandler('onResourceStop', function(resource)
    for name, entry in pairs(keys) do
        if entry.owner == resource then keys[name] = nil end
    end
end)
