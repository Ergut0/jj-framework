local MAX_LABEL = 32

local function fail(message)
    return { ok = false, message = message }
end

local function ok(message)
    return { ok = true, message = message }
end

local function cleanLabel(value)
    if type(value) ~= 'string' then return nil end
    local label = value:gsub('%c', ' '):gsub('%^%d', ''):match('^%s*(.-)%s*$')
    if #label < 2 or #label > MAX_LABEL then return nil end
    return label
end

local function cleanRadius(value)
    local radius = tonumber(value)
    if not radius then return nil end
    return math.min(math.max(radius, Config.MinRadius), Config.MaxRadius) + 0.0
end

local function deletePoint(gang, point)
    if point.type == 'garage' then
        RemovePointGarage(point)
    end
    gang.points[point.id] = nil
    MySQL.update.await('DELETE FROM jj_gang_points WHERE id = ?', { point.id })
end

local function isLabelTaken(label, exceptId)
    for _, gang in pairs(Gangs) do
        if gang.id ~= exceptId and gang.label:lower() == label:lower() then
            return true
        end
    end
    return false
end

-- Cambia el rango de un miembro. Solo puede haber un jefe: el anterior pasa al rango inferior
local function setGangRank(gang, identifier, name, rank)
    if rank == Config.TopRank then
        for otherIdentifier, member in pairs(gang.members) do
            if member.rank == Config.TopRank and otherIdentifier ~= identifier then
                SetMember(otherIdentifier, member.name, gang, Config.TopRank - 1)
            end
        end
    end
    SetMember(identifier, name, gang, rank)
end

local GARAGES_UNAVAILABLE = 'jj_garages no está actualizado en el servidor: súbelo y reinícialo'

local actions = {}

function actions.create(src, payload)
    local label = cleanLabel(payload.label)
    if not label then return fail(('El nombre debe tener entre 2 y %d caracteres'):format(MAX_LABEL)) end
    if isLabelTaken(label) then return fail('Ya existe una banda con ese nombre') end

    local coords = GetPedCoords(src)
    if not coords then return fail('Tu personaje no está en el mundo') end

    local color = Config.Colors[tonumber(payload.color)] and tonumber(payload.color) or 1
    local radius = cleanRadius(payload.radius) or Config.DefaultRadius
    local id = MySQL.insert.await('INSERT INTO jj_gangs (label, color, x, y, z, radius) VALUES (?, ?, ?, ?, ?, ?)', {
        label, color, coords.x, coords.y, coords.z, radius,
    })
    if not id then return fail('No se ha podido guardar la banda') end

    Gangs[id] = { id = id, label = label, color = color, x = coords.x, y = coords.y, z = coords.z, radius = radius, points = {}, members = {} }
    SyncWorld()
    local result = ok(('Banda %s creada. Su barrio está centrado donde estás'):format(label))
    result.id = id
    return result
end

function actions.territory(src, payload, gang)
    local radius = cleanRadius(payload.radius)
    local coords = GetPedCoords(src)
    if not radius or not coords then return fail('Datos no válidos') end

    gang.x, gang.y, gang.z, gang.radius = coords.x, coords.y, coords.z, radius
    MySQL.update.await('UPDATE jj_gangs SET x = ?, y = ?, z = ?, radius = ? WHERE id = ?', { gang.x, gang.y, gang.z, radius, gang.id })
    SyncWorld()
    return ok('Barrio actualizado')
end

function actions.radius(_, payload, gang)
    local radius = cleanRadius(payload.radius)
    if not radius then return fail('Radio no válido') end

    gang.radius = radius
    MySQL.update.await('UPDATE jj_gangs SET radius = ? WHERE id = ?', { radius, gang.id })
    SyncWorld()
    return ok('Radio actualizado')
end

