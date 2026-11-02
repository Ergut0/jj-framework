Config = {}

-- Idioma de los mensajes y de la interfaz: 'es' o 'en'
Config.Locale = 'es'

-- Muestra en la consola del servidor lo que se guarda en los registros
Config.Debug = false

-- 'jj' usa JJ.Notify del framework. 'ox' usa lib.notify
Config.Notify = 'jj'

-- Cuenta del framework en la que se cobra el dinero de los contratos: cash, bank o black
Config.MoneyAccount = 'black'

Config.CryptoName = 'JJC'

-- Permisos del panel. También entra quien tenga el permiso de administración del framework (jj.admin)
Config.Admin = {
    command = 'boostingadmin',
    aces = { 'jj.boosting.admin' },
    identifiers = {}, -- identificadores de personaje con acceso
}

-- Cómo se abre la terminal
Config.Access = {
    command = 'boosting', -- false para quitar el comando
    targetDistance = 2.0,
    points = {
        {
            type = 'npc',
            label = 'Hablar con el contacto',
            model = 's_m_y_dealer_01',
            coords = vec4(706.71, -966.90, 30.40, 150.0),
        },
        {
            type = 'point',
            label = 'Usar el ordenador',
            coords = vec3(1275.40, -1710.50, 54.77),
            radius = 1.0,
        },
    },
}

-- Distancias en metros
Config.Distances = {
    hack = 4.0,           -- del jugador al vehículo para hackear la cerradura
    deliverPlayer = 12.0, -- del jugador al vehículo para entregarlo
    zoneMargin = 40.0,    -- margen sobre el radio de la zona para crear el vehículo
    pickup = 3.0,         -- del jugador al punto de recogida de la tienda
}

Config.Contracts = {
    maxOffers = 3,             -- contratos pendientes por jugador
    offerLifetime = 900,       -- segundos para aceptar un contrato ofrecido
    abandonGrace = 180,        -- segundos para volver tras desconectarse antes de perder el contrato
    cooldownAfterFinish = 120, -- segundos sin recibir ofertas al terminar un contrato
    minDeliverySeconds = 20,   -- menos tiempo desde el robo se considera trampa
    maxAverageSpeed = 110.0,   -- m/s de media entre el robo y la entrega. Más se considera teletransporte
    maxDeliverySpeed = 4.0,    -- m/s: el vehículo tiene que estar casi parado para entregarlo
    damagePenalty = 0.5,       -- parte de la recompensa económica que se pierde con el vehículo destrozado
    failXpPenalty = 10,        -- experiencia que se pierde al fallar. 0 para no quitar
}

-- Cola de búsqueda
Config.Queue = {
    tickSeconds = 20,
    minWait = 60,  -- segundos mínimos entre ofertas
    maxWait = 240, -- segundos máximos entre ofertas
}

-- Niveles de experiencia. Se puede añadir o quitar los que quieras
Config.Levels = { 0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000, 5500, 7500, 10000 }

-- Dificultades de hackeo: casillas por lado, longitud de la secuencia, segundos e intentos
Config.HackDifficulties = {
    easy = { grid = 4, length = 4, time = 25, attempts = 3 },
    medium = { grid = 5, length = 5, time = 22, attempts = 3 },
    hard = { grid = 6, length = 6, time = 20, attempts = 2 },
    expert = { grid = 6, length = 8, time = 18, attempts = 2 },
}

-- Qué ocurre al agotar los intentos: 'fail' pierde el contrato, 'alarm' salta la alarma y avisa a la policía
Config.HackExhausted = 'fail'

-- Modalidades de contrato
Config.Tiers = {
    basic = {
        label = 'Básico',
        locked = false,
        hack = false,
        tracker = false,
        guards = 0,
    },
    intermediate = {
        label = 'Intermedio',
        locked = true,
        hack = true,
        tracker = false,
        guards = 0,
    },
    advanced = {
        label = 'Avanzado',
        locked = true,
        hack = true,
        tracker = true,
        guards = 2,
    },
}

