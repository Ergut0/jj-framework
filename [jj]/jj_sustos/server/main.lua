-- Comandos solo para administradores. El permiso se comprueba siempre aquí

local function reply(source, message, kind)
    if source == 0 then
        print(('[jj_sustos] %s'):format(message))
    else
        JJ.Notify(source, message, kind or 'inform')
    end
end

-- Sin id, el objetivo es el propio administrador, para probarlo
local function getTarget(source, arg)
    local target = source
    if arg then
        target = tonumber(arg)
        target = target and math.tointeger(target)
    end
    if target and target ~= 0 and JJ.GetPlayer(target) then return target end
    return nil
end

local function getSeconds(arg)
    local seconds = math.floor(tonumber(arg) or Config.DefaultSeconds)
    return math.max(1, math.min(Config.MaxSeconds, seconds))
end

local function register(name, usage, run)
    RegisterCommand(name, function(source, args)
        if not JJ.IsAdmin(source) then
            reply(source, 'No tienes permiso para usar este comando', 'error')
            return
        end

        local target = getTarget(source, args[1])
        if not target then
            reply(source, ('Ese jugador no está conectado. Uso: /%s %s'):format(name, usage), 'error')
            return
        end

        run(target, args)
        print(('[jj_sustos] %s ha usado /%s sobre %s'):format(source == 0 and 'Consola' or GetPlayerName(source), name, GetPlayerName(target)))
        reply(source, ('/%s aplicado a %d'):format(name, target), 'success')
    end, false)
end

register('susto', '[id] [segundos]', function(target, args)
    TriggerClientEvent('jj_sustos:client:start', target, 'screamer', getSeconds(args[2]))
end)

register('sustofoto', '[id] [segundos]', function(target, args)
    TriggerClientEvent('jj_sustos:client:start', target, 'photo', getSeconds(args[2]))
end)

register('sustostop', '[id]', function(target)
    TriggerClientEvent('jj_sustos:client:stop', target)
end)

register('sustocoche', '[id]', function(target)
    TriggerClientEvent('jj_sustos:client:leaveVehicle', target)
end)

register('sustoexplosion', '[id]', function(target)
    TriggerClientEvent('jj_sustos:client:explosion', target)
end)
