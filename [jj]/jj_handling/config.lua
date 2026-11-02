Config = {}

Config.Framework = 'jj'         -- Solo hay integración con JJ Framework
Config.Locale = 'es'            -- Textos en Config.Locales
Config.Command = 'handling'     -- Abre el editor (admins en cualquier sitio, mecánicos en su taller)
Config.Debug = false            -- Mensajes de depuración en la consola

-- PERMISOS ---------------------------------------------------------------------------------
-- Niveles: usuario (sin acceso), mecánico, admin y superadmin. Se comprueban siempre en el servidor
-- admin: el ACE de administrador de JJ Framework (jj.admin)
-- superadmin: este ACE. Ejemplo en server.cfg: add_ace group.admin jj.superadmin allow
Config.SuperAdminAce = 'jj.superadmin'

-- Trabajos que cuentan como mecánico y grado mínimo
Config.MechanicJobs = {
    mechanic = 0,
    bennys = 0,
}
Config.MechanicRequiresDuty = true

-- Lo que puede hacer cada nivel
--   anywhere: abrir el editor fuera de un taller
--   categories: 'all' o lista de categorías de Parameters.Categories
--   exclude: parámetros que no puede tocar aunque estén en sus categorías
--   maxRelative: cuánto puede alejarse cada valor del original (0.35 = ±35 %). nil = sin límite
--   applyTemp: aplicar cambios temporales al vehículo para probarlo
--   saveProfiles: guardar perfiles propios
--   install: dejar un perfil instalado en el vehículo (por matrícula)
--   modelDefault: poner un perfil como el de serie de un modelo para todo el servidor
--   editAny / deleteAny: editar o borrar perfiles de otros
--   import / export: perfiles en JSON
--   panel: panel de administración (todos los perfiles, búsqueda, historial)
--   logs: ver registros
--   settings: ajustes globales del sistema
Config.Levels = {
    mechanic = {
        anywhere = false,
        categories = { 'traction', 'brakes', 'suspension', 'steering' },
        exclude = { 'fMass', 'nInitialDriveGears' },
        maxRelative = 0.35,
        applyTemp = true, saveProfiles = true, install = true,
        modelDefault = false, editAny = false, deleteAny = false,
        import = false, export = true, panel = false, logs = false, settings = false,
    },
    admin = {
        anywhere = true,
        categories = 'all',
        exclude = {},
        maxRelative = nil,
        applyTemp = true, saveProfiles = true, install = true,
        modelDefault = true, editAny = true, deleteAny = true,
        import = true, export = true, panel = true, logs = true, settings = false,
    },
    superadmin = {
        anywhere = true,
        categories = 'all',
        exclude = {},
        maxRelative = nil,
        applyTemp = true, saveProfiles = true, install = true,
        modelDefault = true, editAny = true, deleteAny = true,
        import = true, export = true, panel = true, logs = true, settings = true,
    },
}

-- TALLERES ---------------------------------------------------------------------------------
-- Los mecánicos solo abren el editor con el vehículo dentro de uno de estos puntos
--   jobs: trabajos que pueden usarlo (nil = cualquiera de Config.MechanicJobs)
--   testRadius: distancia para la prueba de conducción. Si el vehículo se aleja más, se restauran los valores
Config.Workshops = {
    { label = "Benny's", coords = vec3(-211.55, -1324.55, 30.89), radius = 10.0, jobs = nil, testRadius = 800.0 },
    { label = 'Taller de LS Customs', coords = vec3(-337.39, -136.92, 39.01), radius = 10.0, jobs = nil, testRadius = 800.0 },
}
Config.InteractDistance = 10.0   -- Distancia a la que aparece el aviso [E] dentro del taller
Config.InteractKey = 38          -- E

-- VEHÍCULOS --------------------------------------------------------------------------------
-- Clases de GetVehicleClass que no se pueden editar (bicis, barcos, helicópteros, aviones, trenes)
Config.BlockedClasses = { 13, 14, 15, 16, 21 }
Config.BlockedModels = {}        -- { 'rhino', 'oppressor' }
Config.AllowedModels = nil       -- Lista blanca opcional. nil = todos los que no estén bloqueados

-- Límites por clase que sustituyen a los de shared/parameters.lua. { mínimo, máximo }
Config.ClassLimits = {
    [8] = { fMass = { 50, 600 }, fSteeringLock = { 10, 50 }, fInitialDriveForce = { 0.01, 0.8 } },   -- Motos
    [10] = { fMass = { 1000, 40000 } },   -- Industriales
    [20] = { fMass = { 1000, 40000 } },   -- Comerciales
}
-- Turismos y similares: la masa entre 200 kg y 6 toneladas
for _, class in ipairs({ 0, 1, 2, 3, 4, 5, 6, 7, 9, 12, 17, 18, 22 }) do
    Config.ClassLimits[class] = Config.ClassLimits[class] or {}
    Config.ClassLimits[class].fMass = { 200, 6000 }
