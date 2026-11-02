-- Capa de acceso a datos. Todas las consultas estan parametrizadas.
DB = {}

local Q = {
    settings     = 'SELECT `key`, `value` FROM race_settings',
    setSetting   = 'INSERT INTO race_settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)',

    -- Circuitos -------------------------------------------------------------
    tracks       = 'SELECT id, name, category, difficulty, description, laps_default, vehicle_class, enabled, version, tested_version, allow_crews, base_prize, time_limit, collisions, reference_time, grid, created_by, UNIX_TIMESTAMP(created_at) AS created_at, UNIX_TIMESTAMP(updated_at) AS updated_at FROM race_tracks',
    checkpoints  = 'SELECT c.track_id, c.idx, c.kind, c.x, c.y, c.z, c.radius, c.height, c.link_from, c.link_to FROM race_checkpoints c JOIN race_tracks t ON t.id = c.track_id AND t.version = c.version ORDER BY c.track_id, c.idx',
    insertTrack  = 'INSERT INTO race_tracks (name, category, difficulty, description, laps_default, vehicle_class, enabled, version, tested_version, allow_crews, base_prize, time_limit, collisions, reference_time, grid, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    updateTrack  = 'UPDATE race_tracks SET name = ?, category = ?, difficulty = ?, description = ?, laps_default = ?, vehicle_class = ?, enabled = ?, version = ?, tested_version = ?, allow_crews = ?, base_prize = ?, time_limit = ?, collisions = ?, reference_time = ?, grid = ? WHERE id = ?',
    deleteCps    = 'DELETE FROM race_checkpoints WHERE track_id = ? AND version = ?',
    insertCp     = 'INSERT INTO race_checkpoints (track_id, version, idx, kind, x, y, z, radius, height, link_from, link_to) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    setEnabled   = 'UPDATE race_tracks SET enabled = ? WHERE id = ?',
    setTested    = 'UPDATE race_tracks SET tested_version = ?, reference_time = ? WHERE id = ?',
    deleteTrack  = 'DELETE FROM race_tracks WHERE id = ?',

    -- Records ---------------------------------------------------------------
    bestRecords  = 'SELECT r.track_id, r.citizenid, r.name, r.crew_tag, r.crew_color, r.best_lap, r.vehicle_model FROM race_records r JOIN race_tracks t ON t.id = r.track_id AND t.version = r.track_version ORDER BY r.track_id, r.best_lap ASC',
    trackBest    = 'SELECT citizenid, name, crew_tag, crew_color, best_lap, vehicle_model FROM race_records WHERE track_id = ? AND track_version = ? ORDER BY best_lap ASC LIMIT 1',
    leaderboard  = 'SELECT citizenid, name, crew_tag, crew_color, best_lap, vehicle_model, vehicle_class, UNIX_TIMESTAMP(updated_at) AS at FROM race_records WHERE track_id = ? AND track_version = ? ORDER BY best_lap ASC LIMIT ?',
    playerRecord = 'SELECT id, best_lap, result_id FROM race_records WHERE track_id = ? AND track_version = ? AND citizenid = ?',
    upsertRecord = 'INSERT INTO race_records (track_id, track_version, citizenid, name, crew_id, crew_tag, crew_color, best_lap, vehicle_model, vehicle_class, result_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), crew_id = VALUES(crew_id), crew_tag = VALUES(crew_tag), crew_color = VALUES(crew_color), best_lap = VALUES(best_lap), vehicle_model = VALUES(vehicle_model), vehicle_class = VALUES(vehicle_class), result_id = VALUES(result_id)',
    deleteRecord = 'DELETE FROM race_records WHERE track_id = ? AND track_version = ? AND citizenid = ?',
    bestResult   = 'SELECT id, name, crew_id, crew_tag, crew_color, best_lap, vehicle_model, vehicle_class FROM race_results WHERE track_id = ? AND track_version = ? AND citizenid = ? AND voided = 0 AND flagged = 0 AND best_lap > 0 ORDER BY best_lap ASC LIMIT 1',

    -- Resultados ------------------------------------------------------------
    insertResult = 'INSERT INTO race_results (race_key, track_id, track_name, track_version, event_id, mode, citizenid, name, crew_id, crew_tag, crew_color, position, status, total_time, best_lap, laps, vehicle_model, vehicle_class, prize, points, crew_points, flagged, flag_reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    resultByKey  = 'SELECT id, race_key, track_id, track_name, track_version, mode, citizenid, name, crew_id, crew_tag, crew_color, position, status, total_time, best_lap, laps, vehicle_model, prize, points, crew_points, flagged, voided, UNIX_TIMESTAMP(created_at) AS created_at FROM race_results WHERE race_key = ? ORDER BY position ASC',
    resultById   = 'SELECT id, race_key, track_id, track_name, track_version, citizenid, name, best_lap, flagged, voided FROM race_results WHERE id = ?',
    history      = 'SELECT id, race_key, track_id, track_name, mode, position, status, total_time, best_lap, prize, points, crew_points, flagged, voided, UNIX_TIMESTAMP(created_at) AS created_at FROM race_results WHERE citizenid = ? ORDER BY id DESC LIMIT ? OFFSET ?',
    countHistory = 'SELECT COUNT(*) FROM race_results WHERE citizenid = ?',
    stats        = 'SELECT COUNT(*) AS races, COALESCE(SUM(status = \'finished\' AND position = 1), 0) AS wins, COALESCE(SUM(status = \'finished\' AND position <= 3), 0) AS podiums, COALESCE(SUM(prize), 0) AS earnings, COALESCE(SUM(points), 0) AS points FROM race_results WHERE citizenid = ? AND voided = 0',
    playerBests  = 'SELECT r.track_id, t.name AS track_name, r.best_lap, r.vehicle_model FROM race_records r JOIN race_tracks t ON t.id = r.track_id AND t.version = r.track_version WHERE r.citizenid = ? ORDER BY t.name',
    pilotRanking = 'SELECT citizenid, MAX(name) AS name, MAX(crew_tag) AS crew_tag, MAX(crew_color) AS crew_color, COUNT(*) AS races, SUM(status = \'finished\' AND position = 1) AS wins, SUM(status = \'finished\' AND position <= 3) AS podiums, SUM(points) AS points FROM race_results WHERE voided = 0 GROUP BY citizenid ORDER BY points DESC, wins DESC LIMIT ?',
    adminResults = 'SELECT id, race_key, track_id, track_name, mode, citizenid, name, crew_tag, position, status, total_time, best_lap, prize, flagged, flag_reason, voided, void_reason, UNIX_TIMESTAMP(created_at) AS created_at FROM race_results WHERE (? = 0 OR (flagged = 1 AND voided = 0)) AND (CHAR_LENGTH(?) = 0 OR name LIKE ? OR citizenid LIKE ? OR track_name LIKE ?) ORDER BY id DESC LIMIT ? OFFSET ?',
    countAdminResults = 'SELECT COUNT(*) FROM race_results WHERE (? = 0 OR (flagged = 1 AND voided = 0)) AND (CHAR_LENGTH(?) = 0 OR name LIKE ? OR citizenid LIKE ? OR track_name LIKE ?)',
    voidResult   = 'UPDATE race_results SET voided = 1, void_reason = ?, voided_by = ? WHERE id = ? AND voided = 0',
    approveResult = 'UPDATE race_results SET flagged = 0 WHERE id = ? AND flagged = 1',

    -- Eventos ---------------------------------------------------------------
    insertEvent  = 'INSERT INTO race_events (track_id, title, laps, vehicle_class, prize, scheduled_at, created_by) VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?), ?)',
    events       = 'SELECT e.id, e.track_id, t.name AS track_name, e.title, e.laps, e.vehicle_class, e.prize, UNIX_TIMESTAMP(e.scheduled_at) AS scheduled_at, e.status FROM race_events e JOIN race_tracks t ON t.id = e.track_id WHERE e.status IN (\'scheduled\', \'open\', \'running\') OR e.scheduled_at > (NOW() - INTERVAL 7 DAY) ORDER BY e.scheduled_at DESC LIMIT 100',
    eventsDue    = 'SELECT e.id, e.track_id, e.title, e.laps, e.vehicle_class, e.prize, UNIX_TIMESTAMP(e.scheduled_at) AS scheduled_at FROM race_events e WHERE e.status = \'scheduled\' ORDER BY e.scheduled_at ASC',
    eventById    = 'SELECT id, track_id, title, laps, vehicle_class, prize, UNIX_TIMESTAMP(scheduled_at) AS scheduled_at, status FROM race_events WHERE id = ?',
    setEventStatus = 'UPDATE race_events SET status = ? WHERE id = ?',
    staleEvents  = 'UPDATE race_events SET status = \'cancelled\' WHERE status IN (\'open\', \'running\')',

    -- Dinero retenido -------------------------------------------------------
    insertEscrow = 'INSERT INTO race_escrow (kind, owner, amount, account, ref, reason) VALUES (?, ?, ?, ?, ?, ?)',
    deleteEscrow = 'DELETE FROM race_escrow WHERE id = ?',
    escrows      = 'SELECT id, kind, owner, amount, account, ref, reason FROM race_escrow ORDER BY id',
    creditCash   = 'UPDATE jj_players SET accounts = JSON_SET(accounts, \'$.cash\', COALESCE(JSON_EXTRACT(accounts, \'$.cash\'), 0) + ?) WHERE identifier = ?',
    creditBank   = 'UPDATE jj_players SET accounts = JSON_SET(accounts, \'$.bank\', COALESCE(JSON_EXTRACT(accounts, \'$.bank\'), 0) + ?) WHERE identifier = ?',

    -- Logs ------------------------------------------------------------------
    insertLog    = 'INSERT INTO race_logs (actor_cid, actor_name, action, details, is_admin) VALUES (?, ?, ?, ?, ?)',
    adminLogs    = 'SELECT id, actor_cid, actor_name, action, details, is_admin, UNIX_TIMESTAMP(created_at) AS created_at FROM race_logs WHERE (CHAR_LENGTH(?) = 0 OR action = ?) AND (CHAR_LENGTH(?) = 0 OR actor_name LIKE ? OR actor_cid LIKE ? OR details LIKE ?) ORDER BY id DESC LIMIT ? OFFSET ?',
    countAdminLogs = 'SELECT COUNT(*) FROM race_logs WHERE (CHAR_LENGTH(?) = 0 OR action = ?) AND (CHAR_LENGTH(?) = 0 OR actor_name LIKE ? OR actor_cid LIKE ? OR details LIKE ?)',
    purgeLogs    = 'DELETE FROM race_logs WHERE created_at < (NOW() - INTERVAL ? DAY)',
}

