local invites = {} -- [source invitado] = { gang, expires }

function SetMember(identifier, name, gang, rank)
    local previous = Gangs[Members[identifier]]
    if previous then
        previous.members[identifier] = nil
    end

    gang.members[identifier] = { name = name, rank = rank }
    Members[identifier] = gang.id
    MySQL.query.await('REPLACE INTO jj_gang_members (identifier, gang_id, name, `rank`) VALUES (?, ?, ?, ?)', { identifier, gang.id, name, rank })

    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then
        RefreshPlayer(player.source)
    end
end

function RemoveMember(identifier)
    local gang = Gangs[Members[identifier]]
    if gang then
        gang.members[identifier] = nil
    end
    Members[identifier] = nil
    MySQL.update.await('DELETE FROM jj_gang_members WHERE identifier = ?', { identifier })

    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then
        RefreshPlayer(player.source)
    end
end

local function fail(message)
    return { ok = false, message = message }
end

local function ok(message)
    return { ok = true, message = message }
end

-- Devuelve quién gestiona la banda: tiene que estar junto a un punto de gestión
local function getManager(src)
    local player, gang, member = GetMember(src)
    if not gang or not HasNearPoint(src, gang, 'boss') then return nil end
    return player, gang, member
end

lib.callback.register('jj_gangs:server:getRoster', function(source)
    local player, gang, member = getManager(source)
    if not player then return nil end

    local roster = {}
    for identifier, data in pairs(gang.members) do
        roster[#roster + 1] = {
            identifier = identifier,
            name = data.name,
            rank = data.rank,
            online = JJ.GetPlayerByIdentifier(identifier) ~= nil,
            isSelf = identifier == player.identifier,
        }
    end
    table.sort(roster, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.name < b.name
    end)

    return {
        label = gang.label,
        rank = member.rank,
        canInvite = HasPermission(member.rank, 'canInvite'),
        canPromote = HasPermission(member.rank, 'canPromote'),
        canKick = HasPermission(member.rank, 'canKick'),
        roster = roster,
    }
end)

lib.callback.register('jj_gangs:server:invite', function(source, targetId)
    local player, gang, member = getManager(source)
    if not player then return fail('Tienes que estar junto al punto de gestión') end
    if not HasPermission(member.rank, 'canInvite') then return fail('No tienes permiso para invitar') end

    local target = tonumber(targetId)
    local targetPlayer = target and JJ.GetPlayer(target)
    if not targetPlayer then return fail('Ese jugador no está conectado') end
    if target == source then return fail('No puedes invitarte a ti mismo') end
    if Members[targetPlayer.identifier] then return fail('Ese jugador ya está en una banda') end

    local coords = GetPedCoords(source)
    if not coords or not IsNear(target, coords.x, coords.y, coords.z, Config.InviteDistance) then
        return fail('Ese jugador está demasiado lejos')
    end

    invites[target] = { gang = gang.id, expires = os.time() + Config.InviteTimeout }
    TriggerClientEvent('jj_gangs:client:invite', target, gang.label, player.getName())
    return ok('Invitación enviada')
end)

RegisterNetEvent('jj_gangs:server:answerInvite', function(accepted)
    local src = source
    local invite = invites[src]
    invites[src] = nil
    if not invite or accepted ~= true or invite.expires < os.time() then return end

    local player = JJ.GetPlayer(src)
    local gang = Gangs[invite.gang]
    if not player or not gang or Members[player.identifier] then return end

    SetMember(player.identifier, player.getName(), gang, 0)
    for _, member in ipairs(GetOnlineMembers(gang.id)) do
        Notify(member, ('%s se ha unido a la banda'):format(player.getName()), 'success')
    end
end)

lib.callback.register('jj_gangs:server:setRank', function(source, identifier, rank)
    local player, gang, member = getManager(source)
    if not player then return fail('Tienes que estar junto al punto de gestión') end
    if not HasPermission(member.rank, 'canPromote') then return fail('No tienes permiso') end

    rank = tonumber(rank)
    local target = gang.members[identifier]
    if not target or not rank or not Config.Ranks[rank] then return fail('Datos no válidos') end
    if identifier == player.identifier then return fail('No puedes cambiar tu propio rango') end

    local isBoss = Config.Ranks[member.rank].isBoss == true
    if not isBoss and (target.rank >= member.rank or rank >= member.rank) then
        return fail('Solo puedes gestionar rangos inferiores al tuyo')
    end

    SetMember(identifier, target.name, gang, rank)

    -- Nombrar a otro jefe traspasa la banda
    if isBoss and Config.Ranks[rank].isBoss then
        SetMember(player.identifier, player.getName(), gang, member.rank - 1)
    end
    return ok('Rango actualizado')
end)

lib.callback.register('jj_gangs:server:kick', function(source, identifier)
    local player, gang, member = getManager(source)
    if not player then return fail('Tienes que estar junto al punto de gestión') end
    if not HasPermission(member.rank, 'canKick') then return fail('No tienes permiso') end

    local target = gang.members[identifier]
    if not target then return fail('Ese jugador no está en la banda') end
    if identifier == player.identifier then return fail('No puedes expulsarte a ti mismo') end
    if target.rank >= member.rank then return fail('Solo puedes expulsar a rangos inferiores al tuyo') end

    RemoveMember(identifier)
    local kicked = JJ.GetPlayerByIdentifier(identifier)
    if kicked then
        Notify(kicked.source, ('Te han expulsado de %s'):format(gang.label), 'error')
    end
    return ok('Miembro expulsado')
end)

lib.callback.register('jj_gangs:server:leave', function(source)
    local player, gang, member = GetMember(source)
    if not gang then return fail('No estás en ninguna banda') end
    if Config.Ranks[member.rank].isBoss then return fail('Traspasa la banda a otro miembro antes de salir') end

    RemoveMember(player.identifier)
    return ok(('Has salido de %s'):format(gang.label))
end)

-- Puntos que abre el servidor

RegisterNetEvent('jj_gangs:server:openStash', function(pointId)
    local src = source
    local _, gang = GetMember(src)
    local point = gang and GetNearPoint(src, gang, pointId, 'stash')
    if point then
        exports.ox_inventory:forceOpenInventory(src, 'stash', ('jj_gang_stash_%d'):format(point.id))
    end
end)

AddEventHandler('playerDropped', function()
    invites[source] = nil
end)
