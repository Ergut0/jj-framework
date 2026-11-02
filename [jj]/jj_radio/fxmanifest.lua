fx_version 'cerulean'
game 'gta5'

author 'Josete & jesus'
description 'Radio para civiles'
version '1.0.0'

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
    '@oxmysql/lib/MySQL.lua',
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
    'oxmysql',
    'pma-voice'
}
