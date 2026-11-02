Config = {}

-- General -------------------------------------------------------------------
Config.Locale = 'es'                 -- 'es' | 'en' (ver carpeta locales)
Config.Debug = false                 -- logs de depuracion en consola
Config.Currency = '$'

-- Comandos -------------------------------------------------------------------
-- El panel de jugador se abre con el objeto tablet_reacing de ox_inventory
Config.AdminCommand = 'raceadmin'    -- abre el panel de administracion
Config.LeaveCommand = 'raceleave'    -- abandona la sala o la carrera actual ('' para desactivar)

-- Permisos de administracion (validados SIEMPRE en el servidor) -------------
-- Además de los administradores de jj-framework, quien tenga este ACE: add_ace group.mod races.admin allow
Config.AdminAce = 'races.admin'

-- Integracion con crews ------------------------------------------------------
-- Nombres con los que puede estar iniciado el recurso de crews (se usa el primero que este iniciado y exponga los exports)
Config.CrewsResources = { 'jj_crews' }

-- Catalogo ------------------------------------------------------------------
Config.Categories = { 'street', 'circuit', 'offroad', 'sprint', 'circular' }
Config.PointToPointCategories = { sprint = true }   -- categorias de una sola vuelta (salida -> meta)
Config.Difficulties = { 'easy', 'medium', 'hard', 'extreme' }

-- Clases de vehiculo permitidas. `classes` usa los ids de GetVehicleClass (nil = cualquiera).
-- `models` (opcional) es una lista blanca de modelos: la comprobacion mas estricta posible.
Config.VehicleClasses = {
    any        = { classes = nil },
    street     = { classes = { 0, 1, 2, 3, 4, 5, 6 } },
    muscle     = { classes = { 4 } },
    classics   = { classes = { 5 } },
    sports     = { classes = { 6 } },
    super      = { classes = { 7 } },
    offroad    = { classes = { 2, 9 } },
    motorcycle = { classes = { 8 } },
}
-- Clases que se pueden usar en carreras (editable en vivo desde el panel admin)
Config.DefaultAllowedClasses = { 'any', 'street', 'muscle', 'classics', 'sports', 'super', 'offroad', 'motorcycle' }
-- Modelos que nunca se admiten (nombres de spawn)
Config.BlacklistedModels = { 'rhino', 'khanjali', 'oppressor', 'oppressor2', 'deluxo', 'scramjet', 'voltic2', 'vigilante' }
-- Clases de GTA que jamas se admiten (aviones, helicopteros, barcos, trenes, bicis...)
Config.BlacklistedClasses = { 13, 14, 15, 16, 21 }

-- Ajustes editables en vivo desde el panel admin (se guardan en BD) ---------
Config.Settings = {
    maxPlayers = 12,                 -- pilotos maximos por carrera (tambien limitado por la parrilla del circuito)
    minPlayersToStart = 1,           -- minimo para lanzar una carrera abierta
    minPlayersForRewards = 2,        -- por debajo no hay premios, puntos de crew ni premio base (evita farmeo en solitario)
    maxLaps = 15,
    countdownSeconds = 5,
    finishGraceSeconds = 60,         -- tiempo extra para llegar a meta tras el primer clasificado
    entryFeeMax = 50000,             -- inscripcion maxima fijada por un jugador
    extraPrizeMax = 100000,          -- bolsa extra maxima aportada por el anfitrion
    baseMaxPrize = 250000,           -- tope del premio base configurable por circuito
    commissionPct = 10,              -- % de las inscripciones que retiene el servidor (sumidero de dinero)
    prizeSplit = { 50, 30, 20 },     -- % del bote por posicion (si hay menos pilotos se normaliza)
    pilotPoints = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 },  -- puntos del ranking de pilotos por posicion
    allowedClasses = Config.DefaultAllowedClasses,
    useRoutingBuckets = true,        -- aisla cada carrera en un routing bucket propio
    openLobbyMinutes = 15,           -- una sala abierta se cancela (con reembolso) pasado este tiempo
    -- Integracion con crews
    crewPointsByPosition = { 100, 60, 40, 25, 15, 10 },   -- puntos para el crew del piloto por posicion
    crewFinishPoints = 5,            -- puntos por terminar fuera de la tabla anterior
    crewMaxPointsPerRace = 300,      -- tope de puntos que un mismo crew obtiene en una carrera abierta (0 = sin tope)
    crewRequireOutsider = true,      -- los puntos solo cuentan si corre al menos un piloto ajeno al crew
    crewPrizeSharePct = 0,           -- % del premio de cada piloto que se ingresa en el banco de su crew
    crewVsFormula = 'points',        -- 'points' | 'positions' | 'best'
    crewVsWinPoints = 500,           -- puntos extra para el crew ganador de un crew vs crew
    crewVsStakeMax = 500000,         -- apuesta maxima por crew en un reto
    crewVsMinRank = 3,               -- nivel de rango minimo para retar / aceptar retos (el lider siempre puede)
}

-- Premios de eventos oficiales y del premio base los paga el servidor (dinero nuevo).
Config.EntryAccount = 'bank'         -- cuenta de la que se cobra la inscripcion
Config.PrizeAccount = 'bank'         -- cuenta que recibe los premios

-- Eventos programados -------------------------------------------------------
Config.Events = {
    joinWindowSeconds = 180,         -- tiempo que la sala oficial permanece abierta
    minPlayers = 2,                  -- minimo para disputar el evento (si no, se cancela)
    maxPrize = 1000000,
    maxAheadDays = 60,
}

