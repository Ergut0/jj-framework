fx_version 'cerulean'
game 'gta5'

name "jj_deathsystem"
description "Sistema de Muerte"
author "jj"
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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/scripts.js',
    'html/fonts/*.ttf',
}
