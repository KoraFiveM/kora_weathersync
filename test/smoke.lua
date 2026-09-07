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
function GetGameTimer() return 1000 end
function Wait() end
function CreateThread() end
function AddEventHandler() end
function RegisterNetEvent() end
function TriggerClientEvent() end
function GetCurrentResourceName() return 'qbweathersync' end

QB = {
    commands = { add = function(name, _, _, _, handler) commands[name] = handler end },
    permissions = { hasLevel = function() return true end },
    notify = { send = function() end },
}

dofile('config.lua')
dofile('server/state.lua')
dofile('server/commands.lua')

test('starts with a replicated world snapshot', function()
    equal(GlobalState.qbweathersync.weather, Config.startingWeather, 'starting weather')
    equal(GlobalState.qbweathersync.hour, Config.startingTime.hour, 'starting hour')
    equal(GlobalState.qbweathersync.revision, 1, 'initial publish revision')
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

test('the time command accepts configured presets for qbadmin menu compatibility', function()
    commands.time(7, { 'morning' })
    local hour, minute = registeredExports.getTime()
    equal(hour, Config.timePresets.morning.hour, 'preset hour')
    equal(minute, Config.timePresets.morning.minute, 'preset minute')
end)

print(('-- %d passed, %d failed --'):format(passed, failed))
if failed > 0 then os.exit(1) end
