RemoveHudComponents = {
    [1] = true, --WANTED_STARS,
    [2] = true, --WEAPON_ICON
    [3] = true, --CASH
    [4] = true, --MP_CASH
    [5] = false, --MP_MESSAGE
    [6] = true, --VEHICLE_NAME
    [7] = true, -- AREA_NAME
    [8] = true, -- VEHICLE_CLASS
    [9] = true, --STREET_NAME
    [10] = false, --HELP_TEXT
    [11] = false, --FLOATING_HELP_TEXT_1
    [12] = false, --FLOATING_HELP_TEXT_2
    [13] = true, --CASH_CHANGE
    [14] = false, --RETICLE
    [15] = true, --SUBTITLE_TEXT
    [16] = false, --RADIO_STATIONS
    [17] = true, --SAVING_GAME,
    [18] = false, --GAME_STREAM
    [19] = false, --WEAPON_WHEEL
    [20] = false, --WEAPON_WHEEL_STATS
    [21] = false, --HUD_COMPONENTS
    [22] = false, --HUD_WEAPONS
}

for i = 1, #RemoveHudComponents do
    if RemoveHudComponents[i] then
        SetHudComponentSize(i, 0.0, 0.0)
        SetHudComponentPosition(i, 900, 900)
    end
end