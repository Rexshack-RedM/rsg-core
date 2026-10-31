fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

lua54 'yes'

description 'rsg-core'
version '3.1.1'

shared_scripts {
    'shared/locale.lua',
    'shared/config.lua',
    'shared/main.lua',
    'shared/items.lua',
    'shared/jobs.lua',
    'shared/vehicles.lua',
    'shared/gangs.lua',
    'shared/weapons.lua',
    'shared/locations.lua',
    'shared/keybinds.lua',
    'shared/multijob.lua'
}

ui_page 'html/index.html'

files {
    'shared/locale.lua',  -- shared: other resources use '@rsg-core/shared/locale.lua'
    'shared/require.lua', -- shared: other resources use '@rsg-core/shared/require.lua'
    'locales/*.json',
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/multijob/style.css',
    'html/multijob/admin.css',
    'html/multijob/script.js',
    'html/multijob/admin.js'
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/lib.lua',
    'client/loops.lua',
    'client/events.lua',
    'client/drawtext.lua',
    'client/prompts.lua',
    'client/pvp.lua',
    'client/multijob.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/functions.lua',
    'server/moneyitems.lua',
    'server/player.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/exports.lua',
    'server/multijob/sv_config.lua',
    'server/multijob/default_jobs.lua',
    'server/multijob/webhook.lua',
    'server/multijob/jobs.lua',
    'server/multijob/server.lua',
    'server/multijob/admin.lua',
    'server/debug.lua',
    'server/versionchecker.lua'
}

-- rsg-multijob is built in; old dependencies and exports['rsg-multijob'] calls still resolve
provide 'rsg-multijob'

dependencies {
    'oxmysql',
}
