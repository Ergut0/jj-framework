fx_version 'adamant'
games { 'gta5' }
description 'Sistema de gym'
author 'josete & jesus'
version '1.0.0'
lua54 "yes"

dependencies {
  'oxmysql',
  'ox_lib',
  'jj-framework',
  'ox_inventory',
  'jj_paymethods',
}

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
  'shared/*.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua',
}

client_scripts {
  'client/*.lua',
}
