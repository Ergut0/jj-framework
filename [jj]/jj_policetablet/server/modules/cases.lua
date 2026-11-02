-- Informes (incident) e incidentes internos (report): misma estructura, distintos permisos
local BASE_FIELDS = { id = true, title = true, description = true, status = true, division = true, creator = true, date = true }

local REPORT_DIVISIONS = {
    ia = 'reports.access.ia',
    detectives = 'reports.access.detectives',
    sargentos = 'reports.access.sargentos',
    ia_lssd = 'reports.access.ia',
    detectives_lssd = 'reports.access.detectives',
    sargentos_lssd = 'reports.access.sargentos',
}

local function toCase(row, full)
    local case = {
        id = row.id,
        title = row.title,
        description = row.description or '',
        status = row.status,
        division = row.division,
        date = row.date,
        creator = { name = row.creator_name, citizenid = row.creator_citizenid },
    }

    if full then
        for key, value in pairs(DecodeJson(row.data) or {}) do
            if not BASE_FIELDS[key] then case[key] = value end
        end
    end

    return case
end

-- El resto de campos (ciudadanos, vehículos, pruebas...) se guarda tal cual en data
local function splitExtra(data)
    local extra = {}
    for key, value in pairs(data) do
        if not BASE_FIELDS[key] then extra[key] = value end
    end
    return json.encode(extra)
end

local function canSeeDivision(source, division)
    local permission = REPORT_DIVISIONS[division]
    return permission and HasPerm(source, permission)
end

local function listCases(kind, source, where, ...)
    local rows = MySQL.query.await(('SELECT * FROM jj_policetablet_cases WHERE kind = ? %s ORDER BY id DESC LIMIT 200'):format(where or ''), { kind, ... }) or {}
    local cases = {}

    for _, row in ipairs(rows) do
        if kind == 'incident' or canSeeDivision(source, row.division) then
            cases[#cases + 1] = toCase(row)
        end
    end

    return cases
end

local function getCase(id, kind)
    return MySQL.single.await('SELECT * FROM jj_policetablet_cases WHERE id = ? AND kind = ?', { id, kind })
end

local function createCase(source, kind, data, division)
    local player = JJ.GetPlayer(source)
    local date = Today()
    local id = MySQL.insert.await([[INSERT INTO jj_policetablet_cases
        (kind, title, description, status, division, creator_citizenid, creator_name, data, date)
        VALUES (?, ?, ?, 'open', ?, ?, ?, ?, ?)]], {
        kind,
        CleanText(data.title, 200) or 'Sin título',
        data.description,
        division,
        player.identifier,
        player.getName(),
        splitExtra(data),
        date,
    })

    return { id = id, date = date, division = division }
end

local function saveCase(data, kind)
    MySQL.update.await('UPDATE jj_policetablet_cases SET title = ?, description = ?, status = ?, division = ?, data = ? WHERE id = ? AND kind = ?', {
        CleanText(data.title, 200) or 'Sin título',
        data.description,
        data.status == 'closed' and 'closed' or 'open',
        data.division,
        splitExtra(data),
        data.id,
        kind,
    })
end

-- Lo edita quien lo creó o quien tiene el permiso
local function canEdit(source, row, permission)
    local player = GetAgent(source)
    return player and (row.creator_citizenid == player.identifier or HasPerm(source, permission))
end

local function dateCondition(date)
    if type(date) ~= 'string' or date == '' then return '', nil end
    return ' AND date = ?', date
end

-- ==================== Informes ====================

lib.callback.register('jj_policetablet:callback:getIncidents', function(source)
    WaitForDatabase()
    return HasPerm(source, 'incidents.access') and listCases('incident', source) or {}
end)

lib.callback.register('jj_policetablet:callback:getIncidentById', function(source, id)
    if not HasPerm(source, 'incidents.access') then return nil end

    local row = getCase(id, 'incident')
    return row and toCase(row, true) or nil
end)

lib.callback.register('jj_policetablet:callback:getIncidentsBySearchTerm', function(source, query, date)
    if not HasPerm(source, 'incidents.access') then return {} end

    local condition, dateValue = dateCondition(date)
    local pattern = SearchPattern(query)
    if dateValue then
        return listCases('incident', source, 'AND title LIKE ?' .. condition, pattern, dateValue)
    end
    return listCases('incident', source, 'AND title LIKE ?', pattern)
end)

lib.callback.register('jj_policetablet:callback:createIncident', function(source, data)
    if not HasPerm(source, 'incidents.access') or type(data) ~= 'table' then return { id = -1 } end
    return createCase(source, 'incident', data)
end)

lib.callback.register('jj_policetablet:callback:updateIncident', function(source, payload)
    local data = type(payload) == 'table' and payload.selectedIncident
    if type(data) ~= 'table' then return false end

    local row = getCase(data.id, 'incident')
    if not row or not canEdit(source, row, 'incidents.edit') then return false end

    data.division = nil
    saveCase(data, 'incident')
    return true
end)

lib.callback.register('jj_policetablet:callback:deleteIncident', function(source, id)
    if not HasPerm(source, 'incidents.delete') then return false end

    MySQL.query.await("DELETE FROM jj_policetablet_cases WHERE id = ? AND kind = 'incident'", { id })
    return true
end)

lib.callback.register('jj_policetablet:callback:openEvidenceStash', function(source, id)
    if not HasPerm(source, 'incidents.access') or not getCase(id, 'incident') then return false end

    local stash = ('police_evidence_%d'):format(id)
    exports.ox_inventory:RegisterStash(stash, ('Pruebas del informe %d'):format(id), 50, 500000)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stash)
    return true
end)

