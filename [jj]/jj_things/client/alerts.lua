local ALERT_BLIP_TIME = 60000

RegisterNetEvent('jj_things:client:alert', function(data)
    Notify(data.title .. ': ' .. data.message, 'inform', 10000)

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    SetTimeout(ALERT_BLIP_TIME, function()
        RemoveBlip(blip)
    end)
end)
