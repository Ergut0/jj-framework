fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jj_announce'
author 'Jesusfriasv01'
description 'Sistema de anuncios con banners animados, tipos y permisos'
version '1.0.0'

dependency 'jj-framework'

shared_script 'config.lua'
server_script 'server.lua'
client_script 'client.lua'

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/script.js' }