-- ==================== Incidentes internos ====================

lib.callback.register('jj_policetablet:callback:getReports', function(source)
    WaitForDatabase()
    return HasPerm(source, 'reports.access') and listCases('report', source) or {}
end)

lib.callback.register('jj_policetablet:callback:getReportById', function(source, id)
    local row = getCase(id, 'report')
    if not row or not HasPerm(source, 'reports.access') or not canSeeDivision(source, row.division) then return nil end

    return toCase(row, true)
end)

lib.callback.register('jj_policetablet:callback:getReportsBySearchTerm', function(source, query, date)
    if not HasPerm(source, 'reports.access') then return {} end

    local condition, dateValue = dateCondition(date)
    local pattern = SearchPattern(query)
    if dateValue then
        return listCases('report', source, 'AND title LIKE ?' .. condition, pattern, dateValue)
    end
    return listCases('report', source, 'AND title LIKE ?', pattern)
end)

lib.callback.register('jj_policetablet:callback:createReport', function(source, data)
    if not HasPerm(source, 'reports.access') or type(data) ~= 'table' then return { error = 'no_permission' } end
    if not canSeeDivision(source, data.division) then return { error = 'no_permission' } end

    return createCase(source, 'report', data, data.division)
end)

lib.callback.register('jj_policetablet:callback:updateReport', function(source, payload)
    local data = type(payload) == 'table' and payload.selectedReport
    if type(data) ~= 'table' then return false end

    local row = getCase(data.id, 'report')
    if not row or not canEdit(source, row, 'reports.edit') or not canSeeDivision(source, data.division) then return false end

    saveCase(data, 'report')
    return true
end)

lib.callback.register('jj_policetablet:callback:deleteReport', function(source, id)
    if not HasPerm(source, 'reports.delete') then return false end

    MySQL.query.await("DELETE FROM jj_policetablet_cases WHERE id = ? AND kind = 'report'", { id })
    return true
end)

-- ==================== Código penal ====================

lib.callback.register('jj_policetablet:callback:getPenalCodes', function(source)
    WaitForDatabase()
    if not GetAgent(source) then return { penalCodes = {}, chapters = {} } end

    return {
        penalCodes = MySQL.query.await('SELECT id, chapter_id, id_article, article, description, fine FROM jj_policetablet_penalcodes') or {},
        chapters = MySQL.query.await('SELECT id, name FROM jj_policetablet_chapters ORDER BY id') or {},
    }
end)

local function cleanArticle(article)
    if type(article) ~= 'table' then return nil end

    local name = CleanText(article.article, 200)
    local code = CleanText(tostring(article.id_article or ''), 20)
    if not name or not code then return nil end

    return tonumber(article.chapter_id), code, name, CleanText(article.description, 4000), math.max(0, math.floor(tonumber(article.fine) or 0))
end

lib.callback.register('jj_policetablet:callback:createPenalCode', function(source, data)
    if not HasPerm(source, 'penalcode.create') or type(data) ~= 'table' then return nil end

    local chapter, code, name, description, fine = cleanArticle(data.newArticle)
    if not code then return nil end

    local id = MySQL.insert.await('INSERT INTO jj_policetablet_penalcodes (chapter_id, id_article, article, description, fine) VALUES (?, ?, ?, ?, ?)', {
        chapter, code, name, description, fine,
    })
    return { id = id }
end)

lib.callback.register('jj_policetablet:callback:updatePenalCode', function(source, data)
    if not HasPerm(source, 'penalcode.edit') or type(data) ~= 'table' then return false end

    local chapter, code, name, description, fine = cleanArticle(data.updatedArticle)
    if not code then return false end

    MySQL.update.await('UPDATE jj_policetablet_penalcodes SET chapter_id = ?, id_article = ?, article = ?, description = ?, fine = ? WHERE id = ?', {
        chapter, code, name, description, fine, data.id,
    })
    return true
end)

