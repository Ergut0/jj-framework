fx_version 'cerulean'
game 'gta5'

name "jj_entornozones"
description "Sistemas de zonas de entorno"
author "Josete & Jesus"
version "1.0.0"
lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

ui_page 'web/dist/index.html'

files {
	'web/dist/index.html',
	'web/dist/logo.webp',
	'web/dist/assets/*',
}

dependencies {
	'ox_lib',
	'oxmysql',
	'jj-framework',
	'fivem-freecam',
}
