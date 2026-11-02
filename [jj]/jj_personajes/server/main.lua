-- Pantalla de personajes. Propiedad del personaje, huecos y datos se comprueban siempre aquí
local BUCKET_OFFSET = 1000
local MAX_NAME_LENGTH = 30
local MAX_NATIONALITY_LENGTH = 60
local INVENTORY_WAIT = 100
local INVENTORY_TRIES = 100

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_character_slots` (
            `license` VARCHAR(60) NOT NULL,
            `slots` INT NOT NULL,
            PRIMARY KEY (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

local function getLicense(src)
    return GetPlayerIdentifierByType(src, 'license')
end

local function getSlots(license)
    local slots = license and MySQL.scalar.await('SELECT slots FROM jj_character_slots WHERE license = ?', { license })
    return slots or Config.DefaultSlots
end

local function decode(value)
    if type(value) ~= 'string' then return value end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or nil
end

local function getOutfit(gender)
    return Config.BaseOutfits[gender == 1 and 1 or 0]
end

-- Modelo del personaje: el de su aspecto guardado o, si no tiene, el básico de su sexo
local function getModel(skin, gender)
    local appearance = decode(skin)
    if type(appearance) == 'table' and appearance.model then
        return type(appearance.model) == 'string' and GetHashKey(appearance.model) or appearance.model
    end
    return getOutfit(gender).model
end

local function fetchCharacters(license)
    if not license then return {} end

    local rows = MySQL.query.await([[
        SELECT identifier, name, charinfo, skin, accounts, job, job_grade, position, UNIX_TIMESTAMP(last_seen) AS last_seen
        FROM jj_players WHERE license = ? ORDER BY id
    ]], { license }) or {}

    local now = os.time()
    local characters = {}
    for index, row in ipairs(rows) do
        local charinfo = decode(row.charinfo) or {}
        local accounts = decode(row.accounts) or {}
        local job = JJ.Utils.BuildJob(row.job, row.job_grade)
        local gender = charinfo.gender == 1 and 1 or 0

        characters[index] = {
            identifier = row.identifier,
            name = row.name,
            birthdate = charinfo.birthdate or '',
            nationality = charinfo.nationality or '',
            gender = gender,
            job = job and job.label or row.job,
            grade = job and job.gradeLabel or '',
            cash = tonumber(accounts.cash) or 0,
            bank = tonumber(accounts.bank) or 0,
            position = decode(row.position),
            secondsAgo = row.last_seen and math.max(0, now - row.last_seen) or nil,
            model = getModel(row.skin, gender),
            skin = row.skin,
        }
    end
    return characters
end

local function buildLoaded(player)
    local data = player.getData()
    local gender = data.charinfo and data.charinfo.gender == 1 and 1 or 0
    return {
        name = data.name,
        model = getModel(data.skin, gender),
        skin = data.skin,
        gender = gender,
        position = data.position,
    }
end

local function trim(value)
    return type(value) == 'string' and value:match('^%s*(.-)%s*$') or nil
end

local function isValidName(value)
    if not value then return false end
    local length = utf8.len(value)
    return length ~= nil and length >= 2 and length <= MAX_NAME_LENGTH and not value:find('[%c<>]')
end

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

-- Devuelve la edad, o nil si la fecha no es válida
local function getAge(value)
    if type(value) ~= 'string' then return nil end

    local day, month, year = value:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    day, month, year = tonumber(day), tonumber(month), tonumber(year)
    if not day or month < 1 or month > 12 then return nil end

    local days = { 31, isLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if day < 1 or day > days[month] then return nil end

    local today = os.date('*t')
    local age = today.year - year
    if today.month < month or (today.month == month and today.day < day) then
        age = age - 1
    end
    return age
end

-- Devuelve los datos limpios del personaje, o nil y el motivo
local function parseCharacterData(data)
    if type(data) ~= 'table' then
        return nil, 'Datos no válidos'
    end

    local firstname, lastname = trim(data.firstname), trim(data.lastname)
    if not isValidName(firstname) or not isValidName(lastname) then
        return nil, ('El nombre y los apellidos deben tener entre 2 y %d letras'):format(MAX_NAME_LENGTH)
    end

    local age = getAge(data.birthdate)
    if not age or age < Config.MinAge or age > Config.MaxAge then
        return nil, ('La fecha de nacimiento debe dar una edad de %d a %d años'):format(Config.MinAge, Config.MaxAge)
    end

    if data.gender ~= 0 and data.gender ~= 1 then
        return nil, 'El sexo no es válido'
    end

    local nationality = trim(data.nationality) or ''
    local nationalityLength = utf8.len(nationality)
    if not nationalityLength or nationalityLength > MAX_NATIONALITY_LENGTH or nationality:find('[%c<>]') then
        return nil, 'La nacionalidad no es válida'
    end

    return {
        firstname = firstname,
        lastname = lastname,
        birthdate = data.birthdate,
        gender = data.gender,
        nationality = nationality,
    }
end

-- El inventario se carga en segundo plano al cargar el personaje: hay que esperarlo para dar los objetos
local function giveStarterItems(src, player)
    CreateThread(function()
        for _ = 1, INVENTORY_TRIES do
            if not GetPlayerName(src) then return end
            if exports.ox_inventory:GetInventory(src) then break end
            Wait(INVENTORY_WAIT)
        end

        for _, item in ipairs(Config.StarterItems) do
            local metadata = item.metadata
            if type(metadata) == 'function' then
                metadata = metadata(player)
            end
            exports.ox_inventory:AddItem(src, item.name, item.amount, metadata)
        end
    end)
end

-- Mientras elige no ve a nadie ni nadie le ve
lib.callback.register('jj_personajes:enter', function(source)
    if JJ.GetPlayer(source) then return nil end

    SetPlayerRoutingBucket(source, BUCKET_OFFSET + source)

    local license = getLicense(source)
    local characters = fetchCharacters(license)
    return {
        characters = characters,
        -- Quien tenga más personajes que huecos, porque se los han bajado, sigue viéndolos todos
        slots = math.max(math.min(getSlots(license), Config.MaxSlots), #characters),
        minAge = Config.MinAge,
        maxAge = Config.MaxAge,
    }
end)

lib.callback.register('jj_personajes:load', function(source, identifier)
    if not JJ.LoadCharacter(source, identifier) then return nil end

    SetPlayerRoutingBucket(source, 0)
    return buildLoaded(JJ.GetPlayer(source))
end)

lib.callback.register('jj_personajes:create', function(source, data)
    if JJ.GetPlayer(source) then
        return { error = 'Ya tienes un personaje cargado' }
    end

    local charinfo, reason = parseCharacterData(data)
    if not charinfo then
        return { error = reason }
    end

    local license = getLicense(source)
    if #fetchCharacters(license) >= math.min(getSlots(license), Config.MaxSlots) then
        return { error = 'No tienes más huecos de personaje disponibles' }
    end

    local identifier = JJ.CreateCharacter(source, charinfo.firstname .. ' ' .. charinfo.lastname, charinfo)
    if not identifier or not JJ.LoadCharacter(source, identifier) then
        return { error = 'No se ha podido crear el personaje' }
    end

    local player = JJ.GetPlayer(source)
    giveStarterItems(source, player)
    return { character = buildLoaded(player) }
end)

-- Un personaje nuevo sale de su instancia cuando ya tiene su aspecto puesto
lib.callback.register('jj_personajes:leave', function(source)
    if not JJ.GetPlayer(source) then return false end

    SetPlayerRoutingBucket(source, 0)
    return true
end)

-- Comandos de huecos. El jugador se indica por su id si está conectado, o por su licencia
-- (license:xxxx) si no lo está

-- Devuelve la licencia y el id del jugador si está conectado, o nil
local function findTarget(value)
    if type(value) ~= 'string' then return nil end

    if value:match('^license:%x+$') then
        for _, id in ipairs(GetPlayers()) do
            if getLicense(tonumber(id)) == value then return value, tonumber(id) end
        end
        return value, nil
    end

    local id = tonumber(value)
    local license = id and GetPlayerName(id) and getLicense(id)
    if license then return license, id end
end

local function saveSlots(license, slots)
    MySQL.update.await('INSERT INTO jj_character_slots (license, slots) VALUES (?, ?) ON DUPLICATE KEY UPDATE slots = VALUES(slots)', { license, slots })
end

local function registerSlotsCommand(name, usage, handler)
    RegisterCommand(name, function(src, args)
        local function reply(message, kind)
            if src == 0 then
                print(('[jj_personajes] %s'):format(message))
            else
                JJ.Notify(src, message, kind)
            end
        end

        if src ~= 0 and not JJ.IsAdmin(src) then
            return reply('No tienes permiso para usar este comando', 'error')
        end

        local license, target = findTarget(args[1])
        if not license then
            return reply(('Uso: /%s %s'):format(name, usage), 'error')
        end

        local current = getSlots(license)
        local slots, message = handler(current, args[2])
        if not slots then
            return reply(message, 'error')
        end

        saveSlots(license, slots)
        reply(('Huecos de personaje: %d → %d'):format(current, slots), 'success')
        if target then
            JJ.Notify(target, ('Ahora tienes %d %s de personaje'):format(slots, slots == 1 and 'hueco' or 'huecos'), 'inform')
        end
    end, false)
end

local function readAmount(value)
    if value == nil then return 1 end
    local amount = math.tointeger(tonumber(value))
    return amount and amount >= 1 and amount or nil
end

-- /setslots <id|licencia> <cantidad>: pone un número exacto de huecos
registerSlotsCommand('setslots', ('<id|licencia> <1-%d>'):format(Config.MaxSlots), function(_, value)
    local slots = math.tointeger(tonumber(value))
    if not slots or slots < 1 or slots > Config.MaxSlots then
        return nil, ('Uso: /setslots <id|licencia> <1-%d>'):format(Config.MaxSlots)
    end
    return slots
end)

-- /darslot <id|licencia> [cantidad]: suma huecos, 1 si no se dice cuántos
registerSlotsCommand('darslot', '<id|licencia> [cantidad]', function(current, value)
    local amount = readAmount(value)
    if not amount then return nil, 'La cantidad tiene que ser un número mayor que 0' end
    if current >= Config.MaxSlots then
        return nil, ('Ya tiene el máximo de huecos (%d)'):format(Config.MaxSlots)
    end
    return math.min(current + amount, Config.MaxSlots)
end)

-- /quitarslot <id|licencia> [cantidad]: resta huecos, 1 si no se dice cuántos. Nunca baja de 1
registerSlotsCommand('quitarslot', '<id|licencia> [cantidad]', function(current, value)
    local amount = readAmount(value)
    if not amount then return nil, 'La cantidad tiene que ser un número mayor que 0' end
    if current <= 1 then
        return nil, 'Ya tiene un solo hueco, no se le pueden quitar más'
    end
    return math.max(current - amount, 1)
end)
