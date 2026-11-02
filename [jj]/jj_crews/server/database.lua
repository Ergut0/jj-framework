-- Capa de acceso a datos. Todas las consultas estan parametrizadas.
DB = {}

local Q = {
    crews        = 'SELECT id, name, tag, color, logo, level, points, wins, money, frozen, leader_cid, UNIX_TIMESTAMP(created_at) AS created_at FROM crews',
    ranks        = 'SELECT id, crew_id, name, level, is_leader, permissions FROM crew_ranks',
    members      = 'SELECT citizenid, crew_id, rank_id, name, UNIX_TIMESTAMP(joined_at) AS joined_at FROM crew_members',
    settings     = 'SELECT `key`, `value` FROM crew_settings',
    setSetting   = 'INSERT INTO crew_settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)',
    insertCrew   = 'INSERT INTO crews (name, tag, color, logo, leader_cid) VALUES (?, ?, ?, ?, ?)',
    updateIdent  = 'UPDATE crews SET name = ?, tag = ?, color = ?, logo = ? WHERE id = ?',
    updateStyle  = 'UPDATE crews SET color = ?, logo = ? WHERE id = ?',
    setFrozen    = 'UPDATE crews SET frozen = ? WHERE id = ?',
    setLeader    = 'UPDATE crews SET leader_cid = ? WHERE id = ?',
    deleteCrew   = 'DELETE FROM crews WHERE id = ?',
    insertRank   = 'INSERT INTO crew_ranks (crew_id, name, level, is_leader, permissions) VALUES (?, ?, ?, ?, ?)',
    updateRank   = 'UPDATE crew_ranks SET name = ?, permissions = ? WHERE id = ?',
    deleteRank   = 'DELETE FROM crew_ranks WHERE id = ?',
    insertMember = 'INSERT INTO crew_members (citizenid, crew_id, rank_id, name) VALUES (?, ?, ?, ?)',
    deleteMember = 'DELETE FROM crew_members WHERE citizenid = ?',
    memberRank   = 'UPDATE crew_members SET rank_id = ? WHERE citizenid = ?',
    memberName   = 'UPDATE crew_members SET name = ? WHERE citizenid = ?',
    -- Estadisticas: una consulta fija por campo (sin concatenar SQL)
    setStat = {
        level  = 'UPDATE crews SET level = ? WHERE id = ?',
        points = 'UPDATE crews SET points = ? WHERE id = ?',
        wins   = 'UPDATE crews SET wins = ? WHERE id = ?',
        money  = 'UPDATE crews SET money = ? WHERE id = ?',
    },
    getStat = {
        level  = 'SELECT level FROM crews WHERE id = ?',
        points = 'SELECT points FROM crews WHERE id = ?',
        wins   = 'SELECT wins FROM crews WHERE id = ?',
        money  = 'SELECT money FROM crews WHERE id = ?',
    },
    addPoints    = 'UPDATE crews SET points = GREATEST(points + ?, 0) WHERE id = ?',
    addWins      = 'UPDATE crews SET wins = GREATEST(wins + ?, 0) WHERE id = ?',
    -- Operacion atomica sobre el banco: evita saldos negativos y condiciones de carrera
    changeMoney  = 'UPDATE crews SET money = money + ? WHERE id = ? AND money + ? >= 0 AND money + ? <= ?',
    insertTx     = 'INSERT INTO crew_transactions (crew_id, citizenid, name, type, amount, balance_after, note) VALUES (?, ?, ?, ?, ?, ?, ?)',
    getTx        = 'SELECT id, citizenid, name, type, amount, balance_after, note, UNIX_TIMESTAMP(created_at) AS created_at FROM crew_transactions WHERE crew_id = ? ORDER BY id DESC LIMIT ? OFFSET ?',
    countTx      = 'SELECT COUNT(*) FROM crew_transactions WHERE crew_id = ?',
    insertInvite = 'INSERT INTO crew_invites (crew_id, citizenid, invited_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?)) ON DUPLICATE KEY UPDATE invited_by = VALUES(invited_by), expires_at = VALUES(expires_at)',
    getInvites   = 'SELECT id, crew_id, citizenid, invited_by, UNIX_TIMESTAMP(expires_at) AS expires_at FROM crew_invites WHERE citizenid = ? AND expires_at > NOW()',
    getInvite    = 'SELECT id, crew_id, citizenid, invited_by, UNIX_TIMESTAMP(expires_at) AS expires_at FROM crew_invites WHERE id = ?',
    findInvite   = 'SELECT id FROM crew_invites WHERE crew_id = ? AND citizenid = ? AND expires_at > NOW()',
    countInvites = 'SELECT COUNT(*) FROM crew_invites WHERE crew_id = ? AND expires_at > NOW()',
    deleteInvite = 'DELETE FROM crew_invites WHERE id = ?',
    deleteInvCid = 'DELETE FROM crew_invites WHERE citizenid = ?',
    purgeInvites = 'DELETE FROM crew_invites WHERE expires_at <= NOW()',
    insertLog    = 'INSERT INTO crew_logs (crew_id, crew_name, actor_cid, actor_name, action, details, is_admin) VALUES (?, ?, ?, ?, ?, ?, ?)',
    crewLogs     = 'SELECT id, crew_name, actor_cid, actor_name, action, details, UNIX_TIMESTAMP(created_at) AS created_at FROM crew_logs WHERE crew_id = ? AND is_admin = 0 ORDER BY id DESC LIMIT ? OFFSET ?',
    countCrewLogs = 'SELECT COUNT(*) FROM crew_logs WHERE crew_id = ? AND is_admin = 0',
    -- Visor admin: los filtros opcionales se resuelven con parametros (? IS NULL OR ...)
    adminLogs    = 'SELECT id, crew_id, crew_name, actor_cid, actor_name, action, details, is_admin, UNIX_TIMESTAMP(created_at) AS created_at FROM crew_logs WHERE (? = 0 OR crew_id = ?) AND (CHAR_LENGTH(?) = 0 OR action = ?) AND (CHAR_LENGTH(?) = 0 OR actor_name LIKE ? OR actor_cid LIKE ? OR crew_name LIKE ?) ORDER BY id DESC LIMIT ? OFFSET ?',
    countAdminLogs = 'SELECT COUNT(*) FROM crew_logs WHERE (? = 0 OR crew_id = ?) AND (CHAR_LENGTH(?) = 0 OR action = ?) AND (CHAR_LENGTH(?) = 0 OR actor_name LIKE ? OR actor_cid LIKE ? OR crew_name LIKE ?)',
    purgeLogs    = 'DELETE FROM crew_logs WHERE created_at < (NOW() - INTERVAL ? DAY)',
    findPlayer   = 'SELECT identifier AS citizenid, name FROM jj_players WHERE identifier = ? LIMIT 1',
}

