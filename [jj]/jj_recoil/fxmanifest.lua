fx_version 'cerulean'
game 'gta5'

name "jj_recoil"
description "Sistema de recoil"
author "Josete & Jesus"
version "1.0.0"
lua54 'yes'

dependencies {
	'ox_lib',
	'ox_inventory',
	'jj-framework',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
