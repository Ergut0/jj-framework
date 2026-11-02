-- Rastreadores que ve la policía. Estos mensajes solo los envía el servidor a policías de servicio
local trackers = {}
local watching = false

local function removeTracker(uid)
    local tracker = trackers[uid]
    if not tracker then return end
    RemoveBlip(tracker.blip)
    trackers[uid] = nil
end

-- Quita los que dejan de actualizarse, por ejemplo al salir de servicio
local function watchTrackers()
    if watching then return end
    watching = true

    CreateThread(function()
        while next(trackers) do
            Wait(5000)
            local now = GetGameTimer()
            for uid, tracker in pairs(trackers) do
                if now > tracker.expiresAt then removeTracker(uid) end
            end
        end
        watching = false
    end)
end

RegisterNetEvent('jj_boosting:client:trackerPulse', function(data)
    local tracker = trackers[data.uid]
    if not tracker then
        local blip = AddBlipForCoord(data.x, data.y, data.z)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Rastreador: %s (%s)'):format(data.model, data.plate))
        EndTextCommandSetBlipName(blip)
        tracker = { blip = blip }
        trackers[data.uid] = tracker
        watchTrackers()
    else
        SetBlipCoords(tracker.blip, data.x, data.y, data.z)
    end
    tracker.expiresAt = GetGameTimer() + data.ttl * 1000
end)

RegisterNetEvent('jj_boosting:client:trackerStop', removeTracker)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for uid in pairs(trackers) do removeTracker(uid) end
end)
