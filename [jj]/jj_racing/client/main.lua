-- Objeto, comandos y eventos generales del cliente.

RegisterCommand(Config.AdminCommand, function() UI.Open('admin') end, false)

-- Se abre con el objeto del inventario: client = { export = 'jj_racing.openTablet' } en data/items.lua
exports('openTablet', function()
    UI.Open('player')
end)

Current = { lobby = nil }

RegisterNetEvent('races:client:notify', function(text, kind, ms)
    if type(text) == 'string' then Notify(text, kind, ms) end
end)

-- El servidor avisa cuando cambian los datos (retos, invitaciones, ajustes)
RegisterNetEvent('races:client:refresh', function()
    UI.Refresh()
end)

-- Estado de la sala del jugador (false = ya no esta en ninguna)
RegisterNetEvent('races:client:lobby', function(view)
    Current.lobby = view or nil
    SendNUIMessage({ action = 'lobby', lobby = view or false })
end)

-- Comprobacion de vehiculo antes de la salida: el servidor contrasta el modelo con su propia vista
RegisterNetEvent('races:client:vehicleCheck', function(lobbyId, token)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        TriggerServerEvent('races:server:vehicleCheck', lobbyId, token, 0, -1, '')
        return
    end
    local model = GetEntityModel(veh)
    TriggerServerEvent('races:server:vehicleCheck', lobbyId, token, model, GetVehicleClass(veh), GetDisplayNameFromVehicleModel(model))
end)

-- Resultados finales: se muestran en el panel unos instantes despues de la meta
RegisterNetEvent('races:client:results', function(payload)
    SetTimeout(2500, function()
        if UI.isOpen then
            SendNUIMessage({ action = 'results', results = payload })
        else
            UI.Open('player', { tab = 'results', results = payload })
        end
    end)
end)

-- Resultado de la prueba de un circuito: reabre el editor
RegisterNetEvent('races:client:testResult', function(data)
    SetTimeout(1500, function()
        UI.Open('admin', { tab = 'tracks', testResult = data })
    end)
end)
