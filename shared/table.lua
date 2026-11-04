-- rsg-core table helpers (replaces ox_lib table.type / table.clone / table.contains / table.wipe)
--
-- Loaded by rsg-core itself. Other resources:
--   shared_scripts { '@rsg-core/shared/table.lua', ... }
-- Only fills in functions the runtime does not already provide.

---Returns 'empty', 'array', 'hash' or 'mixed'
---@param tbl table
---@return string
table.type = table.type or function(tbl)
    local size = #tbl
    local n = 0

    for k in pairs(tbl) do
        n += 1
        if type(k) ~= 'number' or k < 1 or k > size or math.type(k) ~= 'integer' then
            return size > 0 and 'mixed' or 'hash'
        end
    end

    if n == 0 then return 'empty' end
    return n == size and 'array' or 'mixed'
end

---Clears every key, keeping the same table reference
---@param tbl table
---@return table
table.wipe = table.wipe or function(tbl)
    for k in pairs(tbl) do tbl[k] = nil end
    return tbl
end

---Shallow copy (deep = true copies nested tables)
---@param tbl table
---@param deep? boolean
---@return table
table.clone = table.clone or function(tbl, deep)
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = (deep and type(v) == 'table') and table.clone(v, true) or v
    end
    return setmetatable(out, getmetatable(tbl))
end

---True when the array contains value (or any of the values in a table)
---@param tbl table
---@param value any
---@return boolean
table.contains = table.contains or function(tbl, value)
    if type(value) ~= 'table' then
        for _, v in pairs(tbl) do if v == value then return true end end
        return false
    end

    for _, want in pairs(value) do
        if not table.contains(tbl, want) then return false end
    end
    return true
end
