fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fivem-strict-rp'
author 'UseAI Instant'
description 'نظام سيرفر RP مشدد — عقوبات، اقتصاد، احتياجات، قوانين، وظائف، معارض، ميكانيك، أعمال، مزارع، أراضي، سلسلة توريد، تابلت.'
version '1.5.0'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/penalties.lua',
    'config/economy.lua',
    'config/needs.lua',
    'config/rules.lua',
    'config/jobs.lua',
    'config/dealerships.lua',
    'config/businesses.lua',
    'config/land.lua',
    'config/supply.lua',
}

client_scripts {
    'client/penalties.lua',
    'client/needs.lua',
    'client/jobs.lua',
    'client/dealerships.lua',
    'client/mechanic.lua',
    'client/businesses.lua',
    'client/farms.lua',
    'client/land.lua',
    'client/supply.lua',
    'client/tablet.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/penalties.lua',
    'server/economy.lua',
    'server/needs.lua',
    'server/rules.lua',
    'server/jobs.lua',
    'server/dealerships.lua',
    'server/mechanic.lua',
    'server/businesses.lua',
    'server/farms.lua',
    'server/land.lua',
    'server/land_admin.lua',
    'server/supply.lua',
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
