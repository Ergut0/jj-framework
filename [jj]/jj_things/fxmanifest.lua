fx_version 'cerulean'
game 'gta5'

name "jj_things"
description "Pequeños recursos de fivem"
author "josete & jesus"
version "1.0.0"
lua54 'yes'

dependencies {
	'ox_lib',
	'jj-framework',
	'ox_inventory',
	'ox_target',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
	'shared/core/*.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}
