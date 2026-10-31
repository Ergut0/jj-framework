CreateThread(function()
    while true do
        local isInMeleeCombat = IsPedInMeleeCombat(cache.ped)
        local isInWeaponAiming = IsPlayerFreeAiming(PlayerId())
        
        if isInWeaponAiming or isInMeleeCombat then 
            local ped, coords = lib.getClosestPed(GetEntityCoords(cache.ped), 2.0)
            if ped then 
                local pedType = GetPedType(ped) 
                if pedType ~= 28 and pedType ~= 27 and pedType ~= 6 and pedType ~= 29 then
                    local currentWeapon = GetSelectedPedWeapon(cache.ped)
                    local playerJob = GetPlayerData().job.name     
                    if currentWeapon ~= GetHashKey('WEAPON_UNARMED') and playerJob ~= 'police' and playerJob ~= 'sheriff' then
                        HelpNotify("Someter a la persona") 
                        if IsControlJustPressed(0, 38) then

                            if not Entity(ped).state.isPoliceNotified then 
                                -- La categoria "police" de origen_police ya incluye police y sheriff
                                TriggerServerEvent("SendAlert:police", {
                                    coords = GetEntityCoords(cache.ped),
                                    title = "Secuestro de persona",
                                    message = "Estoy viendo como secuestran a una persona, estan con un arma y parece que la estan sometiendo... Ayuda por favor, se aleja de la zona",
                                    type = "GENERAL",
                                    job = "police"
                                })
                                Entity(ped).state.isPoliceNotified = true
                            end

                            SetEntityAsMissionEntity(ped, true, true)
                            SetPedFleeAttributes(ped, 0, 0)
                            SetPedCombatAttributes(ped, 17, 1)
                            SetPedCombatAttributes(ped, 46, 1)
                            SetBlockingOfNonTemporaryEvents(ped, true)
                            SetPedCanRagdoll(ped, false)
                            TaskStandStill(ped, -1)
                            
                            if not following then following = {} end
                            if following[ped] == nil then following[ped] = false end

                            lib.registerMenu({
                                id = 'hostage_menu',
                                title = 'PERSONA SOMETIDA',
                                position = 'bottom-right',
                                options = {
                                    {
                                        label = (following[ped] and 'Dejar de seguirte' or 'Hacer que te siga'),
                                        icon = (following[ped] and 'fa-person-walking-dashed-line-arrow-right' or 'fa-person-walking')
                                    },
                                    {
                                        label = 'Poner de rodillas',
                                        icon = 'fa-person-praying'
                                    },
                                    {
                                        label = 'Liberar',
                                        icon = 'fa-unlock'
                                    },
                                },
                            }, function(selected, scrollIndex, args)
                                if selected == 1 then 
                                    following[ped] = not following[ped]
                                    lib.notify({
                                        description = (following[ped] and 'La persona te está siguiendo' or 'La persona ha dejado de seguirte'),
                                        type = 'success'
                                    })
                                    if following[ped] then
                                        ClearPedTasks(ped)
                                        CreateThread(function()
                                            while following[ped] and DoesEntityExist(ped) do
                                                local playerVeh = GetVehiclePedIsIn(cache.ped, false)
                                                if playerVeh ~= 0 then
                                                    local pedVeh = GetVehiclePedIsIn(ped, false)
                                                    if pedVeh == 0 then
                                                        local seat = GetVehicleMaxNumberOfPassengers(playerVeh)
                                                        for i = 0, seat do
                                                            if i ~= -1 and IsVehicleSeatFree(playerVeh, i) then
                                                                TaskEnterVehicle(ped, playerVeh, -1, i, 2.0, 1, 0)
                                                                break
                                                            end
                                                        end
                                                    end
                                                else
                                                    local pedVeh = GetVehiclePedIsIn(ped, false)
                                                    if pedVeh ~= 0 then
                                                        TaskLeaveVehicle(ped, pedVeh, 0)
                                                    else
                                                        TaskGoToEntity(ped, cache.ped, -1, 2.0, 2.0, 1073741824, 0)
                                                    end
                                                end
                                                Wait(1000)
                                            end
                                        end)
                                    else
                                        ClearPedTasks(ped)
                                        TaskStandStill(ped, -1)
                                    end
                                elseif selected == 2 then
                                    lib.notify({
                                        description = 'La persona ha sido puesta de rodillas',
                                        type = 'success'
                                    })
                                    following[ped] = false
                                    lib.requestAnimDict('random@arrests')
                                    TaskPlayAnim(ped, 'random@arrests', 'kneeling_arrest_idle', 8.0, 1.0, -1, 2, 0, 0, 0, 0)
                                elseif selected == 3 then
                                    lib.notify({
                                        description = 'La persona ha sido liberada',
                                        type = 'success'
                                    })
                                    following[ped] = false
                                    ClearPedTasksImmediately(ped)
                                    SetBlockingOfNonTemporaryEvents(ped, false)
                                    SetPedCanRagdoll(ped, true)
                                    SetPedFleeAttributes(ped, 0, 1)
                                    TaskSmartFleePed(ped, cache.ped, 200.0, -1, false, false)
                                    SetEntityAsNoLongerNeeded(ped)
                                end
                            end)
                            lib.showMenu('hostage_menu')
                        end
                    end
                end
            end
        end 
        Wait(1)
    end
end)