local function MathRound(value, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
  
    return math.floor(value * mult + 0.5) / mult
end

RegisterCommand('limitator', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 and not IsThisModelABicycle(GetEntityModel(vehicle)) and not IsThisModelAPlane(GetEntityModel(vehicle)) and not IsThisModelAHeli(GetEntityModel(vehicle)) and IsVehicleEngineOn(vehicle) and GetPedInVehicleSeat(vehicle, -1) == playerPed then
        if Entity(vehicle).state.limitator then
            Entity(vehicle).state:set('limitator', false, true)
            Notify('Limitador desactivado', 'success')
        else
            Entity(vehicle).state:set('limitator', (GetEntitySpeed(vehicle) * 3.6), true)
            Notify('Has activado el limitador a ' .. MathRound((GetEntitySpeed(vehicle) * 3.6), 0) .. ' km/h', 'success')
        end
    end
end, false)
  
RegisterKeyMapping('limitator', 'Activar/desactivar limitador', 'keyboard', 'J')

local inVehicle = false
lib.onCache('vehicle', function(veh)
    inVehicle = veh
    CreateThread(function()
        while inVehicle do
            if Entity(veh).state.limitator then
                SetEntityMaxSpeed(veh, Entity(veh).state.limitator / 3.6)
            else
                SetEntityMaxSpeed(veh, GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel'))
            end
            local roll = GetEntityRoll(veh)
            if (roll > 75.0 or roll < -75.0) and GetEntitySpeed(veh) < 2 then
                DisableControlAction(2,59,true) -- Disable left/right
                DisableControlAction(2,60,true) -- Disable up/down
            end
            Wait(1)
        end
    end)
end)