# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_weathersync — Core & Libraries

  @kora_weathersync @checklist @checklist:kora_weathersync:weather-cmd @cat:core-and-libraries @needs:admin
  Scenario: /weather <type> (admin)
    """
    Checklist test: As admin run /weather RAIN/THUNDER/SNOW/BLIZZARD etc.; sky changes for all players with a 15s blend; non-admins refused.
    """
    When I run the command "/weather RAIN"
    Then I confirm: my sky changes to rain with a blend of about 15 seconds
    When I run the command "/weather THUNDER"
    Then I confirm: my sky changes to thunder with a blend of about 15 seconds
    When I run the command "/weather SNOW"
    Then I confirm: my sky changes to snow with a blend of about 15 seconds
    When I run the command "/weather BLIZZARD"
    Then I confirm: my sky changes to blizzard with a blend of about 15 seconds
    And I confirm: the other player sees the same weather change
    When I manually: ask a second non-admin player to run /weather RAIN
    Then I confirm: the non-admin player is refused and the weather does not change

  @kora_weathersync @checklist @checklist:kora_weathersync:weather-effects @cat:core-and-libraries @needs:admin
  Scenario: Rain, snow and blizzard effects
    """
    Checklist test: RAIN/THUNDER show rain, SNOW/SNOWLIGHT/XMAS show snow and trails, BLIZZARD adds low gravity.
    """
    When I run the command "/weather RAIN"
    Then I confirm: rain is visible
    When I run the command "/weather THUNDER"
    Then I confirm: rain is visible and heavier than in RAIN
    When I run the command "/weather SNOW"
    Then I confirm: snow is visible and my character leaves snow trails
    When I run the command "/weather SNOWLIGHT"
    Then I confirm: snow is visible and my character leaves snow trails
    When I run the command "/weather XMAS"
    Then I confirm: snow is visible and my character leaves snow trails
    When I run the command "/weather BLIZZARD"
    Then I confirm: heavy snow is visible and gravity is low (only applies when the BLIZZARD gravityLevel in Config.weatherEffects is not 0)

  @kora_weathersync @checklist @checklist:kora_weathersync:freezeweather @cat:core-and-libraries @needs:admin
  Scenario: /freezeweather [true|false]
    """
    Checklist test: Toggle dynamic weather; when frozen weather stops cycling (default changes every 10 min).
    """
    When I run the command "/freezeweather true"
    Then I confirm: dynamic weather is turned off and the weather stops cycling
    When I manually: note the current weather and wait about 10 minutes with weather frozen
    Then I confirm: the weather has not changed after 10 minutes
    When I run the command "/freezeweather false"
    Then I confirm: dynamic weather is on again and the weather changes automatically about every 10 minutes

  @kora_weathersync @checklist @checklist:kora_weathersync:time-cmd @cat:core-and-libraries @needs:admin
  Scenario: /time <hour> [minute]
    """
    Checklist test: Set the world clock for everyone; HUD/sky match. Invalid values are rejected.
    """
    When I run the command "/time 18 30"
    And the HUD should show "18:30"
    Then I confirm: my sky matches 18:30
    And I confirm: the world clock is 18:30 for the other players too
    When I run the command "/time 99"
    Then I confirm: the invalid time is rejected and the clock does not change
    When I run the command "/time abc"
    Then I confirm: the invalid time is rejected and the clock does not change

  @kora_weathersync @checklist @checklist:kora_weathersync:time-presets @cat:core-and-libraries @needs:admin @manual
  Scenario: /morning /noon /evening /night
    """
    Checklist test: Presets set time to 09:00, 12:00, 18:00, 23:00 for all players.
    """
    When I manually: run /morning
    Then I confirm: the time is 09:00 for me and for the other player
    When I manually: run /noon
    Then I confirm: the time is 12:00 for me and for the other player
    When I manually: run /evening
    Then I confirm: the time is 18:00 for me and for the other player
    When I manually: run /night
    Then I confirm: the time is 23:00 for me and for the other player

  @kora_weathersync @checklist @checklist:kora_weathersync:freezetime @cat:core-and-libraries @needs:admin
  Scenario: /freezetime [true|false]
    """
    Checklist test: Pause/resume the game clock (1 game minute per 8 real seconds when running).
    """
    When I run the command "/freezetime true"
    And I wait 60 seconds
    Then I confirm: the game clock is paused and does not advance
    When I run the command "/freezetime false"
    And I wait 60 seconds
    Then I confirm: the clock runs again at 1 game minute per 8 real seconds

  @kora_weathersync @checklist @checklist:kora_weathersync:blackout @cat:core-and-libraries @needs:admin
  Scenario: /blackout [true|false]
    """
    Checklist test: Toggle artificial lights blackout across the map; vehicle lights unaffected by default.
    """
    When I run the command "/blackout true"
    Then I confirm: artificial lights across the map are off
    And I confirm: vehicle lights stay on (only applies when Config.blackoutAffectsVehicles is false, the default)
    When I run the command "/blackout false"
    Then I confirm: artificial lights are back on

  @kora_weathersync @checklist @checklist:kora_weathersync:late-join-sync @cat:core-and-libraries @needs:admin
  Scenario: New joiners get current world
    """
    Checklist test: Change weather/time, then connect a second player: they see the same weather and time immediately.
    """
    When I run the command "/weather RAIN"
    And I run the command "/time 18 30"
    And I manually: ask a second player to connect to the server
    Then I confirm: the other player sees RAIN and the time 18:30 immediately after joining

  @kora_weathersync @checklist @checklist:kora_weathersync:dynamic-weather @cat:core-and-libraries @needs:admin
  Scenario: Automatic weather transitions
    """
    Checklist test: With dynamic weather on, weather changes along configured transitions every ~10 real minutes.
    """
    When I run the command "/freezeweather false"
    And I manually: note the current weather and wait about 10 real minutes
    Then I confirm: the weather changes to one of the allowed next types in Config.weatherTransitions for the previous weather
    When I manually: wait another 10 real minutes
    Then I confirm: the weather changes again along the configured transitions
