fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_boosting'
description 'Contratos de robo de vehículos, progresión, hackeos, criptomoneda, tienda y administración'
author 'Josete & Jesus'
version '1.0.0'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'jj-framework',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/contracts.lua',
    'client/vehicles.lua',
    'client/hacking.lua',
    'client/gps.lua',
    'client/police.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/db.lua',
    'server/security.lua',
    'server/progression.lua',
    'server/economy.lua',
    'server/history.lua',
    'server/leaderboard.lua',
    'server/store.lua',
    'server/contracts.lua',
    'server/admin.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*',
}
