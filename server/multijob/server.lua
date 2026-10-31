-- Merged from rsg-multijob (github.com/Rexshack-RedM/rsg-multijob)
local Config = RSGConfig.MultiJob

local function registerCallback(name, fn)
    RSGCore.Functions.CreateCallback(name, function(source, cb, ...)
        cb(fn(source, ...))
    end)
end

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------

local switchCooldowns = {} -- citizenid -> GetGameTimer() value the player may next switch jobs
local actionThrottle = {}  -- source -> GetGameTimer() of last menu action (anti-spam)
local ACTION_THROTTLE_MS = 750

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local function Notify(src, title, description, nType)
    TriggerClientEvent('RSGCore:Client:Notify', src, {
        title = title,
        description = description,
        type = nType or 'inform',
        duration = 5000,
    })
end

local function IsThrottled(src)
    local now = GetGameTimer()
    if actionThrottle[src] and now - actionThrottle[src] < ACTION_THROTTLE_MS then
        return true
    end
    actionThrottle[src] = now
    return false
end

local function JobLabel(job)
    local info = JobRegistry.Get(job)
    return info and info.label or job
end

local function IsValidJobName(job)
    return type(job) == 'string' and job ~= 'unemployed' and JobRegistry.Get(job) ~= nil
end

-- Best-effort display name for webhook logs
local function GetCharName(Player)
    if not Player then return locale('wh_unknown') end

    local info = Player.PlayerData.charinfo
    if info and (info.firstname or info.lastname) then
        return (('%s %s'):format(info.firstname or '', info.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    end

    return GetPlayerName(Player.PlayerData.source) or locale('wh_unknown')
end

local function PlayerTag(Player, cid)
    if Player then
        return ('%s (`%s`)'):format(GetCharName(Player), Player.PlayerData.citizenid)
    end
    return ('`%s`'):format(cid)
end

-- Whether Player currently holds a boss grade in jobName
local function IsBossOf(Player, jobName)
    if not Player or Player.PlayerData.job.name ~= jobName then return false end

    local job = JobRegistry.Get(jobName)
    if not job then return false end

    local grade = job.grades[tostring(Player.PlayerData.job.grade.level)]
    return grade ~= nil and grade.isboss == true
end

-----------------------------------------------------------------------
-- Database
-----------------------------------------------------------------------

local function GetJobCount(cid)
    return MySQL.scalar.await('SELECT COUNT(*) FROM player_jobs WHERE citizenid = ?', { cid }) or 0
end

-- Stored grade for job on cid, or nil if not held
local function GetStoredGrade(cid, job)
    local grade = MySQL.scalar.await('SELECT grade FROM player_jobs WHERE citizenid = ? AND job = ? LIMIT 1', { cid, job })
    return grade and tonumber(grade) or nil
end

-- Builds the { job, salary, jobLabel, gradeLabel, grade } list for a player's stored jobs
local function BuildJobList(cid)
    local list = {}
    local rows = MySQL.query.await('SELECT job, grade FROM player_jobs WHERE citizenid = ?', { cid }) or {}

    for _, row in ipairs(rows) do
        local job = JobRegistry.Get(row.job)
        local grade = job and job.grades[tostring(row.grade)]

        if not job then
            print(('[rsg-core:jobs] WARNING: Missing job definition: "%s" | Citizen ID: %s'):format(row.job, cid))
        elseif not grade then
            print(('[rsg-core:jobs] WARNING: Missing grade %s for job "%s" | Citizen ID: %s'):format(row.grade, row.job, cid))
        else
            list[#list + 1] = {
                job = row.job,
                salary = grade.payment,
                jobLabel = job.label,
                gradeLabel = grade.name,
                grade = row.grade,
                icon = job.icon,
            }
        end
    end

    return list
end

-- Sends the current job list to an online player's open menu
local function PushJobs(Player, currentJob)
    if not Player then return end
    TriggerClientEvent('rsg-multijob:client:refreshJobs', Player.PlayerData.source, BuildJobList(Player.PlayerData.citizenid), currentJob or Player.PlayerData.job.name)
end

-- Offline player: if job is their saved active job, swap it to unemployed
local function SetOfflineUnemployedIfActive(cid, job)
    local raw = MySQL.scalar.await('SELECT job FROM players WHERE citizenid = ? LIMIT 1', { cid })
    if not raw then return end

    local ok, current = pcall(json.decode, raw)
    if not ok or type(current) ~= 'table' or current.name ~= job then return end

    local unemployed = JobRegistry.Get('unemployed')
    local grade = unemployed and unemployed.grades and unemployed.grades['0'] or {}

    MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode({
        name = 'unemployed',
        label = unemployed and unemployed.label or locale('unemployed_label'),
        payment = grade.payment or 0,
        type = unemployed and unemployed.type or nil,
        onduty = false,
        isboss = false,
        grade = { name = grade.name or locale('unemployed_grade'), level = 0 },
    }), cid })
