fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_creatorjobs'
description 'Creador de trabajos'
author 'josete & jesus'
version '2.0.0'

dependencies {
  'oxmysql',
  'ox_lib',
  'ox_inventory',
  'jj-framework',
}

shared_scripts {
  '@ox_lib/init.lua',
  'shared/core.lua',
  'shared/cfg.lua',
}

client_scripts {
  'client/Modules/Functions.lua',
  'client/Modules/Nui.lua',
  'client/client.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/Classes/*.lua',
  'server/logs.lua',
  'server/Modules/Functions.lua',
  'server/Modules/Database.lua',
  'server/Modules/Callbacks.lua',
  'server/Modules/Events.lua',
  'server/server.lua',
}

ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/**/*',
}
