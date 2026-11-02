-- Acceso a la base de datos. Perfiles y asignaciones se cargan una vez al arrancar y se
-- mantienen en memoria; solo el historial y los registros se consultan cuando se piden
DB = {}

local function readInstallSql()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql') or ''
    local statements = {}
    for statement in sql:gsub('%-%-[^\n]*', ''):gmatch('[^;]+') do
        if statement:find('%S') then statements[#statements + 1] = statement end
    end
    return statements
end

function DB.Init()
    for _, statement in ipairs(readInstallSql()) do
        MySQL.query.await(statement)
    end

    local profiles = MySQL.query.await('SELECT * FROM jj_handling_profiles') or {}
    local assignments = MySQL.query.await('SELECT kind, target, profile_id FROM jj_handling_assignments') or {}
    return profiles, assignments
end

function DB.InsertProfile(profile)
    return MySQL.insert.await([[
        INSERT INTO jj_handling_profiles (name, model_hash, model_name, vehicle_class, params, preset, is_global, author, author_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        profile.name, profile.modelHash, profile.modelName, profile.class, json.encode(profile.params),
        profile.preset, profile.global and 1 or 0, profile.author, profile.authorName,
    })
end

-- Solo actualiza si nadie lo ha cambiado desde la versión que se editó. Devuelve true si lo ha hecho
function DB.UpdateProfile(profile, expectedVersion)
    local affected = MySQL.update.await([[
        UPDATE jj_handling_profiles SET name = ?, params = ?, preset = ?, is_global = ?, version = version + 1
        WHERE id = ? AND version = ?
    ]], { profile.name, json.encode(profile.params), profile.preset, profile.global and 1 or 0, profile.id, expectedVersion })
    return (affected or 0) > 0
end

function DB.DeleteProfile(id)
    MySQL.update.await('DELETE FROM jj_handling_assignments WHERE profile_id = ?', { id })
    MySQL.update.await('DELETE FROM jj_handling_history WHERE profile_id = ?', { id })
    return (MySQL.update.await('DELETE FROM jj_handling_profiles WHERE id = ?', { id }) or 0) > 0
end

function DB.InsertHistory(profile, editor)
    MySQL.insert.await([[
        INSERT INTO jj_handling_history (profile_id, version, name, params, edited_by, edited_by_name) VALUES (?, ?, ?, ?, ?, ?)
    ]], { profile.id, profile.version, profile.name, json.encode(profile.params), editor.identifier, editor.name })

    -- Se conservan solo las últimas versiones
    MySQL.update.await([[
        DELETE FROM jj_handling_history WHERE profile_id = ? AND id NOT IN (
            SELECT id FROM (SELECT id FROM jj_handling_history WHERE profile_id = ? ORDER BY id DESC LIMIT ?) AS keep
        )
    ]], { profile.id, profile.id, Config.HistoryPerProfile })
end

function DB.GetHistory(profileId)
    return MySQL.query.await([[
        SELECT id, version, name, params, edited_by_name, UNIX_TIMESTAMP(created_at) AS created_at
        FROM jj_handling_history WHERE profile_id = ? ORDER BY id DESC
    ]], { profileId }) or {}
end

function DB.GetHistoryEntry(profileId, historyId)
    return MySQL.single.await('SELECT * FROM jj_handling_history WHERE id = ? AND profile_id = ?', { historyId, profileId })
end

function DB.SetAssignment(kind, target, profileId, by)
    MySQL.insert.await([[
        INSERT INTO jj_handling_assignments (kind, target, profile_id, assigned_by) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE profile_id = VALUES(profile_id), assigned_by = VALUES(assigned_by), created_at = CURRENT_TIMESTAMP
    ]], { kind, target, profileId, by })
end

function DB.RemoveAssignment(kind, target)
    MySQL.update.await('DELETE FROM jj_handling_assignments WHERE kind = ? AND target = ?', { kind, target })
end

function DB.InsertLog(action, actor, actorName, target, details)
    MySQL.insert('INSERT INTO jj_handling_logs (action, actor, actor_name, target, details) VALUES (?, ?, ?, ?, ?)',
        { action, actor, actorName, target, details })
end

function DB.GetLogs(filter)
    local where, params = {}, {}
    if filter.action then
        where[#where + 1] = 'action = ?'
        params[#params + 1] = filter.action
    end
    if filter.search then
        where[#where + 1] = '(actor_name LIKE ? OR target LIKE ? OR details LIKE ?)'
        local like = '%' .. filter.search:gsub('[%%_]', '\\%0') .. '%'
        params[#params + 1], params[#params + 2], params[#params + 3] = like, like, like
    end
    params[#params + 1] = filter.limit or 100

    local sql = ('SELECT id, action, actor_name, target, details, UNIX_TIMESTAMP(created_at) AS created_at FROM jj_handling_logs %s ORDER BY id DESC LIMIT ?')
        :format(#where > 0 and ('WHERE ' .. table.concat(where, ' AND ')) or '')
    return MySQL.query.await(sql, params) or {}
end
