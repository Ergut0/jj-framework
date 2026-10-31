fx_version 'cerulean'
game 'gta5'

name "jj_paymethods"
description "Sistema de facturas y pagos"
author "josete & jesus"
version "1.0.0"
lua54 'yes'

dependencies {
	'ox_lib',
	'jj-framework',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}