local function bit(v) return v and 1 or 0 end

-- Ajustes -----------------------------------------------------------------------
function DB.GetSettings() return MySQL.query.await(Q.settings) or {} end
function DB.SetSetting(key, valueJson) return MySQL.update.await(Q.setSetting, { key, valueJson }) end

-- Circuitos ---------------------------------------------------------------------
function DB.GetTracks() return MySQL.query.await(Q.tracks) or {} end
function DB.GetCheckpoints() return MySQL.query.await(Q.checkpoints) or {} end

local function trackValues(t)
    return {
        t.name, t.category, t.difficulty, t.description, t.lapsDefault, t.vehicleClass, bit(t.enabled), t.version,
        t.testedVersion, bit(t.allowCrews), t.basePrize, t.timeLimit, bit(t.collisions), t.referenceTime, json.encode(t.grid),
    }
end

local function cpValues(trackId, version, cp)
    return { trackId, version, cp.idx, cp.kind, cp.x, cp.y, cp.z, cp.radius, cp.height, cp.linkFrom or 0, cp.linkTo or 0 }
end

--- Inserta un circuito nuevo con sus checkpoints. Devuelve el id o nil.
function DB.InsertTrack(t, createdBy)
    local values = trackValues(t)
    values[#values + 1] = createdBy
    local id = MySQL.insert.await(Q.insertTrack, values)
    if not id then return nil end
    local queries = {}
    for _, cp in ipairs(t.checkpoints) do
        queries[#queries + 1] = { query = Q.insertCp, values = cpValues(id, t.version, cp) }
    end
    if not MySQL.transaction.await(queries) then
        MySQL.update.await(Q.deleteTrack, { id })
        return nil
    end
    return id
end

--- Actualiza un circuito y reemplaza los checkpoints de su version actual (transaccion).
function DB.UpdateTrack(t)
    local values = trackValues(t)
    values[#values + 1] = t.id
    local queries = {
        { query = Q.updateTrack, values = values },
        { query = Q.deleteCps, values = { t.id, t.version } },
    }
    for _, cp in ipairs(t.checkpoints) do
        queries[#queries + 1] = { query = Q.insertCp, values = cpValues(t.id, t.version, cp) }
    end
    return MySQL.transaction.await(queries) == true
end

function DB.SetTrackEnabled(id, enabled) return MySQL.update.await(Q.setEnabled, { bit(enabled), id }) end
function DB.SetTrackTested(id, version, referenceTime) return MySQL.update.await(Q.setTested, { version, referenceTime, id }) end
function DB.DeleteTrack(id) return MySQL.update.await(Q.deleteTrack, { id }) end

-- Records -----------------------------------------------------------------------
function DB.GetBestRecords() return MySQL.query.await(Q.bestRecords) or {} end
function DB.GetTrackBest(trackId, version) return MySQL.single.await(Q.trackBest, { trackId, version }) end
function DB.GetLeaderboard(trackId, version, limit) return MySQL.query.await(Q.leaderboard, { trackId, version, limit }) or {} end
function DB.GetPlayerRecord(trackId, version, cid) return MySQL.single.await(Q.playerRecord, { trackId, version, cid }) end

-- Nota: oxmysql no admite `nil` dentro de los arrays de parametros, por eso los opcionales usan 0.
function DB.UpsertRecord(trackId, version, r)
    return MySQL.update.await(Q.upsertRecord, {
        trackId, version, r.citizenid, r.name, r.crewId or 0, r.crewTag or '', r.crewColor or '', r.bestLap, r.vehicleModel or '', r.vehicleClass or '', r.resultId or 0,
    })
end

function DB.DeleteRecord(trackId, version, cid) return MySQL.update.await(Q.deleteRecord, { trackId, version, cid }) end
function DB.GetBestResult(trackId, version, cid) return MySQL.single.await(Q.bestResult, { trackId, version, cid }) end

-- Resultados --------------------------------------------------------------------
function DB.InsertResult(r)
    return MySQL.insert.await(Q.insertResult, {
        r.raceKey, r.trackId, r.trackName, r.trackVersion, r.eventId or 0, r.mode, r.citizenid, r.name, r.crewId or 0, r.crewTag or '', r.crewColor or '',
        r.position, r.status, r.totalTime, r.bestLap, r.laps, r.vehicleModel or '', r.vehicleClass or '', r.prize, r.points, r.crewPoints,
        bit(r.flagged), r.flagReason or '',
    })
end

function DB.GetResultsByKey(key) return MySQL.query.await(Q.resultByKey, { key }) or {} end
function DB.GetResult(id) return MySQL.single.await(Q.resultById, { id }) end
function DB.GetHistory(cid, limit, offset) return MySQL.query.await(Q.history, { cid, limit, offset }) or {} end
function DB.CountHistory(cid) return MySQL.scalar.await(Q.countHistory, { cid }) or 0 end
function DB.GetStats(cid) return MySQL.single.await(Q.stats, { cid }) end
function DB.GetPlayerBests(cid) return MySQL.query.await(Q.playerBests, { cid }) or {} end
function DB.GetPilotRanking(limit) return MySQL.query.await(Q.pilotRanking, { limit }) or {} end

function DB.GetAdminResults(flaggedOnly, search, limit, offset)
    local like = '%' .. search .. '%'
    return MySQL.query.await(Q.adminResults, { flaggedOnly and 1 or 0, search, like, like, like, limit, offset }) or {}
end

function DB.CountAdminResults(flaggedOnly, search)
    local like = '%' .. search .. '%'
    return MySQL.scalar.await(Q.countAdminResults, { flaggedOnly and 1 or 0, search, like, like, like }) or 0
end

function DB.VoidResult(id, reason, by) return MySQL.update.await(Q.voidResult, { reason, by, id }) end
function DB.ApproveResult(id) return MySQL.update.await(Q.approveResult, { id }) end

-- Eventos -----------------------------------------------------------------------
function DB.InsertEvent(e, createdBy)
    return MySQL.insert.await(Q.insertEvent, { e.trackId, e.title, e.laps, e.vehicleClass, e.prize, e.scheduledAt, createdBy })
end

function DB.GetEvents() return MySQL.query.await(Q.events) or {} end
function DB.GetPendingEvents() return MySQL.query.await(Q.eventsDue) or {} end
function DB.GetEvent(id) return MySQL.single.await(Q.eventById, { id }) end
function DB.SetEventStatus(id, status) return MySQL.update.await(Q.setEventStatus, { status, id }) end
function DB.CancelStaleEvents() return MySQL.update.await(Q.staleEvents) end

-- Dinero retenido ----------------------------------------------------------------
function DB.InsertEscrow(kind, owner, amount, account, ref, reason)
    return MySQL.insert.await(Q.insertEscrow, { kind, tostring(owner), amount, account, ref, reason or '' })
end

--- Borra una retencion. Devuelve true solo si la fila existia (puerta anti doble pago).
function DB.DeleteEscrow(id) return (MySQL.update.await(Q.deleteEscrow, { id }) or 0) > 0 end
function DB.GetEscrows() return MySQL.query.await(Q.escrows) or {} end

--- Ingresa dinero a un jugador desconectado (solo cuentas conocidas).
function DB.CreditOffline(cid, account, amount)
    local q = account == 'cash' and Q.creditCash or account == 'bank' and Q.creditBank or nil
    if not q then return false end
    local ok, res = pcall(MySQL.update.await, q, { amount, cid })
    return ok and (res or 0) > 0
end

-- Logs ---------------------------------------------------------------------------
function DB.InsertLog(cid, name, action, details, isAdmin)
    return MySQL.insert.await(Q.insertLog, { cid, name, action, details, isAdmin })
end

function DB.GetAdminLogs(action, search, limit, offset)
    local like = '%' .. search .. '%'
    return MySQL.query.await(Q.adminLogs, { action, action, search, like, like, like, limit, offset }) or {}
end

function DB.CountAdminLogs(action, search)
    local like = '%' .. search .. '%'
    return MySQL.scalar.await(Q.countAdminLogs, { action, action, search, like, like, like }) or 0
end

function DB.PurgeLogs(days) return MySQL.update.await(Q.purgeLogs, { days }) end
