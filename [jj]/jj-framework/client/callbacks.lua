local pending = {}
local nextRequestId = 0

-- cb recibe los valores enviados por el servidor, o nada si se agota el tiempo de espera
function JJ.TriggerCallback(name, cb, ...)
    nextRequestId = nextRequestId + 1
    local requestId = nextRequestId
    pending[requestId] = cb
    TriggerServerEvent('jj:server:callback', name, requestId, ...)

    SetTimeout(Config.CallbackTimeout, function()
        local callback = pending[requestId]
        if callback then
            pending[requestId] = nil
            print(('[jj-framework] Callback "%s" sin respuesta'):format(name))
            callback()
        end
    end)
end

function JJ.AwaitCallback(name, ...)
    local p = promise.new()
    JJ.TriggerCallback(name, function(...)
        p:resolve(table.pack(...))
    end, ...)
    local result = Citizen.Await(p)
    return table.unpack(result, 1, result.n)
end

RegisterNetEvent('jj:client:callbackResponse', function(requestId, ...)
    local callback = pending[requestId]
    if callback then
        pending[requestId] = nil
        callback(...)
    end
end)
