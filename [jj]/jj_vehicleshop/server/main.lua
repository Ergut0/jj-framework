local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local STATE_OUT = 0
local TEST_BUCKET_BASE = 20000
local TEST_GRACE = 15000 -- ms de margen antes de que el servidor termine una prueba por su cuenta

local sessions = {} -- [source] = concesionario abierto
local tests = {} -- [source] = prueba de conducción en curso
local buying = {} -- [source] = compra en curso
local deliveries = {} -- [source] = matrícula recién comprada

-- La tarjeta de empresa no cobra nada: solo vale donde el concesionario lo permite
local function isMethodAllowed(dealership, method, vehicle)
    if method == 'cp' then return (tonumber(vehicle.coins) or 0) > 0 end
    return method == 'cash' or method == 'bank' or (method == 'company' and dealership.company_card == true)
end

local function hasJob(player, restricted)
    if not restricted then return true end
    local jobName = player.getJob().name
    for _, job in pairs(restricted) do
        if job == jobName then
            return true
        end
    end
    return false
end

-- El concesionario solo se abre junto a un vendedor suyo y con el trabajo o permiso que pida
local function getOpenError(src, player, name)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return 'too_far' end

    local coords = GetEntityCoords(ped)
    local denied = false
    for _, seller in ipairs(Config.Peds) do
        if seller.concesionario == name and #(coords - seller.coords) <= Config.MaxPedDistance then
            local allowed = hasJob(player, seller.restricted)
                and (not seller.isVip or IsPlayerAceAllowed(tostring(src), Config.VipAce))
            if allowed then return nil end
            denied = true
        end
    end
    return denied and 'no_access' or 'too_far'
end

-- Devuelve el concesionario abierto por el jugador y sus datos
local function getSession(src)
    local name = sessions[src]
    local player = JJ.GetPlayer(src)
    if name and player and Config.Dealerships[name] then
        return Config.Dealerships[name], player
    end
end

local function dealerSells(dealership, category)
    for _, name in ipairs(dealership.categories) do
        if name == category then
            return Config.Categories[category] ~= nil
        end
    end
    return false
end

-- Busca el vehículo en la configuración: el precio nunca sale de lo que envía el cliente
local function findVehicle(dealership, category, model)
    if type(category) ~= 'string' or type(model) ~= 'string' or not dealerSells(dealership, category) then
        return nil
    end
    for _, vehicle in ipairs(Config.Categories[category]) do
        if vehicle.name == model then
            return vehicle
        end
    end
end

-- Concesionario

lib.callback.register('jj_vehicleshop:server:open', function(source, name)
    local player = JJ.GetPlayer(source)
    if not player or type(name) ~= 'string' or not Config.Dealerships[name] or tests[source] then
        return { ok = false, error = 'no_access' }
    end

    local reason = getOpenError(source, player, name)
    if reason then
        return { ok = false, error = reason }
    end

    sessions[source] = name
    return { ok = true }
end)

RegisterNetEvent('jj_vehicleshop:server:close', function()
    sessions[source] = nil
end)

lib.callback.register('jj_vehicleshop:server:getCategory', function(source, category)
    local dealership = getSession(source)
    if not dealership or type(category) ~= 'string' or not dealerSells(dealership, category) then
        return nil
    end
    return Config.Categories[category]
end)

-- Compra

