local loading = {}

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license')
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update(JJ.T('connecting'))
    Wait(0)

    local identifier = getLicense(src)
    if not identifier then
        deferrals.done(JJ.T('no_license'))
        return
    end
    if JJ.GetPlayerByLicense(identifier) then
        deferrals.done(JJ.T('already_connected'))
        return
    end
    deferrals.done()
end)

-- Carga un personaje en el jugador. fetchRow lee sus datos y devuelve nil si no se puede usar
local function loadPlayer(src, license, identifier, fetchRow)
    if JJ.GetPlayer(src) or loading[license] then
        return false
    end
    if JJ.GetPlayerByLicense(license) then
        DropPlayer(src, JJ.T('already_connected'))
        return false
    end

    loading[license] = true
    local ok, row = pcall(fetchRow)
    loading[license] = nil

    if not ok then
        print(('[jj-framework] Error al cargar a %s: %s'):format(identifier, row))
        DropPlayer(src, JJ.T('load_failed'))
        return false
    end

    -- El jugador pudo desconectarse mientras se consultaba la base de datos
    if not row or not GetPlayerName(src) then
        return false
    end

    local player = JJInternal.CreatePlayer(src, identifier, row)
    JJInternal.AddPlayer(player)
    TriggerClientEvent('jj:client:playerLoaded', src, player.getData())
    TriggerEvent('jj:server:playerLoaded', src)
    return true
end

RegisterNetEvent('jj:server:playerReady', function()
    local src = source
    if Config.Multicharacter then
        return
    end

    local license = getLicense(src)
    if not license then
        DropPlayer(src, JJ.T('no_license'))
        return
    end

    loadPlayer(src, license, license, function()
        return JJInternal.FetchPlayerRow(license, GetPlayerName(src))
    end)
end)

-- Personajes de la licencia del jugador. No hace falta que tenga uno cargado
function JJ.GetCharacters(src)
    local license = getLicense(src)
    return license and JJInternal.FetchCharacters(license) or {}
end

-- Crea un personaje. Devuelve su identificador, o nil si no se ha podido
function JJ.CreateCharacter(src, name, charinfo)
    local license = getLicense(src)
    return license and JJInternal.InsertCharacter(license, name, charinfo) or nil
end

-- Carga un personaje, solo si pertenece a la licencia del jugador
function JJ.LoadCharacter(src, identifier)
    local license = getLicense(src)
    if not license or type(identifier) ~= 'string' then
        return false
    end

    return loadPlayer(src, license, identifier, function()
        local row = JJInternal.FetchCharacter(identifier)
        return row and row.license == license and row or nil
    end)
end

RegisterNetEvent('jj:server:clientSpawned', function()
    local src = source
    local player = JJ.GetPlayer(src)
    if not player or player.isSpawned() then
        return
    end
    player.setSpawned()
    TriggerEvent('jj:server:playerSpawned', src)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then
        return
    end
    player.updatePosition()
    -- Antes de guardar, para que los cambios hechos por otros recursos en este evento no se pierdan
    TriggerEvent('jj:server:playerDropped', src, reason)
    JJInternal.SavePlayer(player)
    JJInternal.RemovePlayer(src)
end)

local function saveAll()
    local count = 0
    for _, player in JJInternal.EachPlayer() do
        player.updatePosition()
        JJInternal.SavePlayer(player)
        count = count + 1
    end
    return count
end

JJInternal.SaveAll = saveAll

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        saveAll()
    end
end)

CreateThread(function()
    while true do
        Wait(Config.PositionInterval * 1000)
        for _, player in JJInternal.EachPlayer() do
            player.updatePosition()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.AutosaveInterval * 1000)
        saveAll()
    end
end)

CreateThread(function()
    while true do
        Wait(Config.PaycheckInterval * 1000)
        for src, player in JJInternal.EachPlayer() do
            local salary = player.getJob().salary
            if player.isSpawned() and salary > 0 and player.addMoney(Config.PaycheckAccount, salary, 'paycheck') then
                JJ.Notify(src, JJ.T('paycheck', salary), 'success')
            end
        end
    end
end)

exports('GetCoreObject', function()
    return JJ
end)
