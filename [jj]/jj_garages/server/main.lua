local JJ = exports['jj-framework']:GetCoreObject()

-- Estados de jj_vehicles.state
local STATE_OUT = 0
local STATE_IN = 1
local STATE_IMPOUND = 2

local PENDING_TIMEOUT = 30000
local DELETE_DELAY = 2000
local DEFAULT_GARAGE = 'garagecentral'

-- [matrícula] = operación en curso. Evita sacar dos veces el mismo vehículo y permite deshacer un spawn fallido
local pending = {}

-- Helpers

local function Notify(src, description, type)
    TriggerClientEvent('ox_lib:notify', src, { description = description, type = type or 'inform' })
end

local function NormalizePlate(plate)
    if type(plate) ~= 'string' then return nil end
    local normalized = plate:gsub('%s+', ''):upper()
    return normalized ~= '' and normalized or nil
end

local function GetVehicleEntities()
    local entities = {}
    for _, veh in ipairs(GetAllVehicles()) do
        local plate = NormalizePlate(GetVehicleNumberPlateText(veh))
        if plate then
            entities[plate] = veh
        end
    end
    return entities
end

local function GetGarage(garageId)
    return type(garageId) == 'string' and Config.Garages[garageId] or nil
end

local function IsNearGarage(src, garage)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - garage.takeVehicle) <= Config.MaxGarageDistance
end

local function HasGarageAccess(player, garage)
    if garage.type == 'public' or garage.type == 'depot' then
        return true
    end
    if garage.type == 'gang' then
        return GetResourceState('jj_gangs') == 'started' and exports.jj_gangs:isMember(player.source, garage.gang)
    end
    if garage.type ~= 'job' then
        return false
    end
    local jobName = player.getJob().name
    if type(garage.job) == 'table' then
        for _, job in pairs(garage.job) do
            if job == jobName then
                return true
            end
        end
        return false
    end
    return garage.job == jobName
end

-- Devuelve el jugador si puede usar ese garaje desde donde está
local function GetGarageUser(src, garage)
    local player = JJ.GetPlayer(src)
    if player and garage and IsNearGarage(src, garage) and HasGarageAccess(player, garage) then
        return player
    end
end

local function DecodeProps(props)
    if type(props) ~= 'string' then return {} end
    local ok, decoded = pcall(json.decode, props)
    return ok and type(decoded) == 'table' and decoded or {}
end

local function GetDepotPrice(vehicle)
    return vehicle.depotprice > 0 and vehicle.depotprice or Config.DepotPrice
end

local function Charge(player, price)
    if price <= 0 then return true end
    for _, account in ipairs(Config.PayWith) do
        if player.removeMoney(account, price, 'garage_depot') then
            return true, account
        end
    end
    return false
end

-- Base de datos

