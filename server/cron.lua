-- RSGCore cron scheduler (replaces lib.cron from ox_lib)
-- RSGCore.Functions.CreateCron(expression, job, options) / exports['rsg-core']:CreateCron(...)
-- expression: 5-field cron 'min hour day month weekday' (server local time)
--   supports *, n, a-b, a,b,c, */n, a-b/n, month names (jan-dec), day names (sun-sat, 0 or 7 = sunday)
--   and the macros @yearly @annually @monthly @weekly @daily @midnight @hourly
-- job(task, date) runs at most once per matching minute; errors are caught and printed
-- options: { debug = bool }
-- returns task: task:stop(), task:run(), task:isActive(), task.id, task.expression, task.resource
-- tasks are stopped automatically when the resource that created them stops

local Tasks = {}
local NextId = 0

local Macros = {
    ['@yearly'] = '0 0 1 1 *', ['@annually'] = '0 0 1 1 *',
    ['@monthly'] = '0 0 1 * *', ['@weekly'] = '0 0 * * 0',
    ['@daily'] = '0 0 * * *', ['@midnight'] = '0 0 * * *',
    ['@hourly'] = '0 * * * *',
}

local Names = {
    month = { jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12 },
    wday = { sun = 0, mon = 1, tue = 2, wed = 3, thu = 4, fri = 5, sat = 6 },
}

local Ranges = {
    { 0, 59 },  -- minute
    { 0, 23 },  -- hour
    { 1, 31 },  -- day of month
    { 1, 12 },  -- month
    { 0, 7 },   -- day of week (0/7 = sunday)
}

local function toNumber(value, names)
    local n = tonumber(value)
    if n then return n end
    return names and names[value:lower()]
end

-- parse one field into a lookup set { [value] = true }; returns nil on error
local function parseField(field, index)
    local min, max = Ranges[index][1], Ranges[index][2]
    local names = (index == 4 and Names.month) or (index == 5 and Names.wday) or nil
    local set = {}

    for part in field:gmatch('[^,]+') do
        local base, step = part:match('^(.-)/(%d+)$')
        base = base or part
        step = tonumber(step) or 1
        if step < 1 then return nil end

        local lo, hi
        if base == '*' then
            lo, hi = min, max
        else
            local a, b = base:match('^(%w+)-(%w+)$')
            if a then
                lo, hi = toNumber(a, names), toNumber(b, names)
            else
                lo = toNumber(base, names)
                hi = (part:find('/') and max) or lo
            end
        end

        if not lo or not hi or lo < min or hi > max or lo > hi then return nil end
        for v = lo, hi, step do set[v] = true end
    end

    if index == 5 and set[7] then set[0] = true end
    return set
end

local function parseExpression(expression)
    if type(expression) ~= 'string' then return nil end
    expression = Macros[expression:lower()] or expression

    local fields = {}
    for f in expression:gmatch('%S+') do fields[#fields + 1] = f end
    if #fields ~= 5 then return nil end

    local parsed = {}
    for i = 1, 5 do
        parsed[i] = parseField(fields[i], i)
        if not parsed[i] then return nil end
    end
    -- standard cron: if both day fields are restricted, either may match
    parsed.domAny = fields[3] == '*'
    parsed.dowAny = fields[5] == '*'
    return parsed
end

local function matches(p, t)
    if not (p[1][t.min] and p[2][t.hour] and p[4][t.month]) then return false end
    local dom, dow = p[3][t.day], p[5][t.wday - 1]
    if p.domAny or p.dowAny then return dom and dow end
    return dom or dow
end

local Task = {}
Task.__index = Task

function Task:run(date)
    local ok, err = pcall(self.job, self, date or os.date('*t'))
    if not ok then
        print(('^1[rsg-core] cron task %s (%s) from %s failed: %s^7'):format(self.id, self.expression, self.resource, tostring(err)))
    elseif self.debug then
        print(('^2[rsg-core] cron task %s (%s) from %s ran^7'):format(self.id, self.expression, self.resource))
    end
end

function Task:stop()
    Tasks[self.id] = nil
end

function Task:isActive()
    return Tasks[self.id] ~= nil
end

function RSGCore.Functions.CreateCron(expression, job, options)
    local parsed = parseExpression(expression)
    if not parsed then
        error(('rsg-core cron: invalid expression "%s"'):format(tostring(expression)), 2)
    end
    if type(job) ~= 'function' and type(job) ~= 'table' then
        error('rsg-core cron: job must be a function', 2)
    end

    NextId = NextId + 1
    local task = setmetatable({
        id = NextId,
        expression = expression,
        parsed = parsed,
        job = job,
        debug = options and options.debug or false,
        resource = GetInvokingResource() or GetCurrentResourceName(),
    }, Task)
    Tasks[task.id] = task
    return task
end

-- stop a task by id (useful from other resources, where task methods may not cross the export boundary)
function RSGCore.Functions.StopCron(id)
    if type(id) == 'table' then id = id.id end
    if not Tasks[id] then return false end
    Tasks[id] = nil
    return true
end

exports('CreateCron', RSGCore.Functions.CreateCron)
exports('StopCron', RSGCore.Functions.StopCron)

AddEventHandler('onResourceStop', function(resource)
    for id, task in pairs(Tasks) do
        if task.resource == resource then Tasks[id] = nil end
    end
end)

CreateThread(function()
    local lastMinute
    while true do
        local key = os.date('%Y%m%d%H%M')
        if key ~= lastMinute then
            lastMinute = key
            local t = os.date('*t')
            for _, task in pairs(Tasks) do
                if matches(task.parsed, t) then
                    CreateThread(function() task:run(t) end)
                end
            end
        end
        Wait(1000)
    end
end)
