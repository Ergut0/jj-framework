local MAX_DISTANCE = 6.0
local VEHICLE_DISTANCE = 12.0
local STATE_OUT = 0
local STATE_IMPOUND = 2

local PROP_ITEMS = {
    prop_mp_cone_02 = true,
    prop_barrier_work05 = true,
    prop_parking_sign_1 = true,
    prop_mp_barrier_02b = true,
    prop_air_conelight = true,
}

local function getDutyJob(src)
    local player = JJ.GetPlayer(src)
    if not player then return nil end

    local job = player.getJob()
    return player, job.onDuty and job or nil
end

local function isPolice(src)
    local player, job = getDutyJob(src)
    if job and Config.PoliceJobs[job.name] then return player, job end
end

local function isAssist(src)
    local player, job = getDutyJob(src)
    if job and (Config.PoliceJobs[job.name] or Config.AssistJobs[job.name]) then return player, job end
end

local function isNear(src, target, distance)
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if a == 0 or b == 0 then return false end

    return #(GetEntityCoords(a) - GetEntityCoords(b)) <= distance
end

local function getNearbyVehicle(src, netId)
    local vehicle = type(netId) == 'number' and NetworkGetEntityFromNetworkId(netId) or 0
    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return nil end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(vehicle)) > VEHICLE_DISTANCE then return nil end

    return vehicle
end

local function trimPlate(plate)
    return (plate or ''):gsub('^%s*(.-)%s*$', '%1')
end

-- ==================== Armerías ====================

local function itemExists(name)
    return exports.ox_inventory:Items(name) ~= nil
end

local function registerShops()
    local groups = {}
    for job in pairs(Config.PoliceJobs) do groups[job] = 0 end

    for name, items in pairs(Config.itemsArmory) do
        local inventory, missing = {}, {}

        for _, item in ipairs(items) do
            if itemExists(item.name) then
                local metadata = item.serial and { serial = item.serial } or nil
                if item.components then
                    metadata = metadata or {}
                    metadata.components = item.components
                end
                inventory[#inventory + 1] = { name = item.name, price = 0, metadata = metadata }
            else
                missing[#missing + 1] = item.name
            end
        end

        exports.ox_inventory:RegisterShop(name, { name = 'Armería', inventory = inventory, groups = groups })

        if #missing > 0 then
            print(('^3[jj_policejob] %s: estos objetos no existen en ox_inventory y no salen en la armería: %s^7'):format(name, table.concat(missing, ', ')))
        end
    end
end

CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(500) end
    Wait(1000)
    registerShops()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' then
        SetTimeout(1000, registerShops)
    end
end)

RegisterNetEvent('jj_policejob:server:giveBasicEquipment', function()
    local src = source
    if not isPolice(src) then return end

    local given = 0
    for _, entry in ipairs(Config.basicEquipment) do
        -- Quien ya lo tiene no recibe otro: la munición y el resto salen de la armería
        if itemExists(entry.item) and exports.ox_inventory:GetItemCount(src, entry.item) == 0 then
            local metadata = entry.serial and { serial = entry.serial } or nil
            if exports.ox_inventory:AddItem(src, entry.item, entry.amount, metadata) then
                given += 1
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        description = given > 0 and 'Has recibido el equipamiento básico' or 'Ya tienes el equipamiento básico',
        type = given > 0 and 'success' or 'inform',
    })
end)

RegisterNetEvent('jj_policejob:server:saveEquipment', function()
    local src = source
    if not isPolice(src) then return end

    local names = {}
    for _, entry in ipairs(Config.basicEquipment) do names[entry.item] = true end
    for _, items in pairs(Config.itemsArmory) do
        for _, item in ipairs(items) do names[item.name] = true end
    end

    for name in pairs(names) do
        if itemExists(name) then
            local count = exports.ox_inventory:GetItemCount(src, name)
            if count > 0 then
                exports.ox_inventory:RemoveItem(src, name, count)
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { description = 'Equipamiento guardado', type = 'success' })
end)

RegisterNetEvent('jj_policejob:server:OpenTrash', function()
    local src = source
    if not isPolice(src) then return end

    local id = exports.ox_inventory:CreateTemporaryStash({ label = 'Papelera', slots = 30, maxWeight = 100000 })
    exports.ox_inventory:forceOpenInventory(src, 'stash', id)
end)

-- ==================== Servicio y jefes ====================