function DB.GetCrews() return MySQL.query.await(Q.crews) or {} end
function DB.GetRanks() return MySQL.query.await(Q.ranks) or {} end
function DB.GetMembers() return MySQL.query.await(Q.members) or {} end
function DB.GetSettings() return MySQL.query.await(Q.settings) or {} end
function DB.SetSetting(key, valueJson) return MySQL.update.await(Q.setSetting, { key, valueJson }) end

function DB.InsertCrew(c, leaderCid) return MySQL.insert.await(Q.insertCrew, { c.name, c.tag, c.color, c.logo, leaderCid }) end
function DB.UpdateIdentity(c) return MySQL.update.await(Q.updateIdent, { c.name, c.tag, c.color, c.logo, c.id }) end
function DB.UpdateStyle(id, color, logo) return MySQL.update.await(Q.updateStyle, { color, logo, id }) end
function DB.SetFrozen(id, frozen) return MySQL.update.await(Q.setFrozen, { frozen and 1 or 0, id }) end
function DB.SetLeader(id, cid) return MySQL.update.await(Q.setLeader, { cid, id }) end
function DB.DeleteCrew(id) return MySQL.update.await(Q.deleteCrew, { id }) end

function DB.InsertRank(crewId, name, level, isLeader, permsJson)
    return MySQL.insert.await(Q.insertRank, { crewId, name, level, isLeader and 1 or 0, permsJson })
