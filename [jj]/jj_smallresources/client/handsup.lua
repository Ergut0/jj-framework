local handsUp = false

RegisterCommand(Config.HandsUp.command, function()
    local ped = PlayerPedId()
    if IsPedReloading(ped) then return end
    if IsPedInAnyVehicle(ped, false) then return end
    if LocalPlayer.state.isDead or LocalPlayer.state.isLastStand then return end
    if not HasAnimDictLoaded('missminuteman_1ig_2') then
        RequestAnimDict('missminuteman_1ig_2')
        while not HasAnimDictLoaded('missminuteman_1ig_2') do
            Wait(10)
        end
    end
    handsUp = not handsUp
    if handsUp then
        TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, 8.0, -1, 50, 0, false, false, false)
        exports['jj_smallresources']:addDisableControls(Config.HandsUp.controls)
    else
        ClearPedTasks(ped)
        exports['jj_smallresources']:removeDisableControls(Config.HandsUp.controls)
    end
end, false)

RegisterKeyMapping(Config.HandsUp.command, 'Hands Up', 'keyboard', Config.HandsUp.keybind)
exports('getHandsup', function() return handsUp end)
