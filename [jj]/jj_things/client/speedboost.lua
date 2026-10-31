CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()

        if not IsEntityDead(ped) then
            if IsPedReloading(ped) then

                DisableControlAction(0, 21, true)

                SetPedMoveRateOverride(ped, 0.5)

            else
                SetPedMoveRateOverride(ped, 1.0)
            end
        else
            Wait(500)
        end
    end
end)