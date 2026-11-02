-- Salas de carrera: creacion, union, estados, abandono, cuenta atras y progreso en carrera.
-- Estados: open -> countdown -> running -> finished | cancelled   (el chequeo de vehiculos es el subestado `checking` de open)
-- Convencion: las funciones de dominio devuelven (true, dato) o (false, claveError).

Lobbies = { list = {}, nextId = 1, byPlayer = {}, busy = {}, usedBuckets = {}, loopActive = false }
Money = {}
Events = { token = 0 }

local STANDINGS_ROWS = 8

function Lobbies.Notify(src, text, kind, ms)
    TriggerClientEvent('races:client:notify', src, text, kind or 'primary', ms or 6000)
end

function Lobbies.NewKey()
    return ('%x%04x%d'):format(os.time(), math.random(0, 0xffff), Lobbies.nextId)
end

-- Dinero ---------------------------------------------------------------------------------
-- Las inscripciones se retienen en race_escrow. Siempre se borra la fila ANTES de pagar:
-- si el servidor cae en medio, se pierde un pago pero nunca se duplica dinero.

--- Cobra y retiene. Devuelve (true, escrowId|nil) o (false, codigo)
function Money.Charge(src, account, amount, reason, ref)
    if amount <= 0 then return true, nil end
    local P = JJ.GetPlayer(src)
    if not P then return false, 'generic' end
    if (P.getMoney(account) or 0) < amount then return false, 'no_money' end
    if not P.removeMoney(account, amount, 'race-' .. reason) then return false, 'no_money' end
    local id = DB.InsertEscrow('player', P.identifier, amount, account, ref, reason)
    if not id then
        P.addMoney(account, amount, 'race-refund-db')
        return false, 'db'
    end
    return true, id
end

function Money.Pay(cid, account, amount, reason)
    if amount <= 0 then return true end
    local P = JJ.GetPlayerByIdentifier(cid)
    if P then return P.addMoney(account, amount, 'race-' .. reason) == true end
    return DB.CreditOffline(cid, account, amount)
end

--- Devuelve una retencion a su dueno (jugador o crew). false si ya estaba liquidada.
function Money.RefundEntry(e)
    if e.id and not DB.DeleteEscrow(e.id) then return false end
    if e.kind == 'crew' then return CrewLink.AddMoney(e.crewId, e.amount, 'race refund') end
    return Money.Pay(e.cid, e.account, e.amount, 'refund')
end

--- Convierte la retencion en bote de premios (no se devuelve). false si ya estaba liquidada.
function Money.Consume(e)
    if e.id then return DB.DeleteEscrow(e.id) end
    return true
end

--- Al arrancar: reembolsa todo lo que quedo retenido por una caida del servidor
function Money.RecoverEscrows()
    local rows = DB.GetEscrows()
    for _, r in ipairs(rows) do
        local amount = tonumber(r.amount) or 0
        if DB.DeleteEscrow(r.id) then
            local ok
            if r.kind == 'crew' then
                ok = CrewLink.AddMoney(tonumber(r.owner), amount, 'race recovery')
            else
                ok = Money.Pay(r.owner, r.account, amount, 'recovery')
            end
            Logs.Add({ name = 'system' }, 'escrow_recover', { kind = r.kind, owner = r.owner, amount = amount, ref = r.ref, ok = ok == true }, true)
        end
    end
    if #rows > 0 then print(('^3[races]^7 %d retenciones recuperadas tras reinicio'):format(#rows)) end
end

-- Parametros -----------------------------------------------------------------------------------

--- Valida vueltas y clase para un circuito. Devuelve (laps, class) o (nil, codigoError)
function Lobbies.CheckRaceParams(track, laps, class)
    if Utils.IsPointToPoint(track.category) then
        laps = 1
    else
        laps = Utils.Int(laps == nil and track.lapsDefault or laps, 1, Settings.maxLaps)
        if not laps then return nil, 'laps_invalid' end
    end
    if class == nil then class = track.vehicleClass end
    if type(class) ~= 'string' or not Config.VehicleClasses[class] then return nil, 'class_invalid' end
    if track.vehicleClass ~= 'any' and class ~= track.vehicleClass then return nil, 'class_invalid' end
    if not Utils.Contains(Settings.allowedClasses, class) then return nil, 'class_invalid' end
    return laps, class
end

-- Consultas ---------------------------------------------------------------------------------------------

function Lobbies.Get(id) return Lobbies.list[id] end
function Lobbies.OfPlayer(src) return Lobbies.byPlayer[src] end

local function countTeam(lobby, team)
    local n = 0
    for _, p in pairs(lobby.players) do
        if p.team == team then n = n + 1 end
    end
    return n
end

local function activeCount(lobby)
    local n = 0
    for _, p in pairs(lobby.players) do
        if not p.left then n = n + 1 end
    end
    return n
end

function Lobbies.PrizePool(lobby)
    local entries, extra = 0, 0
    for _, e in ipairs(lobby.escrows) do
        if e.reason == 'entry' then entries = entries + e.amount end
        if e.reason == 'host_prize' then extra = extra + e.amount end
    end
    local commission = math.floor(entries * Settings.commissionPct / 100)
    local base = lobby.basePrize or 0
    return { entries = entries, commission = commission, extra = extra, base = base, total = entries - commission + extra + base }
end

local function crewBrief(c)
    if not c then return nil end
    return { id = c.id, name = c.name, tag = c.tag, color = c.color }
end

local STATE_VIEW = { open = 'open', countdown = 'countdown', running = 'running' }

