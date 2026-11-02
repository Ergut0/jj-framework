-- Objeto, comando de administración y eventos del cliente.

RegisterCommand(Config.AdminCommand, function() UI.Open('admin') end, false)

-- Se abre con el objeto del inventario: client = { export = 'jj_crews.openTablet' } en data/items.lua
exports('openTablet', function()
    UI.Open('player')
end)

-- El servidor avisa cuando cambian los datos del crew o llegan invitaciones
RegisterNetEvent('crews:client:refresh', function()
    UI.Refresh()
end)
