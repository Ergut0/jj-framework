fx_version 'cerulean'
game 'gta5'

author 'Josete & jesus'
description 'Sustos para administradores'
version '2.0.0'

lua54 'yes'

shared_scripts {
    'shared/core.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**',
    'web/dist/assets/**'
}

dependencies {
    'jj-framework'
}