--- Vista de la sala para la NUI (sin datos sensibles)
function Lobbies.View(lobby, src)
    local players = {}
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and not p.left then
            players[#players + 1] = {
                pid = s, name = p.name, ready = p.ready or p.cid == lobby.hostCid, host = p.cid == lobby.hostCid, team = p.team,
                crew = p.crew and { tag = p.crew.tag, color = p.crew.color, name = p.crew.name } or nil, you = s == src,
            }
        end
    end
    local track = lobby.track
    local pool = Lobbies.PrizePool(lobby)
    return {
        id = lobby.id, name = lobby.name, mode = lobby.mode, state = lobby.checking and 'checking' or STATE_VIEW[lobby.state] or lobby.state,
        trackId = track.id, trackName = track.name, category = track.category, difficulty = track.difficulty, collisions = track.collisions,
        laps = lobby.laps, vehicleClass = lobby.vehicleClass, entryFee = lobby.entryFee, extraPrize = pool.extra, prizePool = pool.total,
        private = lobby.private, maxPlayers = lobby.maxPlayers, official = lobby.mode == 'official', hostName = lobby.hostName,
        isHost = lobby.hostSrc ~= nil and lobby.hostSrc == src, you = src,
        crewVs = lobby.crew and {
            a = crewBrief(lobby.crew.a.info), b = crewBrief(lobby.crew.b.info), size = lobby.crew.size, stake = lobby.crew.stake,
            formula = Settings.crewVsFormula,
        } or nil,
        players = players,
    }
end

--- Resumen para el listado de carreras abiertas
function Lobbies.Summary(lobby)
    local v = Lobbies.View(lobby, 0)
    v.players = nil
    v.playerCount = activeCount(lobby)
    return v
end

--- Envia la vista actualizada a todos los miembros
function Lobbies.Push(lobby)
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and not p.left then TriggerClientEvent('races:client:lobby', s, Lobbies.View(lobby, s)) end
    end
end

