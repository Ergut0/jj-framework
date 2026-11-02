-- Funciones del cliente, compartidas con Nui.lua y client.lua
CJ = {}

local MARKER_DISTANCE = 6.5
local INTERACT_DISTANCE = 1.0
local CONTROL_INTERACT = 38
local PLATE_PATTERN = '%s+'

local PointsLoaded = {}
local TeleportsLoaded = {}
local PublicTeleportsLoaded = {}
local GlobalTeleportsLoaded = {}
local npcSpawned = false

-- Identifican la última actualización pedida: si llega otra mientras tanto, esta se descarta
local refreshTokens = { points = 0, teleports = 0, public = 0, global = 0 }

function CJ.GetJob()
    local data = JJ.GetPlayerData()
    return data and data.job
end

local function Notify(description, type)
    lib.notify({ description = description, type = type or 'inform' })
end

function CJ.toggleNuiFrame(shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    SendNUIMessage({ action = 'setVisible', data = shouldShow })
end

local function GetLabel(typePoint, job)
    if typePoint == 'Servicio' then
        return job.onDuty and 'Salir de servicio' or 'Entrar de servicio'
    elseif typePoint == 'Inventario' then
        return 'Acceder al inventario'
    elseif typePoint == 'Mercado' then
        return 'Acceder al mercado'
    elseif typePoint == 'Ropero' then
        return 'Acceder al ropero'
    elseif typePoint == 'Crafteo' then
        return 'Acceder a la mesa de crafteo'
    elseif typePoint == 'Tuneo' then
        return 'Acceder al menú de tuneo'
    elseif typePoint == 'Garaje' then
        return 'Acceder al garaje'
    elseif typePoint == 'GuardarVehiculo' then
        return 'Guardar el vehículo'
    elseif typePoint == 'Jefe' then
        return 'Acceder a la sociedad'
    elseif typePoint == 'Garaje Compraventa' then
        return 'Acceder al garaje de compraventa'
    end
    return typePoint
end

local function FirstUpper(str)
    return (str:gsub('^%l', string.upper))
end

local function NormalizePlate(plate)
    return (tostring(plate or ''):gsub(PLATE_PATTERN, ''):upper())
end

function CJ.CreateZone(coords, radius, name)
    return lib.zones.sphere({
        coords = vector3(coords.x, coords.y, coords.z),
        radius = radius or 5.0,
        debug = false,
        onEnter = function()
            LocalPlayer.state.inBussinesZone = true
        end,
        onExit = function()
            LocalPlayer.state.inBussinesZone = false
            local job = CJ.GetJob()
            if job and job.name == name and job.onDuty then
                lib.notify({
                    title = 'Zona de trabajo',
                    description = 'Has salido de la zona de trabajo y del servicio',
                    type = 'error',
                })
                TriggerServerEvent('jj_creatorjobs:server:setDuty', false)
            end
        end,
    })
end

-- Crea un vehículo en un punto y mete dentro al jugador
local function SpawnVehicle(model, coords)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        Notify(('El vehículo %s no existe'):format(model), 'error')
        return nil
    end

    lib.requestModel(hash)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)

    local timeout = GetGameTimer() + 3000
    while not DoesEntityExist(vehicle) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not DoesEntityExist(vehicle) then
        return nil
    end

    SetVehicleOnGroundProperly(vehicle)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    return vehicle
end

