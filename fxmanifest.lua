fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fivem-strict-rp'
author 'UseAI Instant'
description 'نظام سيرفر RP مشدد — عقوبات تلقائية، اقتصاد واقعي، احتياجات، قوانين.'
version '0.2.0'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/penalties.lua',
    'config/economy.lua',
}

client_scripts {
    'client/penalties.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/penalties.lua',
    'server/economy.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

dependencies {
    'qb-core',
    'oxmysql',
}
