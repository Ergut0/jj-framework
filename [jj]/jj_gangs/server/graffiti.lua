local Graffitis = {} -- [id] = { id, gang_id, x, y, z, nx, ny, nz }
local painting = {} -- [source] = datos del grafiti y hora de inicio
local erasing = {} -- [source] = { id, startedAt }
local lastAlert = {} -- [id de grafiti] = hora del último aviso

function LoadGraffitis()
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_gang_graffitis') or {}) do
        if Gangs[row.gang_id] then
            Graffitis[row.id] = row
        end
    end
end

function SyncGraffitis(target)
    local list = {}
    for _, graffiti in pairs(Graffitis) do
        list[#list + 1] = graffiti
    end
    TriggerClientEvent('jj_gangs:client:graffitis', target, list)
end

function RemoveGangGraffitis(gangId)
    for id, graffiti in pairs(Graffitis) do
        if graffiti.gang_id == gangId then
            Graffitis[id] = nil
            TriggerClientEvent('jj_gangs:client:removeGraffiti', -1, id)
        end
    end
    MySQL.update.await('DELETE FROM jj_gang_graffitis WHERE gang_id = ?', { gangId })
end

function GetGangGraffitis(gangId)
    local list = {}
    for _, graffiti in pairs(Graffitis) do
        if graffiti.gang_id == gangId then
            list[#list + 1] = {
                id = graffiti.id, x = graffiti.x, y = graffiti.y, z = graffiti.z, nx = graffiti.nx, ny = graffiti.ny, nz = graffiti.nz,
                url = graffiti.url, author = graffiti.author,
            }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function RemoveGraffiti(id, gangId)
    local graffiti = Graffitis[id]
    if not graffiti or graffiti.gang_id ~= gangId then return false end

    Graffitis[id] = nil
    MySQL.update.await('DELETE FROM jj_gang_graffitis WHERE id = ?', { id })
    TriggerClientEvent('jj_gangs:client:removeGraffiti', -1, id)
    return true
end

local function countGraffitis(gangId)
    local count = 0
    for _, graffiti in pairs(Graffitis) do
        if graffiti.gang_id == gangId then
            count = count + 1
        end
    end
    return count
end

-- Comprueba el sitio elegido por el cliente: cerca del jugador, en una pared y sin otro grafiti encima
local function getPaintError(src, gang, data)
    if type(data) ~= 'table' then return 'Sitio no válido' end

    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    local nx, ny, nz = tonumber(data.nx), tonumber(data.ny), tonumber(data.nz)
    if not x or not y or not z or not nx or not ny or not nz then return 'Sitio no válido' end

    local length = math.sqrt(nx * nx + ny * ny + nz * nz)
    if length < 0.9 or length > 1.1 or math.abs(nz) > 0.5 then return 'Solo puedes pintar en una pared' end
    if not IsNear(src, x, y, z, Config.Graffiti.ServerDistance) then return 'Estás demasiado lejos' end
    if countGraffitis(gang.id) >= Config.Graffiti.MaxPerGang then return 'Tu banda ya tiene demasiados grafitis' end

    for _, graffiti in pairs(Graffitis) do
        local dx, dy, dz = graffiti.x - x, graffiti.y - y, graffiti.z - z
        if math.sqrt(dx * dx + dy * dy + dz * dz) < Config.Graffiti.MinSpacing then
            return 'Ya hay un grafiti aquí'
        end
    end

    local urlError = GetGraffitiUrlError(data.url)
    if urlError then return urlError end

    if Config.Graffiti.Item and exports.ox_inventory:Search(src, 'count', Config.Graffiti.Item) < 1 then
        return 'Te hace falta un spray'
    end
    return nil, { x = x, y = y, z = z, nx = nx, ny = ny, nz = nz, url = data.url ~= '' and data.url or nil }
end

lib.callback.register('jj_gangs:server:startPaint', function(source, data)
    local _, gang = GetMember(source)
    if not gang then return { ok = false, message = 'No estás en ninguna banda' } end

    local reason, spot = getPaintError(source, gang, data)
    if reason then return { ok = false, message = reason } end

    spot.gang = gang.id
    spot.startedAt = GetGameTimer()
    painting[source] = spot
    return { ok = true, time = Config.Graffiti.PaintTime }
end)

lib.callback.register('jj_gangs:server:finishPaint', function(source)
    local spot = painting[source]
    painting[source] = nil

    local player, gang = GetMember(source)
    if not spot or not gang or gang.id ~= spot.gang then return { ok = false } end
    if GetGameTimer() - spot.startedAt < Config.Graffiti.PaintTime - 1000 then return { ok = false } end

    -- Se comprueba otra vez: otro jugador ha podido pintar al lado mientras tanto
    local reason = getPaintError(source, gang, spot)
    if reason then return { ok = false, message = reason } end

    if Config.Graffiti.Item and not exports.ox_inventory:RemoveItem(source, Config.Graffiti.Item, 1) then
        return { ok = false, message = 'Te hace falta un spray' }
    end

    local author = player.getName()
    local id = MySQL.insert.await('INSERT INTO jj_gang_graffitis (gang_id, x, y, z, nx, ny, nz, url, author) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        gang.id, spot.x, spot.y, spot.z, spot.nx, spot.ny, spot.nz, spot.url, author,
    })
    if not id then return { ok = false } end

    print(('[jj_gangs] %s (%d) pinta un grafiti de %s: %s'):format(author, source, gang.label, spot.url or 'nombre de la banda'))

    local graffiti = { id = id, gang_id = gang.id, x = spot.x, y = spot.y, z = spot.z, nx = spot.nx, ny = spot.ny, nz = spot.nz, url = spot.url, author = author }
    Graffitis[id] = graffiti
    TriggerClientEvent('jj_gangs:client:addGraffiti', -1, graffiti)
    return { ok = true, message = 'Grafiti terminado' }
end)

