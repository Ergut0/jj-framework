fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_gangs'
description 'Bandas, territorios, droga y grafitis'
author 'josete & jesus'
version '1.0.0'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'jj-framework',
    'jj_garages',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/menus.lua',
    'client/panel.lua',
    'client/drugs.lua',
    'client/graffiti.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/members.lua',
    'server/admin.lua',
    'server/drugs.lua',
    'server/graffiti.lua',
}

ui_page 'web/dist/index.html'

files {
    'html/graffiti.html',
    'web/dist/index.html',
    'web/dist/assets/*',
}
