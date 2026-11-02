-- Callbacks de jj-framework (NUI -> cliente -> servidor).
-- Todo se valida aqui: el cliente solo solicita. Respuesta: { ok, data | error, code }.

local buckets = {}

local function rateLimited(src, group)
    local cfg = Config.RateLimit[group] or Config.RateLimit.default
    local now = GetGameTimer()
    local key = ('%d:%s'):format(src, group)
    local b = buckets[key]
    if not b or now >= b.resetAt then
        buckets[key] = { count = 1, resetAt = now + cfg.window }
        return false
    end
    b.count = b.count + 1
    return b.count > cfg.max
end

AddEventHandler('playerDropped', function()
    local prefix = ('%d:'):format(source)
    for key in pairs(buckets) do
        if key:sub(1, #prefix) == prefix then buckets[key] = nil end
    end
end)

--- Registra un callback con rate limit, comprobacion de admin y manejo de errores.
---@param opts table { limit = 'default'|'heavy'|'admin', admin = boolean }
local function register(name, opts, handler)
    JJ.RegisterCallback('races:srv:' .. name, function(src, cb, data)
        local function fail(code, ...)
            cb({ ok = false, code = code, error = L('err_' .. code, ...) })
        end

        if not Tracks.ready then return fail('generic') end
        if rateLimited(src, opts.limit or (opts.admin and 'admin') or 'default') then return fail('rate_limited') end
        if type(data) ~= 'table' then data = {} end

        if opts.admin and not Perms.IsAdmin(src) then
            print(('^1[races]^7 intento de accion admin sin permiso: %s (id %d) -> %s'):format(GetPlayerName(src) or '?', src, name))
            return fail('no_permission')
        end

        local player = JJ.GetPlayer(src)
        if not player then return fail('generic') end
        local cid = player.identifier
        local pname = Perms.PlayerName(player)
        local ctx = {
            src = src, player = player, cid = cid, name = pname,
            actor = { cid = cid, name = pname, admin = opts.admin == true },
        }

        local ok, a, b, c = pcall(handler, ctx, data)
        if not ok then
            print(('^1[races]^7 error en %s: %s'):format(name, tostring(a)))
            return fail('generic')
        end
        if a == true then return cb({ ok = true, data = b }) end
        return fail(b or 'generic', c)
    end)
end

-- Helpers ---------------------------------------------------------------------------------------

local function idParam(v) return Utils.Int(v, 1, 2147483647) end

local function reasonParam(v)
    local s = Utils.PlainStr(v, 120)
    if not s or #s < 3 then return nil end
    return s
end

local function searchParam(v)
    return Utils.PlainStr(v == nil and '' or v, 40) or ''
end

local function pageParam(v)
    local page = Utils.Int(v, 1, 100000) or 1
    return page, Config.PageSize, (page - 1) * Config.PageSize
end

local function decode(s)
    if type(s) ~= 'string' then return {} end
    local ok, v = pcall(json.decode, s)
    return ok and type(v) == 'table' and v or {}
end

local function allowedClassKeys()
    local out = {}
    for _, key in ipairs(Settings.allowedClasses) do
        if Config.VehicleClasses[key] then out[#out + 1] = key end
    end
    return out
end

local function buildConfig()
    local cr = Config.Creator
    local p2p = {}
    for k, v in pairs(Config.PointToPointCategories) do
        if v then p2p[#p2p + 1] = k end
    end
    return {
        locale = Config.Locale, currency = Config.Currency, categories = Config.Categories, difficulties = Config.Difficulties,
        pointToPoint = p2p, vehicleClasses = allowedClassKeys(), allVehicleClasses = (function()
            local all = {}
            for key in pairs(Config.VehicleClasses) do all[#all + 1] = key end
            table.sort(all)
            return all
        end)(),
        pageSize = Config.PageSize, leaderboardSize = Config.LeaderboardSize,
        maxLaps = Settings.maxLaps, entryFeeMax = Settings.entryFeeMax, extraPrizeMax = Settings.extraPrizeMax, baseMaxPrize = Settings.baseMaxPrize,
        maxPlayers = Settings.maxPlayers, countdownSeconds = Settings.countdownSeconds, commissionPct = Settings.commissionPct,
        prizeSplit = Settings.prizeSplit, crewsEnabled = CrewLink.Enabled(),
        crewVs = { maxTeamSize = Config.CrewVs.maxTeamSize, stakeMax = Settings.crewVsStakeMax, formula = Settings.crewVsFormula, minRank = Settings.crewVsMinRank },
        creator = {
            minRadius = cr.minRadius, maxRadius = cr.maxRadius, defaultRadius = cr.defaultRadius,
            minHeight = cr.minHeight, maxHeight = cr.maxHeight, defaultHeight = cr.defaultHeight,
            maxCheckpoints = cr.maxCheckpoints, maxGrid = cr.maxGrid, requireTest = cr.requireTest,
        },
        eventsMaxPrize = Config.Events.maxPrize,
    }
end

local function stripCid(rows)
    local out = {}
    for i, r in ipairs(rows) do
        local c = {}
        for k, v in pairs(r) do
            if k ~= 'citizenid' then c[k] = v end
        end
        out[i] = c
    end
    return out
end

-- Estado / jugador ------------------------------------------------------------------------------

register('getState', {}, function(ctx)
    local crew = CrewLink.Enabled() and CrewLink.GetPlayerCrew(ctx.src) or nil
    local lobby = Lobbies.byPlayer[ctx.src]
    return true, {
        config = buildConfig(),
        isAdmin = Perms.IsAdmin(ctx.src),
        me = { name = ctx.name, pid = ctx.src },
        crewsEnabled = CrewLink.Enabled(),
        crew = crew and { id = crew.id, name = crew.name, tag = crew.tag, color = crew.color, level = crew.level, points = crew.points, wins = crew.wins, canChallenge = CrewLink.CanChallenge(ctx.src) ~= nil } or nil,
        lobby = lobby and Lobbies.View(lobby, ctx.src) or nil,
        invites = Lobbies.InvitesFor(ctx.cid),
        challenges = Challenges.ForPlayer(ctx.src),
        hasResult = Results.Last(ctx.cid) ~= nil,
    }
end)

register('listTracks', {}, function(ctx, d)
    return true, Tracks.List({
        search = searchParam(d.search), category = d.category, difficulty = d.difficulty, vehicleClass = d.vehicleClass,
        sort = d.sort, page = d.page,
    }, false)
end)

register('getTrack', {}, function(ctx, d)
    local t = Tracks.byId[idParam(d.id) or 0]
    if not t or not t.enabled then return false, 'track_not_found' end
    return true, Tracks.Detail(t, false)
end)

register('getLeaderboard', {}, function(ctx, d)
    local t = Tracks.byId[idParam(d.trackId) or 0]
    if not t then return false, 'track_not_found' end
    return true, { track = { id = t.id, name = t.name, version = t.version }, rows = stripCid(Leaderboard.Track(t)) }
end)

register('getPilotRanking', {}, function()
    return true, { rows = stripCid(Leaderboard.Pilots()) }
end)

register('getCrewRanking', {}, function()
    return true, { enabled = CrewLink.Enabled(), rows = Leaderboard.Crews() }
end)

register('getStats', {}, function(ctx)
    local s = DB.GetStats(ctx.cid) or {}
    local bests = {}
    for i, b in ipairs(DB.GetPlayerBests(ctx.cid)) do
        bests[i] = { trackId = b.track_id, trackName = b.track_name, bestLap = b.best_lap, vehicle = b.vehicle_model }
    end
    return true, {
        stats = {
            races = tonumber(s.races) or 0, wins = tonumber(s.wins) or 0, podiums = tonumber(s.podiums) or 0,
            earnings = tonumber(s.earnings) or 0, points = tonumber(s.points) or 0,
        },
        bests = bests,
    }
end)

register('getHistory', {}, function(ctx, d)
    local page, size, offset = pageParam(d.page)
    local rows = {}
    for i, r in ipairs(DB.GetHistory(ctx.cid, size, offset)) do
        rows[i] = {
            id = r.id, raceKey = r.race_key, trackId = r.track_id, trackName = r.track_name, mode = r.mode, position = r.position, status = r.status,
            totalTime = r.total_time, bestLap = r.best_lap, prize = r.prize, points = r.points, crewPoints = r.crew_points,
            flagged = r.flagged == 1 or r.flagged == true, voided = r.voided == 1 or r.voided == true, createdAt = r.created_at,
        }
    end
    return true, { items = rows, total = tonumber(DB.CountHistory(ctx.cid)) or 0, page = page, pageSize = size }
end)

register('getLastResult', {}, function(ctx)
    return true, Results.Last(ctx.cid)
end)

register('getRaceResults', {}, function(ctx, d)
    local key = Utils.Str(d.raceKey, 40)
    if not key or key == '' then return false, 'invalid_data' end
    local list = DB.GetResultsByKey(key)
    if #list == 0 then return false, 'result_not_found' end
    local rows = {}
    for i, r in ipairs(list) do
        rows[i] = {
            position = r.position, name = r.name, crew = r.crew_tag ~= '' and { tag = r.crew_tag, color = r.crew_color } or nil,
            status = r.status, totalTime = r.total_time, bestLap = r.best_lap, laps = r.laps, prize = r.prize, points = r.points,
            crewPoints = r.crew_points, vehicle = r.vehicle_model,
        }
    end
    return true, { raceKey = key, trackId = list[1].track_id, trackName = list[1].track_name, mode = list[1].mode, rows = rows }
end)

-- Carreras -----------------------------------------------------------------------------------------------

register('listRaces', {}, function(ctx)
    return true, { races = Lobbies.ListOpen(ctx.src, ctx.cid), invites = Lobbies.InvitesFor(ctx.cid) }
end)

register('createRace', { limit = 'heavy' }, function(ctx, d)
    local ok, res = Lobbies.Create(ctx.src, {
        trackId = idParam(d.trackId), laps = d.laps, vehicleClass = d.vehicleClass, entryFee = d.entryFee,
        extraPrize = d.extraPrize, private = d.private, name = d.name,
    })
    return ok, res
end)

register('joinRace', { limit = 'heavy' }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    return Lobbies.Join(ctx.src, id)
end)

register('leaveRace', {}, function(ctx)
    local ok, err = Lobbies.Leave(ctx.src)
    return ok, ok and {} or err
end)

register('setReady', {}, function(ctx, d)
    local ok, err = Lobbies.SetReady(ctx.src, d.ready == true)
    return ok, ok and {} or err
end)

register('startRace', { limit = 'heavy' }, function(ctx)
    local lobby = Lobbies.byPlayer[ctx.src]
    if not lobby then return false, 'not_in_race' end
    local ok, err = Lobbies.RequestStart(lobby, ctx.src)
    return ok, ok and {} or err
end)

register('kickPlayer', {}, function(ctx, d)
    local lobby = Lobbies.byPlayer[ctx.src]
    local pid = idParam(d.pid)
    if not lobby or not pid then return false, 'not_in_race' end
    local ok, err = Lobbies.Kick(lobby, pid, false, ctx.src, true)
    return ok, ok and {} or err
end)

register('invitePlayer', {}, function(ctx, d)
    local pid = idParam(d.pid)
    if not pid then return false, 'invalid_data' end
    local ok, err = Lobbies.Invite(ctx.src, pid)
    return ok, ok and {} or err
end)

-- Crews ---------------------------------------------------------------------------------------------------------

register('listCrews', {}, function(ctx, d)
    if not CrewLink.Enabled() then return false, 'crews_disabled' end
    local mine = CrewLink.GetPlayerCrew(ctx.src)
    local search = searchParam(d.search):lower()
    local list = {}
    for _, c in ipairs(CrewLink.GetAllCrews()) do
        if not c.frozen and (not mine or c.id ~= mine.id) and (search == '' or c.name:lower():find(search, 1, true) or c.tag:lower():find(search, 1, true)) then
            list[#list + 1] = { id = c.id, name = c.name, tag = c.tag, color = c.color, level = c.level, points = c.points, members = c.members }
        end
    end
    table.sort(list, function(a, b) return (a.points or 0) > (b.points or 0) end)
    while #list > 50 do table.remove(list) end
    return true, { items = list }
end)

register('challengeCrew', { limit = 'heavy' }, function(ctx, d)
    local data = {
        crewId = idParam(d.crewId), trackId = idParam(d.trackId), laps = d.laps, vehicleClass = d.vehicleClass,
        teamSize = d.teamSize, stake = d.stake == nil and 0 or d.stake,
    }
    if not data.crewId or not data.trackId then return false, 'invalid_data' end
    return Challenges.Create(ctx.src, ctx.cid, ctx.name, data)
end)

register('respondChallenge', { limit = 'heavy' }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    return Challenges.Respond(ctx.src, ctx.cid, ctx.name, id, d.accept == true)
end)

register('cancelChallenge', {}, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local ok, err = Challenges.Cancel(ctx.src, id)
    return ok, ok and {} or err
end)

-- Administracion: circuitos ---------------------------------------------------------------------------------------------

register('adminListTracks', { admin = true }, function(ctx, d)
    return true, Tracks.List({
        search = searchParam(d.search), category = d.category, difficulty = d.difficulty, vehicleClass = d.vehicleClass,
        status = d.status, sort = d.sort, page = d.page,
    }, true)
end)

register('adminGetTrack', { admin = true }, function(ctx, d)
    local t = Tracks.byId[idParam(d.id) or 0]
    if not t then return false, 'track_not_found' end
    return true, Tracks.Detail(t, true)
end)

register('adminSaveTrack', { admin = true, limit = 'heavy' }, function(ctx, d)
    local ok, t, bumped = Tracks.Save(d, ctx.actor)
    if not ok then return false, t end
    return true, { track = Tracks.Detail(t, true), newVersion = bumped == true }
end)

register('adminDuplicateTrack', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local ok, t = Tracks.Duplicate(id, ctx.actor)
    if not ok then return false, t end
    return true, { track = Tracks.Detail(t, true) }
end)

register('adminToggleTrack', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    if not id or type(d.enabled) ~= 'boolean' then return false, 'invalid_data' end
    local ok, err = Tracks.SetEnabled(id, d.enabled, ctx.actor)
    return ok, ok and {} or err
end)

register('adminDeleteTrack', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local ok, err = Tracks.Delete(id, ctx.actor)
    return ok, ok and {} or err
end)

register('adminExportTrack', { admin = true, limit = 'heavy' }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local ok, res = Tracks.Export(id, ctx.actor)
    if not ok then return false, res end
    return true, { json = res }
end)

register('adminImportTrack', { admin = true, limit = 'heavy' }, function(ctx, d)
    local ok, t = Tracks.Import(d.json, ctx.actor)
    if not ok then return false, t end
    return true, { track = Tracks.Detail(t, true) }
end)

register('adminTestTrack', { admin = true, limit = 'heavy' }, function(ctx, d)
    local t = Tracks.byId[idParam(d.id) or 0]
    if not t then return false, 'track_not_found' end
    local ok, res = Lobbies.CreateTest(ctx.src, t)
    return ok, res
end)

register('adminLeaderboard', { admin = true }, function(ctx, d)
    local t = Tracks.byId[idParam(d.trackId) or 0]
    if not t then return false, 'track_not_found' end
    return true, { track = { id = t.id, name = t.name, version = t.version }, rows = Leaderboard.Track(t) }
end)

-- Administracion: carreras activas -------------------------------------------------------------------------------------------

register('adminListRaces', { admin = true }, function()
    return true, { races = Lobbies.AdminList() }
end)

register('adminCancelRace', { admin = true }, function(ctx, d)
    local lobby = Lobbies.list[idParam(d.id) or 0]
    local reason = reasonParam(d.reason)
    if not lobby then return false, 'race_not_found' end
    if not reason then return false, 'reason_required' end
    local ok = Lobbies.Cancel(lobby, 'admin', { cid = ctx.cid, name = ctx.name })
    return ok == true, ok and {} or 'race_not_found'
end)

register('adminKickPlayer', { admin = true }, function(ctx, d)
    local lobby = Lobbies.list[idParam(d.raceId) or 0]
    local pid = idParam(d.pid)
    local reason = reasonParam(d.reason)
    if not lobby or not pid then return false, 'race_not_found' end
    if not reason then return false, 'reason_required' end
    local name = lobby.players[pid] and lobby.players[pid].name or '?'
    local ok, err = Lobbies.Kick(lobby, pid, true, ctx.src, d.refund == true)
    if not ok then return false, err end
    Logs.Add(ctx.actor, 'race_kick', { lobby = lobby.id, player = name, refund = d.refund == true, reason = reason }, true)
    return true, {}
end)

-- Administracion: eventos --------------------------------------------------------------------------------------------------------

register('adminListEvents', { admin = true }, function()
    local rows = {}
    for i, e in ipairs(DB.GetEvents()) do
        rows[i] = {
            id = e.id, trackId = e.track_id, trackName = e.track_name, title = e.title, laps = e.laps, vehicleClass = e.vehicle_class,
            prize = e.prize, scheduledAt = e.scheduled_at, status = e.status,
        }
    end
    return true, { items = rows }
end)

register('adminSaveEvent', { admin = true }, function(ctx, d)
    local track = Tracks.byId[idParam(d.trackId) or 0]
    if not track or not track.enabled then return false, 'track_not_found' end
    local title = Utils.PlainStr(d.title, 64)
    if not title or #title < 3 then return false, 'invalid_data' end
    local laps, class = Lobbies.CheckRaceParams(track, d.laps, d.vehicleClass)
    if not laps then return false, class end
    local prize = Utils.Int(d.prize == nil and 0 or d.prize, 0, Config.Events.maxPrize)
    local now = os.time()
    local at = Utils.Int(d.scheduledAt, now + 30, now + Config.Events.maxAheadDays * 86400)
    if not prize or not at then return false, 'event_invalid' end

    local id = DB.InsertEvent({ trackId = track.id, title = title, laps = laps, vehicleClass = class, prize = prize, scheduledAt = at }, ctx.cid)
    if not id then return false, 'db' end
    Events.Schedule()
    Logs.Add(ctx.actor, 'event_create', { id = id, title = title, track = track.name, prize = prize, at = os.date('%Y-%m-%d %H:%M', at) }, true)
    TriggerClientEvent('races:client:notify', -1, L('n_event_scheduled', title, track.name, os.date('%d/%m %H:%M', at)), 'primary', 12000)
    return true, { id = id }
end)

register('adminCancelEvent', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local e = DB.GetEvent(id)
    if not e or e.status ~= 'scheduled' then return false, 'event_invalid' end
    DB.SetEventStatus(id, 'cancelled')
    Events.Schedule()
    Logs.Add(ctx.actor, 'event_cancel', { id = id, title = e.title }, true)
    return true, {}
end)

-- Administracion: resultados -----------------------------------------------------------------------------------------------------------

register('adminListResults', { admin = true }, function(ctx, d)
    local page, size, offset = pageParam(d.page)
    local search = searchParam(d.search)
    local flagged = d.flaggedOnly == true
    local rows = {}
    for i, r in ipairs(DB.GetAdminResults(flagged, search, size, offset)) do
        rows[i] = {
            id = r.id, raceKey = r.race_key, trackId = r.track_id, trackName = r.track_name, mode = r.mode, citizenid = r.citizenid, name = r.name,
            crewTag = r.crew_tag ~= '' and r.crew_tag or nil, position = r.position, status = r.status, totalTime = r.total_time, bestLap = r.best_lap,
            prize = r.prize, flagged = r.flagged == 1 or r.flagged == true, flagReason = r.flag_reason, voided = r.voided == 1 or r.voided == true,
            voidReason = r.void_reason, createdAt = r.created_at,
        }
    end
    return true, { items = rows, total = tonumber(DB.CountAdminResults(flagged, search)) or 0, page = page, pageSize = size }
end)

register('adminVoidResult', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    local reason = reasonParam(d.reason)
    if not id then return false, 'invalid_data' end
    if not reason then return false, 'reason_required' end
    local ok, err = Results.Void(id, reason, ctx.actor)
    return ok, ok and {} or err
end)

register('adminApproveResult', { admin = true }, function(ctx, d)
    local id = idParam(d.id)
    if not id then return false, 'invalid_data' end
    local ok, err = Results.Approve(id, ctx.actor)
    return ok, ok and {} or err
end)

--- Anula el record vigente de un piloto en un circuito (anula el resultado que lo origino)
register('adminVoidRecord', { admin = true }, function(ctx, d)
    local t = Tracks.byId[idParam(d.trackId) or 0]
    local cid = Utils.Str(d.citizenid, 50)
    local reason = reasonParam(d.reason)
    if not t or not cid or cid == '' then return false, 'invalid_data' end
    if not reason then return false, 'reason_required' end
    local rec = DB.GetPlayerRecord(t.id, t.version, cid)
    if not rec then return false, 'result_not_found' end
    local ok, err
    if rec.result_id and rec.result_id > 0 then
        ok, err = Results.Void(rec.result_id, reason, ctx.actor)
    else
        DB.DeleteRecord(t.id, t.version, cid)
        Leaderboard.RefreshBest(t)
        ok = true
    end
    if ok then Logs.Add(ctx.actor, 'record_void', { track = t.name, citizenid = cid, time = Utils.FormatTime(rec.best_lap), reason = reason }, true) end
    return ok, ok and {} or err
end)

-- Administracion: ajustes y logs -----------------------------------------------------------------------------------------------------------

register('adminGetSettings', { admin = true }, function()
    return true, { settings = PublicSettings(), allClasses = buildConfig().allVehicleClasses }
end)

register('adminSaveSettings', { admin = true, limit = 'heavy' }, function(ctx, d)
    local ok, err, key = SaveSettings(d.settings, ctx.actor)
    if not ok then return false, err, key end
    TriggerClientEvent('races:client:refresh', -1)
    return true, { settings = PublicSettings() }
end)

register('adminLogs', { admin = true }, function(ctx, d)
    local page, size, offset = pageParam(d.page)
    local action = Utils.Str(d.action == nil and '' or d.action, 40) or ''
    local search = searchParam(d.search)
    local rows = {}
    for i, r in ipairs(DB.GetAdminLogs(action, search, size, offset)) do
        rows[i] = {
            id = r.id, actorCid = r.actor_cid, actorName = r.actor_name, action = r.action, details = decode(r.details),
            isAdmin = r.is_admin == 1 or r.is_admin == true, createdAt = r.created_at,
        }
    end
    return true, { items = rows, total = tonumber(DB.CountAdminLogs(action, search)) or 0, page = page, pageSize = size }
end)
