local config = lib.load('shared.cfg')

local BUCKET_OFFSET = 1000
local MAX_NAME_LENGTH = 30
local MAX_NATIONALITY_LENGTH = 60
local TOTAL_SLOTS = 5
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

-- Helpers

local function getSlots(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    local slots = license and MySQL.scalar.await('SELECT slots FROM jj_character_slots WHERE license = ?', { license })
    return slots or config.defaultOpenCharSlot
end

local function getGenderKey(gender)
    return gender == 1 and 'female' or 'male'
end

-- Modelo del personaje: el de su aspecto guardado o, si no tiene, el básico de su sexo
local function getModel(skin, gender)
    if type(skin) == 'string' then
        local ok, decoded = pcall(json.decode, skin)
        if ok and type(decoded) == 'table' and decoded.model then
            return type(decoded.model) == 'string' and GetHashKey(decoded.model) or decoded.model
        end
    end
    return config.randomPeds[getGenderKey(gender)].model
end

local function getGender(charinfo)
    return charinfo and charinfo.gender or 0
end

local function buildClientCharacter(player)
    local data = player.getData()
    local gender = getGender(data.charinfo)
    return {
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
    return value ~= nil and #value >= 2 and #value <= MAX_NAME_LENGTH and not value:find('[%c<>]')
end

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function isValidBirthdate(value)
    if type(value) ~= 'string' then return false end
    local day, month, year = value:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    day, month, year = tonumber(day), tonumber(month), tonumber(year)
    if not day or month < 1 or month > 12 or year < 1900 or year > tonumber(os.date('%Y')) then
        return false
    end
    local days = { 31, isLeapYear(year) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    return day >= 1 and day <= days[month]
end

-- Devuelve los datos limpios del personaje, o nil y el motivo
local function parseCharacterData(data)
    if type(data) ~= 'table' then
        return nil, 'Datos no válidos'
    end

    local firstname, lastname = trim(data.firstname), trim(data.lastname)
    if not isValidName(firstname) or not isValidName(lastname) then
        return nil, ('El nombre y los apellidos deben tener entre 2 y %d caracteres'):format(MAX_NAME_LENGTH)
    end
    if not isValidBirthdate(data.birthdate) then
        return nil, 'La fecha de nacimiento no es válida'
    end
    if data.gender ~= 0 and data.gender ~= 1 then
        return nil, 'El sexo no es válido'
    end

    local nationality = trim(data.nationality) or ''
    if #nationality > MAX_NATIONALITY_LENGTH then
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

        for _, item in ipairs(config.starterItems) do
            local metadata = item.metadata
            if type(metadata) == 'function' then
                metadata = metadata(player)
            end
            exports.ox_inventory:AddItem(src, item.name, item.amount, metadata)
        end
    end)
end

-- Callbacks

lib.callback.register('jj_multicharacter:server:enterInstance', function(source)
    if JJ.GetPlayer(source) then return false end
    SetPlayerRoutingBucket(source, BUCKET_OFFSET + source)
    return true
end)

lib.callback.register('jj_multicharacter:server:leaveInstance', function(source)
    if not JJ.GetPlayer(source) then return false end
    SetPlayerRoutingBucket(source, 0)
    return true
end)

lib.callback.register('jj_multicharacter:server:setupCharacters', function(source)
    local characters = {}
    for _, row in ipairs(JJ.GetCharacters(source)) do
        characters[#characters + 1] = {
            id = row.id,
            citizenid = row.identifier,
            fullName = row.name,
            birthdate = row.charinfo and row.charinfo.birthdate or '',
        }
    end
    return characters
end)

lib.callback.register('jj_multicharacter:server:GetNumberOfCharacters', function(source)
    return getSlots(source)
end)

lib.callback.register('jj_multicharacter:server:getPreviewPedData', function(source, identifier)
    for _, row in ipairs(JJ.GetCharacters(source)) do
        if row.identifier == identifier then
            local gender = getGender(row.charinfo)
            return { model = getModel(row.skin, gender), skin = row.skin, gender = gender }
        end
    end
    return nil
end)

lib.callback.register('jj_multicharacter:server:loadCharacter', function(source, identifier)
    if not JJ.LoadCharacter(source, identifier) then
        return false
    end
    SetPlayerRoutingBucket(source, 0)
    return buildClientCharacter(JJ.GetPlayer(source))
end)

lib.callback.register('jj_multicharacter:server:createCharacter', function(source, data)
    if JJ.GetPlayer(source) then
        return { error = 'Ya tienes un personaje cargado' }
    end

    local charinfo, reason = parseCharacterData(data)
    if not charinfo then
        return { error = reason }
    end

    if #JJ.GetCharacters(source) >= getSlots(source) then
        return { error = 'No tienes más huecos de personaje disponibles' }
    end

    local identifier = JJ.CreateCharacter(source, charinfo.firstname .. ' ' .. charinfo.lastname, charinfo)
    if not identifier or not JJ.LoadCharacter(source, identifier) then
        return { error = 'No se ha podido crear el personaje' }
    end

    local player = JJ.GetPlayer(source)
    giveStarterItems(source, player)
    return { character = buildClientCharacter(player) }
end)

-- Administración

local function registerAdminCommand(name, handler)
    RegisterCommand(name, function(src, args)
        if not JJ.IsAdmin(src) then
            if src ~= 0 then
                TriggerClientEvent('ox_lib:notify', src, { description = 'No tienes permiso para usar este comando', type = 'error' })
            end
            return
        end
        handler(src, args)
    end, false)
end

-- /setslots <id> <cantidad>: huecos de personaje de la licencia de un jugador conectado
registerAdminCommand('setslots', function(src, args)
    local target, slots = tonumber(args[1]), math.tointeger(tonumber(args[2]) or 0)
    local license = target and GetPlayerName(target) and GetPlayerIdentifierByType(target, 'license')
    local message

    if not license or not slots or slots < 1 or slots > TOTAL_SLOTS then
        message = ('Uso: /setslots <id> <1-%d>'):format(TOTAL_SLOTS)
    else
        MySQL.update.await('INSERT INTO jj_character_slots (license, slots) VALUES (?, ?) ON DUPLICATE KEY UPDATE slots = VALUES(slots)', { license, slots })
        message = ('Huecos de personaje actualizados: %d'):format(slots)
    end

    if src == 0 then
        print(('[jj_multicharacter] %s'):format(message))
    else
        TriggerClientEvent('ox_lib:notify', src, { description = message })
    end
end)

registerAdminCommand('test_scene', function(src, args)
    if src ~= 0 then
        TriggerClientEvent('jj_multicharacter:client:testScene', src, tonumber(args[1]))
    end
end)

registerAdminCommand('stop_scene', function(src)
    if src ~= 0 then
        TriggerClientEvent('jj_multicharacter:client:stopScene', src)
    end
end)
