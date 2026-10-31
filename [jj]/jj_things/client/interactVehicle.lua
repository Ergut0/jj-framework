local function PutInVehicle()
    local cVehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 6.0)
    if not cVehicle then return end
    local cPlayer, cPed, _ = lib.getClosestPlayer(GetEntityCoords(cache.ped), 6.0, false) 
    if not cPlayer then return end

    local cPlayerServerId = GetPlayerServerId(cPlayer)
    local cPlayerState = Player(cPlayerServerId).state

    if cPlayerState.isDead or cPlayerState.isLastStand then
        if not DoesEntityExist(cVehicle) then return end

        local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(cVehicle)

        for i = maxSeats - 1, 0, -1 do
            if IsVehicleSeatFree(cVehicle, i) then
                freeSeat = i
                break
            end
        end

        if not freeSeat then print("No free seat available") return end

        TriggerServerEvent('jj_things:putInVehicle', cPlayerServerId, VehToNet(cVehicle), freeSeat)
        local msg = "Lo mete con cuidado en el coche y le coloca el cinturón"
        TriggerServerEvent("jj_chat:server:executeCommand", "me", msg)
    end
end

local function OutOfVehicle()
    local cVehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 6.0)
    if not cVehicle then return end
    local maxSeats = GetVehicleMaxNumberOfPassengers(cVehicle)
    local targetPed

    for i = maxSeats - 1, 0, -1 do
        local ped = GetPedInVehicleSeat(cVehicle, i)
        if ped ~= 0 then
            targetPed = ped
            break
        end
    end

    if not targetPed then return end

    local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
    local targetServerId = GetPlayerServerId(targetPlayerId)
    local targetState = Player(targetServerId).state

    print(targetServerId, targetState.isDead, targetState.isLastStand)
    if targetState.isDead or targetState.isLastStand then
        TriggerServerEvent('jj_things:outOfVehicle', targetServerId, VehToNet(cVehicle))
        local msg = "Le quita el cinturón y lo saca con cuidado"
        TriggerServerEvent("jj_chat:server:executeCommand", "me", msg)
    end
end

CreateThread(function()
    local wait = 1500
    while true do
        if cache.vehicle then 
            wait = 1
            if not IsVehicleOnAllWheels(cache.vehicle) then 
                local vehType = GetVehicleTypeRaw(cache.vehicle)
                if vehType ~= 11 and vehType ~= 12 and vehType ~= 13 then
                    DisableControlAction(0, 61, true) -- Disable exit vehicle
                    DisableControlAction(0, 60, true) -- Disable exit vehicle
                    DisableControlAction(0, 62, true) -- Disable exit vehicle
                    DisableControlAction(0, 132, true) -- Disable exit vehicle
                    DisableControlAction(0, 224, true) -- Disable exit vehicle
                    DisableControlAction(0, 280, true) -- Disable exit vehicle
                    DisableControlAction(0, 281, true) -- Disable exit vehicle
                    DisableControlAction(0, 326, true) -- Disable exit vehicle
                    DisableControlAction(0, 341, true) -- Disable exit vehicle
                    DisableControlAction(0, 343, true) -- Disable exit vehicle
                end
            end
        else
            wait = 1500
        end
        Wait(wait)
    end
end)


RegisterNetEvent('jj_things:client:putInVehicle', function(netId, seat)
    local vehicle = NetToVeh(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetPedIntoVehicle(cache.ped, vehicle, seat)
    end
end)

RegisterNetEvent('jj_things:client:outOfVehicle', function(netId)
    local vehicle = NetToVeh(netId)
    if vehicle and vehicle ~= 0 and cache.vehicle == vehicle then
        TaskLeaveVehicle(cache.ped, vehicle, 0)
    end
end)

exports('PutInVehicle', PutInVehicle)
exports('OutOfVehicle', OutOfVehicle)