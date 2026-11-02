-- Zonas de entorno: texto de rol que aparece al entrar en una zona del mapa.
-- Se gestionan desde el panel /entornos, solo para administradores; aquí se comprueba todo lo que llega
local MAX_TEXT = 500
local MAX_LABEL = 64
local MIN_POINTS = 3
local MAX_POINTS = 100
local DEFAULT_COLOR = '#9B30FF'

local zones = {}

local function reply(src, message, kind)
    if src == 0 then
        print(('[jj_entornozones] %s'):format(message))
    else
        JJ.Notify(src, message, kind)
    end
end

local function decode(value)
    if type(value) ~= 'string' then return value end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or nil
end

local function load()
    zones = {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_entorno_zones ORDER BY id') or {}) do
        local coords = decode(row.coords)
        if type(coords) == 'table' and type(coords.points) == 'table' then
            zones[#zones + 1] = {
                id = row.id,
                label = row.label,
                entorno = row.entorno,
                coords = coords,
                duration = row.duration or 10,
                color = row.color or DEFAULT_COLOR,
                enabled = row.enabled == true or row.enabled == 1,
                createdBy = row.created_by,
            }
        end
    end
end

-- Las tablas creadas antes del panel no tienen las columnas nuevas
local NEW_COLUMNS = {
    label = 'ALTER TABLE `jj_entorno_zones` ADD COLUMN `label` VARCHAR(64) NULL AFTER `id`',
    duration = 'ALTER TABLE `jj_entorno_zones` ADD COLUMN `duration` INT NOT NULL DEFAULT 10',
    color = "ALTER TABLE `jj_entorno_zones` ADD COLUMN `color` VARCHAR(7) NOT NULL DEFAULT '#9B30FF'",
    enabled = 'ALTER TABLE `jj_entorno_zones` ADD COLUMN `enabled` TINYINT(1) NOT NULL DEFAULT 1',
}

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_entorno_zones` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(64) NULL,
            `entorno` VARCHAR(500) NOT NULL,
            `coords` LONGTEXT NOT NULL,
            `duration` INT NOT NULL DEFAULT 10,
            `color` VARCHAR(7) NOT NULL DEFAULT '#9B30FF',
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` VARCHAR(60) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    local existing = {}
    for _, column in ipairs(MySQL.query.await('SHOW COLUMNS FROM `jj_entorno_zones`') or {}) do
        existing[column.Field] = true
    end
    for name, query in pairs(NEW_COLUMNS) do
        if not existing[name] then MySQL.query.await(query) end
    end

    load()
    TriggerClientEvent('jj_entornozones:client:loadZone', -1)
end)

