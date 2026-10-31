-- Funciones internas del recurso: no se exponen a otros recursos a través de JJ
JJInternal = {}

local function decode(value)
    if type(value) ~= 'string' then
        return nil
    end
    local ok, result = pcall(json.decode, value)
    return ok and result or nil
end

local function defaultAccounts()
    local accounts = {}
    for name, account in pairs(Config.Accounts) do
        accounts[name] = account.start
    end
    return accounts
end

-- Añade lo que necesitan los personajes a las bases de datos creadas antes de que existieran
MySQL.ready(function()
    local columns = {
        license = 'VARCHAR(60) NULL',
        charinfo = 'LONGTEXT NULL',
        skin = 'LONGTEXT NULL',
    }
    for _, column in ipairs(MySQL.query.await('SHOW COLUMNS FROM `jj_players`') or {}) do
        columns[column.Field] = nil
    end
    local addedLicense = columns.license ~= nil
    for name, definition in pairs(columns) do
        MySQL.query.await(('ALTER TABLE `jj_players` ADD COLUMN `%s` %s'):format(name, definition))
    end
    if addedLicense then
        MySQL.query.await('ALTER TABLE `jj_players` ADD KEY `idx_jj_players_license` (`license`)')
        -- Hasta ahora el identificador de cada jugador era su licencia
        MySQL.update.await('UPDATE jj_players SET license = identifier WHERE license IS NULL')
    end
end)

local function parseRow(row)
    -- Las cuentas añadidas a la configuración después de crear al jugador empiezan con su saldo inicial
    local accounts = defaultAccounts()
    local saved = decode(row.accounts) or {}
    for accountName in pairs(accounts) do
        local balance = JJ.Utils.ToAmount(saved[accountName], true)
        if balance then
            accounts[accountName] = balance
        end
    end

    return {
        id = row.id,
        license = row.license,
        name = row.name,
        charinfo = decode(row.charinfo),
        skin = row.skin,
        accounts = accounts,
        job = row.job,
        job_grade = row.job_grade,
        position = decode(row.position),
        metadata = decode(row.metadata) or {}
    }
end

local SELECT_CHARACTER = 'SELECT id, license, name, charinfo, skin, accounts, job, job_grade, position, metadata FROM jj_players WHERE identifier = ?'

function JJInternal.FetchCharacter(identifier)
    local row = MySQL.single.await(SELECT_CHARACTER, { identifier })
    return row and parseRow(row) or nil
end

-- Modo sin personajes: lee la fila del jugador o la crea si es su primera conexión
function JJInternal.FetchPlayerRow(identifier, name)
    local row = MySQL.single.await(SELECT_CHARACTER, { identifier })
    if row then
        return parseRow(row)
    end

    local accounts = defaultAccounts()
    local id = MySQL.insert.await(
        'INSERT INTO jj_players (identifier, name, accounts, job, job_grade, license) VALUES (?, ?, ?, ?, ?, ?)',
        { identifier, name, json.encode(accounts), Config.DefaultJob, 0, identifier }
    )
    return { id = id, license = identifier, accounts = accounts, job = Config.DefaultJob, job_grade = 0, metadata = {} }
end

function JJInternal.FetchCharacters(license)
    local rows = MySQL.query.await('SELECT id, identifier, name, charinfo, skin FROM jj_players WHERE license = ? ORDER BY id', { license }) or {}
    for _, row in ipairs(rows) do
        row.charinfo = decode(row.charinfo)
    end
    return rows
end

local function generateIdentifier()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local identifier = { 'JJ' }
    for i = 2, 9 do
        local index = math.random(1, #chars)
        identifier[i] = chars:sub(index, index)
    end
    return table.concat(identifier)
end

-- Devuelve el identificador del personaje nuevo, o nil si no se ha podido crear
function JJInternal.InsertCharacter(license, name, charinfo)
    for _ = 1, 10 do
        local identifier = generateIdentifier()
        local inserted = MySQL.update.await(
            'INSERT IGNORE INTO jj_players (identifier, license, name, charinfo, accounts, job, job_grade) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { identifier, license, name, json.encode(charinfo), json.encode(defaultAccounts()), Config.DefaultJob, 0 }
        )
        if inserted and inserted > 0 then
            return identifier
        end
    end
    return nil
end

-- Sin await a propósito: también se ejecuta durante playerDropped y onResourceStop
function JJInternal.SavePlayer(player)
    local data = player.getData()
    MySQL.update(
        'UPDATE jj_players SET name = ?, accounts = ?, job = ?, job_grade = ?, position = ?, metadata = ?, skin = ? WHERE identifier = ?',
        {
            data.name,
            json.encode(data.accounts),
            data.job.name,
            data.job.grade,
            json.encode(data.position),
            json.encode(data.metadata),
            data.skin,
            data.identifier
        }
    )
end
