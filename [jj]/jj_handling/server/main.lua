-- Callbacks del editor y del panel. Cada petición comprueba permisos, vehículo y valores en el servidor
local L = Config.Locales
local STATE_KEY = 'jj_handling'

local sessions = {}   -- source -> sesión del editor abierta
local temps = {}      -- netId -> { vehicle, src, workshop, expires } cambios temporales activos

MySQL.ready(function()
    local ok, err = pcall(Profiles.Load)
    if not ok then print(('^1[jj_handling] No se han podido cargar los perfiles: %s^7'):format(tostring(err))) end
end)

local function debug(...)
    if Config.Debug then print('[jj_handling]', ...) end
end

-- Límites de cada parámetro para una clase, para que la interfaz use los mismos que el servidor
local function limitsFor(class)
    local limits = {}
    for _, param in ipairs(Parameters.List) do
        local min, max = Validation.Limits(param.key, class)
        limits[param.key] = { min = min, max = max }
    end
    return limits
end

local function keys(set)
    local list = {}
    for key in pairs(set) do list[#list + 1] = key end
    table.sort(list)
    return list
end

-- Lo que hay aplicado ahora en un vehículo
local function vehicleState(vehicle, modelHash, plate)
    local temp = Entity(vehicle).state[STATE_KEY]
    local profile, source = Profiles.Resolve(modelHash, plate)
    return {
        temp = temp and { label = temp.label, by = temp.by, expires = temp.expires, profileId = temp.profileId, params = temp.params } or nil,
        persistent = profile and { id = profile.id, name = profile.name, source = source } or nil,
        autoApply = Permissions.Settings.autoApply,
    }
end

local function clearTemp(netId)
    local temp = temps[netId]
    temps[netId] = nil
    local vehicle = temp and temp.vehicle or NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        Entity(vehicle).state:set(STATE_KEY, nil, true)
    end
end

-- Sesión abierta y con el mismo vehículo, que sigue conduciendo
local function activeSession(src)
    local session = sessions[src]
    if not session then return nil, 'Abre el editor desde el vehículo' end
    if not Security.DriverVehicle(src, session.netId) then return nil, L.no_vehicle end
    return session
end

local function register(name, handler, options)
    options = options or {}
    lib.callback.register('jj_handling:' .. name, function(src, data)
        if not Security.Allow(src, options.light) then return { error = L.too_fast } end

        local level, rules = Permissions.Get(src)
        if not level and not options.public then return { error = L.no_permission } end

        local ok, result, err = pcall(handler, src, type(data) == 'table' and data or {}, level, rules)
        if not ok then
            print(('^1[jj_handling] Error en %s: %s^7'):format(name, tostring(result)))
            return { error = 'Error interno, revisa la consola del servidor' }
        end
        if result == nil and err then return { error = err } end
        return result or {}
    end)
end

-- Abrir el editor. Sin vehículo, los admins pueden usar solo el panel
register('open', function(src, data, level, rules)
    local actor = Permissions.Actor(src)
    local ui = {
        level = level,
        rules = {
            applyTemp = rules.applyTemp, saveProfiles = rules.saveProfiles, install = rules.install,
            modelDefault = rules.modelDefault, editAny = rules.editAny, deleteAny = rules.deleteAny,
            import = rules.import, export = rules.export, panel = rules.panel, logs = rules.logs,
            settings = rules.settings, maxRelative = rules.maxRelative,
        },
        settings = rules.settings and Permissions.Settings or nil,
        limits = limitsFor(nil),
    }

    local vehicle = data.netId and Security.DriverVehicle(src, data.netId)
    if not vehicle then
        if rules.panel then return ui end
        return nil, L.no_vehicle
    end

    local class, modelHash = Security.CheckVehicle(vehicle, data.class)
    if not class then return nil, L.blocked_vehicle end

    local workshopIndex, workshop = Permissions.Workshop(src, vehicle)
    if not rules.anywhere and not workshopIndex then return nil, L.not_in_workshop end

    local plate = Security.Plate(vehicle)
    local allowed = Permissions.AllowedParams(rules)
    local session = {
        netId = data.netId,
        vehicle = vehicle,
        modelHash = modelHash,
        modelName = Utils.ModelName(data.modelName),
        class = class,
        plate = plate,
        workshop = workshopIndex,
        allowed = allowed,
        maxRelative = rules.maxRelative,
        original = Security.CleanOriginal(data.original),
    }

    -- Si ya tenía una sesión con el mismo vehículo se conservan los originales del principio,
    -- así no se pueden "mover" para saltarse el límite de cambio
    local previous = sessions[src]
    if previous and previous.netId == session.netId and previous.modelHash == modelHash then
        session.original = previous.original
    end
    sessions[src] = session

    Logs.Add('open', actor, plate or session.modelName, { model = session.modelName or modelHash, workshop = workshop and workshop.label or 'libre' })

    ui.vehicle = {
        netId = data.netId,
        modelHash = modelHash,
        modelName = session.modelName,
        plate = plate,
        class = class,
        workshop = workshop and workshop.label or nil,
    }
    ui.allowed = keys(allowed)
    ui.limits = limitsFor(class)
    ui.profiles = Profiles.ForModel(modelHash, actor, rules)
    ui.state = vehicleState(vehicle, modelHash, plate)
    ui.testMinutes = Permissions.Settings.testMinutes
    return ui
end)

register('close', function(src)
    sessions[src] = nil
    return { ok = true }
end)

-- Cambios temporales para probar. Se guardan en el vehículo con un state bag, así los aplica
-- quien lo conduzca aunque cambie de conductor
register('applyTemp', function(src, data, _, rules)
    if not rules.applyTemp then return nil, L.no_permission end
    local session, err = activeSession(src)
    if not session then return nil, err end

    local params, errors = Validation.Check(data.params, {
        class = session.class, allowed = session.allowed, maxRelative = session.maxRelative, original = session.original,
    })
    if not params then return nil, table.concat(errors, '\n') end

    local actor = Permissions.Actor(src)
    local minutes = Permissions.Settings.testMinutes
    local expires = minutes > 0 and os.time() + minutes * 60 or nil
    local label = Utils.Trim(data.label, 48) or 'Personalizado'
    local profileId = math.tointeger(tonumber(data.profileId))

    Entity(session.vehicle).state:set(STATE_KEY, { params = params, label = label, by = actor.name, expires = expires, profileId = profileId }, true)
    temps[session.netId] = { vehicle = session.vehicle, src = src, workshop = session.workshop, expires = expires }

    Logs.Add('apply', actor, session.plate or session.modelName, { model = session.modelName or session.modelHash, label = label, params = params })
    return { state = vehicleState(session.vehicle, session.modelHash, session.plate) }
end)

register('restore', function(src)
    local session, err = activeSession(src)
    if not session then return nil, err end

    clearTemp(session.netId)
    Logs.Add('restore', Permissions.Actor(src), session.plate or session.modelName)
    return { state = vehicleState(session.vehicle, session.modelHash, session.plate) }
end)

-- Perfiles

local function saveContext(src, rules, modelHash)
    local session = sessions[src]
    if session and session.modelHash == modelHash then
        return { allowed = session.allowed, maxRelative = session.maxRelative, original = session.original }
    end
    if rules.panel then return {} end
    return nil
end

register('save', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local existing = data.id and Profiles.Get(data.id)
    local session = sessions[src]

    local payload = {
        id = data.id, version = data.version, name = data.name, params = data.params,
        preset = data.preset, global = data.global,
    }
    if not existing then
        if session and not data.modelName then
            -- Nuevo desde el editor: el modelo es el del vehículo, no lo que diga la interfaz
            payload.modelHash, payload.modelName, payload.class = session.modelHash, session.modelName, session.class
        elseif rules.panel then
            local modelName = Utils.ModelName(data.modelName)
            if not modelName then return nil, 'Escribe el nombre del modelo (por ejemplo: sultan)' end
            payload.modelHash, payload.modelName = Utils.ModelHash(modelName), modelName
            payload.class = math.tointeger(tonumber(data.class))
        else
            return nil, 'Abre el editor desde el vehículo'
        end
    end

    local context = saveContext(src, rules, existing and existing.modelHash or payload.modelHash)
    if not context then return nil, L.no_permission end

    local profile, err = Profiles.Save(actor, rules, payload, context)
    if not profile then return nil, err end
    return { profile = Profiles.Public(profile, actor, rules, true) }
end)

register('duplicate', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local profile, err = Profiles.Duplicate(actor, rules, data.id, data.name)
    if not profile then return nil, err end
    return { profile = Profiles.Public(profile, actor, rules, true) }
end)

register('delete', function(src, data, _, rules)
    local ok, err = Profiles.Delete(Permissions.Actor(src), rules, data.id)
    if not ok then return nil, err end
    return { ok = true }
end)

register('get', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local profile = Profiles.Get(data.id)
    if not profile or not Profiles.CanSee(profile, actor, rules) then return nil, 'Ese perfil ya no existe' end
    return { profile = Profiles.Public(profile, actor, rules, true) }
end)

register('search', function(src, data, _, rules)
    return { profiles = Profiles.Search(data, Permissions.Actor(src), rules) }
end)

register('history', function(src, data, _, rules)
    local list = Profiles.History(Permissions.Actor(src), rules, data.id)
    if not list then return nil, 'Ese perfil ya no existe' end
    return { history = list }
end)

register('revert', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local profile, err = Profiles.Revert(actor, rules, data.id, data.historyId, data.version)
    if not profile then return nil, err end
    return { profile = Profiles.Public(profile, actor, rules, true) }
end)

register('export', function(src, data, _, rules)
    if not rules.export then return nil, L.no_permission end
    local text = Profiles.Export(Permissions.Actor(src), rules, data.id)
    if not text then return nil, 'Ese perfil ya no existe' end
    return { json = text }
end)

register('import', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local profile, err = Profiles.Import(actor, rules, data.json)
    if not profile then return nil, err end
    return { profile = Profiles.Public(profile, actor, rules, true) }
end)

-- Instalar en el vehículo que se está editando (por matrícula)
register('install', function(src, data, _, rules)
    local session, err = activeSession(src)
    if not session then return nil, err end
    if not session.plate then return nil, 'El vehículo no tiene matrícula' end

    local ok, reason = Profiles.Install(Permissions.Actor(src), rules, session.plate, data.id, session.modelHash)
    if not ok then return nil, reason end
    clearTemp(session.netId)
    return { state = vehicleState(session.vehicle, session.modelHash, session.plate) }
end)

register('uninstall', function(src, _, _, rules)
    local session, err = activeSession(src)
    if not session then return nil, err end

    local ok, reason = Profiles.Uninstall(Permissions.Actor(src), rules, session.plate)
    if not ok then return nil, reason end
    return { state = vehicleState(session.vehicle, session.modelHash, session.plate) }
end)

register('setModelDefault', function(src, data, _, rules)
    local actor = Permissions.Actor(src)
    local ok, err = Profiles.SetModelDefault(actor, rules, data.id, data.enabled == true)
    if not ok then return nil, err end
    local profile = Profiles.Get(data.id)
    local result = { profile = profile and Profiles.Public(profile, actor, rules, true) or nil }
    local session = sessions[src]
    if session and Security.DriverVehicle(src, session.netId) then
        result.state = vehicleState(session.vehicle, session.modelHash, session.plate)
    end
    return result
end)

register('logs', function(_, data, _, rules)
    if not rules.logs then return nil, L.no_permission end
    local action = type(data.action) == 'string' and Logs.Labels[data.action] and data.action or nil
    local search = Utils.Trim(data.search, 32)
    local list = {}
    for _, row in ipairs(DB.GetLogs({ action = action, search = search, limit = 150 })) do
        list[#list + 1] = {
            id = row.id, action = row.action, label = Logs.Labels[row.action] or row.action,
            actor = row.actor_name, target = row.target, details = row.details,
            createdAt = row.created_at,
        }
    end
    return { logs = list, actions = Logs.Labels }
end)

register('settings', function(src, data, _, rules)
    if not rules.settings then return nil, L.no_permission end
    local settings = Permissions.SaveSettings(data)
    Logs.Add('settings', Permissions.Actor(src), 'global', settings)
    TriggerClientEvent('jj_handling:client:invalidate', -1, { all = true })
    return { settings = settings }
end)

-- Perfil persistente de un vehículo. Lo pide quien se sube a conducir; no hace falta permiso
register('resolve', function(src, data)
    if not Permissions.Settings.autoApply then return { params = nil } end
    local vehicle = Security.DriverVehicle(src, data.netId)
    if not vehicle then return { params = nil } end

    local profile, source = Profiles.Resolve(Utils.ModelHash(GetEntityModel(vehicle)), Security.Plate(vehicle))
    if not profile then return { params = nil } end
    debug('resolve', data.netId, profile.id, source)
    return { params = profile.params, name = profile.name, source = source }
end, { public = true, light = true })

-- Las pruebas temporales se acaban solas: por tiempo o al alejarse del taller
CreateThread(function()
    while true do
        Wait(5000)
        if next(temps) then
            local now = os.time()
            for netId, temp in pairs(temps) do
                if not DoesEntityExist(temp.vehicle) then
                    temps[netId] = nil
                elseif Config.RestoreOnLeaveVehicle and GetPedInVehicleSeat(temp.vehicle, -1) == 0 then
                    clearTemp(netId)
                    Logs.Add('expire', nil, tostring(netId), { reason = 'sin conductor' })
                elseif temp.expires and now >= temp.expires then
                    clearTemp(netId)
                    if GetPlayerName(temp.src) then JJ.Notify(temp.src, L.test_expired, 'inform', 7000) end
                    Logs.Add('expire', nil, tostring(netId), { reason = 'tiempo' })
                elseif temp.workshop then
                    local workshop = Config.Workshops[temp.workshop]
                    if workshop and #(GetEntityCoords(temp.vehicle) - workshop.coords) > workshop.testRadius then
                        clearTemp(netId)
                        if GetPlayerName(temp.src) then JJ.Notify(temp.src, L.test_left, 'inform', 7000) end
                        Logs.Add('expire', nil, tostring(netId), { reason = 'fuera del taller' })
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
    Security.Forget(source)
end)

RegisterCommand(Config.Command, function(src)
    if src == 0 then return end
    if not Permissions.Get(src) then return JJ.Notify(src, L.no_permission, 'error') end
    TriggerClientEvent('jj_handling:client:open', src)
end, false)
