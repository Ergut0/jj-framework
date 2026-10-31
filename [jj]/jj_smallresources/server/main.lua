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

local function removeItemIfHas(src, item, amount)
    if exports.ox_inventory:GetItemCount(src, item) >= amount then
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end
    return false
end

-- Cargar personas: se guardan las parejas para que nadie pueda interrumpir las de otros

local carrying = {}

RegisterNetEvent('CarryPeople:sync', function(target)
    local src = source
    if type(target) ~= 'number' or target == src or not isNear(src, target, 6.0) then return end
    carrying[src] = target
    TriggerClientEvent('CarryPeople:syncTarget', target, src)
end)

RegisterNetEvent('CarryPeople:stop', function(target)
    local src = source
    if type(target) == 'number' and (carrying[src] == target or carrying[target] == src) then
        carrying[src] = nil
        carrying[target] = nil
        if getPed(target) then
            TriggerClientEvent('CarryPeople:cl_stop', target)
        end
    end
    TriggerClientEvent('CarryPeople:cl_stop', src)
end)

-- Chalecos: se marca quién lleva cada uno para que no se pueda devolver un objeto que no se ha gastado

RegisterNetEvent('consumables:server:useArmor', function()
    local src = source
    if removeItemIfHas(src, 'armor', 1) then
        Player(src).state:set('jj_smallresources:armor', true, true)
    end
end)

RegisterNetEvent('consumables:server:useHeavyArmor', function()
    local src = source
    if removeItemIfHas(src, 'heavyarmor', 1) then
        Player(src).state:set('jj_smallresources:heavyArmor', true, true)
    end
end)

local function returnArmor(src, stateKey, item)
    local state = Player(src).state
    if state[stateKey] then
        state:set(stateKey, false, true)
        exports.ox_inventory:AddItem(src, item, 1)
    end
end

RegisterNetEvent('consumables:server:resetArmor', function()
    returnArmor(source, 'jj_smallresources:heavyArmor', 'heavyarmor')
end)

RegisterNetEvent('consumables:server:resetNormalArmor', function()
    returnArmor(source, 'jj_smallresources:armor', 'armor')
end)

-- Doctor ilegal: el servidor decide los objetos necesarios y comprueba que el jugador está junto al doctor

RegisterNetEvent('jj_smallresources:server:doctorRevive', function(index)
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

-- Identificadores y registros, usados por /cachear de jj_things

lib.callback.register('jj_smallresources:getIdentifiers', function(source, target)
    if type(target) ~= 'number' or not isNear(source, target, 6.0) then return nil end
    local player = JJ.GetPlayer(target)
    return player and { name = player.getName(), citizenid = player.identifier } or nil
end)

local logCooldowns = {}

RegisterNetEvent('jj_smallresources:server:createLongExtends', function(logType, message, channel)
    local src = source
    if type(message) ~= 'string' or #message == 0 or #message > 500 then return end

    local now = os.time()
    if logCooldowns[src] and now - logCooldowns[src] < 2 then return end
    logCooldowns[src] = now

    local player = JJ.GetPlayer(src)
    print(('[jj_smallresources][%s][%s] %s (%s): %s'):format(
        tostring(channel or 'log'), tostring(logType), player and player.getName() or 'Desconocido', src, message))
end)

AddEventHandler('playerDropped', function()
    local src = source
    logCooldowns[src] = nil

    local target = carrying[src]
    carrying[src] = nil
    if target and getPed(target) then
        TriggerClientEvent('CarryPeople:cl_stop', target)
    end
    for carrier, carried in pairs(carrying) do
        if carried == src then
            carrying[carrier] = nil
            TriggerClientEvent('CarryPeople:cl_stop', carrier)
        end
    end
end)

-- Documentos, usados por /actualizarinfopj de jj_things

local function giveDocument(src, item, extra)
    local player = JJ.GetPlayer(src)
    local charinfo = player and player.getCharInfo()
    if not charinfo then return end

    local metadata = {
        Name = player.getName(),
        Nation = charinfo.nationality ~= '' and charinfo.nationality or 'Desconocida',
        Birthdate = charinfo.birthdate,
        Gender = charinfo.gender == 0 and 'Hombre' or 'Mujer',
        ID = player.identifier,
    }
    for key, value in pairs(extra or {}) do
        metadata[key] = value
    end

    -- No duplica un documento con los mismos datos
    if exports.ox_inventory:GetItemCount(src, item, metadata, true) == 0 then
        exports.ox_inventory:AddItem(src, item, 1, metadata)
    end
end

RegisterNetEvent('smallresources:server:CreateID', function()
    giveDocument(source, 'id_card')
end)

RegisterNetEvent('smallresources:server:CreateDriverLicense', function()
    giveDocument(source, 'driver_license', { Type = 'Permiso de conducir' })
end)

-- Detector de huellas

RegisterNetEvent('detector:setPlayer', function(target)
    local src = source
    if type(target) ~= 'number' or exports.ox_inventory:GetItemCount(src, 'detector') < 1 then return end
    if isNear(src, target, 6.0) then
        TriggerClientEvent('detector:client:domyfinguer', target)
    end
end)

-- Tiendas de Config.Shops

CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        exports.ox_inventory:RegisterShop(shop.shop.name, {
            name = shop.shop.name,
            inventory = shop.shop.items,
        })
    end
end)
