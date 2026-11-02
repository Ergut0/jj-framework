-- Departamento de la policía en jj-framework. Los grados salen de Config.Jobs o de jj_creatorjobs
POLICE_JOB = 'police'

-- Permisos de cada rango, además de los jefes, que los tienen todos
DEFAULT_PERMISSIONS = { 'citizens.access', 'incidents.access', 'penalcode.access', 'debtors.access', 'federal.access' }

function GetRanks()
    local job = JJ.GetJobs()[POLICE_JOB]
    local ranks = {}

    for grade, data in pairs(job and job.grades or {}) do
        ranks[#ranks + 1] = { id = grade, grade = grade, label = data.label, isBoss = data.isBoss == true }
    end

    table.sort(ranks, function(a, b) return a.grade < b.grade end)
    return ranks
end

-- Devuelve el jugador si es policía
function GetAgent(src)
    local player = JJ.GetPlayer(src)
    if player and player.getJob().name == POLICE_JOB then return player end
end

function GetRankPermissions(grade)
    local row = MySQL.scalar.await('SELECT permissions FROM jj_policetablet_ranks WHERE grade = ?', { grade })
    return row and json.decode(row) or DEFAULT_PERMISSIONS
end

function HasPerm(src, permission)
    local player = GetAgent(src)
    if not player then return false end

    local job = player.getJob()
    if job.isBoss then return true end

    for _, value in ipairs(GetRankPermissions(job.grade)) do
        if value == permission then return true end
    end

    return false
end

function CleanText(value, length)
    if type(value) ~= 'string' then return nil end

    local text = value:match('^%s*(.-)%s*$')
    return text ~= '' and (length and text:sub(1, length) or text) or nil
end

function CleanUrl(value)
    local url = CleanText(value, 500)
    return url and url:match('^https?://[^%s"\'<>]+$') and url or nil
end

function Today()
    return os.date('%d/%m/%Y')
end

function DecodeJson(value)
    if type(value) ~= 'string' or value == '' then return nil end

    local ok, result = pcall(json.decode, value)
    return ok and result or nil
end

function IsTrue(value)
    return value == true or value == 1
end

function SearchPattern(term)
    return ('%%%s%%'):format((tostring(term or '')):gsub('[%%_]', ''))
end

-- Datos de personaje de una fila de jj_players
function CitizenFromRow(row, extra)
    local charinfo = DecodeJson(row.charinfo) or {}
    local first, last = (row.name or ''):match('^(%S+)%s*(.*)$')
    local citizen = {
        id = row.id,
        citizenid = row.identifier,
        imageUrl = extra and extra.image_url or nil,
        firstname = charinfo.firstname or first or '',
        lastname = charinfo.lastname or last or '',
        nationality = charinfo.nationality or '',
        dateofbirth = charinfo.birthdate or '',
        gender = charinfo.gender == 0 and 'Hombre' or 'Mujer',
    }

    return citizen
end

function GetPhoneNumber(identifier)
    for _, tableName in ipairs({ 'phone_phones', 'phone_last_phone' }) do
        local ok, number = pcall(MySQL.scalar.await, ('SELECT phone_number FROM %s WHERE id = ?'):format(tableName), { identifier })
        if ok and number then return number end
    end
end

-- Modifica los metadatos de un personaje, esté conectado o no
function SetCitizenMetadata(identifier, key, value)
    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then
        player.setMetadata(key, value)
        return
    end

    local raw = MySQL.scalar.await('SELECT metadata FROM jj_players WHERE identifier = ?', { identifier })
    local metadata = DecodeJson(raw) or {}
    metadata[key] = value
    MySQL.update.await('UPDATE jj_players SET metadata = ? WHERE identifier = ?', { json.encode(metadata), identifier })
end
