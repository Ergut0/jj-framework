-- Validacion: parametros de circuitos, vehiculos, checkpoints y tiempos (anti-trampas).
-- Toda la logica corre en el servidor; el cliente solo reporta progreso.

Validation = { modelClass = {} }

local hashCache = {}

-- Posicion del jugador en el servidor ----------------------------------------------------

function Validation.HasServerPos()
    return GetConvar('onesync', 'off') ~= 'off'
end

--- Posicion autoritativa del piloto (OneSync). Devuelve { x, y, z } o nil.
function Validation.PlayerPos(src)
    if not Validation.HasServerPos() then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z }
end

--- Vehiculo actual del piloto: entidad, modelo normalizado, netId. nil si va a pie.
function Validation.PlayerVehicle(src)
    if not Validation.HasServerPos() then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return nil end
    return {
        entity = veh,
        model = Utils.NormHash(GetEntityModel(veh)),
        netId = NetworkGetNetworkIdFromEntity(veh),
        driver = GetPedInVehicleSeat(veh, -1) == ped,
    }
end

-- Vehiculos -----------------------------------------------------------------------------------

local function hashSet(list)
    if not list then return nil end
    if hashCache[list] then return hashCache[list] end
    local set = {}
    for _, name in ipairs(list) do set[Utils.NormHash(GetHashKey(name))] = true end
    hashCache[list] = set
    return set
end

--- Comprueba que un vehiculo (modelo y clase reportados) sirve para la clase de carrera.
--- El modelo se contrasta con el servidor; la clase se aprende por modelo y no puede cambiar despues.
---@return boolean ok, string|nil errorCode
function Validation.VehicleAllowed(classKey, model, class)
    model = Utils.NormHash(model)
    class = Utils.Int(class, 0, 40)
    if not model or not class then return false, 'vehicle_invalid' end

    local banned = hashSet(Config.BlacklistedModels)
    if banned and banned[model] then return false, 'vehicle_blacklisted' end
    if Utils.Contains(Config.BlacklistedClasses, class) then return false, 'vehicle_class' end

    local known = Validation.modelClass[model]
    if known and known ~= class then return false, 'vehicle_invalid' end
    Validation.modelClass[model] = class

    local def = Config.VehicleClasses[classKey]
    if not def then return false, 'class_invalid' end
    local whitelist = hashSet(def.models)
    if whitelist and not whitelist[model] then return false, 'vehicle_class' end
    if def.classes and not Utils.Contains(def.classes, class) then return false, 'vehicle_class' end
    return true
end

-- Circuitos -----------------------------------------------------------------------------------------

local COORD_MAX, Z_MIN, Z_MAX = 12000.0, -500.0, 3000.0

local function coord(v) return Utils.Num(v, -COORD_MAX, COORD_MAX) end

local function cpKind(v)
    if v == 'normal' or v == 'shortcut' or v == 'pit' then return v end
    return nil
end