RegisterNetEvent('jj_gangs:server:cancelPaint', function()
    painting[source] = nil
end)

-- Borrar: solo pueden los miembros de una banda. Si es de otra, la banda dueña recibe un aviso

lib.callback.register('jj_gangs:server:startErase', function(source, id)
    local _, gang = GetMember(source)
    local graffiti = Graffitis[tonumber(id)]
    if not gang then return { ok = false, message = 'No estás en ninguna banda' } end
    if not graffiti or not IsNear(source, graffiti.x, graffiti.y, graffiti.z, Config.Graffiti.ServerDistance) then
        return { ok = false, message = 'Estás demasiado lejos' }
    end

    erasing[source] = { id = graffiti.id, startedAt = GetGameTimer() }

    if graffiti.gang_id ~= gang.id then
        local now = os.time()
        if not lastAlert[graffiti.id] or now - lastAlert[graffiti.id] >= Config.Graffiti.AlertCooldown then
            lastAlert[graffiti.id] = now
            AlertGang(graffiti.gang_id, 'Grafiti', 'Están borrando vuestro grafiti', graffiti)
        end
    end
    return { ok = true, time = Config.Graffiti.EraseTime }
end)

lib.callback.register('jj_gangs:server:finishErase', function(source)
    local job = erasing[source]
    erasing[source] = nil
    if not job then return { ok = false } end

    local _, gang = GetMember(source)
    local graffiti = Graffitis[job.id]
    if not gang or not graffiti then return { ok = false } end
    if GetGameTimer() - job.startedAt < Config.Graffiti.EraseTime - 1000 then return { ok = false } end
    if not IsNear(source, graffiti.x, graffiti.y, graffiti.z, Config.Graffiti.ServerDistance) then
        return { ok = false, message = 'Te has alejado del grafiti' }
    end

    Graffitis[graffiti.id] = nil
    lastAlert[graffiti.id] = nil
    MySQL.update.await('DELETE FROM jj_gang_graffitis WHERE id = ?', { graffiti.id })
    TriggerClientEvent('jj_gangs:client:removeGraffiti', -1, graffiti.id)

    if graffiti.gang_id ~= gang.id then
        AlertGang(graffiti.gang_id, 'Grafiti', ('%s ha borrado vuestro grafiti'):format(gang.label), graffiti)
    end
    return { ok = true, message = 'Grafiti borrado' }
end)

RegisterNetEvent('jj_gangs:server:cancelErase', function()
    erasing[source] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    painting[src] = nil
    erasing[src] = nil
end)
