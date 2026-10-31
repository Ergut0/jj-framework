local CHAT_DISTANCE = 25.0
local MAX_CHAT_LENGTH = 200
local ALERT_COOLDOWN = 5
local ALERT_JOBS = { police = true, sheriff = true, ambulance = true }

local function getPed(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return ped
end

local function isNear(src, target, maxDistance)
    local a, b = getPed(src), getPed(target)
    if not a or not b then return false end
    return #(GetEntityCoords(a) - GetEntityCoords(b)) <= maxDistance
end

local function getVehicle(netId)
    if type(netId) ~= 'number' then return nil end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    return vehicle
end

local function isVehicleNear(src, vehicle, maxDistance)
    local ped = getPed(src)
    return ped ~= nil and #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) <= maxDistance
end

local function isDown(target)
    local state = Player(target).state
    return state.isDead or state.isLastStand
end

-- Comandos de rol: /me y /do solo los ven los jugadores cercanos

local function sendRoleMessage(src, prefix, color, message)
    if type(message) ~= 'string' or message == '' then return end
    local ped = getPed(src)
    if not ped then return end
    if GetResourceState('jj_chat') == 'started' and exports.jj_chat:isMuted(src) then return end

    local player = JJ.GetPlayer(src)
    local name = player and player.getName() or GetPlayerName(src)
    local coords = GetEntityCoords(ped)
    local bucket = GetPlayerRoutingBucket(src)

    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        local targetPed = getPed(target)
        if targetPed and GetPlayerRoutingBucket(target) == bucket and #(coords - GetEntityCoords(targetPed)) <= CHAT_DISTANCE then
            TriggerClientEvent('chat:addMessage', target, {
                channel = 'local',
                color = color,
                args = { ('%s %s'):format(prefix, name), message:sub(1, MAX_CHAT_LENGTH) },
            })
        end
    end
end

local roleCommands = {
    me = function(src, message) sendRoleMessage(src, '[ME]', { 194, 162, 218 }, message) end,
    ['do'] = function(src, message) sendRoleMessage(src, '[DO]', { 100, 180, 240 }, message) end,
}

for name, send in pairs(roleCommands) do
    RegisterCommand(name, function(src, args)
        if src ~= 0 then
            send(src, table.concat(args, ' '))
        end
    end, false)
end

RegisterNetEvent('jj_chat:server:executeCommand', function(command, message)
    local send = roleCommands[command]
    if send then
        send(source, message)
    end
end)

-- Avisos a un trabajo: llegan solo a quien esté de servicio

local alertCooldowns = {}

local function sendAlert(src, jobName, title, message, coords)
    local now = os.time()
    if alertCooldowns[src] and now - alertCooldowns[src] < ALERT_COOLDOWN then return end
    alertCooldowns[src] = now

    for _, id in pairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(id)
        local job = player and player.getJob()
        if job and job.name == jobName and job.onDuty then
            TriggerClientEvent('jj_things:client:alert', id, { title = title, message = message, coords = coords })
        end
    end
end

RegisterNetEvent('SendAlert:police', function(data)
    local src = source
    local ped = getPed(src)
    if not ped or type(data) ~= 'table' or not ALERT_JOBS[data.job] then return end
    if type(data.title) ~= 'string' or type(data.message) ~= 'string' then return end
    -- La posición es la del jugador que avisa: la que envía el cliente no es de fiar
    sendAlert(src, data.job, data.title:sub(1, 60), data.message:sub(1, MAX_CHAT_LENGTH), GetEntityCoords(ped))
end)

-- /entorno <mensaje>: aviso a la policía
RegisterCommand('entorno', function(src, args)
    local ped = src ~= 0 and getPed(src)
    local message = table.concat(args, ' ')
    if ped and message ~= '' then
        sendAlert(src, 'police', 'Entorno', message:sub(1, MAX_CHAT_LENGTH), GetEntityCoords(ped))
    end
end, false)

-- Esposas. Devuelve true si queda esposado, false si queda libre y nil si la acción no es válida

local function canUseCuffs(src, item)
    local player = JJ.GetPlayer(src)
    if not player then return false end
    local job = player.getJob().name
    return job == 'police' or job == 'sheriff' or exports.ox_inventory:GetItemCount(src, item) > 0
end

lib.callback.register('jj_things:setPlayerCuffs', function(source, target, cuffType)
    if type(target) ~= 'number' or target == source or not isNear(source, target, 5.0) then return nil end
    local state = Player(target).state

    if cuffType == 'handcuffs' then
        if state.isCuffed or not canUseCuffs(source, 'handcuffs') then return nil end
        state:set('isCuffed', true, true)
        return true
    end

    if cuffType == 'uncuff' then
        if not state.isCuffed or not canUseCuffs(source, 'llave_negra') then return nil end
        state:set('isCuffed', false, true)
        return false
    end

    return nil
end)

-- Meter y sacar heridos de un vehículo

RegisterNetEvent('jj_things:putInVehicle', function(target, netId, seat)
    local src = source
    local vehicle = getVehicle(netId)
    if type(target) ~= 'number' or type(seat) ~= 'number' or not vehicle then return end
    if seat < 0 or seat > 16 or not isNear(src, target, 10.0) or not isDown(target) then return end
    if not isVehicleNear(src, vehicle, 15.0) or GetPedInVehicleSeat(vehicle, seat) ~= 0 then return end
    TriggerClientEvent('jj_things:client:putInVehicle', target, netId, seat)
end)

RegisterNetEvent('jj_things:outOfVehicle', function(target, netId)
    local src = source
    local vehicle = getVehicle(netId)
    if type(target) ~= 'number' or not vehicle then return end
    if not isNear(src, target, 10.0) or not isDown(target) then return end

    local targetPed = getPed(target)
    for seat = -1, 16 do
        if GetPedInVehicleSeat(vehicle, seat) == targetPed then
            TriggerClientEvent('jj_things:client:outOfVehicle', target, netId)
            return
        end
    end
end)

-- Carterismo a NPC. El cliente decide si supera la prueba, y el tiempo entre recompensas limita el abuso

local pickpocketCooldowns = {}
local pickpocketRewards = {}

RegisterNetEvent('pickpocket_standalone:attempt', function(netId, failed)
    local src = source
    if type(netId) ~= 'number' then return end

    local now = os.time()
    if pickpocketCooldowns[src] and now - pickpocketCooldowns[src] < 2 then return end
    pickpocketCooldowns[src] = now

    local ped = NetworkGetEntityFromNetworkId(netId)
    if not ped or ped == 0 or not DoesEntityExist(ped) or IsPedAPlayer(ped) then return end

    local playerPed = getPed(src)
    if not playerPed or #(GetEntityCoords(playerPed) - GetEntityCoords(ped)) > 6.0 then return end

    local state = Entity(ped).state
    local player = JJ.GetPlayer(src)
    if state.hk_pickpocket_robbed or not player then return end

    if failed then
        state:set('hk_pickpocket_robbed', true, true)
        TriggerClientEvent('pickpocket_standalone:result', src, {
            aggressive = true,
            netId = netId,
            message = 'Te ha pillado intentando robarle.',
            type = 'error',
        })
        return
    end

    local config = Config.Pickpocket
    if pickpocketRewards[src] and now - pickpocketRewards[src] < config.RewardCooldownSeconds then
        TriggerClientEvent('pickpocket_standalone:result', src, {
            aggressive = false,
            netId = netId,
            message = 'Espera un poco antes de volver a intentarlo.',
            type = 'error',
        })
        return
    end

    state:set('hk_pickpocket_robbed', true, true)
    pickpocketRewards[src] = now

    local amount = math.random(config.MinMoney, config.MaxMoney)
    player.addMoney('cash', amount, 'pickpocket')

    TriggerClientEvent('pickpocket_standalone:result', src, {
        aggressive = math.random() < config.AggressiveChance,
        netId = netId,
        message = ('Has robado %s$'):format(amount),
        type = 'success',
    })
end)

-- Objetos

local function removeOneItem(src, item)
    if exports.ox_inventory:GetItemCount(src, item) > 0 then
        exports.ox_inventory:RemoveItem(src, item, 1)
    end
end

RegisterNetEvent('jj_things:server:removeParachute', function()
    removeOneItem(source, 'parachute')
end)

RegisterNetEvent('confetti:removeItem', function()
    removeOneItem(source, 'confetti')
end)

RegisterNetEvent('removeWheelChair', function(netId)
    local src = source
    local vehicle = getVehicle(netId)
    if not vehicle or GetEntityModel(vehicle) ~= joaat('wheelchair') then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= 0 or not isVehicleNear(src, vehicle, 5.0) then return end

    DeleteEntity(vehicle)
    exports.ox_inventory:AddItem(src, 'wheelchair', 1)
end)

-- Maleteros: solo quien ocupa uno puede liberarlo

local trunkBusy = {}

lib.callback.register('jj_things:trunk:getBusy', function(_, plate)
    return type(plate) == 'string' and trunkBusy[plate] ~= nil
end)

RegisterNetEvent('jj_things:trunk:server:setBusy', function(plate, busy)
    local src = source
    if type(plate) ~= 'string' or plate == '' or #plate > 8 then return end
    if trunkBusy[plate] and trunkBusy[plate] ~= src then return end
    trunkBusy[plate] = busy and src or nil
end)

RegisterNetEvent('jj_things:trunk:server:kidnap', function(target, netId)
    local src = source
    local vehicle = getVehicle(netId)
    if type(target) ~= 'number' or not vehicle then return end
    if isNear(src, target, 6.0) and isVehicleNear(src, vehicle, 10.0) then
        TriggerClientEvent('jj_things:trunk:client:kidnapGetIn', target, netId)
    end
end)

-- La puerta la mueve quien controla el vehículo, normalmente su conductor
RegisterNetEvent('jj_things:trunk:server:door', function(netId, open, door)
    local src = source
    local vehicle = getVehicle(netId)
    if not vehicle or type(door) ~= 'number' or not isVehicleNear(src, vehicle, 10.0) then return end
    TriggerClientEvent('jj_things:trunk:client:door', NetworkGetEntityOwner(vehicle), netId, open == true, door)
end)

-- Doctor ilegal: el servidor decide los objetos necesarios y comprueba que el jugador está junto al doctor

RegisterNetEvent('jj_things:server:doctorRevive', function(index)
    local src = source
    local doctor = Config.DoctorIlegal.infoDoctor[index]
    local ped = getPed(src)
    if not doctor or not ped or not JJ.GetPlayer(src) then return end
    if #(GetEntityCoords(ped) - doctor.coords) > 5.0 then return end

    if doctor.needItems then
        for _, item in ipairs(Config.DoctorIlegal.itemsNeeded) do
            if exports.ox_inventory:GetItemCount(src, item.name) < item.amount then return end
        end
        for _, item in ipairs(Config.DoctorIlegal.itemsNeeded) do
            exports.ox_inventory:RemoveItem(src, item.name, item.amount)
        end
    end

    if GetResourceState('jj_deathsystem') == 'started' then
        exports.jj_deathsystem:revive(src)
    end
end)

-- Datos del personaje

RegisterNetEvent('consumables:server:updateDrunk', function(drunk)
    local player = JJ.GetPlayer(source)
    local value = tonumber(drunk)
    if not player or not value then return end
    value = math.max(0, math.min(100, value))
    if player.getMetadata('drunk') ~= value then
        player.setMetadata('drunk', value)
    end
end)

lib.callback.register('jj_things:callback:getPlayerCP', function(source)
    local player = JJ.GetPlayer(source)
    return player and player.getMetadata('cp') or 0
end)

-- Resolución de pantalla

lib.callback.register('jj_things:getDiscordID', function(source)
    local identifier = GetPlayerIdentifierByType(source, 'discord')
    return identifier and identifier:gsub('^discord:', '') or ''
end)

RegisterNetEvent('jj_things:kickres', function()
    DropPlayer(source, 'Tu resolución no está permitida. Usa 16:9 o 16:10 para jugar.')
end)

-- Almacenes de jefes y de trabajo

CreateThread(function()
    for jobName in pairs(Config.BossStashes) do
        local job = JJ.Config.Jobs[jobName]
        if job then
            local minGrade
            for grade, data in pairs(job.grades) do
                if data.isBoss and (not minGrade or grade < minGrade) then
                    minGrade = grade
                end
            end
            if minGrade then
                exports.ox_inventory:RegisterStash(jobName .. '-boss', 'Almacén de ' .. job.label, 100, 200000, false, { [jobName] = minGrade })
            end
        end
    end

    for jobName in pairs(Config.JobStashes) do
        local job = JJ.Config.Jobs[jobName]
        if job then
            exports.ox_inventory:RegisterStash(jobName .. '-boss', 'Almacén de ' .. job.label, 100, 200000, false, { [jobName] = 0 })
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    alertCooldowns[src] = nil
    pickpocketCooldowns[src] = nil
    pickpocketRewards[src] = nil
    for plate, occupant in pairs(trunkBusy) do
        if occupant == src then
            trunkBusy[plate] = nil
        end
    end
end)
