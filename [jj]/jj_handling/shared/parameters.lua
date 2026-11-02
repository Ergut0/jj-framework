-- Parámetros de handling que se pueden editar.
-- Los valores se muestran y se guardan en las unidades del handling.meta. El juego guarda
-- algunos en otra unidad (radianes, m/s, el doble...), así que cada uno indica cómo convertirlo:
--   scale: valor del meta = valor interno * scale
--   bias:  reparto delantero/trasero. El juego guarda delante = meta * 2 y detrás = (1 - meta) * 2
--   drive: como bias, pero 0 y 1 son tracción trasera y delantera puras
Parameters = {}

Parameters.Categories = {
    { id = 'performance', label = 'Rendimiento', icon = 'fa-gauge-high' },
    { id = 'traction', label = 'Tracción y transmisión', icon = 'fa-gears' },
    { id = 'brakes', label = 'Frenado', icon = 'fa-circle-stop' },
    { id = 'suspension', label = 'Suspensión', icon = 'fa-car-burst' },
    { id = 'steering', label = 'Dirección y estabilidad', icon = 'fa-arrows-turn-to-dots' },
    { id = 'weight', label = 'Peso y resistencia', icon = 'fa-weight-hanging' },
}

local RAD = 180 / math.pi

Parameters.List = {
    -- Rendimiento
    { key = 'fInitialDriveForce', category = 'performance', label = 'Fuerza del motor', min = 0.01, max = 1.5, step = 0.005,
      desc = 'Aceleración. Multiplica la fuerza que llega a las ruedas.' },
    { key = 'fDriveInertia', category = 'performance', label = 'Inercia del motor', min = 0.1, max = 2.0, step = 0.01,
      desc = 'Lo rápido que sube de vueltas. Más alto, respuesta más viva.' },
    { key = 'fInitialDriveMaxFlatVel', category = 'performance', label = 'Velocidad máxima teórica', min = 50, max = 500, step = 1, scale = 3.6, unit = 'km/h',
      desc = 'Velocidad punta en llano según el meta. La real depende también de la resistencia y la fuerza.' },
    { key = 'fClutchChangeRateScaleUpShift', category = 'performance', label = 'Cambio a marcha superior', min = 0.5, max = 15, step = 0.1,
      desc = 'Rapidez del embrague al subir de marcha.' },
    { key = 'fClutchChangeRateScaleDownShift', category = 'performance', label = 'Cambio a marcha inferior', min = 0.5, max = 15, step = 0.1,
      desc = 'Rapidez del embrague al reducir.' },

    -- Tracción y transmisión
    { key = 'fDriveBiasFront', category = 'traction', label = 'Reparto de tracción delantera', min = 0, max = 1, step = 0.01, convert = 'drive',
      rear = 'fDriveBiasRear', desc = '0 = trasera, 1 = delantera, 0.5 = 4x4 al 50 %.' },
    { key = 'nInitialDriveGears', category = 'traction', label = 'Número de marchas', min = 1, max = 8, step = 1, int = true, special = true,
      desc = 'Se aplica también la marcha más alta. Algunos vehículos no lo aceptan hasta volver a entrar.' },
    { key = 'fTractionCurveMax', category = 'traction', label = 'Agarre máximo', min = 0.5, max = 5, step = 0.01,
      desc = 'Agarre en curva y al acelerar en el punto óptimo de deslizamiento.' },
    { key = 'fTractionCurveMin', category = 'traction', label = 'Agarre mínimo', min = 0.5, max = 5, step = 0.01,
      desc = 'Agarre cuando la rueda ya desliza. Debe ser menor o igual que el máximo.' },
    { key = 'fTractionCurveLateral', category = 'traction', label = 'Curva de agarre lateral', min = 5, max = 45, step = 0.1, scale = RAD, unit = '°',
      desc = 'Ángulo de deslizamiento con más agarre. Más alto, derrapa más progresivo.' },
    { key = 'fTractionSpringDeltaMax', category = 'traction', label = 'Elasticidad del neumático', min = 0.01, max = 1, step = 0.01,
      desc = 'Distancia que se deforma el neumático antes de perder agarre.' },
    { key = 'fLowSpeedTractionLossMult', category = 'traction', label = 'Pérdida de agarre a baja velocidad', min = 0, max = 5, step = 0.01,
      desc = 'Patinaje al arrancar. 0 = sin patinar.' },
    { key = 'fTractionLossMult', category = 'traction', label = 'Pérdida de agarre en superficie', min = 0, max = 5, step = 0.01,
      desc = 'Cuánto afecta tierra, hierba o mojado al agarre.' },

    -- Frenado
    { key = 'fBrakeForce', category = 'brakes', label = 'Fuerza de frenado', min = 0.05, max = 5, step = 0.01,
      desc = 'Potencia del freno de servicio.' },
    { key = 'fBrakeBiasFront', category = 'brakes', label = 'Reparto de frenada delantero', min = 0, max = 1, step = 0.01, convert = 'bias',
      rear = 'fBrakeBiasRear', desc = 'Parte de la frenada en el eje delantero. Lo habitual está entre 0.45 y 0.7.' },
    { key = 'fHandBrakeForce', category = 'brakes', label = 'Fuerza del freno de mano', min = 0, max = 5, step = 0.01,
      desc = 'Potencia del freno de mano. Influye en lo fácil que es cruzar el coche.' },

    -- Suspensión
    { key = 'fSuspensionForce', category = 'suspension', label = 'Rigidez', min = 0.5, max = 10, step = 0.05,
      desc = 'Fuerza de los muelles. Más alto, más dura.' },
    { key = 'fSuspensionCompDamp', category = 'suspension', label = 'Amortiguación en compresión', min = 0.1, max = 10, step = 0.05, scale = 10,
      desc = 'Resistencia del amortiguador al hundirse.' },
    { key = 'fSuspensionReboundDamp', category = 'suspension', label = 'Amortiguación en rebote', min = 0.1, max = 10, step = 0.05, scale = 10,
      desc = 'Resistencia del amortiguador al extenderse.' },
    { key = 'fSuspensionUpperLimit', category = 'suspension', label = 'Recorrido superior', min = 0, max = 0.5, step = 0.005,
      desc = 'Lo que puede subir la rueda. Debe ser mayor que el inferior.' },
    { key = 'fSuspensionLowerLimit', category = 'suspension', label = 'Recorrido inferior', min = -0.5, max = 0, step = 0.005,
      desc = 'Lo que puede bajar la rueda.' },
    { key = 'fSuspensionRaise', category = 'suspension', label = 'Altura de la carrocería', min = -0.2, max = 0.2, step = 0.005,
      desc = 'Positivo sube el coche, negativo lo baja.' },
    { key = 'fSuspensionBiasFront', category = 'suspension', label = 'Reparto de rigidez delantero', min = 0, max = 1, step = 0.01, convert = 'bias',
      rear = 'fSuspensionBiasRear', desc = 'Más alto, el eje delantero es más duro que el trasero.' },
    { key = 'fAntiRollBarForce', category = 'suspension', label = 'Barra estabilizadora', min = 0, max = 5, step = 0.01,
      desc = 'Reduce la inclinación de la carrocería en curva.' },
    { key = 'fAntiRollBarBiasFront', category = 'suspension', label = 'Reparto de la barra delantero', min = 0, max = 1, step = 0.01, convert = 'bias',
      rear = 'fAntiRollBarBiasRear', desc = 'Más delante tiende a subvirar, más detrás a sobrevirar.' },

    -- Dirección y estabilidad
    { key = 'fSteeringLock', category = 'steering', label = 'Ángulo de giro', min = 10, max = 75, step = 0.5, scale = RAD, unit = '°',
      desc = 'Máximo giro de las ruedas. Más alto, gira más cerrado pero es más nervioso a alta velocidad.' },
    { key = 'fRollCentreHeightFront', category = 'steering', label = 'Centro de balanceo delantero', min = -0.5, max = 1, step = 0.01,
      desc = 'Más alto, menos balanceo delante y más tendencia a subvirar.' },
    { key = 'fRollCentreHeightRear', category = 'steering', label = 'Centro de balanceo trasero', min = -0.5, max = 1, step = 0.01,
      desc = 'Más alto, menos balanceo detrás y más tendencia a sobrevirar.' },

    -- Peso y resistencia
    { key = 'fMass', category = 'weight', label = 'Masa', min = 50, max = 40000, step = 10, unit = 'kg', special = true,
      desc = 'Peso del vehículo. Cambia inercia y choques. En algunos modelos no se nota hasta volver a crear el vehículo.' },
    { key = 'fInitialDragCoeff', category = 'weight', label = 'Resistencia aerodinámica', min = 0, max = 100, step = 0.1, scale = 10000,
      desc = 'Frena el coche a alta velocidad. Más alto, menos velocidad punta.' },
    { key = 'fDownforceModifier', category = 'weight', label = 'Carga aerodinámica', min = 0, max = 100, step = 0.1,
      desc = 'Agarre extra a alta velocidad. Solo lo usan algunos modelos.' },
}