--- Valida y normaliza un circuito recibido del cliente (editor, importacion o duplicado).
---@return table|boolean cleanOrFalse, string|nil errorCode
function Validation.Track(data)
    if type(data) ~= 'table' then return false, 'invalid_data' end
    local cr = Config.Creator

    local name = Utils.PlainStr(data.name, 64)
    if not name or #name < 3 or #name > 48 then return false, 'name_invalid' end

    if not Utils.Contains(Config.Categories, data.category) then return false, 'category_invalid' end
    if not Utils.Contains(Config.Difficulties, data.difficulty) then return false, 'difficulty_invalid' end

    local description = data.description == nil and '' or Utils.PlainStr(data.description, 255)
    if not description then return false, 'invalid_data' end

    local p2p = Utils.IsPointToPoint(data.category)
    local lapsDefault = p2p and 1 or Utils.Int(data.lapsDefault, 1, Settings.maxLaps)
    if not lapsDefault then return false, 'laps_invalid' end

    local class = data.vehicleClass
    if type(class) ~= 'string' or not Config.VehicleClasses[class] then return false, 'class_invalid' end

    local allowCrews, collisions = Utils.Bool(data.allowCrews), Utils.Bool(data.collisions)
    if allowCrews == nil or collisions == nil then return false, 'invalid_data' end

    local basePrize = Utils.Int(data.basePrize, 0, Settings.baseMaxPrize)
    local timeLimit = Utils.Int(data.timeLimit, 0, 86400)
    if not basePrize then return false, 'prize_invalid' end
    if not timeLimit then return false, 'invalid_data' end

    -- Checkpoints
    local src = data.checkpoints
    if type(src) ~= 'table' or #src < 2 or #src > cr.maxCheckpoints then return false, 'checkpoints_invalid' end
    local cps, normals = {}, 0
    for i, c in ipairs(src) do
        if type(c) ~= 'table' then return false, 'checkpoint_invalid' end
        local kind = cpKind(c.kind)
        local x, y, z = coord(c.x), coord(c.y), Utils.Num(c.z, Z_MIN, Z_MAX)
        local radius = Utils.Num(c.radius, cr.minRadius, cr.maxRadius)
        local height = Utils.Num(c.height, cr.minHeight, cr.maxHeight)
        if not kind or not x or not y or not z or not radius or not height then return false, 'checkpoint_invalid' end
        if kind == 'normal' then normals = normals + 1 end
        cps[i] = {
            idx = i, kind = kind, x = Utils.Round(x, 2), y = Utils.Round(y, 2), z = Utils.Round(z, 2),
            radius = Utils.Round(radius, 1), height = Utils.Round(height, 1),
            linkFrom = nil, linkTo = nil,
        }
        if kind == 'shortcut' then
            cps[i].linkFrom = Utils.Int(c.linkFrom, 1, 1000)
            cps[i].linkTo = Utils.Int(c.linkTo, 2, 1000)
            if not cps[i].linkFrom or not cps[i].linkTo then return false, 'shortcut_invalid' end
        end
    end
    if normals < 2 then return false, 'too_few_checkpoints' end
    for _, c in ipairs(cps) do
        -- Un atajo enlaza dos checkpoints normales saltandose al menos uno
        if c.kind == 'shortcut' and (c.linkTo < c.linkFrom + 2 or c.linkTo > normals) then return false, 'shortcut_invalid' end
    end

    -- Parrilla de salida
    local gridSrc = data.grid
    if type(gridSrc) ~= 'table' or #gridSrc < 1 or #gridSrc > cr.maxGrid then return false, 'grid_invalid' end
    local grid = {}
    for i, g in ipairs(gridSrc) do
        if type(g) ~= 'table' then return false, 'grid_invalid' end
        local x, y, z, h = coord(g.x), coord(g.y), Utils.Num(g.z, Z_MIN, Z_MAX), Utils.Num(g.h, -360.0, 720.0)
        if not x or not y or not z or not h then return false, 'grid_invalid' end
        grid[i] = { x = Utils.Round(x, 2), y = Utils.Round(y, 2), z = Utils.Round(z, 2), h = Utils.Round(h % 360.0, 1) }
    end

    return {
        name = name, category = data.category, difficulty = data.difficulty, description = description,
        lapsDefault = lapsDefault, vehicleClass = class, allowCrews = allowCrews, collisions = collisions,
        basePrize = basePrize, timeLimit = timeLimit, checkpoints = cps, grid = grid,
    }
end

