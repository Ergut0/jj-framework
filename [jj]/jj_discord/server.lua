-- El cliente solo ve a los jugadores cercanos, así que el total lo publica el servidor

GlobalState.jjMaxPlayers = GetConvarInt('sv_maxclients', 48)

CreateThread(function()
    while true do
        GlobalState.jjPlayerCount = GetNumPlayerIndices()
        Wait(Config.Interval * 1000)
    end
end)
