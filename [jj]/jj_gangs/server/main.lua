JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

Gangs = {} -- [id] = { id, label, color, x, y, z, radius, points = { [id] = punto }, members = { [identifier] = { name, rank } } }
Members = {} -- [identifier] = id de la banda

local loaded = false -- Hasta terminar la carga, los clientes siguen pidiendo los datos

-- Helpers

function Notify(src, description, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = description, type = kind or 'inform' })
end

function GetColor(index)
    return Config.Colors[index] or Config.Colors[1]
end

-- Devuelve el jugador, su banda y su ficha de miembro, si tiene
function GetMember(src)
    local player = JJ.GetPlayer(src)
    if not player then return nil end
    local gang = Gangs[Members[player.identifier]]
    if not gang then return player end
    return player, gang, gang.members[player.identifier]
end

function HasPermission(rank, permission)
    local definition = Config.Ranks[rank]
    return definition ~= nil and (definition.isBoss == true or definition[permission] == true)
end

function GetOnlineMembers(gangId)
    local gang = Gangs[gangId]
    local online = {}
    if not gang then return online end
    for identifier in pairs(gang.members) do
        local player = JJ.GetPlayerByIdentifier(identifier)
        if player then
            online[#online + 1] = player.source
        end
    end
    return online
end

function GetPedCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped), ped
end

function IsNear(src, x, y, z, distance)
    local coords = GetPedCoords(src)
    return coords ~= nil and #(coords - vector3(x, y, z)) <= distance
end

-- Devuelve el punto de la banda si existe y el jugador está junto a él
function GetNearPoint(src, gang, pointId, pointType)
    local point = gang.points[tonumber(pointId)]
    if point and (not pointType or point.type == pointType)
        and IsNear(src, point.x, point.y, point.z, Config.ServerPointDistance) then
        return point
    end
end

function HasNearPoint(src, gang, pointType)
    for _, point in pairs(gang.points) do
        if point.type == pointType and IsNear(src, point.x, point.y, point.z, Config.ServerPointDistance) then
            return true
        end
    end
    return false
end

-- Devuelve la banda dueña del barrio en esas coordenadas. Si se solapan, el barrio más pequeño
function FindTerritory(coords)
    local found
    for _, gang in pairs(Gangs) do
        if gang.radius > 0 then
            local dx, dy = coords.x - gang.x, coords.y - gang.y
            if math.sqrt(dx * dx + dy * dy) <= gang.radius and (not found or gang.radius < found.radius) then
                found = gang
            end
        end
    end
    return found
end

-- Avisos con marca temporal en el mapa
function AlertGang(gangId, title, message, coords)
    for _, member in ipairs(GetOnlineMembers(gangId)) do
        TriggerClientEvent('jj_gangs:client:alert', member, { title = title, message = message, coords = { x = coords.x, y = coords.y, z = coords.z } })
    end
end

-- Sincronización con los clientes

local function getPublicGangs()
    local list = {}
    for _, gang in pairs(Gangs) do
        local color = GetColor(gang.color)
        list[#list + 1] = {
            id = gang.id, label = gang.label, blip = color.blip, hex = color.hex,
            x = gang.x, y = gang.y, z = gang.z, radius = gang.radius,
        }
    end
    return list
end

function SyncWorld(target)
    TriggerClientEvent('jj_gangs:client:world', target or -1, getPublicGangs(), loaded)
end

