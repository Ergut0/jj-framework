local dutyStarted = {}

local function agentFromRow(row)
    local citizen = CitizenFromRow(row, row)

    return {
        citizen = citizen,
        badge_number = row.badge_number or '000',
        rank_id = row.job_grade,
        department = row.department or 'lspd',
        divisions = DecodeJson(row.divisions) or {},
        horastrabajo = math.floor((row.duty_seconds or 0) / 360) / 10,
    }
end

local AGENT_SELECT = [[
    SELECT p.id, p.identifier, p.name, p.charinfo, p.job_grade,
        a.badge_number, a.department, a.divisions, a.duty_seconds, c.image_url
    FROM jj_players p
    LEFT JOIN jj_policetablet_agents a ON a.citizenid = p.identifier
    LEFT JOIN jj_policetablet_citizens c ON c.citizenid = p.identifier
]]

local function getAgents(extraWhere, ...)
    local rows = MySQL.query.await(AGENT_SELECT .. ' WHERE p.job = ?' .. (extraWhere or '') .. ' ORDER BY p.job_grade DESC, p.name LIMIT 200', { POLICE_JOB, ... }) or {}
    local agents = {}

    for index, row in ipairs(rows) do
        agents[index] = agentFromRow(row)
    end

    return agents
end

local function getAgentByCitizenId(citizenid)
    -- El trabajo solo se guarda en la base de datos cada cierto tiempo: si está conectado manda el actual
    local online = JJ.GetPlayerByIdentifier(citizenid)
    if online and online.getJob().name ~= POLICE_JOB then return nil end

    local row
    if online then
        row = MySQL.single.await(AGENT_SELECT .. ' WHERE p.identifier = ?', { citizenid })
    else
        row = MySQL.single.await(AGENT_SELECT .. ' WHERE p.job = ? AND p.identifier = ?', { POLICE_JOB, citizenid })
    end
    if not row then return nil end

    local agent = agentFromRow(row)
    if online then agent.rank_id = online.getJob().grade end
    agent.citizen.phoneNumber = GetPhoneNumber(citizenid)
    agent.infractions = MySQL.query.await('SELECT id, title, description, author, date FROM jj_policetablet_infractions WHERE citizenid = ? ORDER BY id DESC', { citizenid }) or {}
    return agent
end

local function saveDutyTime(src, citizenid)
    local started = dutyStarted[src]
    if not started or not citizenid then return end

    dutyStarted[src] = nil
    MySQL.query.await([[INSERT INTO jj_policetablet_agents (citizenid, duty_seconds) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE duty_seconds = duty_seconds + VALUES(duty_seconds)]], { citizenid, os.time() - started })
end

AddEventHandler('jj:server:playerLoaded', function(src)
    local player = GetAgent(src)
    if player and player.getJob().onDuty then dutyStarted[src] = os.time() end
end)

AddEventHandler('jj:server:dutyChanged', function(src, onDuty)
    local player = GetAgent(src)
    if not player then return end

    if onDuty then
        dutyStarted[src] = dutyStarted[src] or os.time()
    else
        saveDutyTime(src, player.identifier)
    end
end)

AddEventHandler('jj:server:jobChanged', function(src, job, oldJob)
    local player = JJ.GetPlayer(src)
    if not player then return end

    -- La lista de agentes se lee de la base de datos: un cambio de trabajo tiene que verse enseguida
    if job.name == POLICE_JOB or (oldJob and oldJob.name == POLICE_JOB) then
        MySQL.update('UPDATE jj_players SET job = ?, job_grade = ? WHERE identifier = ?', { job.name, job.grade, player.identifier })
    end

    if job.name == POLICE_JOB and job.onDuty then
        dutyStarted[src] = dutyStarted[src] or os.time()
    elseif oldJob and oldJob.name == POLICE_JOB then
        saveDutyTime(src, player.identifier)
    end
end)

AddEventHandler('jj:server:playerDropped', function(src)
    local player = JJ.GetPlayer(src)
    if player then saveDutyTime(src, player.identifier) end
    dutyStarted[src] = nil
end)

lib.callback.register('jj_policetablet:callback:getRanks', function(source)
    WaitForDatabase()
    return GetAgent(source) and GetRanks() or {}
end)

lib.callback.register('jj_policetablet:callback:getPlayerData', function(source)
    WaitForDatabase()

    local player = GetAgent(source)
    if not player then return false end

    local agent = getAgentByCitizenId(player.identifier)
    if not agent then return false end

    agent.rank_id = player.getJob().grade
    agent.onDuty = player.getJob().onDuty == true
    return agent
end)

lib.callback.register('jj_policetablet:callback:toggleDutyStatus', function(source)
    local player = GetAgent(source)
    if not player then return { success = false } end

    local onDuty = not player.getJob().onDuty
    player.setDuty(onDuty)
    return { success = true, onDuty = onDuty }
end)

