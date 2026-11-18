-- Periodically asks the server to save this player (the server rate-limits this event)
CreateThread(function()
    local interval = (1000 * 60) * RSGCore.Config.UpdateInterval

    while true do
        Wait(interval)
        if LocalPlayer.state.isLoggedIn and not RSGCore.Config.ServerSideSave then
            TriggerServerEvent('RSGCore:UpdatePlayer')
        end
    end
end)
