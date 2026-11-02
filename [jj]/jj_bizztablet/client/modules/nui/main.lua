function SendNui(event, data)
    SendNUIMessage({
        type = event,
        data = data
    })
end

function NuiOn(event, callback)
    RegisterNUICallback(event, function(data, cb)
        local result = callback(data)
        if result == nil then
            cb('ok')
        else
            cb(result)
        end
    end)
end
