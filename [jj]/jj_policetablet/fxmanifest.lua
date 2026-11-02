fx_version 'cerulean'
game 'gta5'

name "jj_policetablet"
description "Sistema de tablet policial"
author "Josete & Jesus"
version "2.0.0"
lua54 'yes'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'jj-framework',
    'jj_policedispatch',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/main.lua',
    'client/modules/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
    'server/database.lua',
    'server/modules/*.lua',
}

ui_page "web/dist/index.html"

files {
    'client/utils/functions.lua',
    'web/dist/**',
    'web/dist/assets/**',
}
