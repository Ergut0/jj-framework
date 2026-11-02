-- Cárcel federal. El tiempo solo corre con el preso conectado
local MAX_MINUTES = 600

local function setJailed(citizenid, minutes)
    SetCitizenMetadata(citizenid, 'injail', minutes > 0 and minutes or nil)

    if minutes > 0 then
        MySQL.query.await('INSERT INTO jj_policetablet_jail (citizenid, minutes) VALUES (?, ?) ON DUPLICATE KEY UPDATE minutes = VALUES(minutes)', { citizenid, minutes })
    else
        MySQL.query.await('DELETE FROM jj_policetablet_jail WHERE citizenid = ?', { citizenid })
    end
end

local function findTarget(reference)
    local id = tonumber(reference)
    return (id and JJ.GetPlayer(id)) or JJ.GetPlayerByIdentifier(tostring(reference):upper()) or JJ.GetPlayerByIdentifier(tostring(reference))
end

lib.callback.register('jj_policetablet:callback:sendToFederal', function(source, data)
    if not HasPerm(source, 'federal.access') or type(data) ~= 'table' then
        return { success = false, message = 'No tienes permiso' }
    end

    local minutes = math.floor(tonumber(data.time) or 0)
    if minutes < 1 or minutes > MAX_MINUTES then
        return { success = false, message = ('El tiempo debe estar entre 1 y %d minutos'):format(MAX_MINUTES) }
    end

    local target = findTarget(data.targetId)
    if not target then
        return { success = false, message = 'La persona no está conectada' }
    end

    setJailed(target.identifier, minutes)
    TriggerClientEvent('jj_policetablet:client:teleportToFederal', target.source, minutes)
    return { success = true }
end)

lib.callback.register('jj_policetablet:callback:getJailedPlayers', function(source)
    WaitForDatabase()
    if not HasPerm(source, 'federal.access') then return {} end

    local rows = MySQL.query.await([[SELECT j.minutes, p.id, p.identifier, p.name, p.charinfo, c.image_url
        FROM jj_policetablet_jail j
        INNER JOIN jj_players p ON p.identifier = j.citizenid
        LEFT JOIN jj_policetablet_citizens c ON c.citizenid = j.citizenid
        ORDER BY j.minutes DESC]]) or {}

    local jailed = {}
    for index, row in ipairs(rows) do
        local citizen = CitizenFromRow(row, row)
        jailed[index] = {
            id = row.id,
            citizenid = row.identifier,
            imageUrl = row.image_url,
            firstname = citizen.firstname,
            lastname = citizen.lastname,
            injail = row.minutes,
        }
    end
    return jailed
end)

lib.callback.register('jj_policetablet:callback:releaseJailedPlayer', function(source, data)
    if not HasPerm(source, 'federal.access') or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then
        return { success = false }
    end

    setJailed(data.citizenid, 0)
    local target = JJ.GetPlayerByIdentifier(data.citizenid)
    if target then
        TriggerClientEvent('jj_policetablet:client:teleportToRelease', target.source)
    end
    return { success = true }
end)

-- El aviso del cliente solo vale cuando el servidor también da la condena por cumplida
RegisterNetEvent('jj_policetablet:server:resetJail', function()
    local player = JJ.GetPlayer(source)
    if not player then return end

    local minutes = MySQL.scalar.await('SELECT minutes FROM jj_policetablet_jail WHERE citizenid = ?', { player.identifier })
    if not minutes or minutes <= 1 then
        setJailed(player.identifier, 0)
    end
end)

CreateThread(function()
    WaitForDatabase()

    while true do
        Wait(60000)

        for _, src in pairs(JJ.GetPlayers()) do
            local player = JJ.GetPlayer(src)
            -- Sin condena, el objeto del framework no devuelve ningún valor: tonumber() fallaría
            local injail = player and player.getMetadata('injail')
            local minutes = tonumber(injail)
            if minutes and minutes > 1 then
                setJailed(player.identifier, minutes - 1)
            end
        end
    end
end)
