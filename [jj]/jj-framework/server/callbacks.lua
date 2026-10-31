local callbacks = {}

-- handler(source, cb, ...): llama a cb con los valores que recibirá el cliente
function JJ.RegisterCallback(name, handler)
    callbacks[name] = handler
end

RegisterNetEvent('jj:server:callback', function(name, requestId, ...)
    local src = source
    if type(name) ~= 'string' or type(requestId) ~= 'number' then
        return
    end

    local handler = callbacks[name]
    if not handler then
        print(('[jj-framework] Callback desconocido "%s" solicitado por %s'):format(name, src))
        TriggerClientEvent('jj:client:callbackResponse', src, requestId)
        return
    end

    handler(src, function(...)
        TriggerClientEvent('jj:client:callbackResponse', src, requestId, ...)
    end, ...)
end)

JJ.RegisterCallback('jj:getPlayerData', function(src, cb)
    local player = JJ.GetPlayer(src)
    cb(player and player.getData() or nil)
end)
