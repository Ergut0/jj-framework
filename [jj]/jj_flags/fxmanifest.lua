fx_version 'cerulean'
game 'gta5'

author 'Josete & jesus'
description 'Captura de banderas entre bandas'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/core.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/logo.webp',
    'web/dist/assets/*'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'jj-framework',
    'jj_gangs'
}