end

-- PERSISTENCIA -----------------------------------------------------------------------------
-- Prioridad al conducir: cambios temporales > perfil instalado en la matrícula > perfil de serie del modelo
Config.AutoApply = true          -- Aplica perfiles instalados y de serie al subir como conductor
Config.MaxProfilesPerUser = 50
Config.HistoryPerProfile = 20    -- Versiones anteriores que se guardan de cada perfil

-- PRUEBAS ----------------------------------------------------------------------------------
-- Los cambios temporales se quitan solos pasado este tiempo (0 = nunca) o al alejarse del taller
Config.TestMinutes = 20
Config.RestoreOnLeaveVehicle = false   -- Restaurar al bajarse del vehículo

-- SEGURIDAD --------------------------------------------------------------------------------
Config.Security = {
    Cooldown = 250,          -- ms mínimos entre peticiones del mismo jugador
    Burst = 12,              -- Peticiones máximas en BurstWindow
    BurstWindow = 5000,
    MaxImportSize = 8192,    -- Bytes máximos de un JSON importado
}

-- LOGS -------------------------------------------------------------------------------------
Config.Logs = {
    Database = true,
    Console = true,
    -- Webhook de Discord. Mejor en server.cfg: set jj_handling_webhook "https://..."
    Webhook = '',
}

-- INTERFAZ ---------------------------------------------------------------------------------
Config.UI = {
    SpeedUnit = 'kmh',       -- 'kmh' o 'mph'
    RefreshMs = 200,         -- Cada cuánto se actualiza la velocidad mientras el editor está abierto
}

-- PERFILES PRECONFIGURADOS -----------------------------------------------------------------
-- Cambian el handling ORIGINAL de cada vehículo, así que se adaptan a cada modelo:
--   mult: multiplica el original   add: suma al original   set: valor fijo
-- El resultado siempre se limita a los rangos permitidos. classes: clases donde se pueden usar (nil = todas)
-- Son un punto de partida: probadlos con los vehículos del servidor antes de usarlos en serio
local CARS = { 0, 1, 2, 3, 4, 5, 6, 7, 9, 12, 17, 18, 22 }
local STREET = { 0, 1, 3, 4, 5, 6, 7, 22 }

