Config = {}

Config.NPC = {
    model = "csb_chin_goon",                           -- The model of the NPC to spawn
    coords = vector4(224.9, -1545.62, -86.09, 242.38), -- The coordinates where the NPC will spawn
}

Config.Target = false  -- True para usar ox_target, false para usar puntos

Config.KeyItem = "vehicle_key" -- Objeto de ox_inventory que se usa como llave
Config.KeyCopyPrice = 0        -- Precio de hacer una copia de la llave
Config.ChangeLockPrice = 0     -- Precio de cambiar la cerradura

Config.KeyItem = "vehicle_key" -- Objeto de ox_inventory que se usa como llave
Config.KeyCopyPrice = 0        -- Precio de hacer una copia de la llave
Config.ChangeLockPrice = 0     -- Precio de cambiar la cerradura

Config.Puenteo = false -- True para tener que puentear el coche, false para que no haga falta

Config.PoliceCall = function(vehicle)
    local r, g, b = GetVehicleColor(vehicle) -- Get the RGB color of the vehicle

    Notify("Se ha enviado un entorno a la policia", "inform")

    -- La categoria "police" de origen_police ya incluye police y sheriff
    TriggerServerEvent("SendAlert:police", {
        coords = GetEntityCoords(vehicle),
        title = 'Robo de Vehículo',
        type = 'FORCE',
        message = 'Están robando un vehiculo en la zona',
        job = "police",
        metadata = {
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            color = { r, g, b },
            plate = GetVehicleNumberPlateText(vehicle),
        }
    })
end