RegisterNetEvent('jj_policejob:server:toggleDuty', function()
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then return end

    local job = player.getJob()
    if not Config.PoliceJobs[job.name] then return end

    player.setDuty(not job.onDuty)
    TriggerClientEvent('ox_lib:notify', src, {
        description = job.onDuty and 'Has salido de servicio' or 'Has entrado de servicio',
        type = 'inform',
    })
end)

local function getBoss(src)
    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    if job and Config.PoliceJobs[job.name] and job.isBoss then return job end
end

RegisterNetEvent('jj_policejob:hireEmployee', function(target)
    local job = getBoss(source)
    local player = job and JJ.GetPlayer(tonumber(target) or -1)
    if player then player.setJob(job.name, 0) end
end)

RegisterNetEvent('jj_policejob:fireEmployee', function(target)
    local job = getBoss(source)
    local player = job and JJ.GetPlayer(tonumber(target) or -1)
    if player and player.getJob().name == job.name then
        player.setJob(JJ.Config.DefaultJob, 0)
    end
end)

RegisterNetEvent('jj_policejob:assignRank', function(target, grade)
    local job = getBoss(source)
    local player = job and JJ.GetPlayer(tonumber(target) or -1)
    if player and player.getJob().name == job.name then
        player.setJob(job.name, tonumber(grade) or 0)
    end
end)

-- ==================== Esposas, escolta y cacheo ====================

lib.callback.register('jj_policejob:callback:setPlayerCuffs', function(source, target, cuffType)
    if not isAssist(source) or type(target) ~= 'number' or target == source then return nil end
    if not JJ.GetPlayer(target) or not isNear(source, target, MAX_DISTANCE) then return nil end

    local state = Player(target).state

    if cuffType == 'handcuffs' then
        if state.isCuffed then return nil end
        state:set('isCuffed', true, true)
        return true
    end

    if cuffType == 'uncuff' then
        if not state.isCuffed then return nil end
        state:set('isCuffed', false, true)
        state:set('isEscorted', false, true)
        return false
    end

    return nil
end)

lib.callback.register('jj_policejob:callback:setPlayerEscort', function(source, target, isAttached)
    if type(target) ~= 'number' or target == source or not isNear(source, target, MAX_DISTANCE) then return nil end
    if not JJ.GetPlayer(target) then return nil end

    local state = Player(target).state

    if isAttached then
        if state.isEscorted ~= source then return nil end
        state:set('isEscorted', false, true)
        return false
    end

    if not state.isCuffed and not state.isDead then return nil end
    state:set('isEscorted', source, true)
    return true
end)

RegisterNetEvent('jj_policejob:server:searchPlayer', function(target)
    local src = source
    if type(target) ~= 'number' or target == src or not JJ.GetPlayer(target) or not isNear(src, target, MAX_DISTANCE) then return end

    local state = Player(target).state
    if isPolice(src) or state.isCuffed or state.isDead then
        exports.ox_inventory:forceOpenInventory(src, 'player', target)
    end
end)

RegisterNetEvent('jj_policejob:putInVehicle', function(target, netId, seat)
    local src = source
    if not isAssist(src) or type(target) ~= 'number' or not isNear(src, target, MAX_DISTANCE) then return end
    if not getNearbyVehicle(src, netId) then return end

    local state = Player(target).state
    if state.isCuffed or state.isDead then
        state:set('isEscorted', false, true)
        TriggerClientEvent('jj_things:client:putInVehicle', target, netId, seat)
    end
end)

RegisterNetEvent('jj_policejob:outOfVehicle', function(target, netId)
    local src = source
    if not isAssist(src) or type(target) ~= 'number' or not getNearbyVehicle(src, netId) then return end

    local state = Player(target).state
    if state.isCuffed or state.isDead then
        TriggerClientEvent('jj_things:client:outOfVehicle', target, netId)
    end
end)

RegisterNetEvent('jj_policejob:server:jail', function(target, minutes, station)
    local src = source
    if not isPolice(src) or type(target) ~= 'number' or not isNear(src, target, MAX_DISTANCE) then return end

    minutes = math.floor(tonumber(minutes) or 0)
    if minutes < 1 or minutes > Config.MaxJailMinutes then return end
    if not Config.points[station] or not Player(target).state.isCuffed then return end

    Player(target).state:set('isCuffed', false, true)
    TriggerClientEvent('jj_policejob:jail:sendToJail', target, minutes, station)
end)

-- ==================== Vehículos ====================

