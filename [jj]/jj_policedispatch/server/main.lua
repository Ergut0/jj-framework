local config = lib.load('shared.main')

local ALERT_LIFETIME = 45 * 60 * 1000
local ALERT_COOLDOWN = 3000
local BLIP_INTERVAL = 1500
local NEARBY_GROUP = 8.0
local MAX_HISTORY = 100
local MAX_TEXT = 300

local alerts = {}
local alertCooldowns = {}
local nextAlertId = 1

local channels = {}       -- id = { id, freq, zone, name, members = { [citizenid] = miembro } }
local channelByFreq = {}
local memberChannel = {}  -- citizenid = id del canal
local units = {}          -- source = referencia en el mapa
local globalRadio = {}    -- frecuencia = { [source] = true }
local globalBySource = {} -- source = frecuencia
local directTalks = {}    -- source = lista de quienes le oyen
local radioHistory = {}
local speedZones = {}
local nextSpeedZone = 1

for _, info in ipairs(config.radioInfo) do
    for _, channel in ipairs(info.channels) do
        channels[channel.id] = { id = channel.id, freq = channel.freq, zone = info.zone, name = channel.name, members = {} }
        channelByFreq[channel.freq] = channels[channel.id]
    end
end

local function jobHasAccess(jobName)
    for _, name in ipairs(config.jobsAccess) do
        if name == jobName then return true end
    end
    return false
end

-- Devuelve el jugador si está de servicio en una facción con dispatch
local function getAgent(src)
    local player = JJ.GetPlayer(src)
    if not player then return nil end

    local job = player.getJob()
    if job.onDuty and jobHasAccess(job.name) then return player, job end
end

local function zoneAllowed(job, zone)
    if job.name == 'ambulance' then return zone == 'safmd' end
    return zone ~= 'safmd'
end

local function forEachAgent(callback)
    for _, src in pairs(JJ.GetPlayers()) do
        local player, job = getAgent(src)
        if player then callback(src, player, job) end
    end
end

local function getDepartment(player, job)
    if job.name == 'ambulance' then return 'safmd' end
    return player.getMetadata('department') or 'lspd'
end

-- ==================== Avisos ====================

local function cleanText(value, length)
    if type(value) ~= 'string' then return nil end

    local text = value:match('^%s*(.-)%s*$')
    return text ~= '' and text:sub(1, length or MAX_TEXT) or nil
end

local function sendToFaction(eventName, target, ...)
    local args = { ... }
    forEachAgent(function(src, _, job)
        if target == 'all' or target == job.name then
            TriggerClientEvent(eventName, src, table.unpack(args))
        end
    end)
end

