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

function HelpNotify(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- av_gangs es opcional: sin él, nadie pertenece a una banda
function GetGang()
    if GetResourceState('av_gangs') == 'started' then
        return exports.av_gangs:getGang()
    end
    return nil
end

-- Matrícula del vehículo, sin los espacios con los que la rellena el juego
function GetPlate(vehicle)
    return (GetVehicleNumberPlateText(vehicle):gsub('^%s*(.-)%s*$', '%1'))
end

-- Devuelve el jugador más cercano y su distancia, o -1 y -1 si no hay nadie
function GetClosestPlayerToMe()
    local coords = GetEntityCoords(cache.ped)
    local playerId, _, playerCoords = lib.getClosestPlayer(coords, 10.0, false)
    if not playerId then
        return -1, -1
    end
    return playerId, #(coords - playerCoords)
end

function SpawnVehicle(model, cb, coords)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        Notify('El vehículo no está instalado', 'error')
        return
    end
    lib.requestModel(hash)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), true, true)
    SetModelAsNoLongerNeeded(hash)
    cb(vehicle)
end
