fx_version 'cerulean'
game 'gta5'

author 'Josete & Jesus'
description 'Cola de entrada, prioridad y whitelist por Discord'
version '2.0.0'

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua',
    'server/logs.lua'
}

dependencies {
    'oxmysql'
}
