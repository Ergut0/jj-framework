local LEVELS = { none = 0, mod = 1, admin = 2 }
local MAX_REASON = 200
local MAX_ITEM_COUNT = 10000
local MAX_LOG_DETAILS = 300

local actions = {}
local frozen = {}
local spectating = {}
local playerViewers = {}
local activeBans = 0

-- Permisos

local function getLevel(src)
    if src == 0 or IsPlayerAceAllowed(tostring(src), Config.AdminAce) then return 'admin' end
    if IsPlayerAceAllowed(tostring(src), Config.ModAce) then return 'mod' end
    return 'none'
end

local function canUse(src, action)
    local required = Config.Actions[action]
    return required ~= nil and LEVELS[getLevel(src)] >= LEVELS[required]
end

-- Un moderador no puede actuar sobre un administrador
local function isProtected(src, target)
    return LEVELS[getLevel(target)] > LEVELS[getLevel(src)]
end

local function getAllowedActions(src)
    local allowed = {}
    for action in pairs(Config.Actions) do
        if canUse(src, action) then
            allowed[#allowed + 1] = action
        end
    end
    return allowed
end

-- Base de datos

local function refreshBanCount()
    activeBans = MySQL.scalar.await('SELECT COUNT(*) FROM jj_bans WHERE expires_at IS NULL OR expires_at > ?', { os.time() }) or 0
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_bans` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `license` VARCHAR(60) NOT NULL,
            `discord` VARCHAR(60) NULL,
            `name` VARCHAR(64) NOT NULL,
            `reason` VARCHAR(255) NOT NULL,
            `admin` VARCHAR(64) NOT NULL,
            `created_at` INT UNSIGNED NOT NULL,
            `expires_at` INT UNSIGNED NULL,
            PRIMARY KEY (`id`),
            KEY `idx_jj_bans_license` (`license`),
            KEY `idx_jj_bans_discord` (`discord`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_admin_logs` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `admin` VARCHAR(64) NOT NULL,
            `license` VARCHAR(60) NULL,
            `action` VARCHAR(32) NOT NULL,
            `target` VARCHAR(64) NULL,
            `details` VARCHAR(300) NULL,
            `created_at` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_jj_admin_logs_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.update.await('DELETE FROM jj_bans WHERE expires_at IS NOT NULL AND expires_at <= ?', { os.time() })
    refreshBanCount()
end)

local function getDisplayName(src)
    if src == 0 then return 'Consola' end
    local player = JJ.GetPlayer(src)
    return player and player.getName() or GetPlayerName(src) or ('ID ' .. src)
end

local function log(src, action, target, details)
    local admin = getDisplayName(src)
    print(('[jj_admin] %s -> %s %s %s'):format(admin, action, target or '-', details or ''))
    MySQL.insert('INSERT INTO jj_admin_logs (admin, license, action, target, details, created_at) VALUES (?, ?, ?, ?, ?, ?)', {
        admin,
        src ~= 0 and GetPlayerIdentifierByType(src, 'license') or nil,
        action,
        target,
        details and details:sub(1, MAX_LOG_DETAILS) or nil,
        os.time(),
    })
end

-- Baneos: se comprueban al conectarse

local function formatBanMessage(reason, admin, expiresAt)
    local duration = expiresAt and os.date('%d/%m/%Y %H:%M', expiresAt) or 'permanente'
    return ('Estás baneado.\nMotivo: %s\nPor: %s\nHasta: %s'):format(reason, admin, duration)
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    deferrals.update('Comprobando baneos...')

    local license = GetPlayerIdentifierByType(src, 'license')
    local discord = GetPlayerIdentifierByType(src, 'discord')
    if not license then
        deferrals.done()
        return
    end

    local ok, ban = pcall(MySQL.single.await,
        'SELECT reason, admin, expires_at FROM jj_bans WHERE (license = ? OR discord = ?) AND (expires_at IS NULL OR expires_at > ?) LIMIT 1',
        { license, discord or '', os.time() })

    if ok and ban then
        deferrals.done(formatBanMessage(ban.reason, ban.admin, ban.expires_at))
    else
        deferrals.done()
    end
