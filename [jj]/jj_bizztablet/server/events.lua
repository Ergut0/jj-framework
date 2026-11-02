local events = {}
local cooldowns = {}

local function nowMs()
    return os.time() * 1000
end

local function fromRow(row)
    return {
        id = row.id,
        job = row.job,
        title = row.title,
        startAt = row.start_at,
        endAt = row.end_at,
        location = row.location,
        description = row.description or '',
        organizer = row.organizer,
        imageUrl = row.image_url or '',
        cancelled = row.cancelled == true or row.cancelled == 1,
    }
end

local function findEvent(id)
    id = tonumber(id)
    for index, event in ipairs(events) do
        if event.id == id then return event, index end
    end
end

local function broadcast()
    TriggerClientEvent('jj_bizztablet:updateEvents', -1, events)
    QueueStatusRefresh()
end

local function isFinished(event)
    return event.endAt < nowMs()
end

local function canManage(source, player, event)
    if HasPerms(source) then return true end

    local job = player.getJob()
    return job.isBoss and event.job == job.name
end

local function cleanEvent(data)
    if type(data) ~= 'table' then return nil, 'Datos no válidos' end

    local title = CleanText(data.title, 80)
    local location = CleanText(data.location, 80)
    local organizer = CleanText(data.organizer, 80)
    local startAt, endAt = tonumber(data.startAt), tonumber(data.endAt)

    if not title then return nil, 'El título es obligatorio' end
    if not location then return nil, 'El lugar es obligatorio' end
    if not organizer then return nil, 'El colaborador es obligatorio' end
    if not startAt or not endAt then return nil, 'La fecha no es válida' end

    startAt, endAt = math.floor(startAt), math.floor(endAt)

    if endAt <= startAt then return nil, 'El evento tiene que terminar después de empezar' end
    if endAt - startAt > Config.MaxEventHours * 3600000 then
        return nil, ('Un evento no puede durar más de %d horas'):format(Config.MaxEventHours)
    end
    if endAt < nowMs() then return nil, 'El evento ya habría terminado' end

    return {
        title = title,
        location = location,
        organizer = organizer,
        startAt = startAt,
        endAt = endAt,
        description = CleanText(data.description, 1000),
        imageUrl = CleanUrl(data.imageUrl),
    }
end

local function isOnCooldown(source)
    local now = GetGameTimer()
    if cooldowns[source] and now - cooldowns[source] < 1500 then return true end

    cooldowns[source] = now
    return false
end

function GetEventsList()
    return events
end

function HasActiveEvent(job)
    local now = nowMs()

    for _, event in ipairs(events) do
        if event.job == job and not event.cancelled and event.startAt <= now and event.endAt >= now then
            return true
        end
    end

    return false
end

lib.callback.register('jj_bizztablet:createEvent', function(source, data)
    WaitForDatabase()

    local player = JJ.GetPlayer(source)
    if not player then return { success = false, error = 'Jugador no encontrado' } end
    if isOnCooldown(source) then return { success = false, error = 'Espera un momento' } end

    local job = player.getJob()
    if not job.isBoss and not HasPerms(source) then
        return { success = false, error = 'Solo los jefes pueden crear eventos' }
    end

    local active = 0
    for _, event in ipairs(events) do
        if event.job == job.name and not event.cancelled and not isFinished(event) then
            active += 1
        end
    end
    if active >= Config.MaxActiveEventsPerJob then
        return { success = false, error = 'Tu negocio ya tiene demasiados eventos activos' }
    end

    local clean, reason = cleanEvent(data)
    if not clean then return { success = false, error = reason } end

    local id = MySQL.insert.await([[INSERT INTO jj_bizztablet_events
        (job, title, start_at, end_at, location, description, organizer, image_url, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        job.name, clean.title, clean.startAt, clean.endAt, clean.location,
        clean.description, clean.organizer, clean.imageUrl, player.identifier,
    })

    events[#events + 1] = {
        id = id,
        job = job.name,
        title = clean.title,
        startAt = clean.startAt,
        endAt = clean.endAt,
        location = clean.location,
        description = clean.description or '',
        organizer = clean.organizer,
        imageUrl = clean.imageUrl or '',
        cancelled = false,
    }
    broadcast()

    return { success = true }
end)

lib.callback.register('jj_bizztablet:updateEvent', function(source, data)
    WaitForDatabase()

    local player = JJ.GetPlayer(source)
    local event = player and type(data) == 'table' and findEvent(data.id)
    if not event then return { success = false, error = 'El evento no existe' } end
    if not canManage(source, player, event) then return { success = false, error = 'No tienes permiso' } end
    if event.cancelled or isFinished(event) then
        return { success = false, error = 'No puedes editar un evento finalizado' }
    end

    local clean, reason = cleanEvent(data)
    if not clean then return { success = false, error = reason } end

    MySQL.update.await([[UPDATE jj_bizztablet_events SET title = ?, start_at = ?, end_at = ?, location = ?,
        description = ?, organizer = ?, image_url = ? WHERE id = ?]], {
        clean.title, clean.startAt, clean.endAt, clean.location,
        clean.description, clean.organizer, clean.imageUrl, event.id,
    })

    event.title = clean.title
    event.startAt = clean.startAt
    event.endAt = clean.endAt
    event.location = clean.location
    event.description = clean.description or ''
    event.organizer = clean.organizer
    event.imageUrl = clean.imageUrl or ''
    broadcast()

    return { success = true }
end)

lib.callback.register('jj_bizztablet:cancelEvent', function(source, id)
    WaitForDatabase()

    local player = JJ.GetPlayer(source)
    local event = player and findEvent(id)
    if not event then return { success = false, error = 'El evento no existe' } end
    if not canManage(source, player, event) then return { success = false, error = 'No tienes permiso' } end
    if event.cancelled or isFinished(event) then
        return { success = false, error = 'No puedes cancelar un evento finalizado' }
    end

    MySQL.update.await('UPDATE jj_bizztablet_events SET cancelled = 1 WHERE id = ?', { event.id })
    event.cancelled = true
    broadcast()

    return { success = true }
end)

lib.callback.register('jj_bizztablet:deleteEvent', function(source, id)
    WaitForDatabase()

    if not HasPerms(source) then return { success = false, error = 'No tienes permiso' } end

    local event, index = findEvent(id)
    if not event then return { success = false, error = 'El evento no existe' } end

    MySQL.query.await('DELETE FROM jj_bizztablet_events WHERE id = ?', { event.id })
    table.remove(events, index)
    broadcast()

    return { success = true }
end)

AddEventHandler('jj:server:playerDropped', function(src)
    cooldowns[src] = nil
end)

CreateThread(function()
    WaitForDatabase()

    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_bizztablet_events ORDER BY start_at') or {}) do
        events[#events + 1] = fromRow(row)
    end
end)