RegisterNetEvent('jj_policejob:server:vehicleSpawned', function(netId)
    local src = source
    if not isPolice(src) then return end

    local vehicle = getNearbyVehicle(src, netId)
    if vehicle and GetResourceState('jj_keysystem') == 'started' then
        exports.jj_keysystem:addTempKey(src, GetVehicleNumberPlateText(vehicle))
    end
end)

RegisterNetEvent('jj_policejob:server:forceVehicle', function(netId)
    local src = source
    if not isPolice(src) then return end

    local vehicle = getNearbyVehicle(src, netId)
    if vehicle then SetVehicleDoorsLocked(vehicle, 1) end
end)

-- Incautado va al depósito público; confiscado solo sale del depósito policial
RegisterNetEvent('jj_policejob:server:deleteVehicle', function(netId, confiscate)
    local src = source
    local player, job = getDutyJob(src)
    if not player or not job then return end

    local allowed = Config.PoliceJobs[job.name] or (not confiscate and Config.AssistJobs[job.name])
    local vehicle = allowed and getNearbyVehicle(src, netId)
    if not vehicle then return end

    local plate = trimPlate(GetVehicleNumberPlateText(vehicle))
    MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE plate = ?', {
        confiscate and Config.ConfiscatedState or STATE_IMPOUND, plate,
    })
    DeleteEntity(vehicle)
end)

lib.callback.register('jj_policejob:GetVehiclesInDepot', function(source)
    if not isPolice(source) then return false end

    return MySQL.query.await('SELECT plate, model AS vehicle, props AS mods FROM jj_vehicles WHERE state = ?', {
        Config.ConfiscatedState,
    }) or {}
end)

RegisterNetEvent('jj_policejob:server:updateStateVehicle', function(_, plate)
    if not isPolice(source) or type(plate) ~= 'string' then return end

    MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE plate = ? AND state = ?', {
        STATE_OUT, trimPlate(plate), Config.ConfiscatedState,
    })
end)

RegisterNetEvent('jj_policejob:server:giveStartVehicles', function()
    local src = source
    local player = isPolice(src)
    if not player or player.getMetadata('givedVehicles') then return end

    player.setMetadata('givedVehicles', true)

    for _, model in ipairs(Config.startVehicles) do
        local plate = ('POL%05d'):format(math.random(0, 99999))
        MySQL.insert.await('INSERT INTO jj_vehicles (plate, owner, model) VALUES (?, ?, ?)', {
            plate, player.identifier, model:lower(),
        })
    end

    TriggerClientEvent('ox_lib:notify', src, { description = 'Tus vehículos están en el garaje', type = 'success' })
end)

-- ==================== Otros ====================

-- Taquilla personal: la misma que usan los roperos de jj_creatorjobs
local function registerPersonalStash(src)
    local player = JJ.GetPlayer(src)
    if player then
        exports.ox_inventory:RegisterStash(player.identifier .. '-personal', 'Taquilla personal', 30, 50000, player.identifier)
    end
end

AddEventHandler('jj:server:playerLoaded', registerPersonalStash)

RegisterNetEvent('jj_policejob:server:toggleBelongings', function(keep)
    local src = source
    if not JJ.GetPlayer(src) then return end

    if keep then
        exports.ox_inventory:ConfiscateInventory(src)
    else
        exports.ox_inventory:ReturnInventory(src)
    end
end)

RegisterNetEvent('jj_policejob:server:RenewID', function()
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then return end

    local count = exports.ox_inventory:GetItemCount(src, 'id_card')
    if count > 0 then exports.ox_inventory:RemoveItem(src, 'id_card', count) end

    local charinfo = player.getCharInfo() or {}
    exports.ox_inventory:AddItem(src, 'id_card', 1, {
        Name = player.getName(),
        Nation = charinfo.nationality ~= '' and charinfo.nationality or 'Desconocida',
        Birthdate = charinfo.birthdate,
        Gender = charinfo.gender == 0 and 'Hombre' or 'Mujer',
        ID = player.identifier,
    })
end)

RegisterNetEvent('jj_policejob:server:pickUpProp', function(netId)
    local src = source
    if not isPolice(src) or type(netId) ~= 'number' then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) or not Entity(entity).state.isPropPolice then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(entity)) > MAX_DISTANCE then return end

    local model = GetEntityModel(entity)
    DeleteEntity(entity)

    for name in pairs(PROP_ITEMS) do
        if joaat(name) == model and itemExists(name) then
            exports.ox_inventory:AddItem(src, name, 1)
            return
        end
    end
end)
