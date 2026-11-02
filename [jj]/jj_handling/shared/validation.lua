-- Validación de parámetros. La usa el servidor antes de guardar o aplicar nada,
-- y el cliente para avisar en la interfaz antes de enviarlo
Validation = {}

-- Límites de un parámetro para una clase de vehículo (GetVehicleClass)
function Validation.Limits(key, class)
    local param = Parameters.ByKey[key]
    if not param then return nil end
    local override = class and Config.ClassLimits[class] and Config.ClassLimits[class][key]
    if override then return override[1], override[2] end
    return param.min, param.max
end

local function valueOf(key, params, original)
    if params[key] ~= nil then return params[key] end
    return original and original[key]
end

-- Comprueba una tabla { parámetro = valor } en unidades del meta.
-- options: class, original ({ parámetro = valor }), allowed ({ parámetro = true }), maxRelative (0.5 = ±50 %)
-- Devuelve la tabla limpia o nil y la lista de errores
function Validation.Check(params, options)
    options = options or {}
    if type(params) ~= 'table' then return nil, { 'Los parámetros no son válidos' } end

    local clean, errors = {}, {}
    local count = 0

    for key, value in pairs(params) do
        count = count + 1
        local param = Parameters.ByKey[key]
        if type(key) ~= 'string' or not param then
            errors[#errors + 1] = ('Parámetro desconocido: %s'):format(tostring(key))
        elseif not Utils.IsFiniteNumber(value) then
            errors[#errors + 1] = ('%s: el valor no es un número válido'):format(param.label)
        elseif options.allowed and not options.allowed[key] then
            errors[#errors + 1] = ('%s: no tienes permiso para cambiarlo'):format(param.label)
        else
            local min, max = Validation.Limits(key, options.class)
            if param.int and math.type(value) ~= 'integer' and value % 1 ~= 0 then
                errors[#errors + 1] = ('%s: tiene que ser un número entero'):format(param.label)
            elseif value < min or value > max then
                errors[#errors + 1] = ('%s: tiene que estar entre %s y %s'):format(param.label, min, max)
            else
                local original = options.original and options.original[key]
                if options.maxRelative and Utils.IsFiniteNumber(original) and original ~= 0
                    and math.abs(value - original) > math.abs(original) * options.maxRelative + 1e-6 then
                    errors[#errors + 1] = ('%s: no puede cambiar más de un %d %% respecto al original'):format(param.label, math.floor(options.maxRelative * 100))
                else
                    clean[key] = param.int and math.tointeger(math.floor(value + 0.5)) or Utils.Round(value, 5)
                end
            end
        end
    end

    if count > #Parameters.List then
        return nil, { 'Demasiados parámetros' }
    end

    -- Combinaciones que el juego no maneja bien
    local tmax, tmin = valueOf('fTractionCurveMax', clean, options.original), valueOf('fTractionCurveMin', clean, options.original)
    if tmax and tmin and tmin > tmax then
        errors[#errors + 1] = 'El agarre mínimo no puede ser mayor que el máximo'
    end
    local upper, lower = valueOf('fSuspensionUpperLimit', clean, options.original), valueOf('fSuspensionLowerLimit', clean, options.original)
    if upper and lower and lower >= upper then
        errors[#errors + 1] = 'El recorrido inferior tiene que ser menor que el superior'
    end

    if #errors > 0 then return nil, errors end
    return clean, nil
end

-- Avisos de configuraciones poco realistas. No impiden guardar
function Validation.Warnings(params, original)
    local warnings = {}
    local function get(key) return valueOf(key, params, original) end
    local function changed(key, factor)
        local value, base = params[key], original and original[key]
        return value and Utils.IsFiniteNumber(base) and base ~= 0 and (value / base > factor or value / base < 1 / factor)
    end

    local brake = get('fBrakeForce')
    if brake and brake > 2.0 then warnings[#warnings + 1] = 'Fuerza de frenado muy alta: el vehículo puede clavarse o volcar al frenar' end

    local bias = get('fBrakeBiasFront')
    if bias and (bias < 0.35 or bias > 0.8) then warnings[#warnings + 1] = 'Reparto de frenada extremo: puede bloquear un eje y hacer trompo' end

    local tmax, tmin = get('fTractionCurveMax'), get('fTractionCurveMin')
    if tmax and tmin and tmax - tmin > 1.0 then warnings[#warnings + 1] = 'Mucha diferencia entre agarre máximo y mínimo: pierde el agarre de golpe' end
    if tmax and tmax > 3.5 then warnings[#warnings + 1] = 'Agarre máximo muy alto: el vehículo puede volcar en curva' end

    local force = get('fInitialDriveForce')
    if force and force > 0.6 then warnings[#warnings + 1] = 'Fuerza del motor muy alta para un vehículo de calle' end

    local lock = get('fSteeringLock')
    if lock and lock > 55 then warnings[#warnings + 1] = 'Ángulo de giro muy grande: inestable a alta velocidad (normal en drift)' end

    local loss = get('fTractionLossMult')
    if loss and loss > 2 then warnings[#warnings + 1] = 'Pierde mucho agarre fuera del asfalto' end

    if changed('fMass', 1.5) then warnings[#warnings + 1] = 'La masa cambia más de un 50 %: afecta a choques y empujones' end
    if changed('fSuspensionForce', 2) then warnings[#warnings + 1] = 'La rigidez de la suspensión cambia mucho respecto al original' end

    local raise = get('fSuspensionRaise')
    if raise and raise < -0.1 then warnings[#warnings + 1] = 'Muy bajo: puede rozar el suelo y engancharse en bordillos' end

    local drag = get('fInitialDragCoeff')
    if drag and drag < 2 then warnings[#warnings + 1] = 'Resistencia aerodinámica muy baja: la velocidad punta puede dispararse' end

    return warnings
end
