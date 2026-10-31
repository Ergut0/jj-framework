local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local function getAuthor(src)
    if src == 0 then return 'Consola' end
    local player = JJ.GetPlayer(src)
    return player and player.getName() or GetPlayerName(src)
end

local function send(kind, message, author)
    local t = Config.Types[kind]
    if not t then return false end
    message = tostring(message or ''):match('^%s*(.-)%s*$'):sub(1, Config.MaxLength)
    if message == '' then return false end
    TriggerClientEvent('jj_announce:show', -1, {
        kind = kind, title = t.title, color = t.color, message = message,
        author = author or 'Staff', duration = Config.Duration,
    })
    return true
end

-- EXPORT: exports.jj_announce:Announce('evento', 'Carrera en el aeropuerto', 'Staff')
exports('Announce', send)

for kind, t in pairs(Config.Types) do
    RegisterCommand(t.command, function(src, args)
        if not JJ.IsAdmin(src) then
            TriggerClientEvent('chat:addMessage', src, { args = { '^1Anuncios', 'No tienes permiso para usar este comando.' } })
            return
        end
        local msg = table.concat(args, ' ')
        local author = getAuthor(src)
        if not send(kind, msg, author) then
            local reply = ('Uso: /%s <mensaje>'):format(t.command)
            if src == 0 then print(reply) else TriggerClientEvent('chat:addMessage', src, { args = { '^3Anuncios', reply } }) end
            return
        end
        print(('[jj_announce] %s envio un %s: %s'):format(author, kind, msg))
    end, false)
end
