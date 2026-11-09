fx_version 'cerulean'
game 'gta5'

provide 'qb-weathersync'
lua54 'yes'

name 'kora_weathersync'
author 'qbcore2'
version '1.0.0'
description 'Server-authoritative weather, clock, blackout, and environmental-level sync'

dependency 'kora_lib'

shared_script '@kora_lib/init.lua'
shared_script 'config.lua'

server_scripts {
    'server/state.lua',
    'server/commands.lua'
}

client_script 'client/main.lua'

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
