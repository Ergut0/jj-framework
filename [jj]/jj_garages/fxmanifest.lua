fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'josete'
version '2.0.0'

dependencies {
    'oxmysql',
    'ox_lib',
    'jj-framework',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/es.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
