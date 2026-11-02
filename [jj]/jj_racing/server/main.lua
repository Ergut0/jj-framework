-- Nucleo: ajustes en vivo, cache de circuitos (CRUD, versiones, import/export), arranque y exports.

Tracks = { list = {}, byId = {}, ready = false }
Settings = {}

local function truthy(v) return v == true or v == 1 end

-- Ajustes en vivo --------------------------------------------------------------------------------

local ENUM_FORMULAS = { points = true, positions = true, best = true }

SettingsSchema = {
    maxPlayers           = { t = 'int', min = 2, max = 32 },
    minPlayersToStart    = { t = 'int', min = 1, max = 32 },
    minPlayersForRewards = { t = 'int', min = 1, max = 32 },
    maxLaps              = { t = 'int', min = 1, max = 100 },
    countdownSeconds     = { t = 'int', min = 3, max = 30 },
    finishGraceSeconds   = { t = 'int', min = 10, max = 900 },
    entryFeeMax          = { t = 'int', min = 0, max = 10000000 },
    extraPrizeMax        = { t = 'int', min = 0, max = 10000000 },
    baseMaxPrize         = { t = 'int', min = 0, max = 10000000 },
    commissionPct        = { t = 'int', min = 0, max = 100 },
    prizeSplit           = { t = 'intlist', min = 0, max = 100, maxItems = 16, sumMax = 100 },
    pilotPoints          = { t = 'intlist', min = 0, max = 10000, maxItems = 32 },
    allowedClasses       = { t = 'classlist' },
    useRoutingBuckets    = { t = 'bool' },
    openLobbyMinutes     = { t = 'int', min = 1, max = 240 },
    crewPointsByPosition = { t = 'intlist', min = 0, max = 100000, maxItems = 32 },
    crewFinishPoints     = { t = 'int', min = 0, max = 100000 },
    crewMaxPointsPerRace = { t = 'int', min = 0, max = 1000000 },
    crewRequireOutsider  = { t = 'bool' },
    crewPrizeSharePct    = { t = 'int', min = 0, max = 100 },
    crewVsFormula        = { t = 'formula' },
    crewVsWinPoints      = { t = 'int', min = 0, max = 1000000 },
    crewVsStakeMax       = { t = 'int', min = 0, max = 10000000 },
    crewVsMinRank        = { t = 'int', min = 1, max = 99 },
}

