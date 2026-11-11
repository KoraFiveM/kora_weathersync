-- The state table is rebuilt for every publish.  GlobalState serializes values
-- by assignment, so mutating a nested table in place would not reliably reach
-- clients or late joiners.
WeatherSync = WeatherSync or {}

local validWeather = {}
for _, weatherType in ipairs(Config.weatherTypes) do validWeather[weatherType] = true end

local function copyState()
    return {
        weather = WeatherSync.state.weather,
        hour = WeatherSync.state.hour,
        minute = WeatherSync.state.minute,
        timeFrozen = WeatherSync.state.timeFrozen,
        dynamicWeather = WeatherSync.state.dynamicWeather,
        blackout = WeatherSync.state.blackout,
        blackoutAffectsVehicles = Config.blackoutAffectsVehicles,
        revision = WeatherSync.state.revision,
    }
end

function WeatherSync.publish()
    WeatherSync.state.revision = WeatherSync.state.revision + 1
    GlobalState.kora_weathersync = copyState()
end

local weatherTimer

---Arms one timeout for the next dynamic weather stage, replacing a 1 s poll
---(F#269). Called whenever nextWeatherAt or dynamicWeather changes.
local function scheduleWeather()
    if weatherTimer then Kora.timers.clearTimeout(weatherTimer); weatherTimer = nil end
    if not WeatherSync.state.dynamicWeather or WeatherSync.weatherInterval <= 0 then return end
    local delay = math.max(0, math.floor(WeatherSync.nextWeatherAt - GetGameTimer()))
    weatherTimer = Kora.timers.setTimeout(function()
        weatherTimer = nil
        WeatherSync.nextWeatherStage()
    end, delay)
end

local function validInteger(value, minimum, maximum)
    return type(value) == 'number' and value == math.floor(value) and value >= minimum and value <= maximum
end

local function validWeatherType(weatherType)
    return type(weatherType) == 'string' and validWeather[weatherType:upper()] == true
end

function WeatherSync.getState()
    return copyState()
end

---@param weatherType string
---@return boolean, string|nil
function WeatherSync.setWeather(weatherType)
    if not validWeatherType(weatherType) then
        return false, ('unknown weather type %q'):format(tostring(weatherType))
    end

    WeatherSync.state.weather = weatherType:upper()
    WeatherSync.nextWeatherAt = GetGameTimer() + WeatherSync.weatherInterval
    scheduleWeather()
    WeatherSync.publish()
    return true
end

---@param hour integer
---@param minute integer
---@return boolean, string|nil
function WeatherSync.setTime(hour, minute)
    if not validInteger(hour, 0, 23) or not validInteger(minute, 0, 59) then
        return false, 'hour must be 0-23 and minute must be 0-59'
    end

    WeatherSync.state.hour = hour
    WeatherSync.state.minute = minute
    WeatherSync.publish()
    return true
end

---@param enabled boolean|nil
---@return boolean
function WeatherSync.setTimeFrozen(enabled)
    if enabled == nil then enabled = not WeatherSync.state.timeFrozen end
    WeatherSync.state.timeFrozen = enabled == true
    WeatherSync.publish()
    return WeatherSync.state.timeFrozen
end

---@param enabled boolean|nil
---@return boolean
function WeatherSync.setDynamicWeather(enabled)
    if enabled == nil then enabled = not WeatherSync.state.dynamicWeather end
    WeatherSync.state.dynamicWeather = enabled == true
    WeatherSync.nextWeatherAt = GetGameTimer() + WeatherSync.weatherInterval
    scheduleWeather()
    WeatherSync.publish()
    return WeatherSync.state.dynamicWeather
end

---@param enabled boolean|nil
---@return boolean
function WeatherSync.setBlackout(enabled)
    if enabled == nil then enabled = not WeatherSync.state.blackout end
    WeatherSync.state.blackout = enabled == true
    WeatherSync.publish()
    return WeatherSync.state.blackout
end

---@return boolean, string|nil
function WeatherSync.nextWeatherStage()
    local stages = Config.weatherTransitions[WeatherSync.state.weather]
    local nextWeather = stages and stages[math.random(#stages)] or 'CLEAR'
    return WeatherSync.setWeather(nextWeather)
end

local startingTime = Config.startingTime or {}
assert(validWeatherType(Config.startingWeather), 'Config.startingWeather must be a configured weather type.')
assert(validInteger(startingTime.hour, 0, 23), 'Config.startingTime.hour must be an integer from 0 to 23.')
assert(validInteger(startingTime.minute, 0, 59), 'Config.startingTime.minute must be an integer from 0 to 59.')
assert(type(Config.realSecondsPerGameMinute) == 'number' and Config.realSecondsPerGameMinute > 0,
    'Config.realSecondsPerGameMinute must be greater than zero.')

WeatherSync.weatherInterval = math.max(0, math.floor((Config.weatherChangeEveryMinutes or 0) * 60000))
WeatherSync.state = {
    weather = Config.startingWeather:upper(),
    hour = startingTime.hour,
    minute = startingTime.minute,
    timeFrozen = Config.freezeTime == true,
    dynamicWeather = Config.dynamicWeather == true and WeatherSync.weatherInterval > 0,
    blackout = Config.blackout == true,
    revision = 0,
}
WeatherSync.nextWeatherAt = GetGameTimer() + WeatherSync.weatherInterval
scheduleWeather()
WeatherSync.publish()

exports('setWeather', WeatherSync.setWeather)
exports('getWeather', function() return WeatherSync.state.weather end)
exports('setTime', WeatherSync.setTime)
exports('getTime', function() return WeatherSync.state.hour, WeatherSync.state.minute end)
exports('setTimeFrozen', WeatherSync.setTimeFrozen)
exports('getTimeFrozen', function() return WeatherSync.state.timeFrozen end)
exports('setDynamicWeather', WeatherSync.setDynamicWeather)
exports('getDynamicWeather', function() return WeatherSync.state.dynamicWeather end)
exports('setBlackout', WeatherSync.setBlackout)
exports('getBlackout', function() return WeatherSync.state.blackout end)
exports('nextWeatherStage', WeatherSync.nextWeatherStage)
exports('getState', WeatherSync.getState)

local function legacyTime(hour, minute)
    local legacyHour, legacyMinute = tonumber(hour), tonumber(minute) or 0
    if not legacyHour or legacyHour < 0 or legacyHour > 24 then return false end
    legacyHour, legacyMinute = math.floor(legacyHour), math.floor(legacyMinute)
    if legacyMinute < 0 then return false end
    return WeatherSync.setTime(legacyHour < 24 and legacyHour or 0, legacyMinute < 60 and legacyMinute or 0)
end

local legacyExports = {
    nextWeatherStage = WeatherSync.nextWeatherStage,
    setWeather = function(weatherType) return (WeatherSync.setWeather(weatherType)) end,
    setTime = function(hour, minute) return (legacyTime(hour, minute)) end,
    setBlackout = WeatherSync.setBlackout,
    setTimeFreeze = WeatherSync.setTimeFrozen,
    setDynamicWeather = WeatherSync.setDynamicWeather,
    getBlackoutState = function() return WeatherSync.state.blackout end,
    getTimeFreezeState = function() return WeatherSync.state.timeFrozen end,
    getWeatherState = function() return WeatherSync.state.weather end,
    getDynamicWeather = function() return WeatherSync.state.dynamicWeather end,
    getTime = function() return WeatherSync.state.hour, WeatherSync.state.minute end,
}
for name, handler in pairs(legacyExports) do
    Kora.compat.provideExport('qb-weathersync', name, handler)
end

local function originOf(value)
    return tonumber(value) or 0
end

local function serverOnly(name, handler)
    RegisterNetEvent(name, function(...)
        if originOf(source) > 0 then return end
        handler(...)
    end)
end

serverOnly('kora_weathersync:server:setWeather', WeatherSync.setWeather)
serverOnly('kora_weathersync:server:setTime', WeatherSync.setTime)
serverOnly('qb-weathersync:server:setWeather', legacyExports.setWeather)
serverOnly('qb-weathersync:server:setTime', legacyExports.setTime)
serverOnly('qb-weathersync:server:toggleBlackout', WeatherSync.setBlackout)
serverOnly('qb-weathersync:server:toggleFreezeTime', WeatherSync.setTimeFrozen)
serverOnly('qb-weathersync:server:toggleDynamicWeather', WeatherSync.setDynamicWeather)

local syncCooldownMs = 2000
local lastSyncRequest = {}

local function requestStateSync()
    local player = originOf(source)
    if player <= 0 then
        TriggerClientEvent('kora_weathersync:client:state', -1, WeatherSync.getState())
        return
    end
    local now = GetGameTimer()
    if lastSyncRequest[player] and now - lastSyncRequest[player] < syncCooldownMs then return end
    lastSyncRequest[player] = now
    TriggerClientEvent('kora_weathersync:client:state', player, WeatherSync.getState())
end

RegisterNetEvent('kora_weathersync:server:requestStateSync', requestStateSync)
RegisterNetEvent('qb-weathersync:server:RequestStateSync', requestStateSync)

AddEventHandler('playerDropped', function()
    lastSyncRequest[originOf(source)] = nil
end)

CreateThread(function()
    local tickMilliseconds = math.floor(Config.realSecondsPerGameMinute * 1000)
    while true do
        Wait(tickMilliseconds)
        if not WeatherSync.state.timeFrozen then
            WeatherSync.state.minute = WeatherSync.state.minute + 1
            if WeatherSync.state.minute >= 60 then
                WeatherSync.state.minute = 0
                WeatherSync.state.hour = (WeatherSync.state.hour + 1) % 24
            end
            WeatherSync.publish()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    GlobalState.kora_weathersync = nil
end)
