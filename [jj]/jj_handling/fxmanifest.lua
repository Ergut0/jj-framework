fx_version 'cerulean'
game 'gta5'

name 'jj_handling'
author 'Josete & jesus'
description 'Editor de handling en tiempo real con perfiles, talleres y permisos'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/core.lua',
    'config.lua',
    'shared/utils.lua',
    'shared/parameters.lua',
    'shared/validation.lua',
}

client_scripts {
    'client/handling.lua',
    'client/editor.lua',
    'client/main.lua',
    'client/workshop.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/logs.lua',
    'server/security.lua',
    'server/permissions.lua',
    'server/profiles.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/logo.webp',
    'web/dist/assets/*',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'jj-framework',
}
