-- Mejores tiempos por circuito, ranking de pilotos y ranking de crews (via crews).
Leaderboard = { best = {}, boards = {}, pilots = nil, crews = nil }

local function now() return GetGameTimer() / 1000.0 end

local function recordView(r)
    return {
        citizenid = r.citizenid, name = r.name, crewTag = r.crew_tag ~= '' and r.crew_tag or nil, crewColor = r.crew_color ~= '' and r.crew_color or nil,
        time = r.best_lap, vehicle = r.vehicle_model,
    }
end

--- Carga el mejor tiempo de cada circuito (version actual) al arrancar
function Leaderboard.LoadBest()
    Leaderboard.best = {}
    for _, r in ipairs(DB.GetBestRecords()) do
        -- La consulta viene ordenada por mejor tiempo: la primera fila de cada circuito es el record
        if not Leaderboard.best[r.track_id] then Leaderboard.best[r.track_id] = recordView(r) end
    end
end

function Leaderboard.Best(trackId)
    return Leaderboard.best[trackId]
end

--- Releer el record de un circuito desde la base de datos
function Leaderboard.RefreshBest(track)
    local r = DB.GetTrackBest(track.id, track.version)
    Leaderboard.best[track.id] = r and recordView(r) or nil
    Leaderboard.boards[track.id] = nil
end

--- Clasificacion de un circuito (mejores vueltas de la version actual), con cache corta
function Leaderboard.Track(track)
    local cached = Leaderboard.boards[track.id]
    if cached and cached.version == track.version and now() - cached.at < Config.LeaderboardCacheSeconds then return cached.rows end
    local rows = {}
    for i, r in ipairs(DB.GetLeaderboard(track.id, track.version, Config.LeaderboardSize)) do
        local v = recordView(r)
        v.position, v.vehicleClass, v.at = i, r.vehicle_class, r.at
        rows[i] = v
    end
    Leaderboard.boards[track.id] = { at = now(), version = track.version, rows = rows }
    return rows
end

--- Ranking global de pilotos (puntos de posicion), con cache corta
function Leaderboard.Pilots()
    local c = Leaderboard.pilots
    if c and now() - c.at < Config.LeaderboardCacheSeconds then return c.rows end
    local rows = {}
    for i, r in ipairs(DB.GetPilotRanking(Config.LeaderboardSize)) do
        rows[i] = {
            position = i, citizenid = r.citizenid, name = r.name, crewTag = r.crew_tag ~= '' and r.crew_tag or nil,
            crewColor = r.crew_color ~= '' and r.crew_color or nil,
            races = tonumber(r.races) or 0, wins = tonumber(r.wins) or 0, podiums = tonumber(r.podiums) or 0, points = tonumber(r.points) or 0,
        }
    end
    Leaderboard.pilots = { at = now(), rows = rows }
    return rows
end

--- Ranking de crews: se consulta siempre al recurso crews (fuente unica de puntos)
function Leaderboard.Crews()
    if not CrewLink.Enabled() then return {} end
    local c = Leaderboard.crews
    if c and now() - c.at < Config.LeaderboardCacheSeconds then return c.rows end
    local list = CrewLink.GetAllCrews()
    table.sort(list, function(a, b)
        if (a.points or 0) ~= (b.points or 0) then return (a.points or 0) > (b.points or 0) end
        return (a.wins or 0) > (b.wins or 0)
    end)
    local rows = {}
    for i = 1, math.min(#list, Config.LeaderboardSize) do
        local k = list[i]
        rows[i] = { position = i, id = k.id, name = k.name, tag = k.tag, color = k.color, points = k.points or 0, wins = k.wins or 0, level = k.level or 1, members = k.members or 0 }
    end
    Leaderboard.crews = { at = now(), rows = rows }
    return rows
end

function Leaderboard.InvalidatePilots()
    Leaderboard.pilots = nil
    Leaderboard.crews = nil
end

--- Registra la vuelta de un piloto como record personal si mejora el anterior.
---@param entry table { citizenid, name, crewId, crewTag, crewColor, bestLap, vehicleModel, vehicleClass, resultId }
---@return boolean improved, boolean trackRecord
function Leaderboard.Submit(track, entry)
    local cur = DB.GetPlayerRecord(track.id, track.version, entry.citizenid)
    if cur and cur.best_lap <= entry.bestLap then return false, false end
    DB.UpsertRecord(track.id, track.version, entry)
    Leaderboard.boards[track.id] = nil

    local best = Leaderboard.best[track.id]
    local isRecord = best == nil or entry.bestLap < best.time
    if isRecord then
        Leaderboard.best[track.id] = recordView({
            citizenid = entry.citizenid, name = entry.name, crew_tag = entry.crewTag or '', crew_color = entry.crewColor or '',
            best_lap = entry.bestLap, vehicle_model = entry.vehicleModel,
        })
    end
    return true, isRecord
end

--- Recalcula el record personal de un piloto tras anular o aprobar un resultado
function Leaderboard.Recompute(trackId, version, cid)
    local track = Tracks.byId[trackId]
    local r = DB.GetBestResult(trackId, version, cid)
    if r then
        DB.UpsertRecord(trackId, version, {
            citizenid = cid, name = r.name, crewId = r.crew_id, crewTag = r.crew_tag, crewColor = r.crew_color,
            bestLap = r.best_lap, vehicleModel = r.vehicle_model, vehicleClass = r.vehicle_class, resultId = r.id,
        })
    else
        DB.DeleteRecord(trackId, version, cid)
    end
    if track and track.version == version then Leaderboard.RefreshBest(track) end
    Leaderboard.InvalidatePilots()
end
