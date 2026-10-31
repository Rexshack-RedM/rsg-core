-- Multi-job settings (merged from rsg-multijob). Webhook URLs live in server/multijob/sv_config.lua.
RSGConfig.MultiJob = {
    MaxJobs = 3,
    JobSwitchCooldown = 3000, -- ms a player must wait between job switches

    -- Job admin panel: create/edit/delete server jobs in-game.
    -- Job definitions are stored in the `multijob_jobs` table.
    Admin = {
        Command = 'jobadmin',
        Permission = 'admin', -- RSGCore permission level required (god, admin, mod, ...)
    },

    -- Fallback icons. Jobs created/edited in /jobadmin store their own icon, which takes priority.
    JobIcons = {
        ['vallaw'] = 'fa-solid fa-shield',
        ['rholaw'] = 'fa-solid fa-shield',
        ['blklaw'] = 'fa-solid fa-shield',
        ['strlaw'] = 'fa-solid fa-shield',
        ['stdenlaw'] = 'fa-solid fa-shield',
        ['medic'] = 'fa-solid fa-user-nurse',
        ['priest'] = 'fa-solid fa-user-nurse',
        ['banker'] = 'fa-solid fa-shield',
        ['judge'] = 'fa-solid fa-shield',
        ['wagonmechanic'] = 'fa-solid fa-shield',
        ['reporter'] = 'fa-solid fa-shield',
        ['bountyhunter'] = 'fa-solid fa-shield',
        ['gunsmith'] = 'fa-solid fa-shield',
        ['taxi'] = 'fa-solid fa-shield',
        ['saloonowner'] = 'fa-solid fa-shield',
        ['undertaker'] = 'fa-solid fa-shield',
        ['traindriver'] = 'fa-solid fa-shield',
        ['fireman'] = 'fa-solid fa-shield',
        ['drugdealer'] = 'fa-solid fa-shield',
        ['valgang'] = 'fa-solid fa-shield',
        ['rhogang'] = 'fa-solid fa-shield',
        ['stdengang'] = 'fa-solid fa-shield',
        ['strgang'] = 'fa-solid fa-shield',
        ['blkgang'] = 'fa-solid fa-shield',
        ['wagonrepairs'] = 'fa-solid fa-shield',
        ['horsebreeder'] = 'fa-solid fa-shield',
        ['merchant'] = 'fa-solid fa-shield',
        ['barber'] = 'fa-solid fa-shield',
        ['tailor'] = 'fa-solid fa-shield',
    }
}
