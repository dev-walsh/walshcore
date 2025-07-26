fx_version 'cerulean'
game 'gta5'

author 'Walsh Development Team'
description 'Walsh Core - The foundation of Walsh Framework'
version '1.0.0'
repository 'https://github.com/walsh-development/walsh-core'

shared_scripts {
    'config/config.lua',
    'shared/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
    'server/player.lua',
    'server/commands.lua',
    'server/functions.lua',
    'server/loops.lua',
    'server/events.lua'
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/events.lua',
    'client/loops.lua'
}

dependencies {
    'mysql-async'
}

provide 'walsh-core'