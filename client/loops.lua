CreateThread(function()
    while true do
        local sleep = 0
        if LocalPlayer.state.isLoggedIn then
            sleep = (1000 * 60) * RSGCore.Config.UpdateInterval
            TriggerServerEvent('RSGCore:UpdatePlayer')
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if (RSGCore.PlayerData.metadata['hunger'] <= 0 or RSGCore.PlayerData.metadata['thirst'] <= 0) and not (RSGCore.PlayerData.metadata['isdead'] or RSGCore.PlayerData.metadata['inlaststand']) then
                local ped = PlayerPedId()
                local currentHealth = GetEntityHealth(ped)
                local decreaseThreshold = math.random(5, 10)
                SetEntityHealth(ped, currentHealth - decreaseThreshold)
            end
        end
        Wait(RSGCore.Config.StatusInterval)
    end
end)
