-- Perfiles guardados y a qué vehículos se aplican
Profiles = {}

local store = {}          -- id -> perfil
local modelDefaults = {}  -- hash del modelo -> id de perfil
local plates = {}         -- matrícula -> id de perfil

local function toSeconds(value)
    value = tonumber(value)
    if not value then return os.time() end
    return value > 1e11 and math.floor(value / 1000) or value
end

local function decodeParams(text)
    local ok, params = pcall(json.decode, text or '{}')
    if not ok or type(params) ~= 'table' then return {} end
    -- Lo guardado se vuelve a validar por si alguien tocó la base de datos a mano
    local clean = Validation.Check(params)
    return clean or {}
end

function Profiles.Load()
    local rows, assignments = DB.Init()
    store, modelDefaults, plates = {}, {}, {}

    for _, row in ipairs(rows) do
        store[row.id] = {
            id = row.id,
            name = row.name,
            modelHash = Utils.ModelHash(row.model_hash),
            modelName = row.model_name,
            class = row.vehicle_class,
            params = decodeParams(row.params),
            preset = row.preset,
            global = row.is_global == 1 or row.is_global == true,
            author = row.author,
            authorName = row.author_name,
            version = row.version,
            createdAt = toSeconds(row.created_at),
            updatedAt = toSeconds(row.updated_at),
        }
    end

    for _, row in ipairs(assignments) do
        if store[row.profile_id] then
            if row.kind == 'model' then
                local hash = Utils.ModelHash(tonumber(row.target))
                if hash then modelDefaults[hash] = row.profile_id end
            elseif row.kind == 'plate' then
                plates[row.target] = row.profile_id
            end
        end
    end
end

function Profiles.Get(id)
    return store[tonumber(id) or -1]
end

-- Avisa a los clientes de que lo guardado para un modelo o matrícula ha cambiado.
-- Solo viaja la clave; quien esté conduciendo ese vehículo lo vuelve a pedir
function Profiles.Invalidate(data)
    TriggerClientEvent('jj_handling:client:invalidate', -1, data)
end

-- Permisos sobre un perfil

function Profiles.CanSee(profile, actor, rules)
    return profile.global or profile.author == actor.identifier or rules.panel
end

function Profiles.CanEdit(profile, actor, rules)
    return (profile.author == actor.identifier and rules.saveProfiles) or rules.editAny
end

function Profiles.CanDelete(profile, actor, rules)
    return (profile.author == actor.identifier and rules.saveProfiles) or rules.deleteAny
end

