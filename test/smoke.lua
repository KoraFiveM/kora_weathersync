local passed, failed = 0, 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print(('  [PASS] %s'):format(name))
    else
        failed = failed + 1
        print(('  [FAIL] %s -- %s'):format(name, tostring(err)))
    end
end

local function equal(actual, expected, message)
    if actual ~= expected then error(('%s (expected %s, got %s)'):format(message, tostring(expected), tostring(actual)), 2) end
end

Config = nil
WeatherSync = nil
GlobalState = {}
local registeredExports, commands = {}, {}

function exports(name, fn) registeredExports[name] = fn end
local now = 1000
function GetGameTimer() return now end
function Wait() end
function CreateThread() end
local events = {}
function AddEventHandler(name, handler) events[name] = handler end
local netHandlers, sent = {}, {}
function RegisterNetEvent(name, handler) netHandlers[name] = handler end
function TriggerClientEvent(name, target, ...) sent[#sent + 1] = { name = name, target = target, args = { ... } } end
function GetCurrentResourceName() return 'kora_weathersync' end

Kora = {
    commands = { add = function(name, _, _, _, handler) commands[name] = handler end },
    permissions = { hasLevel = function() return true end },
    notify = { send = function() end },
}

Kora.compat = dofile('../kora_lib/compat/provider.lua')()
dofile('config.lua')
dofile('server/state.lua')
dofile('server/commands.lua')

test('starts with a replicated world snapshot', function()
    equal(GlobalState.kora_weathersync.weather, Config.startingWeather, 'starting weather')
    equal(GlobalState.kora_weathersync.hour, Config.startingTime.hour, 'starting hour')
    equal(GlobalState.kora_weathersync.revision, 1, 'initial publish revision')
end)

test('weather is normalized and invalid values are rejected', function()
    local ok = registeredExports.setWeather('rain')
    equal(ok, true, 'rain is accepted')
    equal(registeredExports.getWeather(), 'RAIN', 'weather is upper-cased')
    local bad, err = registeredExports.setWeather('acid')
    equal(bad, false, 'unknown weather is rejected')
    equal(type(err), 'string', 'rejection describes the problem')
end)

test('time accepts only whole clock values', function()
    local ok = registeredExports.setTime(23, 59)
    equal(ok, true, 'valid clock accepted')
    local hour, minute = registeredExports.getTime()
    equal(hour, 23, 'stored hour')
    equal(minute, 59, 'stored minute')
    local bad = registeredExports.setTime(24, 0)
    equal(bad, false, 'out-of-range hour rejected')
    bad = registeredExports.setTime(12.5, 0)
    equal(bad, false, 'fractional hour rejected')
end)

test('freeze and blackout exports support both setting and toggling', function()
    equal(registeredExports.setTimeFrozen(true), true, 'time freezes')
    equal(registeredExports.setTimeFrozen(), false, 'time toggle unfreezes')
    equal(registeredExports.setBlackout(true), true, 'blackout enabled')
    equal(registeredExports.getBlackout(), true, 'blackout persisted')
end)

test('world commands are registered by the sync resource', function()
    equal(type(commands.weather), 'function', 'weather command')
    equal(type(commands.time), 'function', 'time command')
    equal(type(commands.blackout), 'function', 'blackout command')
end)

test('the time command accepts configured presets for kora_admin menu compatibility', function()
    commands.time(7, { 'morning' })
    local hour, minute = registeredExports.getTime()
    equal(hour, Config.timePresets.morning.hour, 'preset hour')
    equal(minute, Config.timePresets.morning.minute, 'preset minute')
end)

test('legacy blackout export publishes through the same authoritative setter', function()
    local legacy
    events['__cfx_export_qb-weathersync_setBlackout'](function(fn) legacy = fn end)
    equal(legacy, registeredExports.setBlackout, 'same handler')
    local previous = GlobalState.kora_weathersync
    equal(legacy(false), false, 'disable result')
    equal(GlobalState.kora_weathersync.blackout, false, 'replicated off')
    equal(GlobalState.kora_weathersync.revision, previous.revision + 1, 'publishes fresh revision')
    equal(legacy(), true, 'toggle result')
    equal(GlobalState.kora_weathersync.blackout, true, 'replicated on')
end)

local function legacyExport(name)
    local fn
    events['__cfx_export_qb-weathersync_' .. name](function(f) fn = f end)
    return fn
end

test('every stock qb-weathersync export is provided', function()
    for _, name in ipairs({ 'nextWeatherStage', 'setWeather', 'setTime', 'setBlackout', 'setTimeFreeze',
        'setDynamicWeather', 'getBlackoutState', 'getTimeFreezeState', 'getWeatherState', 'getDynamicWeather', 'getTime' }) do
        equal(type(legacyExport(name)), 'function', name)
    end
end)

test('legacy exports keep stock return shapes', function()
    equal(legacyExport('setWeather')('clear'), true, 'setWeather success')
    equal(legacyExport('getWeatherState')(), 'CLEAR', 'upper-case weather')
    equal(legacyExport('setWeather')('acid'), false, 'invalid weather')
    equal(legacyExport('setTime')('13', '30'), true, 'string time accepted')
    local hour, minute = legacyExport('getTime')()
    equal(hour * 100 + minute, 1330, 'time')
    equal(legacyExport('setTime')(24), true, 'hour 24 wraps')
    equal(legacyExport('getTime')(), 0, 'hour 24 is midnight')
    equal(legacyExport('setTime')(25), false, 'hour above 24 rejected')
    equal(legacyExport('setTime')('x'), false, 'non numeric rejected')
    equal(legacyExport('setTimeFreeze')(true), true, 'freeze')
    equal(legacyExport('getTimeFreezeState')(), true, 'freeze state')
    equal(legacyExport('setDynamicWeather')(false), false, 'dynamic off')
    equal(legacyExport('getDynamicWeather')(), false, 'dynamic state')
    equal(legacyExport('setBlackout')(true), true, 'blackout')
    equal(legacyExport('getBlackoutState')(), true, 'blackout state')
end)

test('legacy world-changing events ignore client sources', function()
    source = 5
    netHandlers['qb-weathersync:server:setWeather']('RAIN')
    netHandlers['qb-weathersync:server:setTime'](3, 0)
    netHandlers['qb-weathersync:server:toggleBlackout'](false)
    netHandlers['qb-weathersync:server:toggleFreezeTime'](false)
    netHandlers['qb-weathersync:server:toggleDynamicWeather'](true)
    equal(registeredExports.getWeather(), 'CLEAR', 'weather untouched')
    equal(registeredExports.getBlackout(), true, 'blackout untouched')
    equal(registeredExports.getTimeFrozen(), true, 'freeze untouched')
    equal(registeredExports.getDynamicWeather(), false, 'dynamic untouched')
    source = ''
    netHandlers['qb-weathersync:server:setWeather']('RAIN')
    netHandlers['qb-weathersync:server:toggleBlackout'](false)
    equal(registeredExports.getWeather(), 'RAIN', 'server origin applies')
    equal(registeredExports.getBlackout(), false, 'server origin toggles')
    source = nil
end)

test('RequestStateSync replies to the caller and is rate limited', function()
    sent = {}
    source = 7
    netHandlers['qb-weathersync:server:RequestStateSync']()
    netHandlers['qb-weathersync:server:RequestStateSync']()
    equal(#sent, 1, 'second request inside cooldown dropped')
    equal(sent[1].target, 7, 'reply targets caller')
    now = now + 3000
    netHandlers['qb-weathersync:server:RequestStateSync']()
    equal(#sent, 2, 'allowed after cooldown')
    source = ''
    netHandlers['qb-weathersync:server:RequestStateSync']()
    equal(sent[3].target, -1, 'server origin broadcasts')
    source = nil
end)

print(('-- %d passed, %d failed --'):format(passed, failed))
if failed > 0 then os.exit(1) end
