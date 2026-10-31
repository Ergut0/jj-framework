fx_version 'cerulean'
game 'gta5'

name "jj_keysystem"
description "Sistema de ganzuado y llaves de los vehiculos"
author "jj#8142"
version "1.0.0"
lua54 'yes'

dependencies {
	'oxmysql',
	'ox_lib',
	'jj-framework',
	'ox_inventory',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}
