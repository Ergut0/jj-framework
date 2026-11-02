-- Cola de entrada. Cuando el servidor está lleno, los que conectan esperan su turno por prioridad y por orden de llegada
local queue = {}      -- { license, priority, joined, source }
local loading = {}    -- license -> momento en que pasó la cola, hasta que aparece en el servidor
local recent = {}     -- license -> momento en que se fue, para la vuelta tras una caída

local function getIdentifier(src, kind)
    return GetPlayerIdentifierByType(src, kind)
end

local function discordId(src)
    local identifier = getIdentifier(src, 'discord')
    return identifier and identifier:sub(9) or nil
end

-- Discord: un bot de vuestro servidor dice si la persona está dentro y qué roles tiene

local API = 'https://discord.com/api/v10'
local discordCache = {} -- id de Discord -> { roles, member, at }

local function botToken()
    local token = GetConvar('jj_queue_bot_token', '')
    if token == '' then token = Config.Discord.BotToken or '' end
    return token
end

local function discordEnabled()
    return Config.Discord.Enabled and Config.Discord.GuildId ~= '' and botToken() ~= ''
end

local function request(url)
    local response = promise.new()
    PerformHttpRequest(url, function(status, body, headers)
        response:resolve({ status = status, body = body, headers = headers })
    end, 'GET', '', { Authorization = 'Bot ' .. botToken(), ['Content-Type'] = 'application/json' })
    return Citizen.Await(response)
end

-- Devuelve { member = true/false, roles = { id = true } }, o nil si Discord no ha respondido
local function getMember(discord)
    local cached = discordCache[discord]
    if cached and os.time() - cached.at < Config.Discord.CacheSeconds then return cached end

    local url = ('%s/guilds/%s/members/%s'):format(API, Config.Discord.GuildId, discord)
    local response = request(url)

    -- Demasiadas consultas seguidas: se espera lo que pide Discord y se prueba una vez más
    if response.status == 429 then
        local data = response.body and json.decode(response.body) or {}
        Wait(math.min(math.ceil((tonumber(data.retry_after) or 1) * 1000), 5000))
        response = request(url)
    end

    local result
    if response.status == 200 then
        local data = json.decode(response.body or '') or {}
        local roles = {}
        for _, role in ipairs(data.roles or {}) do roles[tostring(role)] = true end
        result = { member = true, roles = roles }
    elseif response.status == 404 then
        result = { member = false, roles = {} }
    else
        print(('[jj_queue] Discord no responde (código %s). Revisa el token del bot y el id del servidor'):format(tostring(response.status)))
        return nil
    end

    -- Solo se recuerda a quien está dentro: quien entra al Discord para poder jugar no tiene que esperar
    if result.member then
        result.at = os.time()
        discordCache[discord] = result
    end
    return result
end

local function rolePriority(member)
    local priority = 0
    for role, value in pairs(Config.Discord.PriorityRoles) do
        if member and member.roles[tostring(role)] and value > priority then priority = value end
    end
    return priority
end

local function getPriority(src, license, member)
    local priority = rolePriority(member)
    for ace, value in pairs(Config.Priority) do
        if value > priority and IsPlayerAceAllowed(src, ace) then priority = value end
    end

    local left = recent[license]
    if left and os.time() - left <= Config.ReconnectGrace and Config.ReconnectPriority > priority then
        priority = Config.ReconnectPriority
    end
    return priority
end

local function indexOf(license)
    for index, entry in ipairs(queue) do
        if entry.license == license then return index end
    end
end

local function removeFromQueue(license)
    local index = indexOf(license)
    if index then table.remove(queue, index) end
end

-- Mayor prioridad primero; con la misma, quien llegó antes
local function insert(entry)
    local position = #queue + 1
    for index, other in ipairs(queue) do
        if entry.priority > other.priority then
            position = index
            break
        end
    end
    table.insert(queue, position, entry)
end

local function countLoading()
    local now, count = os.time(), 0
    for license, since in pairs(loading) do
        if now - since > Config.LoadingTimeout then
            loading[license] = nil
        else
            count = count + 1
        end
    end
    return count
end

local function hasSlot(priority)
    local max = GetConvarInt('sv_maxclients', 48)
    if priority < Config.ReservedPriority then
        max = max - Config.ReservedSlots
    end
    return #GetPlayers() + countLoading() < max
end

