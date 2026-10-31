-- Merged from rsg-multijob (github.com/Rexshack-RedM/rsg-multijob)
-----------------------------------------------------------------------
-- Job admin panel (/jobadmin)
-- Every callback re-checks permission server-side; the NUI is never trusted.
-----------------------------------------------------------------------

local Config = RSGConfig.MultiJob

local function registerCallback(name, fn)
    RSGCore.Functions.CreateCallback(name, function(source, cb, ...)
        cb(fn(source, ...))
    end)
end

local lastAction = {}
local THROTTLE_MS = 500

local function IsAdmin(src)
    return src and src > 0 and RSGCore.Functions.HasPermission(src, Config.Admin.Permission) == true
end

local function Throttled(src)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < THROTTLE_MS then return true end
    lastAction[src] = now
    return false
end

local function AdminTag(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return GetPlayerName(src) or tostring(src) end
    local ci = Player.PlayerData.charinfo or {}
    return ('%s %s (`%s`)'):format(ci.firstname or '', ci.lastname or '', Player.PlayerData.citizenid)
end

-- NUI-friendly list: grades as ordered arrays, sorted by label
local function BuildAdminList()
    local counts = JobRegistry.HolderCounts()
    local online = {}
    for _, Player in pairs(RSGCore.Functions.GetRSGPlayers() or {}) do
        local j = Player.PlayerData.job and Player.PlayerData.job.name
        if j then online[j] = (online[j] or 0) + 1 end
    end

    local list = {}
    for name, def in pairs(JobRegistry.All()) do
        local grades, n = {}, 0
        for _ in pairs(def.grades) do n = n + 1 end
        for lvl = 0, n - 1 do
            local g = def.grades[tostring(lvl)]
            grades[#grades + 1] = { name = g.name, payment = g.payment, isboss = g.isboss == true }
        end

        list[#list + 1] = {
            name = name,
            label = def.label,
            type = def.type or '',
            icon = def.icon or Config.JobIcons[name] or '',
            defaultDuty = def.defaultDuty == true,
            offDutyPay = def.offDutyPay == true,
            grades = grades,
            holders = counts[name] or 0,
            active = online[name] or 0,
        }
    end

    table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    return list
end

local function Result(ok, msgKey, extra, ...)
    local r = extra or {}
    r.ok = ok
    r.message = msgKey and locale(msgKey, ...) or nil
    if ok then r.jobs = BuildAdminList() end
    return r
end

-----------------------------------------------------------------------
-- Command
-----------------------------------------------------------------------

RSGCore.Commands.Add(Config.Admin.Command, locale('cmd_jobadmin_desc'), {}, false, function(source)
    if not JobRegistry.IsLoaded() then
        TriggerClientEvent('RSGCore:Client:Notify', source, { title = locale('title_error'), description = locale('adm_err_not_loaded'), type = 'error' })
        return
    end
    TriggerClientEvent('rsg-multijob:client:openAdmin', source)
end, Config.Admin.Permission)

-----------------------------------------------------------------------
-- Callbacks
-----------------------------------------------------------------------

registerCallback('rsg-multijob:server:admin:getJobs', function(source)
    if not IsAdmin(source) or not JobRegistry.IsLoaded() then return nil end
    return BuildAdminList()
end)

registerCallback('rsg-multijob:server:admin:saveJob', function(source, job, isNew)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) then return { ok = false, message = locale('adm_err_slow') } end

    isNew = isNew == true
    local def, err = JobRegistry.Save(job, isNew)
    if not def then return Result(false, err) end

    local gradeCount = 0
    for _ in pairs(def.grades) do gradeCount = gradeCount + 1 end

    MultiJobWebhook.Send(isNew and 'JobCreated' or 'JobUpdated', {
        description = locale(isNew and 'wh_job_created' or 'wh_job_updated', def.label, def.name),
        fields = {
            { name = locale('wh_field_admin'), value = AdminTag(source), inline = true },
            { name = locale('wh_field_job'), value = ('%s (`%s`)'):format(def.label, def.name), inline = true },
            { name = locale('wh_field_grades'), value = tostring(gradeCount), inline = true },
        }
    })

    return Result(true, isNew and 'adm_ok_created' or 'adm_ok_saved', { saved = def.name }, def.label)
end)

registerCallback('rsg-multijob:server:admin:deleteJob', function(source, name)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) or type(name) ~= 'string' then return { ok = false, message = locale('adm_err_slow') } end

    local def = JobRegistry.Get(name)
    local label = def and def.label or name
    local ok, err, holders = JobRegistry.Delete(name)
    if not ok then return Result(false, err) end

    MultiJobWebhook.Send('JobDefinitionDeleted', {
        description = locale('wh_job_def_deleted', label, name),
        fields = {
            { name = locale('wh_field_admin'), value = AdminTag(source), inline = true },
            { name = locale('wh_field_job'), value = ('%s (`%s`)'):format(label, name), inline = true },
            { name = locale('wh_field_holders'), value = tostring(holders), inline = true },
        }
    })

    return Result(true, 'adm_ok_deleted', nil, label, holders)
end)

