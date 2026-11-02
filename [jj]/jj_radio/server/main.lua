-- Radio civil. Objeto, frecuencia y canal se comprueban siempre aquí
local frequencies = {} -- frecuencia en décimas -> source -> true
local members = {}     -- source -> { tenths, channel }
local viewers = {}     -- source con el panel abierto
local invites = {}     -- source invitado -> frecuencia en décimas -> { from, expires }
local lastChange = {}
local lastInvite = {}
local lastSave = {}

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_radio_frequencies` (
            `identifier` VARCHAR(60) NOT NULL,
            `frequency` INT UNSIGNED NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            PRIMARY KEY (`identifier`, `frequency`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- Las frecuencias se guardan en décimas para no comparar decimales
local function toTenths(frequency)
    if type(frequency) ~= 'number' then return nil end

    local scaled = frequency * 10
    local tenths = math.floor(scaled + 0.5)
    if math.abs(scaled - tenths) > 0.001 then return nil end
    if tenths < math.floor(Config.MinFrequency * 10 + 0.5) or tenths > math.floor(Config.MaxFrequency * 10 + 0.5) then
        return nil
    end
    return tenths
end

local function hasRadio(source)
    return exports.ox_inventory:GetItemCount(source, Config.RadioItem) > 0
end

local function countMembers(tenths)
    local count = 0
    for _ in pairs(frequencies[tenths] or {}) do count = count + 1 end
    return count
end

local function syncFrequency(tenths)
    local count = countMembers(tenths)
    for source in pairs(frequencies[tenths] or {}) do
        if viewers[source] then
            TriggerClientEvent('jj_radio:client:count', source, count)
        end
    end
end

local function removeMember(source)
    local member = members[source]
    if not member then return nil end

    members[source] = nil
    local players = frequencies[member.tenths]
    if players then
        players[source] = nil
        if not next(players) then frequencies[member.tenths] = nil end
    end
    syncFrequency(member.tenths)
    return member
end

-- Saca al jugador de la radio. message avisa de por qué, si la desconexión no la ha pedido él
local function disconnect(source, message)
    local member = removeMember(source)
    if not member then return end

    if Player(source).state.radioChannel == member.channel then
        exports['pma-voice']:setPlayerRadio(source, 0)
    end
    TriggerClientEvent('jj_radio:client:disconnected', source, message)
end

local function failure(message)
    return { ok = false, message = message }
end

local function joinFrequency(source, tenths)
    if not hasRadio(source) then return failure('No tienes una radio') end

    local now = GetGameTimer()
    if lastChange[source] and now - lastChange[source] < Config.ChangeDelay then
        return failure('Espera un momento')
    end

    local member = members[source]
    local current = Player(source).state.radioChannel
    -- pma-voice solo admite un canal: no se le quita a nadie la radio de la policía o de la banda
    if current and current ~= 0 and not (member and member.channel == current) then
        return failure('Desconecta primero la otra radio')
    end

    if member and member.tenths == tenths then
        return { ok = true, frequency = tenths / 10, count = countMembers(tenths) }
    end

    lastChange[source] = now
    removeMember(source)

    local channel = Config.BaseChannel + tenths
    members[source] = { tenths = tenths, channel = channel }
    frequencies[tenths] = frequencies[tenths] or {}
    frequencies[tenths][source] = true

    exports['pma-voice']:setPlayerRadio(source, channel)
    syncFrequency(tenths)

    return { ok = true, frequency = tenths / 10, count = countMembers(tenths) }
end

-- Frecuencias guardadas de cada personaje

local function getSaved(identifier)
    local rows = MySQL.query.await('SELECT `frequency`, `label` FROM `jj_radio_frequencies` WHERE `identifier` = ? ORDER BY `label`, `frequency`', { identifier }) or {}
    local saved = {}
    for index, row in ipairs(rows) do
        saved[index] = { frequency = row.frequency / 10, label = row.label }
    end
    return saved
end

local function cleanLabel(label)
    if type(label) ~= 'string' then return nil end

    label = label:gsub('%c', ' '):match('^%s*(.-)%s*$')
    local length = utf8.len(label)
    if not length or length == 0 or length > Config.MaxLabelLength then return nil end
    return label
end

-- Guarda o renombra una frecuencia. Devuelve false y el motivo si no cabe
local function storeFrequency(identifier, tenths, label)
    local saved = getSaved(identifier)
    local exists = false
    for _, entry in ipairs(saved) do
        if math.floor(entry.frequency * 10 + 0.5) == tenths then exists = true end
    end
    if not exists and #saved >= Config.MaxSaved then
        return false, ('Solo puedes guardar %d frecuencias'):format(Config.MaxSaved)
    end

    local result = MySQL.update.await('INSERT INTO `jj_radio_frequencies` (`identifier`, `frequency`, `label`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `label` = VALUES(`label`)', { identifier, tenths, label })
    if not result then return false, 'No se ha podido guardar' end
    return true
end

-- Invitaciones

local function getInvites(source)
    local list = {}
    local now = GetGameTimer()
    for tenths, invite in pairs(invites[source] or {}) do
        if invite.expires > now then
            list[#list + 1] = { frequency = tenths / 10, from = invite.from }
        else
            invites[source][tenths] = nil
        end
    end
    table.sort(list, function(a, b) return a.frequency < b.frequency end)
    return list
end

local function syncInvites(source)
    if viewers[source] then
        TriggerClientEvent('jj_radio:client:invites', source, getInvites(source))
    end
end

local function removeInvite(source, tenths)
    if invites[source] then invites[source][tenths] = nil end
    syncInvites(source)
end

-- Callbacks

lib.callback.register('jj_radio:open', function(source)
    local player = JJ.GetPlayer(source)
    if not player or not hasRadio(source) then return nil end

    viewers[source] = true
    local member = members[source]
    return {
        frequency = member and member.tenths / 10 or nil,
        count = member and countMembers(member.tenths) or 0,
        min = Config.MinFrequency,
        max = Config.MaxFrequency,
        maxSaved = Config.MaxSaved,
        maxLabel = Config.MaxLabelLength,
        saved = getSaved(player.identifier),
        invites = getInvites(source),
    }
end)

RegisterNetEvent('jj_radio:server:close', function()
    viewers[source] = nil
end)

lib.callback.register('jj_radio:join', function(source, frequency)
    if not JJ.GetPlayer(source) then return failure('No se ha podido conectar') end

    local tenths = toTenths(frequency)
    if not tenths then return failure('Esa frecuencia no existe') end

    return joinFrequency(source, tenths)
end)

RegisterNetEvent('jj_radio:server:leave', function()
    disconnect(source)
end)

local function canSave(source)
    local now = GetGameTimer()
    if lastSave[source] and now - lastSave[source] < Config.SaveDelay then return false end
    lastSave[source] = now
    return true
end

lib.callback.register('jj_radio:save', function(source, frequency, label)
    local player = JJ.GetPlayer(source)
    if not player then return failure('No se ha podido guardar') end
    if not canSave(source) then return failure('Espera un momento') end

    local tenths = toTenths(frequency)
    if not tenths then return failure('Esa frecuencia no existe') end

    label = cleanLabel(label)
    if not label then return failure(('Ponle un nombre de hasta %d letras'):format(Config.MaxLabelLength)) end

    local stored, reason = storeFrequency(player.identifier, tenths, label)
    if not stored then return failure(reason) end

    return { ok = true, saved = getSaved(player.identifier) }
end)

lib.callback.register('jj_radio:delete', function(source, frequency)
    local player = JJ.GetPlayer(source)
    if not player then return failure('No se ha podido borrar') end
    if not canSave(source) then return failure('Espera un momento') end

    local tenths = toTenths(frequency)
    if not tenths then return failure('Esa frecuencia no existe') end

    MySQL.update.await('DELETE FROM `jj_radio_frequencies` WHERE `identifier` = ? AND `frequency` = ?', { player.identifier, tenths })
    return { ok = true, saved = getSaved(player.identifier) }
end)

lib.callback.register('jj_radio:invite', function(source, target)
    local player = JJ.GetPlayer(source)
    if not player then return failure('No se ha podido invitar') end

    local member = members[source]
    if not member then return failure('Conéctate antes a una frecuencia') end

    local now = GetGameTimer()
    if lastInvite[source] and now - lastInvite[source] < Config.InviteDelay then
        return failure('Espera un momento')
    end

    target = type(target) == 'number' and math.tointeger(target)
    if not target or target == source or not JJ.GetPlayer(target) then
        return failure('No hay nadie con ese id')
    end
    lastInvite[source] = now

    if not hasRadio(target) then return failure('Esa persona no tiene una radio') end

    local targetMember = members[target]
    if targetMember and targetMember.tenths == member.tenths then
        return failure('Esa persona ya está en tu frecuencia')
    end

    -- Quita las caducadas antes de contar
    local pending = #getInvites(target)
    local targetInvites = invites[target] or {}
    invites[target] = targetInvites

    -- Repetir la invitación solo alarga su duración: no se puede molestar con avisos
    local repeated = targetInvites[member.tenths] ~= nil
    if not repeated and pending >= Config.MaxInvites then
        return failure('Esa persona tiene demasiadas invitaciones')
    end

    targetInvites[member.tenths] = { from = player.getName(), expires = now + Config.InviteTime }

    if not repeated then
        JJ.Notify(target, ('%s te invita a la frecuencia %.1f. Abre tu radio para responder'):format(player.getName(), member.tenths / 10), 'inform', 8000)
    end
    syncInvites(target)

    return { ok = true }
end)

lib.callback.register('jj_radio:answerInvite', function(source, frequency, accept)
    local player = JJ.GetPlayer(source)
    if not player then return failure('No se ha podido responder') end

    local tenths = toTenths(frequency)
    local pending = false
    for _, invite in ipairs(getInvites(source)) do
        if tenths and math.floor(invite.frequency * 10 + 0.5) == tenths then pending = true end
    end
    if not pending then return failure('Esa invitación ha caducado') end

    if not accept then
        removeInvite(source, tenths)
        return { ok = true }
    end

    local result = joinFrequency(source, tenths)
    if not result.ok then return result end

    -- Se guarda sola para no perderla, sin pisar el nombre si ya estaba guardada
    local from = invites[source][tenths].from
    local exists = false
    for _, entry in ipairs(getSaved(player.identifier)) do
        if math.floor(entry.frequency * 10 + 0.5) == tenths then exists = true end
    end
    if not exists then
        local label = cleanLabel(from) or ('Frecuencia %.1f'):format(tenths / 10)
        local stored, reason = storeFrequency(player.identifier, tenths, label)
        if not stored then
            JJ.Notify(source, ('No se ha guardado la frecuencia: %s'):format(reason), 'error')
        end
    end

    removeInvite(source, tenths)
    result.saved = getSaved(player.identifier)
    return result
end)

-- Comprobaciones periódicas

local function checkMember(source, member)
    if not JJ.GetPlayer(source) then
        disconnect(source)
    elseif not hasRadio(source) then
        disconnect(source, 'Te has quedado sin radio')
    elseif Player(source).state.radioChannel ~= member.channel then
        -- Se ha cambiado a otra radio, como la de la policía
        disconnect(source)
    end
end

CreateThread(function()
    while true do
        Wait(Config.CheckInterval)

        for source, member in pairs(members) do
            local ok, err = pcall(checkMember, source, member)
            if not ok then print(('^1[jj_radio] Error al comprobar la radio: %s^7'):format(tostring(err))) end
        end
    end
end)

AddEventHandler('jj:server:playerDropped', function(source)
    removeMember(source)
    viewers[source] = nil
    invites[source] = nil
    lastChange[source] = nil
    lastInvite[source] = nil
    lastSave[source] = nil
end)

-- Al parar el recurso nadie se queda en un canal que ya no se comprueba
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for source in pairs(members) do disconnect(source) end
end)
