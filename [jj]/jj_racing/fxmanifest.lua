fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_racing'
author 'Josete & jesus'
description 'Creador y sistema de carreras para jj-framework con NUI en Bun/React, integrado con jj_crews'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/core.lua',
    'config.lua',
    'locales/*.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/nui.lua',
    'client/main.lua',
    'client/race.lua',
    'client/ghost.lua',
    'client/creator.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'server/database.lua',
    'server/permissions.lua',
    'server/validation.lua',
    'server/crews.lua',
    'server/leaderboard.lua',
    'server/lobbies.lua',
    'server/results.lua',
    'server/main.lua',
    'server/callbacks.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**',
}

dependencies {
    'jj-framework',
    'ox_lib',
    'oxmysql',
}

-- Opcional (se detecta en tiempo de ejecucion): jj_crews
