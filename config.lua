RSGConfig = {}

RSGConfig.MaxPlayers = GetConvarInt('sv_maxclients', 48) -- Gets max players from config file, default 48
RSGConfig.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)
RSGConfig.UpdateInterval = 1 -- how often to update player data in minutes
RSGConfig.StatusInterval = 5000 -- how often to check hunger/thirst status in milliseconds
RSGConfig.EnablePVP = true
RSGConfig.HidePlayerNames = true

RSGConfig.Money = {}
RSGConfig.Money.MoneyTypes = { cash = 50, bank = 500, bloodmoney = 0 } -- type = startamount - Add or remove money types for your server (for ex. blackmoney = 0), remember once added it will not be removed from the database!
RSGConfig.Money.DontAllowMinus = { 'cash', 'bloodmoney' } -- Money that is not allowed going in minus
RSGConfig.Money.PayCheckTimeOut = 30 -- The time in minutes that it will give the paycheck
RSGConfig.Money.PayCheckSociety = false -- If true paycheck will come from the society account that the player is employed at, requires qb-management

RSGConfig.Player = {}
RSGConfig.Player.RevealMap = true
RSGConfig.Player.HungerRate = 1.0 -- Rate at which hunger goes down.
RSGConfig.Player.ThirstRate = 1.0 -- Rate at which thirst goes down.
RSGConfig.Player.Bloodtypes = {
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-",
}

RSGConfig.Server = {} -- General server config
RSGConfig.Server.Closed = false -- Set server closed (no one can join except people with ace permission 'qbadmin.join')
RSGConfig.Server.ClosedReason = "Server Closed" -- Reason message to display when people can't join the server
RSGConfig.Server.Uptime = 0 -- Time the server has been up.
RSGConfig.Server.Whitelist = false -- Enable or disable whitelist on the server
RSGConfig.Server.WhitelistPermission = 'admin' -- Permission that's able to enter the server when the whitelist is on
RSGConfig.Server.Discord = "" -- Discord invite link
RSGConfig.Server.CheckDuplicateLicense = false -- Check for duplicate rockstar license on join
RSGConfig.Server.Permissions = { 'god', 'admin', 'mod' } -- Add as many groups as you want here after creating them in your server.cfg

RSGConfig.Notify = {}

RSGConfig.Notify.NotificationStyling = {
    group = false, -- Allow notifications to stack with a badge instead of repeating
    position = "right", -- top-left | top-right | bottom-left | bottom-right | top | bottom | left | right | center
    progress = true -- Display Progress Bar
}

-- These are how you define different notification variants
-- The "color" key is background of the notification
-- The "icon" key is the css-icon code, this project uses `Material Icons` & `Font Awesome`
RSGConfig.NotifyPosition = 'top-right' -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
