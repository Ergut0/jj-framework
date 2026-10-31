exports('wheelchair', function(data)
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    
    exports.ox_inventory:useItem(data, function(data)
        SpawnVehicle('wheelchair', function(vehicle)
            if data then
                TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
                SetEntityHeading(vehicle, heading)
                Notify('Silla desplegada', 'success')
            end
        end, coords)
    end)
end)

CreateThread(function()
    while not GetPlayerData() or not GetPlayerData().job do
        Wait(100)
    end

    exports.ox_target:addModel('wheelchair', {
        label = 'Desmontar silla de ruedas',
        name = 'remove',
        icon = 'fa-solid fa-wheelchair',
        distance = 2.0,
        canInteract = function(entity)
            return not DoesEntityExist(GetPedInVehicleSeat(entity, -1))
        end,
        onSelect = function(data)
            TriggerServerEvent('removeWheelChair', NetworkGetNetworkIdFromEntity(data.entity))
        end
    })
end)