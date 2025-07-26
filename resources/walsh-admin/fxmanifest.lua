fx_version 'cerulean'
game 'gta5'

author 'Walsh Development Team'
description 'Walsh Admin - Administration Tools for Walsh Framework'
version '1.0.0'

shared_scripts {
    '@walsh-core/shared/main.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/admin.lua',
    'client/noclip.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
    'server/admin.lua',
    'server/commands.lua',
    'server/bans.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js'
}

dependencies {
    'walsh-core',
    'mysql-async'
}

provide 'walsh-admin'