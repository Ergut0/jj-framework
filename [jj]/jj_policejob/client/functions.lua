local ox_inventory = exports.ox_inventory

local OpenArmory = function(typeRec)
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job or (PlayerData.job.grade and PlayerData.job.grade.level == 1) then
        Notify("No tienes rango suficiente para acceder a la armería", "error")
        return
    end

    lib.registerContext({
        id = 'armory_menu',
        title = 'Lista de armas',
        menu = 'armory_menu',
        options = {
            {
                title = "Abrir taquilla personal",
                description = "Abre la taquilla para guardar tus pertenencias",
                onSelect = function()
                    local PlayerData = GetPlayerData()
                    Inventory:openInventory('stash', PlayerData.citizenid .. "-personal")
                end,
                icon = "fa-solid fa-warehouse",
                arrow = true,
            },
            {
                title = "Recibir equipamiento basico",
                description = "Recibe el equipamiento basico para empezar a patrullar",
                onSelect = function()
                    TriggerServerEvent('jj_policejob:server:giveBasicEquipment')
                end,
                icon = "fas fa-box-open",
                arrow = true,
            },
            {
                title = "Abrir Armeria",
                description = "Abre la armeria donde se encuentra todo el equipamiento policial",
                onSelect = function()
                    Inventory:openInventory("shop", { type = typeRec })
                end,
                icon = "fa-gun",
                arrow = true,
            },
            {
                title = "Guardar equipamiento",
                description = "Guarda el equipamiento que llevas encima",
                onSelect = function()
                    TriggerServerEvent('jj_policejob:server:saveEquipment')
                end,
                icon = "fa-floppy-disk",
                arrow = true,
            },
            {
                title = "Papelera",
                description = "Deja lo que no uses en la papelera",
                onSelect = function()
                    TriggerServerEvent("jj_policejob:server:OpenTrash")
                end,
                icon = "fa-trash",
                arrow = true,
            },
        },
    })
    lib.showContext('armory_menu')
end

local OpenDivisionsArmory = function(typeRec, allowedDivisions)
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job or (PlayerData.job.grade and PlayerData.job.grade.level == 0) then
        Notify("No tienes rango suficiente para acceder a la armería", "error")
        return
    end

    local divisions = PlayerData.metadata.divisions or {}
    local canOpen = PlayerData.job.isboss
    if not canOpen then
        for _, v in pairs(allowedDivisions) do
            for _, d in pairs(divisions) do
                if v == d then
                    canOpen = true
                    break
                end
            end
            if canOpen then break end
        end
    end
    if not canOpen then
        Notify("No tienes acceso a esta armería", "error")
        return
    end
    lib.registerContext({
        id = 'armory_divisions_menu',
        title = 'Lista de armas',
        menu = 'armory_divisions_menu',
        options = {
            {
                title = "Abrir armeria de divisiones",
                description = "Abre la armeria donde se encuentra el equipamiento especial de divisiones",
                onSelect = function()
                    Inventory:openInventory("shop", { type = typeRec })
                end,
                icon = "fa-gun",
                arrow = true,
            },
            {
                title = "Papelera",
                description = "Deja lo que no uses en la papelera",
                onSelect = function()
                    TriggerServerEvent("jj_policejob:server:OpenTrash")
                end,
                icon = "fa-trash",
                arrow = true,
            },
            {
                title = "Cambiar tinte del arma",
                description = "Cambia el tinte del arma que llevas equipada",
                onSelect = function()
                    --local tintTextTable = { [0] = "Tinte por defecto", [1] = "Tinte 1", [2] = "Tinte 2", [3] = "Tinte 3", [4] = "Tinte 4", [5] = "Tinte 5", [6] = "Tinte 6", [7] = "Tinte 7" }

                    local weapon = exports.ox_inventory:getCurrentWeapon()
                    if weapon == nil or weapon == 0 then
                        Notify("No tienes un arma equipada", "error")
                        return
                    end
                    if not Config.weaponTints[weapon.name] then
                        Notify("El arma equipada no tiene tintes disponibles", "error")
                        return
                    end

                    local PlayerData = GetPlayerData()
                    local availableTints = Config.weaponTints[weapon.name]
                    local formattedTints = {}

                    for k, v in pairs(availableTints) do
                        --print("Available tint: " .. tostring(k) .. " - " .. tostring(v.label) .. "required rank: " .. tostring(v.requiredRank))
                        if not v.requiredRank or PlayerData.job.grade.level >= v.requiredRank then
                            table.insert(formattedTints, v)
                        end
                    end
                    local input = lib.inputDialog("armoryTintIndex",
                        { { type = 'select', label = 'Índice de Tinte', options = formattedTints, required = true, icon = 'fa-palette' } })
                    if input then
                        --print("Selected tint index: " .. tostring(input[1]))
                        SetPedWeaponTintIndex(cache.ped, weapon.hash, input[1])
                    end
                end,
                icon = "fa-palette",
                arrow = true,
            }
        },
    })
    lib.showContext('armory_divisions_menu')
