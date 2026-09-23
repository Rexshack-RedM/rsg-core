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
                args = { 'System', Lang:t('error.missing_args2') }
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
RSGCore.Commands.Add('tp', Lang:t('command.tp.help'), { { name = Lang:t('command.tp.params.x.name'), help = Lang:t('command.tp.params.x.help') }, { name = Lang:t('command.tp.params.y.name'), help = Lang:t('command.tp.params.y.help') }, { name = Lang:t('command.tp.params.z.name'), help = Lang:t('command.tp.params.z.help') } }, false, function(source, args)
    if args[1] and not args[2] and not args[3] then
        local targetId = tonumber(args[1])
        if targetId then
            local target = GetPlayerPed(targetId)
            if target ~= 0 then
                TriggerClientEvent('RSGCore:Command:TeleportToPlayer', source, GetEntityCoords(target))
            else
                notify(source, Lang:t('error.not_online'), 'error')
            end
        else
            local location = RSGShared.Locations[args[1]]
            if location then
                TriggerClientEvent('RSGCore:Command:TeleportToCoords', source, location.x, location.y, location.z, location.w)
            else
                notify(source, Lang:t('error.location_not_exist'), 'error')
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
            notify(source, Lang:t('error.wrong_format'), 'error')
        end
    else
        notify(source, Lang:t('error.missing_args'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add('tpm', Lang:t('command.tpm.help'), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:GoToMarker', source)
end, 'admin')

RSGCore.Commands.Add('togglepvp', Lang:t('command.togglepvp.help'), {}, false, function()
    RSGCore.Config.Server.PVP = not RSGCore.Config.Server.PVP
    TriggerClientEvent('RSGCore:Client:PvpHasToggled', -1, RSGCore.Config.Server.PVP)
end, 'admin')

-- admin noclip
RSGCore.Commands.Add('noclip', Lang:t("command.noclip.help"), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:ToggleNoClip', source)
end, 'admin')

-- Permissions

RSGCore.Commands.Add('addpermission', Lang:t('command.addpermission.help'), { { name = Lang:t('command.addpermission.params.id.name'), help = Lang:t('command.addpermission.params.id.help') }, { name = Lang:t('command.addpermission.params.permission.name'), help = Lang:t('command.addpermission.params.permission.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RSGCore.Functions.AddPermission(Player.PlayerData.source, permission)
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

RSGCore.Commands.Add('removepermission', Lang:t('command.removepermission.help'), { { name = Lang:t('command.removepermission.params.id.name'), help = Lang:t('command.removepermission.params.id.help') }, { name = Lang:t('command.removepermission.params.permission.name'), help = Lang:t('command.removepermission.params.permission.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RSGCore.Functions.RemovePermission(Player.PlayerData.source, permission)
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

-- Open & Close Server

RSGCore.Commands.Add('openserver', Lang:t('command.openserver.help'), {}, false, function(source)
    if not RSGCore.Config.Server.Closed then
        notify(source, Lang:t('error.server_already_open'), 'error')
        return
    end
    if RSGCore.Functions.HasPermission(source, 'admin') then
        RSGCore.Config.Server.Closed = false
        notify(source, Lang:t('success.server_opened'), 'success')
    else
        RSGCore.Functions.Kick(source, Lang:t('error.no_permission'))
    end
end, 'admin')

RSGCore.Commands.Add('closeserver', Lang:t('command.closeserver.help'), { { name = Lang:t('command.closeserver.params.reason.name'), help = Lang:t('command.closeserver.params.reason.help') } }, false, function(source, args)
    if RSGCore.Config.Server.Closed then
        notify(source, Lang:t('error.server_already_closed'), 'error')
        return
    end
    if RSGCore.Functions.HasPermission(source, 'admin') then
        local reason = #args > 0 and table.concat(args, ' ') or Lang:t('info.no_reason')
        RSGCore.Config.Server.Closed = true
        RSGCore.Config.Server.ClosedReason = reason
        for k in pairs(RSGCore.Players) do
            if not RSGCore.Functions.HasPermission(k, RSGCore.Config.Server.WhitelistPermission) then
                RSGCore.Functions.Kick(k, reason)
            end
        end
        notify(source, Lang:t('success.server_closed'), 'success')
    else
        RSGCore.Functions.Kick(source, Lang:t('error.no_permission'))
    end
end, 'admin')

-- Vehicle

RSGCore.Commands.Add('vehicle', Lang:t('command.car.help'), { { name = Lang:t('command.car.params.model.name'), help = Lang:t('command.car.params.model.help') } }, true, function(source, args)
    TriggerClientEvent('RSGCore:Command:SpawnVehicle', source, args[1])
end, 'admin')

RSGCore.Commands.Add('dv', Lang:t('command.dv.help'), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:DeleteVehicle', source)
end, 'admin')

RSGCore.Commands.Add('dvall', Lang:t('command.dvall.help'), {}, false, function()
    for _, vehicle in ipairs(GetAllVehicles()) do
        DeleteEntity(vehicle)
    end
end, 'admin')

-- Peds

RSGCore.Commands.Add('dvp', Lang:t('command.dvp.help'), {}, false, function()
    for _, ped in ipairs(GetAllPeds()) do
        -- never delete player peds (previously /dvp deleted every player's character ped)
        if not IsPedAPlayer(ped) then
            DeleteEntity(ped)
        end
    end
end, 'admin')

-- Objects

RSGCore.Commands.Add('dvo', Lang:t('command.dvo.help'), {}, false, function()
    for _, object in ipairs(GetAllObjects()) do
        DeleteEntity(object)
    end
end, 'admin')

-- Money

RSGCore.Commands.Add('givemoney', Lang:t('command.givemoney.help'), { { name = Lang:t('command.givemoney.params.id.name'), help = Lang:t('command.givemoney.params.id.help') }, { name = Lang:t('command.givemoney.params.moneytype.name'), help = Lang:t('command.givemoney.params.moneytype.help') }, { name = Lang:t('command.givemoney.params.amount.name'), help = Lang:t('command.givemoney.params.amount.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        if Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]), 'Admin give money') then
            notify(source, Lang:t('success.money_given'), 'success')
        else
            notify(source, Lang:t('error.invalid_money'), 'error')
        end
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add('setmoney', Lang:t('command.setmoney.help'), { { name = Lang:t('command.setmoney.params.id.name'), help = Lang:t('command.setmoney.params.id.help') }, { name = Lang:t('command.setmoney.params.moneytype.name'), help = Lang:t('command.setmoney.params.moneytype.help') }, { name = Lang:t('command.setmoney.params.amount.name'), help = Lang:t('command.setmoney.params.amount.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        if Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]), 'Admin set money') then
            notify(source, Lang:t('success.money_set'), 'success')
        else
            notify(source, Lang:t('error.invalid_money'), 'error')
        end
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Job

RSGCore.Commands.Add('job', Lang:t('command.job.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerJob = Player.PlayerData.job
    notify(source, Lang:t('info.job_info', { value = PlayerJob.label, value2 = PlayerJob.grade.name, value3 = PlayerJob.onduty and Lang:t('info.yes') or Lang:t('info.no') }), 'inform')
end, 'user')

RSGCore.Commands.Add('setjob', Lang:t('command.setjob.help'), { { name = Lang:t('command.setjob.params.id.name'), help = Lang:t('command.setjob.params.id.help') }, { name = Lang:t('command.setjob.params.job.name'), help = Lang:t('command.setjob.params.job.help') }, { name = Lang:t('command.setjob.params.grade.name'), help = Lang:t('command.setjob.params.grade.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        local job = tostring(args[2])
        local grade = tonumber(args[3])
        if not RSGCore.Shared.Jobs[job] then
            notify(source, Lang:t('error.job_not_exist'), 'error')
            return
        end
        if GetResourceState('rsg-multijob') == 'started' then
            exports['rsg-multijob']:AddJobToPlayer(Player.PlayerData.citizenid, job, grade)
        end
        Player.Functions.SetJob(job, grade)
        notify(source, Lang:t('success.job_set'), 'success')
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Gang

RSGCore.Commands.Add('gang', Lang:t('command.gang.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local PlayerGang = Player.PlayerData.gang
    notify(source, Lang:t('info.gang_info', { value = PlayerGang.label, value2 = PlayerGang.grade.name }), 'inform')
end, 'user')

RSGCore.Commands.Add('setgang', Lang:t('command.setgang.help'), { { name = Lang:t('command.setgang.params.id.name'), help = Lang:t('command.setgang.params.id.help') }, { name = Lang:t('command.setgang.params.gang.name'), help = Lang:t('command.setgang.params.gang.help') }, { name = Lang:t('command.setgang.params.grade.name'), help = Lang:t('command.setgang.params.grade.help') } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        if Player.Functions.SetGang(tostring(args[2]), tonumber(args[3])) then
            notify(source, Lang:t('success.gang_set'), 'success')
        else
            notify(source, Lang:t('error.gang_not_exist'), 'error')
        end
    else
        notify(source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Out of Character Chat
local OOC_RANGE = 20.0

RSGCore.Commands.Add('ooc', Lang:t('command.ooc.help'), {}, false, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local message = table.concat(args, ' '):gsub('[~<].-[>~]', '')
    if message == '' then return notify(source, Lang:t('error.missing_args2'), 'error') end

    local name = GetPlayerName(source) or ('ID ' .. source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local sentToAdmin = false

    for _, v in pairs(RSGCore.Functions.GetPlayers()) do
        local prefix
        if v == source or #(playerCoords - GetEntityCoords(GetPlayerPed(v))) < OOC_RANGE then
            prefix = 'OOC | '
        elseif RSGCore.Functions.IsOptin(v) then
            prefix = 'Proximity OOC | '
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

RSGCore.Commands.Add('me', Lang:t('command.me.help'), { { name = Lang:t('command.me.params.message.name'), help = Lang:t('command.me.params.message.help') } }, false, function(source, args)
    if #args < 1 then
        notify(source, Lang:t('error.missing_args2'), 'error')
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
RSGCore.Commands.Add('id', Lang:t('command.id.help'), {}, false, function(source)
    notify(source, Lang:t('info.your_id', { value = source }), 'inform')
end, 'user')

RSGCore.Commands.Add('cid', Lang:t('command.cid.help'), {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    notify(source, Lang:t('info.your_cid', { value = Player.PlayerData.citizenid }), 'inform')
end, 'user')
