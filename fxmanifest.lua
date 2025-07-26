fx_version 'cerulean'
game 'gta5'

author 'AI Generated Framework'
description 'Walsh Core - Custom FiveM Framework for PvP Gameplay'
version '1.0.0'

shared_scripts {
    'shared/utils.lua',
    'shared/config.lua',
    'config.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/modules/player.lua',
    'server/modules/economy.lua',
    'server/modules/gangs.lua',
    'server/modules/jobs.lua',
    'server/modules/redzone.lua',
    'server/modules/vehicles.lua',
    'server/modules/weapons.lua',
    'server/modules/admin.lua'
}

client_scripts {
    'client/main.lua',
    'client/events.lua',
    'client/ui.lua',
    'client/modules/player.lua',
    'client/modules/economy.lua',
    'client/modules/gangs.lua',
    'client/modules/redzone.lua',
    'client/modules/vehicles.lua',
    'client/modules/weapons.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/style.css',
    'html/js/script.js'
}

dependencies {
    'mysql-async'
}
