---
title: Commands
sidebar_position: 3
---

# Commands

All commands are registered through `Kora.commands.add` on the server and require the level in `Config.command.permission` (default `admin`, ACE `kora_core.admin`). The permission check is `Kora.permissions.hasLevel` with `Config.command.levels` and `Config.command.permissionPrefix`. Replies are sent as a `kora_lib` notification to the player, or printed to the console with a `[kora_weathersync]` prefix when run from the console (source 0). Texts come from `locales/en.lua`.

| Command | Arguments | Effect |
| --- | --- | --- |
| `/weather` | `type` (required) | Sets weather to a type from `Config.weatherTypes`; unknown types are rejected. Resets the dynamic weather timer. |
| `/freezeweather` | optional `true` or `false` | Sets dynamic weather. See the note below. No argument toggles. |
| `/time` | `hour` and optional `minute`, or a preset name | Sets the clock. Integer hour 0-23, minute 0-59 (minute defaults to 0). A preset name such as `noon` is accepted as the first argument. |
| `/freezetime` | optional `true` or `false` | `true` freezes the clock, `false` runs it. No argument toggles. |
| `/blackout` | optional `true` or `false` | Enables or disables the blackout. No argument toggles. |
| `/morning`, `/noon`, `/evening`, `/night` | none | One command per entry in `Config.timePresets`; sets that time. |

Boolean arguments accept `true`, `1`, `on`, `false`, `0` and `off` (case-insensitive). Anything else gives the `expected_boolean` message.

## `/freezeweather` semantics

The argument sets the **dynamic weather** flag, not a freeze flag: `/freezeweather true` turns dynamic weather **on**, and `/freezeweather false` turns it off (weather stops cycling). Running it without an argument toggles the flag. This is the opposite of what the command name suggests and of the wording in `tests/checklist-core-and-libraries.feature`; the docs follow the code.

## Permissions

Without permission the player sees "You do not have permission for this command." Grant the ACE, for example `add_ace group.admin kora_core.admin allow`, according to how your `kora_lib` permission setup resolves levels.
