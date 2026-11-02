local IsEntityAttachedToEntity = IsEntityAttachedToEntity
local playerState = LocalPlayer.state
local targetsAdded = false

local function vehicleActions()
    if targetsAdded then return end
    targetsAdded = true

    Target:addGlobalVehicle({
        {
            name = 'police_put_in_vehicle',
            icon = 'fa-solid fa-arrow-up',
            label = 'Meter en el vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                if not IsOnDuty('police', 'ambulance', 'sheriff') then return false end
                local targetPlayerId, targetPed, _ = lib.getClosestPlayer(coords, 2.0, false)
                if not targetPed then return false end
                local targetSvId = GetPlayerServerId(targetPlayerId)
                local targetState = Player(targetSvId).state
                return targetPed and not IsPedInAnyVehicle(targetPed, false) or
                    targetState.isDead and not playerState.invBusy
            end,
            onSelect = function(data)
                local vehicle = data.entity
                if not DoesEntityExist(vehicle) then return end

                local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

                for i = maxSeats - 1, 0, -1 do
                    if IsVehicleSeatFree(vehicle, i) then
                        freeSeat = i
                        break
                    end
                end


                if not freeSeat then
                    Notify('El vehículo no tiene asientos libres', 'error')
                    return
                end

                local targetId, targetPed, _ = lib.getClosestPlayer(data.coords, 2.0, false)
                local targetSvId = GetPlayerServerId(targetId)

                if not targetPed or not targetId then return end
                local targetState = Player(targetSvId).state

                if targetState.isCuffed or targetState.isDead then
                    playerState.isEscorting = false
                    TriggerServerEvent('jj_policejob:putInVehicle', targetSvId, VehToNet(data.entity), freeSeat)
                    local msg = "Introduce a la persona en el vehículo con cuidado"
                    RpAction(msg)
                end
            end
        },
        {
            name = 'police_out_of_vehicle',
            icon = 'fa-solid fa-arrow-down',
            label = 'Sacar del vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                if not IsOnDuty('police', 'ambulance', 'sheriff') then return false end
                local veh = entity
                local maxSeats = GetVehicleMaxNumberOfPassengers(veh)
                for i = maxSeats - 1, 0, -1 do
                    local ped = GetPedInVehicleSeat(veh, i)
                    if ped ~= 0 then
                        local targetPlayerId = NetworkGetPlayerIndexFromPed(ped)
                        local targetSvId = GetPlayerServerId(targetPlayerId)
                        local targetState = Player(targetSvId).state
                        if targetState.isCuffed or targetState.isDead then
                            return true
                        end
                    end
                end
                return false
            end,
            onSelect = function(data)
                local vehicle = data.entity
                if not DoesEntityExist(vehicle) then return end

                local maxSeats, targetPed = GetVehicleMaxNumberOfPassengers(vehicle)

                for i = maxSeats - 1, 0, -1 do
                    local ped = GetPedInVehicleSeat(vehicle, i)
                    if ped ~= 0 then
                        targetPed = ped
                        break
                    end
                end

                if not targetPed then return end

                local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
                local targetSvId = GetPlayerServerId(targetPlayerId)
                local targetState = Player(targetSvId).state
                if not targetState.isCuffed and not targetState.isDead then return end
                TriggerServerEvent('jj_policejob:outOfVehicle', targetSvId, VehToNet(data.entity))
                local msg = "Saca a la persona del vehículo con cuidado"
                RpAction(msg)
            end
        },
        {
            name = 'delete_vehicle',
            icon = 'fa-solid fa-car',
            label = 'Incautar vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                local playerInfo = GetPlayerData()
                if playerInfo.job.name ~= 'police' and playerInfo.job.name ~= 'ambulance' then return false end
                if playerInfo.job.onduty == false then return false end
                return true
            end,
            onSelect = function(data)
                if lib.progressCircle({
                        duration = 3000,
                        label = 'Llamando a la grúa',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            combat = true,
                        },
                    }) then
                    local vehicle = data.entity
                    if not DoesEntityExist(vehicle) then return end
                    TriggerServerEvent('jj_policejob:server:deleteVehicle', NetworkGetNetworkIdFromEntity(vehicle), false)
                    local msg = "Vendria una grua a incautar el vehículo con cuidado"
                    RpAction(msg)
                else
                    Notify('Has cancelado la incautación', 'error')
                end
            end
        },
        {
            name = 'delete_vehicle',
            icon = 'fa-solid fa-car',
            label = 'Confiscar vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                local playerInfo = GetPlayerData()
                if playerInfo.job.name ~= 'police' then return false end
                if playerInfo.job.onduty == false then return false end
                return true
            end,
            onSelect = function(data)
                if lib.progressCircle({
                        duration = 3000,
                        label = 'Llamando a la grúa',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            combat = true,
                        },
                    }) then
                    local vehicle = data.entity
                    if not DoesEntityExist(vehicle) then return end

                    TriggerServerEvent('jj_policejob:server:deleteVehicle', NetworkGetNetworkIdFromEntity(vehicle), true)
                    local msg = "Vendria una grua a confiscar el vehículo con cuidado"
                    RpAction(msg)
                else
                    Notify('Has cancelado la incautación', 'error')
                end
            end
        },
        {
            name = 'police_force_vehicle',
            icon = 'fa-solid fa-unlock',
            label = 'Forzar vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                local playerInfo = GetPlayerData()
                if playerInfo.job.name ~= 'police' then return false end
                if playerInfo.job.onduty == false then return false end
                if IsPedInAnyVehicle(cache.ped, false) then return false end
                return GetVehicleDoorLockStatus(entity) > 1
            end,
            onSelect = function(data)
                local vehicle = data.entity
                if not DoesEntityExist(vehicle) then return end

                RpAction("Saca las herramientas de apertura y comienza a forzar la cerradura del vehículo")

                if lib.progressCircle({
                        duration = 10000,
                        label = 'Forzando el vehículo',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            combat = true,
                        },
                        anim = {
                            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
                            clip = 'machinic_loop_mechandplayer',
                            flag = 1,
                        },
                    }) then
                    if not DoesEntityExist(vehicle) then return end
                    TriggerServerEvent('jj_policejob:server:forceVehicle', VehToNet(vehicle))
                    Notify('Has forzado el vehículo', 'success')
                    RpAction("Se escucharía un fuerte chasquido y la cerradura del vehículo cedería")
                else
                    Notify('Has dejado de forzar el vehículo', 'error')
                end
            end
        },
        {
            name = 'clean_vehicle',
            icon = 'fa-solid fa-soap',
            label = 'Limpiar vehículo',
            canInteract = function(entity, distance, coords, name, bone)
                local playerInfo = GetPlayerData()
                if playerInfo.job.name ~= 'police' then return false end
                if playerInfo.job.onduty == false then return false end

                --local playerCoords = GetEntityCoords(PlayerPedId())
                for _, location in pairs(Config.points) do
                    for _, point in pairs(location.vehiclePoints or {}) do
                        if #(coords - vector3(point.Spawn.x, point.Spawn.y, point.Spawn.z)) <= 35 then
                            return true
                        end
                    end
                end
                return false
            end,
            onSelect = function(data)
                local vehicle = data.entity
                if not DoesEntityExist(vehicle) then return end

                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local vehicleCoords = GetEntityCoords(vehicle)
                -- Spawn fuel pump attendant ped
                local pedModel = `s_m_y_winclean_01`
                lib.requestModel(pedModel)

                local forwardVector = GetEntityForwardVector(vehicle)
                local angle = 105 * math.pi / 180
                local swVector = vector3(
                    forwardVector.x * math.cos(angle) - forwardVector.y * math.sin(angle),
                    forwardVector.x * math.sin(angle) + forwardVector.y * math.cos(angle),
                    0
                )
                local spawnCoords
                local retval, groundZ, _ = GetGroundZAndNormalFor_3dCoord(vehicleCoords.x, vehicleCoords.y,
                    vehicleCoords.z)
                if retval == 1 then
                    spawnCoords = vehicleCoords + (swVector * 2)
                    spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
                else
                    spawnCoords = vehicleCoords + (swVector * 2) + vector3(0, 0, -0.45)
                end
                --local spawnCoords = vehicleCoords + (swVector * 2) + vector3(0, 0, zHeight)
                --print("Coordenadas de spawn del peón calculadas" .. tostring(spawnCoords))
                local attendant = CreatePed(4, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z,
                    GetEntityHeading(vehicle) - 90, true, false)
                SetBlockingOfNonTemporaryEvents(attendant, true)
                FreezeEntityPosition(attendant, true)
                SetEntityInvincible(attendant, true)
                -- Load and play fuel animation
                TaskStartScenarioInPlace(attendant, 'WORLD_HUMAN_MAID_CLEAN', 0, true)

                Wait(5 * 1000)

                -- Cleaning

                Notify('Vehículo limpio y reluciente', 'success')
                SetVehicleDirtLevel(vehicle, 0)

                -- Cleanup
                ClearPedTasks(attendant)
                DeleteEntity(attendant)
            end
        },
    })
end

OnPlayerLoaded(function()
    vehicleActions()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if IsLoggedIn() then vehicleActions() end
    end
end)