-- Clases. order marca el progreso; rewards va en { mínimo, máximo }
-- purchasePrice: precio en criptomoneda para comprar el contrato en vez de esperar la cola. false para no venderlo
Config.Classes = {
    D = {
        label = 'Clase D',
        order = 1,
        tier = 'basic',
        unlockXp = 0,
        offerWeight = 50,
        duration = 1500,
        minPolice = 0,
        alertChance = 0.15,
        hackDifficulty = 'easy',
        purchasePrice = false,
        rewards = { money = { 800, 1500 }, crypto = { 2, 5 }, xp = { 20, 30 } },
        models = {
            { model = 'blista', label = 'Dinka Blista' },
            { model = 'asea', label = 'Declasse Asea' },
            { model = 'ingot', label = 'Vulcar Ingot' },
            { model = 'prairie', label = 'Bollokan Prairie' },
        },
    },
    C = {
        label = 'Clase C',
        order = 2,
        tier = 'basic',
        unlockXp = 250,
        offerWeight = 40,
        duration = 1500,
        minPolice = 0,
        alertChance = 0.3,
        hackDifficulty = 'easy',
        purchasePrice = false,
        rewards = { money = { 1800, 3200 }, crypto = { 5, 10 }, xp = { 35, 50 } },
        models = {
            { model = 'sultan', label = 'Karin Sultan' },
            { model = 'buffalo', label = 'Bravado Buffalo' },
            { model = 'schafter2', label = 'Benefactor Schafter' },
        },
    },
    B = {
        label = 'Clase B',
        order = 3,
        tier = 'intermediate',
        unlockXp = 800,
        offerWeight = 30,
        duration = 1800,
        minPolice = 1,
        alertChance = 0.5,
        hackDifficulty = 'medium',
        purchasePrice = 40,
        rewards = { money = { 4000, 7000 }, crypto = { 12, 22 }, xp = { 60, 85 } },
        models = {
            { model = 'comet2', label = 'Pfister Comet' },
            { model = 'carbonizzare', label = 'Grotti Carbonizzare' },
            { model = 'feltzer2', label = 'Benefactor Feltzer' },
        },
    },
    A = {
        label = 'Clase A',
        order = 4,
        tier = 'advanced',
        unlockXp = 2300,
        offerWeight = 15,
        duration = 1800,
        minPolice = 2,
        alertChance = 0.8,
        hackDifficulty = 'hard',
        purchasePrice = 90,
        guards = 2,
        rewards = { money = { 9000, 15000 }, crypto = { 30, 50 }, xp = { 100, 140 } },
        models = {
            { model = 'turismor', label = 'Grotti Turismo R' },
            { model = 'entityxf', label = 'Överflöd Entity XF' },
            { model = 'zentorno', label = 'Pegassi Zentorno' },
        },
    },
    S = {
        label = 'Clase S',
        order = 5,
        tier = 'advanced',
        unlockXp = 5500,
        offerWeight = 5,
        duration = 2100,
        minPolice = 3,
        alertChance = 1.0,
        hackDifficulty = 'expert',
        purchasePrice = 200,
        guards = 4,
        rewards = { money = { 20000, 35000 }, crypto = { 70, 120 }, xp = { 180, 260 } },
        models = {
            { model = 't20', label = 'Progen T20' },
            { model = 'osiris', label = 'Pegassi Osiris' },
            { model = 'tempesta', label = 'Pegassi Tempesta' },
        },
    },
}

-- Zonas de búsqueda. center y radius es lo que ve el jugador; spots son los sitios reales del vehículo
-- Las coordenadas son orientativas: ajústalas a tu mapa (ver README)
Config.Zones = {
    legion = {
        label = 'Legion Square',
        center = vec3(210.0, -850.0, 30.5),
        radius = 220.0,
        spots = { vec4(215.80, -810.10, 30.73, 340.0), vec4(238.40, -800.30, 30.40, 70.0), vec4(148.60, -1072.40, 29.19, 90.0) },
    },
    mirror = {
        label = 'Mirror Park',
        center = vec3(1140.0, -480.0, 66.0),
        radius = 260.0,
        spots = { vec4(1163.10, -330.40, 68.90, 100.0), vec4(1137.60, -468.20, 66.50, 345.0) },
    },
    davis = {
        label = 'Davis',
        center = vec3(120.0, -1920.0, 21.0),
        radius = 250.0,
        spots = { vec4(106.40, -1941.20, 20.80, 45.0), vec4(-46.80, -1838.70, 26.10, 320.0) },
    },
    vespucci = {
        label = 'Vespucci',
        center = vec3(-1150.0, -1470.0, 4.4),
        radius = 240.0,
        spots = { vec4(-1183.90, -1510.30, 4.38, 305.0), vec4(-1081.70, -1261.50, 5.60, 120.0) },
    },
    sandy = {
        label = 'Sandy Shores',
        center = vec3(1880.0, 3720.0, 33.0),
        radius = 350.0,
        spots = { vec4(1965.20, 3741.10, 32.34, 300.0), vec4(1737.60, 3710.20, 34.10, 20.0) },
    },
    paleto = {
        label = 'Paleto Bay',
        center = vec3(-150.0, 6330.0, 31.5),
        radius = 300.0,
        spots = { vec4(-99.70, 6212.00, 31.03, 45.0), vec4(-290.30, 6251.40, 31.49, 45.0) },
    },
}

