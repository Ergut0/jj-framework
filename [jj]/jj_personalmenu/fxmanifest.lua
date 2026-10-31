fx_version 'adamant'
games { 'gta5' }
lua54 'yes'

dependencies {
    'ox_lib',
    'jj-framework',
    'ox_inventory',
    'jj_things',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
    'freecam/*.lua',
}

server_scripts {
    'server/*.lua',
}
