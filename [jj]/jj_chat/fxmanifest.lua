fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_chat'
description 'Chat de rol'
author 'jj'
version '1.0.0'

-- Sustituye al recurso chat de FiveM
provide 'chat'

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
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}