lib.callback.register('jj_vehicleshop:server:buy', function(source, category, model, method)
    local dealership, player = getSession(source)
    if not dealership or not dealership.buy_vehicle then return { ok = false, error = 'no_access' } end
    if buying[source] then return { ok = false, error = 'buy_failed' } end

    local vehicle = findVehicle(dealership, category, model)
    if not vehicle then return { ok = false, error = 'not_available' } end

    if not isMethodAllowed(dealership, method, vehicle) then return { ok = false, error = 'buy_failed' } end

    local cost = method == 'cp' and vehicle.coins or vehicle.price
    buying[source] = true

    local ok, paid = pcall(function()
        return exports.jj_paymethods:Pay(source, vehicle.price, method, vehicle.coins)
    end)
    if not ok then
        print(('[jj_vehicleshop] No se puede cobrar: %s. ¿Está arrancado y actualizado jj_paymethods?'):format(paid))
        buying[source] = nil
        return { ok = false, error = 'payment_unavailable' }
    end
    if not paid then
        buying[source] = nil
        return { ok = false, error = 'not_enough_money' }
    end

    local plate = exports.jj_garages:addVehicle(player.identifier, model, dealership.garage)
    buying[source] = nil

    if not plate then
        -- Con la tarjeta de empresa no se ha cobrado nada
        if method == 'cp' then
            JJ.AddCP(source, cost, 'jj_vehicleshop_refund')
        elseif method ~= 'company' then
            player.addMoney(method, cost, 'jj_vehicleshop_refund')
        end
        return { ok = false, error = 'buy_failed' }
    end

    deliveries[source] = plate
    sessions[source] = nil
    print(('[jj_vehicleshop] %s (%d) compra %s por %d con %s. Matrícula %s'):format(player.getName(), source, model, cost, method, plate))
    return { ok = true, plate = plate, model = model }
end)

-- El vehículo queda en el garaje hasta que aparece en el mundo: si falla, no se pierde
RegisterNetEvent('jj_vehicleshop:server:delivered', function()
    local src = source
    local plate = deliveries[src]
    if plate then
        deliveries[src] = nil
        MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE plate = ?', { STATE_OUT, plate })
    end
end)

-- Prueba de conducción: se hace en un mundo aparte para no cruzarse con nadie

local function deleteTestVehicle(test)
    local entity = test.netId and NetworkGetEntityFromNetworkId(test.netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function finishTest(src)
    local test = tests[src]
    if not test then return end
    tests[src] = nil
    deleteTestVehicle(test)
    if GetPlayerName(src) then
        SetPlayerRoutingBucket(src, test.bucket)
    end
end

lib.callback.register('jj_vehicleshop:server:startTest', function(source, category, model)
    local dealership = getSession(source)
    if not dealership or not dealership.test_vehicles or tests[source] or not findVehicle(dealership, category, model) then
        return false
    end

    local test = { bucket = GetPlayerRoutingBucket(source) }
    tests[source] = test
    sessions[source] = nil
    SetPlayerRoutingBucket(source, TEST_BUCKET_BASE + source)

    -- Por si el cliente nunca avisa del final de la prueba
    SetTimeout(Config.DriveTestTime * 60000 + TEST_GRACE, function()
        if tests[source] == test then
            finishTest(source)
        end
    end)
    return true
end)

RegisterNetEvent('jj_vehicleshop:server:testVehicle', function(netId)
    local test = tests[source]
    if test and type(netId) == 'number' then
        test.netId = netId
    end
end)

RegisterNetEvent('jj_vehicleshop:server:endTest', function()
    finishTest(source)
end)

-- Administración: registra a tu nombre el vehículo en el que vas

RegisterCommand('registrarcoche', function(src)
    if src == 0 then return end
    if not JJ.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { description = Lang['no_permission'], type = 'error' })
        return
    end
    TriggerClientEvent('jj_vehicleshop:client:registerCurrent', src)
end, false)

lib.callback.register('jj_vehicleshop:server:registerCurrent', function(source, model)
    local player = JJ.GetPlayer(source)
    if not player or not JJ.IsAdmin(source) or type(model) ~= 'string' then return nil end

    local plate = exports.jj_garages:addVehicle(player.identifier, model)
    if plate then
        MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE plate = ?', { STATE_OUT, plate })
        print(('[jj_vehicleshop] %s (%d) registra %s. Matrícula %s'):format(player.getName(), source, model, plate))
    end
    return plate
end)

AddEventHandler('playerDropped', function()
    local src = source
    finishTest(src)
    sessions[src] = nil
    buying[src] = nil
    deliveries[src] = nil
end)
