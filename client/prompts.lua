local Prompts = {}
local PromptGroups = {}

local function createPrompt(name, coords, key, text, options)
    if (Prompts[name] == nil) then
        Prompts[name] = {}
        Prompts[name].name = name
        Prompts[name].coords = coords
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
        PromptGroups[group].coords = coords
        PromptGroups[group].label = label
        PromptGroups[group].group = group
        PromptGroups[group].created = false
        PromptGroups[group].prompts = prompts
    else
        print('[rsg-core]  Prompt with name ' .. group .. ' already exists!')
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
        UiPromptDelete(Prompts[name].prompt)
        Prompts[name] = nil
    end
end

local function deletePromptGroup(name)
    if PromptGroups[name] then
        for k,v in pairs(PromptGroups[name].prompts) do
            UiPromptDelete(v.prompt)
        end
        PromptGroups[name] = nil
    end
end


local function executeOptions(options)
    if (options.type == 'client') then
        if (options.args == nil) then
            TriggerEvent(options.event)
        else
            TriggerEvent(options.event, table.unpack(options.args))
        end
    else
        if (options.args == nil) then
            TriggerServerEvent(options.event)
        else
            TriggerServerEvent(options.event, table.unpack(options.args))
        end
    end
end

local function setupPrompt(prompt)
    local str = CreateVarString(10, 'LITERAL_STRING', prompt.text)
    prompt.prompt = Citizen.InvokeNative(0x04F97DE45A519419, Citizen.ReturnResultAnyway())
    Citizen.InvokeNative(0xB5352B7494A08258, prompt.prompt, prompt.key)
    Citizen.InvokeNative(0x5DD02A8318420DD7, prompt.prompt, str)
    Citizen.InvokeNative(0x8A0FB4D03A630D21, prompt.prompt, true)
    Citizen.InvokeNative(0x71215ACCFDE075EE, prompt.prompt, true)
    Citizen.InvokeNative(0x94073D5CA3F16B7B, prompt.prompt, 1000)
    Citizen.InvokeNative(0xF7AA2696A22AD8B9, prompt.prompt)
end

local function setupPromptGroup(prompt)
    for k,v in pairs(prompt.prompts) do
        local str = CreateVarString(10, 'LITERAL_STRING', v.text)
        v.prompt = Citizen.InvokeNative(0x04F97DE45A519419, Citizen.ReturnResultAnyway())
        Citizen.InvokeNative(0xB5352B7494A08258, v.prompt, v.key)
        Citizen.InvokeNative(0x5DD02A8318420DD7, v.prompt, str)
        Citizen.InvokeNative(0x8A0FB4D03A630D21, v.prompt, true)
        Citizen.InvokeNative(0x71215ACCFDE075EE, v.prompt, true)
        Citizen.InvokeNative(0x94073D5CA3F16B7B, v.prompt, 1000)
        Citizen.InvokeNative(0x2F11D3A254169EA4, v.prompt, prompt.group, 0)
        Citizen.InvokeNative(0xF7AA2696A22AD8B9, v.prompt)
    end

    prompt.created = true
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for k,v in pairs(Prompts) do
        UiPromptDelete(Prompts[k].prompt)
    end
    Prompts = {}

    for _,pGroup in pairs(PromptGroups) do
        for k,v in pairs(pGroup.prompts) do
            UiPromptDelete(v.prompt)
        end 
    end
    PromptGroups = {}
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if (next(Prompts) ~= nil) then
            local coords = GetEntityCoords(cache.ped, true)
            for k,v in pairs(Prompts) do
                local distance = #(coords - v.coords)
                if (distance < RSGConfig.PromptDistance) then
                    sleep = 1
                    if (Prompts[k].prompt == nil) then
                        setupPrompt(Prompts[k])
                    end
                    if UiPromptHasHoldModeCompleted(Prompts[k].prompt) then
                        executeOptions(Prompts[k].options)
                        UiPromptSetEnabled(Prompts[k].prompt, false)
                        UiPromptSetVisible(Prompts[k].prompt, false)
                        Wait(0)
                        UiPromptSetEnabled(Prompts[k].prompt, true)
                        UiPromptSetVisible(Prompts[k].prompt, true)
                        break
                    end
                else
                    if Prompts[k].prompt then
                        UiPromptDelete(Prompts[k].prompt)
                        Prompts[k].prompt = nil
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if (next(PromptGroups) ~= nil) then
            local coords = GetEntityCoords(cache.ped, true)
            for k,v in pairs(PromptGroups) do
                local distance = #(coords - v.coords)
                local promptGroup = PromptGroups[k].group
                if (distance < RSGConfig.PromptDistance) then
                    sleep = 1
                    if (PromptGroups[k].created == false) then
                        setupPromptGroup(PromptGroups[k])
                    end

                    Citizen.InvokeNative(0xC65A45D4453C2627, promptGroup, CreateVarString(10, 'LITERAL_STRING', PromptGroups[k].label), 1)

                    for i,j in pairs(PromptGroups[k].prompts) do
                        if UiPromptHasHoldModeCompleted(j.prompt) then
                            executeOptions(j.options)
                            UiPromptSetEnabled(j.prompt, false)
                            UiPromptSetVisible(j.prompt, false)
                            Wait(0)
                            UiPromptSetEnabled(j.prompt, true)
                            UiPromptSetVisible(j.prompt, true)
                            break
                        end
                    end
                else
                    if (PromptGroups[k].created) then
                        for i,j in pairs(PromptGroups[k].prompts) do
                            UiPromptDelete(j.prompt)
                            j.prompt = nil
                        end
                        PromptGroups[k].created = false
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- https://github.com/femga/rdr3_discoveries/tree/master/graphics/HUD/prompts/prompt_types
CreateThread(function()
    while true do
        Wait(1)
        Citizen.InvokeNative(0xFC094EF26DD153FA, 1)
        Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
        --Citizen.InvokeNative(0xFC094EF26DD153FA, 3)
    end
end)

exports('createPrompt', createPrompt)
exports('createPromptGroup', createPromptGroup)
exports('getPrompt', getPrompt)
exports('getPromptGroup',getPromptGroup)
exports('deletePrompt', deletePrompt)
exports('deletePromptGroup',deletePromptGroup)
