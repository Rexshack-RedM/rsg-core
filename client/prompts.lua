local Prompts = {}
local PromptGroups = {}

local function toVec3(c)
    return vector3(c.x or c[1], c.y or c[2], c.z or c[3])
end

local function safeDelete(prompt)
    if prompt then UiPromptDelete(prompt) end
end

local function createPrompt(name, coords, key, text, options)
    if (Prompts[name] == nil) then
        Prompts[name] = {}
        Prompts[name].name = name
        Prompts[name].coords = toVec3(coords)
        Prompts[name].key = key
        Prompts[name].text = text
        Prompts[name].options = options
        Prompts[name].prompt = nil
    else
        print('[rsg-core]  Prompt with name ' .. name .. ' already exists!')
    end
end

local function createPromptGroup(group, label, coords, prompts)
    if (PromptGroups[group] == nil) then
        PromptGroups[group] = {}
        PromptGroups[group].coords = toVec3(coords)
        PromptGroups[group].label = label
        PromptGroups[group].group = group
        PromptGroups[group].created = false
        PromptGroups[group].prompts = prompts
    else
        print('[rsg-core]  Prompt group ' .. tostring(group) .. ' already exists!')
    end
end

local function getPrompt()
    return Prompts
end

local function getPromptGroup()
    return PromptGroups
end


local function deletePrompt(name)
    if Prompts[name] then
        safeDelete(Prompts[name].prompt)
        Prompts[name] = nil
    end
end

local function deletePromptGroup(name)
    if PromptGroups[name] then
        for _, v in pairs(PromptGroups[name].prompts) do
            safeDelete(v.prompt)
        end
        PromptGroups[name] = nil
    end
end


local function executeOptions(options)
    if not options or not options.event then return end
    local args = options.args or {}
    if options.type == 'client' then
        TriggerEvent(options.event, table.unpack(args))
    else
        TriggerServerEvent(options.event, table.unpack(args))
    end
end

local function buildPrompt(key, text, group)
    local prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, key)
    UiPromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', text))
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
    UiPromptSetHoldMode(prompt, 1000)
    if group then UiPromptSetGroup(prompt, group, 0) end
    UiPromptRegisterEnd(prompt)
    return prompt
end

local function setupPrompt(prompt)
    prompt.prompt = buildPrompt(prompt.key, prompt.text)
end

local function setupPromptGroup(pGroup)
    for _, v in pairs(pGroup.prompts) do
        v.prompt = buildPrompt(v.key, v.text, pGroup.group)
    end
    pGroup.created = true
end

-- briefly hides a prompt after it fires so the hold has to be restarted
local function resetPrompt(prompt)
    UiPromptSetEnabled(prompt, false)
    UiPromptSetVisible(prompt, false)
    Wait(0)
    UiPromptSetEnabled(prompt, true)
    UiPromptSetVisible(prompt, true)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, v in pairs(Prompts) do
        safeDelete(v.prompt)
    end
    for _, pGroup in pairs(PromptGroups) do
        for _, v in pairs(pGroup.prompts) do
            safeDelete(v.prompt)
        end
    end
    Prompts, PromptGroups = {}, {}
end)

-- single loop handles both prompts and prompt groups
CreateThread(function()
    while true do
        local sleep = 1000
        if next(Prompts) or next(PromptGroups) then
            local coords = GetEntityCoords(cache.ped)
            local maxDist = RSGConfig.PromptDistance

            for _, v in pairs(Prompts) do
                if #(coords - v.coords) < maxDist then
                    sleep = 0
                    if not v.prompt then setupPrompt(v) end
                    if UiPromptHasHoldModeCompleted(v.prompt) then
                        executeOptions(v.options)
                        resetPrompt(v.prompt)
                        break
                    end
                elseif v.prompt then
                    UiPromptDelete(v.prompt)
                    v.prompt = nil
                end
            end

            for _, pGroup in pairs(PromptGroups) do
                if #(coords - pGroup.coords) < maxDist then
                    sleep = 0
                    if not pGroup.created then setupPromptGroup(pGroup) end
                    Citizen.InvokeNative(0xC65A45D4453C2627, pGroup.group, CreateVarString(10, 'LITERAL_STRING', pGroup.label), 1) -- UiPromptSetActiveGroupThisFrame
                    for _, v in pairs(pGroup.prompts) do
                        if UiPromptHasHoldModeCompleted(v.prompt) then
                            executeOptions(v.options)
                            resetPrompt(v.prompt)
                            break
                        end
                    end
                elseif pGroup.created then
                    for _, v in pairs(pGroup.prompts) do
                        safeDelete(v.prompt)
                        v.prompt = nil
                    end
                    pGroup.created = false
                end
            end
        end
        Wait(sleep)
    end
end)

-- https://github.com/femga/rdr3_discoveries/tree/master/graphics/HUD/prompts/prompt_types
-- hides the default prompt types every frame (must run each frame)
CreateThread(function()
    while true do
        Citizen.InvokeNative(0xFC094EF26DD153FA, 1) -- UiPromptDisablePromptTypeThisFrame
        Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
        Wait(0)
    end
end)

exports('createPrompt', createPrompt)
exports('createPromptGroup', createPromptGroup)
exports('getPrompt', getPrompt)
exports('getPromptGroup',getPromptGroup)
exports('deletePrompt', deletePrompt)
exports('deletePromptGroup',deletePromptGroup)
