-- Merged from rsg-multijob (github.com/Rexshack-RedM/rsg-multijob)
local Config = RSGConfig.MultiJob

local isUIOpen = false
local uiLocales -- built once, locales don't change at runtime

local function withIcons(jobs)
    jobs = jobs or {}
    for _, job in ipairs(jobs) do
        job.icon = (type(job.icon) == 'string' and job.icon ~= '' and job.icon) or Config.JobIcons[job.job] or 'fa-solid fa-briefcase'
    end
    return jobs
end

-- Every ui_* key in locales/<lang>.json is sent to the NUI, so new UI text
-- only needs adding to the locale files.
local UI_KEYS = {
    'ui_page_title', 'ui_my_jobs', 'ui_subtitle', 'ui_close', 'ui_back', 'ui_drag_hint',
    'ui_duty_label', 'ui_on_duty', 'ui_off_duty', 'ui_capacity_label', 'ui_max_jobs_footer',
    'ui_job_actions', 'ui_select_action', 'ui_switch_job', 'ui_switch_desc', 'ui_delete_job',
    'ui_delete_desc', 'ui_confirm_title', 'ui_confirm_text', 'ui_confirm', 'ui_cancel',
    'ui_no_jobs_title', 'ui_no_jobs_sub', 'ui_current_pill', 'ui_grade', 'ui_salary',
    'ui_switch_confirm_title', 'ui_switch_confirm_text', 'ui_delete_confirm_title', 'ui_delete_confirm_text',
}

local function getUILocales()
    if uiLocales then return uiLocales end

    uiLocales = {}
    for _, key in ipairs(UI_KEYS) do
        uiLocales[key] = locale(key)
    end
    return uiLocales
end

local function closeUI()
    isUIOpen = false
    SetNuiFocus(false, false)
end

local function openUI()
    if isUIOpen then return end

    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return end

    isUIOpen = true
    local jobs = withIcons(RSGCore.Functions.AwaitCallback('rsg-multijob:server:myJobs'))
    if not isUIOpen then return end -- closed while waiting

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'multijob:open',
        jobs = jobs,
        currentJob = PlayerData.job.name,
        onDuty = PlayerData.job.onduty,
        maxJobs = Config.MaxJobs,
        locales = getUILocales(),
    })
end

RegisterNUICallback('multijob:closeUI', function(_, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('multijob:toggleDuty', function(_, cb)
    TriggerServerEvent('RSGCore:ToggleDuty')
    cb('ok')
end)

RegisterNUICallback('multijob:switchJob', function(data, cb)
    if type(data) == 'table' and type(data.job) == 'string' then
        TriggerServerEvent('rsg-multijob:server:changeJob', data.job)
    end
    cb('ok')
end)

RegisterNUICallback('multijob:deleteJob', function(data, cb)
    if type(data) == 'table' and type(data.job) == 'string' then
        TriggerServerEvent('rsg-multijob:server:deleteJob', data.job)
    end
    cb('ok')
end)

RegisterNetEvent('rsg-multijob:client:openmenu', openUI)

-- Server pushes the up-to-date list after any change (switch/add/delete/fire)
RegisterNetEvent('rsg-multijob:client:refreshJobs', function(jobs, currentJobName)
    if not isUIOpen then return end

    SendNUIMessage({
        action = 'multijob:refreshJobs',
        jobs = withIcons(jobs),
        currentJob = currentJobName,
    })
end)

-- Keep the duty indicator live while the menu is open.
-- (Job capture is handled server-side via RSGCore:Server:OnJobUpdate.)
RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(job)
    if not isUIOpen or not job then return end

    SendNUIMessage({ action = 'multijob:updateDuty', onDuty = job.onduty, currentJob = job.name })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isUIOpen then
        closeUI()
    end
end)

-----------------------------------------------------------------------
-- Job admin panel (/jobadmin)
-- All checks happen on the server; these callbacks only relay.
-----------------------------------------------------------------------

local isAdminOpen = false
local adminLocales

-- Every adm_ui_* key in locales/en.json is sent to the admin NUI
local function getAdminLocales()
    if adminLocales then return adminLocales end
    adminLocales = {}

    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    local ok, keys = pcall(json.decode, raw or '{}')
    for key in pairs(ok and keys or {}) do
        if key:sub(1, 7) == 'adm_ui_' then adminLocales[key] = locale(key) end
    end
    return adminLocales
end

local function closeAdmin()
    isAdminOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'admin:close' })
end

RegisterNetEvent('rsg-multijob:client:openAdmin', function()
    if isAdminOpen or isUIOpen then return end
    isAdminOpen = true

    local jobs = RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:getJobs')
    if not jobs or not isAdminOpen then
        isAdminOpen = false
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'admin:open', jobs = jobs, locales = getAdminLocales() })
end)

RegisterNUICallback('admin:close', function(_, cb)
    closeAdmin()
    cb('ok')
end)

RegisterNUICallback('admin:save', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' or type(data.job) ~= 'table' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:saveJob', nil, data.job, data.isNew == true) or { ok = false })
end)

RegisterNUICallback('admin:delete', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' or type(data.name) ~= 'string' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:deleteJob', nil, data.name) or { ok = false })
end)

RegisterNUICallback('admin:import', function(_, cb)
    if not isAdminOpen then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:importCore') or { ok = false })
end)

-- Employees tab: relays only, the server re-checks permission and every value
RegisterNUICallback('admin:holders', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' or type(data.job) ~= 'string' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:getHolders', nil, data.job) or { ok = false })
end)

RegisterNUICallback('admin:assign', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:assignJob', nil, data) or { ok = false })
end)

RegisterNUICallback('admin:setGrade', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:setGrade', nil, data) or { ok = false })
end)

RegisterNUICallback('admin:removeHolder', function(data, cb)
    if not isAdminOpen or type(data) ~= 'table' then return cb({ ok = false }) end
    cb(RSGCore.Functions.AwaitCallback('rsg-multijob:server:admin:removeHolder', nil, data) or { ok = false })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isAdminOpen then
        closeAdmin()
    end
end)
