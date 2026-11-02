-- Único punto de contacto con el framework y otros recursos. Para integrar otro sistema, solo se cambia aquí
Bridge = {}

function Bridge.GetPlayer(src)
    return JJ.GetPlayer(src)
end

function Bridge.GetPlayerByIdentifier(identifier)
    return JJ.GetPlayerByIdentifier(identifier)
end

function Bridge.Identifier(player)
    return player.identifier
end

function Bridge.Name(player)
    return player.getName() or 'Desconocido'
end

function Bridge.Notify(src, message, kind)
    if Config.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'inform' })
    else
        JJ.Notify(src, message, kind)
    end
end

function Bridge.AddMoney(player, amount, reason)
    if amount <= 0 then return true end
    return player.addMoney(Config.MoneyAccount, amount, reason) == true
end

function Bridge.IsAdmin(src, player)
    if JJ.IsAdmin(src) then return true end

    for _, ace in ipairs(Config.Admin.aces) do
        if IsPlayerAceAllowed(tostring(src), ace) then return true end
    end

    for _, identifier in ipairs(Config.Admin.identifiers) do
        if player and identifier == player.identifier then return true end
    end

    return false
end

-- Policías de servicio
function Bridge.GetPolice()
    local list = {}
    for _, src in pairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        local job = player and player.getJob()
        if job and Config.Police.jobs[job.name] and job.onDuty then
            list[#list + 1] = src
        end
    end
    return list
end

-- Aviso a la policía. Devuelve true si se ha enviado
function Bridge.PoliceAlert(data, coords)
    local dispatch = Config.Police.dispatch
    if dispatch == 'jj_policedispatch' then
        if GetResourceState('jj_policedispatch') ~= 'started' then return false end
        -- Un fallo del dispatch no puede parar el contrato
        local ok, id = pcall(function()
            return exports.jj_policedispatch:AddAlert({
                title = data.title,
                textAlert = data.text,
                zone = data.zone,
                type = Config.Police.alertType,
                plate = data.plate,
                vehModel = data.model,
                targetFaction = 'police',
            }, { x = coords.x, y = coords.y, z = coords.z })
        end)
        if not ok then
            print(('^3[jj_boosting] No se ha podido avisar a la policía: actualiza y reinicia jj_policedispatch (%s)^7'):format(tostring(id)))
            return false
        end
        return id ~= nil
    elseif dispatch == 'event' then
        TriggerEvent(Config.Police.event, data, { x = coords.x, y = coords.y, z = coords.z })
        return true
    end
    return false
end

-- Inventario
function Bridge.ItemExists(name)
    return exports.ox_inventory:Items(name) ~= nil
end

function Bridge.CanCarry(src, item, count)
    return exports.ox_inventory:CanCarryItem(src, item, count) == true
end

function Bridge.GiveItem(src, item, count)
    return exports.ox_inventory:AddItem(src, item, count) == true
end

function Bridge.RemoveItem(src, item, count)
    return exports.ox_inventory:RemoveItem(src, item, count) == true
end

-- Llaves de jj_keysystem para el vehículo robado
function Bridge.GiveKeys(src, plate)
    if GetResourceState('jj_keysystem') == 'started' then
        pcall(function() exports.jj_keysystem:addTempKey(src, plate) end)
    end
end
