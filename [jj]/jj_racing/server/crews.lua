-- Puente con el recurso `jj_crews` (dependencia opcional detectada en tiempo de ejecucion)
-- y retos crew vs crew. Todas las llamadas a los exports quedan en los logs de auditoria.

CrewLink = {}
Challenges = { list = {}, nextId = 1 }

-- Nombre real del recurso de crews. Se prueban Config.CrewsResources en orden y se usa el primero que este
-- iniciado Y exponga los exports.
local resolved = nil
local lastProbe = 0
local warned = {}

local function warnOnce(key, msg)
    if warned[key] then return end
    warned[key] = true
    print('^3[races]^7 ' .. msg)
end

local function resolve()
    if resolved then
        if GetResourceState(resolved) == 'started' then return resolved end
        resolved = nil
    end
    local now = GetGameTimer()
    if now - lastProbe < 3000 then return nil end -- no sondear en cada llamada mientras crews no esta listo
    lastProbe = now
    for _, name in ipairs(Config.CrewsResources) do
        if GetResourceState(name) == 'started' then
            -- GetCrew(0) no tiene efectos: devuelve nil si el export existe y lanza error si no existe
            local ok, err = pcall(function()
                exports[name]:GetCrew(0)
                exports[name]:GetPlayerCrew(0)
            end)
            if ok then
                resolved = name
                warned = {}
                print(('^2[races]^7 integracion con crews activa (recurso "%s")'):format(name))
                return name
            end
            warnOnce(name, ('el recurso "%s" esta iniciado pero no expone los exports de crews (%s). Reinicialo / actualizalo; mientras tanto las carreras funcionan sin crews.'):format(name, tostring(err)))
        end
    end
    return nil
end

function CrewLink.Enabled()
    return resolve() ~= nil
end

local function call(fn, ...)
    local res = resolve()
    if not res then return nil end
    local args = { ... }
    local ok, out = pcall(function()
        return exports[res][fn](exports[res], table.unpack(args))
    end)
    if not ok then
        warnOnce(fn, ('error llamando a %s:%s -> %s'):format(res, fn, tostring(out)))
        return nil
    end
    return out
end

local function audit(export, crewId, amount, reason, ok)
    Logs.Add({ cid = '', name = resolved or 'crews' }, 'crew_export', { export = export, crewId = crewId, amount = amount, reason = reason, ok = ok == true }, false)
end

-- Lectura ---------------------------------------------------------------------------

--- Vista compacta del crew de un jugador (o nil)
function CrewLink.GetPlayerCrew(src)
    local c = call('GetPlayerCrew', src)
    if type(c) ~= 'table' then return nil end
    return c
end

--- Datos minimos para mostrar en lobby, HUD y resultados
function CrewLink.Tag(src)
    local c = CrewLink.GetPlayerCrew(src)
    if not c then return nil end
    return { id = c.id, name = c.name, tag = c.tag, color = c.color }
end

function CrewLink.IsInCrew(src, crewId)
    return call('IsInCrew', src, crewId) == true
end

function CrewLink.GetCrew(crewId)
    local c = call('GetCrew', crewId)
    return type(c) == 'table' and c or nil
end

function CrewLink.GetMembers(crewId)
    local m = call('GetCrewMembers', crewId)
    return type(m) == 'table' and m or {}
end

function CrewLink.GetAllCrews()
    local list = call('GetAllCrews')
    return type(list) == 'table' and list or {}
end

-- Escritura (solo el servidor decide; cada llamada se audita) --------------------------

function CrewLink.AddPoints(crewId, amount, reason)
    if not crewId or not amount or amount == 0 then return false end
    local ok = call('AddCrewPoints', crewId, amount, reason) == true
    audit('AddCrewPoints', crewId, amount, reason, ok)
    return ok
end

function CrewLink.AddWin(crewId, reason)
    if not crewId then return false end
    local ok = call('AddCrewWin', crewId, 1, reason) == true
    audit('AddCrewWin', crewId, 1, reason, ok)
    return ok
end

--- amount positivo ingresa, negativo retira (false si no hay fondos)
function CrewLink.AddMoney(crewId, amount, reason)
    if not crewId or not amount or amount == 0 then return false end
    local ok = call('AddCrewMoney', crewId, amount, reason) == true
    audit('AddCrewMoney', crewId, amount, reason, ok)
    return ok
end

