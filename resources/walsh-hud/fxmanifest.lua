fx_version 'cerulean'
game 'gta5'

author 'Walsh Development Team'
description 'Walsh HUD - User Interface for Walsh Framework'
version '1.0.0'

shared_script '@walsh-core/shared/main.lua'

client_scripts {
    'client/main.lua',
    'client/hud.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js',
    'html/assets/*.png',
    'html/assets/*.jpg',
    'html/assets/*.svg'
}

dependencies {
    'walsh-core'
}

provide 'walsh-hud'