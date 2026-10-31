Config = {}

Config.Command = 'admin'
Config.DefaultKey = 'F7'

-- Permisos ACE. jj.admin puede hacerlo todo; jj.mod solo lo marcado como 'mod'
Config.AdminAce = 'jj.admin'
Config.ModAce = 'jj.mod'

Config.LogLimit = 200
Config.PlayersRefresh = 2000 -- ms entre actualizaciones de "Ver jugadores"

-- Nivel mínimo de cada acción
Config.Actions = {
    -- Jugadores
    ['goto'] = 'mod',
    bring = 'mod',
    spectate = 'mod',
    freeze = 'mod',
    revive = 'mod',
    heal = 'mod',
    kick = 'mod',
    ban = 'mod',
    viewInventory = 'mod',
    kill = 'admin',
    money = 'admin',
    setJob = 'admin',
    setDuty = 'admin',
    giveItem = 'admin',
    clearInventory = 'admin',
    giveVehicle = 'admin',

    -- Mis herramientas
    noclip = 'mod',
    invisible = 'mod',
    players = 'mod',
    tpWaypoint = 'mod',
    tpCoords = 'mod',
    god = 'admin',

    -- Vehículos
    vehicleRepair = 'mod',
    vehicleFlip = 'mod',
    vehicleDelete = 'mod',
    spawnVehicle = 'admin',
    clearVehicles = 'admin',

    -- Servidor
    announce = 'mod',
    weather = 'admin',
    time = 'admin',
    saveAll = 'admin',
    unban = 'admin',
    banOffline = 'admin',
}

Config.Weather = {
    { value = 'EXTRASUNNY', label = 'Muy soleado' },
    { value = 'CLEAR', label = 'Despejado' },
    { value = 'CLOUDS', label = 'Nublado' },
    { value = 'OVERCAST', label = 'Muy nublado' },
    { value = 'FOGGY', label = 'Niebla' },
    { value = 'RAIN', label = 'Lluvia' },
    { value = 'THUNDER', label = 'Tormenta' },
    { value = 'SNOW', label = 'Nieve' },
    { value = 'HALLOWEEN', label = 'Halloween' },
}

Config.VehiclePresets = { 'adder', 'zentorno', 't20', 'sultan', 'police', 'ambulance', 'sanchez', 'buzzard2', 'dinghy' }
