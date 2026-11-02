-- Radio y acciones de banda. Banda, objeto y distancia se comprueban siempre aquí
local ACTION_DELAY = 500

local frequencies = {} -- id de banda -> frecuencia -> source -> nombre
local members = {}     -- source -> { gangId, frequency, channel }
local viewers = {}     -- source -> id de banda con el panel abierto
local gangCuffed = {}  -- source esposado desde este panel
local bagged = {}      -- source -> id de red de la bolsa
local lastAction = {}

local function getGang(source)
    if GetResourceState('jj_gangs') ~= 'started' then return nil end
    local gang = exports.jj_gangs:getGang(source)
    return gang
end

local function getFrequencyList(gangId)
    local list = {}
    local gangFrequencies = frequencies[gangId] or {}
    for frequency = 1, Config.Frequencies do
        local players = {}
        for id, name in pairs(gangFrequencies[frequency] or {}) do
            players[#players + 1] = { id = id, name = name }
        end
        table.sort(players, function(a, b) return a.name < b.name end)
        list[frequency] = players
    end
    return list
end

local function syncGang(gangId)
    local list
    for source, viewedGang in pairs(viewers) do
        if viewedGang == gangId then
            list = list or getFrequencyList(gangId)
            TriggerClientEvent('jj_radioilegal:client:sync', source, list)
        end
    end
end

local function removeMember(source)
    local member = members[source]
    if not member then return nil end

    members[source] = nil
    local gangFrequencies = frequencies[member.gangId]
    if gangFrequencies and gangFrequencies[member.frequency] then
        gangFrequencies[member.frequency][source] = nil
    end
    syncGang(member.gangId)
    return member
end

-- Saca al jugador de la radio. message avisa de por qué, si la desconexión no la ha pedido él
local function disconnect(source, message)
    local member = removeMember(source)
    if not member then return end

    if Player(source).state.radioChannel == member.channel then
        exports['pma-voice']:setPlayerRadio(source, 0)
    end
    TriggerClientEvent('jj_radioilegal:client:disconnected', source, message)
end

local function failure(message)
    return { ok = false, message = message }
end

lib.callback.register('jj_radioilegal:open', function(source)
    local player = JJ.GetPlayer(source)
    local gang = player and getGang(source)
    if not gang then return nil end

    viewers[source] = gang.id
    local member = members[source]
    return {
        gang = gang.label,
        name = player.getName(),
        frequency = member and member.frequency or nil,
        frequencies = getFrequencyList(gang.id),
    }
end)

RegisterNetEvent('jj_radioilegal:server:close', function()
    viewers[source] = nil
end)

lib.callback.register('jj_radioilegal:join', function(source, frequency)
    local player = JJ.GetPlayer(source)
    local gang = player and getGang(source)
    if not gang then return failure('No tienes banda para usar la radio') end

    frequency = type(frequency) == 'number' and math.tointeger(frequency)
    if not frequency or frequency < 1 or frequency > Config.Frequencies then
        return failure('Esa frecuencia no existe')
    end

    if exports.ox_inventory:GetItemCount(source, Config.RadioItem) < 1 then
        return failure('No tienes una radio para conectarte a la frecuencia')
    end

    removeMember(source)

    local channel = Config.BaseChannel + gang.id * Config.ChannelsPerGang + frequency
    members[source] = { gangId = gang.id, frequency = frequency, channel = channel }

    local gangFrequencies = frequencies[gang.id] or {}
    frequencies[gang.id] = gangFrequencies
    gangFrequencies[frequency] = gangFrequencies[frequency] or {}
    gangFrequencies[frequency][source] = player.getName()

    exports['pma-voice']:setPlayerRadio(source, channel)
    syncGang(gang.id)

    return { ok = true, frequency = frequency }
end)

RegisterNetEvent('jj_radioilegal:server:leave', function()
    disconnect(source)
end)

-- Acciones sobre otros jugadores

local function isDown(state)
    return state.isDead or state.isLastStand
end

-- Devuelve el estado del objetivo, o nil y el motivo si la acción no es válida
local function checkAction(source, target)
    local now = GetGameTimer()
    if lastAction[source] and now - lastAction[source] < ACTION_DELAY then return nil, 'Espera un momento' end
    lastAction[source] = now

    if not JJ.GetPlayer(source) or not getGang(source) then return nil, 'No tienes banda' end

    local ownState = Player(source).state
    if ownState.isCuffed or isDown(ownState) then return nil, 'Ahora no puedes hacer eso' end

    if type(target) ~= 'number' or target == source or not JJ.GetPlayer(target) then
        return nil, 'No hay nadie cerca'
    end

    local ped, targetPed = GetPlayerPed(source), GetPlayerPed(target)
    if not ped or ped == 0 or not targetPed or targetPed == 0 then return nil, 'No hay nadie cerca' end
    -- Margen sobre la distancia del cliente: el servidor recibe las posiciones con retraso
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > Config.ActionDistance + 2.0 then
        return nil, 'No hay nadie cerca'
    end

    return Player(target).state
end

lib.callback.register('jj_radioilegal:cuff', function(source, target)
    local state, reason = checkAction(source, target)
    if not state then return failure(reason) end

    if state.isCuffed then
        if not gangCuffed[target] and exports.ox_inventory:GetItemCount(source, Config.UncuffItem) < 1 then
            return failure('Necesitas una llave para quitarle estas esposas')
        end
        gangCuffed[target] = nil
        state:set('isCuffed', false, true)
        state:set('isEscorted', false, true)
        return { ok = true, cuffed = false }
    end

    state:set('isCuffed', true, true)
    gangCuffed[target] = true
    return { ok = true, cuffed = true }
end)

lib.callback.register('jj_radioilegal:vehicle', function(source, target, netId, seat)
    local state, reason = checkAction(source, target)
    if not state then return failure(reason) end

    if not state.isCuffed and not isDown(state) then
        return failure('El jugador tiene que estar abatido o esposado')
    end

    local vehicle = type(netId) == 'number' and NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return failure('No hay ningún vehículo cerca') end
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(vehicle)) > Config.VehicleDistance + 4.0 then
        return failure('El vehículo está muy lejos')
    end

    if seat == nil then
        if GetVehiclePedIsIn(GetPlayerPed(target), false) ~= vehicle then return failure('No está en ese vehículo') end
        TriggerClientEvent('jj_things:client:outOfVehicle', target, netId)
        return { ok = true }
    end

    seat = type(seat) == 'number' and math.tointeger(seat)
    if not seat or seat < 0 or seat > 16 or GetPedInVehicleSeat(vehicle, seat) ~= 0 then
        return failure('No hay asientos libres')
    end

    state:set('isEscorted', false, true)
    TriggerClientEvent('jj_things:client:putInVehicle', target, netId, seat)
    return { ok = true }
end)

