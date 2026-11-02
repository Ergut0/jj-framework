Config = {}

Config.ServerName = 'Atlantis Roleplay'

-- Hace falta tener Discord enlazado con FiveM para entrar
Config.RequireDiscord = true

-- Whitelist: con true solo entra quien tenga el rol de whitelist en Discord (Config.Discord.WhitelistRole)
-- o esté añadido a mano con /addwhitelist
Config.Whitelist = true
Config.DiscordInvite = 'discord.gg/atlantisrpesp' -- se muestra a quien no está en el Discord o no tiene el rol

-- Roles de vuestro servidor de Discord, que consulta un bot al conectar
Config.Discord = {
    Enabled = true,
    -- Token del bot: va en server.cfg con  set jj_queue_bot_token "..."  para que no se suba a GitHub.
    -- Aquí solo como alternativa, y nunca en un repositorio
    BotToken = '',
    GuildId = '1445552310431518913',          -- id del servidor de Discord (clic derecho en el servidor > Copiar ID)
    RequireMember = true,  -- hay que estar dentro del servidor de Discord para jugar
    WhitelistRole = '1563452395206484038',    -- id del rol que da la whitelist (solo cuenta con Config.Whitelist = true)

    -- Prioridad en la cola por rol: ['id del rol'] = prioridad. Cuenta la más alta que tenga
    PriorityRoles = {
        -- ['111111111111111111'] = 100, -- Staff
        -- ['222222222222222222'] = 50,  -- VIP
    },

    CacheSeconds = 300, -- tiempo que se recuerdan los roles de alguien antes de volver a preguntar
}

-- Prioridad en la cola según los permisos (ACE) del jugador, además de los roles de Discord.
-- Se dan en server.cfg, por ejemplo: add_ace identifier.discord:123456789 jj.queue.vip allow
Config.Priority = {
    ['jj.admin'] = 100,
    ['jj.queue.staff'] = 80,
    ['jj.queue.vip'] = 50,
}

-- Quien se cae del servidor y vuelve en este tiempo (segundos) entra el primero
Config.ReconnectGrace = 180
Config.ReconnectPriority = 90

-- Huecos reservados: solo los usa quien tiene esta prioridad o más (0 para no reservar ninguno)
Config.ReservedSlots = 0
Config.ReservedPriority = 80

-- Tiempo máximo que se guarda el hueco a quien ya ha pasado la cola y está cargando (segundos)
Config.LoadingTimeout = 300

-- Avisos en Discord de quien entra, sale o no puede entrar
Config.Logs = {
    Enabled = true,
    -- Webhook del canal: Editar canal > Integraciones > Webhooks > Nuevo webhook > Copiar URL.
    -- Va en server.cfg con  set jj_queue_webhook "..."  para que no se suba a GitHub.
    -- Si no hay webhook, escribe el bot en el canal de ChannelId (necesita permiso para enviar mensajes allí)
    Webhook = '',
    ChannelId = '1566773990817796208',
    Join = true,     -- entra en el servidor
    Leave = true,    -- sale, con el personaje, el tiempo jugado y el motivo
    Rejected = true, -- no le deja entrar: sin Discord, sin whitelist...
}