end

-- Removes a stored job; drops the player to unemployed if it was active.
-- Returns true if a row was removed.
local function RemoveStoredJob(cid, Player, job)
    local affected = MySQL.update.await('DELETE FROM player_jobs WHERE citizenid = ? AND job = ?', { cid, job })
    if not affected or affected < 1 then return false end

    if Player then
        if Player.PlayerData.job.name == job then
            Player.Functions.SetJob('unemployed', 0)
        end
        PushJobs(Player)
    else
        SetOfflineUnemployedIfActive(cid, job)
    end

    return true
end

-- Resolves a server id (online) or citizenid (online/offline) to cid + Player.
-- Unknown citizenids return nil so typos can't create orphan rows.
local function ResolvePlayer(identifier)
    if type(identifier) == 'number' then
        local Player = RSGCore.Functions.GetPlayer(identifier)
        if not Player then return nil, nil end
        return Player.PlayerData.citizenid, Player
    end

    if type(identifier) ~= 'string' or identifier == '' then return nil, nil end

    local Player = RSGCore.Functions.GetPlayerByCitizenId(identifier)
    if Player then return Player.PlayerData.citizenid, Player end

    if not MySQL.scalar.await('SELECT 1 FROM players WHERE citizenid = ? LIMIT 1', { identifier }) then
        return nil, nil
    end

    return identifier, nil
end

-----------------------------------------------------------------------
-- Commands
-----------------------------------------------------------------------

RSGCore.Commands.Add('myjobs', locale('cmd_myjobs_desc'), {}, false, function(source)
    TriggerClientEvent('rsg-multijob:client:openmenu', source)
end)

RSGCore.Commands.Add('removejob', locale('cmd_removejob_desc'), {
    { name = 'id', help = locale('cmd_removejob_id') },
    { name = 'job', help = locale('cmd_removejob_job') },
}, true, function(source, args)
    local src = source
    local job = args[2]
    local cid, Player = ResolvePlayer(tonumber(args[1]) or args[1])

    if not cid then
        Notify(src, locale('title_error'), locale('player_not_found'), 'error')
        return
    end

    if not RemoveStoredJob(cid, Player, job) then
        Notify(src, locale('title_error'), locale('job_specified'), 'error')
        return
    end

    Notify(src, locale('title_job_removed'), locale('job_removed_desc', JobLabel(job), args[1]), 'success')

    local Admin = src > 0 and RSGCore.Functions.GetPlayer(src) or nil
    MultiJobWebhook.Send('JobRemovedByAdmin', {
        description = locale('wh_admin_removed', JobLabel(job), Player and GetCharName(Player) or cid),
        fields = {
            { name = locale('wh_field_admin'), value = Admin and PlayerTag(Admin) or locale('wh_console'), inline = true },
            { name = locale('wh_field_target'), value = PlayerTag(Player, cid), inline = true },
            { name = locale('wh_field_job'), value = JobLabel(job), inline = true },
        }
    })
end, 'admin')

