local MAX_VEHICLE_DISTANCE = 15.0
local MAX_LOCKPICK_DISTANCE = 6.0
local MAX_NPC_DISTANCE = 10.0
local MAX_NICKNAME_LENGTH = 30
local LOCKPICK_COOLDOWN = 10

-- Llaves temporales, por ejemplo de un vehículo alquilado: [source][matrícula] = true
local tempKeys = {}
local lockpickCooldowns = {}

MySQL.ready(function()
    for _, column in ipairs(MySQL.query.await('SHOW COLUMNS FROM `jj_vehicles`') or {}) do
        if column.Field == 'serial' then return end
    end
    MySQL.query.await('ALTER TABLE `jj_vehicles` ADD COLUMN `serial` VARCHAR(16) NULL')
end)

-- Helpers

local function normalizePlate(plate)
    if type(plate) ~= 'string' then return nil end
    local normalized = plate:gsub('%s+', ''):upper()
    return normalized ~= '' and normalized or nil
end

local function notify(src, description, type)
    TriggerClientEvent('ox_lib:notify', src, { description = description, type = type or 'inform' })
end

local function getVehicleRow(plate)
    return MySQL.single.await('SELECT owner, model, serial FROM jj_vehicles WHERE plate = ?', { plate })
end

local function generateSerial()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local serial = {}
    for i = 1, 10 do
        local index = math.random(1, #chars)
        serial[i] = chars:sub(index, index)
    end
    return table.concat(serial)
end

local function saveSerial(plate, serial)
    MySQL.update.await('UPDATE jj_vehicles SET serial = ? WHERE plate = ?', { serial, plate })
end

-- Tiene llave quien es el dueño, quien tiene una llave temporal o quien lleva una copia con el serial actual
local function hasKey(src, rawPlate)
    local player = JJ.GetPlayer(src)
    local plate = normalizePlate(rawPlate)
    if not player or not plate then return false end
    if tempKeys[src] and tempKeys[src][plate] then return true end

    local vehicle = getVehicleRow(plate)
    if not vehicle then return false end
    if vehicle.owner == player.identifier then return true end
    if not vehicle.serial then return false end

    local count = exports.ox_inventory:Search(src, 'count', Config.KeyItem, { Plate = plate, Serial = vehicle.serial })
    return type(count) == 'number' and count > 0
end

local function isNearNPC(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local npc = Config.NPC.coords
    return #(GetEntityCoords(ped) - vector3(npc.x, npc.y, npc.z)) <= MAX_NPC_DISTANCE
end

local function getNearbyVehicle(src, netId, maxDistance)
    if type(netId) ~= 'number' then return nil end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > maxDistance then return nil end
    return vehicle
end

local function charge(player, price)
    if price <= 0 then return true end
    return player.removeMoney('cash', price, 'jj_keysystem') or player.removeMoney('bank', price, 'jj_keysystem')
end

-- Devuelve el jugador y el vehículo si puede usar el cerrajero con esa matrícula
local function getLocksmithRequest(src, rawPlate)
    local player = JJ.GetPlayer(src)
    local plate = normalizePlate(rawPlate)
    if not player or not plate or not isNearNPC(src) then return nil end
    local vehicle = getVehicleRow(plate)
    if not vehicle or vehicle.owner ~= player.identifier then return nil end
    return player, vehicle, plate
end

-- Callbacks y eventos

lib.callback.register('jj_keysystem:checkOwnership', function(source, plate)
    return hasKey(source, plate)
end)

lib.callback.register('jj_keysystem:server:getMyCars', function(source)
    local player = JJ.GetPlayer(source)
    if not player then return {} end
    return MySQL.query.await('SELECT plate, model, serial FROM jj_vehicles WHERE owner = ?', { player.identifier }) or {}
end)

RegisterNetEvent('jj_keysystem:setDoors', function(netId, state)
    local src = source
    if state ~= 1 and state ~= 2 then return end
    local vehicle = getNearbyVehicle(src, netId, MAX_VEHICLE_DISTANCE)
    if vehicle and hasKey(src, GetVehicleNumberPlateText(vehicle)) then
        SetVehicleDoorsLocked(vehicle, state)
    end
end)

-- La prueba de la ganzúa se resuelve en el cliente: la distancia y la espera limitan el abuso
RegisterNetEvent('jj_keysystem:server:lockpicked', function(netId)
    local src = source
    local now = os.time()
    if lockpickCooldowns[src] and now - lockpickCooldowns[src] < LOCKPICK_COOLDOWN then return end

    local vehicle = getNearbyVehicle(src, netId, MAX_LOCKPICK_DISTANCE)
    if vehicle then
        lockpickCooldowns[src] = now
        SetVehicleDoorsLocked(vehicle, 1)
    end
end)

RegisterNetEvent('jj_keysystem:server:CreateKey', function(rawPlate)
    local src = source
    local player, vehicle, plate = getLocksmithRequest(src, rawPlate)
    if not player then return end

    if not charge(player, Config.KeyCopyPrice) then
        return notify(src, 'No tienes suficiente dinero', 'error')
    end

    local serial = vehicle.serial
    if not serial then
        serial = generateSerial()
        saveSerial(plate, serial)
    end

    exports.ox_inventory:AddItem(src, Config.KeyItem, 1, {
        Car = vehicle.model:upper(),
        Plate = plate,
        Owner = player.getName(),
        Serial = serial,
    })
    notify(src, 'Has creado una copia de la llave', 'success')
end)

-- Las copias anteriores dejan de funcionar al cambiar el serial
RegisterNetEvent('jj_keysystem:server:ChangeSerial', function(rawPlate)
    local src = source
    local player, _, plate = getLocksmithRequest(src, rawPlate)
    if not player then return end

    if not charge(player, Config.ChangeLockPrice) then
        return notify(src, 'No tienes suficiente dinero', 'error')
    end

    saveSerial(plate, generateSerial())
    notify(src, 'Has cambiado la cerradura: las llaves anteriores ya no sirven', 'success')
end)

RegisterNetEvent('jj_keysystem:server:SetMetadata', function(slot, nickname)
    local src = source
    if type(slot) ~= 'number' or type(nickname) ~= 'string' then return end
    nickname = nickname:sub(1, MAX_NICKNAME_LENGTH)

    local item = exports.ox_inventory:GetSlot(src, slot)
    if not item or item.name ~= Config.KeyItem then return end

    local metadata = item.metadata or {}
    metadata.label = nickname ~= '' and nickname or nil
    exports.ox_inventory:SetMetadata(src, slot, metadata)
end)

RegisterNetEvent('jj_keysystem:server:removeTemporalKeys', function()
    tempKeys[source] = nil
end)

-- Para otros recursos

exports('addTempKey', function(src, rawPlate)
    local plate = normalizePlate(rawPlate)
    if not plate or not JJ.GetPlayer(src) then return false end
    tempKeys[src] = tempKeys[src] or {}
    tempKeys[src][plate] = true
    return true
end)

exports('hasKey', hasKey)

AddEventHandler('playerDropped', function()
    tempKeys[source] = nil
    lockpickCooldowns[source] = nil
end)
