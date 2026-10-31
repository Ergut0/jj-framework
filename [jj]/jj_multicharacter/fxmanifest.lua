fx_version 'cerulean'
game 'gta5'
name "jj_multicharacter"
description "Sistema de Multicharacter"
author "josete & jesus"
version "1.0.0"
lua54 "yes"

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
        'web/dist/assets/*.js',
        'web/dist/assets/*.css',
        'web/dist/video.mp4',
        'web/dist/index.html',
}