-----------------------------------------------------------------------
-- Menu
-----------------------------------------------------------------------

registerCallback('rsg-multijob:server:myJobs', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end

    return BuildJobList(Player.PlayerData.citizenid)
end)

RegisterNetEvent('rsg-multijob:server:changeJob', function(job)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or type(job) ~= 'string' or IsThrottled(src) then return end

    local cid = Player.PlayerData.citizenid
    local now = GetGameTimer()
    local readyAt = switchCooldowns[cid]

    if readyAt and now < readyAt then
        Notify(src, locale('title_cooldown'), locale('cooldown_desc', math.ceil((readyAt - now) / 1000)), 'warning')
        PushJobs(Player) -- undo the menu's instant highlight
        return
    end

    if Player.PlayerData.job.name == job then
        Notify(src, locale('title_current_job'), locale('current_job_error'), 'inform')
        return
    end

    local jobInfo = JobRegistry.Get(job)
    if not jobInfo then
        Notify(src, locale('title_invalid_job'), locale('invalid_job_desc'), 'error')
        return
    end

    local grade = GetStoredGrade(cid, job)
    if grade == nil then
        Notify(src, locale('title_error'), locale('not_hold_job'), 'error')
        return
    end

    local gradeInfo = jobInfo.grades[tostring(grade)]
    if not gradeInfo then
        Notify(src, locale('title_error'), locale('invalid_grade'), 'error')
        return
    end

    switchCooldowns[cid] = now + (Config.JobSwitchCooldown or 3000)

    Player.Functions.SetJob(job, grade)
    Player.Functions.SetJobDuty(false)
    TriggerClientEvent('RSGCore:Client:SetDuty', src, false)
    Notify(src, locale('title_job_changed'), locale('job_changed_desc', jobInfo.label), 'success')

    MultiJobWebhook.Send('JobSwitched', {
        description = locale('wh_switched', GetCharName(Player), jobInfo.label),
        fields = {
            { name = locale('wh_field_player'), value = PlayerTag(Player), inline = true },
            { name = locale('wh_field_server_id'), value = tostring(src), inline = true },
            { name = locale('wh_field_new_job'), value = ('%s — %s'):format(jobInfo.label, gradeInfo.name), inline = true },
        }
    })

    PushJobs(Player, job)
end)

RegisterNetEvent('rsg-multijob:server:deleteJob', function(job)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or type(job) ~= 'string' or IsThrottled(src) then return end

    local cid = Player.PlayerData.citizenid
    if not RemoveStoredJob(cid, Player, job) then
        Notify(src, locale('title_error'), locale('not_hold_job'), 'error')
        return
    end

    Notify(src, locale('title_job_deleted'), locale('job_deleted_desc', JobLabel(job)), 'success')

    MultiJobWebhook.Send('JobDeleted', {
        description = locale('wh_deleted', GetCharName(Player), JobLabel(job)),
        fields = {
            { name = locale('wh_field_player'), value = PlayerTag(Player), inline = true },
            { name = locale('wh_field_server_id'), value = tostring(src), inline = true },
            { name = locale('wh_field_job'), value = JobLabel(job), inline = true },
        }
    })
end)

-----------------------------------------------------------------------
-- Job capture
-- Server-side only: the job is read from the player's own data, never
-- from the client, so nobody can add themselves a job they weren't given.
-----------------------------------------------------------------------

