-- Captura de banderas entre las bandas de jj_gangs. Todas las reglas se comprueban aquí
local L = Config.Locales
local PLANT_TOLERANCE = 3.0
local CAPTURE_TOLERANCE = 4.0

local active = GetResourceKvpInt('active') == 1
local flags = {}          -- id -> { id, gang, coords }
local captures = {}       -- id de bandera -> { attacker, secondsLeft, contested }
local lastPlant = {}      -- banda -> momento
local lastAttack = {}     -- banda -> momento
local lastDefend = {}     -- banda -> momento
local planting = {}       -- source -> { gang, coords, at }
local gangCache = {}      -- banda -> { label, blip, hex }

-- Ajustes que se pueden cambiar desde el panel. Se guardan y pisan a los de config.lua
local SETTINGS = {
    RadiusFlag = { min = 10, max = 200 },
    MaxFlagsPerGang = { min = 1, max = 30 },
    SecondsBetweenPlants = { min = 0, max = 3600 },
    SecondsToPlant = { min = 1, max = 120 },
    SecondsToCapture = { min = 10, max = 3600 },
    SecondsBetweenDefends = { min = 0, max = 7200 },
    SecondsBetweenAttacks = { min = 0, max = 7200 },
    PauseWhenDefended = { bool = true },
    ClearOnStart = { bool = true },
}

local function loadSettings()
    local ok, saved = pcall(json.decode, GetResourceKvpString('settings') or '{}')
    if not ok or type(saved) ~= 'table' then return end
    for key, rule in pairs(SETTINGS) do
        local value = saved[key]
        if rule.bool and type(value) == 'boolean' then
            Config[key] = value
        elseif not rule.bool and type(value) == 'number' then
            Config[key] = math.max(rule.min, math.min(rule.max, value))
        end
    end
end

local function currentSettings()
    local list = {}
    for key in pairs(SETTINGS) do list[key] = Config[key] end
    return list
end

-- Bandas que no participan: ni ven las banderas ni pueden plantar o capturar
local excluded = {}
do
    local ok, saved = pcall(json.decode, GetResourceKvpString('excluded') or '[]')
    for _, id in ipairs(ok and type(saved) == 'table' and saved or {}) do excluded[id] = true end
end
loadSettings()

local function notify(src, message, kind)
    JJ.Notify(src, message, kind or 'inform', 7000)
end

local function getGang(src)
    if GetResourceState('jj_gangs') ~= 'started' then return nil end
    local gang = exports.jj_gangs:getGang(src)
    if gang and excluded[gang.id] then return nil end
    return gang
end

local function refreshGangs()
    gangCache = {}
    if GetResourceState('jj_gangs') ~= 'started' then return end
    for _, gang in ipairs(exports.jj_gangs:getGangs() or {}) do
        gangCache[gang.id] = gang
    end
end

local function hexToRgb(hex)
    local r, g, b = tostring(hex or ''):match('^#(%x%x)(%x%x)(%x%x)$')
    if not r then return { 168, 85, 247 } end
    return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

-- Aspecto de la bandera de una banda: el color de jj_gangs, o el de Config.GangStyles si tiene
local function styleOf(gangId)
    local gang = gangCache[gangId] or {}
    local custom = gang.label and Config.GangStyles[gang.label] or {}
    return {
        label = gang.label or ('Banda %s'):format(gangId),
        prop = custom.prop or Config.DefaultProp,
        color = custom.color or hexToRgb(gang.hex),
        blipColor = custom.blipColor or gang.blip or 27,
    }
end

local function clientFlag(flag)
    local style = styleOf(flag.gang)
    local capture = captures[flag.id]
    return {
        id = flag.id,
        gang = flag.gang,
        label = style.label,
        coords = flag.coords,
        prop = style.prop,
        color = style.color,
        blipColor = style.blipColor,
        beingCaptured = capture ~= nil,
        secondsLeft = capture and capture.secondsLeft or nil,
        contested = capture and capture.contested or false,
    }
end

-- Jugadores conectados de cada banda: source -> id de banda
local function gangMembers()
    local members = {}
    for _, src in ipairs(JJ.GetPlayers()) do
        local gang = getGang(src)
        if gang then members[src] = gang.id end
    end
    return members