lib.callback.register('jj_policetablet:callback:getAgents', function(source)
    return GetAgent(source) and getAgents() or {}
end)

lib.callback.register('jj_policetablet:callback:getAgentById', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' then return nil end
    return getAgentByCitizenId(data.citizenid)
end)

local function filterAgents(term)
    local pattern = SearchPattern(term)
    return getAgents(' AND (p.name LIKE ? OR p.identifier LIKE ? OR a.badge_number LIKE ?)', pattern, pattern, pattern)
end

lib.callback.register('jj_policetablet:callback:getAgentsByFilter', function(source, term)
    return GetAgent(source) and filterAgents(term) or {}
end)

lib.callback.register('jj_policetablet:callback:searchAgents', function(source, term)
    return GetAgent(source) and filterAgents(term) or {}
end)

lib.callback.register('jj_policetablet:callback:getFrequencyAgents', function(source)
    if not GetAgent(source) then return {} end

    local agents = {}
    for _, member in ipairs(exports.jj_policedispatch:GetChannelMembers(source)) do
        local agent = getAgentByCitizenId(member.citizenid)
        if agent then agents[#agents + 1] = agent end
    end
    return agents
end)

lib.callback.register('jj_policetablet:callback:updateAgent', function(source, data)
    if not HasPerm(source, 'agents.edit') or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return false end

    local grade = math.floor(tonumber(data.rank_id) or -1)
    local validRank = false
    for _, rank in ipairs(GetRanks()) do
        if rank.grade == grade then validRank = true end
    end
    if not validRank then return false end

    local badge = CleanText(tostring(data.badge_number or ''), 10)
    local department = CleanText(data.department, 20) or 'lspd'
    local divisions = {}
    for _, division in ipairs(type(data.divisions) == 'table' and data.divisions or {}) do
        local name = CleanText(division, 30)
        if name then divisions[#divisions + 1] = name end
    end

    MySQL.query.await([[INSERT INTO jj_policetablet_agents (citizenid, badge_number, department, divisions) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE badge_number = VALUES(badge_number), department = VALUES(department), divisions = VALUES(divisions)]], {
        data.citizenid, badge, department, json.encode(divisions),
    })

    SetCitizenMetadata(data.citizenid, 'badge_number', badge)
    SetCitizenMetadata(data.citizenid, 'department', department)
    SetCitizenMetadata(data.citizenid, 'divisions', divisions)

    local target = JJ.GetPlayerByIdentifier(data.citizenid)
    if target then
        if target.getJob().name == POLICE_JOB then target.setJob(POLICE_JOB, grade) end
    else
        MySQL.update.await('UPDATE jj_players SET job_grade = ? WHERE identifier = ? AND job = ?', { grade, data.citizenid, POLICE_JOB })
    end

    return true
end)

lib.callback.register('jj_policetablet:callback:addAgentBySourceId', function(source, data)
    if not HasPerm(source, 'agents.add') or type(data) ~= 'table' then return false end

    local target = JJ.GetPlayer(tonumber(data.sourceId) or -1)
    if not target then return false end

    MySQL.query.await('INSERT IGNORE INTO jj_policetablet_agents (citizenid) VALUES (?)', { target.identifier })
    return target.setJob(POLICE_JOB, 0) == true
end)

lib.callback.register('jj_policetablet:callback:fireAgent', function(source, data)
    if not HasPerm(source, 'agents.edit') or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return false end

    local target = JJ.GetPlayerByIdentifier(data.citizenid)
    if target then
        if target.getJob().name ~= POLICE_JOB then return false end
        target.setJob(JJ.Config.DefaultJob, 0)
    else
        MySQL.update.await('UPDATE jj_players SET job = ?, job_grade = 0 WHERE identifier = ? AND job = ?', {
            JJ.Config.DefaultJob, data.citizenid, POLICE_JOB,
        })
    end

    MySQL.query.await('DELETE FROM jj_policetablet_agents WHERE citizenid = ?', { data.citizenid })
    return true
end)

lib.callback.register('jj_policetablet:callback:resetAgentWorkHours', function(source, data)
    if not HasPerm(source, 'agents.edit') or type(data) ~= 'table' then return { success = false } end

    MySQL.update.await('UPDATE jj_policetablet_agents SET duty_seconds = 0 WHERE citizenid = ?', { data.citizenid })
    local target = JJ.GetPlayerByIdentifier(data.citizenid)
    if target and dutyStarted[target.source] then dutyStarted[target.source] = os.time() end
    return { success = true }
end)

lib.callback.register('jj_policetablet:callback:addAgentInfraction', function(source, data)
    if not HasPerm(source, 'agents.edit') or type(data) ~= 'table' then return nil end

    local title = CleanText(data.title, 120)
    if not title or type(data.citizenid) ~= 'string' then return nil end

    local author = JJ.GetPlayer(source).getName()
    local date = Today()
    local description = CleanText(data.description, 2000)
    local id = MySQL.insert.await('INSERT INTO jj_policetablet_infractions (citizenid, title, description, author, date) VALUES (?, ?, ?, ?, ?)', {
        data.citizenid, title, description, author, date,
    })

    return { id = id, title = title, description = description or '', author = author, date = date }
end)

lib.callback.register('jj_policetablet:callback:deleteAgentInfraction', function(source, data)
    if not HasPerm(source, 'agents.edit') or type(data) ~= 'table' then return false end

    MySQL.query.await('DELETE FROM jj_policetablet_infractions WHERE id = ? AND citizenid = ?', { data.infractionId, data.citizenid })
    return true
end)

lib.callback.register('jj_policetablet:callback:getAgentIncidents', function(source, citizenid)
    if not GetAgent(source) then return {} end

    return MySQL.query.await([[SELECT id, title, status, date FROM jj_policetablet_cases
        WHERE kind = 'incident' AND (creator_citizenid = ? OR data LIKE ?) ORDER BY id DESC LIMIT 100]], {
        citizenid, SearchPattern(citizenid),
    }) or {}
end)

lib.callback.register('jj_policetablet:callback:getAgentBills', function(source, data)
    if not GetAgent(source) or type(data) ~= 'table' then return {} end

    return MySQL.query.await([[SELECT id, amount, title, jail_time, payed, date, agent_name AS agentName, agent_badge AS agentBadge, id_article
        FROM jj_policetablet_bills WHERE agent_citizenid = ? ORDER BY id DESC LIMIT 100]], { data.citizenid }) or {}
end)

lib.callback.register('jj_policetablet:callback:getOnDutyAgents', function(source)
    if not GetAgent(source) then return {} end

    local agents = {}
    for _, src in pairs(JJ.GetPlayers()) do
        local player = GetAgent(src)
        if player and player.getJob().onDuty then
            local coords = GetEntityCoords(GetPlayerPed(src))
            agents[#agents + 1] = {
                source = src,
                badge_number = player.getMetadata('badge_number') or '000',
                asig = ('%s - Patrulla'):format(player.getMetadata('badge_number') or '000'),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                heading = GetEntityHeading(GetPlayerPed(src)),
                is_self = src == source,
                department = player.getMetadata('department') or 'lspd',
            }
        end
    end
    return agents
end)

lib.callback.register('jj_policetablet:callback:getOnDutyAgentDetails', function(source, target)
    if not GetAgent(source) then return nil end

    local player = GetAgent(tonumber(target) or -1)
    if not player then return nil end

    local job = player.getJob()
    local first, last = (player.getName() or ''):match('^(%S+)%s*(.*)$')

    return {
        source = player.source,
        citizen = { firstname = first or '', lastname = last or '', citizenid = player.identifier },
        badge_number = player.getMetadata('badge_number') or '000',
        rank_id = job.grade,
        rank_label = job.gradeLabel,
        department = player.getMetadata('department') or 'lspd',
        divisions = player.getMetadata('divisions') or {},
        is_self = player.source == source,
    }
end)

lib.callback.register('jj_policetablet:callback:getRanksSettings', function(source)
    WaitForDatabase()
    if not GetAgent(source) then return {} end

    local ranks = GetRanks()
    for _, rank in ipairs(ranks) do
        rank.permissions = GetRankPermissions(rank.grade)
    end
    return ranks
end)

lib.callback.register('jj_policetablet:callback:saveRankPermissions', function(source, data)
    local player = GetAgent(source)
    if not player or not player.getJob().isBoss or type(data) ~= 'table' then return { success = false, message = 'no_permission' } end

    local grade = math.floor(tonumber(data.rankGrade) or -1)
    local permissions = {}
    for _, value in ipairs(type(data.permissions) == 'table' and data.permissions or {}) do
        local name = CleanText(value, 40)
        if name then permissions[#permissions + 1] = name end
    end

    MySQL.query.await('INSERT INTO jj_policetablet_ranks (grade, permissions) VALUES (?, ?) ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)', {
        grade, json.encode(permissions),
    })
    return { success = true }
end)

lib.callback.register('jj_policetablet:callback:canUseCamera', function(source)
    return GetAgent(source) ~= nil
end)

-- La clave se pone en server.cfg: set jj_policetablet:fivemanage "clave"
lib.callback.register('jj_policetablet:callback:getFivemanageConfig', function(source)
    if not GetAgent(source) then return false end

    return { url = 'https://api.fivemanage.com/api/image', apiKey = GetConvar('jj_policetablet:fivemanage', '') }
end)
