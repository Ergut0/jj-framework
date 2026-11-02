local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local function Notify(source, message, type)
    TriggerClientEvent('ox_lib:notify', source, { description = message, type = type })
end

local function NormalizePlate(plate)
    if type(plate) ~= 'string' then return nil end
    local normalized = plate:gsub('%s+', ''):upper()
    return normalized ~= '' and normalized or nil
end

local function HasStaffPermission(source)
    return JJ.IsAdmin(source) or IsPlayerAceAllowed(tostring(source), Config.PermsCommand)
end

-- Quien trabaja en un punto de tuneo de jj_creatorjobs puede tunear vehículos ajenos
local function IsAtJobTuningPoint(source)
    if GetResourceState('jj_creatorjobs') ~= 'started' then return false end
    return exports.jj_creatorjobs:isAtTuningPoint(source) == true
end

-- Guarda el tuneo: lo puede hacer el dueño, un administrador o un mecánico en su punto
RegisterNetEvent('jj_tuneos:server:SaveVehicleProps', function(vehicleProps, rawPlate)
    local src = source
    local player = JJ.GetPlayer(src)
    local plate = NormalizePlate(rawPlate)
    if not player or not plate or type(vehicleProps) ~= 'table' then return end

    -- Un vehículo sin dueño no tiene dónde guardarse
    local owner = MySQL.scalar.await('SELECT owner FROM jj_vehicles WHERE plate = ?', { plate })
    if not owner then return end

    if owner ~= player.identifier and not HasStaffPermission(src) and not IsAtJobTuningPoint(src) then
        return
    end

    vehicleProps.plate = plate
    MySQL.update.await('UPDATE jj_vehicles SET props = ? WHERE plate = ?', { json.encode(vehicleProps), plate })
    Notify(src, 'Modificaciones del vehículo guardadas', 'success')
end)

-- Cobra las modificaciones. Solo sale dinero del propio jugador
RegisterNetEvent('jj_tuneos:server:ChargeMoney', function(amount)
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then return end

    if player.removeMoney('bank', amount, 'jj_tuneos') == true then
        Notify(src, ('Pagaste $%s por las modificaciones'):format(amount), 'success')
        TriggerClientEvent('jj_tuneos:client:UpdateCash', src)
    else
        Notify(src, 'No tienes suficiente dinero', 'error')
        TriggerClientEvent('jj_tuneos:client:RejectPayment', src)
    end
end)

RegisterCommand('tuneo', function(source)
    if source == 0 then return end

    if not HasStaffPermission(source) then
        Notify(source, 'No tienes permisos para usar este comando', 'error')
        return
    end

    TriggerClientEvent('jj_tuneos:client:OpenAdminMenu', source)
end, false)

RegisterNetEvent('jj_tuneos:server:CheckVehicleOwnership', function(rawPlate)
    local src = source
    local player = JJ.GetPlayer(src)
    local plate = NormalizePlate(rawPlate)
    if not player then return end

    local owner = plate and MySQL.scalar.await('SELECT owner FROM jj_vehicles WHERE plate = ?', { plate })
    TriggerClientEvent('jj_tuneos:client:VehicleOwned', src, owner == player.identifier)
end)

-- Export para otros recursos
exports('openTuningMenu', function(playerId)
    if playerId then
        TriggerClientEvent('jj_tuneos:client:OpenAdminMenu', playerId)
    end
end)
