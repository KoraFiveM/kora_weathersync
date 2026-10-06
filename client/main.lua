local currentState
local transitionRevision = -1

local function numberInRange(value, minimum, maximum, fallback)
    value = tonumber(value)
    if not value then return fallback end
    assert(value == value and value ~= math.huge and value ~= -math.huge,
        'QB.util.clamp requires finite bounds where min is at most max.')
    return math.max(minimum, math.min(maximum, value))
end

local function effectsFor(weatherType)
    local configured = Config.weatherEffects[weatherType] or {}
    return {
        rainLevel = numberInRange(configured.rainLevel, 0.0, 1.0, 0.0),
        snowLevel = numberInRange(configured.snowLevel, 0.0, 1.0, 0.0),
        gravityLevel = math.floor(numberInRange(configured.gravityLevel, 0, 3, 0)),
        snowTrails = configured.snowTrails == true,
    }
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
        if currentState and currentState.weather == weatherType then
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(weatherType)
            SetWeatherTypeNow(weatherType)
            SetWeatherTypeNowPersist(weatherType)
        end
    end)
end

local function applyState(state, blendWeather)
    if type(state) ~= 'table' or type(state.weather) ~= 'string' then return end

    local previousState = currentState
    currentState = state
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

AddStateBagChangeHandler('qbweathersync', nil, function(_, _, value)
    if value == nil then return end
    applyState(value, currentState ~= nil)
end)

RegisterNetEvent('qbweathersync:client:state', function(state)
    applyState(state, currentState ~= nil)
end)

-- qbadmin reads this at menu-open time.  Exporting the source list keeps its
-- selector aligned with this resource's config (including snow-only/event
-- weather) without making qbadmin start-order dependent on this resource.
exports('getWeatherTypes', function()
    return Config.weatherTypes
end)

CreateThread(function()
    while currentState == nil do
        local state = GlobalState.qbweathersync
        if state then applyState(state, false) end
        Wait(1000)
    end

    -- NetworkOverrideClockTime is an override rather than a running clock.
    -- Reapplying it once a second keeps every client aligned between server
    -- minute updates, including after a player briefly loses scope.
    while true do
        NetworkOverrideClockTime(currentState.hour, currentState.minute, 0)
        applyLevels(currentState)
        Wait(1000)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
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
