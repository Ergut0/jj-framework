-- Tienda de Ethereum. Saldo, precios y permisos se comprueban siempre aquí
local ACCOUNT = 'ethereum'
local BUY_DELAY = 500

local minutesOnline = {} -- source -> minutos desde el último pago
local lastBuy = {}
local busy = {}

local function canBuy(item, jobName)
    if not item.buyers then return true end

    local buyers = type(item.buyers) == 'table' and item.buyers or { item.buyers }
    for _, buyer in pairs(buyers) do
        if jobName:find(buyer, 1, true) then return true end
    end
    return false
end

local function isSold(item)
    if item.type == 'vehicle' then return GetResourceState('jj_garages') == 'started' end
    return item.type == 'item' and exports.ox_inventory:Items(item.name) ~= nil
end

CreateThread(function()
    if not JJ.Config.Accounts[ACCOUNT] then
        print('^1[jj_tienda] Falta la cuenta ethereum en Config.Accounts de jj-framework^7')
    end

    for _, item in ipairs(Config.Items) do
        if not isSold(item) then
            print(('^3[jj_tienda] %s no se vende: no existe en ox_inventory o su tipo no está admitido^7'):format(tostring(item.name)))
        end
    end
end)

lib.callback.register('jj_tienda:getStore', function(source)
    local player = JJ.GetPlayer(source)
    if not player then return nil end

    local jobName = player.getJob().name
    local items = {}
    for _, item in ipairs(Config.Items) do
        if isSold(item) and canBuy(item, jobName) then
            items[#items + 1] = { index = item.index, img = item.img, label = item.label, price = item.price, category = item.category }
        end
    end

    return { balance = player.getMoney(ACCOUNT) or 0, items = items }
end)

local function buy(source, player, index)
    local item = type(index) == 'number' and Config.Items[math.tointeger(index)]
    if not item or not isSold(item) or not canBuy(item, player.getJob().name) then
        return { ok = false, message = 'Ese artículo no está disponible' }
    end

    local isVehicle = item.type == 'vehicle'
    if not isVehicle and not exports.ox_inventory:CanCarryItem(source, item.name, 1) then
        return { ok = false, message = 'No te cabe en el inventario' }
    end

    if not player.removeMoney(ACCOUNT, item.price, 'Tienda: ' .. item.label) then
        return { ok = false, message = 'No tienes suficiente Ethereum' }
    end

    -- Ya está cobrado: si la entrega falla o da error, se devuelve el dinero
    local ok, delivered = pcall(function()
        if isVehicle then return exports.jj_garages:addVehicle(player.identifier, item.name) end
        return exports.ox_inventory:AddItem(source, item.name, 1)
    end)

    if not ok or not delivered then
        if not ok then print(('^1[jj_tienda] Error al entregar %s: %s^7'):format(item.name, tostring(delivered))) end
        player.addMoney(ACCOUNT, item.price, 'Devolución de la tienda: ' .. item.label)
        return { ok = false, message = 'No se ha podido entregar el artículo', balance = player.getMoney(ACCOUNT) }
    end

    local message = isVehicle
        and ('Has comprado %s. Está en tu garaje con la matrícula %s'):format(item.label, delivered)
        or ('Has comprado %s'):format(item.label)
    return { ok = true, message = message, balance = player.getMoney(ACCOUNT) }
end

lib.callback.register('jj_tienda:buy', function(source, index)
    local player = JJ.GetPlayer(source)
    if not player then return nil end

    local now = GetGameTimer()
    if busy[source] or (lastBuy[source] and now - lastBuy[source] < BUY_DELAY) then
        return { ok = false, message = 'Espera un momento' }
    end
    lastBuy[source] = now
    busy[source] = true

    local ok, result = pcall(buy, source, player, index)
    busy[source] = nil

    if not ok then
        print(('^1[jj_tienda] Error en la compra: %s^7'):format(tostring(result)))
        return { ok = false, message = 'Ha ocurrido un error' }
    end
    return result
end)

-- Ethereum por tiempo de juego

local function canEarn(source)
    if not Config.OnlyForGangs then return true end
    if GetResourceState('jj_gangs') ~= 'started' then return false end
    return exports.jj_gangs:getGang(source) ~= nil
end

local function payOnlineTime(source, player)
    local minutes = (minutesOnline[source] or 0) + 1
    if minutes < Config.MinutesPerGive then
        minutesOnline[source] = minutes
        return
    end
    minutesOnline[source] = 0

    if not canEarn(source) then return end

    local amount = Config.EthereumToGive * (Config.JobsMultiplier[player.getJob().name] or 1)
    if player.addMoney(ACCOUNT, amount, 'Tiempo de juego') then
        JJ.Notify(source, ('Has recibido %d de Ethereum por tu tiempo en la ciudad'):format(amount), 'success')
    end
end

CreateThread(function()
    while true do
        Wait(60000)
        for _, source in pairs(JJ.GetPlayers()) do
            local player = JJ.GetPlayer(source)
            if player and player.isSpawned() then
                local ok, err = pcall(payOnlineTime, source, player)
                if not ok then print(('^1[jj_tienda] Error al pagar: %s^7'):format(tostring(err))) end
            end
        end
    end
end)

AddEventHandler('jj:server:playerDropped', function(source)
    minutesOnline[source] = nil
    lastBuy[source] = nil
    busy[source] = nil
end)