-- Retos entre crews ---------------------------------------------------------
Config.CrewVs = {
    challengeExpirySeconds = 90,     -- tiempo para aceptar un reto
    joinWindowSeconds = 240,         -- tiempo para que ambos equipos se reunan tras aceptar
    maxTeamSize = 6,
    drawRefunds = true,              -- en caso de empate se devuelven las apuestas
}

-- Salas ---------------------------------------------------------------------
Config.Lobby = {
    nameMax = 32,
    inviteExpirySeconds = 120,
    vehicleCheckTimeoutMs = 3500,    -- espera a las respuestas de comprobacion de vehiculo
}

-- Anti-trampas (todo se valida en el servidor; requiere OneSync) ------------
Config.AntiCheat = {
    enabled = true,
    maxSpeed = 120.0,                -- m/s plausibles entre dos puntos (~430 km/h)
    minTimeFactor = 0.55,            -- tiempo minimo entre checkpoints = distancia / maxSpeed * factor
    posTolerance = 35.0,             -- metros extra al comprobar la posicion del piloto al pasar un checkpoint
    teleportSpeed = 260.0,           -- m/s entre muestras que se consideran un teletransporte
    sampleInterval = 1000,           -- ms entre muestras de posicion
    strikesToFlag = 3,               -- avisos para marcar el resultado como sospechoso
    strikesToDq = 8,                 -- avisos para descalificar
    leftVehicleGrace = 30,           -- segundos permitidos fuera del vehiculo
    dqOnVehicleChange = true,        -- cambiar de vehiculo durante la carrera descalifica
    minRefFactor = 0.5,              -- vuelta < tiempo de referencia * factor => sospechoso
    maxReportsPerSecond = 12,        -- limite de eventos de progreso por jugador
}

-- Modo fantasma / colisiones ------------------------------------------------
Config.Ghost = {
    enabled = true,
    startSeconds = 5,                -- fantasma temporal tras la salida aunque haya colisiones
    alpha = 140,                     -- opacidad de los vehiculos rivales en modo fantasma (0-255)
}

-- Pit stops (checkpoints opcionales de tipo "pit") ---------------------------
Config.Pit = {
    enabled = true,
    cooldownSeconds = 25,
    repair = true,
    refuel = true,
}

-- Marcadores del mundo (cliente) --------------------------------------------
Config.Markers = {
    next     = { r = 168, g = 85, b = 247, a = 140 },
    after    = { r = 255, g = 255, b = 255, a = 60 },
    finish   = { r = 255, g = 255, b = 255, a = 150 },
    shortcut = { r = 255, g = 190, b = 40, a = 130 },
    pit      = { r = 60, g = 200, b = 255, a = 120 },
    drawDistance = 160.0,            -- distancia (m) a la que se dibujan y detectan los checkpoints
    blipColour = 27,
}

-- Creador de circuitos (administracion) -------------------------------------
Config.Creator = {
    requireTest = true,              -- un circuito no se publica hasta superar una prueba con su version actual
    maxCheckpoints = 350,            -- tambien cubre los circuitos largos de sql/tracks.sql (hasta 340 puntos)
    maxGrid = 20,
    minRadius = 3.0, maxRadius = 60.0, defaultRadius = 12.0,
    minHeight = 2.0, maxHeight = 40.0, defaultHeight = 8.0,
    raycastDistance = 300.0,
    -- Controles (ids de INPUT_*). Se muestran en el overlay del editor.
    Keys = {
        place      = 38,   -- E
        remove     = 44,   -- Q
        prev       = 174,  -- flecha izquierda
        next       = 175,  -- flecha derecha
        move       = 23,   -- F: mueve el seleccionado a la posicion actual
        source     = 37,   -- TAB: cursor (mira) / posicion del jugador
        kind       = 20,   -- Z: normal -> atajo -> pit -> parrilla
        finish     = 177,  -- Backspace: volver al panel
        radiusUp   = 241,  -- rueda arriba
        radiusDown = 242,  -- rueda abajo
        radiusUp2  = 172,  -- flecha arriba (alternativa a la rueda)
        radiusDown2 = 173, -- flecha abajo
        modifier   = 21,   -- SHIFT: la rueda cambia la altura
    },
    -- Etiquetas que muestra el overlay del editor para cada control
    KeyLabels = {
        place = 'E', remove = 'Q', prev = '←', next = '→', move = 'F', source = 'TAB', kind = 'Z', finish = 'RETROCESO',
        wheel = 'RUEDA / ↑↓', modifier = 'SHIFT',
    },
}

-- Limites de uso (peticiones por ventana, ms) -------------------------------
Config.RateLimit = {
    default = { max = 15, window = 5000 },
    heavy   = { max = 6,  window = 5000 },
    admin   = { max = 25, window = 5000 },
}

-- Listados ------------------------------------------------------------------
Config.PageSize = 12
Config.LeaderboardSize = 25
Config.LeaderboardCacheSeconds = 30
Config.LogRetentionDays = 90         -- 0 = no limpiar logs
Config.AnnounceRecords = true        -- anuncia nuevos records a todos los jugadores
Config.HudInterval = 500             -- ms entre actualizaciones de clasificacion mientras hay carrera

-- Discord (opcional). El webhook NO va en este fichero porque se comparte con el
-- cliente: define el convar en server.cfg:  set races_webhook "https://discord.com/api/webhooks/..."
Config.Webhook = IsDuplicityVersion() and GetConvar('races_webhook', '') or ''
Config.WebhookName = 'Races'
Config.WebhookActions = { race_result = true, new_record = true, result_void = true, record_void = true, event_start = true }

-- Routing buckets -----------------------------------------------------------
Config.BucketBase = 7000             -- primer bucket asignable (evita choques con otros recursos)
