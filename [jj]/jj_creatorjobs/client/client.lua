local CLOSED_BLIP_COLOUR = 0

local blips = {}
local blipInfo = {}
local zones = {}
local Permissions = {}

-- Blips

-- El blip tiene su color cuando el negocio está abierto, y blanco cuando está cerrado
local function BlipColour(colour, open)
    return open and (tonumber(colour) or 2) or CLOSED_BLIP_COLOUR
end

local function CreateBusinessBlip(i)
    local id = tostring(i.id)
    local blip = AddBlipForCoord(vector3(i.x, i.y, i.z))
    SetBlipSprite(blip, tonumber(i.blipsprite))
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, BlipColour(i.blipcolor, i.open))
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(i.label)
    EndTextCommandSetBlipName(blip)
    blips[id] = blip
    blipInfo[id] = { job = i.job, colour = i.blipcolor }
end

local function RemoveBusinessBlip(id)
    id = tostring(id)
    if blips[id] then
        RemoveBlip(blips[id])
        blips[id] = nil
        blipInfo[id] = nil
    end
end

RegisterNetEvent('jj_creatorjobs:client:syncBlipStatus', function(jobName, open)
    for id, info in pairs(blipInfo) do
        if info.job == jobName and blips[id] then
            SetBlipColour(blips[id], BlipColour(info.colour, open))
        end
    end
end)

RegisterNetEvent('jj_creatorjobs:client:syncAddBlip', function(i, jobName)
    RemoveBusinessBlip(i.id)
    i.job = i.job or jobName
    CreateBusinessBlip(i)
end)

RegisterNetEvent('jj_creatorjobs:client:syncDeleteBlip', RemoveBusinessBlip)

-- Zonas de trabajo

local function RefreshZones()
    local zonesInfo = lib.callback.await('jj_creatorjobs:callback:getAllZones', false)
    for name, zone in pairs(zones) do
        zone:remove()
        zones[name] = nil
    end
    for _, info in pairs(zonesInfo or {}) do
        zones[info.name] = CJ.CreateZone(info.coords, info.radius, info.name)
    end
end

-- Arranque: al aparecer el personaje, o al reiniciar el recurso con el personaje ya en el mundo

local function LoadPermissions(jobName)
    Permissions = lib.callback.await('jj_creatorjobs:callback:getPerms', false, jobName) or {}
end

local function OnPlayerReady()
    local job = CJ.GetJob()
    if not job then return end

    for id in pairs(blips) do
        RemoveBusinessBlip(id)
    end
    for _, blip in pairs(lib.callback.await('jj_creatorjobs:callback:getAllBlips', false) or {}) do
        CreateBusinessBlip(blip)
    end

    LoadPermissions(job.name)
    RefreshZones()
    CJ.SpawnNPC()
    CJ.RefreshPoints(job)
    CJ.RefreshTeleports(job)
    CJ.RefreshPublicTeleports()
    CJ.RefreshGlobalTeleports()
end

AddEventHandler('jj:client:playerSpawned', OnPlayerReady)

CreateThread(function()
    if LocalPlayer.state.isLoggedIn or JJ.IsSpawned() then
        OnPlayerReady()
    end
end)

AddEventHandler('jj:client:playerDataChanged', function(key, job)
    if key ~= 'job' then return end
    LoadPermissions(job.name)
    CJ.RefreshTeleports(job)
    CJ.RefreshPoints(job)
end)

-- Sincronización de los cambios hechos desde la interfaz

local function isOwnJob(jobName)
    local job = CJ.GetJob()
    return job ~= nil and job.name == jobName
end

RegisterNetEvent('jj_creatorjobs:client:syncAddPerm', function(i, jobName)
    if isOwnJob(jobName) then
        table.insert(Permissions, i)
    end
end)

RegisterNetEvent('jj_creatorjobs:client:syncDeletePerm', function(id, jobName)
    if isOwnJob(jobName) then
        for k, v in pairs(Permissions) do
            if v.id == tonumber(id) then
                table.remove(Permissions, k)
                break
            end
        end
    end
end)

