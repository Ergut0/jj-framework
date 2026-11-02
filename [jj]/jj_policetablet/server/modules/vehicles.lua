local STATE_IN = 1
local STATE_IMPOUND = 2
local STATE_CONFISCATED = 3

local VEHICLE_QUERY = [[
    SELECT v.plate, v.model, v.owner, v.serial AS chassis, v.state, t.image, t.wanted
    FROM jj_vehicles v
    LEFT JOIN jj_policetablet_vehicles t ON t.plate = v.plate
]]

local function toVehicle(row, index)
    return {
        id = index or 1,
        plate = row.plate,
        model = row.model,
        owner = row.owner,
        chassis = row.chassis or '',
        image = row.image,
        wanted = IsTrue(row.wanted),
        incauted = row.state == STATE_IMPOUND or row.state == STATE_CONFISCATED,
    }
end

local function toVehicles(rows)
    local vehicles = {}
    for index, row in ipairs(rows or {}) do
        vehicles[index] = toVehicle(row, index)
    end
    return vehicles
end

local function search(term)
    local pattern = SearchPattern(term)
    return toVehicles(MySQL.query.await(VEHICLE_QUERY .. ' WHERE v.plate LIKE ? OR v.model LIKE ? LIMIT 50', { pattern, pattern }))
end

lib.callback.register('jj_policetablet:callback:getVehicles', function(source)
    WaitForDatabase()
    if not GetAgent(source) then return {} end
    return toVehicles(MySQL.query.await(VEHICLE_QUERY .. ' LIMIT 50'))
end)

lib.callback.register('jj_policetablet:callback:getVehiclesByFilter', function(source, term)
    return GetAgent(source) and search(term) or {}
end)

lib.callback.register('jj_policetablet:callback:getVehiclesIncidents', function(source, term)
    return GetAgent(source) and search(term) or {}
end)

lib.callback.register('jj_policetablet:callback:getVehicleByPlate', function(source, plate)
    if not GetAgent(source) or type(plate) ~= 'string' then return nil end

    local row = MySQL.single.await(VEHICLE_QUERY .. ' WHERE v.plate = ?', { plate })
    if not row then return nil end

    local vehicle = toVehicle(row)
    vehicle.notes = MySQL.query.await("SELECT id, title, description, pinged, author, date FROM jj_policetablet_notes WHERE kind = 'vehicle' AND reference = ? ORDER BY id DESC", { plate }) or {}
    for _, note in ipairs(vehicle.notes) do
        note.pinged = IsTrue(note.pinged)
    end
    vehicle.incidents = MySQL.query.await("SELECT id, title, status, date FROM jj_policetablet_cases WHERE kind = 'incident' AND data LIKE ? ORDER BY id DESC LIMIT 50", { SearchPattern(plate) }) or {}
    return vehicle
end)

local function ensureVehicle(plate)
    MySQL.query.await('INSERT IGNORE INTO jj_policetablet_vehicles (plate) VALUES (?)', { plate })
end

lib.callback.register('jj_policetablet:callback:toggleVehicleIncautedStatus', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' then return false end

    local state = MySQL.scalar.await('SELECT state FROM jj_vehicles WHERE plate = ?', { data.vehiclePlate })
    if not state then return false end

    local held = state == STATE_IMPOUND or state == STATE_CONFISCATED
    MySQL.update.await('UPDATE jj_vehicles SET state = ? WHERE plate = ?', { held and STATE_IN or STATE_IMPOUND, data.vehiclePlate })
    return true
end)

lib.callback.register('jj_policetablet:callback:toggleVehicleWantedStatus', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' or type(data.vehiclePlate) ~= 'string' then return false end

    ensureVehicle(data.vehiclePlate)
    MySQL.update.await('UPDATE jj_policetablet_vehicles SET wanted = NOT wanted WHERE plate = ?', { data.vehiclePlate })
    return true
end)

lib.callback.register('jj_policetablet:callback:updateVehicleImageUrl', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' or type(data.vehiclePlate) ~= 'string' then return false end

    ensureVehicle(data.vehiclePlate)
    MySQL.update.await('UPDATE jj_policetablet_vehicles SET image = ? WHERE plate = ?', { CleanUrl(data.imageUrl), data.vehiclePlate })
    return true
end)

lib.callback.register('jj_policetablet:callback:addVehicleNote', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' or type(data.note) ~= 'table' or type(data.vehiclePlate) ~= 'string' then return nil end

    local title = CleanText(data.note.title, 120)
    if not title then return nil end

    local description = CleanText(data.note.description, 4000)
    local author = JJ.GetPlayer(source).getName()
    local date = Today()
    local id = MySQL.insert.await("INSERT INTO jj_policetablet_notes (kind, reference, title, description, author, date) VALUES ('vehicle', ?, ?, ?, ?, ?)", {
        data.vehiclePlate, title, description, author, date,
    })

    return { id = id, title = title, description = description or '', pinged = false, author = author, date = date }
end)

lib.callback.register('jj_policetablet:callback:deleteVehicleNote', function(source, noteId)
    if not GetAgent(source) then return false end

    MySQL.query.await("DELETE FROM jj_policetablet_notes WHERE id = ? AND kind = 'vehicle'", { noteId })
    return true
end)

lib.callback.register('jj_policetablet:callback:toggleVehicleNotePingedStatus', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' then return false end

    MySQL.update.await("UPDATE jj_policetablet_notes SET pinged = NOT pinged WHERE id = ? AND kind = 'vehicle'", { data.noteId })
    return true
end)
