-- Ciclo de vida de los contratos. El servidor decide todo: el cliente solo pide y muestra
Contracts = {}

local Status = Boost.Status
local Reason = Boost.Reason

local active = {}       -- uid -> contrato en marcha
local byIdentifier = {} -- identificador -> uid del contrato en marcha
local queue = {}        -- identificador -> { src, nextOffer }
local cooldowns = {}    -- identificador -> momento desde el que puede recibir ofertas

local ALPHANUM = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

local function randomString(length)
    local parts = {}
    for index = 1, length do
        local at = math.random(1, #ALPHANUM)
        parts[index] = ALPHANUM:sub(at, at)
    end
    return table.concat(parts)
end

local function roll(range)
    return math.random(range[1], range[2])
end

local function keysOf(source)
    local list = {}
    for key in pairs(source) do list[#list + 1] = key end
    table.sort(list)
    return list
end

local function isClassEnabled(className)
    return Config.Classes[className] ~= nil and Settings.Get('class_disabled_' .. className) ~= true
end

local function pickModel(class)
    local available = {}
    for _, entry in ipairs(class.models) do
        if Settings.Get('model_disabled_' .. entry.model) ~= true then
            available[#available + 1] = entry
        end
    end
    return available[math.random(1, math.max(#available, 1))]
end

local function pickDropoff(spot)
    local ids = keysOf(Config.Dropoffs)
    local far = {}
    for _, id in ipairs(ids) do
        if #(Config.Dropoffs[id].coords - vector3(spot.x, spot.y, spot.z)) > 500.0 then far[#far + 1] = id end
    end
    local list = #far > 0 and far or ids
    return list[math.random(1, #list)]
end

-- Modelo y tipo de vehículo de un contrato guardado
local function modelEntry(class, model)
    for _, entry in ipairs(class.models) do
        if entry.model == model then return entry end
    end
    return { model = model, label = model }
end

-- Lo que el jugador puede ver de una oferta
local function offerView(row)
    local class = Config.Classes[row.class]
    local tier = class and Boost.GetTier(class) or {}
    local zone = Config.Zones[row.zone_id]
    local dropoff = Config.Dropoffs[row.dropoff_id]
    return {
        uid = row.uid,
        class = row.class,
        classLabel = class and class.label or row.class,
        tier = tier.label,
        model = row.label,
        zone = zone and zone.label or row.zone_id,
        dropoff = dropoff and dropoff.label or row.dropoff_id,
        money = row.reward_money,
        crypto = row.reward_crypto,
        xp = row.reward_xp,
        remaining = math.max(row.expires_at - os.time(), 0),
        locked = tier.locked or nil,
        hack = tier.hack or nil,
        tracker = tier.tracker or nil,
        guards = (class and (class.guards or tier.guards) or 0) > 0 or nil,
        assigned = row.assigned_by ~= nil or nil,
    }
end

-- Crea una oferta. opts.assignedBy es el administrador que la asigna
function Contracts.CreateOffer(identifier, className, opts)
    opts = opts or {}
    local class = Config.Classes[className]
    if not class then return nil, 'invalid' end
    if not opts.assignedBy and not isClassEnabled(className) then return nil, 'no_model' end

    local entry = pickModel(class)
    if not entry then return nil, 'no_model' end

    local zoneIds = keysOf(Config.Zones)
    local zoneId = zoneIds[math.random(1, #zoneIds)]
    local zone = Config.Zones[zoneId]
    local spotIndex = math.random(1, #zone.spots)
    local multiplier = tonumber(Settings.Get('reward_multiplier')) or 1.0

    local row = {
        uid = randomString(16),
        identifier = identifier,
        class = className,
        model = entry.model,
        label = entry.label,
        plate = 'BT' .. randomString(6),
        zone_id = zoneId,
        spot_index = spotIndex,
        dropoff_id = pickDropoff(zone.spots[spotIndex]),
        reward_money = math.floor(roll(class.rewards.money) * multiplier),
        reward_crypto = math.floor(roll(class.rewards.crypto) * multiplier),
        reward_xp = roll(class.rewards.xp),
        assigned_by = opts.assignedBy,
        expires_at = os.time() + Config.Contracts.offerLifetime,
    }

    if not DB.InsertContract(row) then return nil, 'internal' end

    local player = Bridge.GetPlayerByIdentifier(identifier)
    if player then
        Bridge.Notify(player.source, Boost.T('new_offer'), 'inform')
        TriggerClientEvent('jj_boosting:client:refresh', player.source)
    end

    return row
end

function Contracts.GetOffers(identifier)
    local list = {}
    for index, row in ipairs(DB.GetOffers(identifier, os.time())) do
        list[index] = offerView(row)
    end
    return list
end

-- Lo que el dueño del contrato puede ver del contrato en marcha
local function view(c)
    local zone = Config.Zones[c.zone_id]
    local dropoff = Config.Dropoffs[c.dropoff_id]
    local stolen = c.status == Status.STOLEN
    return {
        uid = c.uid,
        status = c.status,
        class = c.class,
        classLabel = c.classDef.label,
        tier = c.tier.label,
        model = c.label,
        plate = c.plate,
        money = c.reward_money,
        crypto = c.reward_crypto,
        xp = c.reward_xp,
        remaining = math.max(c.expires_at - os.time(), 0),
        zone = { label = zone.label, x = zone.center.x, y = zone.center.y, z = zone.center.z, radius = zone.radius },
        dropoff = stolen and { label = dropoff.label, x = dropoff.coords.x, y = dropoff.coords.y, z = dropoff.coords.z, radius = dropoff.radius } or nil,
        netId = c.netId,
        guards = c.guardNets,
        locked = c.tier.locked and not c.unlocked or nil,
        hackRequired = c.tier.hack and not c.unlocked or nil,
        tracker = c.tracker and c.tracker.active or nil,
        trackerDisableAt = c.tracker and c.tracker.active and math.max(c.tracker.disableAt - os.time(), 0) or nil,
    }
end

function Contracts.GetActiveView(identifier)
    local uid = byIdentifier[identifier]
    return uid and active[uid] and view(active[uid]) or nil
end

local function sync(c)
    if c.src then TriggerClientEvent('jj_boosting:client:contract', c.src, view(c)) end
end

local function notifyOwner(c, message, kind)
    if c.src then Bridge.Notify(c.src, message, kind) end
end

-- Avisos a la policía. Cada tipo de aviso sale una sola vez por contrato
local function policeAlert(c, kind, coords, chance)
    if c.alerts[kind] then return end
    if math.random() > (chance or 1.0) then return end
    c.alerts[kind] = true

    local zone = Config.Zones[c.zone_id]
    local sent = Bridge.PoliceAlert({
        title = kind == 'tracker' and 'Rastreador de vehículo activo' or 'Robo de vehículo',
        text = ('Robo de un %s, matrícula %s.'):format(c.label, c.plate),
        zone = zone and zone.label,
        plate = c.plate,
        model = c.label,
    }, coords)

    DB.Log('police', c.identifier, nil, 'alert_' .. kind, { uid = c.uid, sent = sent, class = c.class })
end

local function vehicleCoords(c)
    if c.entity and DoesEntityExist(c.entity) then return GetEntityCoords(c.entity) end
end

-- El conductor es el dueño del contrato. Si el servidor aún no ve quién va al volante, vale que esté dentro
local function isDriving(ped, vehicle)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    return driver == ped or (driver == 0 and GetVehiclePedIsIn(ped, false) == vehicle)
end

-- Rastreador

local function stopTracker(c, reason)
    if not c.tracker or not c.tracker.active then return end
    c.tracker.active = false
    for _, src in ipairs(Bridge.GetPolice()) do
        TriggerClientEvent('jj_boosting:client:trackerStop', src, c.uid)
    end
    DB.Log('tracker', c.identifier, nil, 'off', { uid = c.uid, reason = reason })
end

local function pulseTracker(c, now)
    if not c.tracker or not c.tracker.active or now < c.tracker.nextPulse then return end
    c.tracker.nextPulse = now + Config.Tracker.pulseSeconds

    local coords = vehicleCoords(c)
    if not coords then return end

    local accuracy = Config.Tracker.accuracy
    local data = {
        uid = c.uid,
        x = coords.x + (math.random() * 2 - 1) * accuracy,
        y = coords.y + (math.random() * 2 - 1) * accuracy,
        z = coords.z,
        model = c.label,
        plate = c.plate,
        ttl = Config.Tracker.pulseSeconds * 3,
    }
    for _, src in ipairs(Bridge.GetPolice()) do
        TriggerClientEvent('jj_boosting:client:trackerPulse', src, data)
    end
end

-- Fin del contrato

local function cleanupEntities(c)
    if c.entity and DoesEntityExist(c.entity) then DeleteEntity(c.entity) end
    c.entity = nil
    for _, ped in ipairs(c.guardEntities or {}) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    c.guardEntities = nil
end

local function release(c)
    stopTracker(c, 'finished')
    cleanupEntities(c)
    c.hack = nil
    active[c.uid] = nil
    byIdentifier[c.identifier] = nil
    cooldowns[c.identifier] = os.time() + Config.Contracts.cooldownAfterFinish
    if c.src then TriggerClientEvent('jj_boosting:client:contract', c.src, nil) end
end

local function fail(c, result, reason, messageKey)
    if c.finished then return end
    c.finished = true

    local now = os.time()
    if not DB.TransitionContract(c.uid, c.status, result, { finished_at = now }) then
        DB.Log('security', c.identifier, nil, 'finish_conflict', { uid = c.uid, status = c.status })
        release(c)
        return
    end

    local penalty = 0
    if reason ~= Reason.RESTART and Config.Contracts.failXpPenalty > 0 then
        penalty = -Config.Contracts.failXpPenalty
        DB.AddXp(c.identifier, penalty)
    end
    DB.AddResult(c.identifier, 0, 1, 0, 0)
    History.Add(c, result, reason, now - (c.accepted_at or now), 0, 0, penalty)

    notifyOwner(c, Boost.T(messageKey or 'failed'), 'error')
    release(c)
    if c.src then TriggerClientEvent('jj_boosting:client:refresh', c.src) end
end

Contracts.Fail = fail

local function complete(c, player)
    if c.finished or c.status ~= Status.STOLEN then return false end
    c.finished = true

    local now = os.time()
    if not DB.TransitionContract(c.uid, Status.STOLEN, Status.COMPLETED, { finished_at = now }) then
        DB.Log('security', c.identifier, nil, 'complete_conflict', { uid = c.uid })
        release(c)
        return false
    end

    -- El vehículo destrozado rebaja el dinero. El contrato guarda lo pactado: el cliente no interviene
    local body = Boost.Clamp((GetVehicleBodyHealth(c.entity) or 1000.0) / 1000.0, 0.0, 1.0)
    local money = math.floor(c.reward_money * (1.0 - Config.Contracts.damagePenalty * (1.0 - body)))
    local crypto = c.reward_crypto
    local xp = c.reward_xp

    if not Bridge.AddMoney(player, money, 'Contrato de boosting ' .. c.uid) then
        DB.Log('economy', c.identifier, nil, 'money_failed', { uid = c.uid, money = money })
        money = 0
    end
    if not Economy.Reward(c.identifier, crypto, 'Contrato ' .. c.classDef.label, 'contract:' .. c.uid) then
        crypto = 0
    end
    DB.AddXp(c.identifier, xp)
    DB.AddResult(c.identifier, 1, 0, money, crypto)
    History.Add(c, Status.COMPLETED, nil, now - (c.accepted_at or now), money, crypto, xp, Bridge.Name(player))
    DB.Log('contract', c.identifier, nil, 'completed', { uid = c.uid, money = money, crypto = crypto, xp = xp })

    notifyOwner(c, Boost.T('completed', money, crypto, Config.CryptoName, xp), 'success')
    release(c)
    if c.src then TriggerClientEvent('jj_boosting:client:refresh', c.src) end
    return true
end

-- Paso a paso del contrato

local function spawnGuards(c, spot)
    local count = c.classDef.guards or c.tier.guards or 0
    if count <= 0 then return end

    c.guardEntities, c.guardNets = {}, {}
    local weapon = joaat(Config.Guards.weapon)
    for index = 1, count do
        local model = Config.Guards.models[math.random(1, #Config.Guards.models)]
        local angle = (index / count) * math.pi * 2
        local ped = CreatePed(4, joaat(model), spot.x + math.cos(angle) * 4.0, spot.y + math.sin(angle) * 4.0, spot.z, spot.w, true, true)
        local timeout = GetGameTimer() + 2000
        while not DoesEntityExist(ped) and GetGameTimer() < timeout do Wait(50) end

        if DoesEntityExist(ped) then
            GiveWeaponToPed(ped, weapon, 200, false, true)
            SetPedArmour(ped, Config.Guards.armour)
            c.guardEntities[#c.guardEntities + 1] = ped
            c.guardNets[#c.guardNets + 1] = NetworkGetNetworkIdFromEntity(ped)
        end
    end
end

local function spawnVehicle(c)
    local zone = Config.Zones[c.zone_id]
    local spot = zone.spots[c.spot_index] or zone.spots[1]
    local entry = modelEntry(c.classDef, c.model)

    local vehicle = CreateVehicleServerSetter(joaat(c.model), entry.type or 'automobile', spot.x, spot.y, spot.z, spot.w)
    local timeout = GetGameTimer() + 5000
    while not DoesEntityExist(vehicle) and GetGameTimer() < timeout do Wait(50) end
    if not DoesEntityExist(vehicle) then return false end

    SetVehicleNumberPlateText(vehicle, c.plate)
    SetVehicleDoorsLocked(vehicle, c.tier.locked and 2 or 1)
    Entity(vehicle).state:set('jjBoosting', c.uid, true)

    c.entity = vehicle
    c.netId = NetworkGetNetworkIdFromEntity(vehicle)
    spawnGuards(c, spot)
    return true
end

local function markStolen(c, ped)
    if not DB.TransitionContract(c.uid, Status.LOCATED, Status.STOLEN, { stolen_at = os.time() }) then
        fail(c, Status.FAILED, Reason.GIVEUP)
        return
    end

    c.status = Status.STOLEN
    c.stolenAt = os.time()

    -- Lo primero es enviar el punto de entrega: nada de lo que viene después puede dejarlo sin él
    sync(c)

    Bridge.GiveKeys(c.src, c.plate)
    notifyOwner(c, Boost.T('stolen'), 'success')

    local coords = GetEntityCoords(ped)
    policeAlert(c, 'theft', coords, c.classDef.alertChance)

    if c.tier.tracker then
        local now = os.time()
        c.tracker = { active = true, nextPulse = now, disableAt = now + Config.Tracker.disableAfter }
        notifyOwner(c, Boost.T('tracker_on'), 'warning')
        DB.Log('tracker', c.identifier, nil, 'on', { uid = c.uid })
        policeAlert(c, 'tracker', coords, 1.0)
        sync(c)
    end
end

local function aggroGuards(c)
    if c.src and c.guardNets and #c.guardNets > 0 then
        TriggerClientEvent('jj_boosting:client:guardsAggro', c.src, c.guardNets)
    end
end

local function hackFailed(c, kind)
    c.hack = nil
    local attempts = c.attempts[kind] - 1
    c.attempts[kind] = attempts
    DB.Log('contract', c.identifier, nil, 'hack_failed', { uid = c.uid, kind = kind, attempts = attempts })

    local coords = vehicleCoords(c)
    if coords then policeAlert(c, 'hack', coords, Config.Police.hackFailChance) end
    aggroGuards(c)

    if attempts > 0 then
        notifyOwner(c, Boost.T('hack_failed', attempts), 'error')
        return false
    end

    notifyOwner(c, Boost.T('hack_lost'), 'error')
    if kind == 'tracker' then return false end

    if Config.HackExhausted == 'alarm' then
        notifyOwner(c, Boost.T('alarm'), 'warning')
        if coords then policeAlert(c, 'alarm', coords, 1.0) end
        c.unlocked = true
        SetVehicleDoorsLocked(c.entity, 1)
        if c.src then TriggerClientEvent('jj_boosting:client:alarm', c.src, c.netId) end
        sync(c)
        return false
    end

    fail(c, Status.FAILED, Reason.HACK)
    return true
end

-- Revisa cada contrato en marcha. No hace nada cuando no hay ninguno
local function tickContract(c, now)
    if now >= c.expires_at then
        fail(c, Status.EXPIRED, Reason.TIME, 'expired')
        return
    end

    if not c.src then
        if now >= (c.droppedUntil or 0) then fail(c, Status.ABANDONED, Reason.DISCONNECT) end
        return
    end

    if c.hack and GetGameTimer() > c.hack.deadline + 3000 then
        hackFailed(c, c.hack.kind)
        if c.finished then return end
    end

    local ped = GetPlayerPed(c.src)
    if ped == 0 then return end

    if c.status == Status.SEARCHING then
        local zone = Config.Zones[c.zone_id]
        if #(GetEntityCoords(ped) - zone.center) <= zone.radius + Config.Distances.zoneMargin and not c.spawning then
            c.spawning = true
            if spawnVehicle(c) and DB.TransitionContract(c.uid, Status.SEARCHING, Status.LOCATED) then
                c.status = Status.LOCATED
                notifyOwner(c, Boost.T('zone_entered', c.label, c.plate), 'inform')
                if c.tier.hack then notifyOwner(c, Boost.T('locked_hint'), 'inform') end
                sync(c)
            else
                fail(c, Status.FAILED, Reason.DESTROYED)
                return
            end
            c.spawning = false
        end
        return
    end

    if not c.entity or not DoesEntityExist(c.entity) then
        fail(c, Status.FAILED, Reason.DESTROYED)
        return
    end

    if c.status == Status.LOCATED then
        if isDriving(ped, c.entity) then
            if c.tier.hack and not c.unlocked then
                -- Ha entrado sin pasar por el hackeo: no cuenta
                Security.Flag(c.src, 'seat_without_hack', { uid = c.uid })
                TaskLeaveVehicle(ped, c.entity, 0)
                notifyOwner(c, Boost.T('locked_hint'), 'error')
            else
                markStolen(c, ped)
            end
        end
    elseif c.status == Status.STOLEN then
        pulseTracker(c, now)
    end
end

CreateThread(function()
    while true do
        Wait(next(active) and 2000 or 5000)
        local now = os.time()
        for _, c in pairs(active) do
            local ok, err = pcall(tickContract, c, now)
            if not ok then print(('^1[jj_boosting] Error en el contrato %s: %s^7'):format(c.uid, tostring(err))) end
        end
    end
end)

-- Cola de búsqueda

local function pickQueueClass(xp)
    local total, candidates = 0, {}
    for _, name in ipairs(Boost.ClassOrder) do
        local class = Config.Classes[name]
        if Boost.IsClassUnlocked(name, xp) and isClassEnabled(name) then
            total += class.offerWeight
            candidates[#candidates + 1] = { name = name, weight = class.offerWeight }
        end
    end
    if total <= 0 then return nil end

    local value = math.random(1, total)
    for _, candidate in ipairs(candidates) do
        value -= candidate.weight
        if value <= 0 then return candidate.name end
    end
end

local function nextWait(identifier)
    local wait = math.random(Config.Queue.minWait, Config.Queue.maxWait)
    if Progression.UseService(identifier, 'priority') then wait = math.ceil(wait / 2) end
    return wait
end

local function tickQueue()
    local now = os.time()
    for identifier, entry in pairs(queue) do
        if not Bridge.GetPlayerByIdentifier(identifier) then
            queue[identifier] = nil
        elseif now >= entry.nextOffer and not byIdentifier[identifier] and now >= (cooldowns[identifier] or 0) then
            entry.nextOffer = now + Config.Queue.minWait
            if DB.CountOffers(identifier, now) < Config.Contracts.maxOffers then
                local profile = DB.GetProfile(identifier)
                local className = profile and pickQueueClass(profile.xp)
                if className and Contracts.CreateOffer(identifier, className) then
                    entry.nextOffer = now + nextWait(identifier)
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(Config.Queue.tickSeconds * 1000)
        if next(queue) then
            local ok, err = pcall(tickQueue)
            if not ok then print(('^1[jj_boosting] Error en la cola: %s^7'):format(tostring(err))) end
        end
    end
end)

function Contracts.IsQueued(identifier)
    return queue[identifier] ~= nil
end

-- Conexiones

function Contracts.OnPlayerLoaded(src)
    local player = Bridge.GetPlayer(src)
    if not player then return end

    local uid = byIdentifier[Bridge.Identifier(player)]
    local c = uid and active[uid]
    if c then
        c.src = src
        c.droppedUntil = nil
        c.hack = nil
        c.playerName = Bridge.Name(player)
        sync(c)
    end
end

function Contracts.OnPlayerDropped(src)
    local player = Bridge.GetPlayer(src)
    if not player then return end

    local identifier = Bridge.Identifier(player)
    queue[identifier] = nil

    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    if c then
        c.src = nil
        c.hack = nil
        c.droppedUntil = os.time() + Config.Contracts.abandonGrace
    end
end

-- Al arrancar no queda ningún vehículo: los contratos que estaban en marcha se cierran sin penalización
function Contracts.Recover()
    local now = os.time()
    for _, row in ipairs(DB.GetInterrupted()) do
        if DB.TransitionContract(row.uid, row.status, Status.ABANDONED, { finished_at = now }) then
            History.Add(row, Status.ABANDONED, Reason.RESTART, now - (row.accepted_at or now), 0, 0, 0)
        end
    end
    DB.ExpireOffers(now)
end

function Contracts.CleanupAll()
    for _, c in pairs(active) do cleanupEntities(c) end
end

-- Para el panel de administración
function Contracts.GetActiveList()
    local list = {}
    for _, c in pairs(active) do
        list[#list + 1] = {
            uid = c.uid, identifier = c.identifier, class = c.class, model = c.label,
            status = c.status, online = c.src ~= nil, remaining = math.max(c.expires_at - os.time(), 0),
        }
    end
    return list
end

function Contracts.Cancel(uid)
    local c = active[uid]
    if not c then return false end
    fail(c, Status.ABANDONED, Reason.RESTART)
    return true
end

-- Llamadas del cliente

Security.Register('joinQueue', {}, function(src, player, identifier)
    Progression.GetProfile(player)
    queue[identifier] = { src = src, nextOffer = os.time() + nextWait(identifier) }
    DB.Touch(identifier)
    return { ok = true, message = Boost.T('queue_joined'), queued = true }
end)

Security.Register('leaveQueue', {}, function(_, _, identifier)
    queue[identifier] = nil
    return { ok = true, message = Boost.T('queue_left'), queued = false }
end)

Security.Register('acceptContract', { lock = true }, function(src, player, identifier, data)
    if type(data.uid) ~= 'string' or #data.uid ~= 16 then return { ok = false, message = Boost.T('not_found') } end
    if byIdentifier[identifier] then return { ok = false, message = Boost.T('already_active') } end

    local row = DB.GetContract(data.uid)
    if not row or row.identifier ~= identifier or row.status ~= Status.OFFERED or row.expires_at <= os.time() then
        return { ok = false, message = Boost.T('not_found') }
    end

    local class = Config.Classes[row.class]
    if not class or not Config.Zones[row.zone_id] or not Config.Dropoffs[row.dropoff_id] then
        return { ok = false, message = Boost.T('not_found') }
    end

    local profile = Progression.GetProfile(player)
    if not row.assigned_by and not Boost.IsClassUnlocked(row.class, profile.xp) then
        return { ok = false, message = Boost.T('class_locked') }
    end

    if #Bridge.GetPolice() < (class.minPolice or 0) then
        return { ok = false, message = Boost.T('no_police') }
    end

    local now = os.time()
    local expiresAt = now + class.duration
    if not DB.TransitionContract(row.uid, Status.OFFERED, Status.SEARCHING, { accepted_at = now, expires_at = expiresAt }) then
        return { ok = false, message = Boost.T('not_found') }
    end

    local tier = Boost.GetTier(class)
    local c = row
    c.src = src
    c.status = Status.SEARCHING
    c.classDef = class
    c.tier = tier
    c.accepted_at = now
    c.expires_at = expiresAt
    c.alerts = {}
    c.playerName = Bridge.Name(player)
    c.unlocked = not tier.hack

    local difficulty = Config.HackDifficulties[class.hackDifficulty] or Config.HackDifficulties.easy
    local trackerDifficulty = Config.HackDifficulties[Config.Tracker.hackDifficulty] or difficulty
    c.attempts = { lock = difficulty.attempts, tracker = trackerDifficulty.attempts }

    active[c.uid] = c
    byIdentifier[identifier] = c.uid
    queue[identifier] = nil

    DB.Touch(identifier)
    DB.Log('contract', identifier, nil, 'accepted', { uid = c.uid, class = c.class, model = c.model })
    sync(c)
    return { ok = true, message = Boost.T('accepted'), contract = view(c) }
end)

Security.Register('declineContract', { lock = true }, function(_, player, identifier, data)
    if type(data.uid) ~= 'string' then return { ok = false, message = Boost.T('not_found') } end

    local row = DB.GetContract(data.uid)
    if not row or row.identifier ~= identifier or not DB.TransitionContract(row.uid, Status.OFFERED, Status.DECLINED, { finished_at = os.time() }) then
        return { ok = false, message = Boost.T('not_found') }
    end

    History.Add(row, Status.DECLINED, nil, 0, 0, 0, 0, Bridge.Name(player))
    return { ok = true }
end)

Security.Register('abandonContract', { lock = true }, function(_, _, identifier)
    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    if not c then return { ok = false, message = Boost.T('not_found') } end

    fail(c, Status.ABANDONED, Reason.GIVEUP, 'given_up')
    return { ok = true }
end)

-- Compra de un contrato de una clase desbloqueada, sin esperar a la cola
Security.Register('buyContract', { delay = Config.RateLimit.store, lock = true }, function(_, player, identifier, data)
    local class = type(data.class) == 'string' and Config.Classes[data.class]
    if not class or not class.purchasePrice or not isClassEnabled(data.class) then
        return { ok = false, message = Boost.T('not_for_sale') }
    end

    local profile = Progression.GetProfile(player)
    if not Boost.IsClassUnlocked(data.class, profile.xp) then
        return { ok = false, message = Boost.T('class_locked') }
    end
    if DB.CountOffers(identifier, os.time()) >= Config.Contracts.maxOffers then
        return { ok = false, message = Boost.T('offers_full') }
    end

    local reference = ('buy:%s:%s'):format(data.class, randomString(16))
    if not Economy.Spend(identifier, class.purchasePrice, 'Compra de contrato ' .. class.label, reference) then
        return { ok = false, message = Boost.T('no_crypto') }
    end

    local row, reason = Contracts.CreateOffer(identifier, data.class)
    if not row then
        Economy.Reward(identifier, class.purchasePrice, 'Devolución de contrato', reference .. ':refund')
        return { ok = false, message = Boost.T(reason or 'internal') }
    end

    DB.Log('contract', identifier, nil, 'bought', { uid = row.uid, class = row.class, price = class.purchasePrice })
    return { ok = true, offer = offerView(row) }
end)

-- Hackeo: el servidor crea la partida, guarda la solución y corrige la respuesta

local function buildHack(difficulty, kind)
    local total = difficulty.grid * difficulty.grid

    local values = {}
    for value = 0, 255 do values[value + 1] = value end
    for index = #values, 2, -1 do
        local other = math.random(1, index)
        values[index], values[other] = values[other], values[index]
    end

    local grid = {}
    for index = 1, total do grid[index] = ('%02X'):format(values[index]) end

    local picks = {}
    for index = 1, total do picks[index] = index end
    for index = total, 2, -1 do
        local other = math.random(1, index)
        picks[index], picks[other] = picks[other], picks[index]
    end

    local sequence = {}
    for index = 1, math.min(difficulty.length, total) do sequence[index] = grid[picks[index]] end

    local now = GetGameTimer()
    return {
        kind = kind,
        token = randomString(16),
        grid = grid,
        sequence = sequence,
        size = difficulty.grid,
        time = difficulty.time,
        startedAt = now,
        deadline = now + difficulty.time * 1000,
    }
end

local function hackTarget(c, kind)
    if kind == 'lock' then
        return c.status == Status.LOCATED and c.tier.hack and not c.unlocked
    elseif kind == 'tracker' then
        return c.status == Status.STOLEN and c.tracker and c.tracker.active
    end
    return false
end

Security.Register('hackStart', { delay = Config.RateLimit.hack, lock = true }, function(src, _, identifier, data)
    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    local kind = data.kind

    if not c or c.finished or not hackTarget(c, kind) then
        Security.Flag(src, 'hack_invalid_state', { kind = tostring(kind), status = c and c.status })
        return { ok = false, message = Boost.T('not_found') }
    end

    if c.attempts[kind] <= 0 then return { ok = false, message = Boost.T('hack_lost') } end

    local coords = vehicleCoords(c)
    local ped = GetPlayerPed(src)
    if not coords then return { ok = false, message = Boost.T('not_found') } end

    if kind == 'lock' then
        if #(GetEntityCoords(ped) - coords) > Config.Distances.hack then
            return { ok = false, message = Boost.T('too_far') }
        end
    else
        if not isDriving(ped, c.entity) then return { ok = false, message = Boost.T('too_far') } end
        if os.time() < c.tracker.disableAt then return { ok = false, message = Boost.T('tracker_wait') } end
    end

    local difficulty = kind == 'lock'
        and (Config.HackDifficulties[c.classDef.hackDifficulty] or Config.HackDifficulties.easy)
        or (Config.HackDifficulties[Config.Tracker.hackDifficulty] or Config.HackDifficulties.easy)

    c.hack = buildHack(difficulty, kind)
    if kind == 'lock' then aggroGuards(c) end

    return {
        ok = true,
        hack = {
            token = c.hack.token,
            kind = kind,
            grid = c.hack.grid,
            sequence = c.hack.sequence,
            size = c.hack.size,
            time = c.hack.time,
            attempts = c.attempts[kind],
        },
    }
end)

Security.Register('hackSubmit', { delay = 200, lock = true }, function(src, _, identifier, data)
    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    local hack = c and c.hack

    if not hack or data.token ~= hack.token then
        Security.Flag(src, 'hack_invalid_token', { uid = uid })
        return { ok = false, message = Boost.T('not_found') }
    end

    local kind = hack.kind
    local now = GetGameTimer()
    local correct = type(data.answer) == 'table' and #data.answer == #hack.sequence and now <= hack.deadline + 1500
    if correct then
        for index, value in ipairs(hack.sequence) do
            if data.answer[index] ~= value then correct = false break end
        end
    end

    -- Sigue en su sitio al terminar, y una persona no puede resolverlo tan rápido
    if correct and now - hack.startedAt < #hack.sequence * 100 then
        Security.Flag(src, 'hack_too_fast', { uid = c.uid, ms = now - hack.startedAt })
        correct = false
    end
    if correct and kind == 'lock' then
        local coords = vehicleCoords(c)
        if not coords or #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.Distances.hack + 2.0 then correct = false end
    end

    if not correct or not hackTarget(c, kind) then
        local finished = hackFailed(c, kind)
        return { ok = true, success = false, attempts = c.attempts[kind], finished = finished }
    end

    c.hack = nil
    if kind == 'lock' then
        c.unlocked = true
        SetVehicleDoorsLocked(c.entity, 1)
        Bridge.GiveKeys(src, c.plate)
        notifyOwner(c, Boost.T('unlocked'), 'success')
        DB.Log('contract', identifier, nil, 'hack_ok', { uid = c.uid })
    else
        stopTracker(c, 'hack')
        notifyOwner(c, Boost.T('tracker_off'), 'success')
    end
    sync(c)
    return { ok = true, success = true }
end)

-- Rastreador con objeto. Si no hay objeto, el cliente pasa al minijuego
Security.Register('disableTracker', { delay = Config.RateLimit.hack, lock = true }, function(src, _, identifier)
    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    if not c or c.status ~= Status.STOLEN or not c.tracker or not c.tracker.active then
        return { ok = false, message = Boost.T('not_found') }
    end
    if not isDriving(GetPlayerPed(src), c.entity) then return { ok = false, message = Boost.T('too_far') } end
    if os.time() < c.tracker.disableAt then return { ok = false, message = Boost.T('tracker_wait') } end

    local mode = Config.Tracker.mode
    if mode == 'item' or mode == 'both' then
        if Bridge.RemoveItem(src, Config.Tracker.item, 1) then
            stopTracker(c, 'item')
            notifyOwner(c, Boost.T('tracker_off'), 'success')
            sync(c)
            return { ok = true, disabled = true }
        end
        if mode == 'item' then return { ok = false, message = Boost.T('tracker_item') } end
    end

    return { ok = true, needHack = true }
end)

-- Entrega. Todo se comprueba con lo que ve el servidor
Security.Register('deliver', { delay = Config.RateLimit.deliver, lock = true }, function(src, player, identifier)
    local uid = byIdentifier[identifier]
    local c = uid and active[uid]
    if not c or c.status ~= Status.STOLEN then
        Security.Flag(src, 'deliver_invalid_state', { uid = uid, status = c and c.status })
        return { ok = false, message = Boost.T('not_found') }
    end

    local coords = vehicleCoords(c)
    if not coords then return { ok = false, message = Boost.T('deliver_invalid') } end

    if GetEntityModel(c.entity) ~= joaat(c.model) or Entity(c.entity).state.jjBoosting ~= c.uid then
        Security.Flag(src, 'deliver_wrong_vehicle', { uid = c.uid })
        return { ok = false, message = Boost.T('deliver_invalid') }
    end

    local dropoff = Config.Dropoffs[c.dropoff_id]
    if #(coords - dropoff.coords) > dropoff.radius then return { ok = false, message = Boost.T('deliver_far') } end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.Distances.deliverPlayer then return { ok = false, message = Boost.T('too_far') } end

    local velocity = GetEntityVelocity(c.entity)
    if #velocity > Config.Contracts.maxDeliverySpeed then return { ok = false, message = Boost.T('deliver_moving') } end

    -- Tiempo imposible desde el robo: teletransporte
    local elapsed = os.time() - (c.stolenAt or os.time())
    local zone = Config.Zones[c.zone_id]
    local spot = zone.spots[c.spot_index] or zone.spots[1]
    local distance = #(vector3(spot.x, spot.y, spot.z) - dropoff.coords)
    if elapsed < Config.Contracts.minDeliverySeconds or distance / math.max(elapsed, 1) > Config.Contracts.maxAverageSpeed then
        Security.Flag(src, 'deliver_too_fast', { uid = c.uid, elapsed = elapsed, distance = distance })
        return { ok = false, message = Boost.T('deliver_invalid') }
    end

    if not complete(c, player) then return { ok = false, message = Boost.T('not_found') } end
    return { ok = true }
end)
