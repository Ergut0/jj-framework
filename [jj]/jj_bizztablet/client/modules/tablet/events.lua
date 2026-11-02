local function notify(description, notifyType)
    lib.notify({ description = description, type = notifyType or 'inform' })
end

NuiOn('business:update', function(data)
    return lib.callback.await('jj_bizztablet:updateBusiness', false, data)
end)

NuiOn('tablet:setWaypoint', function(data)
    local x, y = tonumber(data and data.x), tonumber(data and data.y)

    if not x or not y then
        notify('Este negocio no tiene ubicación', 'error')
        return
    end

    SetNewWaypoint(x + 0.0, y + 0.0)
    notify('Punto de ruta establecido', 'success')
end)

NuiOn('tablet:getCoords', function()
    local coords = GetEntityCoords(cache.ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end)

NuiOn('tablet:callJob', function(jobName)
    local number = lib.callback.await('jj_bizztablet:getRandomEmployee', false, jobName)

    if not number then
        notify('No hay nadie disponible en este momento, prueba más tarde')
        return
    end

    if GetResourceState('lb-phone') ~= 'started' then
        notify('El teléfono no está disponible', 'error')
        return
    end

    exports['lb-phone']:CreateCall({ number = number })
end)

NuiOn('tablet:createEvent', function(eventData)
    return lib.callback.await('jj_bizztablet:createEvent', false, eventData)
end)

NuiOn('tablet:updateEvent', function(eventData)
    return lib.callback.await('jj_bizztablet:updateEvent', false, eventData)
end)

NuiOn('tablet:cancelEvent', function(eventId)
    return lib.callback.await('jj_bizztablet:cancelEvent', false, eventId)
end)

NuiOn('tablet:deleteEvent', function(eventId)
    return lib.callback.await('jj_bizztablet:deleteEvent', false, eventId)
end)

RegisterNetEvent('jj_bizztablet:updateJob', function(business)
    if business then
        SendNui('tablet:updateJob', HydrateBusiness(business))
    end
end)

RegisterNetEvent('jj_bizztablet:updateJobStatus', function(name, status)
    SendNui('tablet:updateJobStatus', { name = name, status = status })
end)

RegisterNetEvent('jj_bizztablet:updateEvents', function(events)
    SendNui('tablet:updateEvents', events)
end)
