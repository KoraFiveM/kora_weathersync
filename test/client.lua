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
local events, threads = {}, {}
function AddEventHandler(name, handler) events[name] = handler end
function exports() end
function CreateThread(fn) threads[#threads + 1] = fn end
function Wait(ms) coroutine.yield(ms) end
function GetCurrentResourceName() return 'kora_weathersync' end
local clockCleared, rainLevels = 0, {}
function NetworkClearClockTimeOverride() clockCleared = clockCleared + 1 end
function TriggerServerEvent(name) if name == 'qb-weathersync:server:RequestStateSync' then requested = requested + 1 end end
function NetworkOverrideClockTime(h, m) clock = { h, m } end
function SetWeatherTypeNow(w) weatherNow[#weatherNow + 1] = w end
function SetWeatherTypeOverTime(w) weatherNow[#weatherNow + 1] = 'blend:' .. w end
for _, name in ipairs({ 'SetRainLevel', 'SetSnowLevel', 'SetGravityLevel', 'SetForceVehicleTrails', 'SetForcePedFootstepsTracks',
    'SetArtificialLightsState', 'SetArtificialLightsStateAffectsVehicles', 'ClearOverrideWeather', 'ClearWeatherTypePersist',
    'SetWeatherTypePersist', 'SetWeatherTypeNowPersist' }) do _G[name] = function() end end
function SetRainLevel(level) rainLevels[#rainLevels + 1] = level end

-- Same contract as kora_lib's Kora.util (clamp asserts on non-finite input).
local function finite(v) return type(v) == 'number' and v == v and v > -math.huge and v < math.huge end
Kora = { util = { isFiniteNumber = finite, clamp = function(v, lo, hi)
    assert(finite(v) and finite(lo) and finite(hi) and lo <= hi, 'Kora.util.clamp requires finite bounds')
    return math.max(lo, math.min(hi, v))
end } }
dofile('config.lua')
-- A non-finite level must be rejected once at load, not assert in a thread (F#271).
Config.weatherEffects.TESTNAN = { rainLevel = 0 / 0, snowLevel = 5, gravityLevel = 'x' }
Config.weatherEffects.TESTWET = { rainLevel = 0.7 }
local loadOk, loadErr = pcall(dofile, 'client/main.lua')

local function publish(weather, revision)
    stateBag(nil, nil, { weather = weather, hour = 8, minute = 0, blackout = false, revision = revision })
end

test('invalid weather effects are validated once at load (F#271)', function()
    if not loadOk then error(loadErr) end
end)

publish('CLEAR', 1)

test('non-finite effect levels fall back instead of erroring (F#271)', function()
    rainLevels = {}
    publish('TESTNAN', 10)
    equal(rainLevels[1], 0.0, 'NaN rain falls back to 0')
    publish('TESTWET', 11)
    equal(rainLevels[2], 0.7, 'valid rain is applied')
end)

test('the 1 s clock loop only re-applies the clock, not weather levels (F#268)', function()
    local clockThread = coroutine.create(threads[1])
    rainLevels, clock = {}, {}
    for _ = 1, 5 do assert(coroutine.resume(clockThread)) end
    equal(#rainLevels, 0, 'levels are not re-applied each second')
    equal(clock[1], 8, 'the clock override is still re-applied')
end)

test('stopping the resource clears the clock override (F#270)', function()
    events.onClientResourceStop('other')
    equal(clockCleared, 0, 'other resources are ignored')
    events.onClientResourceStop('kora_weathersync')
    equal(clockCleared, 1, 'the clock is released')
end)


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
