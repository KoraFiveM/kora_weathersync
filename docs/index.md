---
title: kora_weathersync
sidebar_position: 1
---

# kora_weathersync

`kora_weathersync` is a server-authoritative weather, clock, blackout and environmental-effects sync resource for Kora servers. The server keeps one world state and publishes it as a single `GlobalState.kora_weathersync` snapshot, so late joiners and resource restarts receive the active world immediately. Clients apply the weather, clock, blackout and extra effects (rain, snow, snow trails, low gravity) locally. It also provides `qb-weathersync` (`provide 'qb-weathersync'`) and exposes qb-weathersync compatible exports and events.

Current version: see `version` in `fxmanifest.lua`.

## Pages

- [Configuration](./configuration.md) - every `Config` option and its effect.
- [Commands](./commands.md) - admin chat/console commands and permission handling.
- [Exports](./exports.md) - server exports, the client export and the state snapshot.
- [Events](./events.md) - net events, state bag, rate limits and trust rules.
- [Compatibility](./compatibility.md) - the `qb-weathersync` exports and events that are provided.
- [Troubleshooting](./troubleshooting.md) - common problems and known quirks.

## Features

- Weather: any type in `Config.weatherTypes`, blended on clients over `Config.weatherTransitionSeconds`.
- Dynamic weather: a single server timer picks the next weather from `Config.weatherTransitions` every `Config.weatherChangeEveryMinutes` minutes.
- Clock: a simulated clock that advances one minute every `Config.realSecondsPerGameMinute` real seconds, can be frozen, set, or set from presets.
- Blackout: artificial lights off, optionally including vehicle lights.
- Effects: per-weather rain level, snow level, gravity level and snow trails from `Config.weatherEffects`.
- No database: all state is in memory and resets to config values when the resource starts.

## Requirements

Declared in `fxmanifest.lua`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | Config adoption (`Kora.config`), locales, commands (`Kora.commands`), permissions (`Kora.permissions`), timers, notifications, compat exports (`Kora.compat`) |

The permission prefix `kora_core` is only an ACE prefix string (see [Commands](./commands.md)); `kora_core` is not declared as a dependency.

## Installation

1. Ensure `kora_lib` starts before this resource.
2. Add `ensure kora_weathersync` to your server config. Do not run another resource that provides `qb-weathersync` at the same time.
3. Grant the admin permission (default `kora_core.admin`) to staff.
4. Adjust `shared/config.lua` as needed.

## Layout

- `fxmanifest.lua` - manifest, `provide 'qb-weathersync'`.
- `shared/config.lua` - all configuration.
- `server/state.lua` - state, setters, exports, events, clock loop.
- `server/commands.lua` - admin commands.
- `client/main.lua` - applies the state, effects and legacy client events.
- `locales/en.lua` - notification and command texts.
- `test/` and `tests/` - offline Lua tests and kora_qa feature files.
