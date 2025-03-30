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
        Prompts[name].active = false
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
        PromptGroups[group].active = false
        PromptGroups[group].created = false
        PromptGroups[group].prompts = prompts
    else
        print('[rsg-core]  Prompt with name ' .. group .. ' already exists!')
    end
end

local function getPrompt()
    if Prompts then 
    return Prompts
    end
end

local function getPromptGroup()
    if PromptGroups then 
    return PromptGroups
    end
end


local function deletePrompt(name)
    if Prompts then
        Citizen.InvokeNative(0x8A0FB4D03A630D21, Prompts[name].prompt, false)
        Citizen.InvokeNative(0x71215ACCFDE075EE, Prompts[name].prompt, false)
        Prompts[name] = nil
    end
end

local function deletePromptGroup(name)
    if PromptGroups then
        Citizen.InvokeNative(0x8A0FB4D03A630D21, PromptGroups[name].prompt, false)
        Citizen.InvokeNative(0x71215ACCFDE075EE, PromptGroups[name].prompt, false)
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
    Citizen.InvokeNative(0x8A0FB4D03A630D21, prompt.prompt, false)
    Citizen.InvokeNative(0x71215ACCFDE075EE, prompt.prompt, false)
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
        Citizen.InvokeNative(0x8A0FB4D03A630D21, Prompts[k].prompt, false)
        Citizen.InvokeNative(0x71215ACCFDE075EE, Prompts[k].prompt, false)
        Prompts[k].prompt = nil
    end
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
                    if (not Prompts[k].active) then
                        Citizen.InvokeNative(0x8A0FB4D03A630D21, Prompts[k].prompt, true)
                        Citizen.InvokeNative(0x71215ACCFDE075EE, Prompts[k].prompt, true)
                        Prompts[k].active = true
                    end
                    if (Citizen.InvokeNative(0xE0F65F0640EF0617, Prompts[k].prompt)) then
                        executeOptions(Prompts[k].options)
                        Citizen.InvokeNative(0x8A0FB4D03A630D21, Prompts[k].prompt, false)
                        Citizen.InvokeNative(0x71215ACCFDE075EE, Prompts[k].prompt, false)
                        Prompts[k].prompt = nil
                        Prompts[k].active = false
                    end
                else
                    if (Prompts[k].active) then
                        Citizen.InvokeNative(0x8A0FB4D03A630D21, Prompts[k].prompt, false)
                        Citizen.InvokeNative(0x71215ACCFDE075EE, Prompts[k].prompt, false)
                        Prompts[k].prompt = nil
                        Prompts[k].active = false
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
                        if (Citizen.InvokeNative(0xE0F65F0640EF0617, j.prompt)) then
                            executeOptions(j.options)
                            j.prompt = nil
                            PromptGroups[k].active = false
                        end
                    end
                else
                    if (PromptGroups[k].active) then
                        for i,j in pairs(PromptGroups[k].prompts) do
                            j.prompt = nil
                        end
                        Prompts[k].active = false
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
