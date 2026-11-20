RSGConfig = {}

RSGConfig.MaxPlayers = GetConvarInt('sv_maxclients', 48) -- Gets max players from config file, default 48
RSGConfig.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)
RSGConfig.UpdateInterval = 5                             -- how often to save player data in database in minutes
RSGConfig.HidePlayerNames = true

RSGConfig.Money = {}
RSGConfig.Money.MoneyTypes = { cash = 50, gold = 0, bank = 0, bloodmoney = 0 } -- valbank/rhobank/blkbank/armbank removed: rsg-banking branches replace them ('bank' kept so old scripts don't break; rsg-banking forwards it to the home branch)
-- -- type = startamount - Add or remove money types for your server (for ex. blackmoney = 0), remember once added it will not be removed from the database!
RSGConfig.Money.DontAllowMinus = { 'cash', 'gold', 'bloodmoney', 'bank' }    -- Money that is not allowed going in minus
RSGConfig.Money.MinusLimit = -5000                                   -- The maximum amount you can be negative 
RSGConfig.Money.PayCheckTimeOut = 10                                 -- The time in minutes that it will give the paycheck
RSGConfig.Money.PayCheckSociety = false                              -- NOT supported by rsg-banking v3 (no society accounts) - leave false
RSGConfig.Money.EnableMoneyItems = true                              -- If true cash and bloodmoney will be represented wih inventory items
RSGConfig.Money.GoldItem = 'gold'                                    -- Inventory item used to represent gold when EnableGoldItems is true

RSGConfig.Gold = {}
RSGConfig.Gold.EnableGoldItems = false

RSGConfig.Player = {}
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
    weight = 35000,
    slots = 25,
}

RSGConfig.Server = {}                                    -- General server config
RSGConfig.Server.Closed = false                          -- Set server closed (no one can join except people with ace permission 'rsgadmin.join')
RSGConfig.Server.ClosedReason = 'Server Closed'          -- Reason message to display when people can't join the server
RSGConfig.Server.Uptime = 0                              -- Time the server has been up.
RSGConfig.Server.Whitelist = false                       -- Enable or disable whitelist on the server
RSGConfig.Server.WhitelistPermission = 'admin'           -- Permission that's able to enter the server when the whitelist is on
RSGConfig.Server.PVP = true                              -- Enable or disable pvp on the server (Ability to shoot other players)
RSGConfig.Server.Discord = ''                            -- Discord invite link
RSGConfig.Server.CheckDuplicateLicense = true            -- Check for duplicate rockstar license on join

 -- Add as many groups as you want here after creating them in your server.cfg
RSGConfig.Server.Permissions = {
    'god',
    'developer',
    'headadmin',
    'admin',
    'mod',
    'helper'
}

RSGConfig.Commands = {}                                  -- Command Configuration
RSGConfig.Commands.OOCColor = { 255, 151, 133 }          -- RGB color code for the OOC command

RSGConfig.PromptDistance = 1.5

-- Death and kill events (RSGCore:Server:OnPlayerDeath / OnPlayerKilled, export GetLastDeath).
-- A kill is only credited to a player when they are in range, in the same routing bucket, PVP is on,
-- and the killer's own client confirms it.
RSGConfig.Death = {
    Enabled = true,
    MaxKillDistance = 500.0,    -- metres between victim and claimed killer (server positions)
    RequireKillerConfirm = true,
    ConfirmTimeout = 3000,      -- ms to wait for the killer's client
    MinSecondsBetween = 8,      -- ignore repeat reports from the same victim inside this window
}

-- While an rsg-core NUI menu (/myjobs, /jobadmin) is open, block game controls but keep push-to-talk working.
RSGConfig.AllowPushToTalkWhileOpen = true
RSGConfig.PushToTalkControls = {
    0x4BC9DABB, -- INPUT_PUSH_TO_TALK
}

RSGConfig.Notify = {
    Position = 'top-right',   -- top-right | top-left | top | bottom-right | bottom-left | bottom | center-right | center-left
    Duration = 5000,          -- default ms
    MaxVisible = 5,           -- oldest are removed when exceeded
    Sound = true,             -- play a frontend sound on notify
}
-- progress bar / circle (RSGCore.Functions.ProgressBar / ProgressCircle)
RSGConfig.Progress = {
    CancelKey   = 0x8CC9CD42, -- X (INPUT_GAME_MENU_TAB_RIGHT_SECONDARY)
    CancelLabel = 'X',        -- shown in the cancel hint
}

RSGConfig.Player.RevealMap = true

-- Metadata keys a client is allowed to change via the 'RSGCore:Server:SetMetaData' net event.
-- Anything not listed here (isdead, injail, ishandcuffed, jailitems, rep, criminalrecord, ...) can only be set server-side.
-- Add keys here only if one of your client scripts genuinely needs to set them.
RSGConfig.ClientWritableMetadata = {
    hunger = true,
    thirst = true,
    cleanliness = true,
    stress = true,
    health = true,
    armor = true,
}

-- Database: create the players/bans tables automatically on start. Set false to import install.sql manually.
RSGConfig.AutoDatabase = true

-- Rate limits and distances used by server events and chat commands
RSGConfig.Limits = {
    SaveCooldown = 30,        -- seconds between client requested saves
    DutyCooldownMs = 2000,    -- duty toggle cooldown
    SpawnCooldownMs = 5000,   -- vehicle spawn callback cooldown
    SpawnMaxDistance = 50.0,  -- max distance between player and requested spawn point
    MeCooldownMs = 2000,      -- /me cooldown
    OocCooldownMs = 2000,     -- /ooc cooldown
    OocRange = 20.0,          -- /ooc chat range
}

-- Saving: the server saves every player each UpdateInterval minutes instead of relying on the client
RSGConfig.ServerSideSave = true
RSGConfig.LogSaves = false -- print a console line on every player save

-- Ban checks on join (license is always checked)
RSGConfig.Ban = {
    CheckDiscord = true,
    CheckIP = false,
}

-- rsg-log channel used for admin command audit logs
RSGConfig.AdminLogChannel = 'admin'