AddEventHandler('RSGCore:Server:OnJobUpdate', function(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job
    if not job or not IsValidJobName(job.name) then return end

    local cid = Player.PlayerData.citizenid
    local level = tonumber(job.grade and job.grade.level) or 0
    local stored = GetStoredGrade(cid, job.name)

    if stored == level then return end -- nothing changed (duty toggle, switch, etc.)

    if stored ~= nil then
        MySQL.update.await('UPDATE player_jobs SET grade = ? WHERE citizenid = ? AND job = ?', { level, cid, job.name })
        PushJobs(Player)
        return
    end

    if GetJobCount(cid) >= Config.MaxJobs then
        Notify(src, locale('title_max_jobs'), locale('job_max'), 'error')
        return
    end

    MySQL.insert.await('INSERT INTO player_jobs (citizenid, job, grade) VALUES (?, ?, ?)', { cid, job.name, level })

    MultiJobWebhook.Send('JobAdded', {
        description = locale('wh_granted', GetCharName(Player), JobLabel(job.name)),
        fields = {
            { name = locale('wh_field_player'), value = PlayerTag(Player), inline = true },
            { name = locale('wh_field_server_id'), value = tostring(src), inline = true },
            { name = locale('wh_field_job'), value = ('%s — %s'):format(JobLabel(job.name), job.grade and job.grade.name or tostring(level)), inline = true },
        }
    })

    PushJobs(Player)
end)

-----------------------------------------------------------------------
-- rsg-bossmenu sync: only a boss of the target's job who outranks (or
-- equals) the target can remove it from their multijob list.
-----------------------------------------------------------------------

RegisterNetEvent('rsg-bossmenu:server:FireEmployee', function(target)
    local src = source
    local Boss = RSGCore.Functions.GetPlayer(src)
    if not Boss or type(target) ~= 'string' then return end

    local bossJob = Boss.PlayerData.job.name
    if not IsBossOf(Boss, bossJob) then return end

    if target == Boss.PlayerData.citizenid then return end

    local Employee = RSGCore.Functions.GetPlayerByCitizenId(target)
    local targetLevel = GetStoredGrade(target, bossJob)

    if targetLevel == nil or targetLevel > Boss.PlayerData.job.grade.level then return end
    if not RemoveStoredJob(target, Employee, bossJob) then return end

    MultiJobWebhook.Send('EmployeeFired', {
        description = locale('wh_fired', GetCharName(Boss), Employee and GetCharName(Employee) or target, JobLabel(bossJob)),
        fields = {
            { name = locale('wh_field_fired_by'), value = PlayerTag(Boss), inline = true },
            { name = locale('wh_field_employee'), value = PlayerTag(Employee, target), inline = true },
            { name = locale('wh_field_job'), value = JobLabel(bossJob), inline = true },
        }
    })
end)

-----------------------------------------------------------------------
-- Cleanup
-----------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    actionThrottle[source] = nil
end)

-----------------------------------------------------------------------
-- Exports
-- identifier: server id (online) or citizenid (online or offline)
-----------------------------------------------------------------------

--- @return boolean canTake, string|nil reason 'invalid_job'|'player_not_found'|'already_held'|'max_jobs'
local function CanTakeJob(identifier, job, bypassMax)
    if not IsValidJobName(job) then return false, 'invalid_job' end

    local cid = ResolvePlayer(identifier)
    if not cid then return false, 'player_not_found' end

    if GetStoredGrade(cid, job) ~= nil then return false, 'already_held' end
    if not bypassMax and GetJobCount(cid) >= Config.MaxJobs then return false, 'max_jobs' end

    return true, nil
end

--- @return boolean held, number|nil grade
local function HasJob(identifier, job)
    if type(job) ~= 'string' then return false, nil end

    local cid = ResolvePlayer(identifier)
    if not cid then return false, nil end

    local grade = GetStoredGrade(cid, job)
    return grade ~= nil, grade
end

--- @return number count, number max
local function ExportGetJobCount(identifier)
    local cid = ResolvePlayer(identifier)
    return cid and GetJobCount(cid) or 0, Config.MaxJobs
end

