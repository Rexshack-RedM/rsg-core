-- rsg-core progress bar / circle (replaces lib.progressBar, lib.progressCircle, lib.progressActive, lib.cancelProgress)
-- Same option table as ox_lib so migrating is a rename:
--   local done = RSGCore.Functions.ProgressBar({ duration, label, position?, useWhileDead?, allowRagdoll?, allowSwimming?,
--       allowCuffed?, allowFalling?, allowMounted?, canCancel?, anim = { dict, clip, flag?, blendIn?, blendOut?, playbackRate?,
--       lockX?, lockY?, lockZ?, scenario?, playEnter? }, prop = { model, bone?, pos?, rot? } | { {...}, {...} },
--       disable = { move?, sprint?, mount?, combat?, mouse? } })
--   returns true when finished, false when cancelled or interrupted. Must be called from a thread (it yields).

local cfg = RSGConfig.Progress or {}
local CANCEL_KEY = cfg.CancelKey or 0x8CC9CD42 -- INPUT_GAME_MENU_TAB_RIGHT_SECONDARY (X) — rdr3_discoveries/Controls

-- control hashes from rdr3_discoveries/Controls/README.md
local DISABLE = {
    move   = { 0x4D8FB4C1, 0xFDA83190, 0xD9D0E1C0, 0x06052D11, 0xDB096B85, 0xDE794E3E }, -- MOVE_LR, MOVE_UD, JUMP, DIVE, DUCK, COVER
    sprint = { 0x8FFC75D6 },                                                          -- SPRINT
    mount  = { 0x126796EB, 0x3BBDEFEF, 0x5AA007D7, 0x5B9FD4E2, 0x6E1F639B, 0xFEFAB9B4 }, -- HORSE_MOVE_LR/UD, HORSE_SPRINT, VEH_ACCELERATE/BRAKE, VEH_EXIT
    combat = { 0x07CE1E61, 0xF84FA74F, 0xB2F377E8, 0x60C81CDE, 0xE30CD707, 0xFD0F0C2C, 0xCC1075A7, 0xAC4BD4F1 }, -- ATTACK, AIM, MELEE, HORSE_ATTACK, RELOAD, NEXT/PREV_WEAPON, WHEEL
    mouse  = { 0xA987235F, 0xD2047988 },                                              -- LOOK_LR, LOOK_UD
}

local active = nil -- { cancelled = bool }

local function spawnProps(ped, prop)
    local list, ents = {}, {}
    if not prop then return ents end
    if prop.model then list = { prop } else list = prop end
    local coords = GetEntityCoords(ped)
    for _, p in ipairs(list) do
        local ok, hash = pcall(RSGCore.Functions.RequestModel, p.model)
        if ok then
            local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
            SetModelAsNoLongerNeeded(hash)
            local bone = type(p.bone) == 'string' and GetEntityBoneIndexByName(ped, p.bone) or (p.bone or GetEntityBoneIndexByName(ped, 'SKEL_R_Hand'))
            local pos, rot = p.pos or vec3(0, 0, 0), p.rot or vec3(0, 0, 0)
            AttachEntityToEntity(obj, ped, bone, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, p.rotOrder or 1, true)
            ents[#ents + 1] = obj
        end
    end
    return ents
end

local function startAnim(ped, anim)
    if not anim then return end
    if anim.scenario then
        TaskStartScenarioInPlaceHash(ped, joaat(anim.scenario), -1, anim.playEnter ~= false, 0, -1.0, false)
    elseif anim.dict and anim.clip then
        local ok = pcall(RSGCore.Functions.RequestAnimDict, anim.dict)
        if not ok then return end
        TaskPlayAnim(ped, anim.dict, anim.clip, anim.blendIn or 3.0, anim.blendOut or 1.0, anim.duration or -1,
            anim.flag or 49, anim.playbackRate or 0, anim.lockX or false, anim.lockY or false, anim.lockZ or false)
        RemoveAnimDict(anim.dict)
    end
end

local function stopAnim(ped, anim)
    if not anim then return end
    if anim.scenario then
        ClearPedTasks(ped)
    elseif anim.dict and anim.clip then
        StopAnimTask(ped, anim.dict, anim.clip, 1.0)
    end
end

-- some ped natives return 1/0 in RedM
local function yes(v) return v == true or v == 1 end

local function interrupted(ped, data)
    if not data.useWhileDead and yes(IsEntityDead(ped)) then return true end
    if not data.allowRagdoll and yes(IsPedRagdoll(ped)) then return true end
    if not data.allowSwimming and yes(IsPedSwimming(ped)) then return true end
    if not data.allowFalling and yes(IsPedFalling(ped)) then return true end
    if not data.allowCuffed and (yes(IsPedCuffed(ped)) or yes(IsPedHogtied(ped))) then return true end
    return false
end

local function run(kind, data)
    if active then return false end
    if type(data) ~= 'table' or type(data.duration) ~= 'number' or data.duration <= 0 then return false end

    local ped = PlayerPedId()
    if interrupted(ped, data) then return false end
    if data.allowMounted == false and yes(IsPedOnMount(ped)) then return false end

    local invoker = GetInvokingResource()
    active = { cancelled = false }
    local disable = data.disable or {}
    local controls = {}
    for key, on in pairs(disable) do
        if on and DISABLE[key] then
            for _, c in ipairs(DISABLE[key]) do controls[#controls + 1] = c end
        end
    end

    local props = spawnProps(ped, data.prop)
    startAnim(ped, data.anim)

    SendNUIMessage({ action = 'progress', data = {
        show = true,
        kind = kind,
        label = data.label,
        duration = data.duration,
        position = data.position,
        cancelHint = data.canCancel and locale('info.progress_cancel', cfg.CancelLabel or 'X') or nil,
    } })

    local finishAt = GetGameTimer() + data.duration
    local success = true
    while GetGameTimer() < finishAt do
        for i = 1, #controls do DisableControlAction(0, controls[i], true) end
        if active.cancelled
            or (data.canCancel and IsControlJustPressed(0, CANCEL_KEY))
            or interrupted(ped, data)
            or (invoker and GetResourceState(invoker) ~= 'started') then
            success = false
            break
        end
        Wait(0)
    end

    stopAnim(ped, data.anim)
    for _, obj in ipairs(props) do
        if DoesEntityExist(obj) then DetachEntity(obj, true, true) DeleteEntity(obj) end
    end
    SendNUIMessage({ action = 'progress', data = { show = false, cancelled = not success } })
    active = nil
    return success
end

function RSGCore.Functions.ProgressBar(data) return run('bar', data) end
function RSGCore.Functions.ProgressCircle(data) return run('circle', data) end
function RSGCore.Functions.IsProgressActive() return active ~= nil end
function RSGCore.Functions.CancelProgress()
    if active then active.cancelled = true end
end

exports('ProgressBar', RSGCore.Functions.ProgressBar)
exports('ProgressCircle', RSGCore.Functions.ProgressCircle)
exports('IsProgressActive', RSGCore.Functions.IsProgressActive)
exports('CancelProgress', RSGCore.Functions.CancelProgress)

RegisterNetEvent('rsg-core:client:CancelProgress', RSGCore.Functions.CancelProgress)
