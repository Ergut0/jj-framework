local MAX_DISTANCE = 15.0
local RENTAL_PLATE_PREFIX = 'ALQ'

-- [source] = matrícula del último alquiler pagado y pendiente de aparecer
local pendingRentals = {}
local nextPlate = 0

local function findVehicle(index, model)
    local spawn = type(index) == 'string' and Config.Spawns[index]
    if not spawn then return nil end
    for _, car in pairs(spawn.listVehicles) do
        if car.model == model then
            return spawn, car
        end
    end
end

lib.callback.register('jj_alquiler:server:rent', function(source, index, model)
    local player = JJ.GetPlayer(source)
    local spawn, car = findVehicle(index, model)
    if not player or not spawn then
        return { ok = false }
    end

    local ped = GetPlayerPed(source)
    local selector = spawn.coordsSelector
    if not ped or ped == 0 or #(GetEntityCoords(ped) - vector3(selector.x, selector.y, selector.z)) > MAX_DISTANCE then
        return { ok = false }
    end

    -- El precio sale de la configuración del servidor, no de lo que envía el cliente
    if not player.removeMoney('cash', car.price, 'jj_alquiler') then
        return { ok = false, error = 'No tienes suficiente dinero' }
    end

    nextPlate = (nextPlate + 1) % 100000
    local plate = ('%s%05d'):format(RENTAL_PLATE_PREFIX, nextPlate)
    pendingRentals[source] = plate
    return { ok = true, plate = plate }
end)

-- Da las llaves del vehículo recién alquilado
RegisterNetEvent('jj_alquiler:server:spawned', function(netId)
    local src = source
    local plate = pendingRentals[src]
    if not plate or type(netId) ~= 'number' then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if GetVehicleNumberPlateText(vehicle):gsub('%s+', '') ~= plate then return end

    pendingRentals[src] = nil
    Entity(vehicle).state:set('hasTempKey', true, true)
    if GetResourceState('jj_keysystem') == 'started' then
        exports.jj_keysystem:addTempKey(src, plate)
    end
end)

AddEventHandler('playerDropped', function()
    pendingRentals[source] = nil
end)
