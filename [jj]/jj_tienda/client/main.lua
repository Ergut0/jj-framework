local REOPEN_DELAY = 5000

local canOpen = true
local buying = false

-- La interfaz muestra el resultado de la compra
RegisterNUICallback('buyItem', function(data, cb)
    if buying then
        cb({ ok = false, message = 'Espera un momento' })
        return
    end
    buying = true

    local result = lib.callback.await('jj_tienda:buy', false, tonumber(data and data.index))
    buying = false
    cb(result or { ok = false, message = 'No se ha podido completar la compra' })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterCommand('tienda', function()
    if not JJ.IsSpawned() then return end

    if not canOpen then
        JJ.Notify('Espera 5 segundos antes de volver a abrir la tienda', 'error')
        return
    end

    canOpen = false
    SetTimeout(REOPEN_DELAY, function() canOpen = true end)

    -- El servidor decide qué artículos puede ver este jugador y cuánto saldo tiene
    local data = lib.callback.await('jj_tienda:getStore', false)
    if not data then return end

    SendNUIMessage({ type = 'display', ethereum = data.balance, items = data.items })
    SetNuiFocus(true, true)
end, false)

-- No dejar el ratón atrapado si el recurso se para con la tienda abierta
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
