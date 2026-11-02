fx_version 'cerulean'
game 'gta5'

author 'Josete & jesus'
description 'Radio y acciones de banda'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
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
    'jj-framework',
    'ox_lib',
    'ox_inventory',
    'pma-voice',
    'jj_gangs',
    'jj_things',
    'jj_policejob'
}
