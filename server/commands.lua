local permissionOptions = {
    permission = Config.command.permission,
    resource = GetCurrentResourceName(),
    checkPermission = function(src, required)
        return QB.permissions.hasLevel(src, required, Config.command.levels, { prefix = Config.command.permissionPrefix })
    end,
    notify = function(src, message, type_)
        if src == 0 then
            print(('[qbweathersync] %s'):format(message))
        else
            QB.notify.send(src, { title = 'Weather', message = message, type = type_ })
        end
    end,
}

local function respond(src, ok, message)
    permissionOptions.notify(src, message, ok and 'success' or 'error')
end

local function parseBoolean(value)
    if value == nil then return nil end
    value = value:lower()
    if value == 'true' or value == '1' or value == 'on' then return true end
    if value == 'false' or value == '0' or value == 'off' then return false end
    return false, 'expected true/false, on/off, or 1/0'
end

local weatherValues = {}
for _, weatherType in ipairs(Config.weatherTypes) do weatherValues[#weatherValues + 1] = weatherType end

QB.commands.add('weather', 'Set synchronized server weather', { { name = 'type', values = weatherValues } }, true,
    function(source, args)
        local ok, err = WeatherSync.setWeather(args[1])
        respond(source, ok, ok and ('Weather set to %s'):format(args[1]:upper()) or err)
    end, permissionOptions)

QB.commands.add('freezeweather', 'Toggle or set dynamic weather', { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local active = WeatherSync.setDynamicWeather(enabled)
        respond(source, true, ('Dynamic weather %s'):format(active and 'enabled' or 'disabled'))
    end, permissionOptions)

QB.commands.add('time', 'Set synchronized server time', { { name = 'hour' }, { name = 'minute' } }, false,
    function(source, args)
        local preset = type(args[1]) == 'string' and Config.timePresets[args[1]:lower()] or nil
        local hour = preset and preset.hour or tonumber(args[1])
        local minute = preset and preset.minute or (args[2] == nil and 0 or tonumber(args[2]))
        local ok, err = WeatherSync.setTime(hour, minute)
        respond(source, ok, ok and ('Time set to %02d:%02d'):format(hour, minute) or err)
    end, permissionOptions)

QB.commands.add('freezetime', 'Toggle or set synchronized time freeze', { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local frozen = WeatherSync.setTimeFrozen(enabled)
        respond(source, true, ('Time %s'):format(frozen and 'frozen' or 'running'))
    end, permissionOptions)

QB.commands.add('blackout', 'Toggle or set artificial-lights blackout', { { name = 'true|false', values = { 'true', 'false' } } }, false,
    function(source, args)
        local enabled, err = parseBoolean(args[1])
        if err then return respond(source, false, err) end
        local blackout = WeatherSync.setBlackout(enabled)
        respond(source, true, ('Blackout %s'):format(blackout and 'enabled' or 'disabled'))
    end, permissionOptions)

for name, preset in pairs(Config.timePresets) do
    QB.commands.add(name, ('Set time to %02d:%02d'):format(preset.hour, preset.minute), nil, false, function(source)
        local ok, err = WeatherSync.setTime(preset.hour, preset.minute)
        respond(source, ok, ok and ('Time set to %02d:%02d'):format(preset.hour, preset.minute) or err)
    end, permissionOptions)
end