Config.Presets = {
    { id = 'original', label = 'Original', desc = 'El handling de serie del vehículo.', ops = {} },
    { id = 'sport', label = 'Deportivo', desc = 'Algo más de motor, agarre y frenos. Suspensión más firme.', classes = CARS, ops = {
        fInitialDriveForce = { mult = 1.12 }, fTractionCurveMax = { mult = 1.06 }, fTractionCurveMin = { mult = 1.05 },
        fBrakeForce = { mult = 1.1 }, fSuspensionForce = { mult = 1.15 }, fSuspensionRaise = { add = -0.015 },
        fAntiRollBarForce = { mult = 1.2 },
    } },
    { id = 'sport_advanced', label = 'Deportivo avanzado', desc = 'Preparación de circuito para calle: más potencia, cambios rápidos y menos balanceo.', classes = STREET, ops = {
        fInitialDriveForce = { mult = 1.25 }, fInitialDriveMaxFlatVel = { mult = 1.06 }, fDriveInertia = { mult = 1.1 },
        fClutchChangeRateScaleUpShift = { mult = 1.6 }, fClutchChangeRateScaleDownShift = { mult = 1.6 },
        fTractionCurveMax = { mult = 1.12 }, fTractionCurveMin = { mult = 1.1 }, fBrakeForce = { mult = 1.2 },
        fSuspensionForce = { mult = 1.3 }, fSuspensionCompDamp = { mult = 1.2 }, fSuspensionReboundDamp = { mult = 1.2 },
        fSuspensionRaise = { add = -0.03 }, fAntiRollBarForce = { mult = 1.4 },
    } },
    { id = 'drift', label = 'Drift', desc = 'Propulsión trasera, más ángulo de giro y agarre que se pierde de forma progresiva.', classes = STREET, ops = {
        fDriveBiasFront = { set = 0.0 }, fSteeringLock = { set = 55 }, fTractionCurveMax = { mult = 0.8 }, fTractionCurveMin = { mult = 0.72 },
        fTractionCurveLateral = { set = 22 }, fLowSpeedTractionLossMult = { mult = 1.4 }, fHandBrakeForce = { mult = 1.5 },
        fInitialDriveForce = { mult = 1.15 }, fAntiRollBarBiasFront = { set = 0.6 }, fSuspensionRaise = { add = -0.02 },
    } },
    { id = 'racing', label = 'Racing', desc = 'Máximo agarre y frenada. Bajo y rígido.', classes = STREET, ops = {
        fInitialDriveForce = { mult = 1.2 }, fClutchChangeRateScaleUpShift = { mult = 2 }, fClutchChangeRateScaleDownShift = { mult = 2 },
        fTractionCurveMax = { mult = 1.18 }, fTractionCurveMin = { mult = 1.16 }, fBrakeForce = { mult = 1.25 }, fBrakeBiasFront = { set = 0.6 },
        fSuspensionForce = { mult = 1.4 }, fSuspensionRaise = { add = -0.04 }, fAntiRollBarForce = { mult = 1.5 },
        fInitialDragCoeff = { mult = 0.92 },
    } },
    { id = 'drag', label = 'Drag', desc = 'Salida fuerte en línea recta. Gira peor.', classes = STREET, ops = {
        fInitialDriveForce = { mult = 1.4 }, fInitialDriveMaxFlatVel = { mult = 1.05 }, fLowSpeedTractionLossMult = { mult = 0.5 },
        fTractionCurveMax = { mult = 1.1 }, fClutchChangeRateScaleUpShift = { mult = 2.5 }, fSteeringLock = { mult = 0.8 },
    } },
    { id = 'offroad', label = 'Off-road', desc = 'Más altura y recorrido, suspensión blanda y mejor agarre en tierra.', classes = { 1, 2, 9, 12 }, ops = {
        fSuspensionRaise = { add = 0.05 }, fSuspensionUpperLimit = { add = 0.03 }, fSuspensionLowerLimit = { add = -0.03 },
        fSuspensionForce = { mult = 0.85 }, fSuspensionCompDamp = { mult = 0.9 }, fTractionLossMult = { mult = 0.4 },
        fLowSpeedTractionLossMult = { mult = 0.8 }, fDriveBiasFront = { set = 0.5 },
    } },
    { id = 'rally', label = 'Rally', desc = 'Buen agarre en tierra, giro rápido y freno de mano fuerte.', classes = CARS, ops = {
        fTractionLossMult = { mult = 0.6 }, fTractionCurveLateral = { add = 2 }, fSuspensionForce = { mult = 0.9 },
        fSuspensionRaise = { add = 0.025 }, fSteeringLock = { mult = 1.1 }, fHandBrakeForce = { mult = 1.3 }, fBrakeBiasFront = { set = 0.55 },
    } },
    { id = 'realistic', label = 'Conducción realista', desc = 'Algo menos de agarre y frenada, con más inercia en curva.', ops = {
        fBrakeForce = { mult = 0.9 }, fTractionCurveMax = { mult = 0.95 }, fTractionCurveMin = { mult = 0.95 },
        fLowSpeedTractionLossMult = { mult = 1.2 }, fSuspensionCompDamp = { mult = 1.1 }, fSteeringLock = { mult = 0.95 },
        fAntiRollBarForce = { mult = 1.1 },
    } },
}
-- "Personalizado" no es un preset: es cualquier configuración que no coincide con uno

Config.Locales = {
    no_permission = 'No tienes permiso para hacer esto',
    no_vehicle = 'Tienes que ser el conductor de un vehículo',
    not_in_workshop = 'Tienes que estar con el vehículo dentro de un taller',
    blocked_vehicle = 'Este vehículo no se puede editar',
    too_fast = 'Vas demasiado rápido, espera un momento',
    applied = 'Cambios aplicados al vehículo (temporales)',
    restored = 'Se han restaurado los valores originales',
    saved = 'Perfil guardado',
    installed = 'Perfil instalado en el vehículo',
    uninstalled = 'Perfil quitado del vehículo',
    model_default = 'Perfil puesto de serie para el modelo',
    model_default_removed = 'El modelo vuelve a su handling original',
    deleted = 'Perfil borrado',
    conflict = 'Otra persona ha cambiado este perfil mientras lo editabas. Vuelve a cargarlo',
    incompatible = 'Este perfil es de otro modelo',
    test_expired = 'Se ha acabado la prueba: el vehículo vuelve a sus valores',
    test_left = 'Te has alejado del taller: el vehículo vuelve a sus valores',
    max_profiles = 'Has llegado al máximo de perfiles guardados',
    open_hint = '[E] Editor de handling',
}
