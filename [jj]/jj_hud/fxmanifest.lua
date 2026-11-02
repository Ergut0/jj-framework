fx_version 'cerulean'
games { 'gta5' }
author 'josete & jesus'

name 'jj_hud'
description 'HUD del jugador y del vehículo, y sistema de hambre y sed'
version '2.0.0'
lua54 'yes'

dependencies {
    'ox_lib',
    'jj-framework',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/vehicle.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/logo.png',
    'web/dist/assets/*',
}