--- Valida un valor segun el esquema. Devuelve el valor limpio o nil.
function ValidateSetting(key, v)
    local def = SettingsSchema[key]
    if not def then return nil end
    if def.t == 'int' then return Utils.Int(v, def.min, def.max) end
    if def.t == 'bool' then return Utils.Bool(v) end
    if def.t == 'formula' then return type(v) == 'string' and ENUM_FORMULAS[v] and v or nil end
    if type(v) ~= 'table' then return nil end
    if def.t == 'intlist' then
        if #v > def.maxItems then return nil end
        local out, sum = {}, 0
        for i, item in ipairs(v) do
            local n = Utils.Int(item, def.min, def.max)
            if not n then return nil end
            out[i] = n
            sum = sum + n
        end
        if def.sumMax and sum > def.sumMax then return nil end
        return out
    end
    if def.t == 'classlist' then
        local out, seen = {}, {}
        for _, item in ipairs(v) do
            if type(item) ~= 'string' or not Config.VehicleClasses[item] then return nil end
            if not seen[item] then seen[item] = true; out[#out + 1] = item end
        end
        if #out == 0 then return nil end
        return out
    end
    return nil
end

local function loadSettings()
    Settings = Utils.DeepCopy(Config.Settings)
    for _, row in ipairs(DB.GetSettings()) do
        local ok, val = pcall(json.decode, row.value)
        if ok then
            local clean = ValidateSetting(row.key, val)
            if clean ~= nil then Settings[row.key] = clean end
        end
    end
end

function SaveSettings(input, actor)
    if type(input) ~= 'table' then return false, 'invalid_data' end
    local clean, changes = {}, {}
    for key, value in pairs(input) do
        local v = ValidateSetting(key, value)
        if v == nil then return false, 'setting_invalid', key end
        clean[key] = v
    end
    for key, v in pairs(clean) do
        if json.encode(Settings[key]) ~= json.encode(v) then
            changes[key] = { from = Settings[key], to = v }
        end
    end
    for key, v in pairs(clean) do
        Settings[key] = v
        DB.SetSetting(key, json.encode(v))
    end
    local keys = {}
    for k in pairs(changes) do keys[#keys + 1] = k end
    table.sort(keys)
    if #keys > 0 then Logs.Add(actor, 'settings_save', { keys = table.concat(keys, ','), changes = json.encode(changes):sub(1, 1500) }, true) end
    return true
end

--- Ajustes que necesita la NUI para validar formularios
function PublicSettings()
    return Utils.DeepCopy(Settings)
end

-- Circuitos ------------------------------------------------------------------------------------------

--- Calcula la numeracion de checkpoints normales, los atajos y la longitud. Idempotente.
function Tracks.Index(t)
    t.normals, t.shortcuts, t.pits = {}, {}, {}
    for _, cp in ipairs(t.checkpoints) do
        if cp.kind == 'normal' then
            t.normals[#t.normals + 1] = cp
            cp.seq = #t.normals
        elseif cp.kind == 'shortcut' then
            t.shortcuts[#t.shortcuts + 1] = cp
            cp.seq = nil
        else
            t.pits[#t.pits + 1] = cp
            cp.seq = nil
        end
    end
    local length = 0.0
    for i = 2, #t.normals do length = length + Utils.Dist3(t.normals[i - 1], t.normals[i]) end
    t.length = math.floor(length)
end

local function rowToTrack(row)
    local grid = row.grid
    if type(grid) == 'string' then
        local ok, decoded = pcall(json.decode, grid)
        grid = ok and decoded or nil
    end
    return {
        id = row.id, name = row.name, category = row.category, difficulty = row.difficulty, description = row.description or '',
        lapsDefault = row.laps_default, vehicleClass = row.vehicle_class, enabled = truthy(row.enabled), version = row.version,
        testedVersion = row.tested_version, allowCrews = truthy(row.allow_crews), basePrize = row.base_prize, timeLimit = row.time_limit,
        collisions = truthy(row.collisions), referenceTime = row.reference_time, grid = type(grid) == 'table' and grid or {},
        createdBy = row.created_by, createdAt = row.created_at, updatedAt = row.updated_at, checkpoints = {},
    }
end

--- Carga circuitos y checkpoints de la version vigente. Un circuito danado no impide cargar el resto.
function Tracks.Load()
    Tracks.list, Tracks.byId = {}, {}
    for _, row in ipairs(DB.GetTracks()) do
        local ok, t = pcall(rowToTrack, row)
        if ok then
            Tracks.list[#Tracks.list + 1] = t
            Tracks.byId[t.id] = t
        else
            print(('^1[races]^7 circuito id %s ilegible en la base de datos: %s'):format(tostring(row.id), tostring(t)))
        end
    end
    for _, c in ipairs(DB.GetCheckpoints()) do
        local t = Tracks.byId[c.track_id]
        if t then
            t.checkpoints[#t.checkpoints + 1] = {
                idx = c.idx, kind = c.kind, x = (tonumber(c.x) or 0) + 0.0, y = (tonumber(c.y) or 0) + 0.0, z = (tonumber(c.z) or 0) + 0.0,
                radius = (tonumber(c.radius) or Config.Creator.defaultRadius) + 0.0, height = (tonumber(c.height) or Config.Creator.defaultHeight) + 0.0,
                linkFrom = c.link_from and c.link_from > 0 and c.link_from or nil, linkTo = c.link_to and c.link_to > 0 and c.link_to or nil,
            }
        end
    end

    local broken = {}
    for _, t in ipairs(Tracks.list) do
        Tracks.Index(t)
        -- Sin checkpoints (importacion incompleta) o sin parrilla no se puede correr: se oculta a los jugadores
        if t.enabled and (#t.normals < 2 or #t.grid < 1) then
            t.enabled = false
            broken[#broken + 1] = t.name
        end
    end
    if #broken > 0 then
        print(('^3[races]^7 %d circuitos desactivados por estar incompletos (sin checkpoints o parrilla), por ejemplo: %s'):format(#broken, table.concat(broken, ', ', 1, math.min(#broken, 5))))
    end
end

--- true si hay una carrera (sala) usando el circuito
function Tracks.InUse(trackId)
    for _, lobby in pairs(Lobbies.list) do
        if lobby.track.id == trackId then return true end
    end
    return false
end

local function nameTaken(name, exceptId)
    local lower = name:lower()
    for _, t in ipairs(Tracks.list) do
        if t.id ~= exceptId and t.name:lower() == lower then return true end
    end
    return false
end

local function uniqueName(base)
    if not nameTaken(base) then return base end
    for i = 2, 99 do
        local suffix = (' (%d)'):format(i)
        local candidate = base:sub(1, 48 - #suffix) .. suffix
        if not nameTaken(candidate) then return candidate end
    end
    return base:sub(1, 40) .. ('-%d'):format(math.random(100, 999))
end

--- Crea o actualiza un circuito. data.id presente = edicion. data.minor = cambio menor (no sube la version).
---@return boolean ok, table|string trackOrError
function Tracks.Save(data, actor)
    if type(data) ~= 'table' then return false, 'invalid_data' end
    local clean, err = Validation.Track(data)
    if not clean then return false, err end

    local existing
    if data.id ~= nil then
        existing = Tracks.byId[Utils.Int(data.id, 1, 2147483647) or 0]
        if not existing then return false, 'track_not_found' end
        if Tracks.InUse(existing.id) then return false, 'track_in_use' end
    end
    if nameTaken(clean.name, existing and existing.id) then return false, 'name_taken' end

    if not existing then
        local t = clean
        t.enabled, t.version, t.testedVersion, t.referenceTime = false, 1, 0, 0
        t.createdBy = actor.cid or ''
        t.id = DB.InsertTrack(t, actor.cid or '')
        if not t.id then return false, 'db' end
        t.createdAt, t.updatedAt = os.time(), os.time()
        Tracks.Index(t)
        Tracks.list[#Tracks.list + 1] = t
        Tracks.byId[t.id] = t
        Logs.Add(actor, 'track_create', { id = t.id, name = t.name }, true)
        return true, t
    end

    local changed = Validation.RouteSignature(clean.checkpoints, clean.grid) ~= Validation.RouteSignature(existing.checkpoints, existing.grid)
    local bump = changed and data.minor ~= true
    local t = clean
    t.id, t.createdBy, t.createdAt = existing.id, existing.createdBy, existing.createdAt
    t.enabled, t.version, t.testedVersion, t.referenceTime = existing.enabled, existing.version, existing.testedVersion, existing.referenceTime
    if bump then
        t.version = existing.version + 1
        t.referenceTime = 0
        if Config.Creator.requireTest then t.enabled = false end
    end
    if not DB.UpdateTrack(t) then return false, 'db' end
    t.updatedAt = os.time()
    Tracks.Index(t)
    for i, old in ipairs(Tracks.list) do
        if old.id == t.id then Tracks.list[i] = t break end
    end
    Tracks.byId[t.id] = t
    if bump then Leaderboard.RefreshBest(t) end
    Logs.Add(actor, 'track_save', { id = t.id, name = t.name, version = t.version, newVersion = bump }, true)
    return true, t, bump
end

function Tracks.Duplicate(id, actor)
    local src = Tracks.byId[id]
    if not src then return false, 'track_not_found' end
    local copy = Tracks.ExportTable(src)
    copy.name = uniqueName((src.name .. ' copy'):sub(1, 48))
    local ok, t = Tracks.Save(copy, actor)
    if ok then Logs.Add(actor, 'track_duplicate', { from = src.id, to = t.id }, true) end
    return ok, t
end

function Tracks.SetEnabled(id, enabled, actor)
    local t = Tracks.byId[id]
    if not t then return false, 'track_not_found' end
    if enabled and Config.Creator.requireTest and t.testedVersion ~= t.version then return false, 'track_untested' end
    t.enabled = enabled
    DB.SetTrackEnabled(id, enabled)
    Logs.Add(actor, enabled and 'track_enable' or 'track_disable', { id = id, name = t.name }, true)
    return true
end

function Tracks.Delete(id, actor)
    local t = Tracks.byId[id]
    if not t then return false, 'track_not_found' end
    if Tracks.InUse(id) then return false, 'track_in_use' end
    DB.DeleteTrack(id)
    for i, old in ipairs(Tracks.list) do
        if old.id == id then table.remove(Tracks.list, i) break end
    end
    Tracks.byId[id] = nil
    Leaderboard.best[id], Leaderboard.boards[id] = nil, nil
    Logs.Add(actor, 'track_delete', { id = id, name = t.name }, true)
    return true
end

--- Una prueba superada fija el tiempo de referencia y habilita la publicacion de la version actual
function Tracks.MarkTested(t, bestLap, actor)
    local ref = bestLap
    if t.testedVersion == t.version and t.referenceTime > 0 then ref = math.min(t.referenceTime, bestLap) end
    t.testedVersion, t.referenceTime = t.version, ref
    DB.SetTrackTested(t.id, t.version, ref)
    Logs.Add(actor, 'track_test', { id = t.id, name = t.name, version = t.version, reference = Utils.FormatTime(ref) }, true)
    return ref
end

-- Importacion / exportacion ----------------------------------------------------------------------------

function Tracks.ExportTable(t)
    local cps = {}
    for i, c in ipairs(t.checkpoints) do
        cps[i] = { kind = c.kind, x = c.x, y = c.y, z = c.z, radius = c.radius, height = c.height, linkFrom = c.linkFrom, linkTo = c.linkTo }
    end
    local grid = {}
    for i, g in ipairs(t.grid) do grid[i] = { x = g.x, y = g.y, z = g.z, h = g.h } end
    return {
        format = 'races.track', schema = 1, name = t.name, category = t.category, difficulty = t.difficulty, description = t.description,
        lapsDefault = t.lapsDefault, vehicleClass = t.vehicleClass, allowCrews = t.allowCrews, basePrize = t.basePrize,
        timeLimit = t.timeLimit, collisions = t.collisions, checkpoints = cps, grid = grid,
    }
end

function Tracks.Export(id, actor)
    local t = Tracks.byId[id]
    if not t then return false, 'track_not_found' end
    Logs.Add(actor, 'track_export', { id = id, name = t.name }, true)
    return true, json.encode(Tracks.ExportTable(t))
end

--- Importa un circuito desde JSON. Siempre queda desactivado y sin probar.
function Tracks.Import(text, actor)
    if type(text) ~= 'string' or #text == 0 or #text > 262144 then return false, 'import_invalid' end
    local ok, data = pcall(json.decode, text)
    if not ok or type(data) ~= 'table' or data.format ~= 'races.track' or data.schema ~= 1 then return false, 'import_invalid' end
    data.id = nil
    if type(data.name) ~= 'string' then return false, 'name_invalid' end
    local name = Utils.PlainStr(data.name, 64)
    if not name or #name < 3 then return false, 'name_invalid' end
    data.name = uniqueName(name:sub(1, 48))
    if type(data.basePrize) == 'number' then data.basePrize = math.min(math.max(0, math.floor(data.basePrize)), Settings.baseMaxPrize) end
    if type(data.lapsDefault) == 'number' then data.lapsDefault = math.min(math.max(1, math.floor(data.lapsDefault)), Settings.maxLaps) end
    if type(data.vehicleClass) ~= 'string' or not Config.VehicleClasses[data.vehicleClass] then data.vehicleClass = 'any' end
    local saved, t = Tracks.Save(data, actor)
    if not saved then return false, t end
    Logs.Add(actor, 'track_import', { id = t.id, name = t.name }, true)
    return true, t
end

-- Vistas --------------------------------------------------------------------------------------------------------

local function baseView(t)
    return {
        id = t.id, name = t.name, category = t.category, difficulty = t.difficulty, description = t.description, lapsDefault = t.lapsDefault,
        vehicleClass = t.vehicleClass, allowCrews = t.allowCrews, basePrize = t.basePrize, timeLimit = t.timeLimit, collisions = t.collisions,
        referenceTime = t.referenceTime, checkpointCount = #t.normals, length = t.length, version = t.version,
        gridSize = #t.grid, record = Leaderboard.Best(t.id),
    }
end

--- Vista de catalogo (jugadores y listados de administracion)
function Tracks.CatalogView(t, admin)
    local v = baseView(t)
    if admin then
        v.enabled, v.tested, v.updatedAt, v.inUse = t.enabled, t.testedVersion == t.version, t.updatedAt, Tracks.InUse(t.id)
    end
    return v
end

--- Detalle: ruta simplificada para el mapa; administracion recibe el trazado completo
function Tracks.Detail(t, admin)
    local v = Tracks.CatalogView(t, admin)
    local route = {}
    for i, c in ipairs(t.checkpoints) do route[i] = { x = c.x, y = c.y, kind = c.kind, seq = c.seq, linkFrom = c.linkFrom, linkTo = c.linkTo } end
    v.route = route
    v.grid = {}
    for i, g in ipairs(t.grid) do v.grid[i] = { x = g.x, y = g.y, h = g.h } end
    if admin then
        v.checkpoints = Utils.DeepCopy(t.checkpoints)
        v.grid = Utils.DeepCopy(t.grid)
        v.testedVersion = t.testedVersion
    end
    return v
end

local function difficultyRank(d)
    for i, name in ipairs(Config.Difficulties) do
        if name == d then return i end
    end
    return 0
end

--- Listado filtrado y paginado. opts = { search, category, difficulty, vehicleClass, status, sort, page }
function Tracks.List(opts, admin)
    local search = (Utils.Str(opts.search or '', 40) or ''):lower()
    local out = {}
    for _, t in ipairs(Tracks.list) do
        local pass = admin or t.enabled
        if pass and opts.category and opts.category ~= '' and t.category ~= opts.category then pass = false end
        if pass and opts.difficulty and opts.difficulty ~= '' and t.difficulty ~= opts.difficulty then pass = false end
        if pass and opts.vehicleClass and opts.vehicleClass ~= '' and t.vehicleClass ~= opts.vehicleClass then pass = false end
        if pass and search ~= '' and not t.name:lower():find(search, 1, true) and not t.description:lower():find(search, 1, true) then pass = false end
        if pass and admin and opts.status == 'enabled' and not t.enabled then pass = false end
        if pass and admin and opts.status == 'disabled' and t.enabled then pass = false end
        if pass and admin and opts.status == 'untested' and t.testedVersion == t.version then pass = false end
        if pass then out[#out + 1] = t end
    end

    local sort = opts.sort
    table.sort(out, function(a, b)
        if sort == 'difficulty' then
            local da, db = difficultyRank(a.difficulty), difficultyRank(b.difficulty)
            if da ~= db then return da < db end
        elseif sort == 'length' then
            if a.length ~= b.length then return a.length > b.length end
        elseif sort == 'newest' then
            if a.id ~= b.id then return a.id > b.id end
        end
        return a.name:lower() < b.name:lower()
    end)

    local page = Utils.Int(opts.page, 1, 100000) or 1
    local size = Config.PageSize
    local items = {}
    for i = (page - 1) * size + 1, math.min(#out, page * size) do items[#items + 1] = Tracks.CatalogView(out[i], admin) end
    return { items = items, total = #out, page = page, pageSize = size }
end

-- Arranque --------------------------------------------------------------------------------------------------------------

--- Ejecuta un paso del arranque sin que un fallo impida marcar el recurso como listo
local function startupStep(label, fn)
    local ok, err = pcall(fn)
    if not ok then print(('^1[races]^7 error en el arranque (%s): %s'):format(label, tostring(err))) end
    return ok
end

MySQL.ready(function()
    startupStep('ajustes', loadSettings)
    if not startupStep('circuitos', Tracks.Load) then
        print('^1[races]^7 no se pudieron cargar los circuitos: comprueba que has importado sql/races.sql')
    end
    startupStep('records', Leaderboard.LoadBest)
    startupStep('eventos', DB.CancelStaleEvents)
    startupStep('retenciones', Money.RecoverEscrows)
    if Config.LogRetentionDays > 0 then startupStep('logs', function() DB.PurgeLogs(Config.LogRetentionDays) end) end
    startupStep('programacion', Events.Schedule)
    Tracks.ready = true

    local enabled = 0
    for _, t in ipairs(Tracks.list) do
        if t.enabled then enabled = enabled + 1 end
    end
    print(('^2[races]^7 %d circuitos cargados (%d activos)'):format(#Tracks.list, enabled))
    if #Tracks.list == 0 then
        print('^3[races]^7 no hay circuitos en la base de datos: importa sql/tracks.sql (circuitos de ejemplo) o crea uno desde /raceadmin')
    end
    if Config.AntiCheat.enabled and not Validation.HasServerPos() then
        print('^3[races]^7 OneSync desactivado: las comprobaciones de posicion y vehiculo en servidor quedan limitadas. Activa OneSync para el anti-trampas completo.')
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Devuelve inscripciones y libera a los pilotos; lo que no llegue a escribirse lo recupera race_escrow al arrancar
    for _, lobby in pairs(Lobbies.list) do
        pcall(Lobbies.Cancel, lobby, 'resource_stop')
    end
end)

-- Exports y eventos publicos ----------------------------------------------------------------------------------------------

exports('GetActiveRaces', function()
    local out = {}
    for _, lobby in pairs(Lobbies.list) do
        local s = Lobbies.Summary(lobby)
        s.state = lobby.state
        out[#out + 1] = s
    end
    return out
end)

exports('GetTrack', function(id)
    local t = Tracks.byId[tonumber(id)]
    return t and Tracks.Detail(t, false) or nil
end)

exports('GetTracks', function()
    local out = {}
    for _, t in ipairs(Tracks.list) do
        if t.enabled then out[#out + 1] = Tracks.CatalogView(t, false) end
    end
    return out
end)

exports('GetTrackRecord', function(id)
    return Leaderboard.Best(tonumber(id))
end)

exports('GetPlayerRace', function(src)
    local lobby = Lobbies.byPlayer[src]
    if not lobby then return nil end
    local p = lobby.players[src]
    return { id = lobby.id, state = lobby.state, mode = lobby.mode, trackId = lobby.track.id, trackName = lobby.track.name, status = p and p.status or nil }
end)

exports('IsInRace', function(src)
    return Lobbies.byPlayer[src] ~= nil
end)
