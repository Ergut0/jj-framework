-- Lectura y escritura del handling de un vehículo con los natives de FiveM.
-- Los cambios son por vehículo y solo en este cliente; los aplica quien conduce, que es quien simula el coche
Handling = {}

local originals = {}   -- vehículo -> { model, values (meta), raw (interno) }
local applied = {}     -- vehículo -> { parámetro = valor } solo lo que ha cambiado este recurso

local FIELD = 'CHandlingData'

local function readRaw(vehicle, param)
    if param.int then return GetVehicleHandlingInt(vehicle, FIELD, param.key) end
    local value = GetVehicleHandlingFloat(vehicle, FIELD, param.key)
    if param.rear then return value, GetVehicleHandlingFloat(vehicle, FIELD, param.rear) end
    return value
end

-- Valores actuales en unidades del meta
function Handling.Read(vehicle)
    local values = {}
    for _, param in ipairs(Parameters.List) do
        local value, rear = readRaw(vehicle, param)
        if param.int then
            values[param.key] = value
        else
            values[param.key] = Utils.Round(Parameters.ToMeta(param, value, rear), 4)
        end
    end
    return values
end

local function cleanup()
    for vehicle in pairs(originals) do
        if not DoesEntityExist(vehicle) then
            originals[vehicle], applied[vehicle] = nil, nil
        end
    end
end

-- Copia de los valores de serie, tomada antes de cambiar nada
function Handling.Original(vehicle)
    local model = GetEntityModel(vehicle)
    local entry = originals[vehicle]
    if entry and entry.model == model then return entry end

    if Utils.Count(originals) > 16 then cleanup() end

    entry = { model = model, values = {}, raw = {} }
    for _, param in ipairs(Parameters.List) do
        local value, rear = readRaw(vehicle, param)
        entry.raw[param.key] = { value, rear }
        entry.values[param.key] = param.int and value or Utils.Round(Parameters.ToMeta(param, value, rear), 4)
    end
    originals[vehicle], applied[vehicle] = entry, nil
    return entry
end

function Handling.HasChanges(vehicle)
    return applied[vehicle] ~= nil
end

local function write(vehicle, param, value, original)
    -- Volver al original escribe el valor interno exacto que había, sin pasar por la conversión
    if value == original.values[param.key] then
        local raw = original.raw[param.key]
        if param.int then
            SetVehicleHandlingInt(vehicle, FIELD, param.key, raw[1])
        else
            SetVehicleHandlingFloat(vehicle, FIELD, param.key, raw[1] + 0.0)
            if param.rear and raw[2] then SetVehicleHandlingFloat(vehicle, FIELD, param.rear, raw[2] + 0.0) end
        end
        return
    end

    if param.int then
        SetVehicleHandlingInt(vehicle, FIELD, param.key, math.floor(value + 0.5))
        return
    end
    local internal, rear = Parameters.ToInternal(param, value)
    SetVehicleHandlingFloat(vehicle, FIELD, param.key, internal + 0.0)
    if param.rear and rear then SetVehicleHandlingFloat(vehicle, FIELD, param.rear, rear + 0.0) end
end

-- Deja el vehículo con estos valores (en unidades del meta). Lo que no venga vuelve a su valor de serie.
-- Solo escribe lo que cambia respecto a lo último aplicado
function Handling.Apply(vehicle, params)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    params = params or {}

    local original = Handling.Original(vehicle)
    local current = applied[vehicle] or {}
    local nextApplied = {}
    local topSpeed, gears = false, nil

    for _, param in ipairs(Parameters.List) do
        local key = param.key
        local target = params[key]
        local value = target
        if value == nil and current[key] ~= nil then value = original.values[key] end   -- Deshacer lo que se cambió

        if value ~= nil and Utils.IsFiniteNumber(value) then
            -- Lo que no ha tocado este recurso se da por que sigue de serie
            local now = current[key]
            if now == nil then now = original.values[key] end
            if value ~= now then
                write(vehicle, param, value, original)
                if key == 'fInitialDriveMaxFlatVel' or key == 'fInitialDriveForce' or key == 'fInitialDragCoeff' then topSpeed = true end
                if key == 'nInitialDriveGears' then gears = math.floor(value + 0.5) end
            end
        end
        if target ~= nil and target ~= original.values[key] then nextApplied[key] = target end
    end

    applied[vehicle] = next(nextApplied) and nextApplied or nil

    -- Sin esto algunos valores del motor no se notan hasta volver a entrar
    if topSpeed then ModifyVehicleTopSpeed(vehicle, 1.0) end
    if gears then SetVehicleHighGear(vehicle, gears) end
    return true
end

function Handling.Restore(vehicle)
    if applied[vehicle] then Handling.Apply(vehicle, {}) end
end

function Handling.RestoreAll()
    for vehicle in pairs(applied) do
        if DoesEntityExist(vehicle) then Handling.Apply(vehicle, {}) end
    end
end

-- Valores de un preset para un vehículo concreto, a partir de su handling de serie
function Handling.ResolvePreset(preset, original, class, allowed, maxRelative)
    local values = {}
    for key, op in pairs(preset.ops or {}) do
        local param = Parameters.ByKey[key]
        local base = original[key]
        if param and base and (not allowed or allowed[key]) then
            local value = op.set or (op.mult and base * op.mult) or (op.add and base + op.add) or base
            local min, max = Validation.Limits(key, class)
            if maxRelative and base ~= 0 then
                local spread = math.abs(base) * maxRelative
                min, max = math.max(min, base - spread), math.min(max, base + spread)
            end
            value = math.max(min, math.min(max, value))
            value = param.int and math.floor(value + 0.5) or Utils.Round(value, 4)
            if value ~= base then values[key] = value end
        end
    end
    return values
end

function Handling.PresetAllowed(preset, class)
    if not preset.classes then return true end
    for _, item in ipairs(preset.classes) do
        if item == class then return true end
    end
    return false
end