local function waitText(position, total, waited)
    return ('%s · En la cola: %d de %d · Esperando %d:%02d'):format(Config.ServerName, position, total, waited // 60, waited % 60)
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update(('%s · Comprobando tu cuenta...'):format(Config.ServerName))

    -- Rechaza la conexión y lo deja en el log de Discord
    local function reject(reason)
        if LogRejected then LogRejected(src, reason) end
        return deferrals.done(reason)
    end

    local license = getIdentifier(src, 'license')
    if not license then
        return reject('No se ha encontrado tu licencia de Rockstar. Abre FiveM de nuevo.')
    end

    local discord = discordId(src)
    if Config.RequireDiscord and not discord then
        return reject('Tienes que tener Discord abierto y enlazado con FiveM para entrar en el servidor.')
    end

    local invite = Config.DiscordInvite ~= '' and ('\nEntra en nuestro Discord: %s'):format(Config.DiscordInvite) or ''

    local member
    if discord and discordEnabled() then
        deferrals.update(('%s · Comprobando tus roles de Discord...'):format(Config.ServerName))
        member = getMember(discord)
        if not member then
            return reject('No se ha podido comprobar tu Discord. Prueba otra vez en un momento.')
        end
        if Config.Discord.RequireMember and not member.member then
            return reject(('Tienes que estar en el Discord de %s para jugar.%s'):format(Config.ServerName, invite))
        end
    end

    if Config.Whitelist then
        local role = Config.Discord.WhitelistRole
        local hasRole = role ~= '' and member and member.roles[tostring(role)]
        local allowed = hasRole or (discord and MySQL.scalar.await('SELECT 1 FROM jj_whitelist WHERE discord = ?', { discord }))
        if not allowed then
            return reject(('No tienes la whitelist de %s.%s'):format(Config.ServerName, invite))
        end
    end

    -- Si ya estaba en la cola (por ejemplo, ha vuelto a conectar), conserva su sitio
    local entry
    local index = indexOf(license)
    if index then
        entry = queue[index]
        entry.source = src
    else
        entry = { license = license, priority = getPriority(src, license, member), joined = os.time(), source = src }
        insert(entry)
    end

    while true do
        -- Ha cancelado o ha conectado otra vez con otra conexión
        if not GetPlayerName(src) or entry.source ~= src then
            if entry.source == src then removeFromQueue(license) end
            return
        end

        local position = indexOf(license)
        if position == 1 and hasSlot(entry.priority) then break end

        deferrals.update(waitText(position or 1, #queue, os.time() - entry.joined))
        Wait(1000)
    end

    removeFromQueue(license)
    loading[license] = os.time()
    deferrals.update(('%s · Entrando...'):format(Config.ServerName))
    Wait(500)
    deferrals.done()
end)

-- Ya ha entrado: deja de ocupar un hueco de carga
AddEventHandler('playerJoining', function()
    local license = getIdentifier(source, 'license')
    if license then loading[license] = nil end
end)

AddEventHandler('playerDropped', function()
    local license = getIdentifier(source, 'license')
    if not license then return end

    loading[license] = nil
    recent[license] = os.time()
end)

-- Limpieza de las caídas antiguas
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for license, left in pairs(recent) do
            if now - left > Config.ReconnectGrace then recent[license] = nil end
        end
    end
end)

-- Whitelist y estado de la cola, para administradores y para la consola

CreateThread(function()
    if not Config.Discord.Enabled then return end
    if Config.Discord.GuildId == '' then
        print('^3[jj_queue] Falta el id del servidor de Discord (Config.Discord.GuildId): no se miran los roles^7')
    elseif botToken() == '' then
        print('^3[jj_queue] Falta el token del bot: ponlo en Config.Discord.BotToken de config.lua. No se miran los roles^7')
    end
end)

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_whitelist` (
            `discord` VARCHAR(32) NOT NULL,
            `added_by` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`discord`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, 'jj.admin')
end

local function reply(src, message)
    if src == 0 then
        print(('[jj_queue] %s'):format(message))
    else
        TriggerClientEvent('ox_lib:notify', src, { description = message })
    end
end

local function adminName(src)
    return src == 0 and 'consola' or GetPlayerName(src)
end

local function validDiscord(value)
    return type(value) == 'string' and value:match('^%d+$') and #value >= 15 and #value <= 21
end

RegisterCommand('addwhitelist', function(src, args)
    if not isAdmin(src) then return reply(src, 'No tienes permiso para usar este comando') end

    local discord = args[1]
    if not validDiscord(discord) then return reply(src, 'Uso: /addwhitelist <id de Discord>') end

    local added = MySQL.update.await('INSERT IGNORE INTO jj_whitelist (discord, added_by) VALUES (?, ?)', { discord, adminName(src) })
    if not added or added < 1 then return reply(src, 'Esa persona ya está en la whitelist') end

    print(('[jj_queue] %s añade a la whitelist el Discord %s'):format(adminName(src), discord))
    reply(src, 'Añadido a la whitelist')
end, false)

RegisterCommand('removewhitelist', function(src, args)
    if not isAdmin(src) then return reply(src, 'No tienes permiso para usar este comando') end

    local discord = args[1]
    if not validDiscord(discord) then return reply(src, 'Uso: /removewhitelist <id de Discord>') end

    local removed = MySQL.update.await('DELETE FROM jj_whitelist WHERE discord = ?', { discord })
    if not removed or removed < 1 then return reply(src, 'Esa persona no está en la whitelist') end

    print(('[jj_queue] %s quita de la whitelist el Discord %s'):format(adminName(src), discord))
    reply(src, 'Quitado de la whitelist')
end, false)

RegisterCommand('cola', function(src)
    if not isAdmin(src) then return reply(src, 'No tienes permiso para usar este comando') end
    local discordState = discordEnabled() and 'roles de Discord activos' or 'sin roles de Discord'
    reply(src, ('En la cola: %d · Cargando: %d · Conectados: %d de %d · %s'):format(#queue, countLoading(), #GetPlayers(), GetConvarInt('sv_maxclients', 48), discordState))
end, false)

-- Para ver los roles de alguien sin esperar a la caché, por ejemplo tras darle un rol en Discord
RegisterCommand('rolesdiscord', function(src, args)
    if not isAdmin(src) then return reply(src, 'No tienes permiso para usar este comando') end
    if not discordEnabled() then return reply(src, 'Los roles de Discord no están configurados') end

    local discord = args[1]
    if not validDiscord(discord) then return reply(src, 'Uso: /rolesdiscord <id de Discord>') end

    discordCache[discord] = nil
    local member = getMember(discord)
    if not member then return reply(src, 'Discord no responde') end
    if not member.member then return reply(src, 'No está en el Discord') end

    local whitelist = Config.Discord.WhitelistRole ~= '' and member.roles[tostring(Config.Discord.WhitelistRole)] and 'sí' or 'no'
    reply(src, ('Está en el Discord · Rol de whitelist: %s · Prioridad por roles: %d'):format(whitelist, rolePriority(member)))
end, false)