end)

local function addBan(license, discord, name, reason, adminName, hours)
    local now = os.time()
    local expiresAt = hours and now + hours * 3600 or nil
    MySQL.insert.await('INSERT INTO jj_bans (license, discord, name, reason, admin, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        license, discord, name, reason, adminName, now, expiresAt,
    })
    refreshBanCount()
    return expiresAt
end

-- Helpers de las acciones

local function ok(message, extra)
    local result = extra or {}
    result.ok = true
    result.message = message
    return result
end

local function fail(message)
    return { ok = false, message = message }
end

local function getTarget(payload)
    local target = type(payload) == 'table' and tonumber(payload.target)
    if target and GetPlayerName(target) then
        return target
    end
    return nil
end

local function getCoordsOf(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function cleanReason(payload, default)
    local reason = type(payload.reason) == 'string' and payload.reason:match('^%s*(.-)%s*$') or ''
    return reason ~= '' and reason:sub(1, MAX_REASON) or default
end

local function getBanHours(payload)
    local hours = tonumber(payload.hours)
    return hours and hours > 0 and hours or nil
end

local function runClient(src, name, ...)
    TriggerClientEvent('jj_admin:client:run', src, name, ...)
end

local function isVehicleEmpty(vehicle)
    for seat = -1, 6 do
        if GetPedInVehicleSeat(vehicle, seat) ~= 0 then
            return false
        end
    end
    return true
end

-- Registra una acción. protectTarget impide usarla sobre alguien con más nivel
local function register(name, handler, protectTarget, needsTarget)
    actions[name] = { handler = handler, protectTarget = protectTarget, needsTarget = needsTarget ~= false and protectTarget ~= nil }
end

-- Acciones sobre jugadores

register('goto', function(src, payload, target)
    local coords = getCoordsOf(target)
    if not coords then return fail('El jugador no tiene personaje en el mundo') end
    SetPlayerRoutingBucket(src, GetPlayerRoutingBucket(target))
    SetEntityCoords(GetPlayerPed(src), coords.x + 1.0, coords.y, coords.z, false, false, false, false)
    return ok('Te has teletransportado'), GetPlayerName(target)
end, false)

register('bring', function(src, payload, target)
    local coords = getCoordsOf(src)
    local targetPed = GetPlayerPed(target)
    if not coords or not targetPed or targetPed == 0 then return fail('El jugador no tiene personaje en el mundo') end
    SetPlayerRoutingBucket(target, GetPlayerRoutingBucket(src))
    SetEntityCoords(targetPed, coords.x + 1.0, coords.y, coords.z, false, false, false, false)
    return ok('Has traído al jugador'), GetPlayerName(target)
end, true)

register('spectate', function(src, payload, target)
    if target == src then return fail('No puedes espectarte a ti mismo') end
    local coords = getCoordsOf(target)
    if not coords then return fail('El jugador no tiene personaje en el mundo') end
    spectating[src] = spectating[src] or { bucket = GetPlayerRoutingBucket(src) }
    spectating[src].target = target
    SetPlayerRoutingBucket(src, GetPlayerRoutingBucket(target))
    runClient(src, 'spectate', target, { x = coords.x, y = coords.y, z = coords.z }, getDisplayName(target))
    return ok('Espectando. Pulsa E para salir', { close = true }), GetPlayerName(target)
end, true)

register('freeze', function(src, payload, target)
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then return fail('El jugador no tiene personaje en el mundo') end
    frozen[target] = not frozen[target] or nil
    FreezeEntityPosition(ped, frozen[target] == true)
    return ok(frozen[target] and 'Jugador congelado' or 'Jugador descongelado'), GetPlayerName(target), frozen[target] and 'congelar' or 'descongelar'
end, true)

register('revive', function(src, payload, target)
    if GetResourceState('jj_deathsystem') ~= 'started' then return fail('jj_deathsystem no está arrancado') end
    if not exports.jj_deathsystem:revive(target) then return fail('El jugador no ha cargado un personaje') end
    return ok('Jugador reanimado'), GetPlayerName(target)
end, false)

register('heal', function(src, payload, target)
    TriggerClientEvent('jj_admin:client:heal', target)
    return ok('Jugador curado'), GetPlayerName(target)
end, false)

register('kill', function(src, payload, target)
    TriggerClientEvent('jj_admin:client:kill', target)
    return ok('Jugador eliminado'), GetPlayerName(target)
end, true)

register('kick', function(src, payload, target)
    if target == src then return fail('No puedes expulsarte a ti mismo') end
    local reason = cleanReason(payload, 'Sin motivo')
    local name = GetPlayerName(target)
    DropPlayer(target, ('Has sido expulsado por %s.\nMotivo: %s'):format(getDisplayName(src), reason))
    return ok('Jugador expulsado'), name, reason
end, true)

register('ban', function(src, payload, target)
    if target == src then return fail('No puedes banearte a ti mismo') end
    local license = GetPlayerIdentifierByType(target, 'license')
    if not license then return fail('El jugador no tiene licencia') end

    local reason = cleanReason(payload, 'Sin motivo')
    local hours = getBanHours(payload)
    local name = GetPlayerName(target)
    local adminName = getDisplayName(src)
    local expiresAt = addBan(license, GetPlayerIdentifierByType(target, 'discord'), name, reason, adminName, hours)
    DropPlayer(target, formatBanMessage(reason, adminName, expiresAt))
    return ok('Jugador baneado'), name, ('%s (%s)'):format(reason, hours and hours .. ' h' or 'permanente')
end, true)

register('viewInventory', function(src, payload, target)
    if GetResourceState('ox_inventory') ~= 'started' then return fail('ox_inventory no está arrancado') end
    if not JJ.GetPlayer(target) then return fail('El jugador no ha cargado un personaje') end
    exports.ox_inventory:forceOpenInventory(src, 'player', target)
    return ok('Inventario abierto', { close = true }), GetPlayerName(target)
end, false)

register('money', function(src, payload, target)
    local player = JJ.GetPlayer(target)
    if not player then return fail('El jugador no ha cargado un personaje') end
    if not JJ.Config.Accounts[payload.account] then return fail('La cuenta no existe') end

    local methods = { add = player.addMoney, remove = player.removeMoney, set = player.setMoney }
    local method = methods[payload.mode]
    if not method then return fail('Operación no válida') end
    if not method(payload.account, payload.amount, 'jj_admin') then
        return fail('No se ha podido cambiar el dinero: revisa la cantidad y el saldo')
    end
    return ok('Dinero actualizado'), player.getName(), ('%s %s %s'):format(payload.mode, payload.account, tostring(payload.amount))
end, false)

register('setJob', function(src, payload, target)
    local player = JJ.GetPlayer(target)
    if not player then return fail('El jugador no ha cargado un personaje') end
    if not player.setJob(payload.job, payload.grade) then return fail('El trabajo o el grado no existen') end
    return ok('Trabajo actualizado'), player.getName(), ('%s %s'):format(tostring(payload.job), tostring(payload.grade))
end, false)

register('setDuty', function(src, payload, target)
    local player = JJ.GetPlayer(target)
    if not player then return fail('El jugador no ha cargado un personaje') end
    local onDuty = not player.getJob().onDuty
    player.setDuty(onDuty)
    return ok(onDuty and 'Ahora está de servicio' or 'Ahora está fuera de servicio'), player.getName()
end, false)

register('giveItem', function(src, payload, target)
    if not JJ.GetPlayer(target) then return fail('El jugador no ha cargado un personaje') end
    local count = math.floor(tonumber(payload.count) or 0)
    if type(payload.item) ~= 'string' or count < 1 or count > MAX_ITEM_COUNT then return fail('Objeto o cantidad no válidos') end
    if not exports.ox_inventory:Items(payload.item) then return fail('El objeto no existe') end
    local success, response = exports.ox_inventory:AddItem(target, payload.item, count)
    if not success then return fail(('No se ha podido dar el objeto: %s'):format(tostring(response))) end
    return ok('Objeto entregado'), getDisplayName(target), ('%s x%d'):format(payload.item, count)
end, false)

register('clearInventory', function(src, payload, target)
    if not JJ.GetPlayer(target) then return fail('El jugador no ha cargado un personaje') end
    -- El efectivo es un objeto: se conserva para no vaciar la cuenta
    exports.ox_inventory:ClearInventory(target, 'money')
    return ok('Inventario vaciado'), getDisplayName(target)
end, true)

register('giveVehicle', function(src, payload, target)
    local player = JJ.GetPlayer(target)
    if not player then return fail('El jugador no ha cargado un personaje') end
    if GetResourceState('jj_garages') ~= 'started' then return fail('jj_garages no está arrancado') end
    local plate = exports.jj_garages:addVehicle(player.identifier, payload.model)
    if not plate then return fail('Modelo de vehículo no válido') end
    return ok(('Vehículo entregado con matrícula %s'):format(plate)), player.getName(), ('%s %s'):format(payload.model, plate)
end, false)

-- Mis herramientas

for _, name in ipairs({ 'noclip', 'god', 'invisible', 'tpWaypoint', 'vehicleRepair', 'vehicleFlip', 'vehicleDelete' }) do
    actions[name] = { handler = function(src)
        runClient(src, name)
        return ok(nil)
    end }
end

actions.tpCoords = { handler = function(src, payload)
    local x, y, z = tonumber(payload.x), tonumber(payload.y), tonumber(payload.z)
    if not x or not y or not z then return fail('Coordenadas no válidas') end
    runClient(src, 'tpCoords', { x = x + 0.0, y = y + 0.0, z = z + 0.0 })
    return ok('Te has teletransportado', { close = true }), nil, ('%.1f %.1f %.1f'):format(x, y, z)
end }

actions.players = { handler = function(src)
    playerViewers[src] = not playerViewers[src] or nil
    runClient(src, playerViewers[src] and 'playersOn' or 'playersOff')
    return ok(nil)
end }

actions.spawnVehicle = { handler = function(src, payload)
    if type(payload.model) ~= 'string' or not payload.model:match('^[%w_]+$') then return fail('Modelo de vehículo no válido') end
    runClient(src, 'spawnVehicle', payload.model)
    return ok(nil), nil, payload.model
end }

actions.clearVehicles = { handler = function(src, payload)
    local radius = tonumber(payload.radius)
    local coords = radius and getCoordsOf(src)
    local count = 0
    for _, vehicle in ipairs(GetAllVehicles()) do
        if isVehicleEmpty(vehicle) and (not coords or #(GetEntityCoords(vehicle) - coords) <= radius) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    return ok(('Vehículos eliminados: %d'):format(count)), nil, radius and ('radio %s'):format(radius) or 'todo el mapa'
end }

-- Servidor

actions.announce = { handler = function(src, payload)
    if GetResourceState('jj_announce') ~= 'started' then return fail('jj_announce no está arrancado') end
    if not exports.jj_announce:Announce(payload.kind, payload.message, getDisplayName(src)) then
        return fail('Escribe un mensaje y elige un tipo válido')
    end
    return ok('Anuncio enviado'), nil, tostring(payload.message)
end }

actions.weather = { handler = function(src, payload)
    local weather = payload.weather
    if weather ~= false then
        local valid = false
        for _, option in ipairs(Config.Weather) do
            if option.value == weather then valid = true end
        end
        if not valid then return fail('Clima no válido') end
    end
    GlobalState.jjWeather = weather or nil
    return ok(weather and 'Clima cambiado' or 'Clima automático'), nil, tostring(weather or 'automático')
end }

actions.time = { handler = function(src, payload)
    if payload.hour == false then
        GlobalState.jjTime = nil
        return ok('Hora automática'), nil, 'automática'
    end
    local hour, minute = tonumber(payload.hour), tonumber(payload.minute) or 0
    if not hour or hour < 0 or hour > 23 or minute < 0 or minute > 59 then return fail('Hora no válida') end
    GlobalState.jjTime = { hour = math.floor(hour), minute = math.floor(minute) }
    return ok('Hora cambiada'), nil, ('%02d:%02d'):format(hour, minute)
end }

actions.saveAll = { handler = function()
    ExecuteCommand('saveall')
    return ok('Jugadores guardados')
end }

actions.banOffline = { handler = function(src, payload)
    local license = type(payload.license) == 'string' and payload.license:match('^%s*(license:%x+)%s*$')
    if not license then return fail('La licencia debe tener el formato license:xxxxxxxx') end
    local name = type(payload.name) == 'string' and payload.name ~= '' and payload.name:sub(1, 64) or 'Desconectado'
    local reason = cleanReason(payload, 'Sin motivo')
    local hours = getBanHours(payload)
    local adminName = getDisplayName(src)
    local expiresAt = addBan(license, nil, name, reason, adminName, hours)

    local online = JJ.GetPlayerByLicense(license)
    if online then
        DropPlayer(online.source, formatBanMessage(reason, adminName, expiresAt))
    end
    return ok('Licencia baneada'), name, ('%s: %s'):format(license, reason)
end }

actions.unban = { handler = function(src, payload)
    local id = tonumber(payload.id)
    local ban = id and MySQL.single.await('SELECT name FROM jj_bans WHERE id = ?', { id })
    if not ban then return fail('El baneo no existe') end
    MySQL.update.await('DELETE FROM jj_bans WHERE id = ?', { id })
    refreshBanCount()
    return ok('Baneo eliminado'), ban.name
end }

-- Llamadas de la interfaz

lib.callback.register('jj_admin:server:canOpen', function(source)
    return getLevel(source) ~= 'none'
end)

lib.callback.register('jj_admin:server:action', function(source, name, payload)
    local action = type(name) == 'string' and actions[name]
    if not action or not canUse(source, name) then
        return fail('No tienes permiso para esta acción')
    end
    payload = type(payload) == 'table' and payload or {}

    local target
    if action.needsTarget then
        target = getTarget(payload)
        if not target then return fail('El jugador no está conectado') end
        if action.protectTarget and isProtected(source, target) then
            return fail('No puedes hacer esto a alguien con más permisos')
        end
    end

    local result, targetName, details = action.handler(source, payload, target)
    if result.ok then
        log(source, name, targetName, details)
    end
    return result
end)

lib.callback.register('jj_admin:server:getData', function(source)
    local level = getLevel(source)
    if level == 'none' then return nil end

    local players, onDuty = {}, { police = 0, ambulance = 0 }
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local player = JJ.GetPlayer(src)
        local ped = GetPlayerPed(src)
        local info = {
            id = src,
            fivemName = GetPlayerName(src),
            name = GetPlayerName(src),
            ping = GetPlayerPing(src),
            license = GetPlayerIdentifierByType(src, 'license'),
            loaded = player ~= nil,
            frozen = frozen[src] == true,
            level = getLevel(src),
            bucket = GetPlayerRoutingBucket(src),
        }
        if ped and ped ~= 0 then
            info.health = GetEntityHealth(ped)
            info.armour = GetPedArmour(ped)
        end
        if player then
            local job = player.getJob()
            info.name = player.getName()
            info.identifier = player.identifier
            info.job = { name = job.name, label = job.label, grade = job.grade, gradeLabel = job.gradeLabel, onDuty = job.onDuty }
            info.accounts = player.getAccounts()
            local state = Player(src).state
            info.down = state.isDead == true or state.isLastStand == true
            if job.onDuty and onDuty[job.name] then
                onDuty[job.name] = onDuty[job.name] + 1
            end
        end
        players[#players + 1] = info
    end
    table.sort(players, function(a, b) return a.id < b.id end)

    local jobs = {}
    for name, job in pairs(JJ.Config.Jobs) do
        local grades = {}
        for grade, data in pairs(job.grades) do
            grades[#grades + 1] = { value = grade, label = data.label }
        end
        table.sort(grades, function(a, b) return a.value < b.value end)
        jobs[#jobs + 1] = { name = name, label = job.label, grades = grades }
    end
    table.sort(jobs, function(a, b) return a.label < b.label end)

    local accounts = {}
    for name, account in pairs(JJ.Config.Accounts) do
        accounts[#accounts + 1] = { name = name, label = account.label }
    end
    table.sort(accounts, function(a, b) return a.label < b.label end)

    return {
        me = { id = source, name = getDisplayName(source), level = level, actions = getAllowedActions(source) },
        players = players,
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        stats = { police = onDuty.police, ambulance = onDuty.ambulance, bans = activeBans },
        jobs = jobs,
        accounts = accounts,
        weatherOptions = Config.Weather,
        vehiclePresets = Config.VehiclePresets,
        weather = GlobalState.jjWeather or false,
        time = GlobalState.jjTime or false,
    }
end)

lib.callback.register('jj_admin:server:getItems', function(source)
    if getLevel(source) == 'none' or GetResourceState('ox_inventory') ~= 'started' then return {} end
    local items = {}
    for name, item in pairs(exports.ox_inventory:Items()) do
        items[#items + 1] = { value = name, label = ('%s (%s)'):format(item.label or name, name) }
    end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items
end)

lib.callback.register('jj_admin:server:getBans', function(source)
    if getLevel(source) == 'none' then return {} end
    return MySQL.query.await('SELECT id, license, name, reason, admin, created_at, expires_at FROM jj_bans WHERE expires_at IS NULL OR expires_at > ? ORDER BY id DESC', { os.time() }) or {}
end)

lib.callback.register('jj_admin:server:getLogs', function(source)
    if getLevel(source) == 'none' then return {} end
    return MySQL.query.await('SELECT id, admin, action, target, details, created_at FROM jj_admin_logs ORDER BY id DESC LIMIT ?', { Config.LogLimit }) or {}
end)

-- Da las llaves del vehículo creado a quien lo ha sacado
RegisterNetEvent('jj_admin:server:vehicleSpawned', function(plate)
    local src = source
    if canUse(src, 'spawnVehicle') and type(plate) == 'string' and GetResourceState('jj_keysystem') == 'started' then
        exports.jj_keysystem:addTempKey(src, plate)
    end
end)

-- Espectar: posición del objetivo y salida

lib.callback.register('jj_admin:server:spectateCoords', function(source)
    local session = spectating[source]
    if not session or not canUse(source, 'spectate') then return nil end
    local coords = GetPlayerName(session.target) and getCoordsOf(session.target)
    return coords and { x = coords.x, y = coords.y, z = coords.z } or nil
end)

RegisterNetEvent('jj_admin:server:stopSpectate', function()
    local src = source
    local session = spectating[src]
    if session then
        SetPlayerRoutingBucket(src, session.bucket)
        spectating[src] = nil
    end
end)

-- "Ver jugadores": envía la posición de todos solo a quien lo tenga activado

CreateThread(function()
    while true do
        Wait(Config.PlayersRefresh)
        if next(playerViewers) then
            local list = {}
            for _, id in ipairs(GetPlayers()) do
                local src = tonumber(id)
                local coords = getCoordsOf(src)
                if coords then
                    list[#list + 1] = { id = src, name = getDisplayName(src), x = coords.x, y = coords.y, z = coords.z }
                end
            end
            for viewer in pairs(playerViewers) do
                if canUse(viewer, 'players') then
                    runClient(viewer, 'playersUpdate', list)
                else
                    playerViewers[viewer] = nil
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    frozen[src] = nil
    spectating[src] = nil
    playerViewers[src] = nil
end)
