RSGCore.Commands = {}
RSGCore.Commands.List = {}

local function notify(src, title, notifyType)
    if not src or src == 0 then return print(title) end -- console
    TriggerClientEvent('ox_lib:notify', src, { title = title, type = notifyType or 'inform', duration = 5000 })
end

RSGCore.Commands.IgnoreList = { -- Ignore old perm levels while keeping backwards compatibility
    ['god'] = true,            -- We don't need to create an ace because god is allowed all commands
    ['user'] = true            -- We don't need to create an ace because builtin.everyone
}

CreateThread(function() -- Add ace to node for perm checking
    local permissions = RSGCore.Config.Server.Permissions
    for i = 1, #permissions do
        local permission = permissions[i]
        ExecuteCommand(('add_ace rsgcore.%s %s allow'):format(permission, permission))
    end
end)

-- Register & Refresh Commands

function RSGCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    local restricted = true                                  -- Default to restricted for all commands
    if not permission then permission = 'user' end           -- some commands don't pass permission level
    if permission == 'user' then restricted = false end      -- allow all users to use command

    RegisterCommand(name, function(source, args, rawCommand) -- Register command within fivem
        if argsrequired and #args < #arguments then
            return TriggerClientEvent('chat:addMessage', source, {
                color = { 255, 0, 0 },
                multiline = true,
                args = { locale('info.system'), locale('error.missing_args2') }
            })
        end
        callback(source, args, rawCommand)
    end, restricted)

    local extraPerms = ... and table.pack(...) or nil
    if extraPerms then
        extraPerms[extraPerms.n + 1] = permission -- The `n` field is the number of arguments in the packed table
        extraPerms.n += 1
        permission = extraPerms
        for i = 1, permission.n do
            if not RSGCore.Commands.IgnoreList[permission[i]] then -- only create aces for extra perm levels
                ExecuteCommand(('add_ace rsgcore.%s command.%s allow'):format(permission[i], name))
            end
        end
        permission.n = nil
    else
        permission = tostring(permission:lower())
        if not RSGCore.Commands.IgnoreList[permission] then -- only create aces for extra perm levels
            ExecuteCommand(('add_ace rsgcore.%s command.%s allow'):format(permission, name))
        end
    end

    RSGCore.Commands.List[name:lower()] = {
        name = name:lower(),
        permission = permission,
        help = help,
        arguments = arguments,
        argsrequired = argsrequired,
        callback = callback
    }
end