end
function DB.UpdateRank(id, name, permsJson) return MySQL.update.await(Q.updateRank, { name, permsJson, id }) end
function DB.DeleteRank(id) return MySQL.update.await(Q.deleteRank, { id }) end

function DB.InsertMember(cid, crewId, rankId, name) return MySQL.insert.await(Q.insertMember, { cid, crewId, rankId, name }) end
function DB.DeleteMember(cid) return MySQL.update.await(Q.deleteMember, { cid }) end
function DB.SetMemberRank(cid, rankId) return MySQL.update.await(Q.memberRank, { rankId, cid }) end
function DB.SetMemberName(cid, name) return MySQL.update.await(Q.memberName, { name, cid }) end

function DB.SetStat(stat, id, value) return MySQL.update.await(Q.setStat[stat], { value, id }) end
function DB.GetStat(stat, id) return MySQL.scalar.await(Q.getStat[stat], { id }) end
function DB.AddPoints(id, delta) return MySQL.update.await(Q.addPoints, { delta, id }) end
function DB.AddWins(id, delta) return MySQL.update.await(Q.addWins, { delta, id }) end
function DB.ChangeMoney(id, delta)
    return MySQL.update.await(Q.changeMoney, { delta, id, delta, delta, Config.MaxBankBalance })
end

function DB.InsertTransaction(crewId, cid, name, txType, amount, balance, note)
    return MySQL.insert.await(Q.insertTx, { crewId, cid or '', name or '', txType, amount, balance, note or '' })
end
function DB.GetTransactions(crewId, limit, offset)
    return MySQL.query.await(Q.getTx, { crewId, limit, offset }) or {}, MySQL.scalar.await(Q.countTx, { crewId }) or 0
end

function DB.InsertInvite(crewId, cid, invitedBy, expiresAt) return MySQL.insert.await(Q.insertInvite, { crewId, cid, invitedBy, expiresAt }) end
function DB.GetInvites(cid) return MySQL.query.await(Q.getInvites, { cid }) or {} end
function DB.GetInvite(id) return MySQL.single.await(Q.getInvite, { id }) end
function DB.HasInvite(crewId, cid) return MySQL.scalar.await(Q.findInvite, { crewId, cid }) ~= nil end
function DB.CountInvites(crewId) return MySQL.scalar.await(Q.countInvites, { crewId }) or 0 end
function DB.DeleteInvite(id) return MySQL.update.await(Q.deleteInvite, { id }) end
function DB.DeleteInvitesOf(cid) return MySQL.update.await(Q.deleteInvCid, { cid }) end
function DB.PurgeInvites() return MySQL.update.await(Q.purgeInvites) end

function DB.InsertLog(crewId, crewName, cid, name, action, detailsJson, isAdmin)
    return MySQL.insert.await(Q.insertLog, { crewId, crewName, cid, name, action, detailsJson, isAdmin })
end
function DB.GetCrewLogs(crewId, limit, offset)
    return MySQL.query.await(Q.crewLogs, { crewId, limit, offset }) or {}, MySQL.scalar.await(Q.countCrewLogs, { crewId }) or 0
end

local function escapeLike(s) return (s:gsub('[\\%%_]', '\\%0')) end

function DB.GetAdminLogs(filters, limit, offset)
    -- Sin nils en los parametros: 0 / '' significan "sin filtro"
    local crewId = filters.crewId or 0
    local action = filters.action or ''
    local like = filters.search and ('%' .. escapeLike(filters.search) .. '%') or ''
    local p = { crewId, crewId, action, action, like, like, like, like }
    local rows = MySQL.query.await(Q.adminLogs, { crewId, crewId, action, action, like, like, like, like, limit, offset }) or {}
    local total = MySQL.scalar.await(Q.countAdminLogs, p) or 0
    return rows, total
end
function DB.PurgeLogs(days) return MySQL.update.await(Q.purgeLogs, { days }) end

function DB.FindPlayer(cid) return MySQL.single.await(Q.findPlayer, { cid }) end
