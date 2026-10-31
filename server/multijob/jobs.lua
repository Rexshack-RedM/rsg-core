-- Merged from rsg-multijob (github.com/Rexshack-RedM/rsg-multijob)
-----------------------------------------------------------------------
-- Job registry
--
-- rsg-core owns every job definition. They live in the
-- `multijob_jobs` table and are pushed into RSGCore.Shared.Jobs at runtime with
-- RSGCore.Functions.AddJob / UpdateJob / RemoveJob, which also sync
-- RSGCore.Shared.Jobs to every client.
--
-- Exposes a global `JobRegistry` for the rest of rsg-core.
-----------------------------------------------------------------------

local Config = RSGConfig.MultiJob

JobRegistry = {}

local jobs = {}       -- name -> definition (core shape + icon)
local loaded = false

local MAX_GRADES = 25
local MAX_PAYMENT = 1000000

-----------------------------------------------------------------------
-- Validation
-----------------------------------------------------------------------

local function trim(s)
    if type(s) ~= 'string' then return '' end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Validates and normalises a job definition from any source
--- (NUI, seed file, rsg-core). Grades may be an array (index 1 = grade 0)
--- or a table keyed by grade level ('0', '1', ...).
--- @return table|nil def, string|nil err  (err is a locale key)
local function Sanitize(input)
    if type(input) ~= 'table' then return nil, 'adm_err_invalid' end

    local name = trim(input.name):lower()
    if #name < 2 or #name > 50 or not name:match('^[a-z0-9_]+$') then
        return nil, 'adm_err_name'
    end

    local label = trim(input.label)
    if label == '' or #label > 100 then return nil, 'adm_err_label' end

    local jtype = trim(input.type)
    if #jtype > 50 or (jtype ~= '' and not jtype:match('^[%w_%-]+$')) then
        return nil, 'adm_err_type'
    end

    local icon = trim(input.icon)
    if #icon > 100 or not icon:match('^[%w%s%-]*$') then return nil, 'adm_err_icon' end

    if type(input.grades) ~= 'table' then return nil, 'adm_err_grades' end

    -- Collect grades by numeric level
    local byLevel, count = {}, 0
    if input.grades[1] ~= nil then
        for i, g in ipairs(input.grades) do
            byLevel[i - 1] = g
            count = count + 1
        end
    else
        for k, g in pairs(input.grades) do
            local lvl = tonumber(k)
            if not lvl or lvl ~= math.floor(lvl) or lvl < 0 then return nil, 'adm_err_grades' end
            byLevel[lvl] = g
            count = count + 1
        end
    end

    if count < 1 or count > MAX_GRADES then return nil, 'adm_err_grades' end

    local grades = {}
    for lvl = 0, count - 1 do
        local g = byLevel[lvl]
        if type(g) ~= 'table' then return nil, 'adm_err_grades' end -- must be 0..n-1 with no gaps

        local gname = trim(g.name)
        if gname == '' or #gname > 50 then return nil, 'adm_err_grade_name' end

        local pay = tonumber(g.payment) or 0
        if pay ~= pay or pay < 0 or pay > MAX_PAYMENT then return nil, 'adm_err_payment' end

        grades[tostring(lvl)] = {
            name = gname,
            payment = pay,
            isboss = (g.isboss == true or g.isboss == 1) or nil,
        }
    end

    return {
        name = name,
        label = label,
        type = jtype ~= '' and jtype or nil,
        icon = icon ~= '' and icon or nil,
        defaultDuty = input.defaultDuty == true or input.defaultDuty == 1,
        offDutyPay = input.offDutyPay == true or input.offDutyPay == 1,
        grades = grades,
    }, nil
end

JobRegistry.Sanitize = Sanitize

-----------------------------------------------------------------------
-- rsg-core sync
-----------------------------------------------------------------------

local function CoreShape(def)
    return {
        name = def.name,
        label = def.label,
        type = def.type,
        defaultDuty = def.defaultDuty,
        offDutyPay = def.offDutyPay,
        grades = def.grades,
    }
end

-- Fresh copy of rsg-core's job table (the RSGCore object in this
-- resource is a snapshot taken at start, so it goes stale).
local function CoreJobs()
    return RSGCore.Shared.Jobs or {}
end

