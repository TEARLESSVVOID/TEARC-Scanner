fx_version 'cerulean'
game 'gta5'

author 'TEARC Development'
description 'TEARC-Scanner - 独立FiveM警用无线电扫描器插件'
version '1.0.0'

client_scripts {
    'config.lua',
    'client/cl_notify.lua',
    'client/cl_audio.lua',
    'client/cl_version.lua',
    'client/cl_scanner.lua',
    'client/cl_sync.lua',
    'client/cl_menu.lua',
    'client/cl_main.lua',
}

server_scripts {
    'config.lua',
    'server/sv_main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'audio/scanner/*.wav',
    'audio/alerts/*.wav',
    'audio/backup/transport/*.wav',
    'audio/backup/coroner/*.wav',
    'audio/backup/animal/*.wav',
    'audio/backup/supervisor/*.wav',
}