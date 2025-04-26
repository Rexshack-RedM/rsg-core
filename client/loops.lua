CreateThread(function()
    local interval = (1000 * 60) * RSGCore.Config.UpdateInterval

    while true do
        Wait(interval)
        if LocalPlayer.state.isLoggedIn then 
            TriggerServerEvent("RSGCore:UpdatePlayer")
        end     
    end
end)