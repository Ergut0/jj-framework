fx_version 'cerulean'
game 'gta5'
author 'Josete & Jesus'
description 'Sistema de tuneos para vehiculos'
version '2.0.0'
lua54 'yes'

dependencies {
        'oxmysql',
        'ox_lib',
        'jj-framework',
}

ui_page 'client/ui/index.html'

files {
        'client/ui/index.html',
        'client/ui/js/**/*.js',
        'client/ui/css/**/*.css',
        'client/ui/img/**/*.png',
        'client/ui/sounds/**/*.ogg'
}

shared_scripts {
        '@ox_lib/init.lua',
        'config/*.lua',
}

client_scripts {
        'client/*.lua',
        'config/tuneos_config/*.lua',
}

server_scripts {
        '@oxmysql/lib/MySQL.lua',
        'server/*.lua',
}
