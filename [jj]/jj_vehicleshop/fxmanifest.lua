name "jj_vehicleshop"
description "Sistemas de concessionario"
author "josete & jesus"
version "1.0.0"

fx_version "cerulean"
games { "gta5" }
lua54 'yes'
ui_page 'web/dist/index.html'

dependencies {
  'oxmysql',
  'ox_lib',
  'jj-framework',
  'jj_garages',
  'jj_paymethods',
}

shared_scripts {
  '@ox_lib/init.lua',
  "config/*.lua",
  "categories/*.lua",
}

client_scripts {
  "client/*.lua",
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  "server/*.lua",
}

files {
  'web/dist/index.html',
  'web/dist/assets/*',
  'web/dist/vehicles/*',
}
