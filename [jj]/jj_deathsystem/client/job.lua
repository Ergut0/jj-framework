local targetPoints = {}
local points = {}
local blipsCreated = false

local function HelpNotify(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function SpawnJobVehicle(model, cb, coords)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        Notify("El vehículo no está instalado", "error")
        return
    end
    lib.requestModel(hash)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    cb(veh)
end

local function DeleteJobVehicle(veh)
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
end

local function VehicleExtras()
    if not cache.vehicle then return end
    lib.registerMenu({
        id = 'vehicle_extras_menu',
        title = 'Modificacion de vehículo',
        position = 'bottom-right',
        options = {
            {label = 'Extras', description = 'Cambia los extras del vehículo', icon = 'fa-solid fa-car', args = {type = 'extras'}},
        },
    }, function(selected, scrollIndex, args)
        if selected == 1 then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local elements = {}

            for extra = 1, 11 do
                local val = 0
                if IsVehicleExtraTurnedOn(vehicle, extra) then
                    val = 1
                end
                elements[#elements+1] = {
                    icon = 'car',
                    label = 'EXTRA ' .. extra,
                    description = 'Activa o desactiva el extra',
                    args = {extra = extra},
                    close = false,
                    checked = val == 1
                }
            end

            lib.registerMenu({
                id = 'vehicle_extras',
                title = 'Extras del vehículo',
                position = 'bottom-right',
                options = elements,
                onCheck = function(selected, secondary, args)
                    local vehicleFuel = GetVehicleFuelLevel(vehicle)
                    local vehicleDamage = GetVehicleEngineHealth(cache.vehicle)
                    SetVehicleEngineHealth(cache.vehicle, vehicleDamage + 0.0)
                    SetVehicleExtra(cache.vehicle, args.extra, not secondary)
                    SetVehicleFuelLevel(cache.vehicle, vehicleFuel)
                end,
                onClose = function()
                    lib.showMenu('vehicle_extras_menu')
                end
            })
            lib.showMenu('vehicle_extras')
        end
    end)
    lib.showMenu('vehicle_extras_menu')
end

local function OpenListVehicles(spawnCoords)
    local listVehicles = {}
    for k, v in pairs(Config.ListVehicles) do
        listVehicles[#listVehicles+1] = {
            icon = "fas fa-car",
            title = GetDisplayNameFromVehicleModel(GetHashKey(v)),
            description = "Sacar vehículo",
            args = {model = v},
            arrow = true,
            onSelect = function(args)
                SpawnJobVehicle(args.model, function(veh)
                    SetVehicleFuelLevel(veh, 100.0)
                    Entity(veh).state:set('HotWire', 'StopNeedHotWire', true)
                end, spawnCoords)
            end,
        }
    end
    lib.registerContext({
        id = 'car_menu',
        title = 'Lista de coches',
        menu = 'car_menu',
        options = listVehicles,
    })
    lib.showContext('car_menu')
end

local function OpenListHelicopters(spawnCoords)
    local listHelicopters = {}
    for k, v in pairs(Config.ListHelicopters) do
        listHelicopters[#listHelicopters+1] = {
            icon = "fas fa-car",
            title = GetDisplayNameFromVehicleModel(GetHashKey(v)),
            description = "Sacar vehículo",
            args = {model = v},
            arrow = true,
            onSelect = function(args)
                SpawnJobVehicle(args.model, function(veh)
                    SetVehicleFuelLevel(veh, 100.0)
                    Entity(veh).state:set('HotWire', 'StopNeedHotWire', true)
                end, spawnCoords)
            end,
        }
    end
    lib.registerContext({
        id = 'helicopter_menu',
        title = 'Lista de helicópteros',
        menu = 'helicopter_menu',
        options = listHelicopters,
    })
    lib.showContext('helicopter_menu')
end

local function OpenListBoats(spawnCoords)
    local listBoats = {}
    for k, v in pairs(Config.ListBoats) do
        listBoats[#listBoats+1] = {
            icon = "fas fa-car",
            title = GetDisplayNameFromVehicleModel(GetHashKey(v)),
            description = "Sacar vehículo",
            args = {model = v},
            arrow = true,
            onSelect = function(args)
                SpawnJobVehicle(args.model, function(veh)
                    SetVehicleFuelLevel(veh, 100.0)
                    Entity(veh).state:set('HotWire', 'StopNeedHotWire', true)
                end, spawnCoords)
            end,
        }
    end
    lib.registerContext({
        id = 'boat_menu',
        title = 'Lista de barcos',
        menu = 'boat_menu',
        options = listBoats,
    })
    lib.showContext('boat_menu')
end

local function OpenCloakroom()
    lib.registerContext({
        id = 'cloakroom_menu',
        title = 'Vestuario',
        menu = 'cloakroom_menu',
        options = {
            {
                title = "Abrir ropero personal",
                description = "Abre el ropero para cambiarte de ropa",
                onSelect = function()
                    TriggerEvent("illenium-appearance:client:openClothingShopMenu")
                end,
                icon = "fas fa-tshirt",
                arrow = true,
            },
            {
                title = "Abrir taquilla personal",
                description = "Abre la taquilla para guardar tus pertenencias",
                onSelect = function()
                    local PlayerData = JJ.GetPlayerData()
                    exports.ox_inventory:openInventory('stash', PlayerData.identifier .. "-personal")
                end,
                icon = "fa-solid fa-warehouse",
                arrow = true,
            },
            {
                title = "Abrir ropero de trabajo",
                description = "Abre el ropero para cambiarte de ropa",
                onSelect = function()
                    TriggerEvent("illenium-apearance:client:outfitsCommand", "ambulance")
                end,
                icon = "fas fa-tshirt",
                arrow = true,
            }
        },
    })
    lib.showContext('cloakroom_menu')
end

local function OpenBossMenu()
    local PlayerData = JJ.GetPlayerData()
    if not PlayerData or not PlayerData.job.isBoss then
        return 
    end

    lib.registerContext({
        id = 'boss_menu',
        title = 'Menú de jefe',
        menu = 'boss_menu',
        options = {
            {
                title = "Administrar personal",
                description = "Gestiona el personal del hospital",
                onSelect = function()
                    local emps = lib.callback.await('jj_deathsystem:callback:getEmployees', false) 
                    local options = {}

                    for _, emp in pairs(emps) do
                        options[#options + 1] = {
                            title = emp.name,
                            description = "Rango: " .. emp.gradeLabel,
                            onSelect = function(self)
                                lib.registerContext({
                                    id = 'employee_actions',
                                    title = 'Acciones de empleado',
                                    menu = 'employee_actions',
                                    options = {
                                        {
                                            title = "Ascender",
                                            description = "Asciende al empleado",
                                            onSelect = function()
                                                local job = JJ.Config.Jobs["ambulance"]
                                                local options = {}
                                                for level, grade in pairs(job.grades) do
                                                    if level > emp.grade then
                                                        options[#options + 1] = {
                                                            title = grade.label,
                                                            description = "Asciende al empleado a " .. grade.label,
                                                            onSelect = function()
                                                                TriggerServerEvent("jj_deathsystem:server:setEmployeeGrade", emp.identifier, level)
                                                            end,
                                                            icon = "fa-solid fa-arrow-up",
                                                            arrow = true,
                                                        }
                                                    end
                                                end
                                                lib.registerContext({
                                                    id = 'promote_employee',
                                                    title = 'Ascender empleado',
                                                    menu = 'promote_employee',
                                                    options = options,
                                                })
                                                lib.showContext('promote_employee')
                                            end,
                                            icon = "fa-solid fa-arrow-up",
                                            arrow = true,
                                        },
                                        {
                                            title = "Descender",
                                            description = "Desciende al empleado",
                                            onSelect = function()
                                                local job = JJ.Config.Jobs["ambulance"]
                                                local options = {}
                                                for level, grade in pairs(job.grades) do
                                                    if level < emp.grade then
                                                        options[#options + 1] = {
                                                            title = grade.label,
                                                            description = "Desciende al empleado a " .. grade.label,
                                                            onSelect = function()
                                                                TriggerServerEvent("jj_deathsystem:server:setEmployeeGrade", emp.identifier, level)
                                                            end,
                                                            icon = "fa-solid fa-arrow-down",
                                                            arrow = true,
                                                        }
                                                    end
                                                end
                                                lib.registerContext({
                                                    id = 'demote_employee',
                                                    title = 'Descender empleado',
                                                    menu = 'demote_employee',
                                                    options = options,
                                                })
                                                lib.showContext('demote_employee')
                                            end,
                                            icon = "fa-solid fa-arrow-down",
                                            arrow = true,
                                        },
                                        {
                                            title = "Despedir",
                                            description = "Despide al empleado",
                                            onSelect = function()
                                                TriggerServerEvent("jj_deathsystem:server:firePlayer", emp.identifier)
                                            end,
                                            icon = "fa-solid fa-trash",
                                            arrow = true,
                                        }
                                    },
                                })
                                lib.showContext('employee_actions')
                            end,
                            icon = "fa-solid fa-user",
                            arrow = true,
                        }
                    end

                    lib.registerContext({
                        id = 'manage_employees',
                        title = 'Gestionar personal',
                        menu = 'manage_employees',
                        options = options,
                    })
                    lib.showContext('manage_employees')
                end,
                icon = "fa-solid fa-users",
                arrow = true,
            },
            {
                title = "Contratar personal",
                description = "Contrata a un nuevo miembro del personal",
                onSelect = function()
                    local input = lib.inputDialog("Contratar personal", {
                        {type = "number", label = "ID del Player", required = true},
                    })
                    if input and input[1] then
                        TriggerServerEvent("jj_deathsystem:server:hirePlayer", input[1])
                    end
                end,
                icon = "fa-solid fa-user-plus",
                arrow = true,
            }
        },
    })
    lib.showContext('boss_menu')
end

local function createPoints()
    local PlayerData = JJ.GetPlayerData()

    if not PlayerData or PlayerData.job.name ~= "ambulance" then
        return
    end

    if not next(Config.Points) then return end  

    for k, info in pairs(Config.Points) do

        if k == "dutyPoints" then
            for _, v in pairs(info) do
                local tPoint = exports.ox_target:addSphereZone({
                    coords = v.coords,
                    radius = 1.5,
                    debug = false,
                    drawSprite = true,
                    options = {
                        label = "Entrar/Salir de servicio",
                        icon = "fa-solid fa-user-doctor",
                        distance = 1.5,
                        onSelect = function(data)
                            TriggerServerEvent("jj_deathsystem:server:toggleDuty")
                        end
                    }
                })

                targetPoints[#targetPoints + 1] = tPoint
            end
        end

        if k == "cloakRooms" then
            for _, v in pairs(info) do
                local tPoint = exports.ox_target:addSphereZone({
                    coords = v.coords,
                    radius = 1.5,
                    debug = false,
                    drawSprite = true,
                    options = {
                        label = "Ropero",
                        icon = "fa-solid fa-tshirt",
                        distance = 1.5,
                        onSelect = function(data)
                            OpenCloakroom()
                        end
                    }
                })

                targetPoints[#targetPoints + 1] = tPoint
            end
        end

        if PlayerData.job.onDuty then
            if k == "inventory" then
                for _, v in pairs(info) do
                    local tPoint = exports.ox_target:addSphereZone({
                        coords = v.coords,
                        radius = 1.5,
                        debug = false,
                        drawSprite = true,
                        options = {
                            label = "Abrir inventario",
                            icon = "fa-solid fa-box-open",
                            distance = 1.5,
                            onSelect = function(data)
                                if v.type == "inventory" then
                                    exports.ox_inventory:openInventory('stash', v.name)
                                elseif v.type == "shop" then
                                    exports.ox_inventory:openInventory("shop", {type = v.name})
                                end
                            end
                        }
                    })
                    targetPoints[#targetPoints + 1] = tPoint
                end
            end


            if k == "extras" then
                for _, v in pairs(info) do
                    local point = lib.points.new({
                        coords = v.coords,
                        distance = 3.0,
                        nearby = function(data)
                            HelpNotify("Menú de extras")
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then return end
                                VehicleExtras()
                            end
                        end,
                    })
                    points[#points + 1] = point
                end
            end

            if k == "vehicles" then
                for _, v in pairs(info) do
                    local point = lib.points.new({
                        coords = v.coords,
                        distance = 4.0,
                        nearby = function(data)
                            HelpNotify("Menú de vehículos")
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then
                                    OpenListVehicles(v.coords)
                                else
                                    DeleteJobVehicle(cache.vehicle)
                                end
                            end
                        end,
                    })
                    points[#points + 1] = point
                end
            end

            if k == "helicopters" then
                for _, v in pairs(info) do
                    local point = lib.points.new({
                        coords = v.coords,
                        distance = 4.0,
                        nearby = function(data)
                            HelpNotify("Menú de helicópteros")
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then
                                    OpenListHelicopters(v.coords)
                                else
                                    DeleteJobVehicle(cache.vehicle)
                                end
                            end
                        end,
                    })
                    points[#points + 1] = point
                end
            end

            if k == "boats" then
                for _, v in pairs(info) do
                    local point = lib.points.new({
                        coords = v.coords,
                        distance = 4.0,
                        nearby = function(data)
                            HelpNotify("Menú de barcos")
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then
                                    OpenListBoats(v.coords)
                                else
                                    DeleteJobVehicle(cache.vehicle)
                                end
                            end
                        end,
                    })
                    points[#points + 1] = point
                end
            end

            if k == "bossPoints" then
                for _, v in pairs(info) do
                    local tPoint = exports.ox_target:addSphereZone({
                        coords = v.coords,
                        radius = 1.5,
                        debug = false,
                        drawSprite = true,
                        options = {
                            label = "Abrir menú de jefe",
                            icon = "fa-solid fa-briefcase",
                            distance = 1.5,
                            onSelect = function(data)
                                OpenBossMenu()
                            end
                        }
                    })

                    targetPoints[#targetPoints + 1] = tPoint
                end
            end

        end
    end
end

local refreshPoints = function()
    if next(points) then
        for _, point in pairs(points) do
            point:remove()
        end
        points = {}
    end

    if next(targetPoints) then
        for _, tPoint in pairs(targetPoints) do
            exports.ox_target:removeZone(tPoint)
        end
        targetPoints = {}
    end

    Wait(500)
    createPoints()
end

local function reviveJob()
    local playerCId, playerPed, playerCoords = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.5)
    if not playerCId then
        lib.notify({
            description = 'No hay jugadores cerca',
            type = 'error',
            duration = 5000,
            icon = 'fa-solid fa-xmark',
        })
        return
    end
    local playerid = GetPlayerServerId(playerCId)
    local isDead = Player(playerid).state.isDead
    local isLastStand = Player(playerid).state.isLastStand

    if isDead or isLastStand then
        if lib.progressCircle({
            duration = 5000,
            position = 'bottom',
            label = 'Tratando al herido',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = false,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = 'mini@cpr@char_a@cpr_str',
                clip = 'cpr_pumpchest',
                flag = 1,
            },
        }) then
            TriggerServerEvent("jj_deathsystem:server:revive", playerid)
            lib.notify({
                description = 'El herido ha sido tratado',
                type = 'inform',
                duration = 5000,
                icon = 'fa-solid fa-kit-medical',
            })
        end
    else
        if lib.progressCircle({
            duration = 5000,
            position = 'bottom',
            label = 'Tratando al herido',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = false,
                combat = true,
                mouse = false,
            },
            anim = {
                dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                clip = "weed_spraybottle_crouch_spraying_02_inspector",
                flag = 49,
            },
        }) then
            TriggerServerEvent("jj_deathsystem:server:adminHeal", playerid)
            lib.notify({
                description = 'El herido ha sido tratado',
                type = 'inform',
                duration = 5000,
                icon = 'fa-solid fa-kit-medical',
            })
        end
    end
end

RegisterCommand("revivep", function()
    local PlayerData = JJ.GetPlayerData()
    if not PlayerData or PlayerData.job.name ~= "ambulance" then
        return
    end
    if PlayerData.job.onDuty then
        reviveJob()
    end
end, false)


local function reviveTarget()
    -- ox_target es opcional: sin él, los médicos usan /revivep
    if GetResourceState('ox_target') ~= 'started' then
        return
    end
    exports.ox_target:removeGlobalPlayer('revive_player')
    local PlayerData = JJ.GetPlayerData()
    if PlayerData and PlayerData.job.name == "ambulance" and PlayerData.job.onDuty then
        exports.ox_target:addGlobalPlayer({
            {
                name = 'revive_player',
                icon = "fa-solid fa-kit-medical",
                label = "Tratar al herido",
                distance = 1.5,
                onSelect = function(data)
                    local player = NetworkGetPlayerIndexFromPed(data.entity)
                    local playerid = GetPlayerServerId(player)
                    local isDead = Player(playerid).state.isDead
                    local isLastStand = Player(playerid).state.isLastStand

                    if isDead or isLastStand then 
                        if lib.progressCircle({
                            duration = 5000,
                            position = 'bottom',
                            label = 'Tratando al herido',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = false,
                                combat = true,
                                mouse = false,
                            },
                            anim = {
                                dict = 'mini@cpr@char_a@cpr_str',
                                clip = 'cpr_pumpchest',
                                flag = 1,
                            },
                        }) then
                            TriggerServerEvent("jj_deathsystem:server:revive", playerid)
                            lib.notify({
                                description = 'El herido ha sido tratado',
                                type = 'inform',
                                duration = 5000,
                                icon = 'fa-solid fa-kit-medical',
                            })
                        end
                    else
                        if lib.progressCircle({
                            duration = 5000,
                            position = 'bottom',
                            label = 'Tratando al herido',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = false,
                                combat = true,
                                mouse = false,
                            },
                            anim = {
                                dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                                clip = "weed_spraybottle_crouch_spraying_02_inspector",
                                flag = 49,
                            },
                        }) then
                            TriggerServerEvent("jj_deathsystem:server:adminHeal", playerid)
                            lib.notify({
                                description = 'El herido ha sido tratado',
                                type = 'inform',
                                duration = 5000,
                                icon = 'fa-solid fa-kit-medical',
                            })
                        end
                    end
                end,
            },
        })
    end
end

local function CreateBlips()
    if blipsCreated then return end
    blipsCreated = true
    for k, v in pairs(Config.Info["blips"]) do
        local blip = AddBlipForCoord(v.coords)
        SetBlipSprite(blip, 61)
        SetBlipDisplay(blip, 6)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v.name)
        EndTextCommandSetBlipName(blip)
    end
end

-- jj-framework avisa con la clave 'job' tanto de los cambios de trabajo como de los de servicio
AddEventHandler('jj:client:playerDataChanged', function(key)
    if key ~= 'job' then
        return
    end
    refreshPoints()
    reviveTarget()
    TriggerServerEvent("jj_deathsystem:createPersonalStash")
end)

OnPlayerReady(function()
    refreshPoints()
    reviveTarget()
    CreateBlips()
    TriggerServerEvent("jj_deathsystem:createPersonalStash")
end)
