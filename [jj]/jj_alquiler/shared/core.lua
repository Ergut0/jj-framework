JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

if IsDuplicityVersion() then return end

function Notify(description, type, duration)
    lib.notify({ description = description, type = type or 'inform', duration = duration })
end

-- Ejecuta callback cada vez que el jugador aparece, y también si ya lo había hecho al iniciar el recurso
function OnPlayerReady(callback)
    AddEventHandler('jj:client:playerSpawned', callback)
    if JJ.IsSpawned() then
        CreateThread(callback)
    end
end

-- Crea el vehículo y mete al jugador en el asiento del conductor. Devuelve nil si no se ha podido
function SpawnVehicle(model, cb, coords)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        Notify('El vehículo no está instalado', 'error')
        return nil
    end
    lib.requestModel(hash)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or GetEntityHeading(cache.ped), true, true)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    if cb then
        cb(vehicle)
    end
    return vehicle
end
