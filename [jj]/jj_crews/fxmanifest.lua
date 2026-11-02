fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_crews'
author 'Josete & jesus'
description 'Sistema de crews (equipos de pilotos) para jj-framework con NUI en Bun/React'
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
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'server/database.lua',
    'server/permissions.lua',
    'server/ranking.lua',
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