function actions.rename(_, payload, gang)
    local label = cleanLabel(payload.label)
    if not label then return fail(('El nombre debe tener entre 2 y %d caracteres'):format(MAX_LABEL)) end
    if isLabelTaken(label, gang.id) then return fail('Ya existe una banda con ese nombre') end

    gang.label = label
    MySQL.update.await('UPDATE jj_gangs SET label = ? WHERE id = ?', { label, gang.id })
    for _, point in pairs(gang.points) do
        SetupPoint(gang, point)
    end
    SyncWorld()
    RefreshGang(gang.id)
    return ok('Nombre actualizado')
end

function actions.color(_, payload, gang)
    local color = tonumber(payload.color)
    if not Config.Colors[color] then return fail('Color no válido') end

    gang.color = color
    MySQL.update.await('UPDATE jj_gangs SET color = ? WHERE id = ?', { color, gang.id })
    SyncWorld()
    return ok('Color actualizado')
end

function actions.addPoint(src, payload, gang)
    local pointType = payload.type
    if not Config.PointTypes[pointType] then return fail('Tipo de punto no válido') end
    if pointType == 'garage' and not AreGaragesAvailable() then return fail(GARAGES_UNAVAILABLE) end

    local lab = nil
    if pointType == 'lab' then
        lab = payload.lab
        if not Config.Labs[lab] then return fail('Elige qué droga se fabrica') end
    end

    local coords, ped = GetPedCoords(src)
    if not coords then return fail('Tu personaje no está en el mundo') end

    local heading = GetEntityHeading(ped)
    local id = MySQL.insert.await('INSERT INTO jj_gang_points (gang_id, type, x, y, z, h, lab) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        gang.id, pointType, coords.x, coords.y, coords.z, heading, lab,
    })
    if not id then return fail('No se ha podido guardar el punto') end

    local point = { id = id, gang_id = gang.id, type = pointType, x = coords.x, y = coords.y, z = coords.z, h = heading, lab = lab }
    gang.points[id] = point
    SetupPoint(gang, point)
    RefreshGang(gang.id)
    return ok(('%s añadido donde estás'):format(Config.PointTypes[pointType].label))
end

function actions.removePoint(_, payload, gang)
    local point = gang.points[tonumber(payload.point)]
    if not point then return fail('El punto no existe') end

    deletePoint(gang, point)
    RefreshGang(gang.id)
    return ok('Punto eliminado')
end

function actions.movePoint(src, payload, gang)
    local point = gang.points[tonumber(payload.point)]
    if not point then return fail('El punto no existe') end
    if point.type == 'garage' and not AreGaragesAvailable() then return fail(GARAGES_UNAVAILABLE) end

    local coords, ped = GetPedCoords(src)
    if not coords then return fail('Tu personaje no está en el mundo') end

    point.x, point.y, point.z, point.h = coords.x, coords.y, coords.z, GetEntityHeading(ped)
    MySQL.update.await('UPDATE jj_gang_points SET x = ?, y = ?, z = ?, h = ? WHERE id = ?', { point.x, point.y, point.z, point.h, point.id })
    SetupPoint(gang, point)
    RefreshGang(gang.id)
    return ok('Punto movido')
end

function actions.memberAdd(_, payload, gang)
    local target = tonumber(payload.target)
    local rank = tonumber(payload.rank) or 0
    local player = target and JJ.GetPlayer(target)
    if not player then return fail('Ese jugador no está conectado o no ha elegido personaje') end
    if not Config.Ranks[rank] then return fail('Rango no válido') end

    setGangRank(gang, player.identifier, player.getName(), rank)
    Notify(target, ('Ahora eres %s de %s'):format(Config.Ranks[rank].name, gang.label), 'success')
    return ok(('%s añadido a %s'):format(player.getName(), gang.label))
end

function actions.memberRank(_, payload, gang)
    local rank = tonumber(payload.rank)
    local member = gang.members[payload.identifier]
    if not member then return fail('Ese jugador no está en la banda') end
    if not Config.Ranks[rank] then return fail('Rango no válido') end

    setGangRank(gang, payload.identifier, member.name, rank)
    return ok('Rango actualizado')
end