-- Puntos de entrega
Config.Dropoffs = {
    scrapyard = { label = 'Desguace de La Mesa', coords = vec3(-428.0, -1728.0, 19.1), radius = 12.0 },
    docks = { label = 'Terminal del puerto', coords = vec3(1210.0, -3115.0, 5.5), radius = 15.0 },
    hangar = { label = 'Hangar de Sandy Shores', coords = vec3(1735.0, 3290.0, 41.1), radius = 15.0 },
    sawmill = { label = 'Aserradero de Paleto', coords = vec3(-573.0, 5253.0, 70.5), radius = 15.0 },
}

-- Protectores de los contratos avanzados
Config.Guards = {
    models = { 's_m_m_highsec_01', 's_m_y_blackops_01' },
    weapon = 'WEAPON_PISTOL',
    armour = 50,
    aggroDistance = 25.0,
}

-- Rastreador de los contratos que lo llevan
Config.Tracker = {
    pulseSeconds = 10,
    accuracy = 30.0,    -- la policía ve el vehículo con este error, en metros
    disableAfter = 60,  -- segundos tras el robo antes de poder intentar desactivarlo
    mode = 'both',      -- 'hack' con el minijuego, 'item' gastando un objeto, 'both' prueba el objeto y si no el minijuego
    item = 'hackingdevice',
    hackDifficulty = 'medium',
    key = 'F7',         -- tecla para desactivarlo dentro del vehículo
}

Config.Police = {
    jobs = { police = true, sheriff = true },
    -- 'jj_policedispatch' usa su export AddAlert. 'event' lanza Config.Police.event en el servidor. false no avisa
    dispatch = 'jj_policedispatch',
    event = 'jj_boosting:policeAlert',
    alertType = 'robo_vehiculo',
    hackFailChance = 0.5, -- probabilidad de aviso al fallar un intento de hackeo
}

-- Tienda. stock false no tiene límite. maxPerPlayer limita por jugador en cada reinicio
-- type: 'item' da un objeto de ox_inventory; 'service' activa un servicio de la terminal
-- pickup true deja la compra en el punto de recogida. requiredClass exige tener esa clase desbloqueada
Config.Store = {
    pickupPoint = { coords = vec3(1275.40, -1712.50, 54.77), label = 'Recoger pedido' },
    items = {
        { id = 'lockpick', type = 'item', item = 'lockpick', label = 'Ganzúa', description = 'Para cerraduras sencillas.', price = 3, stock = 25, maxPerPlayer = 5 },
        { id = 'advancedlockpick', type = 'item', item = 'advancedlockpick', label = 'Ganzúa avanzada', description = 'Más resistente que la normal.', price = 8, stock = 15, maxPerPlayer = 3, requiredClass = 'C' },
        { id = 'electronickit', type = 'item', item = 'electronickit', label = 'Kit electrónico', description = 'Herramientas para electrónica de vehículos.', price = 15, stock = 10, maxPerPlayer = 2, requiredClass = 'B' },
        { id = 'hackingdevice', type = 'item', item = 'hackingdevice', label = 'Dispositivo de hackeo', description = 'Desactiva un rastreador sin minijuego.', price = 35, stock = 5, maxPerPlayer = 1, requiredClass = 'A', pickup = true },
        { id = 'priority', type = 'service', service = 'priority', label = 'Prioridad de cola', description = 'Tus 3 próximas ofertas llegan antes.', price = 20, uses = 3, stock = false, maxPerPlayer = 2 },
    },
}

-- Perfil
Config.Profile = {
    nameMin = 3,
    nameMax = 24,
    nameCooldown = 86400,
    -- Solo se aceptan imágenes https de estos dominios
    avatarDomains = { 'i.imgur.com', 'cdn.discordapp.com', 'media.discordapp.net', 'r2.fivemanage.com' },
}

-- Clasificación. sort: 'xp', 'completed' o 'crypto_earned'
Config.Leaderboard = {
    sort = 'xp',
    size = 50,
    cacheSeconds = 300,
}

-- Milisegundos mínimos entre llamadas iguales de un mismo jugador
Config.RateLimit = {
    default = 400,
    hack = 1500,
    deliver = 2000,
    store = 1000,
    -- Llamadas bloqueadas seguidas que se registran como sospechosas
    flagAfter = 20,
}

-- Días que se conservan los registros. 0 no borra nada
Config.LogRetentionDays = 60