local function onPointChanged(jobName)
    RefreshZones()
    if isOwnJob(jobName) then
        CJ.RefreshPoints()
    end
end

RegisterNetEvent('jj_creatorjobs:client:syncAddPoint', function(_, jobName)
    onPointChanged(jobName)
end)

RegisterNetEvent('jj_creatorjobs:client:syncUpdatePoint', function(_, _, jobName)
    onPointChanged(jobName)
end)

RegisterNetEvent('jj_creatorjobs:client:syncDeletePoint', function(_, jobName)
    onPointChanged(jobName)
end)

-- Un teleport público de otro trabajo también afecta a este jugador
local function onTeleportChanged(jobName)
    if isOwnJob(jobName) then
        CJ.RefreshTeleports()
    end
    CJ.RefreshPublicTeleports()
end

RegisterNetEvent('jj_creatorjobs:client:syncAddTeleport', function(_, jobName)
    onTeleportChanged(jobName)
end)

RegisterNetEvent('jj_creatorjobs:client:syncUpdateTeleport', function(_, _, jobName)
    onTeleportChanged(jobName)
end)

RegisterNetEvent('jj_creatorjobs:client:syncDeleteTeleport', function(_, jobName)
    onTeleportChanged(jobName)
end)

RegisterNetEvent('jj_creatorjobs:client:syncAddGlobalTeleport', CJ.RefreshGlobalTeleports)
RegisterNetEvent('jj_creatorjobs:client:syncUpdateGlobalTeleport', CJ.RefreshGlobalTeleports)
RegisterNetEvent('jj_creatorjobs:client:syncDeleteGlobalTeleport', CJ.RefreshGlobalTeleports)

-- Avisos a todo el servidor

local NOTIFY_STYLE = {
    backgroundColor = 'rgba(0, 0, 0, 0.76)',
    color = 'rgb(202, 202, 202)',
    ['.description'] = { color = 'rgb(202, 202, 202)' },
}

RegisterNetEvent('jj_creatorjobs:client:notiyStatus', function(job, status)
    local isOpen = status == 'open'
    lib.notify({
        title = job,
        description = isOpen and (job .. ' ha abierto, ¡ven a visitarlo!') or (job .. ' ha cerrado, ¡vuelve más tarde!'),
        duration = 5000,
        position = 'top',
        style = NOTIFY_STYLE,
        icon = isOpen and 'fas fa-store' or 'fas fa-store-slash',
        iconColor = isOpen and '#34FE40' or '#FE3434',
    })
end)

RegisterNetEvent('jj_creatorjobs:client:sendAnuncio', function(label, mensaje)
    lib.notify({
        title = label,
        description = mensaje,
        duration = 7000,
        position = 'top',
        style = NOTIFY_STYLE,
        icon = 'fas fa-bullhorn',
        iconColor = '#9B30FF',
    })
end)

-- Confirmaciones que recibe el cliente. Lo que se compra y a qué precio lo guarda el servidor

RegisterNetEvent('jj_creatorjobs:client:confirmDeal', function(kind, matricula, precio, vehicle)
    local isBuy = kind == 'buy'
    local alert = lib.alertDialog({
        header = isBuy and 'Confirmación de venta' or 'Confirmación de compra',
        content = (isBuy and '¿Quieres vender el vehículo %s con matrícula %s por $%s?' or '¿Quieres comprar el vehículo %s con matrícula %s por $%s?'):format(vehicle, matricula, precio),
        cancel = true,
        centered = true,
        labels = {
            confirm = isBuy and 'Vender' or 'Comprar',
            cancel = 'Cancelar',
        },
    })
    TriggerServerEvent('jj_creatorjobs:server:respondDeal', alert == 'confirm')
end)

