RegisterNetEvent('jj_announce:show', function(data)
    SendNUIMessage({ action = 'show', data = data })
    if Config.Sound then
        PlaySoundFrontend(-1, 'Beep_Green', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    end
end)
