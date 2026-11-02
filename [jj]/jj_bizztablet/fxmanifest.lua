fx_version 'cerulean'
games { 'gta5' }
author 'Josete & jesus'
description 'Tablet de negocios y eventos de la ciudad'
version '2.0.0'

lua54 'yes'

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'jj-framework',
    'jj_creatorjobs',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/modules/nui/main.lua',
    'client/modules/tablet/main.lua',
    'client/modules/tablet/events.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/init.lua',
    'server/database.lua',
    'server/businesses.lua',
    'server/events.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
