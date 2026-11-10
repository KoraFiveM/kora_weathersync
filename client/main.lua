local currentState
local transitionRevision = -1
local syncSuspended = false

-- Effect levels are validated once at load (F#271), so the per-state apply path
-- never asserts and never allocates. A non-numeric or non-finite value falls
-- back to the default with one warning instead of erroring inside a thread.
local function level(weatherType, key, value, minimum, maximum, fallback)
    if value == nil then return fallback end
    value = tonumber(value)
    if not Kora.util.isFiniteNumber(value) then
        print(('^3[kora_weathersync] Config.weatherEffects.%s.%s must be a finite number; using %s.^7')
            :format(weatherType, key, fallback))
        return fallback
    end
    return Kora.util.clamp(value, minimum, maximum)
end

local defaultEffects = { rainLevel = 0.0, snowLevel = 0.0, gravityLevel = 0, snowTrails = false }
local effectsByWeather = {}
for weatherType, configured in pairs(Config.weatherEffects or {}) do
    effectsByWeather[weatherType] = {
        rainLevel = level(weatherType, 'rainLevel', configured.rainLevel, 0.0, 1.0, 0.0),
        snowLevel = level(weatherType, 'snowLevel', configured.snowLevel, 0.0, 1.0, 0.0),
        gravityLevel = math.floor(level(weatherType, 'gravityLevel', configured.gravityLevel, 0, 3, 0)),
        snowTrails = configured.snowTrails == true,
    }
end

local function effectsFor(weatherType)
    return effectsByWeather[weatherType] or defaultEffects
end

local function applyLevels(state)
    local effects = effectsFor(state.weather)
    SetRainLevel(effects.rainLevel)
    SetSnowLevel(effects.snowLevel)
    SetGravityLevel(effects.gravityLevel)
    SetForceVehicleTrails(effects.snowTrails)
    SetForcePedFootstepsTracks(effects.snowTrails)
    SetArtificialLightsState(state.blackout == true)
    SetArtificialLightsStateAffectsVehicles(state.blackout == true and state.blackoutAffectsVehicles == true)
end

local function persistWeather(weatherType)
    CreateThread(function()
        Wait(math.floor(Config.weatherTransitionSeconds * 1000))
        -- Clock and blackout updates advance the state revision too.  The
        -- transition is still current as long as the weather itself did not
        -- change while its blend timer was running.
        if currentState and not syncSuspended and currentState.weather == weatherType then
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(weatherType)
            SetWeatherTypeNow(weatherType)
            SetWeatherTypeNowPersist(weatherType)
            applyLevels(currentState)
        end
    end)
end

local function applyState(state, blendWeather)
    if type(state) ~= 'table' or type(state.weather) ~= 'string' then return end

    local previousState = currentState
    currentState = state
    if syncSuspended then return end
    applyLevels(state)

    if previousState == nil then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(state.weather)
        SetWeatherTypeNow(state.weather)
        SetWeatherTypeNowPersist(state.weather)
    elseif blendWeather and previousState.weather ~= state.weather and state.revision ~= transitionRevision then
        transitionRevision = state.revision
        SetWeatherTypeOverTime(state.weather, Config.weatherTransitionSeconds)
        persistWeather(state.weather)
    end
end

AddStateBagChangeHandler('kora_weathersync', nil, function(_, _, value)
    if value == nil then return end
    applyState(value, currentState ~= nil)
end)

RegisterNetEvent('kora_weathersync:client:state', function(state)
    applyState(state, currentState ~= nil)
end)

RegisterNetEvent('qb-weathersync:client:DisableSync', function()
    syncSuspended = true
    SetRainLevel(0.0)
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    NetworkOverrideClockTime(18, 0, 0)
end)

RegisterNetEvent('qb-weathersync:client:EnableSync', function()
    syncSuspended = false
    local state = currentState
    currentState = nil
    if state then applyState(state, false) end
    TriggerServerEvent('qb-weathersync:server:RequestStateSync')
end)

local function copyOf(state)
    local copy = {}
    for key, value in pairs(state) do copy[key] = value end
    return copy
end

RegisterNetEvent('qb-weathersync:client:SyncTime', function(base, offset)
    base, offset = tonumber(base), tonumber(offset)
    if not currentState or not base or not offset then return end
    local total = base + offset
    if total ~= total or total == math.huge or total == -math.huge then return end
    local state = copyOf(currentState)
    state.hour = math.floor((total / 60) % 24)
    state.minute = math.floor(total % 60)
    currentState = state
end)

RegisterNetEvent('qb-weathersync:client:SyncWeather', function(weatherType, blackout)
    if not currentState or type(weatherType) ~= 'string' then return end
    weatherType = weatherType:upper()
    local known = false
    for _, configured in ipairs(Config.weatherTypes) do
        if configured == weatherType then known = true break end
    end
    if not known then return end
    local state = copyOf(currentState)
    state.weather = weatherType
    if blackout ~= nil then state.blackout = blackout == true end
    transitionRevision = -1
    applyState(state, true)
end)

-- kora_admin reads this at menu-open time.  Exporting the source list keeps its
-- selector aligned with this resource's config (including snow-only/event
-- weather) without making kora_admin start-order dependent on this resource.
exports('getWeatherTypes', function()
    return Config.weatherTypes
end)

CreateThread(function()
    while currentState == nil do
        local state = GlobalState.kora_weathersync
        if state then applyState(state, false) end
        Wait(1000)
    end

    -- NetworkOverrideClockTime is an override rather than a running clock.
    -- Reapplying it once a second keeps every client aligned between server
    -- minute updates, including after a player briefly loses scope. Weather
    -- levels only change with the state, so applyState sets them (F#268).
    while true do
        if not syncSuspended then
            NetworkOverrideClockTime(currentState.hour, currentState.minute, 0)
        end
        Wait(1000)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    NetworkClearClockTimeOverride()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetRainLevel(0.0)
    SetSnowLevel(0.0)
    SetGravityLevel(0)
    SetForceVehicleTrails(false)
    SetForcePedFootstepsTracks(false)
    SetArtificialLightsState(false)
    SetArtificialLightsStateAffectsVehicles(false)
end)