lib.callback.register('jj_policetablet:callback:deletePenalCode', function(source, id)
    if not HasPerm(source, 'penalcode.delete') then return false end

    MySQL.query.await('DELETE FROM jj_policetablet_penalcodes WHERE id = ?', { id })
    return true
end)

lib.callback.register('jj_policetablet:callback:createChapter', function(source, name)
    if not HasPerm(source, 'penalcode.create') then return nil end

    name = CleanText(name, 120)
    if not name then return nil end

    name = name:upper()
    return { id = MySQL.insert.await('INSERT INTO jj_policetablet_chapters (name) VALUES (?)', { name }), name = name }
end)

lib.callback.register('jj_policetablet:callback:updateChapter', function(source, data)
    if not HasPerm(source, 'penalcode.edit') or type(data) ~= 'table' then return nil end

    local name = CleanText(data.name, 120)
    if not name then return nil end

    name = name:upper()
    MySQL.update.await('UPDATE jj_policetablet_chapters SET name = ? WHERE id = ?', { name, data.id })
    return { name = name }
end)

lib.callback.register('jj_policetablet:callback:deleteChapter', function(source, id)
    if not HasPerm(source, 'penalcode.delete') then return false end

    MySQL.update.await('UPDATE jj_policetablet_penalcodes SET chapter_id = NULL WHERE chapter_id = ?', { id })
    MySQL.query.await('DELETE FROM jj_policetablet_chapters WHERE id = ?', { id })
    return true
end)

-- ==================== Tablón y plantillas ====================

lib.callback.register('jj_policetablet:callback:getHomeAnnounces', function(source)
    WaitForDatabase()
    if not GetAgent(source) then return {} end

    local rows = MySQL.query.await('SELECT id, text, pinned FROM jj_policetablet_announces ORDER BY id DESC') or {}
    for _, row in ipairs(rows) do
        row.pinned = IsTrue(row.pinned)
    end
    return rows
end)

lib.callback.register('jj_policetablet:callback:createHomeAnnounce', function(source, data)
    if not HasPerm(source, 'home.notes.create') or type(data) ~= 'table' or type(data.text) ~= 'string' then return nil end

    local pinned = data.pinned == true
    local id = MySQL.insert.await('INSERT INTO jj_policetablet_announces (text, pinned) VALUES (?, ?)', { data.text, pinned })
    return { id = id, text = data.text, pinned = pinned }
end)

lib.callback.register('jj_policetablet:callback:updateHomeAnnounce', function(source, data)
    if not HasPerm(source, 'home.notes.edit') or type(data) ~= 'table' or type(data.text) ~= 'string' then return { success = false } end

    MySQL.update.await('UPDATE jj_policetablet_announces SET text = ?, pinned = ? WHERE id = ?', { data.text, data.pinned == true, data.id })
    return { success = true }
end)

lib.callback.register('jj_policetablet:callback:deleteHomeAnnounce', function(source, id)
    if not HasPerm(source, 'home.notes.delete') then return { success = false } end

    MySQL.query.await('DELETE FROM jj_policetablet_announces WHERE id = ?', { id })
    return { success = true }
end)

lib.callback.register('jj_policetablet:callback:getTemplates', function(source, scope)
    WaitForDatabase()
    if not GetAgent(source) then return {} end

    return MySQL.query.await('SELECT id, name, content, created_at * 1000 AS createdAt FROM jj_policetablet_templates WHERE scope = ? ORDER BY id DESC', {
        CleanText(scope, 40) or 'global',
    }) or {}
end)

lib.callback.register('jj_policetablet:callback:createTemplate', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' or type(data.content) ~= 'string' then return { success = false } end

    local name = CleanText(data.name, 120)
    if not name then return { success = false } end

    local createdAt = os.time()
    local id = MySQL.insert.await('INSERT INTO jj_policetablet_templates (scope, name, content, created_at) VALUES (?, ?, ?, ?)', {
        CleanText(data.scope, 40) or 'global', name, data.content, createdAt,
    })

    return { success = true, template = { id = id, name = name, content = data.content, createdAt = createdAt * 1000 } }
end)

lib.callback.register('jj_policetablet:callback:deleteTemplate', function(source, id)
    if not GetAgent(source) then return { success = false } end

    MySQL.query.await('DELETE FROM jj_policetablet_templates WHERE id = ?', { id })
    return { success = true }
end)
