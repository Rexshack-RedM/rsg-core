RSGConfig = {}

RSGConfig.MaxPlayers = GetConvarInt('sv_maxclients', 48) -- Gets max players from config file, default 48
RSGConfig.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)
RSGConfig.UpdateInterval = 5                             -- how often to update player data in minutes
RSGConfig.StatusInterval = 5000                          -- how often to check hunger/thirst status in milliseconds

RSGConfig.Money = {}
RSGConfig.Money.MoneyTypes = { cash = 50, bank = 0, valbank = 0, rhobank = 0, blkbank = 0, armbank = 0, bloodmoney = 0 } -- type = startamount - Add or remove money types for your server (for ex. blackmoney = 0), remember once added it will not be removed from the database!
RSGConfig.Money.DontAllowMinus = { 'cash', 'bloodmoney' } -- Money that is not allowed going in minus
RSGConfig.Money.PayCheckTimeOut = 10                                 -- The time in minutes that it will give the paycheck
RSGConfig.Money.PayCheckSociety = false                              -- If true paycheck will come from the society account that the player is employed at, requires rsg-management

RSGConfig.Player = {}
RSGConfig.Player.HungerRate = 4.2 -- Rate at which hunger goes down.
RSGConfig.Player.ThirstRate = 3.8 -- Rate at which thirst goes down.
RSGConfig.Player.Bloodtypes = {
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
}

RSGConfig.Player.PlayerDefaults = {
    citizenid = function() return RSGCore.Player.CreateCitizenId() end,
    cid = 1,
    money = function()
        local moneyDefaults = {}
        for moneytype, startamount in pairs(RSGConfig.Money.MoneyTypes) do
            moneyDefaults[moneytype] = startamount
        end
        return moneyDefaults
    end,
    optin = true,
    charinfo = {
        firstname = 'Firstname',
        lastname = 'Lastname',
        birthdate = '00-00-0000',
        gender = 0,
        nationality = 'USA',
        phone = function() return RSGCore.Functions.CreatePhoneNumber() end,
        account = function() return RSGCore.Functions.CreateAccountNumber() end
    },
    job = {
        name = 'unemployed',
        label = 'Civilian',
        payment = 10,
        type = 'none',
        onduty = false,
        isboss = false,
        grade = {
            name = 'Freelancer',
            level = 0
        }
    },
    gang = {
        name = 'none',
        label = 'No Gang Affiliation',
        isboss = false,
        grade = {
            name = 'none',
            level = 0
        }
    },
    metadata = {
        health = 600,
        hunger = 100,
        thirst = 100,
        cleanliness = 100,
        stress = 0,
        isdead = false,
        armor = 0,
        ishandcuffed = false,
        injail = 0,
        jailitems = {},
        status = {},
        rep = {},
        callsign = 'NO CALLSIGN',
        bloodtype = function() return RSGConfig.Player.Bloodtypes[math.random(1, #RSGConfig.Player.Bloodtypes)] end,
        fingerprint = function() return RSGCore.Player.CreateFingerId() end,
        walletid = function() return RSGCore.Player.CreateWalletId() end,
        criminalrecord = {
            hasRecord = false,
            date = nil
        },
    },
    position = RSGConfig.DefaultSpawn,
    items = {},
}

RSGConfig.Server = {}                                    -- General server config
RSGConfig.Server.Closed = false                          -- Set server closed (no one can join except people with ace permission 'rsgadmin.join')
RSGConfig.Server.ClosedReason = 'Server Closed'          -- Reason message to display when people can't join the server
RSGConfig.Server.Uptime = 0                              -- Time the server has been up.
RSGConfig.Server.Whitelist = false                       -- Enable or disable whitelist on the server
RSGConfig.Server.WhitelistPermission = 'admin'           -- Permission that's able to enter the server when the whitelist is on
RSGConfig.Server.PVP = true                              -- Enable or disable pvp on the server (Ability to shoot other players)
RSGConfig.EnablePVP = true
RSGConfig.Server.Discord = ''                            -- Discord invite link
RSGConfig.Server.CheckDuplicateLicense = true            -- Check for duplicate rockstar license on join
RSGConfig.Server.Permissions = { 'god', 'admin', 'mod' } -- Add as many groups as you want here after creating them in your server.cfg

RSGConfig.Commands = {}                                  -- Command Configuration
RSGConfig.Commands.OOCColor = { 255, 151, 133 }          -- RGB color code for the OOC command

RSGConfig.Notify = {}

RSGConfig.Notify.NotificationStyling = {
    group = false,      -- Allow notifications to stack with a badge instead of repeating
    position = 'right', -- top-left | top-right | bottom-left | bottom-right | top | bottom | left | right | center
    progress = true     -- Display Progress Bar
}

-- These are how you define different notification variants
-- The "color" key is background of the notification
-- The "icon" key is the css-icon code, this project uses `Material Icons` & `Font Awesome`
RSGConfig.Notify.VariantDefinitions = {
    success = {
        classes = 'success',
        icon = 'check_circle'
    },
    primary = {
        classes = 'primary',
        icon = 'notifications'
    },
    warning = {
        classes = 'warning',
        icon = 'warning'
    },
    error = {
        classes = 'error',
        icon = 'error'
    },
    police = {
        classes = 'police',
        icon = 'local_police'
    },
    ambulance = {
        classes = 'ambulance',
        icon = 'fas fa-ambulance'
    }
}

RSGConfig.PromptDistance = 1.5
RSGConfig.Player.CleanlinessRate = 0.0 -- Rate at which cleanliness goes down.
RSGConfig.Player.RevealMap = true
