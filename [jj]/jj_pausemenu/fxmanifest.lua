fx_version 'cerulean'
games { 'gta5' }
author 'josete & jesus'
description 'Menú de pausa'
version '2.0.0'

lua54 'yes'

dependencies {
    'oxmysql',
    'ox_lib',
    'jj-framework',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/**/*.lua',
}

client_scripts {
    'client/init.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
