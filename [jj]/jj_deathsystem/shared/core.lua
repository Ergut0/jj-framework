JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

if IsDuplicityVersion() then return end

function Notify(description, type)
    lib.notify({ description = description, type = type or 'inform' })
end

-- Ejecuta callback cuando el jugador ha aparecido, también si ya lo había hecho al iniciar el recurso
function OnPlayerReady(callback)
    AddEventHandler('jj:client:playerSpawned', callback)
    if JJ.IsSpawned() then
        CreateThread(callback)
    end
end
