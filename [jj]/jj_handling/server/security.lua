-- Control de peticiones y comprobación de vehículos en el servidor
Security = {}

local requests = {}

-- Limita las peticiones de cada jugador: un mínimo entre peticiones y un máximo por ventana de tiempo
function Security.Allow(src, light)
    local now = GetGameTimer()
    local entry = requests[src]
    if not entry then
        entry = { last = -math.huge, count = 0, windowStart = now }
        requests[src] = entry
    end

    if not light and now - entry.last < Config.Security.Cooldown then return false end
    if now - entry.windowStart > Config.Security.BurstWindow then
        entry.windowStart, entry.count = now, 0
    end
    entry.count = entry.count + 1
    if entry.count > Config.Security.Burst * (light and 2 or 1) then return false end

    entry.last = now
    return true
end

function Security.Forget(src)
    requests[src] = nil
end

local BLOCKED_TYPES = { heli = true, plane = true, boat = true, train = true, submarine = true, trailer = true }

-- Vehículo de un netId que el jugador está conduciendo. Todo se lee en el servidor
function Security.DriverVehicle(src, netId)
    if type(netId) ~= 'number' then return nil end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then return nil end
    if GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(src) then return nil end
    return vehicle
end

function Security.Plate(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle) or ''
    plate = plate:gsub('^%s+', ''):gsub('%s+$', ''):upper()
    return plate ~= '' and plate:sub(1, 16) or nil
end

local function inList(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then return true end
    end
    return false
end

-- La clase la manda el cliente (el servidor no la conoce); se contrasta con el tipo de vehículo,
-- que sí se lee aquí. Devuelve la clase aceptada o nil y el motivo
function Security.CheckVehicle(vehicle, class)
    local vehicleType = GetVehicleType(vehicle)
    if BLOCKED_TYPES[vehicleType] then return nil end

    class = math.tointeger(tonumber(class))
    if not class or class < 0 or class > 22 then return nil end
    if vehicleType == 'bike' and class ~= 8 and class ~= 13 then return nil end
    if vehicleType ~= 'bike' and (class == 8 or class == 13) then return nil end
    if inList(Config.BlockedClasses, class) then return nil end

    local hash = Utils.ModelHash(GetEntityModel(vehicle))
    for _, model in ipairs(Config.BlockedModels) do
        if Utils.ModelHash(model) == hash then return nil end
    end
    if Config.AllowedModels then
        local allowed = false
        for _, model in ipairs(Config.AllowedModels) do
            if Utils.ModelHash(model) == hash then allowed = true end
        end
        if not allowed then return nil end
    end

    return class, hash
end

-- Valores originales que manda el cliente al abrir el editor. Solo se usan para limitar
-- cuánto puede cambiar un mecánico, así que basta con que sean números razonables
function Security.CleanOriginal(original)
    if type(original) ~= 'table' then return {} end
    local clean = {}
    for _, param in ipairs(Parameters.List) do
        local value = original[param.key]
        if Utils.IsFiniteNumber(value) and math.abs(value) < 1e6 then clean[param.key] = value end
    end
    return clean
end