-- Bolsa en la cabeza. Quien la lleva no puede quitársela: se le quita al liberarlo o al levantarse

local function removeBag(target)
    local netId = bagged[target]
    bagged[target] = nil

    local player = Player(target)
    if player and player.state then player.state:set('hasHeadbag', false, true) end

    local bag = netId and netId ~= 0 and NetworkGetEntityFromNetworkId(netId)
    if bag and bag ~= 0 and DoesEntityExist(bag) and GetEntityModel(bag) == joaat(Config.HeadbagModel) then
        DeleteEntity(bag)
    end
end

lib.callback.register('jj_radioilegal:headbag', function(source, target)
    local state, reason = checkAction(source, target)
    if not state then return failure(reason) end

    if bagged[target] then
        removeBag(target)
        return { ok = true, bagged = false }
    end

    if not state.isCuffed and not isDown(state) then
        return failure('El jugador tiene que estar abatido o esposado')
    end

    bagged[target] = 0
    state:set('hasHeadbag', true, true)
    return { ok = true, bagged = true }
end)

-- El cliente con la bolsa la crea para que siga su cabeza; aquí se guarda para borrarla si se desconecta
RegisterNetEvent('jj_radioilegal:server:headbagProp', function(netId)
    local src = source
    if bagged[src] == 0 and type(netId) == 'number' then
        bagged[src] = netId
    end
end)

-- Si lo liberan por otro lado (policía, llave), las esposas de este panel dejan de contar
AddStateBagChangeHandler('isCuffed', nil, function(bagName, _, value)
    if value then return end
    local target = GetPlayerFromStateBagName(bagName)
    if target and target ~= 0 then gangCuffed[target] = nil end
end)

-- Comprobaciones periódicas

local function checkMember(source, member)
    if not JJ.GetPlayer(source) then
        disconnect(source)
        return
    end

    local gang = getGang(source)
    if not gang or gang.id ~= member.gangId then
        disconnect(source, 'Ya no perteneces a esa banda: radio desconectada')
    elseif exports.ox_inventory:GetItemCount(source, Config.RadioItem) < 1 then
        disconnect(source, 'Te has quedado sin radio')
    elseif Player(source).state.radioChannel ~= member.channel then
        -- Se ha cambiado a otra radio, como la de la policía
        disconnect(source)
    end
end

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        for source, member in pairs(members) do
            local ok, err = pcall(checkMember, source, member)
            if not ok then print(('^1[jj_radioilegal] Error al comprobar la radio: %s^7'):format(tostring(err))) end
        end

        for target in pairs(bagged) do
            local state = Player(target).state
            if not state.isCuffed and not isDown(state) then removeBag(target) end
        end
    end
end)

AddEventHandler('jj:server:playerDropped', function(source)
    removeMember(source)
    viewers[source] = nil
    gangCuffed[source] = nil
    lastAction[source] = nil
    if bagged[source] then removeBag(source) end
end)

-- Al parar el recurso nadie se queda con la bolsa puesta ni en un canal que ya no se comprueba
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for target in pairs(bagged) do removeBag(target) end
    for source in pairs(members) do disconnect(source) end
end)