local function EnsureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_vehicles` (
            `plate` VARCHAR(12) NOT NULL,
            `owner` VARCHAR(60) NOT NULL,
            `model` VARCHAR(50) NOT NULL,
            `glovebox` LONGTEXT NULL,
            `trunk` LONGTEXT NULL,
            PRIMARY KEY (`plate`),
            KEY `idx_jj_vehicles_owner` (`owner`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    local columns = {
        garage = ("VARCHAR(50) NOT NULL DEFAULT '%s'"):format(DEFAULT_GARAGE),
        state = ('TINYINT NOT NULL DEFAULT %d'):format(STATE_IN),
        props = 'LONGTEXT NULL',
        fuel = 'FLOAT NOT NULL DEFAULT 100',
        engine = 'FLOAT NOT NULL DEFAULT 1000',
        body = 'FLOAT NOT NULL DEFAULT 1000',
        depotprice = 'INT NOT NULL DEFAULT 0',
    }

    for _, column in ipairs(MySQL.query.await('SHOW COLUMNS FROM `jj_vehicles`') or {}) do
        columns[column.Field] = nil
    end

    for name, definition in pairs(columns) do
        MySQL.query.await(('ALTER TABLE `jj_vehicles` ADD COLUMN `%s` %s'):format(name, definition))
    end
end

MySQL.ready(function()
    EnsureSchema()
    if Config.AutoRespawn then
        MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE state = ?', { STATE_IN, STATE_OUT })
    end
end)

-- Callbacks

lib.callback.register('jj_garages:server:GetGarageVehicles', function(source, garageId)
    local garage = GetGarage(garageId)
    local player = GetGarageUser(source, garage)
    if not player then return {} end

    local rows = MySQL.query.await('SELECT plate, model, fuel, engine, body, state, garage, depotprice FROM jj_vehicles WHERE owner = ?', { player.identifier })
    local entities = garage.type == 'depot' and GetVehicleEntities() or nil
    local vehicles = {}

    for _, row in ipairs(rows or {}) do
        local include
        if garage.type == 'depot' then
            -- También recupera los vehículos que quedaron fuera y ya no existen, tras un reinicio o una desconexión
            include = row.state == STATE_IMPOUND or (row.state == STATE_OUT and not entities[row.plate])
            row.price = include and GetDepotPrice(row) or nil
        else
            include = row.state == STATE_IN and (Config.SharedGarages or row.garage == garageId)
        end
        if include then
            vehicles[#vehicles + 1] = row
        end
    end

    return vehicles
end)

lib.callback.register('jj_garages:server:parkVehicle', function(source, netId, props, garageId)
    local garage = GetGarage(garageId)
    local player = GetGarageUser(source, garage)
    if not player then return { ok = false, error = 'too_far' } end
    if garage.type == 'depot' or type(props) ~= 'table' or type(netId) ~= 'number' then
        return { ok = false, error = 'not_owned' }
    end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return { ok = false, error = 'not_owned' }
    end
    if GetPedInVehicleSeat(entity, -1) ~= GetPlayerPed(source) then
        return { ok = false, error = 'not_driver' }
    end

    -- La matrícula se lee de la entidad: la que manda el cliente no es de fiar
    local plate = NormalizePlate(GetVehicleNumberPlateText(entity))
    local vehicle = plate and MySQL.single.await('SELECT state FROM jj_vehicles WHERE plate = ? AND owner = ?', { plate, player.identifier })
    if not vehicle or vehicle.state ~= STATE_OUT then
        return { ok = false, error = 'not_owned' }
    end

    pending[plate] = nil
    props.plate = plate

    MySQL.update.await('UPDATE jj_vehicles SET props = ?, fuel = ?, engine = ?, body = ?, state = ?, garage = ?, depotprice = 0 WHERE plate = ?', {
        json.encode(props),
        tonumber(props.fuelLevel) or 100.0,
        tonumber(props.engineHealth) or 1000.0,
        tonumber(props.bodyHealth) or 1000.0,
        STATE_IN,
        garageId,
        plate,
    })

    SetTimeout(DELETE_DELAY, function()
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end)

    return { ok = true }
end)

lib.callback.register('jj_garages:server:takeOutVehicle', function(source, rawPlate, garageId)
    local garage = GetGarage(garageId)
    local player = GetGarageUser(source, garage)
    local plate = NormalizePlate(rawPlate)
    if not player then return { ok = false, error = 'too_far' } end
    if not plate then return { ok = false, error = 'not_owned' } end
    if pending[plate] then return { ok = false, error = 'vehicle_busy' } end

    -- Se bloquea antes de la primera consulta para que dos peticiones simultáneas no saquen el vehículo dos veces
    local operation = { source = source }
    pending[plate] = operation

    local function fail(reason)
        pending[plate] = nil
        return { ok = false, error = reason }
    end

    local vehicle = MySQL.single.await('SELECT model, props, fuel, engine, body, state, garage, depotprice FROM jj_vehicles WHERE plate = ? AND owner = ?', { plate, player.identifier })
    if not vehicle then return fail('not_owned') end

    -- Con el vehículo en el mundo no se puede sacar otro con la misma matrícula, sea cual sea su estado
    if GetVehicleEntities()[plate] then return fail('vehicle_out') end

    if garage.type == 'depot' then
        if vehicle.state == STATE_IN then return fail('not_depot') end
        local price = GetDepotPrice(vehicle)
        local paid, account = Charge(player, price)
        if not paid then return fail('not_enough') end
        operation.price, operation.account = price, account
    else
        if vehicle.state == STATE_OUT then return fail('vehicle_out') end
        if vehicle.state == STATE_IMPOUND then return fail('not_depot') end
        if not Config.SharedGarages and vehicle.garage ~= garageId then return fail('not_depot') end
    end

    operation.state = vehicle.state
    operation.depotprice = vehicle.depotprice
    MySQL.update.await('UPDATE jj_vehicles SET state = ?, depotprice = 0 WHERE plate = ?', { STATE_OUT, plate })

    SetTimeout(PENDING_TIMEOUT, function()
        if pending[plate] == operation then
            pending[plate] = nil
        end
    end)

    local props = DecodeProps(vehicle.props)
    props.fuelLevel = vehicle.fuel
    props.engineHealth = vehicle.engine
    props.bodyHealth = vehicle.body

    return { ok = true, model = vehicle.model, plate = plate, props = props }
end)

-- Events

RegisterNetEvent('jj_garages:server:spawnFailed', function(rawPlate)
    local src = source
    local plate = NormalizePlate(rawPlate)
    local operation = plate and pending[plate]
    if not operation or operation.source ~= src or not operation.state then return end

    -- Si el vehículo existe, el spawn no falló: devolverlo al garaje lo duplicaría
    if GetVehicleEntities()[plate] then return end

    pending[plate] = nil
    MySQL.update.await('UPDATE jj_vehicles SET state = ?, depotprice = ? WHERE plate = ?', { operation.state, operation.depotprice, plate })

    local player = JJ.GetPlayer(src)
    if player and operation.account then
        player.addMoney(operation.account, operation.price, 'garage_depot_refund')
    end
end)

-- Otros recursos y administración

local function GeneratePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = {}
    for i = 1, 8 do
        local index = math.random(1, #chars)
        plate[i] = chars:sub(index, index)
    end
    return table.concat(plate)
end

-- Registra un vehículo a nombre de un jugador y devuelve su matrícula, o nil si no se ha podido
local function AddVehicle(identifier, model, garageId)
    if type(identifier) ~= 'string' or type(model) ~= 'string' or not model:match('^[%w_]+$') then
        return nil
    end
    local garage = GetGarage(garageId) and garageId or DEFAULT_GARAGE
    for _ = 1, 10 do
        local plate = GeneratePlate()
        local inserted = MySQL.update.await('INSERT IGNORE INTO jj_vehicles (plate, owner, model, garage, state) VALUES (?, ?, ?, ?, ?)', {
            plate, identifier, model:lower(), garage, STATE_IN
        })
        if inserted and inserted > 0 then
            return plate
        end
    end
    return nil
end

exports('addVehicle', AddVehicle)

exports('getGarageLabel', function(id)
    local garage = Config.Garages[id]
    return garage and garage.label or false
end)

-- Garajes creados en marcha por otros recursos, como los de las bandas
local dynamicGarages = {}

exports('registerGarage', function(id, garage)
    garage.category = garage.category or Config.VehicleClass.car
    dynamicGarages[id] = garage
    Config.Garages[id] = garage
    TriggerClientEvent('jj_garages:client:addGarage', -1, id, garage)
end)

-- Los vehículos guardados allí pasan al garaje por defecto para que nadie los pierda
exports('removeGarage', function(id)
    if not dynamicGarages[id] then return end
    dynamicGarages[id] = nil
    Config.Garages[id] = nil
    MySQL.update.await('UPDATE jj_vehicles SET garage = ? WHERE garage = ?', { DEFAULT_GARAGE, id })
    TriggerClientEvent('jj_garages:client:removeGarage', -1, id)
end)

lib.callback.register('jj_garages:server:getDynamicGarages', function()
    return dynamicGarages
end)

-- Envía un vehículo al depósito, y lo elimina si está en el mundo
exports('impoundVehicle', function(rawPlate, price)
    local plate = NormalizePlate(rawPlate)
    if not plate then return false end
    local vehicle = MySQL.single.await('SELECT plate FROM jj_vehicles WHERE plate = ?', { plate })
    if not vehicle then return false end

    pending[plate] = nil
    MySQL.update.await('UPDATE jj_vehicles SET state = ?, depotprice = ? WHERE plate = ?', { STATE_IMPOUND, JJ.Utils.ToAmount(price, true) or 0, plate })

    local entity = GetVehicleEntities()[plate]
    if entity then
        DeleteEntity(entity)
    end
    return true
end)

-- /darcoche <id> <modelo>
RegisterCommand('darcoche', function(src, args)
    local function reply(message, type)
        if src == 0 then
            print(('[jj_garages] %s'):format(message))
        else
            Notify(src, message, type)
        end
    end

    if not JJ.IsAdmin(src) then
        return reply(Lang:t('error.no_permission'), 'error')
    end

    local target = JJ.GetPlayer(tonumber(args[1]))
    if not target then
        return reply(Lang:t('error.player_not_found'), 'error')
    end

    local plate = AddVehicle(target.identifier, args[2])
    if not plate then
        return reply(Lang:t('error.invalid_vehicle'), 'error')
    end

    reply(Lang:t('success.vehicle_given', plate), 'success')
end, false)

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)
