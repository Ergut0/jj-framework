-- Ranking de crews por puntos (cache con invalidacion)
Ranking = { list = nil, builtAt = 0, ttl = 30000 }

function Ranking.Invalidate() Ranking.list = nil end

local function build()
    local arr = {}
    for _, crew in pairs(Cache.crews) do arr[#arr + 1] = crew end
    table.sort(arr, function(a, b)
        if a.points ~= b.points then return a.points > b.points end
        if a.wins ~= b.wins then return a.wins > b.wins end
        return a.id < b.id
    end)
    local list = {}
    for i, c in ipairs(arr) do
        local count = 0
        for _ in pairs(c.members) do count = count + 1 end
        list[i] = {
            pos = i, id = c.id, name = c.name, tag = c.tag, color = c.color, logo = c.logo,
            level = c.level, points = c.points, wins = c.wins, members = count,
        }
    end
    Ranking.list = list
    Ranking.builtAt = GetGameTimer()
end

--- Devuelve el top N y la posicion del crew indicado
function Ranking.Get(myCrewId)
    if not Ranking.list or GetGameTimer() - Ranking.builtAt > Ranking.ttl then build() end
    local top, mine = {}, nil
    for i, row in ipairs(Ranking.list) do
        if i <= Config.RankingSize then top[#top + 1] = row end
        if row.id == myCrewId then mine = row end
    end
    return top, mine
end
