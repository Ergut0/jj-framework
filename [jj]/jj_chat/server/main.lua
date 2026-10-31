local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local lastSent = {}
local lastReply = {}
local lastReport = {}
local muted = {} -- [licencia] = hora en la que termina el silencio

local function send(target, message)
    TriggerClientEvent('chat:addMessage', target, message)
end

local function notify(src, text)
    if src == 0 then
        print(text)
    else
        send(src, { channel = 'system', tag = 'Sistema', text = text })
    end
end

local function isStaff(src)
    for _, ace in ipairs(Config.StaffAces) do
        if IsPlayerAceAllowed(tostring(src), ace) then
            return true
        end
    end
    return false
end

local function getDisplayName(src)
    local player = JJ.GetPlayer(src)
    return player and player.getName() or GetPlayerName(src)
end

-- Quita los códigos de color y deja el texto dentro del límite sin partir un carácter
local function clean(text)
    if type(text) ~= 'string' then return '' end
    text = text:gsub('%^[%d%*_~=r]', ''):gsub('%c', ' '):match('^%s*(.-)%s*$')
    if #text <= Config.MaxLength then return text end
    local cut = utf8.len(text) and utf8.offset(text, Config.MaxLength + 1)
    return text:sub(1, cut and cut - 1 or Config.MaxLength)
end

-- Silencios

