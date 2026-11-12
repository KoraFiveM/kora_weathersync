---
title: Exports
sidebar_position: 4
---

# Exports

## Server exports

Called as `exports.kora_weathersync:name(...)`. All setters publish a new state snapshot immediately.

| Export | Returns | Description |
| --- | --- | --- |
| `setWeather(weatherType)` | `ok, err` | Sets weather (case-insensitive). `err` is `unknown_weather_type` on failure. Restarts the dynamic weather timer. |
| `getWeather()` | string | Current weather, upper-case. |
| `setTime(hour, minute)` | `ok, err` | Requires integer hour 0-23 and minute 0-59; `err` is `invalid_time` otherwise. Both arguments are required. |
| `getTime()` | `hour, minute` | Current simulated clock. |
| `setTimeFrozen(enabled)` | boolean | Pauses or resumes the clock; `nil` toggles. Returns the new value. |
| `getTimeFrozen()` | boolean | Whether the clock is paused. |
| `setDynamicWeather(enabled)` | boolean | Enables or disables automatic weather changes; `nil` toggles. Restarts the timer. Returns the new value. |
| `getDynamicWeather()` | boolean | Whether dynamic weather is on. |
| `setBlackout(enabled)` | boolean | Sets the blackout; `nil` toggles. Returns the new value. |
| `getBlackout()` | boolean | Whether the blackout is active. |
| `nextWeatherStage()` | `ok, err` | Picks the next weather from `Config.weatherTransitions` (fallback `CLEAR`) and sets it. |
| `getState()` | table | Copy of the current snapshot. |

For the `qb-weathersync` named exports see [Compatibility](./compatibility.md).

## Client export

| Export | Returns | Description |
| --- | --- | --- |
| `getWeatherTypes()` | table | The `Config.weatherTypes` list. |

## State snapshot

`getState()`, `GlobalState.kora_weathersync` and the `kora_weathersync:client:state` event carry a table with these fields:

| Field | Type | Description |
| --- | --- | --- |
| `weather` | string | Current weather type. |
| `hour`, `minute` | integer | Simulated clock. |
| `timeFrozen` | boolean | Clock paused. |
| `dynamicWeather` | boolean | Automatic weather changes on. |
| `blackout` | boolean | Blackout active. |
| `blackoutAffectsVehicles` | boolean | From `Config.blackoutAffectsVehicles`. |
| `revision` | integer | Incremented on every publish. |

The snapshot is republished on every setter call and every simulated clock minute while the clock is running. It is cleared (`nil`) when the resource stops.
