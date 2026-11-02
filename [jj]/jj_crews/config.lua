Config = {}

-- General -------------------------------------------------------------------
Config.Locale = 'es'                 -- 'es' | 'en' (ver carpeta locales)
Config.Debug = false                 -- logs de depuracion en consola
Config.Currency = '$'

-- Comandos -------------------------------------------------------------------
-- El panel de jugador se abre con el objeto tablet_crew de ox_inventory
Config.AdminCommand = 'crewadmin'    -- abre el panel de administracion

-- Permisos de administracion (validados SIEMPRE en el servidor) -------------
-- Además de los administradores de jj-framework, quien tenga este ACE: add_ace group.mod crews.admin allow
Config.AdminAce = 'crews.admin'

-- Dinero --------------------------------------------------------------------
Config.CreateAccount = 'bank'        -- cuenta de la que se cobra la creacion
Config.WithdrawAccount = 'cash'      -- cuenta que recibe los retiros del banco
Config.DepositAccounts = { 'cash', 'bank' }
Config.MaxTransaction = 10000000     -- importe maximo por operacion
Config.MaxBankBalance = 2000000000   -- saldo maximo del banco de un crew

-- Ajustes editables en vivo desde el panel admin (se guardan en BD) ---------
Config.Settings = {
    maxMembers = 20,
    createCost = 25000,
    nameMin = 3,
    nameMax = 24,
    maxRanks = 8,
    inviteExpiryMinutes = 30,
    allowLogo = true,
    bannedNames = { 'admin', 'staff', 'moderador', 'policia', 'police', 'nigger', 'nazi' },
}

-- Identidad del crew --------------------------------------------------------
Config.TagMin = 2
Config.TagMax = 5
Config.DefaultColor = '#a855f7'
Config.LogoHosts = {}                -- vacio = cualquier host https; ej: { 'i.imgur.com', 'cdn.discordapp.com' }

-- Permisos de rango disponibles ---------------------------------------------
Config.PermissionKeys = { 'invite', 'kick', 'setRank', 'deposit', 'withdraw', 'manageRanks', 'editCrew' }

-- Rangos creados por defecto en cada crew (el rango de lider se anade aparte)
Config.DefaultRanks = {
    { name = 'Novato',    level = 1, permissions = {} },
    { name = 'Piloto',    level = 2, permissions = { deposit = true } },
    { name = 'Oficial',   level = 3, permissions = { deposit = true, invite = true, kick = true } },
    { name = 'Sublider',  level = 4, permissions = { deposit = true, invite = true, kick = true, setRank = true, withdraw = true } },
}
Config.LeaderRank = { name = 'Lider', level = 99 }

-- Puntos necesarios para cada nivel (indice = nivel). El nivel solo sube automaticamente.
Config.LevelPoints = { 0, 500, 1500, 3500, 7000, 12000, 20000, 35000, 60000, 100000 }

-- Anti-abuso ----------------------------------------------------------------
Config.RateLimit = {
    default = { max = 15, window = 5000 },   -- peticiones por ventana (ms)
    money   = { max = 4,  window = 5000 },
    admin   = { max = 20, window = 5000 },
}

-- Paginacion / listados -----------------------------------------------------
Config.PageSize = 15
Config.RankingSize = 50
Config.LogRetentionDays = 90         -- 0 = no limpiar logs

-- Discord (opcional). El webhook NO va en este fichero porque es compartido con
-- el cliente: define el convar en server.cfg:  set crews_webhook "https://discord.com/api/webhooks/..."
Config.Webhook = IsDuplicityVersion() and GetConvar('crews_webhook', '') or ''
Config.WebhookName = 'Crews'
