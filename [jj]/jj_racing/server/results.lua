-- Cierre de carrera: posiciones, premios, puntos, records e integracion con crews.
-- Todo el reparto lo decide el servidor al cerrar la carrera; el cliente nunca interviene.

Results = { last = {} }

--- Reparte `total` entre las primeras posiciones segun Settings.prizeSplit (normalizado)
local function distribute(total, count)
    local split = Settings.prizeSplit
    local n = math.min(count, #split)
    local sum = 0
    for i = 1, n do sum = sum + split[i] end
    if n == 0 or sum <= 0 or total <= 0 then return {} end
    local out, given = {}, 0
    for i = 1, n do
        out[i] = math.floor(total * split[i] / sum)
        given = given + out[i]
    end
    out[1] = out[1] + (total - given) -- el redondeo se lo lleva el ganador
    return out
end

local function crewPointsFor(position)
    return Settings.crewPointsByPosition[position] or Settings.crewFinishPoints
end

local function dbStatus(p)
    if p.status == 'finished' then return 'finished' end
    if p.status == 'dq' then return 'dq' end
    return 'dnf'
end

-- Equipos (crew vs crew) -----------------------------------------------------------------------

--- Puntua a un equipo segun la formula configurada. Mayor es mejor.
local function teamScore(list, team, formula)
    local total = #list
    local points, positionSum, best, finishers = 0, 0, math.huge, 0
    for _, p in ipairs(list) do
        if p.team == team then
            if p.status == 'finished' then
                finishers = finishers + 1
                points = points + crewPointsFor(p.position)
                positionSum = positionSum + p.position
                if p.position < best then best = p.position end
            else
                positionSum = positionSum + total + 1 -- penalizacion por no terminar
            end
        end
    end
    if formula == 'positions' then return -positionSum, points end
    if formula == 'best' then return best == math.huge and -math.huge or -best, points end
    return points, points
end

--- Decide el resultado del reto. Devuelve 'A' | 'B' | nil (empate)
local function crewWinner(list)
    local formula = Settings.crewVsFormula
    local sa, ta = teamScore(list, 'A', formula)
    local sb, tb = teamScore(list, 'B', formula)
    if sa ~= sb then return sa > sb and 'A' or 'B', sa, sb end
    if formula == 'best' and ta ~= tb then return ta > tb and 'A' or 'B', sa, sb end
    return nil, sa, sb
end

local function settleCrewRace(lobby, list, summary)
    local finishers = 0
    for _, p in ipairs(list) do
        if p.status == 'finished' then finishers = finishers + 1 end
    end
    local escrows = lobby.escrows
    lobby.escrows = {}
    local winner, sa, sb = nil, 0, 0
    if finishers > 0 then winner, sa, sb = crewWinner(list) end
    summary.crewVs = { winner = winner, scoreA = sa ~= -math.huge and sa or nil, scoreB = sb ~= -math.huge and sb or nil, formula = Settings.crewVsFormula }

    if not winner then
        -- Empate (o nadie termino): se devuelven las apuestas
        for _, e in ipairs(escrows) do Money.RefundEntry(e) end
        return
    end

    local winnerCrew = winner == 'A' and lobby.crew.a or lobby.crew.b
    local pot = 0
    for _, e in ipairs(escrows) do
        if Money.Consume(e) then pot = pot + e.amount end
    end
    local commission = math.floor(pot * Settings.commissionPct / 100)
    local payout = pot - commission + (lobby.basePrize or 0)
    local reason = ('race:%s'):format(lobby.track.name)

    if payout > 0 then CrewLink.AddMoney(winnerCrew.id, payout, reason) end
    CrewLink.AddWin(winnerCrew.id, reason)
    if Settings.crewVsWinPoints > 0 then CrewLink.AddPoints(winnerCrew.id, Settings.crewVsWinPoints, reason) end
    summary.crewVs.winnerCrew = winnerCrew.info and { id = winnerCrew.id, name = winnerCrew.info.name, tag = winnerCrew.info.tag, color = winnerCrew.info.color } or nil
    summary.crewVs.payout = payout
    summary.crewVs.points = Settings.crewVsWinPoints
end

-- Carreras abiertas y oficiales ---------------------------------------------------------------

local function settleOpenRace(lobby, list, finishers, eligible, summary)
    local escrows = lobby.escrows
    lobby.escrows = {}

    if not eligible or #finishers == 0 then
        for _, e in ipairs(escrows) do Money.RefundEntry(e) end
        return
    end

    local pool
    local consumed = {}
    for _, e in ipairs(escrows) do
        if Money.Consume(e) then consumed[#consumed + 1] = e end
    end
    pool = Lobbies.PrizePool({ escrows = consumed, basePrize = lobby.basePrize })
    summary.rewards = { entries = pool.entries, commission = pool.commission, extra = pool.extra, base = pool.base, total = pool.total }

    local prizes = distribute(pool.total, #finishers)
    for i, p in ipairs(finishers) do
        local amount = prizes[i] or 0
        if amount > 0 then
            local share = 0
            if p.crew and CrewLink.Enabled() and Settings.crewPrizeSharePct > 0 then
                share = math.floor(amount * Settings.crewPrizeSharePct / 100)
                if share > 0 and not CrewLink.AddMoney(p.crew.id, share, ('race:%s prize share'):format(lobby.track.name)) then share = 0 end
            end
            local net = amount - share
            if Money.Pay(p.cid, Config.PrizeAccount, net, 'prize') then p.prize = net else p.prize = 0 end
        end
    end
end

--- Puntos de crew por piloto (carreras abiertas y oficiales). Escribe p.crewPoints.
local function awardCrewPoints(lobby, list, finishers)
    if not CrewLink.Enabled() then return end
    local byCrew = {}
    for _, p in ipairs(finishers) do
        if p.crew then
            local c = byCrew[p.crew.id]
            if not c then c = { total = 0, members = {} } byCrew[p.crew.id] = c end
            local pts = crewPointsFor(p.position)
            c.total = c.total + pts
            c.members[#c.members + 1] = { p = p, pts = pts }
        end
    end

    for crewId, c in pairs(byCrew) do
        local outsider = not Settings.crewRequireOutsider
        if not outsider then
            for _, p in ipairs(list) do
                if not p.crew or p.crew.id ~= crewId then outsider = true break end
            end
        end
        if outsider and c.total > 0 then
            local total, scale = c.total, 1.0
            local cap = Settings.crewMaxPointsPerRace
            if cap > 0 and total > cap then
                scale = cap / total
                total = cap
            end
            for _, m in ipairs(c.members) do m.p.crewPoints = math.floor(m.pts * scale) end
            CrewLink.AddPoints(crewId, total, ('race:%s #%d'):format(lobby.track.name, lobby.id))
        end
    end
end

-- Persistencia y records ---------------------------------------------------------------------------

local function saveResults(lobby, list)
    local track = lobby.track
    for _, p in ipairs(list) do
        p.flagReason = Validation.FlagReason(p)
        p.resultId = DB.InsertResult({
            raceKey = lobby.key, trackId = track.id, trackName = track.name, trackVersion = track.version, eventId = lobby.eventId,
            mode = lobby.mode, citizenid = p.cid, name = p.name, crewId = p.crew and p.crew.id or nil,
            crewTag = p.crew and p.crew.tag or '', crewColor = p.crew and p.crew.color or '', position = p.position,
            status = dbStatus(p), totalTime = p.finishTime or 0, bestLap = p.bestLap or 0, laps = #p.lapTimes,
            vehicleModel = p.vehicle and p.vehicle.display or '', vehicleClass = lobby.vehicleClass, prize = p.prize or 0,
            points = p.points or 0, crewPoints = p.crewPoints or 0, flagged = p.flagReason ~= nil, flagReason = p.flagReason or '',
        })
    end
end

local function submitRecords(lobby, list)
    local track = lobby.track
    for _, p in ipairs(list) do
        if p.bestLap and p.status ~= 'dq' and not p.flagReason then
            local improved, isRecord = Leaderboard.Submit(track, {
                citizenid = p.cid, name = p.name, crewId = p.crew and p.crew.id or nil, crewTag = p.crew and p.crew.tag or '',
                crewColor = p.crew and p.crew.color or '', bestLap = p.bestLap, vehicleModel = p.vehicle and p.vehicle.display or '',
                vehicleClass = lobby.vehicleClass, resultId = p.resultId,
            })
            p.personalBest = improved
            if isRecord then
                p.trackRecord = true
                Logs.Add({ cid = p.cid, name = p.name }, 'new_record', { track = track.name, time = Utils.FormatTime(p.bestLap), vehicle = p.vehicle and p.vehicle.display or '' }, false)
                if Config.AnnounceRecords then
                    TriggerClientEvent('races:client:notify', -1, L('n_new_record', track.name, p.name, Utils.FormatTime(p.bestLap)), 'success', 10000)
                end
            end
        end
    end
end

-- Cierre ------------------------------------------------------------------------------------------------------

local function buildPayload(lobby, list, summary)
    local rows = {}
    for i, p in ipairs(list) do
        rows[i] = {
            pid = p.src, position = p.position, name = p.name, status = dbStatus(p),
            crew = p.crew and { tag = p.crew.tag, color = p.crew.color } or nil, team = p.team,
            totalTime = p.finishTime, bestLap = p.bestLap, laps = #p.lapTimes, prize = p.prize or 0, points = p.points or 0,
            crewPoints = p.crewPoints or 0, flagged = p.flagReason ~= nil or nil, trackRecord = p.trackRecord or nil,
            vehicle = p.vehicle and p.vehicle.display or nil,
        }
    end
    return {
        raceKey = lobby.key, trackId = lobby.track.id, trackName = lobby.track.name, laps = lobby.laps, mode = lobby.mode,
        eligible = summary.eligible, rewards = summary.rewards, crewVs = summary.crewVs, rows = rows, at = os.time(),
    }
end

--- Carrera de prueba: sin premios ni records; fija el tiempo de referencia y marca el circuito como probado
local function closeTest(lobby, list)
    local p = list[1]
    local ok = p ~= nil and p.status == 'finished' and p.bestLap ~= nil and Validation.FlagReason(p) == nil
    local ref
    if ok then ref = Tracks.MarkTested(lobby.track, p.bestLap, { cid = p.cid, name = p.name }) end
    if p and not p.left then
        TriggerClientEvent('races:client:testResult', p.src, { ok = ok, time = p and p.bestLap or nil, reference = ref, trackId = lobby.track.id })
    end
    lobby.state = 'finished'
    Lobbies.Cleanup(lobby)
end

local function closeRace(lobby)
    local track = lobby.track
    local list = Lobbies.Standings(lobby)
    for i, p in ipairs(list) do p.position = i end

    if lobby.mode == 'test' then return closeTest(lobby, list) end

    local finishers = {}
    for _, p in ipairs(list) do
        if p.status == 'finished' then finishers[#finishers + 1] = p end
    end
    local eligible = #list >= Settings.minPlayersForRewards
    local summary = { eligible = eligible }

    -- Puntos del ranking de pilotos
    if eligible then
        for _, p in ipairs(finishers) do p.points = Settings.pilotPoints[p.position] or 0 end
    end

    -- Dinero y puntos de crew: la logica depende del modo
    local ok, err = pcall(function()
        if lobby.mode == 'crew' then
            settleCrewRace(lobby, list, summary)
        else
            settleOpenRace(lobby, list, finishers, eligible, summary)
            if eligible then awardCrewPoints(lobby, list, finishers) end
        end
    end)
    if not ok then
        print(('^1[races]^7 error liquidando la carrera %s: %s'):format(lobby.key, tostring(err)))
        Logs.Add({ name = 'system' }, 'settle_error', { lobby = lobby.id, error = tostring(err) }, true)
        -- Lo que quede retenido se devuelve para no perder dinero
        local left = lobby.escrows
        lobby.escrows = {}
        for _, e in ipairs(left) do Money.RefundEntry(e) end
    end

    saveResults(lobby, list)
    submitRecords(lobby, list)
    Leaderboard.InvalidatePilots()

    local payload = buildPayload(lobby, list, summary)
    for _, p in ipairs(list) do
        local mine = {}
        for k, v in pairs(payload) do mine[k] = v end
        mine.you = p.src
        Results.last[p.cid] = mine
        if not p.left then TriggerClientEvent('races:client:results', p.src, mine) end
    end

    -- Resumen para auditoria / webhook y evento publico para otros scripts
    local podium = {}
    for i = 1, math.min(3, #finishers) do podium[i] = ('%d. %s (%s)'):format(i, finishers[i].name, Utils.FormatTime(finishers[i].finishTime)) end
    Logs.Add({ name = 'system' }, 'race_result', {
        track = track.name, mode = lobby.mode, racers = #list, finishers = #finishers, laps = lobby.laps,
        podium = table.concat(podium, ' | '), winnerCrew = summary.crewVs and summary.crewVs.winnerCrew and summary.crewVs.winnerCrew.name or '',
        prize = summary.rewards and summary.rewards.total or 0,
    }, false)

    local event = { raceKey = lobby.key, lobbyId = lobby.id, trackId = track.id, trackName = track.name, mode = lobby.mode, laps = lobby.laps, results = {}, crewVs = summary.crewVs }
    for _, row in ipairs(payload.rows) do
        local p = lobby.players[row.pid]
        event.results[#event.results + 1] = {
            source = row.pid, citizenid = p and p.cid or nil, name = row.name, position = row.position, status = row.status,
            totalTime = row.totalTime, bestLap = row.bestLap, prize = row.prize, points = row.points, crewPoints = row.crewPoints,
            crewId = p and p.crew and p.crew.id or nil, flagged = row.flagged == true,
        }
    end
    TriggerEvent('races:onRaceFinished', event)

    lobby.state = 'finished'
    Lobbies.Cleanup(lobby)
end

--- Cierra la carrera. Ante cualquier error se devuelve lo retenido y se libera a los pilotos.
function Results.Close(lobby)
    local ok, err = pcall(closeRace, lobby)
    if ok then return end
    print(('^1[races]^7 error cerrando la carrera %s: %s'):format(lobby.key, tostring(err)))
    Logs.Add({ name = 'system' }, 'close_error', { lobby = lobby.id, error = tostring(err) }, true)
    local left = lobby.escrows
    lobby.escrows = {}
    lobby.state = 'finished'
    Lobbies.Cleanup(lobby)
    for _, e in ipairs(left) do Money.RefundEntry(e) end
end

--- Ultimo resultado de un jugador (para el panel)
function Results.Last(cid) return Results.last[cid] end

-- Anulacion / aprobacion (administracion) --------------------------------------------------------------------------

--- Anula un resultado (tiempo y record asociado). Recalcula el record del piloto.
function Results.Void(id, reason, actor)
    local r = DB.GetResult(id)
    if not r then return false, 'result_not_found' end
    if r.voided == 1 or r.voided == true then return false, 'already_voided' end
    if DB.VoidResult(id, reason, actor.name) == 0 then return false, 'already_voided' end
    Leaderboard.Recompute(r.track_id, r.track_version, r.citizenid)
    Logs.Add(actor, 'result_void', { result = id, track = r.track_name, player = r.name, reason = reason }, true)
    return true
end

--- Da por buena una marca sospechosa y recalcula el record
function Results.Approve(id, actor)
    local r = DB.GetResult(id)
    if not r then return false, 'result_not_found' end
    if DB.ApproveResult(id) == 0 then return false, 'invalid_data' end
    Leaderboard.Recompute(r.track_id, r.track_version, r.citizenid)
    Logs.Add(actor, 'result_approve', { result = id, track = r.track_name, player = r.name }, true)
    return true
end