--- Firma del trazado (posiciones, orden, tipos y enlaces + parrilla) para detectar cambios de version.
--- Radio, altura y orientacion no cuentan: ajustarlos no invalida los records.
function Validation.RouteSignature(checkpoints, grid)
    local parts = {}
    for _, c in ipairs(checkpoints) do
        parts[#parts + 1] = ('%s:%.1f:%.1f:%.1f:%s:%s'):format(c.kind, c.x, c.y, c.z, tostring(c.linkFrom or ''), tostring(c.linkTo or ''))
    end
    for _, g in ipairs(grid) do
        parts[#parts + 1] = ('g:%.1f:%.1f:%.1f'):format(g.x, g.y, g.z)
    end
    return table.concat(parts, '|')
end

-- Progreso en carrera ----------------------------------------------------------------------------------

--- Suma un aviso al piloto. Devuelve 'dq' si supera el limite de descalificacion.
---@param weight integer gravedad del aviso
function Validation.Strike(p, reason, weight)
    local ac = Config.AntiCheat
    p.flags = p.flags or {}
    p.flags[reason] = (p.flags[reason] or 0) + 1
    p.strikes = (p.strikes or 0) + (weight or 1)
    if p.strikes >= ac.strikesToDq then return 'dq' end
    return nil
end

--- Motivo(s) por los que el resultado queda marcado como sospechoso (o nil)
function Validation.FlagReason(p)
    local ac = Config.AntiCheat
    if not p.flags or (p.strikes or 0) < ac.strikesToFlag then return nil end
    local list = {}
    for reason, n in pairs(p.flags) do list[#list + 1] = ('%s x%d'):format(reason, n) end
    table.sort(list)
    return table.concat(list, ', '):sub(1, 120)
end

--- Valida un checkpoint reportado por el piloto.
---@param kind string 'cp' | 'sc' | 'pit'
---@return boolean ok, string|nil reason, integer|nil weight
function Validation.Checkpoint(p, cp, kind, now)
    local ac = Config.AntiCheat
    if kind == 'cp' then
        if cp.kind ~= 'normal' or cp.seq ~= p.nextSeq then return false, 'order', 1 end
    elseif kind == 'sc' then
        if cp.kind ~= 'shortcut' or cp.linkFrom ~= p.nextSeq - 1 then return false, 'order', 1 end
    elseif kind == 'pit' then
        if cp.kind ~= 'pit' then return false, 'order', 1 end
    else
        return false, 'order', 1
    end
    if not ac.enabled then return true end

    local pos = Validation.PlayerPos(p.src)
    if pos then
        if Utils.Dist2(pos, cp) > cp.radius + ac.posTolerance or math.abs(pos.z - cp.z) > cp.height + ac.posTolerance then
            return false, 'position', 3
        end
    end

    if kind ~= 'pit' and p.lastCp then
        local gap = math.max(0.0, Utils.Dist3(p.lastCp, cp) - (p.lastCp.radius or 0) - cp.radius)
        local minMs = gap / ac.maxSpeed * 1000.0 * ac.minTimeFactor
        if now - p.lastCpAt < minMs then return true, 'too_fast', 2 end
    end
    return true
end

--- Muestreo periodico: teletransportes y vehiculo. Devuelve 'dq', motivo si procede descalificar.
function Validation.Sample(p, now)
    local ac = Config.AntiCheat
    if not ac.enabled or not Validation.HasServerPos() then return nil end

    local pos = Validation.PlayerPos(p.src)
    if pos and p.lastPos and now - p.lastSampleAt >= ac.sampleInterval then
        local speed = Utils.Dist3(p.lastPos, pos) / ((now - p.lastSampleAt) / 1000.0)
        if speed > ac.teleportSpeed and Validation.Strike(p, 'teleport', 4) == 'dq' then return 'dq', 'teleport' end
    end
    if pos and (not p.lastSampleAt or now - p.lastSampleAt >= ac.sampleInterval) then
        p.lastPos, p.lastSampleAt = pos, now
    end

    local veh = Validation.PlayerVehicle(p.src)
    if not veh then
        p.offSince = p.offSince or now
        if now - p.offSince > ac.leftVehicleGrace * 1000 then return 'dq', 'left_vehicle' end
    else
        p.offSince = nil
        if p.vehicle and veh.model ~= p.vehicle.model then
            if ac.dqOnVehicleChange then return 'dq', 'vehicle_changed' end
            if Validation.Strike(p, 'vehicle_changed', 2) == 'dq' then return 'dq', 'vehicle_changed' end
        end
    end
    return nil
end

--- Comprobacion final de una vuelta contra el tiempo de referencia del circuito
function Validation.FinalCheck(lobby, p)
    local ref = lobby.track.referenceTime or 0
    if ref > 0 and p.bestLap and p.bestLap < ref * Config.AntiCheat.minRefFactor then
        Validation.Strike(p, 'below_reference', Config.AntiCheat.strikesToFlag)
    end
end