registerCallback('rsg-multijob:server:admin:importCore', function(source)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) then return { ok = false, message = locale('adm_err_slow') } end

    local n = JobRegistry.ImportFromCore()
    return Result(true, 'adm_ok_imported', nil, n)
end)

-----------------------------------------------------------------------
-- Employees: give players a job / change grade / remove (admin only)
-----------------------------------------------------------------------

local MAX_HOLDERS = 250

local function charName(charinfo)
    local ci = charinfo
    if type(ci) == 'string' then
        local ok, decoded = pcall(json.decode, ci)
        ci = ok and decoded or nil
    end
    if type(ci) ~= 'table' then return nil end
    local name = (('%s %s'):format(ci.firstname or '', ci.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    return name ~= '' and name or nil
end

-- Everyone holding `job` in their job list (online and offline)
local function HolderList(job)
    local rows = MySQL.query.await([[
        SELECT pj.citizenid, pj.grade, p.charinfo,
               JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.name')) AS active_job
        FROM player_jobs pj
        LEFT JOIN players p ON p.citizenid = pj.citizenid
        WHERE pj.job = ?
        ORDER BY pj.grade DESC
        LIMIT ?]], { job, MAX_HOLDERS }) or {}

    local list = {}
    for _, row in ipairs(rows) do
        local Player = RSGCore.Functions.GetPlayerByCitizenId(row.citizenid)
        local entry = {
            citizenid = row.citizenid,
            grade = tonumber(row.grade) or 0,
            name = charName(Player and Player.PlayerData.charinfo or row.charinfo) or row.citizenid,
            online = Player ~= nil,
            id = Player and Player.PlayerData.source or nil,
            active = (Player and Player.PlayerData.job.name == job) or (not Player and row.active_job == job),
        }
        list[#list + 1] = entry
    end
    return list
end

-- Online characters for the player picker
local function OnlineList()
    local list = {}
    for src, Player in pairs(RSGCore.Functions.GetRSGPlayers() or {}) do
        list[#list + 1] = {
            id = src,
            citizenid = Player.PlayerData.citizenid,
            name = charName(Player.PlayerData.charinfo) or GetPlayerName(src) or tostring(src),
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function EmployeesResult(ok, job, msgKey, ...)
    local r = { ok = ok, message = msgKey and locale(msgKey, ...) or nil }
    if ok then
        r.holders = HolderList(job)
        r.players = OnlineList()
        r.jobs = BuildAdminList() -- refresh holder counts in the job list
    end
    return r
end

-- '12' -> server id 12 (online), anything else -> citizen id
local function ParseIdentifier(value)
    if type(value) == 'number' then return math.floor(value) end
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' or #value > 50 then return nil end
    if value:match('^%d+$') and #value <= 6 then return tonumber(value) end
    if not value:match('^[%w]+$') then return nil end
    return value:upper()
end

local function OnlinePlayer(identifier)
    if type(identifier) == 'number' then return RSGCore.Functions.GetPlayer(identifier) end
    return RSGCore.Functions.GetPlayerByCitizenId(identifier)
end

local function DisplayName(identifier)
    local Player = OnlinePlayer(identifier)
    if Player then return charName(Player.PlayerData.charinfo) or Player.PlayerData.citizenid end
    return tostring(identifier)
end

local reasonKeys = {
    invalid_job = 'adm_err_missing',
    invalid_grade = 'adm_err_grade',
    player_not_found = 'adm_err_player',
    max_jobs = 'adm_err_max_jobs',
    job_not_held = 'adm_err_not_held',
}

-- the job must exist and can't be 'unemployed' (it is never stored in job lists)
local function EmployeeJob(job)
    if type(job) ~= 'string' or job == 'unemployed' then return nil end
    return JobRegistry.Get(job)
end

local function ValidGrade(def, grade)
    grade = tonumber(grade)
    if not grade or grade ~= math.floor(grade) then return nil end
    return def.grades[tostring(grade)] and grade or nil
end

registerCallback('rsg-multijob:server:admin:getHolders', function(source, job)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if not EmployeeJob(job) then return { ok = false, message = locale('adm_err_missing') } end
    return EmployeesResult(true, job)
end)

registerCallback('rsg-multijob:server:admin:assignJob', function(source, data)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) or type(data) ~= 'table' then return { ok = false, message = locale('adm_err_slow') } end

    local def = EmployeeJob(data.job)
    if not def then return { ok = false, message = locale('adm_err_missing') } end
    local grade = ValidGrade(def, data.grade)
    if not grade then return { ok = false, message = locale('adm_err_grade') } end
    local identifier = ParseIdentifier(data.player)
    if not identifier then return { ok = false, message = locale('adm_err_player') } end

    local ok, reason = RSGCore.Functions.AddPlayerJob(identifier, data.job, grade, data.bypassMax == true)
    if not ok then return { ok = false, message = locale(reasonKeys[reason] or 'adm_err_invalid') } end

    -- optionally switch them to it straight away (online players only)
    local Player = OnlinePlayer(identifier)
    if data.makeActive == true and Player and Player.PlayerData.job.name ~= data.job then
        Player.Functions.SetJob(data.job, grade)
    end

    return EmployeesResult(true, data.job, 'adm_ok_assigned', DisplayName(identifier), def.label, def.grades[tostring(grade)].name)
end)

registerCallback('rsg-multijob:server:admin:setGrade', function(source, data)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) or type(data) ~= 'table' then return { ok = false, message = locale('adm_err_slow') } end

    local def = EmployeeJob(data.job)
    if not def then return { ok = false, message = locale('adm_err_missing') } end
    local grade = ValidGrade(def, data.grade)
    if not grade then return { ok = false, message = locale('adm_err_grade') } end
    local identifier = ParseIdentifier(data.citizenid)
    if type(identifier) ~= 'string' then return { ok = false, message = locale('adm_err_player') } end

    -- only re-grade existing holders; this never adds a new job
    if not RSGCore.Functions.HasPlayerJob(identifier, data.job) then
        return { ok = false, message = locale('adm_err_not_held') }
    end

    local ok, reason = RSGCore.Functions.AddPlayerJob(identifier, data.job, grade, true)
    if not ok then return { ok = false, message = locale(reasonKeys[reason] or 'adm_err_invalid') } end

    return EmployeesResult(true, data.job, 'adm_ok_regraded', DisplayName(identifier), def.grades[tostring(grade)].name)
end)

registerCallback('rsg-multijob:server:admin:removeHolder', function(source, data)
    if not IsAdmin(source) then return { ok = false, message = locale('adm_err_perm') } end
    if Throttled(source) or type(data) ~= 'table' then return { ok = false, message = locale('adm_err_slow') } end

    local def = EmployeeJob(data.job)
    if not def then return { ok = false, message = locale('adm_err_missing') } end
    local identifier = ParseIdentifier(data.citizenid)
    if type(identifier) ~= 'string' then return { ok = false, message = locale('adm_err_player') } end

    local name = DisplayName(identifier)
    local ok, reason = RSGCore.Functions.RemovePlayerJob(identifier, data.job)
    if not ok then return { ok = false, message = locale(reasonKeys[reason] or 'adm_err_invalid') } end

    return EmployeesResult(true, data.job, 'adm_ok_removed', name, def.label)
end)

AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)