end

-- Solo los miembros de una banda ven las banderas
local function syncTo(src)
    local gang = getGang(src)
    local list = {}
    if gang and active then
        for _, flag in pairs(flags) do list[#list + 1] = clientFlag(flag) end
    end
    TriggerClientEvent('jj_flags:client:setFlags', src, list, gang and gang.id or nil, { radius = Config.RadiusFlag })
end

local function syncAll()
    refreshGangs()
    for _, src in ipairs(JJ.GetPlayers()) do syncTo(src) end
end

local function updateFlag(flag)
    local data = clientFlag(flag)
    for src in pairs(gangMembers()) do
        TriggerClientEvent('jj_flags:client:updateFlag', src, data)
    end
end

local function notifyGang(gangId, message, kind, coords)
    for src, gang in pairs(gangMembers()) do
        if gang == gangId then
            notify(src, message, kind)
            if coords then TriggerClientEvent('jj_flags:client:setInMap', src, coords) end
        end
    end
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    return ped and ped ~= 0 and GetEntityCoords(ped) or nil
end

local function isAlive(src)
    local state = Player(src).state
    return not state.isDead and not state.isLastStand
end

-- Base de datos: las banderas sobreviven a un reinicio

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_flags` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `gang_id` INT UNSIGNED NOT NULL,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_flags') or {}) do
        flags[row.id] = { id = row.id, gang = row.gang_id, coords = vector3(row.x, row.y, row.z) }
    end
    syncAll()
end)

local function countFlags(gangId)
    local count = 0
    for _, flag in pairs(flags) do
        if flag.gang == gangId then count = count + 1 end
    end
    return count
end

-- Plantar

RegisterNetEvent('jj_flags:server:requestPlant', function()
    local src = source
    if not active then return notify(src, L['not_actived'], 'error') end

    local gang = getGang(src)
    if not gang then return notify(src, L['not_gang'], 'error') end
    local now = os.time()
    if not isAlive(src) or (planting[src] and now - planting[src].at < Config.SecondsToPlant + 10) then return end

    if lastPlant[gang.id] and now - lastPlant[gang.id] < Config.SecondsBetweenPlants then
        return notify(src, L['not_time_passed'], 'error')
    end
    if countFlags(gang.id) >= Config.MaxFlagsPerGang then
        return notify(src, L['maximum_flags'], 'error')
    end

    local coords = playerCoords(src)
    if not coords then return end
    for _, flag in pairs(flags) do
        if #(coords - flag.coords) < Config.RadiusFlag * 2 then
            return notify(src, L['so_close'], 'error')
        end
    end

    planting[src] = { gang = gang.id, coords = coords, at = now }
    TriggerClientEvent('jj_flags:client:plant', src, Config.SecondsToPlant)
end)

RegisterNetEvent('jj_flags:server:plant', function()
    local src = source
    local pending = planting[src]
    planting[src] = nil
    if not pending or not active then return end

    -- Tiene que haber pasado el tiempo de plantar sin moverse y seguir en la misma banda
    local now = os.time()
    local coords = playerCoords(src)
    local gang = getGang(src)
    if now - pending.at < Config.SecondsToPlant - 1 or not gang or gang.id ~= pending.gang then return end
    if not coords or #(coords - pending.coords) > PLANT_TOLERANCE then
        return notify(src, L['moved'], 'error')
    end

    -- Se vuelve a comprobar por si otra banda ha plantado cerca mientras tanto
    if countFlags(gang.id) >= Config.MaxFlagsPerGang then return notify(src, L['maximum_flags'], 'error') end
    for _, flag in pairs(flags) do
        if #(pending.coords - flag.coords) < Config.RadiusFlag * 2 then
            return notify(src, L['so_close'], 'error')
        end
    end

    local position = pending.coords
    local id = MySQL.insert.await('INSERT INTO jj_flags (gang_id, x, y, z) VALUES (?, ?, ?, ?)', { gang.id, position.x, position.y, position.z })
    if not id then return end

    lastPlant[gang.id] = now
    flags[id] = { id = id, gang = gang.id, coords = position }
    refreshGangs()
    updateFlag(flags[id])
    notify(src, L['flags_left']:format(Config.MaxFlagsPerGang - countFlags(gang.id)), 'success')
end)

RegisterNetEvent('jj_flags:server:cancelPlant', function()
    planting[source] = nil
end)

-- Capturar

RegisterNetEvent('jj_flags:server:tryToCapture', function(flagId)
    local src = source
    if not active then return notify(src, L['not_actived'], 'error') end

    local flag = type(flagId) == 'number' and flags[flagId]
    if not flag then return end

    local gang = getGang(src)
    if not gang then return notify(src, L['not_gang'], 'error') end
    if gang.id == flag.gang then return notify(src, L['your_flag'], 'error') end
    if captures[flag.id] then return notify(src, L['being_captured'], 'error') end
    if not isAlive(src) then return end

    local coords = playerCoords(src)
    if not coords or #(coords - flag.coords) > Config.ActionDistance + CAPTURE_TOLERANCE then
        return notify(src, L['too_far'], 'error')
    end

    local now = os.time()
    if lastDefend[flag.gang] and now - lastDefend[flag.gang] < Config.SecondsBetweenDefends then
        return notify(src, L['defend_recently'], 'error')
    end
    if lastAttack[gang.id] and now - lastAttack[gang.id] < Config.SecondsBetweenAttacks then
        return notify(src, L['attack_recently'], 'error')
    end

    lastAttack[gang.id] = now
    lastDefend[flag.gang] = now
    captures[flag.id] = { attacker = gang.id, secondsLeft = Config.SecondsToCapture, contested = false }

    notifyGang(gang.id, L['in_attack'], 'warning', flag.coords)
    notifyGang(flag.gang, L['in_defend'], 'error', flag.coords)
    updateFlag(flag)
end)

local function finishCapture(flag, capture, success)
    captures[flag.id] = nil

    if success then
        local previous = flag.gang
        flag.gang = capture.attacker
        MySQL.update.await('UPDATE jj_flags SET gang_id = ? WHERE id = ?', { flag.gang, flag.id })
        notifyGang(capture.attacker, L['captured'], 'success')
        notifyGang(previous, L['lost'], 'error')
    else
        notifyGang(capture.attacker, L['capture_failed'], 'error')
        notifyGang(flag.gang, L['defended'], 'success')
    end

    updateFlag(flag)
end

-- Cada segundo avanzan las capturas según quién hay dentro de la zona
local function tickCaptures()
    if not next(captures) then return end

    local members = gangMembers()
    for flagId, capture in pairs(captures) do
        local flag = flags[flagId]
        if not flag then
            captures[flagId] = nil
        else
            local attackers, defenders = 0, 0
            for src, gang in pairs(members) do
                if gang == capture.attacker or gang == flag.gang then
                    local coords = playerCoords(src)
                    if coords and isAlive(src) and #(coords - flag.coords) <= Config.RadiusFlag then
                        if gang == capture.attacker then attackers = attackers + 1 else defenders = defenders + 1 end
                    end
                end
            end

            if attackers == 0 then
                finishCapture(flag, capture, false)
            else
                local contested = Config.PauseWhenDefended and defenders > 0
                if not contested then capture.secondsLeft = capture.secondsLeft - 1 end

                if capture.secondsLeft <= 0 then
                    finishCapture(flag, capture, true)
                elseif contested ~= capture.contested or capture.secondsLeft % 5 == 0 then
                    capture.contested = contested
                    updateFlag(flag)
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(1000)
        local ok, err = pcall(tickCaptures)
        if not ok then print(('^1[jj_flags] Error en las capturas: %s^7'):format(tostring(err))) end
    end
end)

-- Jugadores

RegisterNetEvent('jj_flags:server:refresh', function()
    refreshGangs()
    syncTo(source)
end)

AddEventHandler('jj:server:playerLoaded', function(src)
    refreshGangs()
    syncTo(src)
end)

AddEventHandler('jj:server:playerDropped', function(src)
    planting[src] = nil
end)

-- Administración

local function adminCommand(name, handler)
    RegisterCommand(name, function(src, args)
        if src ~= 0 and not JJ.IsAdmin(src) then
            return notify(src, 'No tienes permiso para usar este comando', 'error')
        end
        handler(src, args)
    end, false)
end

local function reply(src, message)
    if src == 0 then print(('[jj_flags] %s'):format(message)) else notify(src, message, 'inform') end
end

local function ranking()
    refreshGangs()
    local counts = {}
    for _, flag in pairs(flags) do counts[flag.gang] = (counts[flag.gang] or 0) + 1 end

    local list = {}
    for gangId, count in pairs(counts) do
        list[#list + 1] = { label = styleOf(gangId).label, count = count }
    end
    table.sort(list, function(a, b) return a.count > b.count end)

    local lines = {}
    for index, entry in ipairs(list) do
        lines[#lines + 1] = ('%d. %s: %d'):format(index, entry.label, entry.count)
    end
    return #lines > 0 and table.concat(lines, ' · ') or 'Ninguna banda tiene banderas'
end

local function startEvent()
    if active then return false, 'El evento ya está activo' end

    if Config.ClearOnStart then
        flags, captures, lastPlant, lastAttack, lastDefend = {}, {}, {}, {}, {}
        MySQL.query.await('DELETE FROM jj_flags')
    end

    active = true
    SetResourceKvpInt('active', 1)
    syncAll()
    for src in pairs(gangMembers()) do notify(src, L['started'], 'success') end
    return true, L['started']
end

local function stopEvent()
    if not active then return false, L['not_actived'] end

    active = false
    SetResourceKvpInt('active', 0)
    captures, planting = {}, {}

    local message = ('%s. %s'):format(L['stopped'], ranking())
    for src in pairs(gangMembers()) do notify(src, message, 'inform') end
    syncAll()
    return true, message
end

adminCommand(Config.FlagStartCommand, function(src)
    local _, message = startEvent()
    reply(src, message)
end)

adminCommand(Config.FinishFlagsCommand, function(src)
    local _, message = stopEvent()
    reply(src, message)
end)

adminCommand(Config.CheckFlagsCommand, function(src)
    reply(src, ('%s · %s'):format(active and 'Evento activo' or 'Evento parado', ranking()))
end)

-- Panel de administración

local function toHex(color)
    return ('#%02x%02x%02x'):format(color[1], color[2], color[3])
end

local function panelState()
    refreshGangs()

    local counts, online = {}, {}
    for _, flag in pairs(flags) do counts[flag.gang] = (counts[flag.gang] or 0) + 1 end
    if GetResourceState('jj_gangs') == 'started' then
        for _, src in ipairs(JJ.GetPlayers()) do
            local gang = exports.jj_gangs:getGang(src)
            if gang then online[gang.id] = (online[gang.id] or 0) + 1 end
        end
    end

    local list = {}
    for _, flag in pairs(flags) do
        local style = styleOf(flag.gang)
        local capture = captures[flag.id]
        list[#list + 1] = {
            id = flag.id,
            gang = flag.gang,
            label = style.label,
            hex = toHex(style.color),
            coords = { x = flag.coords.x, y = flag.coords.y, z = flag.coords.z },
            capture = capture and {
                attacker = capture.attacker,
                attackerLabel = styleOf(capture.attacker).label,
                attackerHex = toHex(styleOf(capture.attacker).color),
                secondsLeft = capture.secondsLeft,
                contested = capture.contested,
            } or nil,
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)

    local gangs = {}
    for id in pairs(gangCache) do
        local style = styleOf(id)
        gangs[#gangs + 1] = {
            id = id,
            label = style.label,
            hex = toHex(style.color),
            flags = counts[id] or 0,
            online = online[id] or 0,
            excluded = excluded[id] == true,
        }
    end
    table.sort(gangs, function(a, b)
        if a.flags ~= b.flags then return a.flags > b.flags end
        return a.label < b.label
    end)

    return { active = active, settings = currentSettings(), flags = list, gangs = gangs }
end

local function saveExcluded()
    local list = {}
    for id in pairs(excluded) do list[#list + 1] = id end
    SetResourceKvp('excluded', json.encode(list))
end

local actions = {}

function actions.state() return true end
actions.start = startEvent
actions.stop = stopEvent

function actions.saveSettings(_, data)
    if type(data.settings) ~= 'table' then return false, 'Ajustes no válidos' end

    for key, rule in pairs(SETTINGS) do
        local value = data.settings[key]
        if rule.bool then
            if type(value) == 'boolean' then Config[key] = value end
        else
            value = tonumber(value)
            if value then Config[key] = math.floor(math.max(rule.min, math.min(rule.max, value))) end
        end
    end

    SetResourceKvp('settings', json.encode(currentSettings()))
    syncAll()
    return true, 'Ajustes guardados'
end

function actions.setExcluded(_, data)
    local id = tonumber(data.gang)
    if not id or not gangCache[id] then return false, 'Esa banda no existe' end

    excluded[id] = data.excluded == true or nil
    if excluded[id] then
        for flagId, capture in pairs(captures) do
            if capture.attacker == id then captures[flagId] = nil end
        end
    end

    saveExcluded()
    syncAll()
    return true, excluded[id] and 'La banda ya no participa' or 'La banda vuelve a participar'
end

function actions.placeFlag(src, data)
    local id = tonumber(data.gang)
    if not id or not gangCache[id] then return false, 'Esa banda no existe' end

    local coords = playerCoords(src)
    if not coords then return false, 'No se ha podido leer tu posición' end

    local flagId = MySQL.insert.await('INSERT INTO jj_flags (gang_id, x, y, z) VALUES (?, ?, ?, ?)', { id, coords.x, coords.y, coords.z })
    if not flagId then return false, 'No se ha podido guardar la bandera' end

    flags[flagId] = { id = flagId, gang = id, coords = vector3(coords.x, coords.y, coords.z) }
    syncAll()
    return true, ('Bandera puesta para %s'):format(styleOf(id).label)
end

function actions.setOwner(_, data)
    local flag = flags[tonumber(data.id) or -1]
    local id = tonumber(data.gang)
    if not flag then return false, 'Esa bandera ya no existe' end
    if not id or not gangCache[id] then return false, 'Esa banda no existe' end

    captures[flag.id] = nil
    flag.gang = id
    MySQL.update.await('UPDATE jj_flags SET gang_id = ? WHERE id = ?', { id, flag.id })
    syncAll()
    return true, ('La bandera ahora es de %s'):format(styleOf(id).label)
end

function actions.cancelCapture(_, data)
    local flag = flags[tonumber(data.id) or -1]
    if not flag or not captures[flag.id] then return false, 'Esa bandera no se está capturando' end

    local attacker = captures[flag.id].attacker
    captures[flag.id] = nil
    notifyGang(attacker, 'Un administrador ha cancelado la captura', 'error')
    updateFlag(flag)
    return true, 'Captura cancelada'
end

function actions.deleteFlag(_, data)
    local flag = flags[tonumber(data.id) or -1]
    if not flag then return false, 'Esa bandera ya no existe' end

    flags[flag.id], captures[flag.id] = nil, nil
    MySQL.update.await('DELETE FROM jj_flags WHERE id = ?', { flag.id })
    syncAll()
    return true, 'Bandera borrada'
end

function actions.deleteAll()
    flags, captures = {}, {}
    MySQL.query.await('DELETE FROM jj_flags')
    syncAll()
    return true, 'Se han borrado todas las banderas'
end

for name, handler in pairs(actions) do
    lib.callback.register('jj_flags:admin:' .. name, function(src, data)
        if not JJ.IsAdmin(src) then return { error = 'No tienes permiso' } end

        local ok, message = handler(src, type(data) == 'table' and data or {})
        if ok == false then return { error = message } end
        return { state = panelState(), message = message }
    end)
end

RegisterCommand(Config.PanelCommand, function(src)
    if src == 0 then return end
    if not JJ.IsAdmin(src) then return notify(src, 'No tienes permiso para usar este comando', 'error') end
    TriggerClientEvent('jj_flags:client:openPanel', src)
end, false)