local function pushAlert(data, position)
    local now = GetGameTimer()
    local target = data.targetFaction

    if target ~= 'all' and target ~= 'ambulance' then target = 'police' end

    local alert = {
        id = nextAlertId,
        title = cleanText(data.title, 80) or 'Aviso',
        textAlert = cleanText(data.textAlert),
        zone = cleanText(data.zone, 80),
        type = cleanText(data.type, 40) or 'general',
        plate = cleanText(data.plate, 12),
        vehModel = cleanText(data.vehModel, 40),
        vehColor = type(data.vehColor) == 'table' and data.vehColor or nil,
        targetFaction = target,
        distance = position,
        coords = position,
        timeSend = os.time() * 1000,
        createdAt = now,
    }

    nextAlertId += 1
    alerts[#alerts + 1] = alert
    sendToFaction('jj_policedispatch:client:alertReceived', target, alert)
    return alert.id
end

local function addAlert(src, data)
    if type(data) ~= 'table' then return end

    local now = GetGameTimer()
    if alertCooldowns[src] and now - alertCooldowns[src] < ALERT_COOLDOWN then return end
    alertCooldowns[src] = now

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local coords = GetEntityCoords(ped)
    return pushAlert(data, { x = coords.x, y = coords.y, z = coords.z })
end

-- Aviso desde otro recurso del servidor, en las coordenadas que indique
exports('AddAlert', function(data, coords)
    if type(data) ~= 'table' or type(coords) ~= 'table' then return nil end
    return pushAlert(data, { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 })
end)

RegisterNetEvent('jj_policedispatch:server:addNewAlert', function(data)
    addAlert(source, data)
end)

RegisterNetEvent('jj_policedispatch:server:addNewDrugAlert', function(data)
    if type(data) == 'table' then
        data.type = 'venta_drogas'
        data.targetFaction = 'police'
    end
    addAlert(source, data)
end)

lib.callback.register('jj_policedispatch:callback:getAlerts', function(source)
    if not getAgent(source) then return {} end
    return alerts
end)

lib.callback.register('jj_policedispatch:callback:getAlertById', function(source, id)
    if not getAgent(source) then return nil end

    for _, alert in ipairs(alerts) do
        if alert.id == id then return alert end
    end
end)

RegisterNetEvent('jj_policedispatch:server:assignAlertToUnit', function(alertId, unitName)
    if not getAgent(source) then return end

    for _, alert in ipairs(alerts) do
        if alert.id == alertId then
            alert.assignedUnit = cleanText(unitName, 40)
            sendToFaction('jj_policedispatch:client:alertUnitAssigned', alert.targetFaction, {
                alertId = alertId,
                assignedUnit = alert.assignedUnit,
            })
            return
        end
    end
end)

-- Marca el aviso en el GPS de quienes van en el mismo vehículo
RegisterNetEvent('jj_policedispatch:server:SyncWaypoint', function(coords, players, pinned, alertId)
    local src = source
    if not getAgent(src) or type(players) ~= 'table' then return end

    local origin = GetEntityCoords(GetPlayerPed(src))

    for _, target in ipairs(players) do
        local id = tonumber(target)
        if id and getAgent(id) and #(origin - GetEntityCoords(GetPlayerPed(id))) <= NEARBY_GROUP then
            TriggerClientEvent('jj_policedispatch:client:SyncWaypoint', id, coords, pinned, alertId)
        end
    end
end)

RegisterCommand('911', function(src, args)
    local text = table.concat(args, ' ')
    if src > 0 and text ~= '' then
        TriggerClientEvent('jj_policedispatch:callback:sendAlertCommand', src, text)
    end
end, false)

RegisterCommand('112', function(src, args)
    local text = table.concat(args, ' ')
    if src > 0 and text ~= '' then
        TriggerClientEvent('jj_policedispatch:callback:sendAmbulanceAlertCommand', src, text)
    end
end, false)

-- ==================== Radio ====================

local function getBadge(player)
    return player.getMetadata('badge_number') or '000'
end

local function buildMember(src, player, job, channelId)
    local state = Player(src).state

    return {
        source = src,
        id_group = channelId,
        citizenid = player.identifier,
        fullname = ('%s (%s)'):format(player.getName(), getBadge(player)),
        rank = job.gradeLabel,
        divisions = player.getMetadata('divisions') or {},
        status = state.radio_status ~= false,
        isMuted = state.radio_isMuted == true,
        color = units[src] and units[src].type or 0,
    }
end

local function channelList(channel)
    local list = {}
    for _, member in pairs(channel.members) do
        list[#list + 1] = member
    end
    return list
end

local function channelPayload(channel)
    return channel and { id = channel.id, members = channelList(channel) } or nil
end

local function refreshChannels(lastChannel, newChannel, movedCitizenId)
    local payload = {
        lastChannel = channelPayload(lastChannel),
        newChannel = channelPayload(newChannel),
        movedCitizenId = movedCitizenId,
        newRadioGroup = newChannel and newChannel.id or '',
    }

    forEachAgent(function(src)
        TriggerClientEvent('jj_policedispatch:client:refreshChannels', src, payload)
    end)
end

local function removeFromChannel(citizenid)
    local channel = channels[memberChannel[citizenid]]
    memberChannel[citizenid] = nil

    if channel then channel.members[citizenid] = nil end
    return channel
end

local function placeInChannel(src, player, job, channel)
    local last = removeFromChannel(player.identifier)

    channel.members[player.identifier] = buildMember(src, player, job, channel.id)
    memberChannel[player.identifier] = channel.id
    Player(src).state:set('radio_id_group', channel.id, true)

    return last
end

local function updateUnitLabel(src)
    local unit = units[src]
    local player = JJ.GetPlayer(src)
    if not unit or not player then return end

    local channel = channels[memberChannel[player.identifier]]
    unit.asig = channel and ('%s - %s'):format(getBadge(player), channel.name) or ('Agente #%s'):format(src)
end

lib.callback.register('jj_policedispatch:callback:getMembers', function(source)
    if not getAgent(source) then return {} end

    local members = {}
    for _, channel in pairs(channels) do
        for _, member in pairs(channel.members) do
            members[#members + 1] = member
        end
    end
    return members
end)

lib.callback.register('jj_policedispatch:callback:joinChannel', function(source, channelId)
    local player, job = getAgent(source)
    local channel = channels[channelId]
    if not player or not channel or not zoneAllowed(job, channel.zone) then return false end

    local last = placeInChannel(source, player, job, channel)
    updateUnitLabel(source)
    refreshChannels(last, channel, player.identifier)
    return true
end)

lib.callback.register('jj_policedispatch:callback:leaveChannel', function(source)
    local player = getAgent(source)
    if not player then return false end

    local last = removeFromChannel(player.identifier)
    Player(source).state:set('radio_id_group', '', true)
    updateUnitLabel(source)
    refreshChannels(last, nil, player.identifier)
    return true
end)

-- Mover a otro agente de canal: el mando desde el panel
lib.callback.register('jj_policedispatch:callback:moveMember', function(source, citizenid, _, newId)
    local _, job = getAgent(source)
    local channel = channels[newId]
    if not job or not channel or not job.isBoss or not zoneAllowed(job, channel.zone) then return false end

    local target = JJ.GetPlayerByIdentifier(citizenid)
    if not target then return false end

    local targetPlayer, targetJob = getAgent(target.source)
    if not targetPlayer then return false end

    local last = placeInChannel(target.source, targetPlayer, targetJob, channel)
    updateUnitLabel(target.source)
    TriggerClientEvent('jj_policedispatch:client:joinFreqOnMove', target.source, channel.freq, channel.zone)
    refreshChannels(last, channel, citizenid)
    return true
end)

local function setMemberStatus(src, status)
    local player = getAgent(src)
    if not player then return end

    Player(src).state:set('radio_status', status ~= false, true)

    local channel = channels[memberChannel[player.identifier]]
    if channel and channel.members[player.identifier] then
        channel.members[player.identifier].status = status ~= false
    end

    forEachAgent(function(id)
        TriggerClientEvent('jj_policedispatch:client:memberStatusChanged', id, {
            citizenid = player.identifier,
            status = status ~= false,
        })
    end)
end

RegisterNetEvent('jj_policedispatch:server:setMemberStatus', function(status)
    setMemberStatus(source, status)
end)

-- Los ocupantes del mismo vehículo cambian de estado juntos
local function nearbyGroup(src, targets)
    local list, seen = { src }, { [src] = true }
    if type(targets) ~= 'table' then return list end

    local origin = GetEntityCoords(GetPlayerPed(src))

    for _, target in ipairs(targets) do
        local id = tonumber(target)
        if id and not seen[id] and getAgent(id) and #(origin - GetEntityCoords(GetPlayerPed(id))) <= NEARBY_GROUP then
            seen[id] = true
            list[#list + 1] = id
        end
    end

    return list
end

RegisterNetEvent('jj_policedispatch:server:setMemberStatusGroup', function(status, targets)
    local src = source
    if not getAgent(src) then return end

    for _, id in ipairs(nearbyGroup(src, targets)) do
        setMemberStatus(id, status)
    end
end)

RegisterNetEvent('jj_policedispatch:server:setMemberMuted', function(isMuted)
    local src = source
    local player = getAgent(src)
    if not player then return end

    Player(src).state:set('radio_isMuted', isMuted == true, true)

    local channel = channels[memberChannel[player.identifier]]
    if channel and channel.members[player.identifier] then
        channel.members[player.identifier].isMuted = isMuted == true
    end

    forEachAgent(function(id)
        TriggerClientEvent('jj_policedispatch:client:memberMutedChanged', id, {
            citizenid = player.identifier,
            isMuted = isMuted == true,
        })
    end)
end)

local function stopDirectTalk(src)
    local targets = directTalks[src]
    if not targets then return end

    directTalks[src] = nil
    for _, id in ipairs(targets) do
        TriggerClientEvent('jj_policedispatch:client:receiveDirectTalk', id, src, false)
    end
    TriggerClientEvent('jj_policedispatch:client:stopDirectTalkSpeaker', src)
end

RegisterNetEvent('jj_policedispatch:server:startDirectTalk', function(channelId, freq)
    local src = source
    local _, job = getAgent(src)
    local channel = channels[channelId] or channelByFreq[tonumber(freq)]
    if not job or not channel or not zoneAllowed(job, channel.zone) then return end

    stopDirectTalk(src)

    local targets = {}
    for _, member in pairs(channel.members) do
        if member.source ~= src and not member.isMuted then
            targets[#targets + 1] = member.source
        end
    end

    directTalks[src] = targets
    for _, id in ipairs(targets) do
        TriggerClientEvent('jj_policedispatch:client:receiveDirectTalk', id, src, true)
    end
    TriggerClientEvent('jj_policedispatch:client:startDirectTalkSpeaker', src, targets)
end)

RegisterNetEvent('jj_policedispatch:server:stopDirectTalk', function()
    stopDirectTalk(source)
end)

local function syncGlobalRadio(freq)
    local members = globalRadio[freq]
    if not members then return end

    for src in pairs(members) do
        local others = {}
        for id in pairs(members) do
            if id ~= src then others[tostring(id)] = true end
        end
        TriggerClientEvent('jj_policedispatch:syncGlobalRadio', src, others)
    end
end

local function unregisterGlobalRadio(src)
    local freq = globalBySource[src]
    if not freq then return end

    globalBySource[src] = nil
    if globalRadio[freq] then globalRadio[freq][src] = nil end
    syncGlobalRadio(freq)
end

RegisterNetEvent('jj_policedispatch:registerGlobalRadio', function(freq)
    local src = source
    freq = tonumber(freq)
    if not getAgent(src) or not freq then return end

    unregisterGlobalRadio(src)
    globalRadio[freq] = globalRadio[freq] or {}
    globalRadio[freq][src] = true
    globalBySource[src] = freq
    syncGlobalRadio(freq)
end)

RegisterNetEvent('jj_policedispatch:unRegisterGlobalRadio', function()
    unregisterGlobalRadio(source)
end)

-- Solo se avisa a quien está en la misma radio global: lo que envía el cliente no se usa
RegisterNetEvent('jj_policedispatch:server:memberTalking', function(talking)
    local src = source
    local freq = globalBySource[src]
    if not freq or not getAgent(src) then return end

    for id in pairs(globalRadio[freq] or {}) do
        if id ~= src then
            TriggerClientEvent('jj_policedispatch:client:memberTalking', id, src, talking == true)
        end
    end
end)

local function leaveRadio(src, identifier)
    stopDirectTalk(src)
    unregisterGlobalRadio(src)

    if identifier then
        local last = removeFromChannel(identifier)
        if last then refreshChannels(last, nil, identifier) end
    end
end

RegisterNetEvent('jj_policedispatch:memberOffDuty', function()
    local src = source
    local player = JJ.GetPlayer(src)
    leaveRadio(src, player and player.identifier)
end)

-- ==================== Referencias en el mapa ====================

local function addUnit(src, color, blipId)
    local player, job = getAgent(src)
    if not player then return end

    units[src] = {
        source = src,
        type = tonumber(color) or 0,
        bId = tonumber(blipId) or 1,
        badge_number = getBadge(player),
        department = getDepartment(player, job),
        hidden = false,
    }
    updateUnitLabel(src)
end

local function removeUnit(src)
    if not units[src] then return end

    units[src] = nil
    forEachAgent(function(id)
        TriggerClientEvent('jj_policedispatch:removeUnit', id, src)
    end)
end

RegisterNetEvent('jj_policedispatch:addUnit', function(color, blipId)
    addUnit(source, color, blipId)
end)

lib.callback.register('jj_policedispatch:refreshReference', function(source, duty)
    if duty and getAgent(source) then
        addUnit(source, 0, 1)
    else
        removeUnit(source)
        TriggerClientEvent('jj_policedispatch:removeBlips', source)
    end
    return true
end)

local function updateBlip(src, color, blipId)
    local unit = units[src]
    if not unit then return end

    unit.type = tonumber(color) or unit.type
    unit.bId = tonumber(blipId) or unit.bId

    local player = JJ.GetPlayer(src)
    local channel = player and channels[memberChannel[player.identifier]]
    if channel and channel.members[player.identifier] then
        channel.members[player.identifier].color = unit.type
    end

    TriggerClientEvent('jj_policedispatch:client:refreshStatusNUI', src, { colorId = unit.type, blipId = unit.bId })
end

RegisterNetEvent('jj_policedispatch:server:UpdateBlip', function(color, blipId)
    updateBlip(source, color, blipId)
end)

RegisterNetEvent('jj_policedispatch:server:UpdateBlipGroup', function(color, blipId, targets)
    local src = source
    if not getAgent(src) then return end

    for _, id in ipairs(nearbyGroup(src, targets)) do
        updateBlip(id, color, blipId)
    end
end)

RegisterNetEvent('jj_policedispatch:server:disableOwnReference', function()
    local src = source
    if units[src] then
        units[src].hidden = true
        forEachAgent(function(id)
            TriggerClientEvent('jj_policedispatch:removeUnit', id, src)
        end)
    end
end)

RegisterNetEvent('jj_policedispatch:server:enableOwnReference', function()
    if units[source] then units[source].hidden = false end
end)

CreateThread(function()
    while true do
        Wait(BLIP_INTERVAL)

        local list = {}
        for src, unit in pairs(units) do
            local ped = GetPlayerPed(src)
            if ped ~= 0 and not unit.hidden then
                local coords = GetEntityCoords(ped)
                unit.coords = { x = coords.x, y = coords.y, z = coords.z }
                unit.heading = GetEntityHeading(ped)
                list[#list + 1] = unit
            end
        end

        if #list > 0 then
            forEachAgent(function(id)
                TriggerClientEvent('jj_policedispatch:updateBlips', id, list)
            end)
        end
    end
end)

-- ==================== Cortes de tráfico ====================

RegisterNetEvent('jj_policedispatch:server:StopTraffic', function(position)
    if not getAgent(source) or type(position) ~= 'vector3' and type(position) ~= 'table' then return end

    local id = nextSpeedZone
    nextSpeedZone += 1
    speedZones[id] = { x = position.x, y = position.y, z = position.z }
    TriggerClientEvent('jj_policedispatch:client:AddSpeedZone', -1, id, speedZones[id])
end)

RegisterNetEvent('jj_policedispatch:server:ResumeTraffic', function(position)
    if not getAgent(source) or type(position) ~= 'vector3' and type(position) ~= 'table' then return end

    local center = vector3(position.x, position.y, position.z)
    for id, zone in pairs(speedZones) do
        if #(center - vector3(zone.x, zone.y, zone.z)) <= 90.0 then
            speedZones[id] = nil
        end
    end
    TriggerClientEvent('jj_policedispatch:client:RemoveSpeedZoneRadius', -1, position, 90.0)
end)

RegisterNetEvent('jj_policedispatch:server:vehicleModeChanged', function() end)

-- ==================== Chat de radio ====================

local function radioMessage(src, tag, target, color, text)
    local player, job = getAgent(src)
    if not player or job.name ~= target then return end

    text = cleanText(text)
    if not text then return end

    local header = ('[%s] %s'):format(tag, player.getName())
    radioHistory[#radioHistory + 1] = {
        id = #radioHistory + 1,
        tag = tag,
        header = header,
        msg = text,
        color = color,
        time = os.date('%H:%M'),
    }
    if #radioHistory > MAX_HISTORY then table.remove(radioHistory, 1) end

    forEachAgent(function(id, _, otherJob)
        if otherJob.name == target then
            TriggerClientEvent('chat:addMessage', id, { args = { header, text } })
            TriggerClientEvent('jj_rpchat:addMessage', id, text, src, tag, header, color)
        end
    end)
end

RegisterCommand('rpol', function(src, args)
    radioMessage(src, 'RPOL', 'police', '#3b82f6', table.concat(args, ' '))
end, false)

RegisterCommand('rems', function(src, args)
    radioMessage(src, 'REMS', 'ambulance', '#ef4444', table.concat(args, ' '))
end, false)

lib.callback.register('jj_policedispatch:callback:getRadioHistory', function(source)
    if not getAgent(source) then return {} end
    return radioHistory
end)

-- ==================== Facción y limpieza ====================

RegisterNetEvent('jj_policedispatch:server:addPlayerFaction', function()
    local src = source
    if getAgent(src) and not units[src] then addUnit(src, 0, 1) end
end)

RegisterNetEvent('jj_policedispatch:server:removePlayerFaction', function()
    local src = source
    local player = JJ.GetPlayer(src)
    removeUnit(src)
    leaveRadio(src, player and player.identifier)
end)

AddEventHandler('jj:server:playerDropped', function(src)
    alertCooldowns[src] = nil
    removeUnit(src)

    local player = JJ.GetPlayer(src)
    leaveRadio(src, player and player.identifier)
end)

CreateThread(function()
    while true do
        Wait(60000)

        local now = GetGameTimer()
        for index = #alerts, 1, -1 do
            if now - alerts[index].createdAt > ALERT_LIFETIME then
                local id = alerts[index].id
                table.remove(alerts, index)
                forEachAgent(function(src)
                    TriggerClientEvent('jj_policedispatch:client:alertRemoved', src, id)
                end)
            end
        end
    end
end)

-- Agentes del mismo canal, para añadirlos a un informe desde la tablet
exports('GetChannelMembers', function(src)
    local player = JJ.GetPlayer(src)
    local channel = player and channels[memberChannel[player.identifier]]
    return channel and channelList(channel) or {}
end)