-- fTractionCurveLateral y los centros de balanceo también influyen en la dirección
Parameters.AlsoIn = {
    fTractionCurveLateral = { 'steering' },
    fInitialDragCoeff = { 'performance' },
}

-- Valores derivados: los calcula el juego a partir de otro y no se editan
Parameters.Derived = {
    fDriveBiasRear = { from = 'fDriveBiasFront', label = 'Reparto de tracción trasero', category = 'traction' },
}

Parameters.ByKey = {}
for index, param in ipairs(Parameters.List) do
    param.order = index
    Parameters.ByKey[param.key] = param
end

-- Interno del juego -> unidad del meta
function Parameters.ToMeta(param, internal, rearInternal)
    if param.convert == 'bias' then
        return internal / 2
    elseif param.convert == 'drive' then
        -- Se calcula desde el eje con menos fuerza, que es el que no satura
        local rear = rearInternal or 0
        if internal >= rear then return 1 - rear / 2 end
        return internal / 2
    end
    return internal * (param.scale or 1)
end

-- Unidad del meta -> interno del juego. Devuelve también el valor del eje trasero si lo tiene
function Parameters.ToInternal(param, value)
    if param.convert == 'bias' then
        return value * 2, (1 - value) * 2
    elseif param.convert == 'drive' then
        if value >= 1 then return 1.0, 0.0 end
        if value <= 0 then return 0.0, 1.0 end
        return value * 2, (1 - value) * 2
    end
    return value / (param.scale or 1)
end

-- Reparto trasero tal como lo ve el jugador (0 a 1)
function Parameters.DriveRear(front)
    return 1 - front
end
