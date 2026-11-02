Config = {}

Config.SpeedUnit = 'kmh' -- 'kmh' o 'mph'

-- Hambre y sed: de 0 a 100, se guardan con cada personaje
Config.Needs = {
    Interval = 60, -- Segundos entre cada bajada
    HungerLoss = 1.0, -- Hambre que se pierde en cada bajada
    ThirstLoss = 1.5, -- Sed que se pierde en cada bajada
    Start = 100, -- Valor de un personaje nuevo
    -- Los objetos de ox_inventory indican cuánto llenan en una escala de 1000000: status = { hunger = 200000 } es un 20 %
    ItemScale = 10000,
    MaxPerItem = 50, -- Lo máximo que puede llenar un objeto de una vez
    UseCooldown = 1, -- Segundos mínimos entre dos usos
    Damage = false, -- Con true, a 0 de hambre o sed se pierde vida poco a poco
    DamageAmount = 2,
    DamageInterval = 5, -- Segundos entre cada pérdida de vida
}

Config.Seatbelt = {
    -- K abre la guantera en ox_inventory y B es señalar en jj_smallresources
    Key = 'Y',
    -- Sin cinturón se sale despedido en un choque fuerte. Con false, el cinturón solo es visual
    Eject = false,
    EjectSpeed = 20.0, -- Velocidad mínima del choque en metros por segundo
    EjectUnknown = 1.0,
    EjectModifier = 17.0,
    EjectMinDamage = 2000.0,
}

-- Clases de vehículo sin cinturón: motos, bicicletas, barcos, helicópteros, aviones y trenes
Config.NoSeatbeltClasses = { [8] = true, [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }
Config.BoatClass = 14
Config.AirClasses = { [15] = true, [16] = true }