--- Jugador con rango suficiente para retar / aceptar retos. Devuelve crew | nil, codigoError
function CrewLink.CanChallenge(src)
    if not CrewLink.Enabled() then return nil, 'crews_disabled' end
    local crew = CrewLink.GetPlayerCrew(src)
    if not crew then return nil, 'not_in_crew' end
    if crew.frozen then return nil, 'crew_frozen' end
    local rank = crew.rank
    if not rank or not (rank.isLeader or (rank.level or 0) >= Settings.crewVsMinRank) then return nil, 'no_permission' end
    return crew
end

--- Jugadores conectados de un crew con rango para gestionar retos
local function eligibleMembers(crewId)
    local out = {}
    for _, m in ipairs(CrewLink.GetMembers(crewId)) do
        local p = JJ.GetPlayerByIdentifier(m.citizenid)
        if p and CrewLink.CanChallenge(p.source) then out[#out + 1] = p.source end
    end
    return out
end

-- Retos ---------------------------------------------------------------------------------

local function crewBrief(c)
    return { id = c.id, name = c.name, tag = c.tag, color = c.color }
end

function Challenges.View(ch)
    local from, to = CrewLink.GetCrew(ch.fromCrew), CrewLink.GetCrew(ch.toCrew)
    local track = Tracks.byId[ch.trackId]
    return {
        id = ch.id,
        from = from and crewBrief(from) or { id = ch.fromCrew, name = '?', tag = '?', color = '#888888' },
        to = to and crewBrief(to) or { id = ch.toCrew, name = '?', tag = '?', color = '#888888' },
        fromName = ch.fromName,
        trackId = ch.trackId,
        trackName = track and track.name or '?',
        laps = ch.laps,
        vehicleClass = ch.vehicleClass,
        teamSize = ch.teamSize,
        stake = ch.stake,
        expiresIn = math.max(0, math.ceil((ch.expiresAt - GetGameTimer()) / 1000)),
    }
end

--- Retos relacionados con el jugador: recibidos (puede aceptar) y enviados por su crew
function Challenges.ForPlayer(src)
    local out = { incoming = {}, outgoing = {} }
    local crew = CrewLink.Enabled() and CrewLink.GetPlayerCrew(src) or nil
    if not crew then return out end
    local canManage = CrewLink.CanChallenge(src) ~= nil
    for _, ch in pairs(Challenges.list) do
        if ch.toCrew == crew.id and canManage then out.incoming[#out.incoming + 1] = Challenges.View(ch) end
        if ch.fromCrew == crew.id then out.outgoing[#out.outgoing + 1] = Challenges.View(ch) end
    end
    return out
end

local function notifyCrew(crewId, text)
    for _, src in ipairs(eligibleMembers(crewId)) do
        TriggerClientEvent('races:client:notify', src, text, 'primary', 9000)
        TriggerClientEvent('races:client:refresh', src)
    end
end

function Challenges.Remove(id)
    local ch = Challenges.list[id]
    Challenges.list[id] = nil
    return ch
end

--- Crea un reto. data = { crewId, trackId, laps, vehicleClass, teamSize, stake }
function Challenges.Create(src, cid, name, data)
    local crew, err = CrewLink.CanChallenge(src)
    if not crew then return false, err end
    if Lobbies.byPlayer[src] then return false, 'already_in_race' end

    local target = CrewLink.GetCrew(data.crewId)
    if not target or target.id == crew.id then return false, 'crew_not_found' end
    if target.frozen then return false, 'crew_frozen' end

    local track = Tracks.byId[data.trackId]
    if not track or not track.enabled then return false, 'track_not_found' end
    if not track.allowCrews then return false, 'track_no_crews' end

    local laps, class = Lobbies.CheckRaceParams(track, data.laps, data.vehicleClass)
    if not laps then return false, class end

    local teamSize = Utils.Int(data.teamSize, 1, Config.CrewVs.maxTeamSize)
    local stake = Utils.Int(data.stake, 0, Settings.crewVsStakeMax)
    if not teamSize or not stake then return false, 'invalid_data' end
    if #track.grid < teamSize * 2 then return false, 'grid_too_small' end
    if (crew.money or 0) < stake then return false, 'crew_no_funds' end

    for _, ch in pairs(Challenges.list) do
        if ch.fromCrew == crew.id then return false, 'challenge_exists' end
    end
    if #eligibleMembers(target.id) == 0 then return false, 'target_offline' end

    local id = Challenges.nextId
    Challenges.nextId = id + 1
    local ch = {
        id = id, fromCrew = crew.id, toCrew = target.id, fromCid = cid, fromName = name, fromSrc = src,
        trackId = track.id, laps = laps, vehicleClass = class, teamSize = teamSize, stake = stake,
        expiresAt = GetGameTimer() + Config.CrewVs.challengeExpirySeconds * 1000,
    }
    Challenges.list[id] = ch
    SetTimeout(Config.CrewVs.challengeExpirySeconds * 1000, function()
        if Challenges.list[id] then
            Challenges.Remove(id)
            TriggerClientEvent('races:client:refresh', src)
        end
    end)

    Logs.Add({ cid = cid, name = name }, 'challenge_create', { fromCrew = crew.id, toCrew = target.id, track = track.name, stake = stake, teamSize = teamSize }, false)
    notifyCrew(target.id, L('n_challenge_received', crew.name, track.name))
    return true, Challenges.View(ch)
end

function Challenges.Cancel(src, id)
    local ch = Challenges.list[id]
    if not ch then return false, 'challenge_not_found' end
    local crew = CrewLink.GetPlayerCrew(src)
    if not crew or crew.id ~= ch.fromCrew then return false, 'no_permission' end
    Challenges.Remove(id)
    return true
end

--- Acepta o rechaza un reto. Al aceptar se retienen las apuestas y se abre la sala del reto.
function Challenges.Respond(src, cid, name, id, accept)
    local ch = Challenges.list[id]
    if not ch then return false, 'challenge_not_found' end
    local crew, err = CrewLink.CanChallenge(src)
    if not crew then return false, err end
    if crew.id ~= ch.toCrew then return false, 'no_permission' end

    if not accept then
        Challenges.Remove(id)
        local from = JJ.GetPlayerByIdentifier(ch.fromCid)
        if from then
            TriggerClientEvent('races:client:notify', from.source, L('n_challenge_declined', crew.name), 'error', 6000)
            TriggerClientEvent('races:client:refresh', from.source)
        end
        Logs.Add({ cid = cid, name = name }, 'challenge_decline', { fromCrew = ch.fromCrew, toCrew = ch.toCrew }, false)
        return true
    end

    if Lobbies.byPlayer[src] then return false, 'already_in_race' end
    local challenger = JJ.GetPlayerByIdentifier(ch.fromCid)
    if not challenger then
        Challenges.Remove(id)
        return false, 'challenger_offline'
    end
    local fromSrc = challenger.source
    if Lobbies.byPlayer[fromSrc] then return false, 'challenger_busy' end

    local track = Tracks.byId[ch.trackId]
    if not track or not track.enabled or not track.allowCrews then
        Challenges.Remove(id)
        return false, 'track_not_found'
    end
    local fromCrew = CrewLink.GetCrew(ch.fromCrew)
    if not fromCrew or fromCrew.frozen then
        Challenges.Remove(id)
        return false, 'crew_frozen'
    end

    -- Tomamos el reto antes de hacer yield en la BD: evita aceptarlo dos veces
    Challenges.Remove(id)

    local key = Lobbies.NewKey()
    local stakes = {}
    local function rollback()
        for _, s in ipairs(stakes) do
            if s.escrowId then DB.DeleteEscrow(s.escrowId) end
            CrewLink.AddMoney(s.crewId, ch.stake, 'race challenge refund')
        end
    end
    if ch.stake > 0 then
        local reason = ('race challenge #%d'):format(id)
        for _, crewId in ipairs({ ch.fromCrew, ch.toCrew }) do
            if not CrewLink.AddMoney(crewId, -ch.stake, reason) then
                rollback()
                return false, 'crew_no_funds'
            end
            stakes[#stakes + 1] = { crewId = crewId, escrowId = DB.InsertEscrow('crew', crewId, ch.stake, Config.EntryAccount, key, 'stake') }
        end
    end

    local lobby, lerr = Lobbies.CreateCrewLobby(key, ch, challenger, JJ.GetPlayer(src), stakes)
    if not lobby then
        rollback()
        return false, lerr or 'generic'
    end
    Logs.Add({ cid = cid, name = name }, 'challenge_accept', { fromCrew = ch.fromCrew, toCrew = ch.toCrew, stake = ch.stake, lobby = lobby.id }, false)
    return true, { lobbyId = lobby.id }
end