end


local OpenCloakroom = function()
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
                    local PlayerData = GetPlayerData()
                    Inventory:openInventory('stash', PlayerData.citizenid .. "-personal")
                end,
                icon = "fa-solid fa-warehouse",
                arrow = true,
            },
            {
                title = "Abrir ropero de trabajo",
                description = "Abre el ropero para cambiarte de ropa",
                onSelect = function()
                    TriggerEvent("illenium-apearance:client:outfitsCommand", "police")
                end,
                icon = "fas fa-tshirt",
                arrow = true,
            }
        },
    })
    lib.showContext('cloakroom_menu')
end

local OpenCallSignMenu = function()
    local badge = ("%s%s%s"):format(
        GetVehicleMod(cache.vehicle, 42),
        GetVehicleMod(cache.vehicle, 43),
        GetVehicleMod(cache.vehicle, 44)
    )

    local currentPrecinct = GetVehicleMod(cache.vehicle, 2)
    local precinctDefault = "07"
    if currentPrecinct and currentPrecinct >= 0 then
        precinctDefault = ("%02d"):format(currentPrecinct)
    end

    local input = lib.inputDialog("PERSONALIZACIÓN", {
        { type = 'input',    label = "Numero de placa (000)",         max = 999,        required = true,                                                                 default = badge,    icon = "fa-solid fa-id-badge" },
        { type = 'input',    label = "Numero de comisaria",           disabled = false, default = precinctDefault,                                                       placeholder = "07", icon = "fa-solid fa-id-badge" },
        { type = 'select',   label = "Color del número de placa",     default = 1,      options = { { label = "Negro", value = 1 }, { label = "Blanco", value = 111 } }, required = true,    icon = "fa-solid fa-paint-roller" },
        { type = 'select',   label = "Color del número de comisaría", default = 111,    options = { { label = "Negro", value = 1 }, { label = "Blanco", value = 111 } }, required = true,    icon = "fa-solid fa-paint-roller" },
        { type = 'checkbox', label = "Supervisor",                    required = false, icon = "fa-solid fa-user-shield" },
    }, "md")

    if input then
        local badgeNum = tostring(input[1])
        local precinctNum = tostring(input[2])
        local badgeColor = input[3]
        local pdColor = input[4]
        local isSupervisor = input[5] and true or false

        if #badgeNum == 1 then
            badgeNum = "00" .. badgeNum
        elseif #badgeNum == 2 then
            badgeNum = "0" .. badgeNum
        end

        SetVehicleModKit(cache.vehicle, 0)
        SetVehicleMod(cache.vehicle, 42, tonumber(badgeNum:sub(1, 1)), false)
        SetVehicleMod(cache.vehicle, 43, tonumber(badgeNum:sub(2, 2)), false)
        SetVehicleMod(cache.vehicle, 44, tonumber(badgeNum:sub(3, 3)), false)

        SetVehicleDashboardColor(cache.vehicle, badgeColor)
        SetVehicleInteriorColor(cache.vehicle, pdColor)

        SetVehicleMod(cache.vehicle, 1, 0, false)
        local pNum = tonumber(precinctNum) or 7
        SetVehicleMod(cache.vehicle, 2, pNum, false)
        if isSupervisor then
            SetVehicleMod(cache.vehicle, 8, 1, false)
            SetVehicleMod(cache.vehicle, 9, 1, false)
        else
            SetVehicleMod(cache.vehicle, 8, -1, false)
            SetVehicleMod(cache.vehicle, 9, -1, false)
        end
    end
end

local OpenIncautions = function()
    lib.registerContext({
        id = 'incautions_menu',
        title = 'Incautaciones',
        menu = 'incautions_menu',
        options = {
            {
                title = "Abrir armario de incautaciones",
                description = "Abre la taquilla de incautaciones para guardar los objetos incautados",
                onSelect = function()
                    Inventory:openInventory("policeevidence")
                end,
                icon = "fas fa-box-open",
                arrow = true,
            },
        },
    })
    lib.showContext('incautions_menu')
end

local extrasMenus = { vehicle_extras_menu = true, vehicle_extras = true, liveries_menu = true }
local extrasFrozen = false
local callSignOpen = false