--- Listado de carreras abiertas visible para un jugador
function Lobbies.ListOpen(src, cid)
    local out = {}
    local now = GetGameTimer()
    for _, lobby in pairs(Lobbies.list) do
        if lobby.state == 'open' and lobby.mode ~= 'test' then
            local invited = lobby.invited[cid] and lobby.invited[cid] > now
            if not lobby.private or invited or lobby.hostSrc == src then
                local s = Lobbies.Summary(lobby)
                s.invited = invited == true
                out[#out + 1] = s
            end
        end
    end
    table.sort(out, function(a, b)
        if a.official ~= b.official then return a.official end
        return a.id > b.id
    end)
    return out
end

--- Invitaciones vigentes de un jugador
function Lobbies.InvitesFor(cid)
    local out, now = {}, GetGameTimer()
    for _, lobby in pairs(Lobbies.list) do
        local exp = lobby.invited[cid]
        if exp and exp > now and lobby.state == 'open' then
            out[#out + 1] = { lobbyId = lobby.id, name = lobby.name, trackName = lobby.track.name, hostName = lobby.hostName, expiresIn = math.ceil((exp - now) / 1000) }
        end
    end
    return out
end

function Lobbies.AdminList()
    local out = {}
    for _, lobby in pairs(Lobbies.list) do
        local v = Lobbies.View(lobby, 0)
        v.state = lobby.checking and 'checking' or lobby.state
        v.startedAt = lobby.startedAt and math.floor((GetGameTimer() - lobby.startedAt) / 1000) or nil
        for _, pl in ipairs(v.players) do
            local p = lobby.players[pl.pid]
            pl.status = p and p.status or 'waiting'
            pl.strikes = p and p.strikes or 0
            pl.paid = 0
            for _, e in ipairs(lobby.escrows) do
                if e.owner == pl.pid and e.reason == 'entry' then pl.paid = e.amount end
            end
        end
        out[#out + 1] = v
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

-- Construccion ------------------------------------------------------------------------------------------

local function newLobby(key, mode, track, laps, class)
    local id = Lobbies.nextId
    Lobbies.nextId = id + 1
    return {
        id = id, key = key, mode = mode, state = 'open', track = track, laps = laps, vehicleClass = class,
        entryFee = 0, basePrize = 0, private = false, name = track.name, players = {}, order = {}, escrows = {},
        invited = {}, createdAt = GetGameTimer(), finishCount = 0, maxPlayers = math.min(Settings.maxPlayers, #track.grid),
    }
end

local function addPlayer(lobby, src, P)
    local cid = P.identifier
    local p = {
        src = src, cid = cid, name = Perms.PlayerName(P), crew = CrewLink.Enabled() and CrewLink.Tag(src) or nil,
        ready = false, status = 'waiting', strikes = 0, flags = {}, progress = 0, progTimes = {}, lapTimes = {},
    }
    if lobby.mode == 'crew' then
        p.team = (p.crew and p.crew.id == lobby.crew.a.id) and 'A' or 'B'
    end
    lobby.players[src] = p
    lobby.order[#lobby.order + 1] = src
    Lobbies.byPlayer[src] = lobby
    return p
end

local function register(lobby)
    Lobbies.list[lobby.id] = lobby
    local ttl = (lobby.mode == 'crew' and Config.CrewVs.joinWindowSeconds * 1000) or (lobby.mode == 'official' and Config.Events.joinWindowSeconds * 1000 + 60000)
        or Settings.openLobbyMinutes * 60000
    SetTimeout(ttl, function()
        if Lobbies.list[lobby.id] == lobby and lobby.state == 'open' then Lobbies.Cancel(lobby, 'expired') end
    end)
end

--- Crea una carrera abierta. data = { trackId, laps, vehicleClass, entryFee, extraPrize, private, name }
function Lobbies.Create(src, data)
    if Lobbies.byPlayer[src] or Lobbies.busy[src] then return false, 'already_in_race' end
    local P = JJ.GetPlayer(src)
    if not P then return false, 'generic' end

    local track = Tracks.byId[data.trackId]
    if not track or not track.enabled then return false, 'track_not_found' end
    local laps, class = Lobbies.CheckRaceParams(track, data.laps, data.vehicleClass)
    if not laps then return false, class end

    local fee = Utils.Int(data.entryFee == nil and 0 or data.entryFee, 0, Settings.entryFeeMax)
    local extra = Utils.Int(data.extraPrize == nil and 0 or data.extraPrize, 0, Settings.extraPrizeMax)
    local private = data.private == true
    local name = data.name ~= nil and Utils.PlainStr(data.name, Config.Lobby.nameMax) or track.name
    if not fee or not extra or not name or name == '' then return false, 'invalid_data' end

    local lobby = newLobby(Lobbies.NewKey(), 'open', track, laps, class)
    lobby.entryFee, lobby.extraPrize, lobby.private, lobby.name = fee, extra, private, name
    lobby.basePrize = track.basePrize
    lobby.hostCid, lobby.hostSrc, lobby.hostName = P.identifier, src, Perms.PlayerName(P)

    Lobbies.busy[src] = true
    local p = addPlayer(lobby, src, P)
    p.charging = true

    local failure
    if fee > 0 then
        local ok, id = Money.Charge(src, Config.EntryAccount, fee, 'entry', lobby.key)
        if ok then lobby.escrows[#lobby.escrows + 1] = { kind = 'player', cid = lobby.hostCid, owner = src, account = Config.EntryAccount, amount = fee, id = id, reason = 'entry' }
        else failure = id end
    end
    if not failure and extra > 0 then
        local ok, id = Money.Charge(src, Config.EntryAccount, extra, 'host_prize', lobby.key)
        if ok then lobby.escrows[#lobby.escrows + 1] = { kind = 'player', cid = lobby.hostCid, owner = src, account = Config.EntryAccount, amount = extra, id = id, reason = 'host_prize' }
        else failure = id end
    end
    p.charging = nil
    Lobbies.busy[src] = nil

    -- La sala no esta registrada hasta cobrar; si el anfitrion se desconecto mientras tanto, se devuelve todo
    if failure or lobby.state ~= 'open' then
        Lobbies.byPlayer[src] = nil
        for _, e in ipairs(lobby.escrows) do Money.RefundEntry(e) end
        lobby.escrows = {}
        return false, failure or 'generic'
    end

    register(lobby)
    Logs.Add({ cid = lobby.hostCid, name = lobby.hostName }, 'race_create', { lobby = lobby.id, track = track.name, laps = laps, fee = fee, extra = extra, private = private }, false)
    Lobbies.Push(lobby)
    return true, Lobbies.View(lobby, src)
end

--- Sala de un reto crew vs crew. `stakes` = { { crewId, escrowId } } ya retenidas.
function Lobbies.CreateCrewLobby(key, ch, hostP, guestP, stakes)
    local track = Tracks.byId[ch.trackId]
    if not track or not hostP or not guestP then return nil, 'generic' end
    local lobby = newLobby(key, 'crew', track, ch.laps, ch.vehicleClass)
    lobby.maxPlayers = ch.teamSize * 2
    lobby.basePrize = track.basePrize
    local hostSrc, guestSrc = hostP.source, guestP.source
    lobby.hostCid, lobby.hostSrc, lobby.hostName = hostP.identifier, hostSrc, Perms.PlayerName(hostP)
    lobby.name = track.name
    lobby.crew = {
        a = { id = ch.fromCrew, info = CrewLink.GetCrew(ch.fromCrew) },
        b = { id = ch.toCrew, info = CrewLink.GetCrew(ch.toCrew) },
        size = ch.teamSize, stake = ch.stake,
    }
    for _, s in ipairs(stakes) do
        lobby.escrows[#lobby.escrows + 1] = { kind = 'crew', crewId = s.crewId, amount = ch.stake, id = s.escrowId, reason = 'stake' }
    end
    addPlayer(lobby, hostSrc, hostP)
    addPlayer(lobby, guestSrc, guestP)
    register(lobby)

    -- Avisa a los miembros conectados de ambos crews
    for _, crewId in ipairs({ ch.fromCrew, ch.toCrew }) do
        for _, m in ipairs(CrewLink.GetMembers(crewId)) do
            local mp = JJ.GetPlayerByIdentifier(m.citizenid)
            if mp and not Lobbies.byPlayer[mp.source] then
                Lobbies.Notify(mp.source, L('n_crew_lobby_open', lobby.crew.a.info.tag, lobby.crew.b.info.tag, track.name), 'primary', 9000)
                TriggerClientEvent('races:client:refresh', mp.source)
            end
        end
    end
    Lobbies.Push(lobby)
    return lobby
end

--- Carrera de prueba de un administrador (sin dinero, records ni cubo de enrutado)
function Lobbies.CreateTest(src, track)
    if Lobbies.byPlayer[src] or Lobbies.busy[src] then return false, 'already_in_race' end
    local P = JJ.GetPlayer(src)
    if not P then return false, 'generic' end
    local lobby = newLobby(Lobbies.NewKey(), 'test', track, 1, track.vehicleClass)
    lobby.maxPlayers = 1
    lobby.hostCid, lobby.hostSrc, lobby.hostName = P.identifier, src, Perms.PlayerName(P)
    addPlayer(lobby, src, P).ready = true
    register(lobby)
    Lobbies.Push(lobby)
    Lobbies.RequestStart(lobby, nil)
    return true, Lobbies.View(lobby, src)
end

--- Sala oficial de un evento programado (premio pagado por el servidor)
function Lobbies.CreateOfficial(event, track)
    local laps, class = Lobbies.CheckRaceParams(track, event.laps, event.vehicleClass)
    if not laps then laps, class = event.laps, event.vehicleClass end
    local lobby = newLobby(Lobbies.NewKey(), 'official', track, laps, class)
    lobby.eventId = event.id
    lobby.name = event.title
    lobby.basePrize = event.prize
    lobby.hostName = L('official_host')
    register(lobby)
    SetTimeout(Config.Events.joinWindowSeconds * 1000, function()
        if Lobbies.list[lobby.id] ~= lobby or lobby.state ~= 'open' then return end
        if activeCount(lobby) < Config.Events.minPlayers then
            Lobbies.Cancel(lobby, 'not_enough_players')
        else
            Lobbies.RequestStart(lobby, nil)
        end
    end)
    return lobby
end

-- Union / abandono ------------------------------------------------------------------------------------

function Lobbies.Join(src, lobbyId, code)
    if Lobbies.byPlayer[src] or Lobbies.busy[src] then return false, 'already_in_race' end
    local lobby = Lobbies.list[lobbyId]
    if not lobby or lobby.state ~= 'open' or lobby.mode == 'test' then return false, 'race_not_found' end
    if lobby.checking then return false, 'race_starting' end
    local P = JJ.GetPlayer(src)
    if not P then return false, 'generic' end
    local cid = P.identifier
    if activeCount(lobby) >= lobby.maxPlayers then return false, 'race_full' end

    if lobby.private then
        local exp = lobby.invited[cid]
        if not exp or exp <= GetGameTimer() then return false, 'private_race' end
    end

    if lobby.mode == 'crew' then
        local tag = CrewLink.Enabled() and CrewLink.Tag(src) or nil
        if not tag or (tag.id ~= lobby.crew.a.id and tag.id ~= lobby.crew.b.id) then return false, 'not_crew_member' end
        local team = tag.id == lobby.crew.a.id and 'A' or 'B'
        if countTeam(lobby, team) >= lobby.crew.size then return false, 'team_full' end
    end

    Lobbies.busy[src] = true
    local p = addPlayer(lobby, src, P)
    local fee = lobby.entryFee
    if fee > 0 then
        p.charging = true
        local ok, id = Money.Charge(src, Config.EntryAccount, fee, 'entry', lobby.key)
        p.charging = nil
        if not ok then
            Lobbies.Remove(lobby, src)
            Lobbies.busy[src] = nil
            return false, id
        end
        local e = { kind = 'player', cid = cid, owner = src, account = Config.EntryAccount, amount = fee, id = id, reason = 'entry' }
        -- La sala pudo cancelarse o el jugador ser expulsado mientras se cobraba
        if lobby.state ~= 'open' or lobby.players[src] ~= p then
            Lobbies.busy[src] = nil
            Money.RefundEntry(e)
            return false, 'race_not_found'
        end
        lobby.escrows[#lobby.escrows + 1] = e
    end
    Lobbies.busy[src] = nil
    lobby.invited[cid] = nil
    Lobbies.Push(lobby)
    return true, Lobbies.View(lobby, src)
end

--- Quita a un jugador de la estructura de la sala (sin dinero ni avisos)
function Lobbies.Remove(lobby, src)
    lobby.players[src] = nil
    for i, s in ipairs(lobby.order) do
        if s == src then table.remove(lobby.order, i) break end
    end
    if Lobbies.byPlayer[src] == lobby then Lobbies.byPlayer[src] = nil end
end

local function refundPlayerEntry(lobby, src)
    for i = #lobby.escrows, 1, -1 do
        local e = lobby.escrows[i]
        if e.owner == src and e.reason == 'entry' then
            table.remove(lobby.escrows, i)
            Money.RefundEntry(e)
        end
    end
end

local function restoreBucket(p)
    if not p.bucketSet then return end
    p.bucketSet = nil
    if GetPlayerPed(p.src) ~= 0 then SetPlayerRoutingBucket(p.src, p.prevBucket or 0) end
    if p.vehicle and p.vehicle.entity and DoesEntityExist(p.vehicle.entity) then
        SetEntityRoutingBucket(p.vehicle.entity, p.prevBucket or 0)
    end
end

--- Un jugador sale de la sala (voluntariamente, expulsado o desconectado)
---@param reason string 'leave' | 'kick' | 'drop'
function Lobbies.RemovePlayer(lobby, src, reason)
    local p = lobby.players[src]
    if not p then return false, 'not_in_race' end
    if p.charging then return false, 'busy' end

    if lobby.state == 'open' or lobby.state == 'countdown' then
        if lobby.mode == 'test' or p.cid == lobby.hostCid then
            Lobbies.Cancel(lobby, reason == 'drop' and 'host_dropped' or 'host_left')
            return true
        end
        restoreBucket(p)
        Lobbies.Remove(lobby, src)
        if reason ~= 'drop' then
            TriggerClientEvent('races:client:abort', src, reason)
            TriggerClientEvent('races:client:lobby', src, false)
        end
        refundPlayerEntry(lobby, src)
        local min = lobby.mode == 'test' and 1 or math.max(1, Settings.minPlayersToStart)
        if lobby.state == 'countdown' and activeCount(lobby) < min then
            Lobbies.Cancel(lobby, 'not_enough_players')
        elseif activeCount(lobby) == 0 then
            Lobbies.Cancel(lobby, 'empty')
        else
            Lobbies.Push(lobby)
        end
        return true
    end

    if lobby.state == 'running' then
        -- Abandono: cuenta como DNF y no se devuelve la inscripcion
        if reason == 'kick' then
            p.status, p.dqReason = 'dq', 'kicked'
        elseif p.status == 'racing' then
            p.status = 'dnf'
        end
        p.left = true
        restoreBucket(p)
        if Lobbies.byPlayer[src] == lobby then Lobbies.byPlayer[src] = nil end
        if reason ~= 'drop' then
            TriggerClientEvent('races:client:abort', src, reason)
            TriggerClientEvent('races:client:lobby', src, false)
        end
        Lobbies.CheckEnd(lobby)
        return true
    end
    return false, 'race_not_found'
end

function Lobbies.Leave(src)
    local lobby = Lobbies.byPlayer[src]
    if not lobby then return false, 'not_in_race' end
    return Lobbies.RemovePlayer(lobby, src, 'leave')
end

function Lobbies.OnDrop(src)
    Lobbies.busy[src] = nil
    local lobby = Lobbies.byPlayer[src]
    if lobby and lobby.players[src] then
        lobby.players[src].charging = nil
        Lobbies.RemovePlayer(lobby, src, 'drop')
    end
end

function Lobbies.SetReady(src, ready)
    local lobby = Lobbies.byPlayer[src]
    if not lobby or lobby.state ~= 'open' or lobby.checking then return false, 'race_not_found' end
    local p = lobby.players[src]
    if not p then return false, 'not_in_race' end
    p.ready = ready == true
    Lobbies.Push(lobby)
    return true
end

--- Expulsa a un piloto (anfitrion en sala abierta o administrador en cualquier estado)
function Lobbies.Kick(lobby, targetPid, byAdmin, actorSrc, refund)
    local p = lobby.players[targetPid]
    if not p or p.left then return false, 'target_not_found' end
    if not byAdmin then
        if lobby.state ~= 'open' or lobby.hostSrc ~= actorSrc then return false, 'no_permission' end
        if targetPid == actorSrc then return false, 'cannot_self' end
    end
    if lobby.state == 'running' and refund then refundPlayerEntry(lobby, targetPid) end
    Lobbies.RemovePlayer(lobby, targetPid, 'kick')
    Lobbies.Notify(targetPid, L('n_kicked'), 'error', 8000)
    return true
end

function Lobbies.Invite(src, targetSrc)
    local lobby = Lobbies.byPlayer[src]
    if not lobby or lobby.state ~= 'open' or lobby.hostSrc ~= src then return false, 'no_permission' end
    local target = JJ.GetPlayer(targetSrc)
    if not target then return false, 'target_not_found' end
    if targetSrc == src then return false, 'cannot_self' end
    if Lobbies.byPlayer[targetSrc] then return false, 'target_busy' end
    lobby.invited[target.identifier] = GetGameTimer() + Config.Lobby.inviteExpirySeconds * 1000
    Lobbies.Notify(targetSrc, L('n_invited', lobby.hostName, lobby.track.name), 'primary', 9000)
    TriggerClientEvent('races:client:refresh', targetSrc)
    return true
end

-- Cancelacion / limpieza -------------------------------------------------------------------------------

--- Libera jugadores, buckets y sala (no toca dinero)
function Lobbies.Cleanup(lobby, notifyKey)
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p then
            restoreBucket(p)
            if Lobbies.byPlayer[s] == lobby then Lobbies.byPlayer[s] = nil end
            if not p.left then
                TriggerClientEvent('races:client:end', s)
                TriggerClientEvent('races:client:lobby', s, false)
                if notifyKey then Lobbies.Notify(s, L(notifyKey), 'error', 7000) end
            end
        end
    end
    if lobby.bucket then Lobbies.usedBuckets[lobby.bucket] = nil end
    Lobbies.list[lobby.id] = nil
    if lobby.eventId then
        DB.SetEventStatus(lobby.eventId, lobby.state == 'finished' and 'done' or 'cancelled')
        Events.Schedule()
    end
end

--- Cancela una carrera y devuelve todas las inscripciones, bolsas y apuestas
function Lobbies.Cancel(lobby, reason, actor)
    if lobby.state == 'cancelled' or lobby.state == 'finished' or lobby.state == 'finishing' then return false end
    lobby.state = 'cancelled'
    lobby.checking = false
    local escrows = lobby.escrows
    lobby.escrows = {}
    local keys = { host_left = 'n_cancel_host', host_dropped = 'n_cancel_host', expired = 'n_cancel_expired', not_enough_players = 'n_cancel_players', empty = 'n_cancel_players', admin = 'n_cancel_admin' }
    Lobbies.Cleanup(lobby, lobby.mode ~= 'test' and (keys[reason] or 'n_cancel_generic') or nil)
    local refunded = 0
    for _, e in ipairs(escrows) do
        if Money.RefundEntry(e) then refunded = refunded + 1 end
    end
    Logs.Add(actor or { name = 'system' }, 'race_cancel', { lobby = lobby.id, track = lobby.track.name, reason = reason, refunded = refunded }, actor ~= nil)
    return true
end

-- Inicio: comprobacion de vehiculos -> cuenta atras -> salida ---------------------------------------

local function readyToStart(lobby, auto)
    local count = activeCount(lobby)
    local min = lobby.mode == 'test' and 1 or math.max(1, Settings.minPlayersToStart)
    if count < min then return false, 'not_enough_players' end
    if lobby.mode == 'crew' then
        local a, b = countTeam(lobby, 'A'), countTeam(lobby, 'B')
        if a < 1 or a ~= b then return false, 'teams_unbalanced' end
    end
    if not auto then
        for _, p in pairs(lobby.players) do
            if p.cid ~= lobby.hostCid and not p.ready then return false, 'players_not_ready' end
        end
    end
    return true
end

--- Inicia el proceso de salida. `hostSrc` nil = arranque automatico (eventos y pruebas).
function Lobbies.RequestStart(lobby, hostSrc)
    if lobby.state ~= 'open' or lobby.checking then return false, 'race_starting' end
    if hostSrc and lobby.hostSrc ~= hostSrc then return false, 'no_permission' end
    local ok, err = readyToStart(lobby, hostSrc == nil)
    if not ok then return false, err end

    lobby.checking = true
    lobby.checkToken = (lobby.checkToken or 0) + 1
    lobby.checkResp = {}
    local token = lobby.checkToken
    for _, s in ipairs(lobby.order) do
        TriggerClientEvent('races:client:vehicleCheck', s, lobby.id, token)
    end
    Lobbies.Push(lobby)
    SetTimeout(Config.Lobby.vehicleCheckTimeoutMs, function() Lobbies.FinishCheck(lobby, token) end)
    return true
end

--- Respuesta del cliente a la comprobacion de vehiculo
function Lobbies.OnVehicleReport(src, lobbyId, token, model, class, display)
    local lobby = Lobbies.byPlayer[src]
    if not lobby or lobby.id ~= lobbyId or not lobby.checking or lobby.checkToken ~= token then return end
    lobby.checkResp[src] = { model = model, class = class, display = display }
    for s in pairs(lobby.players) do
        if not lobby.checkResp[s] then return end
    end
    Lobbies.FinishCheck(lobby, token)
end

local function validDisplay(v)
    if type(v) ~= 'string' or #v > 40 or not v:match('^[%w_%- ]+$') then return 'unknown' end
    return v
end

function Lobbies.FinishCheck(lobby, token)
    if lobby.state ~= 'open' or not lobby.checking or lobby.checkToken ~= token then return end
    lobby.checking = false

    local failures = {}
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        local resp = lobby.checkResp[s]
        local err
        if not resp then
            err = 'vehicle_invalid'
        else
            local model = Utils.NormHash(resp.model)
            local veh = Validation.PlayerVehicle(s)
            if Validation.HasServerPos() then
                if not veh or not veh.driver then err = 'vehicle_missing'
                elseif veh.model ~= model then err = 'vehicle_invalid' end
            end
            if not err then
                local ok, e = Validation.VehicleAllowed(lobby.vehicleClass, resp.model, resp.class)
                if not ok then err = e end
            end
            if not err then
                p.vehicle = { model = model, class = resp.class, display = validDisplay(resp.display), entity = veh and veh.entity or nil, netId = veh and veh.netId or nil }
            end
        end
        if err then failures[#failures + 1] = { src = s, name = p.name, err = err } end
    end

    if #failures > 0 then
        if lobby.mode == 'official' then
            for _, f in ipairs(failures) do
                Lobbies.RemovePlayer(lobby, f.src, 'kick')
                Lobbies.Notify(f.src, L('err_' .. f.err), 'error', 8000)
            end
            if lobby.state == 'open' and activeCount(lobby) >= Config.Events.minPlayers then
                return Lobbies.BeginCountdown(lobby)
            elseif lobby.state == 'open' then
                return Lobbies.Cancel(lobby, 'not_enough_players')
            end
            return
        end
        local target = lobby.hostSrc or failures[1].src
        for _, f in ipairs(failures) do
            Lobbies.Notify(f.src, L('err_' .. f.err), 'error', 8000)
            if lobby.hostSrc and f.src ~= lobby.hostSrc then
                Lobbies.Notify(target, L('n_vehicle_failed', f.name), 'error', 8000)
            end
        end
        if lobby.mode == 'test' then Lobbies.Cancel(lobby, 'vehicle') else Lobbies.Push(lobby) end
        return
    end
    Lobbies.BeginCountdown(lobby)
end

function Lobbies.AllocBucket()
    local b = Config.BucketBase
    while Lobbies.usedBuckets[b] do b = b + 1 end
    Lobbies.usedBuckets[b] = true
    return b
end

function Lobbies.BeginCountdown(lobby)
    if lobby.state ~= 'open' then return end
    local track = lobby.track
    lobby.state = 'countdown'

    -- Orden de parrilla: por orden de union; en retos se alternan los equipos
    local ordered = {}
    if lobby.mode == 'crew' then
        local a, b = {}, {}
        for _, s in ipairs(lobby.order) do
            local list = lobby.players[s].team == 'A' and a or b
            list[#list + 1] = s
        end
        for i = 1, math.max(#a, #b) do
            if a[i] then ordered[#ordered + 1] = a[i] end
            if b[i] then ordered[#ordered + 1] = b[i] end
        end
    else
        for _, s in ipairs(lobby.order) do ordered[#ordered + 1] = s end
    end

    local useBucket = Settings.useRoutingBuckets and lobby.mode ~= 'test'
    if useBucket then lobby.bucket = Lobbies.AllocBucket() end

    local racers = {}
    for slot, s in ipairs(ordered) do
        local p = lobby.players[s]
        p.slot = slot
        p.status = 'ready'
        if useBucket then
            p.prevBucket = GetPlayerRoutingBucket(s)
            SetPlayerRoutingBucket(s, lobby.bucket)
            if p.vehicle and p.vehicle.entity then SetEntityRoutingBucket(p.vehicle.entity, lobby.bucket) end
            p.bucketSet = true
        end
        racers[#racers + 1] = {
            pid = s, name = p.name, tag = p.crew and p.crew.tag or nil, color = p.crew and p.crew.color or nil,
            team = p.team, netId = p.vehicle and p.vehicle.netId or nil, slot = slot,
        }
    end

    local countdownMs = Settings.countdownSeconds * 1000
    lobby.goAt = GetGameTimer() + countdownMs
    for _, s in ipairs(ordered) do
        local g = track.grid[lobby.players[s].slot]
        TriggerClientEvent('races:client:prepare', s, {
            lobbyId = lobby.id, trackName = track.name, laps = lobby.laps, mode = lobby.mode, slot = g, countdown = countdownMs,
            collisions = track.collisions, checkpoints = track.checkpoints, normals = #track.normals, racers = racers,
            pit = Config.Pit.enabled, you = s,
        })
    end
    Lobbies.Push(lobby)
    SetTimeout(countdownMs, function() Lobbies.Go(lobby) end)
end

function Lobbies.Go(lobby)
    if lobby.state ~= 'countdown' then return end
    if activeCount(lobby) == 0 then return Lobbies.Cancel(lobby, 'empty') end
    local now = GetGameTimer()
    lobby.state = 'running'
    lobby.startedAt = now

    local racers = {}
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and not p.left then
            p.status = 'racing'
            p.nextSeq, p.lap = 1, 1
            p.progress = 0
            p.progTimes = { [0] = 0 }
            local slot = lobby.track.grid[p.slot]
            p.lastCp = { x = slot.x, y = slot.y, z = slot.z, radius = 0.0 }
            p.lastCpAt, p.lapStart = now, now
            p.lastPos, p.lastSampleAt = Validation.PlayerPos(s), now
            racers[#racers + 1] = { pid = s, netId = p.vehicle and p.vehicle.netId or nil }
        end
    end
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and not p.left then TriggerClientEvent('races:client:go', s, { racers = racers }) end
    end

    if lobby.mode ~= 'test' and lobby.track.timeLimit > 0 then
        SetTimeout(lobby.track.timeLimit * 1000, function() Lobbies.TimeoutRemaining(lobby, 'time_limit') end)
    end
    if lobby.eventId then DB.SetEventStatus(lobby.eventId, 'running') end
    Lobbies.Push(lobby)
    Lobbies.EnsureLoop()
end

-- Progreso -------------------------------------------------------------------------------------------------

local function sendProgress(lobby, p, extra)
    local data = {
        lap = p.lap, nextSeq = p.nextSeq, bestLap = p.bestLap, total = GetGameTimer() - lobby.startedAt,
        status = p.status,
    }
    if extra then for k, v in pairs(extra) do data[k] = v end end
    TriggerClientEvent('races:client:progress', p.src, data)
end

function Lobbies.Finish(lobby, p, now)
    p.status = 'finished'
    p.finishTime = now - lobby.startedAt
    lobby.finishCount = lobby.finishCount + 1
    p.finishOrder = lobby.finishCount
    Validation.FinalCheck(lobby, p)
    sendProgress(lobby, p, { finished = true, finishTime = p.finishTime, finishOrder = p.finishOrder })

    if lobby.finishCount == 1 and lobby.mode ~= 'test' then
        SetTimeout(Settings.finishGraceSeconds * 1000, function() Lobbies.TimeoutRemaining(lobby, 'grace') end)
        for _, s in ipairs(lobby.order) do
            local o = lobby.players[s]
            if o and o.status == 'racing' then Lobbies.Notify(s, L('n_first_finish', p.name, Settings.finishGraceSeconds), 'primary', 6000) end
        end
    end
    Lobbies.CheckEnd(lobby)
end

--- Procesa un checkpoint reportado. kind: 'cp' | 'sc' | 'pit'
function Lobbies.OnCheckpoint(src, kind, idx)
    local lobby = Lobbies.byPlayer[src]
    if not lobby or lobby.state ~= 'running' then return end
    local p = lobby.players[src]
    if not p or p.status ~= 'racing' then return end

    local track = lobby.track
    local cp = track.checkpoints[idx]
    local now = GetGameTimer()
    if not cp then
        if Validation.Strike(p, 'order', 1) == 'dq' then Lobbies.Disqualify(lobby, p, 'order') end
        return
    end

    local ok, reason, weight = Validation.Checkpoint(p, cp, kind, now)
    if reason then
        if Validation.Strike(p, reason, weight) == 'dq' then return Lobbies.Disqualify(lobby, p, reason) end
    end
    if not ok then
        sendProgress(lobby, p, { resync = true })
        return
    end

    if kind == 'pit' then
        local cd = Config.Pit.cooldownSeconds * 1000
        if not Config.Pit.enabled or (p.lastPit and now - p.lastPit < cd) then return end
        p.lastPit = now
        TriggerClientEvent('races:client:pit', src)
        return
    end

    local n = #track.normals
    p.nextSeq = kind == 'sc' and cp.linkTo or cp.seq + 1
    p.progress = (p.lap - 1) * n + (p.nextSeq - 1)
    p.progTimes[p.progress] = now - lobby.startedAt
    p.lastCp, p.lastCpAt = cp, now

    local extra
    if p.nextSeq > n then
        local lapTime = now - p.lapStart
        p.lapTimes[#p.lapTimes + 1] = lapTime
        if not p.bestLap or lapTime < p.bestLap then p.bestLap = lapTime end
        p.lapStart = now
        extra = { lapTime = lapTime }
        if p.lap >= lobby.laps then
            return Lobbies.Finish(lobby, p, now)
        end
        p.lap = p.lap + 1
        p.nextSeq = 1
    end
    sendProgress(lobby, p, extra)
end

function Lobbies.Disqualify(lobby, p, reason)
    if p.status ~= 'racing' then return end
    p.status = 'dq'
    p.dqReason = reason
    TriggerClientEvent('races:client:dq', p.src, reason)
    Lobbies.Notify(p.src, L('n_dq', L('dq_' .. reason)), 'error', 8000)
    Logs.Add({ cid = p.cid, name = p.name }, 'race_dq', { lobby = lobby.id, track = lobby.track.name, reason = reason, strikes = p.strikes }, false)
    Lobbies.CheckEnd(lobby)
end

--- Marca como DNF a quienes sigan corriendo (limite de tiempo o fin de gracia)
function Lobbies.TimeoutRemaining(lobby, why)
    if lobby.state ~= 'running' then return end
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and p.status == 'racing' then
            p.status = 'dnf'
            p.dqReason = why
            TriggerClientEvent('races:client:dq', s, why)
        end
    end
    Lobbies.CheckEnd(lobby)
end

--- Cierra la carrera cuando ya nadie sigue en pista
function Lobbies.CheckEnd(lobby)
    if lobby.state ~= 'running' then return end
    for _, p in pairs(lobby.players) do
        if p.status == 'racing' then return end
    end
    lobby.state = 'finishing'
    CreateThread(function() Results.Close(lobby) end)
end

-- Clasificacion en vivo ----------------------------------------------------------------------------------------

local function distToNext(lobby, p)
    local cp = lobby.track.normals[p.nextSeq]
    if not cp or not p.lastPos then return 0.0 end
    return Utils.Dist3(p.lastPos, cp)
end

local function rankGroup(p)
    if p.status == 'finished' then return 1 end
    if p.status == 'racing' then return 2 end
    return 3
end

--- Lista ordenada de pilotos: meta, en pista (progreso y distancia) y el resto
function Lobbies.Standings(lobby)
    local list = {}
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p then list[#list + 1] = p end
    end
    table.sort(list, function(a, b)
        local ga, gb = rankGroup(a), rankGroup(b)
        if ga ~= gb then return ga < gb end
        if ga == 1 then return a.finishOrder < b.finishOrder end
        if a.progress ~= b.progress then return a.progress > b.progress end
        if ga == 2 then
            local da, db = distToNext(lobby, a), distToNext(lobby, b)
            if da ~= db then return da < db end
        end
        return a.src < b.src
    end)
    return list
end

local function timeAtProgress(leader, progress)
    for q = progress, leader.progress do
        local t = leader.progTimes[q]
        if t then return t end
    end
    return nil
end

local function gapToLeader(leader, p)
    if p == leader then return 0 end
    if p.status == 'finished' and leader.status == 'finished' then return p.finishTime - leader.finishTime end
    local own = p.progTimes[p.progress]
    local lead = own and timeAtProgress(leader, p.progress)
    if not own or not lead then return nil end
    return math.max(0, own - lead)
end

function Lobbies.PushStandings(lobby)
    local list = Lobbies.Standings(lobby)
    local leader = list[1]
    if not leader then return end
    local rows = {}
    for i = 1, math.min(#list, STANDINGS_ROWS) do
        local p = list[i]
        rows[i] = {
            pid = p.src, name = p.name, tag = p.crew and p.crew.tag or nil, color = p.crew and p.crew.color or nil,
            lap = p.lap or 1, finished = p.status == 'finished' or nil, out = (p.status == 'dnf' or p.status == 'dq') or nil,
        }
    end
    for i, p in ipairs(list) do
        if not p.left then
            TriggerClientEvent('races:client:standings', p.src, {
                pos = i, total = #list, gap = gapToLeader(leader, p), leader = leader.name, rows = rows,
            })
        end
    end
end

function Lobbies.Tick(lobby, now)
    for _, s in ipairs(lobby.order) do
        local p = lobby.players[s]
        if p and p.status == 'racing' then
            local action, reason = Validation.Sample(p, now)
            if action == 'dq' then Lobbies.Disqualify(lobby, p, reason) end
        end
    end
    if lobby.state == 'running' then Lobbies.PushStandings(lobby) end
end

--- Hilo unico: solo existe mientras haya alguna carrera en curso (0.00 ms en idle)
function Lobbies.EnsureLoop()
    if Lobbies.loopActive then return end
    Lobbies.loopActive = true
    CreateThread(function()
        while true do
            local any = false
            local now = GetGameTimer()
            for _, lobby in pairs(Lobbies.list) do
                if lobby.state == 'running' then
                    any = true
                    Lobbies.Tick(lobby, now)
                end
            end
            if not any then break end
            Wait(Config.HudInterval)
        end
        Lobbies.loopActive = false
    end)
end

-- Eventos programados ----------------------------------------------------------------------------------------------

function Events.Open(e)
    local track = Tracks.byId[e.track_id]
    if not track or not track.enabled then
        DB.SetEventStatus(e.id, 'cancelled')
        return
    end
    DB.SetEventStatus(e.id, 'open')
    local lobby = Lobbies.CreateOfficial({ id = e.id, title = e.title, laps = e.laps, vehicleClass = e.vehicle_class, prize = e.prize }, track)
    TriggerClientEvent('races:client:notify', -1, L('n_event_open', e.title, track.name, Config.Events.joinWindowSeconds // 60), 'primary', 15000)
    Logs.Add({ name = 'system' }, 'event_start', { event = e.id, title = e.title, track = track.name, prize = e.prize, lobby = lobby.id }, true)
end

function Events.Fire()
    local now = os.time()
    for _, e in ipairs(DB.GetPendingEvents()) do
        if e.scheduled_at <= now then
            if now - e.scheduled_at > 600 then
                DB.SetEventStatus(e.id, 'cancelled') -- demasiado tarde (el servidor estuvo apagado)
            else
                Events.Open(e)
            end
        end
    end
    Events.Schedule()
end

--- Programa un unico temporizador hacia el siguiente evento (sin bucles de sondeo)
function Events.Schedule()
    Events.token = Events.token + 1
    local token = Events.token
    local pending = DB.GetPendingEvents()
    local nextEvent = pending[1]
    if not nextEvent then return end
    local delay = math.max(0, nextEvent.scheduled_at - os.time()) * 1000 + 250
    SetTimeout(math.min(delay, 300000), function()
        if token == Events.token then Events.Fire() end
    end)
end

-- Eventos de red del cliente -----------------------------------------------------------------------------------------------

local reports = {}

local function reportAllowed(src)
    local now = GetGameTimer()
    local r = reports[src]
    if not r or now >= r.resetAt then
        reports[src] = { count = 1, resetAt = now + 1000 }
        return true
    end
    r.count = r.count + 1
    return r.count <= Config.AntiCheat.maxReportsPerSecond
end

RegisterNetEvent('races:server:checkpoint', function(kind, idx)
    local src = source
    if not reportAllowed(src) then return end
    idx = Utils.Int(idx, 1, 1000)
    if not idx or (kind ~= 'cp' and kind ~= 'sc' and kind ~= 'pit') then return end
    Lobbies.OnCheckpoint(src, kind, idx)
end)

RegisterNetEvent('races:server:vehicleCheck', function(lobbyId, token, model, class, display)
    local src = source
    if not reportAllowed(src) then return end
    lobbyId, token = Utils.Int(lobbyId, 1, 2147483647), Utils.Int(token, 1, 2147483647)
    if not lobbyId or not token or type(model) ~= 'number' or type(class) ~= 'number' then return end
    Lobbies.OnVehicleReport(src, lobbyId, token, model, class, display)
end)

-- Antes de que el framework guarde al jugador: un reembolso entra en su saldo y se guarda con él
AddEventHandler('jj:server:playerDropped', function(src)
    reports[src] = nil
    Lobbies.OnDrop(src)
end)