RegisterNetEvent('jj_creatorjobs:client:receiveBill', function(amount, concept, jobLabel)
    local alert = lib.alertDialog({
        header = ('Factura de %s'):format(jobLabel or 'Empresa'),
        content = ('Concepto: %s\n\nCantidad: $%s\n\n¿Quieres pagar esta factura?'):format(concept, amount),
        cancel = true,
        centered = true,
        labels = {
            confirm = 'Pagar',
            cancel = 'Rechazar',
        },
    })
    TriggerServerEvent('jj_creatorjobs:server:payBill', alert == 'confirm')
end)

-- Menú F6

local function getClosestVehicleOrNotify(distance)
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), distance, true)
    if not vehicle or vehicle == 0 then
        lib.notify({ description = 'No hay ningún vehículo cerca', type = 'error' })
        return nil
    end
    return vehicle
end

local function requestVehicleControl(vehicle)
    local timeout = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(vehicle)
        Wait(50)
    end
end

local function vehicleProgress(duration, label, anim)
    return lib.progressCircle({
        duration = duration,
        position = 'bottom',
        label = label,
        useWhileDead = false,
        canCancel = true,
        anim = anim,
        disable = { move = true, combat = true },
    })
end

local optionHandlers = {
    ['Facturar'] = function()
        local input = lib.inputDialog('Menú facturas', {
            { icon = 'user', type = 'number', label = 'ID del jugador', required = true },
            { icon = 'fa-solid fa-dollar-sign', type = 'number', label = 'Cantidad', placeholder = '0', description = 'Cantidad monetaria de la factura', required = true },
            { icon = 'fa-solid fa-pen', type = 'input', label = 'Concepto', description = 'Concepto de la factura', required = true },
        })
        if input then
            TriggerServerEvent('jj_creatorjobs:sendBill', input[1], input[2], input[3])
        end
    end,
    ['Cachear'] = function()
        local playerId, playerPed = lib.getClosestPlayer(GetEntityCoords(cache.ped), 4.0, false)
        if not playerId then
            lib.notify({ description = 'No hay nadie cerca', type = 'error' })
            return
        end
        if not IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 3) and not IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_enter', 3) then
            lib.notify({ description = 'La persona no tiene las manos arriba', type = 'error' })
            return
        end
        if lib.progressBar({
                duration = 5000,
                label = 'Cacheando a la persona',
                useWhileDead = false,
                canCancel = true,
                anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search', flags = 16 },
                disable = { car = true, combat = true },
            }) then
            if not lib.callback.await('jj_creatorjobs:callback:search', false, GetPlayerServerId(playerId)) then
                lib.notify({ description = 'No puedes cachear a esta persona', type = 'error' })
            end
        end
    end,
    ['Compraventa'] = function()
        local selectAction = lib.inputDialog('Menú de compraventa', {
            { icon = 'fa-car', type = 'select', label = 'Selecciona qué quieres hacer', options = { { label = 'Vender', value = 'vender' }, { label = 'Comprar', value = 'comprar' } }, required = true },
        })
        if not selectAction then return end

        local isPurchase = selectAction[1] == 'comprar'
        local input = lib.inputDialog(isPurchase and 'Comprar a un jugador' or 'Vender a un jugador', {
            { icon = 'fa-user', type = 'number', label = 'ID del jugador', placeholder = '1', required = true },
            { icon = 'fa-car', type = 'input', label = 'Matrícula', description = isPurchase and 'Matrícula del vehículo del jugador' or 'Matrícula del vehículo del stock', required = true },
            { icon = 'fa-money-bill-wave', type = 'number', label = 'Precio', placeholder = '0', required = true },
        })
        if input then
            TriggerServerEvent(isPurchase and 'jj_creatorjobs:server:sendMenuCarBuy' or 'jj_creatorjobs:server:sendMenuCarSell', input[1], input[2], input[3])
        end
    end,
    ['Reparar'] = function()
        local vehicle = getClosestVehicleOrNotify(2.5)
        if not vehicle then return end
        if vehicleProgress(7000, 'Reparando el vehículo', { scenario = 'PROP_HUMAN_BUM_BIN' }) then
            requestVehicleControl(vehicle)
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineHealth(vehicle, 1000.0)
        else
            lib.notify({ description = 'Has cancelado la reparación', type = 'error' })
        end
    end,
    ['Abrir cerradura'] = function()
        local vehicle = getClosestVehicleOrNotify(3.0)
        if not vehicle then return end

        local loopedAnim = true
        lib.requestAnimDict('veh@break_in@0h@p_m_one@')
        CreateThread(function()
            while loopedAnim do
                TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, 0, 0, 0)
                Wait(1000)
            end
        end)

        local done = vehicleProgress(7000, 'Forzando cerradura')
        loopedAnim = false
        ClearPedTasksImmediately(cache.ped)

        if done then
            requestVehicleControl(vehicle)
            SetVehicleDoorsLocked(vehicle, 1)
            Entity(vehicle).state:set('HotWire', 'StopNeedHotWire', true)
            lib.notify({ description = 'Has forzado la cerradura con éxito', type = 'success' })
        else
            lib.notify({ description = 'Has cancelado la acción', type = 'error' })
        end
    end,
    ['Incautar'] = function()
        local vehicle = getClosestVehicleOrNotify(2.5)
        if not vehicle then return end
        if vehicleProgress(7000, 'Incautando vehículo', { scenario = 'PROP_HUMAN_BUM_BIN' }) then
            -- Un vehículo con dueño va al depósito: el servidor lo retira
            if not lib.callback.await('jj_creatorjobs:callback:impound', false, GetVehicleNumberPlateText(vehicle)) then
                requestVehicleControl(vehicle)
                SetEntityAsMissionEntity(vehicle, true, true)
                DeleteEntity(vehicle)
            end
        end
    end,
    ['Limpiar'] = function()
        local vehicle = getClosestVehicleOrNotify(2.5)
        if not vehicle then return end
        if vehicleProgress(5000, 'Limpiando vehículo', { dict = 'amb@world_human_maid_clean@base', clip = 'base' }) then
            requestVehicleControl(vehicle)
            SetVehicleDirtLevel(vehicle, 0.0)
        else
            lib.notify({ description = 'Has cancelado la limpieza', type = 'error' })
        end
    end,
    ['Desvolcar'] = function()
        local vehicle = getClosestVehicleOrNotify(5.0)
        if not vehicle then return end
        requestVehicleControl(vehicle)
        local coords = GetEntityCoords(vehicle)
        SetEntityCoords(vehicle, coords.x, coords.y, coords.z + 0.5, false, false, false, true)
        SetVehicleOnGroundProperly(vehicle)
        lib.notify({ description = 'Vehículo desvolcado con éxito', type = 'success' })
    end,
    ['Esposar'] = function()
        if GetResourceState('jj_things') == 'started' then
            exports.jj_things:useHandcuffs()
        end
    end,
    ['Abrir/Cerrar Negocio'] = function()
        TriggerServerEvent('jj_creatorjobs:server:AbrirCerrarNegocio')
    end,
    ['Enviar anuncio'] = function()
        local input = lib.inputDialog('Enviar anuncio', {
            { type = 'input', label = 'Mensaje', placeholder = 'Escribe tu mensaje aquí...' },
        })
        if input then
            TriggerServerEvent('jj_creatorjobs:server:EnviarAnuncio', input[1])
        end
    end,
}

RegisterCommand('openF6Menu', function()
    local job = CJ.GetJob()
    if #Permissions < 1 or not job or not job.onDuty then return end

    local elements = {}
    for _, permission in pairs(Permissions) do
        elements[#elements + 1] = {
            icon = 'fa-solid fa-bars',
            label = permission.typePermission,
            args = permission.typePermission,
        }
    end

    lib.registerMenu({
        id = 'permissions',
        title = 'Menú de trabajo',
        position = 'bottom-right',
        options = elements,
    }, function(_, _, args)
        local handler = optionHandlers[args]
        if handler then
            handler()
        end
    end)

    lib.showMenu('permissions')
end, false)

RegisterKeyMapping('openF6Menu', 'Abrir menú del trabajo', 'keyboard', 'F6')
