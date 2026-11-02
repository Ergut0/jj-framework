fx_version 'cerulean'
game 'gta5'

name "jj_policedispatch"
description "Sistema de dispatch, radio y radar."
author "Josete & Jesus"
version "2.0.0"
lua54 "yes"

dependencies {
    'ox_lib',
    'jj-framework',
    'pma-voice',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/core.lua',
    'shared/main.lua',
    'shared/pursuit_config.lua',
}

client_scripts {
    'client/*.lua',
    'client/modules/*.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page "web/dist/index.html"

files {
    'shared/main.lua',
    'web/dist/**',
    'web/dist/assets/**',
}
