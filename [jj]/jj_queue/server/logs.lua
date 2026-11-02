-- Registro en Discord de quien entra, sale o no puede entrar al servidor.
-- Los mensajes se envían de uno en uno para no pasarse del límite de Discord
local API = 'https://discord.com/api/v10'
local COLORS = { join = 0x4ADE80, leave = 0xFB7185, rejected = 0xFACC15 }

local pending = {}
local sending = false
local joinedAt = {}   -- source -> momento en que entró
local characters = {} -- source -> nombre del personaje cargado

local function botToken()
    local token = GetConvar('jj_queue_bot_token', '')
    if token == '' then token = Config.Discord.BotToken or '' end
    return token
end

-- Con webhook escribe el webhook; si no, el bot en el canal configurado
local function destination()
    local logs = Config.Logs
    local webhook = GetConvar('jj_queue_webhook', '')
    if webhook == '' then webhook = logs.Webhook or '' end
    if webhook ~= '' then
        return webhook, { ['Content-Type'] = 'application/json' }, true
    end
    if logs.ChannelId ~= '' and botToken() ~= '' then
        return ('%s/channels/%s/messages'):format(API, logs.ChannelId), {
            ['Content-Type'] = 'application/json',
            Authorization = 'Bot ' .. botToken(),
        }, false
    end
end

local function post(url, payload, headers)
    local response = promise.new()
    PerformHttpRequest(url, function(status, body)
        response:resolve({ status = status, body = body })
    end, 'POST', json.encode(payload), headers)
    return Citizen.Await(response)
end

local function process()
    if sending then return end
    sending = true

    CreateThread(function()
        while #pending > 0 do
            local message = table.remove(pending, 1)
            local url, headers, isWebhook = destination()
            if not url then
                pending = {}
                break
            end

            if isWebhook then message.username = Config.ServerName end
            local response = post(url, message, headers)

            if response.status == 429 then
                -- Discord pide esperar: se vuelve a intentar el mismo mensaje
                local data = response.body and json.decode(response.body) or {}
                table.insert(pending, 1, message)
                Wait(math.ceil((tonumber(data.retry_after) or 2) * 1000))
            elseif not response.status or response.status == 0 or response.status >= 400 then
                print(('^3[jj_queue] No se ha podido enviar el log a Discord (código %s). Revisa el webhook o que el bot pueda escribir en el canal^7'):format(tostring(response.status)))
            end

            Wait(1100)
        end
        sending = false
    end)
end

local function send(kind, title, fields)
    if not Config.Logs.Enabled then return end

    pending[#pending + 1] = {
        embeds = { {
            title = title,
            color = COLORS[kind],
            fields = fields,
            footer = { text = Config.ServerName },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
        -- Se ve la mención de Discord, pero no avisa a nadie (ni aunque un nombre lleve @everyone)
        allowed_mentions = { parse = {} },
    }
    process()
end

local function clean(text, max)
    text = tostring(text or '')
    text = text:gsub('[`*_~|>]', '')
    if #text > max then text = text:sub(1, max) .. '…' end
    return text ~= '' and text or '-'
end

local function duration(seconds)
    local hours, minutes = seconds // 3600, (seconds % 3600) // 60
    if hours > 0 then return ('%d h %d min'):format(hours, minutes) end
    return ('%d min'):format(math.max(minutes, 0))
end

local function playerFields(src)
    local discord = GetPlayerIdentifierByType(src, 'discord')
    local fields = {
        { name = 'Jugador', value = clean(GetPlayerName(src), 64), inline = true },
        { name = 'Discord', value = discord and ('<@%s>'):format(discord:sub(9)) or 'Sin Discord', inline = true },
        { name = 'Licencia', value = clean(GetPlayerIdentifierByType(src, 'license'), 80), inline = false },
    }
    return fields
end

local function playerCount(offset)
    return ('%d / %d'):format(#GetPlayers() + (offset or 0), GetConvarInt('sv_maxclients', 48))
end

AddEventHandler('playerJoining', function()
    local src = source
    joinedAt[src] = os.time()
    if not Config.Logs.Join then return end

    local fields = playerFields(src)
    table.insert(fields, 2, { name = 'ID', value = tostring(src), inline = true })
    fields[#fields + 1] = { name = 'Jugadores', value = playerCount(), inline = true }
    send('join', 'Entra en el servidor', fields)
end)

-- El nombre del personaje solo se conoce cuando lo elige
AddEventHandler('jj:server:playerLoaded', function(src)
    local ok, name = pcall(function()
        local player = exports['jj-framework']:GetCoreObject().GetPlayer(src)
        return player and player.getName()
    end)
    if ok and name then characters[src] = name end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local joined = joinedAt[src]
    local character = characters[src]
    joinedAt[src], characters[src] = nil, nil
    if not Config.Logs.Leave then return end

    local fields = playerFields(src)
    table.insert(fields, 2, { name = 'ID', value = tostring(src), inline = true })
    fields[#fields + 1] = { name = 'Personaje', value = clean(character or 'No llegó a elegir', 64), inline = true }
    fields[#fields + 1] = { name = 'Tiempo jugado', value = joined and duration(os.time() - joined) or '-', inline = true }
    fields[#fields + 1] = { name = 'Motivo', value = clean(reason, 200), inline = false }
    fields[#fields + 1] = { name = 'Jugadores', value = playerCount(-1), inline = true }
    send('leave', 'Sale del servidor', fields)
end)

-- Lo llama la cola cuando no deja entrar a alguien
function LogRejected(src, reason)
    if not Config.Logs.Rejected then return end

    local fields = playerFields(src)
    fields[#fields + 1] = { name = 'Motivo', value = clean(reason, 200), inline = false }
    send('rejected', 'No ha podido entrar', fields)
end

CreateThread(function()
    if Config.Logs.Enabled and not destination() then
        print('^3[jj_queue] Los logs de Discord están activados pero falta el webhook (jj_queue_webhook en server.cfg) o Config.Logs.ChannelId^7')
    end
end)