local function OpenMarket(job)
    local items = lib.callback.await('jj_creatorjobs:callback:getMarket', false, job.name)
    if not items or next(items) == nil then
        lib.notify({ title = 'Mercado', description = 'No hay productos disponibles en el mercado', type = 'error' })
        return
    end

    local lonjas = {}
    for _, lonja in pairs(Config.Lonja) do
        lonjas[#lonjas + 1] = { value = lonja.nameLonja, label = lonja.nameLonja }
    end

    local elements = {}
    for _, item in pairs(items) do
        elements[#elements + 1] = {
            title = item.label,
            icon = 'fas fa-shopping-cart',
            arrow = true,
            description = 'Precio: $' .. item.price,
            onSelect = function()
                local input = lib.inputDialog('Cantidad a comprar', {
                    { label = item.label, description = 'Cantidad a comprar', icon = 'fas fa-shopping-cart', min = 1, type = 'number', required = true },
                    { icon = 'fa-solid fa-warehouse', type = 'select', label = 'Seleccionar lonja', options = lonjas, placeholder = 'Selecciona una lonja', required = true },
                })
                if input then
                    TriggerServerEvent('jj_creatorjobs:server:buyItem', { id = item.id, amount = input[1], typeLonja = input[2] })
                end
            end,
        }
    end

    lib.registerContext({ id = 'shop_menu', title = 'Tienda de ' .. job.label, options = elements })
    lib.showContext('shop_menu')
end

local function OpenCloakroom()
    lib.registerContext({
        id = 'cloakroom_menu',
        title = 'Vestuario',
        options = {
            {
                title = 'Abrir ropero personal',
                description = 'Abre el ropero para cambiarte de ropa',
                onSelect = function()
                    TriggerEvent('illenium-appearance:client:openClothingShopMenu')
                end,
                icon = 'fas fa-tshirt',
                arrow = true,
            },
            {
                title = 'Abrir taquilla personal',
                description = 'Abre la taquilla para guardar tus pertenencias',
                onSelect = function()
                    local data = JJ.GetPlayerData()
                    exports.ox_inventory:openInventory('stash', data.identifier .. '-personal')
                end,
                icon = 'fa-solid fa-warehouse',
                arrow = true,
            },
        },
    })
    lib.showContext('cloakroom_menu')
end

local function OpenJobGarage(job, coords)
    local list = lib.callback.await('jj_creatorjobs:callback:getVehicles', false, job.name)
    if not list or next(list) == nil then
        lib.notify({ title = 'Garaje', description = 'No tienes vehículos en el garaje', type = 'error' })
        return
    end

    local vehicles = {}
    for _, entry in pairs(list) do
        vehicles[#vehicles + 1] = {
            title = FirstUpper(entry.name),
            icon = 'fas fa-car',
            description = 'Sacar vehículo',
            arrow = true,
            onSelect = function()
                local data = lib.callback.await('jj_creatorjobs:callback:takeJobVehicle', false, entry.id)
                if not data then
                    Notify('No puedes sacar este vehículo', 'error')
                    return
                end
                local vehicle = SpawnVehicle(data.model, coords)
                if vehicle then
                    SetVehicleNumberPlateText(vehicle, data.plate)
                    SetVehicleLivery(vehicle, data.livery)
                    SetVehicleFuelLevel(vehicle, 100.0)
                    Config.addKeyVehicle(vehicle, data.plate)
                end
            end,
        }
    end

    lib.registerContext({ id = 'vehicles_menu', title = 'Garaje', options = vehicles })
    lib.showContext('vehicles_menu')
end

local function OpenSociety(job)
    local info = lib.callback.await('jj_creatorjobs:callback:getSocietyInfo', false)
    if not info then
        Notify('No tienes permisos para acceder aquí', 'error')
        return
    end

    lib.registerContext({
        id = 'society_money',
        title = 'Sociedad',
        options = {
            {
                title = 'Dinero en la sociedad: $' .. info.money,
                icon = 'fas fa-money-bill-wave',
                description = 'Dinero en la sociedad',
            },
            {
                title = 'Nivel de la sociedad: ' .. job.label,
                icon = 'fas fa-user-tie',
                description = 'Nivel actual: ' .. info.level,
            },
            {
                title = 'Depositar dinero',
                icon = 'fas fa-piggy-bank',
                onSelect = function()
                    local input = lib.inputDialog('Cantidad a depositar', {
                        { label = 'Cantidad a depositar', description = 'Sale de tu efectivo', icon = 'fas fa-coins', min = 1, type = 'number', required = true },
                    })
                    if input then
                        TriggerServerEvent('jj_creatorjobs:server:AddSocietyMoney', input[1])
                    end
                end,
                arrow = true,
                description = 'Depositar dinero en la sociedad',
            },
            {
                title = 'Retirar dinero',
                icon = 'fas fa-hand-holding-usd',
                onSelect = function()
                    local input = lib.inputDialog('Cantidad a retirar', {
                        { label = 'Cantidad a retirar', description = 'Pasa a tu efectivo', icon = 'fas fa-coins', min = 1, type = 'number', required = true },
                    })
                    if input then
                        TriggerServerEvent('jj_creatorjobs:server:WithdrawnSocietyMoney', input[1])
                    end
                end,
                arrow = true,
                description = 'Retirar dinero de la sociedad',
            },
            {
                title = 'Empleados',
                icon = 'fas fa-users',
                description = 'Gestionar empleados',
                onSelect = function()
                    CJ.toggleNuiFrame(true)
                end,
                arrow = true,
            },
            {
                title = 'Caja fuerte',
                icon = 'fas fa-lock',
                description = 'Acceder a la caja fuerte',
                onSelect = function()
                    exports.ox_inventory:openInventory('stash', job.name .. 'jefe')
                end,
                arrow = true,
            },
        },
    })
    lib.showContext('society_money')
end

local function OpenDealershipGarage(coords)
    if cache.vehicle then
        local vehicle = cache.vehicle
        local plate = NormalizePlate(GetVehicleNumberPlateText(vehicle))
        if not lib.callback.await('jj_creatorjobs:callback:comprobateVehicle', false, plate) then
            lib.notify({ title = 'Error', description = 'No puedes guardar este vehículo, no es de la compraventa', type = 'error' })
            return
        end
        TriggerServerEvent('jj_creatorjobs:server:saveVehicle', plate, lib.getVehicleProperties(vehicle))
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        return
    end

    local stock = lib.callback.await('jj_creatorjobs:callback:getVehiclesJob', false)
    local elements = {}
    for _, entry in pairs(stock or {}) do
        if entry.state < 1 then
            elements[#elements + 1] = {
                title = FirstUpper(entry.vehicle),
                icon = 'fas fa-car',
                description = 'Matrícula: ' .. entry.plate,
                arrow = true,
                onSelect = function()
                    local data = lib.callback.await('jj_creatorjobs:callback:takeStockVehicle', false, entry.plate)
                    if not data then
                        Notify('Ese vehículo ya no está disponible', 'error')
                        return
                    end
                    local vehicle = SpawnVehicle(data.vehicle, coords)
                    if vehicle then
                        SetVehicleNumberPlateText(vehicle, data.plate)
                        SetVehicleFuelLevel(vehicle, 100.0)
                        Config.addKeyVehicle(vehicle, data.plate)
                        if data.mods then
                            lib.setVehicleProperties(vehicle, json.decode(data.mods))
                        end
                    end
                end,
            }
        end
    end

    if #elements == 0 then
        lib.notify({ title = 'Garaje Compraventa', description = 'No hay vehículos en el garaje', type = 'error' })
        return
    end

    lib.registerContext({ id = 'vehicles_job_menu', title = 'Garaje Compraventa', options = elements })
    lib.showContext('vehicles_job_menu')
end

-- Estas funciones dependen de recursos que este servidor puede no tener
local function RunOptionalResource(resource, action)
    if GetResourceState(resource) ~= 'started' then
        Notify(('Esta función necesita el recurso %s'):format(resource), 'error')
        return
    end
    action()
end

local function RequestAction(typePoint, coords, unique)
    local job = CJ.GetJob()
    if not job then return end

    if typePoint == 'Servicio' then
        TriggerServerEvent('jj_creatorjobs:server:setDuty', not job.onDuty)
    elseif typePoint == 'Inventario' then
        exports.ox_inventory:openInventory('stash', unique)
    elseif typePoint == 'Mercado' then
        OpenMarket(job)
    elseif typePoint == 'Ropero' then
        OpenCloakroom()
    elseif typePoint == 'Crafteo' then
        RunOptionalResource('josete_crafteos', function()
            exports.jj_crafteos:OpenCraftMenu(job.name)
        end)
    elseif typePoint == 'Garaje' then
        OpenJobGarage(job, coords)
    elseif typePoint == 'GuardarVehiculo' then
        local vehicle = cache.vehicle
        if not vehicle then return end
        -- Un vehículo con dueño se guarda en un garaje, para no perderlo
        if Entity(vehicle).state.vehPersonal then
            Notify('Este vehículo tiene dueño: guárdalo en un garaje', 'error')
            return
        end
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    elseif typePoint == 'Jefe' then
        OpenSociety(job)
    elseif typePoint == 'Garaje Compraventa' then
        OpenDealershipGarage(coords)
    elseif typePoint == 'Tuneo' then
        RunOptionalResource('jj_tuneos', function()
            exports.jj_tuneos:openMenuTunning()
        end)
    end
end

local function OpenLonjaMenu(typeLonja)
    local items = lib.callback.await('jj_creatorjobs:callback:getItemLonjaByType', false, typeLonja)
    if not items or next(items) == nil then
        lib.notify({ title = 'Mayorista', description = 'No hay productos disponibles en este mayorista', type = 'error' })
        return
    end

    local elements = {}
    for _, item in pairs(items) do
        elements[#elements + 1] = {
            title = item.label,
            icon = 'fas fa-shopping-cart',
            description = 'Cantidad: ' .. item.amount,
            arrow = true,
            onSelect = function()
                local input = lib.inputDialog('Recoger producto', {
                    { label = item.label, description = 'Cantidad de productos', icon = 'fas fa-shopping-cart', min = 1, type = 'number', max = item.amount, required = true },
                })
                if input then
                    TriggerServerEvent('jj_creatorjobs:server:removeItemLonja', { id = item.id, amount = input[1] })
                end
            end,
        }
    end

    lib.registerContext({ id = 'lonja_menu', title = 'Lonja Productos', options = elements })
    lib.showContext('lonja_menu')
end

-- Marcador con texto y tecla E
local function CreateInteractPoint(x, y, z, text, onPress)
    return lib.points.new({
        coords = vector3(x, y, z),
        distance = MARKER_DISTANCE,
        textShown = false,
        onExit = function(self)
            if self.textShown then
                lib.hideTextUI()
                self.textShown = false
            end
        end,
        nearby = function(self)
            DrawMarker(20, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
            if self.currentDistance <= INTERACT_DISTANCE then
                if not self.textShown then
                    self.textShown = true
                    lib.showTextUI('[E] ' .. text)
                end
                if IsControlJustPressed(0, CONTROL_INTERACT) then
                    onPress()
                end
            elseif self.textShown then
                lib.hideTextUI()
                self.textShown = false
            end
        end,
    })
end

local function ClearPoints(points)
    for key, point in pairs(points) do
        if point.textShown then
            lib.hideTextUI()
        end
        point:remove()
        points[key] = nil
    end
end

-- Los puntos de estos tipos se ven también fuera de servicio
local OFF_DUTY_POINTS = { Servicio = true, Ropero = true, Jefe = true }

function CJ.RefreshPoints(jobInfo)
    local job = jobInfo or CJ.GetJob()
    if not job then return end

    refreshTokens.points = refreshTokens.points + 1
    local token = refreshTokens.points
    local pointsInfo = lib.callback.await('jj_creatorjobs:callback:getPoints', false, job.name)
    if token ~= refreshTokens.points then return end

    ClearPoints(PointsLoaded)

    for _, point in pairs(pointsInfo or {}) do
        -- El garaje personal lo dibuja jj_garages, y la zona no tiene marcador
        local hasMarker = point.typePoint ~= 'Zona Centro' and point.typePoint ~= 'Garaje Personal'
        if hasMarker and (job.onDuty or OFF_DUTY_POINTS[point.typePoint]) then
            local coords = { x = point.x, y = point.y, z = point.z, w = point.heading }
            PointsLoaded[point.id] = CreateInteractPoint(point.x, point.y, point.z, GetLabel(point.typePoint, job), function()
                RequestAction(point.typePoint, coords, point.unique_identifier)
            end)
        end
    end
end

local function FadeTo(entity, x, y, z, heading)
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(entity, x, y, z, false, false, false, true)
    SetEntityHeading(entity, heading)
    Wait(500)
    DoScreenFadeIn(500)
end

local function DoTeleport(x, y, z, heading, allowVehicle)
    if cache.vehicle and allowVehicle ~= 1 then
        lib.notify({ title = 'Teleport', description = 'No puedes teleportarte con un vehículo en este teleport', type = 'error' })
        return
    end
    FadeTo(cache.vehicle or cache.ped, x, y, z, heading)
end

local function AddTeleportPair(points, prefix, teleport)
    points[prefix .. 'entrance_' .. teleport.id] = CreateInteractPoint(teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.label .. ' (Entrada)', function()
        DoTeleport(teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading, teleport.allow_vehicle)
    end)
    points[prefix .. 'exit_' .. teleport.id] = CreateInteractPoint(teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.label .. ' (Salida)', function()
        DoTeleport(teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading, teleport.allow_vehicle)
    end)
end

function CJ.RefreshTeleports(jobInfo)
    local job = jobInfo or CJ.GetJob()
    if not job then return end

    refreshTokens.teleports = refreshTokens.teleports + 1
    local token = refreshTokens.teleports
    local teleports = lib.callback.await('jj_creatorjobs:callback:getTeleports', false, job.name)
    if token ~= refreshTokens.teleports then return end

    ClearPoints(TeleportsLoaded)

    for _, teleport in pairs(teleports or {}) do
        -- Los públicos los carga RefreshPublicTeleports, para todos los trabajos
        local isPublic = teleport.job_only == 0
        local requiresDuty = teleport.on_duty_only == 1
        if not isPublic and (not requiresDuty or job.onDuty) then
            AddTeleportPair(TeleportsLoaded, 'tp_', teleport)
        end
    end
end

function CJ.RefreshPublicTeleports()
    refreshTokens.public = refreshTokens.public + 1
    local token = refreshTokens.public
    local teleports = lib.callback.await('jj_creatorjobs:callback:getPublicTeleports', false)
    if token ~= refreshTokens.public then return end

    ClearPoints(PublicTeleportsLoaded)

    for _, teleport in pairs(teleports or {}) do
        AddTeleportPair(PublicTeleportsLoaded, 'ptp_', teleport)
    end
end

-- El servidor comprueba la contraseña y cambia el mundo del jugador
local function UseGlobalTeleport(teleport, side)
    local password = nil
    if teleport.hasPassword then
        local input = lib.inputDialog(teleport.label, {
            { type = 'input', label = 'Contraseña', password = true, required = true, icon = 'lock' },
        })
        if not input then return end
        password = input[1]
    end

    if not lib.callback.await('jj_creatorjobs:callback:useGlobalTeleport', false, teleport.id, side, password) then
        Notify('Contraseña incorrecta', 'error')
        return
    end

    if side == 'entrance' then
        FadeTo(cache.ped, teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading)
    else
        FadeTo(cache.ped, teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading)
    end
end

function CJ.RefreshGlobalTeleports()
    refreshTokens.global = refreshTokens.global + 1
    local token = refreshTokens.global
    local teleports = lib.callback.await('jj_creatorjobs:callback:getGlobalTeleports', false)
    if token ~= refreshTokens.global then return end

    ClearPoints(GlobalTeleportsLoaded)

    for _, teleport in pairs(teleports or {}) do
        local text = teleport.hasPassword and (teleport.label .. ' (Requiere contraseña)') or teleport.label
        GlobalTeleportsLoaded['gtp_entrance_' .. teleport.id] = CreateInteractPoint(teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, text, function()
            UseGlobalTeleport(teleport, 'entrance')
        end)
        GlobalTeleportsLoaded['gtp_exit_' .. teleport.id] = CreateInteractPoint(teleport.exit_x, teleport.exit_y, teleport.exit_z, text, function()
            UseGlobalTeleport(teleport, 'exit')
        end)
    end
end

function CJ.SpawnNPC()
    if npcSpawned then return end
    npcSpawned = true

    for _, lonja in pairs(Config.Lonja) do
        lib.requestModel(lonja.ped)
        local ped = CreatePed(0, lonja.ped, lonja.coords.x, lonja.coords.y, lonja.coords.z - 1, lonja.coords.w, false, true)
        SetModelAsNoLongerNeeded(lonja.ped)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)

        if Config.Target then
            exports.ox_target:addLocalEntity(ped, {
                {
                    distance = 2.5,
                    label = 'Hablar con el proveedor',
                    icon = 'fa-solid fa-briefcase',
                    onSelect = function()
                        OpenLonjaMenu(lonja.nameLonja)
                    end,
                },
            })
        else
            lib.points.new({
                coords = lonja.coords.xyz,
                distance = 2.5,
                nearby = function()
                    if IsControlJustPressed(0, CONTROL_INTERACT) then
                        OpenLonjaMenu(lonja.nameLonja)
                    end
                end,
                onEnter = function()
                    lib.showTextUI('[E] Hablar con el proveedor')
                end,
                onExit = function()
                    lib.hideTextUI()
                end,
            })
        end
    end
end

exports('trapo', function(data)
    local veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, true)
    if not veh or veh == 0 then
        Notify('No hay ningún vehículo cerca', 'error')
        return
    end

    if lib.progressCircle({
            duration = 5000,
            position = 'bottom',
            label = 'Limpiando vehículo',
            useWhileDead = false,
            canCancel = true,
            anim = { dict = 'amb@world_human_maid_clean@base', clip = 'base' },
            disable = { move = true, combat = true },
        }) then
        exports.ox_inventory:useItem(data, function(used)
            if used then
                SetVehicleDirtLevel(veh, 0.0)
                Notify('Has limpiado el vehículo', 'success')
            end
        end)
    end
end)

exports('repairkit', function(data)
    local veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, true)
    if not veh or veh == 0 then
        Notify('No hay ningún vehículo cerca', 'error')
        return
    end

    if lib.progressCircle({
            duration = 5000,
            position = 'bottom',
            label = 'Reparando vehículo',
            useWhileDead = false,
            canCancel = true,
            anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 },
            disable = { move = true, combat = true },
        }) then
        exports.ox_inventory:useItem(data, function(used)
            if used then
                SetVehicleEngineHealth(veh, 1000.0)
                Notify('Has reparado el vehículo', 'success')
            end
        end)
    end
end)

exports('advancedrepairkit', function(data)
    local veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, false)
    if not veh or veh == 0 then
        Notify('No hay ningún vehículo cerca', 'error')
        return
    end

    if lib.progressCircle({
            duration = 9000,
            position = 'bottom',
            label = 'Reparando vehículo',
            useWhileDead = false,
            canCancel = true,
            anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 },
            disable = { move = true, combat = true },
        }) then
        exports.ox_inventory:useItem(data, function(used)
            if used then
                SetVehicleFixed(veh)
                SetVehicleDirtLevel(veh, 0.0)
                Notify('Has reparado el vehículo', 'success')
            end
        end)
    end
end)
