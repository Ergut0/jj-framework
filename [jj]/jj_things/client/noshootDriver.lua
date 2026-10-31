lib.onCache('vehicle', function(veh)
    local vehicle = veh 
    CreateThread(function()
        while vehicle do
            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                DisablePlayerFiring(PlayerPedId(), true)
            end
            Wait(1)
        end
    end)
end)