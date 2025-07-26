fx_version 'cerulean'
game 'gta5'

author 'Walsh Development Team'
description 'Walsh Gangs - Gang System for Walsh Framework'
version '1.0.0'

shared_scripts {
    '@walsh-core/shared/main.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/gangs.lua',
    'client/territories.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
    'server/gangs.lua',
    'server/territories.lua'
}

dependencies {
    'walsh-core',
    'mysql-async'
}

provide 'walsh-gangs'