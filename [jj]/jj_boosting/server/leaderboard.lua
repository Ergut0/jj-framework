-- Clasificación. Se guarda en memoria para no consultarla en cada apertura
Leaderboard = {}

local cache, cachedAt = nil, 0

function Leaderboard.Invalidate()
    cachedAt = 0
end

function Leaderboard.Get()
    local now = os.time()
    if cache and now - cachedAt < Config.Leaderboard.cacheSeconds then return cache end

    local rows = DB.GetLeaderboard(Config.Leaderboard.sort, Config.Leaderboard.size)
    local list = {}
    for index, row in ipairs(rows) do
        list[index] = {
            position = index,
            name = row.display_name,
            avatar = row.avatar_url,
            completed = row.completed,
            xp = row.xp,
            cryptoEarned = row.crypto_earned,
            class = Boost.GetCurrentClass(row.xp),
            lastActivity = row.last_activity,
            identifier = row.identifier,
        }
    end

    cache, cachedAt = list, now
    return list
end

Security.Register('getLeaderboard', {}, function(_, _, identifier)
    local list = {}
    local own
    for index, row in ipairs(Leaderboard.Get()) do
        -- El identificador del personaje no se envía a los demás jugadores
        list[index] = {
            position = row.position, name = row.name, avatar = row.avatar, completed = row.completed,
            xp = row.xp, cryptoEarned = row.cryptoEarned, class = row.class, lastActivity = row.lastActivity,
            me = row.identifier == identifier or nil,
        }
        if row.identifier == identifier then own = row.position end
    end
    return { ok = true, leaderboard = list, position = own, sort = Config.Leaderboard.sort }
end)
