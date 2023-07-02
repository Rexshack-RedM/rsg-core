RSGCore.Commands = {}
RSGCore.Commands.List = {}
RSGCore.Commands.IgnoreList = { -- Ignore old perm levels while keeping backwards compatibility
    ['god'] = true, -- We don't need to create an ace because god is allowed all commands
    ['user'] = true -- We don't need to create an ace because builtin.everyone
}

CreateThread(function() -- Add ace to node for perm checking
    local permissions = RSGConfig.Server.Permissions
    for i=1, #permissions do
        local permission = permissions[i]
        ExecuteCommand(('add_ace rsgcore.%s %s allow'):format(permission, permission))
    end
end)

-- Register & Refresh Commands

function RSGCore.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    local restricted = true -- Default to restricted for all commands
    if not permission then permission = 'user' end -- some commands don't pass permission level
    if permission == 'user' then restricted = false end -- allow all users to use command

    RegisterCommand(name, function(source, args, rawCommand) -- Register command within fivem
        if argsrequired and #args < #arguments then
            return TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", Lang:t("error.missing_args2")}
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
            local hasPerm = IsPlayerAceAllowed(tostring(src), 'command.'..command)
            if hasPerm then
                suggestions[#suggestions + 1] = {
                    name = '/' .. command,
                    help = info.help,
                    params = info.arguments
                }
            else
                TriggerClientEvent('chat:removeSuggestion', src, '/'..command)
            end
        end
        TriggerClientEvent('chat:addSuggestions', src, suggestions)
    end
end

-- Teleport
RSGCore.Commands.Add('tp', Lang:t("command.tp.help"), { { name = Lang:t("command.tp.params.x.name"), help = Lang:t("command.tp.params.x.help") }, { name = Lang:t("command.tp.params.y.name"), help = Lang:t("command.tp.params.y.help") }, { name = Lang:t("command.tp.params.z.name"), help = Lang:t("command.tp.params.z.help") } }, false, function(source, args)
    if args[1] and not args[2] and not args[3] then
        if tonumber(args[1]) then
        local target = GetPlayerPed(tonumber(args[1]))
        if target ~= 0 then
            local coords = GetEntityCoords(target)
            TriggerClientEvent('RSGCore:Command:TeleportToPlayer', source, coords)
        else
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
        end
    else
            local location = RSGShared.Locations[args[1]]
            if location then
                TriggerClientEvent('RSGCore:Command:TeleportToCoords', source, location.x, location.y, location.z, location.w)
            else
                TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.location_not_exist'), 'error')
            end
        end
    else
        if args[1] and args[2] and args[3] then
            local x = tonumber((args[1]:gsub(",",""))) + .0
            local y = tonumber((args[2]:gsub(",",""))) + .0
            local z = tonumber((args[3]:gsub(",",""))) + .0
            if x ~= 0 and y ~= 0 and z ~= 0 then
                TriggerClientEvent('RSGCore:Command:TeleportToCoords', source, x, y, z)
            else
                TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.wrong_format'), 'error')
            end
        else
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.missing_args'), 'error')
        end
    end
end, 'admin')

-- teleport to marker
RSGCore.Commands.Add('tpm', Lang:t("command.tpm.help"), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:GoToMarker', source)
end, 'admin')

-- noclip
RSGCore.Commands.Add('noclip', Lang:t("command.noclip.help"), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:ToggleNoClip', source)
end, 'admin')

-- Permissions

RSGCore.Commands.Add('addpermission', Lang:t("command.addpermission.help"), { { name = Lang:t("command.addpermission.params.id.name"), help = Lang:t("command.addpermission.params.id.help") }, { name = Lang:t("command.addpermission.params.permission.name"), help = Lang:t("command.addpermission.params.permission.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RSGCore.Functions.AddPermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

RSGCore.Commands.Add('removepermission', Lang:t("command.removepermission.help"), { { name = Lang:t("command.removepermission.params.id.name"), help = Lang:t("command.removepermission.params.id.help") }, { name = Lang:t("command.removepermission.params.permission.name"), help = Lang:t("command.removepermission.params.permission.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RSGCore.Functions.RemovePermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

-- Open & Close Server

RSGCore.Commands.Add('openserver', Lang:t("command.openserver.help"), {}, false, function(source)
    if not RSGCore.Config.Server.Closed then
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.server_already_open'), 'error')
        return
    end
    if RSGCore.Functions.HasPermission(source, 'admin') then
        RSGCore.Config.Server.Closed = false
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('success.server_opened'), 'success')
    else
        RSGCore.Functions.Kick(source, Lang:t("error.no_permission"), nil, nil)
    end
end, 'admin')

RSGCore.Commands.Add('closeserver', Lang:t("command.closeserver.help"), {{ name = Lang:t("command.closeserver.params.reason.name"), help = Lang:t("command.closeserver.params.reason.help")}}, false, function(source, args)
    if RSGCore.Config.Server.Closed then
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.server_already_closed'), 'error')
        return
    end
    if RSGCore.Functions.HasPermission(source, 'admin') then
        local reason = args[1] or 'No reason specified'
        RSGCore.Config.Server.Closed = true
        RSGCore.Config.Server.ClosedReason = reason
        for k in pairs(RSGCore.Players) do
            if not RSGCore.Functions.HasPermission(k, RSGCore.Config.Server.WhitelistPermission) then
                RSGCore.Functions.Kick(k, reason, nil, nil)
            end
        end
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('success.server_closed'), 'success')
    else
        RSGCore.Functions.Kick(source, Lang:t("error.no_permission"), nil, nil)
    end
end, 'admin')

-- HORSES / WAGONS
RSGCore.Commands.Add('dv', Lang:t("command.dv.help"), {}, false, function(source)
    TriggerClientEvent('RSGCore:Command:DeleteVehicle', source)
end, 'admin')

RSGCore.Commands.Add('wagon', Lang:t("command.spawnwagon.help"), { { name = 'model', help = 'Model name of the wagon' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('RSGCore:Command:SpawnVehicle', src, args[1])
end, 'admin')

RSGCore.Commands.Add('horse', Lang:t("command.spawnhorse.help"), { { name = 'model', help = 'Model name of the horse' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('RSGCore:Command:SpawnHorse', src, args[1])
end, 'admin')

-- Money

RSGCore.Commands.Add('givemoney', Lang:t("command.givemoney.help"), { { name = Lang:t("command.givemoney.params.id.name"), help = Lang:t("command.givemoney.params.id.help") }, { name = Lang:t("command.givemoney.params.moneytype.name"), help = Lang:t("command.givemoney.params.moneytype.help") }, { name = Lang:t("command.givemoney.params.amount.name"), help = Lang:t("command.givemoney.params.amount.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add('setmoney', Lang:t("command.setmoney.help"), { { name = Lang:t("command.setmoney.params.id.name"), help = Lang:t("command.setmoney.params.id.help") }, { name = Lang:t("command.setmoney.params.moneytype.name"), help = Lang:t("command.setmoney.params.moneytype.help") }, { name = Lang:t("command.setmoney.params.amount.name"), help = Lang:t("command.setmoney.params.amount.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Job

RSGCore.Commands.Add('job', Lang:t("command.job.help"), {}, false, function(source)
    local PlayerJob = RSGCore.Functions.GetPlayer(source).PlayerData.job
    TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.job_info', {value = PlayerJob.label, value2 = PlayerJob.grade.name, value3 = PlayerJob.onduty}))
end, 'user')

RSGCore.Commands.Add('setjob', Lang:t("command.setjob.help"), { { name = Lang:t("command.setjob.params.id.name"), help = Lang:t("command.setjob.params.id.help") }, { name = Lang:t("command.setjob.params.job.name"), help = Lang:t("command.setjob.params.job.help") }, { name = Lang:t("command.setjob.params.grade.name"), help = Lang:t("command.setjob.params.grade.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetJob(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Gang

RSGCore.Commands.Add('gang', Lang:t("command.gang.help"), {}, false, function(source)
    local PlayerGang = RSGCore.Functions.GetPlayer(source).PlayerData.gang
    TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.gang_info', {value = PlayerGang.label, value2 = PlayerGang.grade.name}))
end, 'user')

RSGCore.Commands.Add('setgang', Lang:t("command.setgang.help"), { { name = Lang:t("command.setgang.params.id.name"), help = Lang:t("command.setgang.params.id.help") }, { name = Lang:t("command.setgang.params.gang.name"), help = Lang:t("command.setgang.params.gang.help") }, { name = Lang:t("command.setgang.params.grade.name"), help = Lang:t("command.setgang.params.grade.help") } }, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetGang(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')


RSGCore.Commands.Add('gang', Lang:t("command.gang.help"), {}, false, function(source)
    local PlayerGang = RSGCore.Functions.GetPlayer(source).PlayerData.gang
    TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.gang_info', {value = PlayerGang.label, value2 = PlayerGang.grade.name}))
end, 'admin')

RSGCore.Commands.Add("givexp", "Give EXP Points to Player (Admin Only)", {{name="id", help="Player ID"}, {name="skill", help="Type of skill (mining, etc)"}, {name="amount", help="Amount of xp"}}, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))

    if not Player then
        RSGCore.Functions.Notify(source, Lang:t('error.not_online'), 'error')

        return
    end

    local fullname = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
    local skill = tostring(args[2])
    local exp = tonumber(args[3])

    Player.Functions.AddXp(skill, exp)

    RSGCore.Functions.Notify(source, exp..' EXP points added to \''..skill..'\' for '..fullname, 'success', 5000)
end, 'admin')

RSGCore.Commands.Add("removexp", "Remove Player EXP (Admin Only)", {{name="id", help="Player ID"}, {name="skill", help="Type of skill (mining, etc)"}, {name="amount", help="Amount of xp"}}, true, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(tonumber(args[1]))

    if not Player then
        RSGCore.Functions.Notify(source, Lang:t('error.not_online'), 'error')

        return
    end

    local fullname = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname
    local skill = tostring(args[2])
    local exp = tonumber(args[3])
    local currentEXP = Player.PlayerData.metadata['xp'][skill]
    local removed = currentEXP - exp

    if removed < 0 then return end

    Player.Functions.RemoveXp(skill, exp)

    RSGCore.Functions.Notify(source, exp..' EXP points removed from \''..skill..'\' for '..fullname, 'success', 5000)
end, 'admin')

RSGCore.Commands.Add("xp", "Check How Much Xp You Have", {{name="skill", help="Type of skill (mining, etc)"}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not Player then
        RSGCore.Functions.Notify(source, Lang:t('error.not_online'), 'error')

        return
    end

    local skill = tostring(args[1])
    local exp = Player.PlayerData.metadata["xp"][skill]

    if exp then
        RSGCore.Functions.Notify(source, 'Your EXP points for \''..skill..'\' is '..exp, 'primary', 5000)
    else
        RSGCore.Functions.Notify(source, 'Not available!', 'error', 3000)
    end
end, 'user')

RSGCore.Commands.Add("givelevel", "Give A Player Level (Admin Only)", {{name="id", help="Player ID"},{name="skill", help="Type of skill (mining, etc)"}, {name="amount", help="Amount of xp"}}, true, function(source, args)
    local Player = GetPlayer(tonumber(args[1]))
    if Player then
        if Player.PlayerData.metadata["levels"][tostring(args[2])] then
            Player.Functions.AddXp(tostring(args[2]), tonumber(args[3]))
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.xp_added'), 'primary')
        else
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.no_skill'), 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add("removelevel", "Remove A Player Level (Admin Only)", {{name="id", help="Player ID"},{name="skill", help="Type of skill (mining, etc)"}, {name="amount", help="Amount of xp"}}, true, function(source, args)
    local Player = GetPlayer(tonumber(args[1]))
    if Player then
        if Player.PlayerData.metadata["levels"][tostring(args[2])] then
            Player.Functions.RemoveXp(tostring(args[2]), tonumber(args[3]))
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.xp_removed'), 'primary')
        else
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.no_skill'), 'error')
        end
    else
        TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

RSGCore.Commands.Add("level", "Check Which Level You Are", {{name="skill", help="Type of skill (mining, etc)"}}, true, function(source, args)
    local Player = GetPlayer(source)
    local Level = Player.PlayerData.metadata["levels"][tostring(args[1])]
    if Player then
        if Level then
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('info.level_info', {value = Level, value2 = tostring(args[1])}), 'primary')
        else
            TriggerClientEvent('RSGCore:Notify', source, Lang:t('error.no_skill'), 'error')
        end
    end
end, 'user')

-- Me command
RSGCore.Commands.Add('me', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
   TriggerClientEvent('RSGCore:triggerDisplay', -1, text, source , "me")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 255, 255, 255 })
end, 'user')

RSGCore.Commands.Add('do', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
   TriggerClientEvent('RSGCore:triggerDisplay', -1, text, source , "do")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 145, 209, 144 })
end, 'user')

RSGCore.Commands.Add('try', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    local random = math.random(1,2)
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
    if random == 1 then
        text = 'He succeeded in trying'..text
    else
        text = 'He has failed trying '..text
    end
   TriggerClientEvent('RSGCore:triggerDisplay', -1, text, source , "try")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 32, 151, 247 })
end, 'user')

-- IDs
RSGCore.Commands.Add("id", "Check Your ID #", {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    TriggerClientEvent('RSGCore:Notify', source, "ID: "..source, 'primary')
end, 'user')

RSGCore.Commands.Add("cid", "Check Your Citizen ID #", {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    TriggerClientEvent('RSGCore:Notify', source, "Citizen ID: "..Playercid, 'primary')
end, 'user')