local FreezeWhileInExtras = function(vehicle)
    if extrasFrozen then return end
    extrasFrozen = true
    FreezeEntityPosition(vehicle, true)

    CreateThread(function()
        local closedTicks = 0
        while closedTicks < 5 and cache.vehicle == vehicle do
            if extrasMenus[lib.getOpenMenu()] or callSignOpen then
                closedTicks = 0
            else
                closedTicks += 1
            end
            Wait(100)
        end

        FreezeEntityPosition(vehicle, false)
        extrasFrozen = false
    end)
end

local VehicleExtras = function()
    if not cache.vehicle then return end
    FreezeWhileInExtras(cache.vehicle)
    lib.registerMenu({
        id = 'vehicle_extras_menu',
        title = 'Modificacion de vehículo',
        position = 'bottom-right',
        options = {
            { label = 'Extras',    description = 'Cambia los extras del vehículo',       icon = 'fa-solid fa-car', args = { type = 'extras' } },
            { label = 'Liveries',  description = 'Cambia las liveries del vehículo',     icon = 'fa-solid fa-car', args = { type = 'livery' } },
            { label = 'Callsigns', description = 'Cambia la informacion de tu vehículo', icon = 'fa-solid fa-car', args = { type = 'callsign' } },
        },
    }, function(selected, scrollIndex, args)
        if selected == 1 then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local elements = {}

            for extra = 1, 12 do
                local val = 0
                if IsVehicleExtraTurnedOn(vehicle, extra) then
                    val = 1
                end
                elements[#elements + 1] = {
                    icon = 'car',
                    label = 'EXTRA ' .. extra,
                    description = 'Activa o desactiva el extra',
                    args = { extra = extra },
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
        elseif selected == 2 then
            lib.registerMenu({
                id = 'liveries_menu',
                title = 'Liveries del vehículo',
                position = 'bottom-right',
                options = {
                    { label = 'Selecciona un livery', icon = 'arrows-up-down-left-right', values = { 'LSPD', 'BCSD', 'SAHP', 'TROOPERS', 'UNMARKED' } },
                },
                onSideScroll = function(selected, scrollIndex, args)
                    local livery = scrollIndex - 1
                    SetVehicleModKit(cache.vehicle, 0)
                    SetVehicleLivery(cache.vehicle, livery)
                    SetVehicleMod(cache.vehicle, 48, livery, false)
                end,
                onClose = function()
                    lib.showMenu('vehicle_extras_menu')
                end
            })
            lib.showMenu('liveries_menu')
        elseif selected == 3 then
            callSignOpen = true
            OpenCallSignMenu()
            callSignOpen = false
        end
    end)
    lib.showMenu('vehicle_extras_menu')
end

local OpenDepot = function(coordsSpawn)
    local vehicles = lib.callback.await('jj_policejob:GetVehiclesInDepot', false)
    if not vehicles then return end
    local listVehicles = {}

    for k, v in pairs(vehicles) do
        listVehicles[#listVehicles + 1] = {
            icon = "fas fa-car",
            title = ('%s - %s'):format(v.vehicle, v.plate),
            description = "Sacar vehículo",
            arrow = true,
            onSelect = function()
                SpawnVehicle(v.vehicle, function(veh)
                    local mods = v.mods and json.decode(v.mods)
                    SetVehicleFuelLevel(veh, 100.0)
                    if mods then lib.setVehicleProperties(veh, mods) end
                    SetVehicleNumberPlateText(veh, v.plate)
                    TriggerServerEvent("jj_policejob:server:updateStateVehicle", 0, v.plate, false)
                end, coordsSpawn, true)
            end,
        }
    end

    lib.registerContext({
        id = 'depot_menu',
        title = 'Deposito de vehículos',
        options = listVehicles,
    })
    lib.showContext('depot_menu')
end

local OpenAscensor = function(info)
    local plantasAscensor = {}

    for k, plantas in pairs(info) do
        plantasAscensor[#plantasAscensor + 1] = {
            title = plantas.label,
            arrow = true,
            icon = 'fa-solid fa-layer-group',
            description = 'Usar el ascensor',
            onSelect = function()
                DoScreenFadeOut(1000)
                while not IsScreenFadedOut() do
                    Wait(100)
                end
                Wait(1000)
                SetEntityCoords(PlayerPedId(), plantas.coords.x, plantas.coords.y, plantas.coords.z - 1)
                SetEntityHeading(PlayerPedId(), plantas.coords.w)
                DoScreenFadeIn(1000)
            end
        }
    end
    lib.registerContext({
        id = 'tp_menu',
        title = 'Ascensor',
        options = plantasAscensor,
    })
    lib.showContext('tp_menu')
end

local OpenBossMenu = function()
    local isBoss = GetPlayerData().job.grade.isboss
    if not isBoss then
        Notify('No tienes permisos para acceder a este menú', 'error')
        return
    end
    lib.registerContext({
        id = 'boss_menu',
        title = 'Menu de jefe',
        options = {
            {
                icon = 'fa-solid fa-user-tie',
                title = 'Contratar empleado',
                description = 'Contrata a un empleado para la comisaria',
                onSelect = function(args)
                    local input = lib.inputDialog('Contratar jugador', {
                        { icon = "fa-solid fa-hashtag", type = 'number', label = 'ID del jugador' },
                    })

                    if input[1] then
                        TriggerServerEvent('jj_policejob:hireEmployee', input[1])
                    end
                end,
                arrow = true,
            },
            {
                icon = 'fa-solid fa-user-slash',
                title = 'Despedir empleado',
                description = 'Contrata a un empleado para la comisaria',
                onSelect = function(args)
                    local input = lib.inputDialog('Despedir jugador', {
                        { icon = "fa-solid fa-hashtag", type = 'number', label = 'ID del jugador' },
                    })

                    if input[1] then
                        TriggerServerEvent('jj_policejob:fireEmployee', input[1])
                    end
                end,
                arrow = true,
            },
            {
                icon = 'fa-solid fa-user-shield',
                title = 'Ascender/Descender empleado',
                description = 'Ascender o descender a un empleado',
                onSelect = function(args)
                    local input = lib.inputDialog('Gestion de rangos', {
                        { icon = "fa-solid fa-hashtag", type = 'number', label = 'ID del jugador' },
                        { icon = "fa-solid fa-hashtag", type = 'number', label = 'Rango',         default = 0 },
                    })

                    if input[1] and input[2] then
                        TriggerServerEvent('jj_policejob:assignRank', input[1], input[2])
                    end
                end,
                arrow = true,
            },
        },
    })
    lib.showContext('boss_menu')
end

local SetDuty = function()
    TriggerServerEvent('jj_policejob:server:toggleDuty')
end

local FormatCallsign = function(callsign)
    return table.concat({ callsign:match("(%d)(%d?)(%d?)") }, " ")
end



local OpenListCars = function(spawnCoords)
    local listCars = {}
    for k, v in pairs(Config.carModels) do
        listCars[#listCars + 1] = {
            icon = "fas fa-car",
            title = v.label,
            description = "Sacar vehículo",
            args = { model = v.model },
            arrow = true,
            onSelect = function(args)
                SpawnVehicle(args.model, function(veh)
                    SetVehicleFuelLevel(veh, 100.0)
                end, spawnCoords, true, true)
            end,
        }
    end

    lib.registerContext({
        id = 'car_menu',
        title = 'Lista de coches',
        menu = 'car_menu',
        options = listCars,
    })
    lib.showContext('car_menu')
end

local OpenListHelicopters = function(spawnCoords)
    local listHelicopters = {}
    for k, v in pairs(Config.helicopterModels) do
        --print("DEBUG: " .. json.encode(v, {indent = true}))
        listHelicopters[#listHelicopters + 1] = {
            icon = "fas fa-helicopter",
            title = v.label,
            description = "Sacar helicóptero",
            args = { model = v.model },
            arrow = true,

            onSelect = function(args)
                local input = lib.inputDialog('Ajustes de helicoptero', {
                    {
                        icon = "fa-solid fa-star",
                        type = 'select',
                        label = 'Faccion',
                        options = v.liverys,
                        --options = { { label = 'LSPD', value = 'lspd' }, { label = 'BCSD', value = 'bcsd' }, { label = 'Trooper', value = 'trooper' } },
                        placeholder = 'Selecciona una faccion'
                    },
                })
                if input then
                    SpawnVehicle(args.model, function(veh)
                        Wait(300)
                        SetVehicleLivery(veh, input[1])
                        SetVehicleFuelLevel(veh, 100.0)
                    end, spawnCoords, true, true)
                end
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

local OpenListBoats = function(spawnCoords)
    local listBoats = {}
    for k, v in pairs(Config.boatModels) do
        listBoats[#listBoats + 1] = {
            icon = "fas fa-ship",
            title = v.label,
            description = "Sacar lancha",
            args = { model = v.model },
            arrow = true,
            onSelect = function(args)
                SpawnVehicle(args.model, function(veh)
                    SetVehicleFuelLevel(veh, 100.0)
                end, spawnCoords, true, true)
            end,
        }
    end
    lib.registerContext({
        id = 'boat_menu',
        title = 'Lista de lanchas',
        menu = 'boat_menu',
        options = listBoats,
    })
    lib.showContext('boat_menu')
end


local OpenNpcMenu = function()
    local options = {
        {
            icon = 'id-card',
            title = 'Renovar el ID',
            description = 'Renueva tu identificación',
            onSelect = function(args)
                TriggerServerEvent('jj_policejob:server:RenewID')
            end,
            arrow = true,
        },
        {
            icon = 'phone',
            title = 'Llamar a un agente de policia',
            description = 'Llama a un agente de policia',
            onSelect = function(args)
                ExecuteCommand(
                    "entorno Hay una persona esperando en la recepción de comisaria, que acuda un agente lo antes posible.")
            end,
            arrow = true,
        },
    }

    local PlayerData = GetPlayerData()
    if PlayerData.job.name == "police" and PlayerData.job.onduty then
        if PlayerData.metadata.givedVehicles == nil then
            options[#options + 1] = {
                icon = 'fa-solid fa-car',
                title = 'Recibir coches policiales',
                description = 'Solicita tu vehiculos policiales.',
                onSelect = function(args)
                    TriggerServerEvent('jj_policejob:server:giveStartVehicles')
                end,
                arrow = true,
            }
        end
    end

    lib.registerContext({
        id = 'npc_menu',
        title = 'Opciones',
        options = options,
    })
    lib.showContext('npc_menu')
end

local OpenNpcLocatorMenu = function(location)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" then
        return
    end

    local options = {
        {
            icon = 'truck',
            title = 'Garaje utilitarios',
            description = 'Ubicar el punto donde están los vehículos utilitarios (furgonetas, autobuses...)',
            onSelect = function(args)
                TriggerEvent('jj_policejob:location:markLocation', location, "vehiclePoints")
            end,
            arrow = true,
        },
        {
            icon = 'spray-can-sparkles',
            title = 'Extras',
            description = 'Ubicar el punto donde se modifican los extras del vehículo',
            onSelect = function(args)
                TriggerEvent('jj_policejob:location:markLocation', location, "extrasPoints")
            end,
            arrow = true,
        },
        {
            icon = 'car-tunnel',
            title = 'Depósito policial',
            description = 'Ubicar el punto del depósito policial',
            onSelect = function(args)
                TriggerEvent('jj_policejob:location:markLocation', location, "depotPoints")
            end,
            arrow = true,
        },
        {
            icon = 'helicopter',
            title = 'Sacar helicóptero',
            description = 'Ubicar el punto de sacar helicóptero',
            onSelect = function(args)
                TriggerEvent('jj_policejob:location:markLocation', location, "helicopterPoints")
            end,
            arrow = true,
        },
        {
            icon = 'ferry',
            title = 'Puerto policial',
            description = 'Ubicar un puerto policial cercano',
            onSelect = function(args)
                TriggerEvent('jj_policejob:location:markLocation', location, "boatPoints")
            end,
            arrow = true,
        },
    }

    lib.registerContext({
        id = 'police_npc_locator',
        title = 'Opciones',
        options = options,
    })
    lib.showContext('police_npc_locator')
end

local PlayAnimFree = function(dict, anim)
    local success = lib.requestAnimDict(dict, 300)
    if not success then return end
    TaskPlayAnim(cache.ped, dict, anim, 5.0, 1.0, 5000.0, 1, 0.0, false, false, false)
    RemoveAnimDict(dict)
    SetTimeout(1100, function()
        ClearPedTasks(cache.ped)
    end)
end

local GetPoliceStatus = function()
    local PlayerData = GetPlayerData()
    return PlayerData.job.name == 'police' and PlayerData.job.onduty or false
end


return {
    OpenArmory = OpenArmory,
    OpenDivisionsArmory = OpenDivisionsArmory,
    OpenCloakroom = OpenCloakroom,
    OpenIncautions = OpenIncautions,
    VehicleExtras = VehicleExtras,
    OpenDepot = OpenDepot,
    OpenAscensor = OpenAscensor,
    OpenBossMenu = OpenBossMenu,
    SetDuty = SetDuty,
    FormatCallsign = FormatCallsign,
    OpenListCars = OpenListCars,
    OpenListHelicopters = OpenListHelicopters,
    OpenListBoats = OpenListBoats,
    OpenNpcMenu = OpenNpcMenu,
    OpenNpcLocatorMenu = OpenNpcLocatorMenu,
    PlayAnimFree = PlayAnimFree,
    GetPoliceStatus = GetPoliceStatus,
    OpenCallSignMenu = OpenCallSignMenu,
}
