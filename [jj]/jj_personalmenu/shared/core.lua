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

-- Antes de cargar el personaje devuelve datos vacíos, para que se pueda consultar en cualquier momento
function GetPlayerData()
    return JJ.GetPlayerData() or { job = {}, metadata = {}, accounts = {} }
end

-- Banda del jugador según jj_gangs. Sin ese recurso, nadie pertenece a una banda
function GetGang()
    if GetResourceState('jj_gangs') == 'started' then
        return exports.jj_gangs:getGang()
    end
    return nil
end