-- Los jugadores solo reciben las zonas activas
lib.callback.register('jj_entornozones:getAllZones', function()
    local list = {}
    for _, zone in ipairs(zones) do
        if zone.enabled then
            list[#list + 1] = { id = zone.id, label = zone.label, entorno = zone.entorno, coords = zone.coords, duration = zone.duration, color = zone.color }
        end
    end
    return list
end)

local function finite(value, limit)
    return type(value) == 'number' and value == value and value >= -limit and value <= limit
end

-- Devuelve la zona limpia, o nil y el motivo
local function parseZone(data)
    if type(data) ~= 'table' or type(data.points) ~= 'table' then return nil, 'Dibuja antes la zona' end
    if #data.points < MIN_POINTS or #data.points > MAX_POINTS then
        return nil, ('La zona necesita entre %d y %d puntos'):format(MIN_POINTS, MAX_POINTS)
    end

    local points = {}
    for index, point in ipairs(data.points) do
        if type(point) ~= 'table' or not finite(point.x, 20000) or not finite(point.y, 20000) or not finite(point.z, 3000) then
            return nil, 'Hay un punto que no es válido'
        end
        points[index] = { x = point.x, y = point.y, z = point.z }
    end

    local thickness = tonumber(data.thickness) or 50.0
    if not finite(thickness, 1000) or thickness < 1 then thickness = 50.0 end

    return { points = points, thickness = thickness }
end

-- Texto con saltos de línea, sin otros caracteres de control ni etiquetas
local function cleanText(text, max)
    if type(text) ~= 'string' then return nil end
    text = text:gsub('\r', ''):match('^%s*(.-)%s*$')
    local length = utf8.len(text)
    if not length or length == 0 or length > max or text:find('[\0-\9\11-\31<>]') then return nil end
    return text
end

local function findZone(id)
    for _, zone in ipairs(zones) do
        if zone.id == id then return zone end
    end
end

local function changed()
    load()
    TriggerClientEvent('jj_entornozones:client:loadZone', -1)
end

local function adminCallback(name, handler)
    lib.callback.register('jj_entornozones:admin:' .. name, function(source, data)
        if not JJ.IsAdmin(source) then return { error = 'No tienes permiso' } end

        local err = handler(source, type(data) == 'table' and data or {})
        if err then return { error = err } end
        return { zones = zones }
    end)
end

adminCallback('list', function() end)

adminCallback('save', function(source, data)
    local id = data.id ~= nil and math.tointeger(tonumber(data.id)) or nil
    if data.id ~= nil and not (id and findZone(id)) then return 'Esa zona ya no existe' end

    local text = cleanText(data.text, MAX_TEXT)
    if not text then return ('El texto debe tener entre 1 y %d caracteres'):format(MAX_TEXT) end

    local label = nil
    if type(data.label) == 'string' and data.label:match('%S') then
        label = cleanText(data.label, MAX_LABEL)
        if not label or label:find('\n') then return ('El nombre tiene hasta %d caracteres, en una línea'):format(MAX_LABEL) end
    end

    local duration = math.tointeger(tonumber(data.duration))
    if not duration or duration < 3 or duration > 60 then return 'El aviso dura entre 3 y 60 segundos' end

    local color = type(data.color) == 'string' and data.color:match('^#%x%x%x%x%x%x$') and data.color:upper() or nil
    if not color then return 'El color no es válido' end

    local enabled = data.enabled ~= false

    local zone
    if data.zone ~= nil then
        local reason
        zone, reason = parseZone(data.zone)
        if not zone then return reason end
    elseif not id then
        return 'Dibuja antes la zona'
    end

    if id then
        if zone then
            MySQL.update.await('UPDATE jj_entorno_zones SET label = ?, entorno = ?, duration = ?, color = ?, enabled = ?, coords = ? WHERE id = ?', {
                label, text, duration, color, enabled and 1 or 0, json.encode(zone), id,
            })
        else
            MySQL.update.await('UPDATE jj_entorno_zones SET label = ?, entorno = ?, duration = ?, color = ?, enabled = ? WHERE id = ?', {
                label, text, duration, color, enabled and 1 or 0, id,
            })
        end
    else
        local player = JJ.GetPlayer(source)
        local inserted = MySQL.insert.await('INSERT INTO jj_entorno_zones (label, entorno, coords, duration, color, enabled, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            label, text, json.encode(zone), duration, color, enabled and 1 or 0, player and player.identifier or GetPlayerName(source),
        })
        if not inserted then return 'No se ha podido guardar la zona' end
    end

    changed()
end)

adminCallback('delete', function(_, data)
    local id = math.tointeger(tonumber(data.id))
    if not id or not findZone(id) then return 'Esa zona ya no existe' end

    MySQL.update.await('DELETE FROM jj_entorno_zones WHERE id = ?', { id })
    changed()
end)

-- /entornos abre el panel. Los comandos de antes también lo abren
local function openPanel(src)
    if src == 0 then return reply(src, 'Usa este comando dentro del juego') end
    if not JJ.IsAdmin(src) then return reply(src, 'No tienes permiso para usar este comando', 'error') end
    TriggerClientEvent('jj_entornozones:client:openPanel', src)
end

RegisterCommand('entornos', openPanel, false)
RegisterCommand('entornozona', openPanel, false)
RegisterCommand('entornozonas', openPanel, false)