function actions.memberKick(_, payload, gang)
    local member = gang.members[payload.identifier]
    if not member then return fail('Ese jugador no está en la banda') end

    RemoveMember(payload.identifier)
    local player = JJ.GetPlayerByIdentifier(payload.identifier)
    if player then
        Notify(player.source, ('Te han sacado de %s'):format(gang.label), 'error')
    end
    return ok(('%s ya no está en la banda'):format(member.name))
end

function actions.removeGraffiti(_, payload, gang)
    if not RemoveGraffiti(tonumber(payload.graffiti), gang.id) then return fail('El grafiti no existe') end
    return ok('Grafiti borrado')
end

function actions.teleport(src, payload)
    local x, y, z = tonumber(payload.x), tonumber(payload.y), tonumber(payload.z)
    if not x or not y or not z then return fail('Coordenadas no válidas') end

    SetEntityCoords(GetPlayerPed(src), x, y, z, false, false, false, false)
    return ok('Te has teletransportado')
end

function actions.delete(_, _, gang)
    local online = GetOnlineMembers(gang.id)

    for _, point in pairs(gang.points) do
        deletePoint(gang, point)
    end
    for identifier in pairs(gang.members) do
        Members[identifier] = nil
    end
    RemoveGangGraffitis(gang.id)

    MySQL.update.await('DELETE FROM jj_gang_members WHERE gang_id = ?', { gang.id })
    MySQL.update.await('DELETE FROM jj_gangs WHERE id = ?', { gang.id })
    Gangs[gang.id] = nil

    SyncWorld()
    for _, src in ipairs(online) do
        RefreshPlayer(src)
        Notify(src, ('La banda %s ha desaparecido'):format(gang.label), 'error')
    end
    return ok('Banda eliminada')
end

lib.callback.register('jj_gangs:server:adminData', function(source)
    if not IsPlayerAceAllowed(tostring(source), Config.AdminAce) then return nil end

    local gangs = {}
    for _, gang in pairs(Gangs) do
        local points, members = {}, {}
        for _, point in pairs(gang.points) do
            points[#points + 1] = { id = point.id, type = point.type, lab = point.lab, x = point.x, y = point.y, z = point.z }
        end
        table.sort(points, function(a, b) return a.id < b.id end)

        for identifier, member in pairs(gang.members) do
            local player = JJ.GetPlayerByIdentifier(identifier)
            members[#members + 1] = {
                identifier = identifier, name = member.name, rank = member.rank,
                online = player ~= nil, source = player and player.source or nil,
            }
        end
        table.sort(members, function(a, b)
            if a.rank ~= b.rank then return a.rank > b.rank end
            return a.name < b.name
        end)

        gangs[#gangs + 1] = {
            id = gang.id, label = gang.label, color = gang.color, hex = GetColor(gang.color).hex,
            x = gang.x, y = gang.y, z = gang.z, radius = gang.radius,
            points = points, members = members, graffitis = GetGangGraffitis(gang.id),
        }
    end
    table.sort(gangs, function(a, b) return a.label < b.label end)

    local players = {}
    for _, src in pairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        local gang = player and Gangs[Members[player.identifier]]
        if player then
            players[#players + 1] = { id = src, name = player.getName(), gang = gang and gang.label or nil }
        end
    end
    table.sort(players, function(a, b) return a.id < b.id end)

    return { gangs = gangs, players = players }
end)

lib.callback.register('jj_gangs:server:admin', function(source, name, payload)
    if not IsPlayerAceAllowed(tostring(source), Config.AdminAce) then return fail('No tienes permiso') end

    local action = type(name) == 'string' and actions[name]
    if not action then return fail('Acción no válida') end
    payload = type(payload) == 'table' and payload or {}

    local gang = nil
    if name ~= 'create' and name ~= 'teleport' then
        gang = Gangs[tonumber(payload.gang)]
        if not gang then return fail('La banda no existe') end
    end

    local result = action(source, payload, gang)
    if result.ok and name ~= 'teleport' then
        print(('[jj_gangs] %s (%d): %s %s'):format(GetPlayerName(source) or '?', source, name, gang and gang.label or tostring(payload.label)))
    end
    return result
end)