local function getMuteMinutes(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    local untilTime = license and muted[license]
    if not untilTime then return nil end
    if untilTime <= os.time() then
        muted[license] = nil
        return nil
    end
    return math.ceil((untilTime - os.time()) / 60)
end

exports('isMuted', function(src)
    return getMuteMinutes(src) ~= nil
end)

-- Devuelve el jugador si puede escribir ahora mismo
local function getSender(src, ignoreMute)
    if src == 0 then
        print('Este comando solo se puede usar dentro del juego')
        return nil
    end

    local player = JJ.GetPlayer(src)
    if not player then
        notify(src, 'Todavía no has entrado con un personaje')
        return nil
    end

    local minutes = not ignoreMute and getMuteMinutes(src)
    if minutes then
        notify(src, ('Estás silenciado. Podrás escribir en %d min'):format(minutes))
        return nil
    end

    local now = GetGameTimer()
    if lastSent[src] and now - lastSent[src] < Config.Cooldown then
        notify(src, 'Espera un momento antes de escribir otra vez')
        return nil
    end
    lastSent[src] = now
    return player
end

-- Canales

local function sendNearby(src, distance, message)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        notify(src, 'Tu personaje aún no está en el mundo')
        return
    end

    local coords = GetEntityCoords(ped)
    local bucket = GetPlayerRoutingBucket(src)
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        local targetPed = GetPlayerPed(target)
        if targetPed and targetPed ~= 0 and GetPlayerRoutingBucket(target) == bucket
            and #(coords - GetEntityCoords(targetPed)) <= distance then
            send(target, message)
        end
    end
end

local function nearbyChannel(channel, tag, distanceKey)
    return function(src, player, text)
        local message = { channel = channel, tag = tag, author = player.getName(), id = src, text = text }
        local distance = Config.Distance[distanceKey]
        if distance then
            sendNearby(src, distance, message)
        else
            send(-1, message)
        end
    end
end

local channels = {
    say = { run = nearbyChannel('local', nil, 'say') },
    shout = { run = nearbyChannel('local', 'Grita', 'shout') },
    whisper = { run = nearbyChannel('local', 'Susurra', 'whisper') },
    ooc = { run = nearbyChannel('ooc', 'OOC', 'ooc') },
    job = {
        run = function(src, player, text)
            local job = player.getJob()
            if Config.NoJobChannel[job.name] then
                return notify(src, 'Tu trabajo no tiene canal')
            end
            if not job.onDuty then
                return notify(src, 'Tienes que estar de servicio')
            end

            local message = { channel = 'job', tag = job.label, author = player.getName(), detail = job.gradeLabel, id = src, text = text }
            for _, id in pairs(JJ.GetPlayers()) do
                local other = JJ.GetPlayer(id)
                local otherJob = other and other.getJob()
                if otherJob and otherJob.name == job.name and otherJob.onDuty then
                    send(id, message)
                end
            end
        end,
    },
    staff = {
        ignoreMute = true,
        run = function(src, player, text)
            if not isStaff(src) then
                return notify(src, 'No tienes permiso para usar este canal')
            end
            for _, id in ipairs(GetPlayers()) do
                local target = tonumber(id)
                if isStaff(target) then
                    send(target, { channel = 'staff', tag = 'Staff', author = player.getName(), id = src, text = text })
                end
            end
        end,
    },
}

local function speak(channelName, src, rawText)
    local channel = channels[channelName]
    local text = clean(rawText)
    if not channel or text == '' then return false end

    local player = getSender(src, channel.ignoreMute)
    if not player then return true end

    -- Otros recursos pueden cancelar el mensaje, igual que con el chat de FiveM
    TriggerEvent('chatMessage', src, player.getName(), text)
    if WasEventCanceled() then return true end

    print(('[jj_chat] [%s] %s (%d): %s'):format(channelName, player.getName(), src, text))
    channel.run(src, player, text)
    return true
end

-- Mensajes privados: el contenido no se escribe en la consola

local function sendPrivate(src, target, rawText)
    local text = clean(rawText)
    if text == '' then return false end

    local player = getSender(src)
    if not player then return true end
    if target == src then
        notify(src, 'No puedes enviarte un mensaje a ti mismo')
        return true
    end
    if not target or not GetPlayerName(target) then
        notify(src, 'Ese jugador no está conectado')
        return true
    end

    send(target, { channel = 'pm', tag = 'De', author = player.getName(), id = src, text = text })
    send(src, { channel = 'pm', tag = 'Para', author = getDisplayName(target), id = target, text = text })
    lastReply[src] = target
    lastReply[target] = src
    print(('[jj_chat] [mp] %d -> %d'):format(src, target))
    return true
end

local function reply(src, text)
    if not lastReply[src] then
        if clean(text) ~= '' then
            notify(src, 'No tienes ningún mensaje privado al que responder')
        end
        return clean(text) ~= ''
    end
    return sendPrivate(src, lastReply[src], text)
end

-- Comandos

local function usage(src, command, params)
    local names = {}
    for _, param in ipairs(params or {}) do
        names[#names + 1] = ('<%s>'):format(param.name)
    end
    notify(src, ('Uso: /%s %s'):format(command, table.concat(names, ' ')))
end

for _, command in ipairs(Config.Commands) do
    if command.channel then
        for _, name in ipairs(command.names) do
            RegisterCommand(name, function(src, args)
                if not speak(command.channel, src, table.concat(args, ' ')) then
                    usage(src, name, command.params)
                end
            end, false)
        end
    end
end

local function registerPrivate(name)
    RegisterCommand(name, function(src, args)
        local target = tonumber(args[1])
        table.remove(args, 1)
        if not target or not sendPrivate(src, target, table.concat(args, ' ')) then
            usage(src, name, { { name = 'id' }, { name = 'mensaje' } })
        end
    end, false)
end

registerPrivate('mp')
registerPrivate('pm')

RegisterCommand('r', function(src, args)
    if not reply(src, table.concat(args, ' ')) then
        usage(src, 'r', { { name = 'mensaje' } })
    end
end, false)

RegisterCommand('reporte', function(src, args)
    local text = clean(table.concat(args, ' '))
    if text == '' then return usage(src, 'reporte', { { name = 'mensaje' } }) end

    local now = os.time()
    if lastReport[src] and now - lastReport[src] < Config.ReportCooldown then
        return notify(src, 'Ya has enviado un reporte. Espera un poco antes de enviar otro')
    end

    local player = getSender(src, true)
    if not player then return end
    lastReport[src] = now

    local delivered = 0
    for _, id in ipairs(GetPlayers()) do
        local target = tonumber(id)
        if isStaff(target) then
            send(target, { channel = 'staff', tag = 'Reporte', author = player.getName(), id = src, text = text })
            delivered = delivered + 1
        end
    end
    print(('[jj_chat] [reporte] %s (%d): %s'):format(player.getName(), src, text))
    notify(src, delivered > 0 and 'Reporte enviado al staff' or 'Reporte guardado: ahora mismo no hay staff conectado')
end, false)

local function canModerate(src, target)
    if src ~= 0 and not isStaff(src) then
        notify(src, 'No tienes permiso para usar este comando')
        return false
    end
    if not target or not GetPlayerName(target) then
        notify(src, 'Ese jugador no está conectado')
        return false
    end
    if not JJ.IsAdmin(src) and JJ.IsAdmin(target) then
        notify(src, 'No puedes hacer esto a un administrador')
        return false
    end
    return true
end

RegisterCommand('silenciar', function(src, args)
    local target = tonumber(args[1])
    if not canModerate(src, target) then return end

    local minutes = math.floor(tonumber(args[2]) or Config.DefaultMuteMinutes)
    if minutes < 1 then return notify(src, 'Los minutos deben ser 1 o más') end

    local license = GetPlayerIdentifierByType(target, 'license')
    if not license then return notify(src, 'Ese jugador no tiene licencia') end
    muted[license] = os.time() + minutes * 60

    local reason = clean(table.concat(args, ' ', 3))
    notify(target, ('Te han silenciado %d min en el chat%s'):format(minutes, reason ~= '' and (': ' .. reason) or ''))
    notify(src, ('%s silenciado %d min'):format(getDisplayName(target), minutes))
    print(('[jj_chat] [silenciar] %d silencia a %d, %d min: %s'):format(src, target, minutes, reason))
end, false)

RegisterCommand('desilenciar', function(src, args)
    local target = tonumber(args[1])
    if not canModerate(src, target) then return end

    local license = GetPlayerIdentifierByType(target, 'license')
    if license then muted[license] = nil end
    notify(target, 'Ya puedes volver a escribir en el chat')
    notify(src, ('%s ya puede escribir'):format(getDisplayName(target)))
end, false)

-- Eventos

local SEND_CHANNELS = { say = true, ooc = true, job = true, staff = true }

RegisterNetEvent('jj_chat:server:send', function(channel, text)
    local src = source
    if channel == 'reply' then
        reply(src, text)
    elseif SEND_CHANNELS[channel] then
        speak(channel, src, text)
    end
end)

-- Un comando que no existe no se publica en el chat, como hace el de FiveM
RegisterNetEvent('__cfx_internal:commandFallback', function(command)
    local src = source
    if type(command) == 'string' then
        TriggerEvent('chatMessage', src, getDisplayName(src), '/' .. command)
        if not WasEventCanceled() then
            notify(src, ('El comando /%s no existe'):format(clean(command):match('^%S*')))
        end
    end
    CancelEvent()
end)

lib.callback.register('jj_chat:server:getAccess', function(source)
    local player = JJ.GetPlayer(source)
    local job = player and player.getJob()
    return {
        staff = isStaff(source),
        job = job and not Config.NoJobChannel[job.name] and job.label or false,
    }
end)

-- Sugerencias: todos los comandos que el jugador tiene permiso para usar

local function refreshCommands(src)
    local suggestions = {}
    for _, command in ipairs(GetRegisteredCommands()) do
        if IsPlayerAceAllowed(tostring(src), ('command.%s'):format(command.name)) and not command.name:find('^[%+%-_]') then
            suggestions[#suggestions + 1] = { name = '/' .. command.name, help = '' }
        end
    end
    TriggerClientEvent('chat:addSuggestions', src, suggestions)
end

RegisterNetEvent('jj_chat:server:ready', function()
    refreshCommands(source)
end)

AddEventHandler('onServerResourceStart', function()
    Wait(500)
    for _, id in ipairs(GetPlayers()) do
        refreshCommands(tonumber(id))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastSent[src] = nil
    lastReply[src] = nil
    lastReport[src] = nil
end)

-- Mismo export que el chat de FiveM, también bajo su nombre
local function addMessage(target, message)
    send(target, message)
end

exports('addMessage', addMessage)
AddEventHandler('__cfx_export_chat_addMessage', function(setCallback)
    setCallback(addMessage)
end)
