RSGCore = {}
RSGCore.Config = RSGConfig
RSGCore.Shared = RSGShared
RSGCore.ClientCallbacks = {}
RSGCore.ServerCallbacks = {}

exports('GetCoreObject', function()
    return RSGCore
end)

-- To use this export in a script instead of manifest method
-- Just put this line of code below at the very top of the script
-- local RSGCore = exports['rsg-core']:GetCoreObject()
