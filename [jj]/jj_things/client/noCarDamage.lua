AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        SetPedConfigFlag(playerPed, 250, false) 
        SetPedConfigFlag(playerPed, 34, false) 
   end
end)

AddEventHandler('jj:client:playerSpawned', function()
    Citizen.Wait(1000) 
    local playerPed = PlayerPedId()
    SetPedConfigFlag(playerPed, 250, false) 
    SetPedConfigFlag(playerPed, 34, false) 
end)

lib.onCache("ped", function(value)
    SetPedConfigFlag(value, 250, false) 
    SetPedConfigFlag(value, 34, false) 
end)


local inVeh = nil 

lib.onCache('vehicle', function(value)
    local contador = 0 
    local wheelsCount = {}
    inVeh = value 
    Citizen.CreateThread(function()
        while inVeh do
            Citizen.Wait(sleep)
            local sleep = 1500 
            if GetPedInVehicleSeat(inVeh, -1) == cache.ped then
                local vehClass = GetVehicleClass(inVeh)
                if vehClass ~= 8 then -- Vehiculos
                    local wheels = {0, 1, 4, 5} 

                    for k, v in pairs(wheels) do
                        if IsVehicleTyreBurst(inVeh, v, false) and not wheelsCount[v] then
                            contador = contador + 1  
                            wheelsCount[v] = true
                        end 
                    end 

                    if contador >= 2 then
                        sleep = 800 
                        SetVehicleEngineOn(inVeh, false, true, true) 
                        SetVehicleUndriveable(inVeh, true) 
                    end
                elseif vehClass == 8 then  -- Motos
                    local wheels = {6, 7} 

                    for k, v in pairs(wheels) do
                        if IsVehicleTyreBurst(inVeh, v, false) and not wheelsCount[v] then
                            contador = contador + 1  
                            wheelsCount[v] = true
                        end 
                    end 

                    if contador >= 1 then
                        sleep = 800 
                        SetVehicleEngineOn(inVeh, false, true, true) 
                        SetVehicleUndriveable(inVeh, true) 
                    end 
                end 
            end
        end
    end)
end)



