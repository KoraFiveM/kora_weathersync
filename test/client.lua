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

local handlers, clock, weatherNow, requested = {}, {}, {}, 0
local stateBag
GlobalState = {}
function RegisterNetEvent(name, handler) handlers[name] = handler end
function AddStateBagChangeHandler(_, _, handler) stateBag = handler end
function AddEventHandler() end
function exports() end
function CreateThread() end
function Wait() end
function TriggerServerEvent(name) if name == 'qb-weathersync:server:RequestStateSync' then requested = requested + 1 end end
function NetworkOverrideClockTime(h, m) clock = { h, m } end
function SetWeatherTypeNow(w) weatherNow[#weatherNow + 1] = w end
function SetWeatherTypeOverTime(w) weatherNow[#weatherNow + 1] = 'blend:' .. w end
for _, name in ipairs({ 'SetRainLevel', 'SetSnowLevel', 'SetGravityLevel', 'SetForceVehicleTrails', 'SetForcePedFootstepsTracks',
    'SetArtificialLightsState', 'SetArtificialLightsStateAffectsVehicles', 'ClearOverrideWeather', 'ClearWeatherTypePersist',
    'SetWeatherTypePersist', 'SetWeatherTypeNowPersist' }) do _G[name] = function() end end

dofile('config.lua')
dofile('client/main.lua')

local function publish(weather, revision)
    stateBag(nil, nil, { weather = weather, hour = 8, minute = 0, blackout = false, revision = revision })
end

publish('CLEAR', 1)

test('DisableSync suspends state application and EnableSync resumes and requests a resync', function()
    handlers['qb-weathersync:client:DisableSync']()
    equal(clock[1], 18, 'interior clock')
    weatherNow = {}
    publish('RAIN', 2)
    equal(#weatherNow, 0, 'no weather applied while suspended')
    handlers['qb-weathersync:client:EnableSync']()
    equal(weatherNow[#weatherNow], 'RAIN', 'latest state applied on enable')
    equal(requested, 1, 'resync requested')
end)

test('SyncTime accepts stock arguments and ignores malformed input', function()
    handlers['qb-weathersync:client:SyncTime'](600, 90, false)
    handlers['qb-weathersync:client:SyncTime']('bad', {}, false)
end)

test('SyncWeather validates the type and blends', function()
    weatherNow = {}
    handlers['qb-weathersync:client:SyncWeather']('acid', false)
    equal(#weatherNow, 0, 'unknown type ignored')
    handlers['qb-weathersync:client:SyncWeather']('clear', true)
    equal(weatherNow[1], 'blend:CLEAR', 'known type blends')
end)

print(('-- %d passed, %d failed --'):format(passed, failed))
if failed > 0 then os.exit(1) end