-- Datos para la interfaz
function Profiles.Public(profile, actor, rules, withParams)
    local installedPlates = {}
    for plate, id in pairs(plates) do
        if id == profile.id then installedPlates[#installedPlates + 1] = plate end
    end
    table.sort(installedPlates)

    return {
        id = profile.id,
        name = profile.name,
        modelHash = profile.modelHash,
        modelName = profile.modelName,
        class = profile.class,
        preset = profile.preset,
        global = profile.global,
        authorName = profile.authorName,
        own = actor and profile.author == actor.identifier or false,
        version = profile.version,
        createdAt = profile.createdAt,
        updatedAt = profile.updatedAt,
        paramCount = Utils.Count(profile.params),
        params = withParams and profile.params or nil,
        modelDefault = modelDefaults[profile.modelHash] == profile.id,
        plates = installedPlates,
        canEdit = actor and Profiles.CanEdit(profile, actor, rules) or false,
        canDelete = actor and Profiles.CanDelete(profile, actor, rules) or false,
    }
end

local function sortProfiles(list)
    table.sort(list, function(a, b)
        if a.updatedAt ~= b.updatedAt then return a.updatedAt > b.updatedAt end
        return a.id > b.id
    end)
    return list
end

-- Perfiles de un modelo que el jugador puede ver (con sus valores, para cargarlos en el editor)
function Profiles.ForModel(hash, actor, rules)
    local list = {}
    for _, profile in pairs(store) do
        if profile.modelHash == hash and Profiles.CanSee(profile, actor, rules) then
            list[#list + 1] = Profiles.Public(profile, actor, rules, true)
        end
    end
    return sortProfiles(list)
end

-- Búsqueda del panel por nombre, modelo o autor
function Profiles.Search(filter, actor, rules)
    local text = type(filter.search) == 'string' and filter.search:lower():sub(1, 32) or ''
    local list = {}
    for _, profile in pairs(store) do
        if Profiles.CanSee(profile, actor, rules) then
            local haystack = ('%s %s %s %s'):format(profile.name, profile.modelName or '', profile.authorName or '', profile.id):lower()
            local matchesScope = filter.scope ~= 'mine' or profile.author == actor.identifier
            if filter.scope == 'global' then matchesScope = profile.global end
            if filter.scope == 'default' then matchesScope = modelDefaults[profile.modelHash] == profile.id end
            if matchesScope and (text == '' or haystack:find(text, 1, true)) then
                list[#list + 1] = Profiles.Public(profile, actor, rules, false)
            end
        end
    end
    sortProfiles(list)
    while #list > 200 do table.remove(list) end
    return list
end

local function countOwn(identifier)
    local count = 0
    for _, profile in pairs(store) do
        if profile.author == identifier then count = count + 1 end
    end
    return count
end

-- Guardar: crea un perfil nuevo o actualiza uno existente.
-- data: { id?, version?, name, params, preset?, global?, modelHash, modelName?, class? }
-- context: { allowed, maxRelative, original } de la sesión del editor para limitar a los mecánicos
function Profiles.Save(actor, rules, data, context)
    if type(data) ~= 'table' then return nil, 'Datos no válidos' end
    context = context or {}

    local name = Utils.Trim(data.name, 64)
    if not name then return nil, 'El perfil necesita un nombre' end

    local existing = data.id and Profiles.Get(data.id)
    if data.id and not existing then return nil, 'Ese perfil ya no existe' end

    local modelHash = existing and existing.modelHash or Utils.ModelHash(data.modelHash)
    if not modelHash then return nil, 'Falta el modelo del vehículo' end
    local class = existing and existing.class or math.tointeger(tonumber(data.class))

    local params, errors = Validation.Check(data.params, {
        class = class,
        allowed = context.allowed,
        maxRelative = context.maxRelative,
        original = context.original,
    })
    if not params then return nil, table.concat(errors, '\n') end
    if not next(params) then return nil, 'El perfil no cambia ningún valor' end

    local global = data.global == true and rules.panel == true
    local preset = type(data.preset) == 'string' and data.preset:sub(1, 32) or nil

    if existing then
        if not Profiles.CanEdit(existing, actor, rules) then return nil, Config.Locales.no_permission end
        if not rules.panel then global = existing.global end
        if data.version ~= existing.version then return nil, Config.Locales.conflict end

        local previous = Utils.Copy(existing)
        local updated = { id = existing.id, name = name, params = params, preset = preset, global = global }
        if not DB.UpdateProfile(updated, existing.version) then return nil, Config.Locales.conflict end
        DB.InsertHistory(previous, actor)

        existing.name, existing.params, existing.preset, existing.global = name, params, preset, global
        existing.version = existing.version + 1
        existing.updatedAt = os.time()

        Logs.Add('update', actor, ('#%d %s'):format(existing.id, name), { model = existing.modelName or existing.modelHash, params = params })
        Profiles.Invalidate({ profile = existing.id, model = existing.modelHash })
        return existing
    end

    if not rules.saveProfiles then return nil, Config.Locales.no_permission end
    if countOwn(actor.identifier) >= Config.MaxProfilesPerUser and not rules.editAny then
        return nil, Config.Locales.max_profiles
    end

    local profile = {
        name = name,
        modelHash = modelHash,
        modelName = Utils.ModelName(data.modelName),
        class = class,
        params = params,
        preset = preset,
        global = global,
        author = actor.identifier,
        authorName = actor.name,
        version = 1,
        createdAt = os.time(),
        updatedAt = os.time(),
    }
    profile.id = DB.InsertProfile(profile)
    if not profile.id then return nil, 'No se ha podido guardar en la base de datos' end
    store[profile.id] = profile

    Logs.Add(data.imported and 'import' or 'create', actor, ('#%d %s'):format(profile.id, name), { model = profile.modelName or modelHash, params = params })
    return profile
end

function Profiles.Duplicate(actor, rules, id, name)
    local source = Profiles.Get(id)
    if not source or not Profiles.CanSee(source, actor, rules) then return nil, 'Ese perfil ya no existe' end
    if not rules.saveProfiles then return nil, Config.Locales.no_permission end

    local copy, err = Profiles.Save(actor, rules, {
        name = Utils.Trim(name, 64) or (source.name .. ' (copia)'):sub(1, 64),
        params = Utils.Copy(source.params),
        preset = source.preset,
        modelHash = source.modelHash,
        modelName = source.modelName,
        class = source.class,
    })
    if copy then Logs.Add('duplicate', actor, ('#%d -> #%d'):format(source.id, copy.id)) end
    return copy, err
end

function Profiles.Delete(actor, rules, id)
    local profile = Profiles.Get(id)
    if not profile then return false, 'Ese perfil ya no existe' end
    if not Profiles.CanDelete(profile, actor, rules) then return false, Config.Locales.no_permission end

    DB.DeleteProfile(profile.id)
    store[profile.id] = nil
    if modelDefaults[profile.modelHash] == profile.id then modelDefaults[profile.modelHash] = nil end
    for plate, profileId in pairs(plates) do
        if profileId == profile.id then plates[plate] = nil end
    end

    Logs.Add('delete', actor, ('#%d %s'):format(profile.id, profile.name), { model = profile.modelName or profile.modelHash })
    Profiles.Invalidate({ profile = profile.id, model = profile.modelHash })
    return true
end

function Profiles.History(actor, rules, id)
    local profile = Profiles.Get(id)
    if not profile or not Profiles.CanSee(profile, actor, rules) then return nil end

    local list = {}
    for _, row in ipairs(DB.GetHistory(profile.id)) do
        list[#list + 1] = {
            id = row.id,
            version = row.version,
            name = row.name,
            params = decodeParams(row.params),
            editedBy = row.edited_by_name,
            createdAt = toSeconds(row.created_at),
        }
    end
    return list
end

-- Vuelve a una versión anterior. Cuenta como una edición más, así que también queda en el historial
function Profiles.Revert(actor, rules, id, historyId, version)
    local profile = Profiles.Get(id)
    if not profile then return nil, 'Ese perfil ya no existe' end
    local entry = DB.GetHistoryEntry(profile.id, tonumber(historyId) or -1)
    if not entry then return nil, 'Esa versión ya no existe' end

    local saved, err = Profiles.Save(actor, rules, {
        id = profile.id,
        version = version,
        name = entry.name,
        params = decodeParams(entry.params),
        preset = profile.preset,
        global = profile.global,
    })
    if saved then Logs.Add('revert', actor, ('#%d %s'):format(profile.id, profile.name), { version = entry.version }) end
    return saved, err
end

-- Importar y exportar en JSON

function Profiles.Export(actor, rules, id)
    local profile = Profiles.Get(id)
    if not profile or not Profiles.CanSee(profile, actor, rules) then return nil end
    Logs.Add('export', actor, ('#%d %s'):format(profile.id, profile.name))
    return json.encode({
        format = 'jj_handling',
        version = 1,
        name = profile.name,
        model = profile.modelName,
        modelHash = profile.modelHash,
        class = profile.class,
        preset = profile.preset,
        params = profile.params,
    })
end

function Profiles.Import(actor, rules, text)
    if not rules.import then return nil, Config.Locales.no_permission end
    if type(text) ~= 'string' or #text == 0 then return nil, 'Pega el JSON del perfil' end
    if #text > Config.Security.MaxImportSize then return nil, 'El JSON es demasiado grande' end

    local ok, data = pcall(json.decode, text)
    if not ok or type(data) ~= 'table' then return nil, 'El texto no es un JSON válido' end
    if data.format ~= 'jj_handling' then return nil, 'No es un perfil de jj_handling' end
    if type(data.params) ~= 'table' then return nil, 'El perfil no tiene parámetros' end

    local modelName = Utils.ModelName(data.model)
    local hash = modelName and Utils.ModelHash(modelName) or Utils.ModelHash(tonumber(data.modelHash))
    if not hash then return nil, 'El perfil no indica un modelo válido' end

    return Profiles.Save(actor, rules, {
        name = data.name,
        params = data.params,
        preset = data.preset,
        modelHash = hash,
        modelName = modelName,
        class = data.class,
        imported = true,
    })
end

-- A qué vehículos se aplica

function Profiles.Install(actor, rules, plate, id, modelHash)
    local profile = Profiles.Get(id)
    if not profile or not Profiles.CanSee(profile, actor, rules) then return false, 'Ese perfil ya no existe' end
    if not rules.install then return false, Config.Locales.no_permission end
    if profile.modelHash ~= modelHash then return false, Config.Locales.incompatible end

    DB.SetAssignment('plate', plate, profile.id, actor.identifier)
    plates[plate] = profile.id
    Logs.Add('install', actor, plate, { profile = ('#%d %s'):format(profile.id, profile.name) })
    Profiles.Invalidate({ plate = plate })
    return true
end

function Profiles.Uninstall(actor, rules, plate)
    if not rules.install then return false, Config.Locales.no_permission end
    if not plates[plate] then return false, 'Este vehículo no tiene ningún perfil instalado' end

    DB.RemoveAssignment('plate', plate)
    plates[plate] = nil
    Logs.Add('uninstall', actor, plate)
    Profiles.Invalidate({ plate = plate })
    return true
end

function Profiles.SetModelDefault(actor, rules, id, enabled)
    local profile = Profiles.Get(id)
    if not profile then return false, 'Ese perfil ya no existe' end
    if not rules.modelDefault then return false, Config.Locales.no_permission end

    local target = tostring(profile.modelHash)
    if enabled then
        DB.SetAssignment('model', target, profile.id, actor.identifier)
        modelDefaults[profile.modelHash] = profile.id
        Logs.Add('model_default', actor, profile.modelName or target, { profile = ('#%d %s'):format(profile.id, profile.name) })
    elseif modelDefaults[profile.modelHash] == profile.id then
        DB.RemoveAssignment('model', target)
        modelDefaults[profile.modelHash] = nil
        Logs.Add('model_default_removed', actor, profile.modelName or target)
    end
    Profiles.Invalidate({ model = profile.modelHash })
    return true
end

-- Lo que le toca a un vehículo: primero lo instalado en su matrícula y si no, lo de serie de su modelo
function Profiles.Resolve(modelHash, plate)
    local id = plate and plates[plate]
    local profile = id and store[id]
    if profile and profile.modelHash == modelHash then
        return profile, 'install'
    end
    profile = store[modelDefaults[modelHash] or -1]
    if profile then return profile, 'model' end
    return nil
end
