# qb-weathersync

Server-authoritative weather, time, blackout, and client environmental effects
for the qblib test server. It follows the state-sync approach from
[QBCore-Remastered/qb-weathersync](https://github.com/QBCore-Remastered/qb-weathersync/),
but uses a single `GlobalState.qbweathersync` snapshot so late joiners and
resource restarts receive the active world immediately.

## Commands

All commands require the configured `qbcore.admin` tier (console is allowed).

- `/weather <type>`
- `/freezeweather [true|false]` — controls dynamic weather
- `/time <hour> [minute]`
- `/freezetime [true|false]`
- `/blackout [true|false]`
- `/morning`, `/noon`, `/evening`, `/night`

## Exports

`setWeather`, `getWeather`, `setTime`, `getTime`, `setTimeFrozen`,
`getTimeFrozen`, `setDynamicWeather`, `getDynamicWeather`, `setBlackout`,
`getBlackout`, `nextWeatherStage`, and `getState` are server exports.

`Config.weatherEffects` maps a weather type to `rainLevel`, `snowLevel`,
`gravityLevel`, and `snowTrails`. `BLIZZARD` ships with low gravity as a
deliberate event-style effect; set its `gravityLevel` to `0` for ordinary snow.
