fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_admin'
description 'Menú de administración'
author 'jj'
version '1.0.0'

dependencies {
    'oxmysql',
    'ox_lib',
    'jj-framework',
    'ox_inventory',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}
