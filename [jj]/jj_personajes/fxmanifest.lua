fx_version 'cerulean'
game 'gta5'

author 'Josete & jesus'
description 'Pantalla de personajes de Atlantis Roleplay'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/core.lua',
    'shared/config.lua'
}

client_scripts {
    'client/stage.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/logo.webp',
    'web/dist/assets/*'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'jj-framework',
    'ox_inventory'
}
