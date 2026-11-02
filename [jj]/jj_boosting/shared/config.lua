-- Constantes del recurso y datos calculados a partir de config.lua. No hace falta tocar este archivo

Boost = {}

Boost.Status = {
    OFFERED = 'offered',
    SEARCHING = 'searching', -- aceptado: el jugador busca la zona
    LOCATED = 'located',     -- el vehículo ya existe
    STOLEN = 'stolen',       -- el dueño del contrato lo conduce
    COMPLETED = 'completed',
    FAILED = 'failed',
    EXPIRED = 'expired',
    DECLINED = 'declined',
    ABANDONED = 'abandoned',
}

Boost.Reason = {
    HACK = 'hack_failed',
    DESTROYED = 'vehicle_destroyed',
    TIME = 'time_over',
    DISCONNECT = 'disconnected',
    GIVEUP = 'gave_up',
    RESTART = 'server_restart',
}

-- Clases de la más fácil a la más difícil
Boost.ClassOrder = {}
for name, class in pairs(Config.Classes) do
    class.name = name
    Boost.ClassOrder[#Boost.ClassOrder + 1] = name
end
table.sort(Boost.ClassOrder, function(a, b) return Config.Classes[a].order < Config.Classes[b].order end)

function Boost.GetTier(class)
    return Config.Tiers[class.tier] or Config.Tiers.basic
end

-- Nivel y progreso a partir de la experiencia
function Boost.GetLevel(xp)
    local level, current, nextXp = 1, 0, nil
    for index, required in ipairs(Config.Levels) do
        if xp >= required then
            level, current = index, required
        else
            nextXp = required
            break
        end
    end
    return level, current, nextXp
end

function Boost.IsClassUnlocked(className, xp)
    local class = Config.Classes[className]
    return class ~= nil and xp >= (class.unlockXp or 0)
end

-- La clase más alta que tiene desbloqueada
function Boost.GetCurrentClass(xp)
    local current = Boost.ClassOrder[1]
    for _, name in ipairs(Boost.ClassOrder) do
        if xp >= Config.Classes[name].unlockXp then current = name end
    end
    return current
end
