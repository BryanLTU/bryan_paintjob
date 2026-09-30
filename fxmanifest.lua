fx_version 'cerulean'
game 'gta5'

author 'BryaN'
description 'Paint job locations with a realistic paint changing effect'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'bridge/init.lua',
}

client_scripts {
    'bridge/client/*.lua',
    'client/utils.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
}
