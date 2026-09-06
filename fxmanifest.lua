fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-weathersync'
author 'qbcore2'
version '1.0.0'
description 'Server-authoritative weather, clock, blackout, and environmental-level sync'

dependency 'qblib'

shared_script '@qblib/init.lua'
shared_script 'config.lua'

server_scripts {
    'server/state.lua',
    'server/commands.lua'
}

client_script 'client/main.lua'
