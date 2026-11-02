fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj-framework'
description 'Framework base para servidores de FiveM'
version '0.4.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'spawnmanager'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/es.lua',
    'shared/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/storage.lua',
    'server/player.lua',
    'server/callbacks.lua',
    'server/main.lua',
    'server/cp.lua',
    'server/commands.lua'
}

client_scripts {
    'client/callbacks.lua',
    'client/main.lua'
}
