CreateThread(function()
    local interval = (1000 * 60) * RSGCore.Config.UpdateInterval

    while true do
        Wait(interval)

        if not LocalPlayer.state.isLoggedIn then goto continue end

        local metadata = {}
        local keys = { "hunger", "thirst", "cleanliness", "stress" }

        for _, key in ipairs(keys) do
            local value = LocalPlayer.state[key]
            if value ~= nil then
                metadata[key] = value
            end
        end

        if next(metadata) then
            TriggerServerEvent("RSGCore:Server:SetMetaData", metadata)
            Wait(0)
        end
        
        TriggerServerEvent("RSGCore:UpdatePlayer")

        ::continue::
    end
end)