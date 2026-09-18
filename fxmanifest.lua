fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fivem-strict-rp'
author 'UseAI Instant'
description 'نظام سيرفر RP مشدد — كل الأنظمة + تطبيقات الجوال (أبشر · ناجز · مدى · مزادي · أطلبني).'
version '3.0.0'

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
    'config/install.lua',
    'config/tuning.lua',
    'config/paths.lua',
    'config/assistant.lua',
    'config/families.lua',
    'config/banks.lua',
    'config/emergency.lua',
    'config/oil.lua',
    'config/hunting.lua',
    'config/livestock.lua',
    'config/farm2.lua',
    'config/carpenter.lua',
    'config/legal.lua',
    'config/stalls.lua',
    'config/phone.lua',
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
    'client/install.lua',
    'client/tuning.lua',
    'client/paths.lua',
    'client/assistant.lua',
    'client/families.lua',
    'client/banks.lua',
    'client/emergency.lua',
    'client/oil.lua',
    'client/hunting.lua',
    'client/livestock.lua',
    'client/farm2.lua',
    'client/carpenter.lua',
    'client/legal.lua',
    'client/stalls.lua',
    'client/phone.lua',
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
    'server/install.lua',
    'server/tuning.lua',
    'server/paths.lua',
    'server/assistant.lua',
    'server/families.lua',
    'server/banks.lua',
    'server/emergency.lua',
    'server/oil.lua',
    'server/hunting.lua',
    'server/livestock.lua',
    'server/farm2.lua',
    'server/carpenter.lua',
    'server/legal.lua',
    'server/stalls.lua',
    'server/phone.lua',
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
