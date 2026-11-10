Config = Config or {}

Config.startingWeather = 'EXTRASUNNY' -- GTA weather type used when this resource starts
Config.startingTime = { hour = 12, minute = 0 } -- simulated clock at resource start
Config.realSecondsPerGameMinute = 8 -- real seconds between simulated clock minutes
Config.freezeTime = false -- whether the simulated clock starts paused
Config.dynamicWeather = true -- whether weather advances through `weatherTransitions`
Config.weatherChangeEveryMinutes = 10 -- real minutes between automatic weather transitions; 0 disables them
Config.blackout = false -- initial artificial-lights blackout state
Config.blackoutAffectsVehicles = false -- whether blackout also turns off vehicle lights
Config.weatherTransitionSeconds = 15.0 -- client-side blend duration between weather types

Config.weatherTypes = {
    'EXTRASUNNY', 'CLEAR', 'NEUTRAL', 'SMOG', 'FOGGY', 'OVERCAST', 'CLOUDS', 'CLEARING',
    'RAIN', 'THUNDER', 'SNOW', 'BLIZZARD', 'SNOWLIGHT', 'XMAS', 'HALLOWEEN',
}

-- Possible next states for dynamic weather.  A weather type absent from this
-- table falls back to CLEAR rather than leaving the scheduler stuck.
Config.weatherTransitions = {
    EXTRASUNNY = { 'CLEAR', 'CLOUDS' },
    CLEAR = { 'CLEARING', 'CLOUDS', 'EXTRASUNNY' },
    NEUTRAL = { 'CLEAR', 'CLOUDS' },
    SMOG = { 'CLEAR', 'FOGGY' },
    FOGGY = { 'CLEARING', 'CLOUDS' },
    OVERCAST = { 'RAIN', 'CLOUDS', 'CLEARING' },
    CLOUDS = { 'OVERCAST', 'CLEAR', 'FOGGY' },
    CLEARING = { 'CLEAR', 'CLOUDS', 'EXTRASUNNY' },
    RAIN = { 'THUNDER', 'CLEARING', 'OVERCAST' },
    THUNDER = { 'RAIN', 'CLEARING' },
    SNOW = { 'SNOWLIGHT', 'BLIZZARD', 'CLOUDS' },
    SNOWLIGHT = { 'SNOW', 'CLOUDS' },
    BLIZZARD = { 'SNOW', 'SNOWLIGHT' },
    XMAS = { 'SNOWLIGHT', 'SNOW' },
    HALLOWEEN = { 'FOGGY', 'CLEAR' },
}

-- Extra environmental natives, applied on every client.  Levels are kept in
-- config so a server can make an event more dramatic without changing code:
-- rain/snow are 0.0–1.0 and gravity is 0 (normal), 1 (low), 2 (very low), or
-- 3 (zero gravity).  BLIZZARD uses low gravity by default as its special twist.
Config.weatherEffects = {
    RAIN = { rainLevel = 0.35 },
    THUNDER = { rainLevel = 0.70 },
    SNOW = { snowLevel = 0.45, snowTrails = true },
    SNOWLIGHT = { snowLevel = 0.25, snowTrails = true },
    BLIZZARD = { snowLevel = 1.00, gravityLevel = 1, snowTrails = true },
    XMAS = { snowLevel = 0.70, snowTrails = true },
}

Config.command = {
    permission = 'admin', -- kora_lib ACE/Discord permission tier required for world controls
    levels = { 'god', 'admin', 'mod', 'user' }, -- ranked levels understood by kora_lib permissions
    permissionPrefix = 'kora_core', -- matches this server's `kora_core.admin` ACE configuration
}

Config.timePresets = {
    morning = { hour = 9, minute = 0 },
    noon = { hour = 12, minute = 0 },
    evening = { hour = 18, minute = 0 },
    night = { hour = 23, minute = 0 },
}

-- Registers this resource-owned configuration with kora_lib without changing its public Config table.
if Kora and Kora.config and Kora.config.adopt then
    Config.startingWeather = Kora.config.enum(Config.startingWeather, {
        label = 'Starting weather',
        description = 'Selects the weather state kora_weathersync applies when the resource starts before any scheduled transition occurs. Only weather names from the authored weather catalogue can be saved.',
        options = Config.weatherTypes,
    })
    Config = Kora.config.adopt(Config)
end