function RSGCore.Commands.Refresh(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local suggestions = {}
    if Player then
        for command, info in pairs(RSGCore.Commands.List) do
            local hasPerm = IsPlayerAceAllowed(tostring(src), 'command.' .. command)
            if hasPerm then
                suggestions[#suggestions + 1] = {
                    name = '/' .. command,
                    help = info.help,
                    params = info.arguments
                }
            else
                TriggerClientEvent('chat:removeSuggestion', src, '/' .. command)
            end
        end
        TriggerClientEvent('chat:addSuggestions', src, suggestions)
    end
end

-- Teleport
RSGCore.Commands.Add('tp', locale('command.tp.help'), { { name = locale('command.tp.params.x.name'), help = locale('command.tp.params.x.help') }, { name = locale('command.tp.params.y.name'), help = locale('command.tp.params.y.help') }, { name = locale('command.tp.params.z.name'), help = locale('command.tp.params.z.help') } }, false, function(source, args)
    if args[1] and not args[2] and not args[3] then
        local targetId = tonumber(args[1])
        if targetId then
            local target = GetPlayerPed(targetId)
            if target ~= 0 then
                TriggerClientEvent('RSGCore:Command:TeleportToPlayer', source, GetEntityCoords(target))
            else
                notify(source, locale('error.not_online'), 'error')
            end
        else
            local location = RSGShared.Locations[args[1]]
            if location then
                TriggerClientEvent('RSGCore:Command:TeleportToCoords', source, location.x, location.y, location.z, location.w)
            else
                notify(source, locale('error.location_not_exist'), 'error')
            end
        end
    elseif args[1] and args[2] and args[3] then
        -- tonumber can fail on bad input; previously this errored with "attempt to perform arithmetic on nil"
        local x = tonumber((args[1]:gsub(',', '')))
        local y = tonumber((args[2]:gsub(',', '')))
        local z = tonumber((args[3]:gsub(',', '')))
        if x and y and z then
            TriggerClientEvent('RSGCore:Command:TeleportToCoords', source, x + 0.0, y + 0.0, z + 0.0)
        else
            notify(source, locale('error.wrong_format'), 'error')
        end
    else
        notify(source, locale('error.missing_args'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add('tpm', locale('command.tpm.help'), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:GoToMarker', source)
end, 'admin')

RSGCore.Commands.Add('togglepvp', locale('command.togglepvp.help'), {}, false, function()
    RSGCore.Config.Server.PVP = not RSGCore.Config.Server.PVP
    TriggerClientEvent('RSGCore:Client:PvpHasToggled', -1, RSGCore.Config.Server.PVP)
end, 'admin')

-- admin noclip
RSGCore.Commands.Add('noclip', locale('command.noclip.help'), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:ToggleNoClip', source)
end, 'admin')

-- Permissions

RSGCore.Commands.Add('addpermission', locale('command.addpermission.help'), { { name = locale('command.addpermission.params.id.name'), help = locale('command.addpermission.params.id.help') }, { name = locale('command.addpermission.params.permission.name'), help = locale('command.addpermission.params.permission.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then return notify(source, locale('error.not_online'), 'error') end
    if not RSGCore.Functions.AddPermission(Player.PlayerData.source, tostring(args[2]):lower()) then
        return notify(source, locale('error.invalid_permission'), 'error')
    end
    notify(source, locale('success.permission_updated'), 'success')
end, 'god')

RSGCore.Commands.Add('removepermission', locale('command.removepermission.help'), { { name = locale('command.removepermission.params.id.name'), help = locale('command.removepermission.params.id.help') }, { name = locale('command.removepermission.params.permission.name'), help = locale('command.removepermission.params.permission.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then return notify(source, locale('error.not_online'), 'error') end
    if not RSGCore.Functions.RemovePermission(Player.PlayerData.source, tostring(args[2]):lower()) then
        return notify(source, locale('error.invalid_permission'), 'error')
    end
    notify(source, locale('success.permission_updated'), 'success')
end, 'god')

-- Open & Close Server (commands are ace-restricted to admin, so no extra permission check is needed)

RSGCore.Commands.Add('openserver', locale('command.openserver.help'), {}, false, function(source)
    if not RSGCore.Config.Server.Closed then
        return notify(source, locale('error.server_already_open'), 'error')
    end
    RSGCore.Functions.SetServerClosed(false)
    notify(source, locale('success.server_opened'), 'success')
end, 'admin')

RSGCore.Commands.Add('closeserver', locale('command.closeserver.help'), { { name = locale('command.closeserver.params.reason.name'), help = locale('command.closeserver.params.reason.help') } }, false, function(source, args)
    if RSGCore.Config.Server.Closed then
        return notify(source, locale('error.server_already_closed'), 'error')
    end
    RSGCore.Functions.SetServerClosed(true, table.concat(args, ' '))
    notify(source, locale('success.server_closed'), 'success')
end, 'admin')

-- Vehicle

RSGCore.Commands.Add('vehicle', locale('command.car.help'), { { name = locale('command.car.params.model.name'), help = locale('command.car.params.model.help') } }, true, function(source, args)
    TriggerClientEvent('RSGCore:Command:SpawnVehicle', source, args[1])
end, 'admin')

RSGCore.Commands.Add('dv', locale('command.dv.help'), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:DeleteVehicle', source)
end, 'admin')

RSGCore.Commands.Add('dvall', locale('command.dvall.help'), {}, false, function()
    for _, vehicle in ipairs(GetAllVehicles()) do
        DeleteEntity(vehicle)
    end
end, 'admin')

-- Peds

RSGCore.Commands.Add('dvp', locale('command.dvp.help'), {}, false, function()
    for _, ped in ipairs(GetAllPeds()) do
        -- never delete player peds (previously /dvp deleted every player's character ped)
        if not IsPedAPlayer(ped) then
            DeleteEntity(ped)
        end
    end
end, 'admin')

-- Objects

RSGCore.Commands.Add('dvo', locale('command.dvo.help'), {}, false, function()
    for _, object in ipairs(GetAllObjects()) do
        DeleteEntity(object)
    end
end, 'admin')

-- Money

RSGCore.Commands.Add('givemoney', locale('command.givemoney.help'), { { name = locale('command.givemoney.params.id.name'), help = locale('command.givemoney.params.id.help') }, { name = locale('command.givemoney.params.moneytype.name'), help = locale('command.givemoney.params.moneytype.help') }, { name = locale('command.givemoney.params.amount.name'), help = locale('command.givemoney.params.amount.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        if Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]), 'Admin give money') then
            notify(source, locale('success.money_given'), 'success')
        else
            notify(source, locale('error.invalid_money'), 'error')
        end
    else
        notify(source, locale('error.not_online'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add('setmoney', locale('command.setmoney.help'), { { name = locale('command.setmoney.params.id.name'), help = locale('command.setmoney.params.id.help') }, { name = locale('command.setmoney.params.moneytype.name'), help = locale('command.setmoney.params.moneytype.help') }, { name = locale('command.setmoney.params.amount.name'), help = locale('command.setmoney.params.amount.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        if Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]), 'Admin set money') then
            notify(source, locale('success.money_set'), 'success')
        else
            notify(source, locale('error.invalid_money'), 'error')
        end
    else
        notify(source, locale('error.not_online'), 'error')
    end
end, 'admin')

-- Job

RSGCore.Commands.Add('job', locale('command.job.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerJob = Player.PlayerData.job
    notify(source, locale('info.job_info', PlayerJob.label, PlayerJob.grade.name, PlayerJob.onduty and locale('info.yes') or locale('info.no')), 'inform')
end, 'user')

RSGCore.Commands.Add('setjob', locale('command.setjob.help'), { { name = locale('command.setjob.params.id.name'), help = locale('command.setjob.params.id.help') }, { name = locale('command.setjob.params.job.name'), help = locale('command.setjob.params.job.help') }, { name = locale('command.setjob.params.grade.name'), help = locale('command.setjob.params.grade.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then return notify(source, locale('error.not_online'), 'error') end
    local job = tostring(args[2]):lower()
    local grade = tonumber(args[3]) or 0
    local jobInfo = RSGCore.Shared.Jobs[job]
    if not jobInfo then return notify(source, locale('error.job_not_exist'), 'error') end
    if not jobInfo.grades[tostring(grade)] then return notify(source, locale('error.grade_not_exist'), 'error') end
    if GetResourceState('rsg-multijob') == 'started' then
        exports['rsg-multijob']:AddJobToPlayer(Player.PlayerData.citizenid, job, grade)
    end
    Player.Functions.SetJob(job, grade)
    notify(source, locale('success.job_set'), 'success')
end, 'admin')

-- Gang

RSGCore.Commands.Add('gang', locale('command.gang.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerGang = Player.PlayerData.gang
    notify(source, locale('info.gang_info', PlayerGang.label, PlayerGang.grade.name), 'inform')
end, 'user')

RSGCore.Commands.Add('setgang', locale('command.setgang.help'), { { name = locale('command.setgang.params.id.name'), help = locale('command.setgang.params.id.help') }, { name = locale('command.setgang.params.gang.name'), help = locale('command.setgang.params.gang.help') }, { name = locale('command.setgang.params.grade.name'), help = locale('command.setgang.params.grade.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if not Player then return notify(source, locale('error.not_online'), 'error') end
    local gang = tostring(args[2]):lower()
    local grade = tonumber(args[3]) or 0
    local gangInfo = RSGCore.Shared.Gangs[gang]
    if not gangInfo then return notify(source, locale('error.gang_not_exist'), 'error') end
    if not gangInfo.grades[tostring(grade)] then return notify(source, locale('error.grade_not_exist'), 'error') end
    Player.Functions.SetGang(gang, grade)
    notify(source, locale('success.gang_set'), 'success')
end, 'admin')

-- Out of Character Chat
local OOC_RANGE = 20.0

RSGCore.Commands.Add('ooc', locale('command.ooc.help'), {}, false, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local message = table.concat(args, ' '):gsub('[~<].-[>~]', '')
    if message == '' then return notify(source, locale('error.missing_args2'), 'error') end

    local name = GetPlayerName(source) or ('ID ' .. source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local sentToAdmin = false

    for _, v in pairs(RSGCore.Functions.GetPlayers()) do
        local prefix
        if v == source or #(playerCoords - GetEntityCoords(GetPlayerPed(v))) < OOC_RANGE then
            prefix = locale('info.ooc_prefix')
        elseif RSGCore.Functions.IsOptin(v) then
            prefix = locale('info.ooc_proximity_prefix')
            sentToAdmin = true
        end
        if prefix then
            TriggerClientEvent('chat:addMessage', v, {
                color = RSGCore.Config.Commands.OOCColor,
                multiline = true,
                args = { prefix .. name, message }
            })
        end
    end

    -- log once per message (previously logged once for every opted-in admin)
    if sentToAdmin then
        TriggerEvent('rsg-log:server:CreateLog', 'ooc', 'OOC', 'white', ('**%s** (CitizenID: %s | ID: %s) **Message:** %s'):format(name, Player.PlayerData.citizenid, source, message), false)
    end
end, 'user')

-- Me command

RSGCore.Commands.Add('me', locale('command.me.help'), { { name = locale('command.me.params.message.name'), help = locale('command.me.params.message.help') } }, false, function(source, args)
    if #args < 1 then
        notify(source, locale('error.missing_args2'), 'error')
        return
    end
    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local msg = table.concat(args, ' '):gsub('[~<].-[>~]', ''):sub(1, 128)
    for _, playerId in ipairs(RSGCore.Functions.GetPlayers()) do
        local target = GetPlayerPed(playerId)
        if target == ped or #(pCoords - GetEntityCoords(target)) < OOC_RANGE then
            TriggerClientEvent('RSGCore:Command:ShowMe3D', playerId, source, msg)
        end
    end
end, 'user')

-- ids
RSGCore.Commands.Add('id', locale('command.id.help'), {}, false, function(source)
    notify(source, locale('info.your_id', source), 'inform')
end, 'user')

RSGCore.Commands.Add('cid', locale('command.cid.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    notify(source, locale('info.your_cid', Player.PlayerData.citizenid), 'inform')
end, 'user')
