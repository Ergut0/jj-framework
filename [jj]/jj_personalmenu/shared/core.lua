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

-- av_gangs es opcional: sin él, nadie pertenece a una banda
function GetGang()
    if GetResourceState('av_gangs') == 'started' then
        return exports.av_gangs:getGang()
    end
    return nil
end