--- @return boolean success, string|nil reason 'invalid_job'|'invalid_grade'|'player_not_found'|'max_jobs'
local function AddJob(identifier, job, grade, bypassMax)
    grade = math.floor(tonumber(grade) or 0)

    if not IsValidJobName(job) then return false, 'invalid_job' end

    local jobInfo = JobRegistry.Get(job)
    local gradeInfo = jobInfo.grades[tostring(grade)]
    if not gradeInfo then return false, 'invalid_grade' end

    local cid, Player = ResolvePlayer(identifier)
    if not cid then return false, 'player_not_found' end

    local stored = GetStoredGrade(cid, job)

    if stored == grade then return true, nil end

    if stored ~= nil then
        MySQL.update.await('UPDATE player_jobs SET grade = ? WHERE citizenid = ? AND job = ?', { grade, cid, job })
        if Player and Player.PlayerData.job.name == job then
            Player.Functions.SetJob(job, grade)
        end
    else
        if not bypassMax and GetJobCount(cid) >= Config.MaxJobs then return false, 'max_jobs' end
        MySQL.insert.await('INSERT INTO player_jobs (citizenid, job, grade) VALUES (?, ?, ?)', { cid, job, grade })
    end

    MultiJobWebhook.Send('JobAdded', {
        description = locale(stored ~= nil and 'wh_export_regraded' or 'wh_export_granted', Player and GetCharName(Player) or cid, jobInfo.label),
        fields = {
            { name = locale('wh_field_player'), value = PlayerTag(Player, cid), inline = true },
            { name = locale('wh_field_job'), value = ('%s — %s'):format(jobInfo.label, gradeInfo.name), inline = true },
            { name = locale('wh_field_invoked_by'), value = GetInvokingResource() or locale('wh_unknown'), inline = true },
        }
    })

    PushJobs(Player)
    return true, nil
end

--- @return boolean success, string|nil reason 'invalid_job'|'player_not_found'|'job_not_held'
local function RemoveJob(identifier, job)
    if type(job) ~= 'string' or job == '' then return false, 'invalid_job' end

    local cid, Player = ResolvePlayer(identifier)
    if not cid then return false, 'player_not_found' end

    if not RemoveStoredJob(cid, Player, job) then return false, 'job_not_held' end

    MultiJobWebhook.Send('JobRemovedByAdmin', {
        description = locale('wh_export_removed', JobLabel(job), Player and GetCharName(Player) or cid),
        fields = {
            { name = locale('wh_field_player'), value = PlayerTag(Player, cid), inline = true },
            { name = locale('wh_field_job'), value = JobLabel(job), inline = true },
            { name = locale('wh_field_invoked_by'), value = GetInvokingResource() or locale('wh_unknown'), inline = true },
        }
    })

    return true, nil
end

--- @return table jobs array of { job, salary, jobLabel, gradeLabel, grade }
local function GetJobs(identifier)
    local cid = ResolvePlayer(identifier)
    return cid and BuildJobList(cid) or {}
end

-- rsg-core already uses AddJob / RemoveJob for job *definitions*, so the
-- player job list functions use Player* names here.
local api = {
    AddPlayerJob = AddJob,
    RemovePlayerJob = RemoveJob,
    GetPlayerJobs = GetJobs,
    HasPlayerJob = HasJob,
    CanTakePlayerJob = CanTakeJob,
    GetPlayerJobCount = ExportGetJobCount,
    GetJobDefinition = function(name) return JobRegistry.Get(name) end,
    GetJobDefinitions = function() return JobRegistry.All() end,
}

for name, fn in pairs(api) do
    RSGCore.Functions[name] = fn
    exports(name, fn)
end

-- Compatibility: scripts still calling exports['rsg-multijob']:<fn> keep working
-- (rsg-core `provide`s rsg-multijob, so the old resource must not be running).
local legacy = {
    AddJob = AddJob,
    RemoveJob = RemoveJob,
    GetJobs = GetJobs,
    HasJob = HasJob,
    CanTakeJob = CanTakeJob,
    GetJobCount = ExportGetJobCount,
    GetJobDefinition = api.GetJobDefinition,
    GetJobDefinitions = api.GetJobDefinitions,
}

for name, fn in pairs(legacy) do
    AddEventHandler(('__cfx_export_rsg-multijob_%s'):format(name), function(setCB)
        setCB(fn)
    end)
end