local function PushToCore(def, coreJobs)
    local job = CoreShape(def)
    local exists = (coreJobs or CoreJobs())[def.name] ~= nil

    local ok, res, err = pcall(function()
        if exists then
            return RSGCore.Functions.UpdateJob(def.name, job)
        end
        return RSGCore.Functions.AddJob(def.name, job)
    end)

    if not ok or res == false then
        print(('[rsg-core:jobs] WARNING: rsg-core rejected job "%s": %s'):format(def.name, tostring(ok and err or res)))
        return false
    end

    return true
end

local function RemoveFromCore(name)
    local ok, res, err = pcall(RSGCore.Functions.RemoveJob, name)
    if not ok or res == false then
        print(('[rsg-core:jobs] WARNING: rsg-core could not remove job "%s": %s'):format(name, tostring(ok and err or res)))
    end
end

-----------------------------------------------------------------------
-- Database
-----------------------------------------------------------------------

local CREATE_SQL = [[
CREATE TABLE IF NOT EXISTS `multijob_jobs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NULL DEFAULT NULL,
    `icon` VARCHAR(100) NULL DEFAULT NULL,
    `default_duty` TINYINT(1) NOT NULL DEFAULT 1,
    `off_duty_pay` TINYINT(1) NOT NULL DEFAULT 0,
    `grades` LONGTEXT NOT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`name`)
)]]

local UPSERT_SQL = [[
INSERT INTO multijob_jobs (name, label, type, icon, default_duty, off_duty_pay, grades)
VALUES (?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE label = VALUES(label), type = VALUES(type), icon = VALUES(icon),
    default_duty = VALUES(default_duty), off_duty_pay = VALUES(off_duty_pay), grades = VALUES(grades)]]

local function WriteRow(def)
    MySQL.query.await(UPSERT_SQL, {
        def.name, def.label, def.type, def.icon,
        def.defaultDuty and 1 or 0, def.offDutyPay and 1 or 0,
        json.encode(def.grades),
    })
end

local function FromRow(row)
    local ok, grades = pcall(json.decode, row.grades or '')
    return Sanitize({
        name = row.name,
        label = row.label,
        type = row.type,
        icon = row.icon,
        defaultDuty = row.default_duty == 1 or row.default_duty == true,
        offDutyPay = row.off_duty_pay == 1 or row.off_duty_pay == true,
        grades = ok and grades or nil,
    })
end

-- Copies a job from another source (seed file / rsg-core) into the DB.
local function ImportJob(name, src)
    if type(src) ~= 'table' then return false end
    local input = {}
    for k, v in pairs(src) do input[k] = v end
    input.name = name
    input.icon = input.icon or Config.JobIcons[name]

    local def, err = Sanitize(input)
    if not def then
        print(('[rsg-core:jobs] WARNING: skipped importing job "%s" (%s)'):format(tostring(name), err))
        return false
    end

    WriteRow(def)
    return true
end

-----------------------------------------------------------------------
-- Player fix-ups after a job changes or disappears
-----------------------------------------------------------------------

local function UnemployedJson()
    local u = jobs['unemployed']
    local g = u and u.grades['0'] or {}
    return json.encode({
        name = 'unemployed',
        label = u and u.label or 'Civilian',
        payment = g.payment or 0,
        onduty = false,
        isboss = false,
        grade = { name = g.name or 'Freelancer', level = 0 },
    })
end

-- Re-applies the job to online holders so label/payment/grades refresh,
-- clamping anyone whose grade no longer exists.
local function RefreshHolders(def)
    local maxLevel = -1
    for k in pairs(def.grades) do maxLevel = math.max(maxLevel, tonumber(k)) end

    MySQL.update.await('UPDATE player_jobs SET grade = ? WHERE job = ? AND grade > ?', { maxLevel, def.name, maxLevel })

    for _, Player in pairs(RSGCore.Functions.GetRSGPlayers() or {}) do
        local job = Player.PlayerData.job
        if job and job.name == def.name then
            local level = math.min(tonumber(job.grade and job.grade.level) or 0, maxLevel)
            local duty = job.onduty
            Player.Functions.SetJob(def.name, level)
            Player.Functions.SetJobDuty(duty)
        end
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

function JobRegistry.IsLoaded() return loaded end

--- Core-shaped definition (with icon) or nil
function JobRegistry.Get(name)
    if type(name) ~= 'string' then return nil end
    if not loaded then return RSGCore.Shared.Jobs[name] end
    return jobs[name]
end

function JobRegistry.All() return jobs end

--- Creates or updates a job. input is validated here.
--- @return table|nil def, string|nil errKey
function JobRegistry.Save(input, isNew)
    local def, err = Sanitize(input)
    if not def then return nil, err end

    if isNew and jobs[def.name] then return nil, 'adm_err_exists' end
    if not isNew and not jobs[def.name] then return nil, 'adm_err_missing' end

    WriteRow(def)
    jobs[def.name] = def
    PushToCore(def)
    if not isNew then RefreshHolders(def) end

    return def, nil
end

--- Deletes a job: removes it from rsg-core, every player's multijob list,
--- and drops anyone using it (online or offline) to unemployed.
--- @return boolean ok, string|nil errKey, number holders
function JobRegistry.Delete(name)
    if name == 'unemployed' then return false, 'adm_err_unemployed', 0 end
    if not jobs[name] then return false, 'adm_err_missing', 0 end

    local holders = MySQL.update.await('DELETE FROM player_jobs WHERE job = ?', { name }) or 0
    MySQL.update.await('DELETE FROM multijob_jobs WHERE name = ?', { name })

    for _, Player in pairs(RSGCore.Functions.GetRSGPlayers() or {}) do
        if Player.PlayerData.job and Player.PlayerData.job.name == name then
            Player.Functions.SetJob('unemployed', 0)
        end
    end

    MySQL.update.await(
        "UPDATE players SET job = ? WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?",
        { UnemployedJson(), name }
    )

    jobs[name] = nil
    RemoveFromCore(name)

    return true, nil, holders
end

--- Imports any jobs rsg-core knows about that aren't managed here yet
--- (e.g. ones another resource registered, or left in shared/jobs.lua).
--- @return number imported
function JobRegistry.ImportFromCore()
    local imported = 0
    for name, job in pairs(CoreJobs()) do
        if not jobs[name] and ImportJob(name, job) then
            local row = MySQL.single.await('SELECT * FROM multijob_jobs WHERE name = ?', { name })
            local def = row and FromRow(row)
            if def then
                jobs[name] = def
                imported = imported + 1
            end
        end
    end
    return imported
end

--- { [job] = count } of players holding each job in their multijob list
function JobRegistry.HolderCounts()
    local counts = {}
    for _, row in ipairs(MySQL.query.await('SELECT job, COUNT(*) AS c FROM player_jobs GROUP BY job') or {}) do
        counts[row.job] = tonumber(row.c) or 0
    end
    return counts
end

-----------------------------------------------------------------------
-- Startup
-----------------------------------------------------------------------

MySQL.ready(function()
    MySQL.query.await(CREATE_SQL)
    MySQL.query.await([[
CREATE TABLE IF NOT EXISTS `player_jobs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
)]])

    local rows = MySQL.query.await('SELECT * FROM multijob_jobs') or {}

    if #rows == 0 then
        -- First run: take whatever rsg-core has (your existing jobs.lua),
        -- then fill gaps from shared/default_jobs.lua.
        local seeded = {}
        for name, job in pairs(CoreJobs()) do
            if ImportJob(name, job) then seeded[name] = true end
        end
        for name, job in pairs(MultiJobDefaultJobs or {}) do
            if not seeded[name] and ImportJob(name, job) then seeded[name] = true end
        end
        rows = MySQL.query.await('SELECT * FROM multijob_jobs') or {}
        print(('[rsg-core:jobs] First start: imported %d job(s) into multijob_jobs'):format(#rows))
    end

    local coreJobs = CoreJobs()
    local count = 0
    for _, row in ipairs(rows) do
        local def, err = FromRow(row)
        if def then
            jobs[def.name] = def
            PushToCore(def, coreJobs)
            count = count + 1
        else
            print(('[rsg-core:jobs] WARNING: job "%s" in multijob_jobs is invalid (%s) and was not loaded'):format(tostring(row.name), err))
        end
    end

    if not jobs['unemployed'] then
        print('[rsg-core:jobs] WARNING: no "unemployed" job defined - rsg-core needs one. Create it in /jobadmin.')
    end

    loaded = true
    print(('[rsg-core:jobs] Registered %d job(s) with rsg-core'):format(count))
    TriggerEvent('rsg-multijob:server:jobsLoaded')
end)