function RefreshPlayer(src)
    local _, gang, member = GetMember(src)
    Player(src).state:set('jjGang', gang and gang.id or nil, true)
    if not gang then
        TriggerClientEvent('jj_gangs:client:setGang', src, nil)
        return
    end

    local points = {}
    for _, point in pairs(gang.points) do
        points[#points + 1] = point
    end
    TriggerClientEvent('jj_gangs:client:setGang', src, {
        id = gang.id, label = gang.label, rank = member.rank, points = points,
    })
end

function RefreshGang(gangId)
    for _, src in ipairs(GetOnlineMembers(gangId)) do
        RefreshPlayer(src)
    end
end

-- Armarios: nadie tiene este grupo, así que solo se abren desde el servidor tras comprobar la banda
function RegisterPointStash(gang, point)
    exports.ox_inventory:RegisterStash(('jj_gang_stash_%d'):format(point.id), ('Armario: %s'):format(gang.label),
        Config.Stash.slots, Config.Stash.weight, false, { [('jj_gang_%d'):format(gang.id)] = 0 }, vector3(point.x, point.y, point.z))
end

-- Los garajes de banda los gestiona jj_garages
local function getGarageId(point)
    return ('gang_%d'):format(point.id)
end

-- Si jj_garages no está actualizado, las bandas tienen que seguir funcionando sin sus garajes
local function callGarages(method, ...)
    local args = { ... }
    local ok, reason = pcall(function()
        return exports.jj_garages[method](exports.jj_garages, table.unpack(args))
    end)
    if not ok then
        print(('[jj_gangs] No se puede usar jj_garages (%s): %s. Actualiza y reinicia jj_garages'):format(method, reason))
    end
    return ok
end

-- Comprueba si jj_garages tiene lo necesario antes de guardar nada
function AreGaragesAvailable()
    if GetResourceState('jj_garages') ~= 'started' then return false end
    return (pcall(function()
        return exports.jj_garages.registerGarage
    end))
end

function RegisterPointGarage(gang, point)
    return callGarages('registerGarage', getGarageId(point), {
        label = ('Garaje: %s'):format(gang.label),
        takeVehicle = vector3(point.x, point.y, point.z),
        spawnPoint = { vector4(point.x, point.y, point.z, point.h) },
        showBlip = false,
        type = 'gang',
        gang = gang.id,
    })
end

function RemovePointGarage(point)
    return callGarages('removeGarage', getGarageId(point))
end

function SetupPoint(gang, point)
    if point.type == 'stash' then
        RegisterPointStash(gang, point)
    elseif point.type == 'garage' then
        RegisterPointGarage(gang, point)
    end
end

local function registerAllGarages()
    for _, gang in pairs(Gangs) do
        for _, point in pairs(gang.points) do
            if point.type == 'garage' then
                RegisterPointGarage(gang, point)
            end
        end
    end
end

-- Base de datos

local function ensureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_gangs` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(40) NOT NULL,
            `color` TINYINT UNSIGNED NOT NULL DEFAULT 1,
            `x` FLOAT NOT NULL DEFAULT 0,
            `y` FLOAT NOT NULL DEFAULT 0,
            `z` FLOAT NOT NULL DEFAULT 0,
            `radius` FLOAT NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_jj_gangs_label` (`label`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_gang_members` (
            `identifier` VARCHAR(60) NOT NULL,
            `gang_id` INT UNSIGNED NOT NULL,
            `name` VARCHAR(64) NOT NULL,
            `rank` TINYINT UNSIGNED NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`),
            KEY `idx_jj_gang_members_gang` (`gang_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_gang_points` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `gang_id` INT UNSIGNED NOT NULL,
            `type` VARCHAR(12) NOT NULL,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `h` FLOAT NOT NULL DEFAULT 0,
            `lab` VARCHAR(20) NULL,
            PRIMARY KEY (`id`),
            KEY `idx_jj_gang_points_gang` (`gang_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_gang_graffitis` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `gang_id` INT UNSIGNED NOT NULL,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `nx` FLOAT NOT NULL,
            `ny` FLOAT NOT NULL,
            `nz` FLOAT NOT NULL,
            `url` VARCHAR(500) NULL,
            `author` VARCHAR(64) NULL,
            PRIMARY KEY (`id`),
            KEY `idx_jj_gang_graffitis_gang` (`gang_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Las tablas creadas antes de poder usar imágenes no tienen estas columnas
    local missing = { url = 'VARCHAR(500) NULL', author = 'VARCHAR(64) NULL' }
    for _, column in ipairs(MySQL.query.await('SHOW COLUMNS FROM `jj_gang_graffitis`') or {}) do
        missing[column.Field] = nil
    end
    for name, definition in pairs(missing) do
        MySQL.query.await(('ALTER TABLE `jj_gang_graffitis` ADD COLUMN `%s` %s'):format(name, definition))
    end
end

local function loadGangs()
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_gangs') or {}) do
        row.points, row.members = {}, {}
        Gangs[row.id] = row
    end
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_gang_members') or {}) do
        local gang = Gangs[row.gang_id]
        if gang then
            gang.members[row.identifier] = { name = row.name, rank = row.rank }
            Members[row.identifier] = gang.id
        end
    end
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_gang_points') or {}) do
        local gang = Gangs[row.gang_id]
        if gang then
            gang.points[row.id] = row
            -- Un punto defectuoso no puede dejar sin datos a todas las bandas
            local ok, reason = pcall(SetupPoint, gang, row)
            if not ok then
                print(('^1[jj_gangs] No se ha podido preparar el punto %d: %s^7'):format(row.id, reason))
            end
        end
    end
end

local function printLoadSummary()
    local gangs, members, points = 0, 0, 0
    for _, gang in pairs(Gangs) do
        gangs = gangs + 1
        for _ in pairs(gang.members) do members = members + 1 end
        for _ in pairs(gang.points) do points = points + 1 end
    end
    print(('[jj_gangs] Cargadas %d bandas, %d miembros y %d puntos'):format(gangs, members, points))
end

MySQL.ready(function()
    local ok, reason = pcall(function()
        ensureSchema()
        loadGangs()
        LoadGraffitis()
    end)
    if not ok then
        print(('^1[jj_gangs] Error al cargar los datos: %s^7'):format(reason))
    end

    -- Pase lo que pase, los clientes reciben lo que se haya podido cargar
    loaded = true
    printLoadSummary()
    SyncWorld()
    SyncGraffitis(-1)
    for _, src in pairs(JJ.GetPlayers()) do
        RefreshPlayer(src)
    end
end)

-- Eventos

RegisterNetEvent('jj_gangs:server:ready', function()
    local src = source
    SyncWorld(src)
    SyncGraffitis(src)
    RefreshPlayer(src)
end)

AddEventHandler('jj:server:playerLoaded', function(src)
    RefreshPlayer(src)
end)

-- Al reiniciar jj_garages pierde los garajes registrados
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj_garages' then
        registerAllGarages()
    end
end)

-- Exports

exports('isMember', function(src, gangId)
    local _, gang = GetMember(src)
    return gang ~= nil and gang.id == gangId
end)

-- Todas las bandas con su color: { id, label, blip, hex }. Lo usa jj_flags
exports('getGangs', function()
    return getPublicGangs()
end)

exports('getGang', function(src)
    local _, gang, member = GetMember(src)
    if not gang then return nil end
    return { id = gang.id, label = gang.label, rank = member.rank }
end)
