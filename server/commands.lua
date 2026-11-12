local permissionOptions = {
    permission = Config.command.permission,
    resource = GetCurrentResourceName(),
    checkPermission = function(src, required)
        return Kora.permissions.hasLevel(src, required, Config.command.levels, { prefix = Config.command.permissionPrefix })
    end,
    notify = function(src, key, type_, ...)
        local commandName = type(key) == 'string' and key:match('^Missing arguments for /(.+)$')
        if commandName then
            key = 'missing_arguments'
            if src == 0 then
                print(('[kora_weathersync] %s'):format(Kora.locale.translate('kora_weathersync', key, commandName)))
            else
                TriggerClientEvent('kora_weathersync:client:notify', src, type_, key, commandName)
            end
            return
        elseif key == 'You do not have permission for this command.' then
            key = 'no_permission'
        end
        if src == 0 then
            print(('[kora_weathersync] %s'):format(Kora.locale.translate('kora_weathersync', key, ...)))
        else
            TriggerClientEvent('kora_weathersync:client:notify', src, type_, key, ...)
        end
    end,
}

local function respond(src, ok, key, ...)
    permissionOptions.notify(src, key, ok and 'success' or 'error', ...)
end

local function parseBoolean(value)
    if value == nil then return nil end
    value = value:lower()
    if value == 'true' or value == '1' or value == 'on' then return true end
    if value == 'false' or value == '0' or value == 'off' then return false end
    return false, 'expected_boolean'
end

local weatherValues = {}
for _, weatherType in ipairs(Config.weatherTypes) do weatherValues[#weatherValues + 1] = weatherType end

Kora.commands.add('weather', Kora.lang('command_weather'), { { name = 'type', values = weatherValues } }, true,
    function(source, args)
        local ok, err = WeatherSync.setWeather(args[1])
        respond(source, ok, ok and 'weather_set' or err, tostring(args[1] or ''):upper())
    end, permissionOptions)

Kora.commands.add('freezeweather', Kora.lang('command_freeze_weather'), { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local active = WeatherSync.setDynamicWeather(enabled)
        respond(source, true, active and 'dynamic_weather_enabled' or 'dynamic_weather_disabled')
    end, permissionOptions)

Kora.commands.add('time', Kora.lang('command_time'), { { name = 'hour' }, { name = 'minute' } }, false,
    function(source, args)
        local preset = type(args[1]) == 'string' and Config.timePresets[args[1]:lower()] or nil
        local hour = preset and preset.hour or tonumber(args[1])
        local minute = preset and preset.minute or (args[2] == nil and 0 or tonumber(args[2]))
        local ok, err = WeatherSync.setTime(hour, minute)
        respond(source, ok, ok and 'time_set' or err, tonumber(hour) or 0, tonumber(minute) or 0)
    end, permissionOptions)

Kora.commands.add('freezetime', Kora.lang('command_freeze_time'), { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local frozen = WeatherSync.setTimeFrozen(enabled)
        respond(source, true, frozen and 'time_frozen' or 'time_running')
    end, permissionOptions)

Kora.commands.add('blackout', Kora.lang('command_blackout'), { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local blackout = WeatherSync.setBlackout(enabled)
        respond(source, true, blackout and 'blackout_enabled' or 'blackout_disabled')
    end, permissionOptions)

for name, preset in pairs(Config.timePresets) do
    Kora.commands.add(name, Kora.lang('command_preset_time', preset.hour, preset.minute), nil, false, function(source)
        local ok, err = WeatherSync.setTime(preset.hour, preset.minute)
        respond(source, ok, ok and 'time_set' or err, preset.hour, preset.minute)
    end, permissionOptions)
end
