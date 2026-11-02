--[[
    Registro de las empresas: lo guarda en la base de datos para la pestaña
    Registro y envía a Discord lo que lleva canal.
    Este archivo solo se carga en el servidor: los webhooks no llegan a los jugadores.
]]

-- Pega aquí la URL de cada webhook: ajustes del canal > Integraciones > Webhooks
local WEBHOOKS = {
    jefe = '',        -- logs-punto-de-jefe: contratar, despedir y cambiar rangos
    caja = '',        -- logs-caja-fuerte: ingresos, retiradas y pedidos pagados con la sociedad
    fichaje = '',     -- logs-fichaje: entrar y salir de servicio
    compraventa = '', -- logs-compra-venta: compra y venta de vehículos
}

local LOG_COLOURS = { servicio = 3447003, empleados = 5763719, dinero = 15844367, facturas = 15105570, vehiculos = 10181046, negocio = 3066993, config = 9807270 }
local LOG_CHANNELS = {}
local LOG_SEND_INTERVAL = 2000 -- Discord limita los envíos: se juntan en un mensaje cada 2 segundos
local LOG_MAX_EMBEDS = 10 -- El máximo de Discord por mensaje
local LOG_MAX_QUEUE = 500
local LOG_RETRY_RATE_LIMIT = 5000
local LOG_RETRY_NO_CONNECTION = 30000

for name, webhook in pairs(WEBHOOKS) do
    LOG_CHANNELS[name] = {
        name = name,
        webhook = webhook,
        queue = {},
        sending = false,
        retryAt = 0,
        errorShown = false,
    }
end

local function RequeueLogs(channel, batch)
    for i = #batch, 1, -1 do
        table.insert(channel.queue, 1, batch[i])
    end
end

local function SendQueuedLogs(channel)
    if channel.sending or #channel.queue == 0 or GetGameTimer() < channel.retryAt then return end

    local batch = {}
    for i = 1, math.min(LOG_MAX_EMBEDS, #channel.queue) do
        batch[i] = table.remove(channel.queue, 1)
    end

    channel.sending = true
    PerformHttpRequest(channel.webhook, function(status)
        channel.sending = false

        if status >= 200 and status < 300 then
            return
        end

        -- Sin conexión o con demasiados envíos, se vuelve a intentar
        if status == 429 or status == 0 or status >= 500 then
            RequeueLogs(channel, batch)
            channel.retryAt = GetGameTimer() + (status == 429 and LOG_RETRY_RATE_LIMIT or LOG_RETRY_NO_CONNECTION)
            return
        end

        -- Reintentarlo no serviría: el webhook no existe o la URL está mal
        if not channel.errorShown then
            channel.errorShown = true
            print(('^1[jj_creatorjobs] Discord ha rechazado el registro (código %d). Revisa el webhook %s en server/logs.lua.^7'):format(status, channel.name))
        end
    end, 'POST', json.encode({
        -- Un nombre o un concepto con @everyone no debe avisar a nadie
        allowed_mentions = { parse = {} },
        embeds = batch,
    }), { ['Content-Type'] = 'application/json' })
end

local function SendLogToDiscord(channel, category, jobName, actor, message)
    if #channel.queue >= LOG_MAX_QUEUE then
        table.remove(channel.queue, 1)
    end

    channel.queue[#channel.queue + 1] = {
        title = jobName or 'Creador de trabajos',
        description = message,
        color = LOG_COLOURS[category],
        footer = { text = actor },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
end

local hasWebhook = false
for _, channel in pairs(LOG_CHANNELS) do
    if channel.webhook ~= '' then
        hasWebhook = true
    else
        print(('^3[jj_creatorjobs] Este registro no se envía a Discord: falta el webhook %s en server/logs.lua.^7'):format(channel.name))
    end
end

if hasWebhook then
    CreateThread(function()
        while true do
            Wait(LOG_SEND_INTERVAL)
            for _, channel in pairs(LOG_CHANNELS) do
                SendQueuedLogs(channel)
            end
        end
    end)
end

--- Envía una prueba a cada canal con webhook. Devuelve los canales a los que se ha enviado.
function SendTestLogs(actor)
    local sent = 0

    for name, channel in pairs(LOG_CHANNELS) do
        if channel.webhook ~= '' then
            sent = sent + 1
            SendLogToDiscord(channel, 'config', nil, actor, ('Prueba del registro en Discord: %s'):format(name))
        end
    end

    return sent
end

--- Guarda una acción en el registro de la empresa y, si lleva canal con webhook, la envía a Discord.
--- @param source number|nil Quien la hace. Sin él, la ha hecho el sistema
--- @param category string servicio, empleados, dinero, facturas, vehiculos, negocio o config
--- @param jobName string|nil
--- @param message string
--- @param channelName string|nil jefe, caja, fichaje o compraventa
function Log(source, category, jobName, message, channelName)
    local player = source and JJ.GetPlayer(source)
    local actor = player and player.getName() or (source and (GetPlayerName(source) or 'Consola')) or 'Sistema'

    MySQL.insert('INSERT INTO jobscreator_logs (job, category, actor, identifier, message, created_at) VALUES (?, ?, ?, ?, ?, ?)', {
        jobName, category, actor, player and player.identifier or nil, message, os.time(),
    })

    local channel = channelName and LOG_CHANNELS[channelName]
    if channel and channel.webhook ~= '' then
        SendLogToDiscord(channel, category, jobName, actor, message)
    end
end
