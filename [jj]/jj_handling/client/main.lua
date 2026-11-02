-- Aplica a cada vehículo lo que le toca cuando te subes a conducirlo:
-- cambios temporales (state bag) > perfil instalado en la matrícula > perfil de serie del modelo
Sync = {}

local STATE_KEY = 'jj_handling'
local CACHE_MS = 5 * 60 * 1000
local resolved = {}   -- 'modelo|matrícula' -> { params, at }

local function plateOf(vehicle)
    return (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s+', ''):gsub('%s+$', ''):upper()
end

local function cacheKey(vehicle)
    return ('%s|%s'):format(Utils.ModelHash(GetEntityModel(vehicle)), plateOf(vehicle))
end

local function isDriver(vehicle)
    return vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == cache.ped
end

function Sync.Refresh(vehicle)
    if not isDriver(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then return end
    if Editor.IsOpenFor(vehicle) then return end

    local temp = Entity(vehicle).state[STATE_KEY]
    if temp then
        Handling.Apply(vehicle, temp.params or {})
        return
    end

    local key = cacheKey(vehicle)
    local entry = resolved[key]
    if not entry or GetGameTimer() - entry.at > CACHE_MS then
        local result = lib.callback.await('jj_handling:resolve', false, { netId = VehToNet(vehicle) })
        if result and result.error then return end   -- Demasiadas peticiones: se reintenta al volver a subir
        entry = { params = result and result.params or nil, at = GetGameTimer() }
        resolved[key] = entry
    end

    if entry.params then
        Handling.Apply(vehicle, entry.params)
    else
        Handling.Restore(vehicle)
    end
end

-- Al subir como conductor. Se espera un poco porque el asiento y el vehículo llegan por separado
local pending = false
local function onSeatChange()
    if pending then return end
    pending = true
    SetTimeout(300, function()
        pending = false
        if cache.vehicle and cache.seat == -1 then
            Sync.Refresh(cache.vehicle)
        elseif Editor.IsOpen() and not Editor.IsPanelOnly() then
            Editor.Close()
        end
    end)
end

lib.onCache('vehicle', onSeatChange)
lib.onCache('seat', onSeatChange)

-- Cambios temporales: los pone el servidor en el vehículo
AddStateBagChangeHandler(STATE_KEY, nil, function(bagName, _, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or vehicle ~= cache.vehicle or cache.seat ~= -1 then return end

    if Editor.IsOpenFor(vehicle) then
        Editor.OnStateChange(value)
        return
    end
    -- El state bag se actualiza después de este evento
    SetTimeout(0, function() Sync.Refresh(vehicle) end)
end)

-- Algo guardado ha cambiado: se olvida lo que había en caché y se vuelve a pedir si afecta al vehículo actual
RegisterNetEvent('jj_handling:client:invalidate', function(data)
    if type(data) ~= 'table' then return end
    if data.all or data.profile then
        resolved = {}
    else
        for key in pairs(resolved) do
            local model, plate = key:match('^(%d+)|(.*)$')
            if (data.model and tonumber(model) == data.model) or (data.plate and plate == data.plate) then
                resolved[key] = nil
            end
        end
    end

    if cache.vehicle and cache.seat == -1 and not resolved[cacheKey(cache.vehicle)] then
        Sync.Refresh(cache.vehicle)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and cache.vehicle and cache.seat == -1 then
        SetTimeout(1000, function() Sync.Refresh(cache.vehicle) end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Handling.RestoreAll()
end)
