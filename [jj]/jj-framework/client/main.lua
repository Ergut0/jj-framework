local playerData = nil
local spawned = false

function JJ.GetPlayerData()
    return playerData
end

function JJ.IsLoaded()
    return playerData ~= nil
end

function JJ.IsSpawned()
    return spawned
end

-- Marca al jugador como aparecido. Con Config.Multicharacter lo llama jj_multicharacter
function JJ.SetSpawned()
    if spawned then
        return
    end
    spawned = true
    LocalPlayer.state:set('isLoggedIn', true, false)
    TriggerServerEvent('jj:server:clientSpawned')
    TriggerEvent('jj:client:playerSpawned')
end

function JJ.Notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('jj:client:notify', function(message)
    JJ.Notify(message)
end)

RegisterNetEvent('jj:client:playerLoaded', function(data)
    playerData = data
    if Config.Multicharacter then
        return
    end

    local position = data.position

    exports.spawnmanager:spawnPlayer({
        x = position.x + 0.0,
        y = position.y + 0.0,
        z = position.z + 0.0,
        heading = (position.heading or 0) + 0.0,
        model = GetHashKey(Config.DefaultModel),
        skipFade = false
    }, function()
        SetPedDefaultComponentVariation(PlayerPedId())
        JJ.SetSpawned()
    end)
end)

RegisterNetEvent('jj:client:playerDataUpdated', function(key, value)
    if playerData then
        playerData[key] = value
        TriggerEvent('jj:client:playerDataChanged', key, value)
    end
end)

local function respawnAfterDeath()
    local point = Config.Death.respawnPoint

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(50)
    end

    NetworkResurrectLocalPlayer(point.x + 0.0, point.y + 0.0, point.z + 0.0, point.heading + 0.0, true, false)
    ClearPedBloodDamage(PlayerPedId())
    ClearPlayerWantedLevel(PlayerId())

    DoScreenFadeIn(500)
    TriggerEvent('jj:client:playerRespawned')
end

CreateThread(function()
    while Config.Death.enabled do
        Wait(1000)
        if spawned and IsEntityDead(PlayerPedId()) then
            JJ.Notify(JJ.T('death_respawn', Config.Death.respawnTime))
            Wait(Config.Death.respawnTime * 1000)
            respawnAfterDeath()
        end
    end
end)

exports('GetCoreObject', function()
    return JJ
end)

-- Avisa al servidor cuando el cliente está listo. También se ejecuta al reiniciar el recurso.
CreateThread(function()
    exports.spawnmanager:setAutoSpawn(false)
    if Config.Multicharacter then
        return
    end
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    TriggerServerEvent('jj:server:playerReady')
end)
