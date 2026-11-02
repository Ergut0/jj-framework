fx_version 'cerulean'
game 'gta5'

name "jj_policejob"
description "Sistema de trabajo de policía"
author "Josete & Jesus"
version "2.0.0"
lua54 'yes'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'jj-framework',
    'jj_things',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/core.lua',
}

client_scripts {
    'client/main.lua',
    'client/locations.lua',
    'client/props.lua',
    'client/interactions/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'client/functions.lua',
    'client/points.lua',
}
