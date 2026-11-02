-- Historial de contratos
History = {}

local PAGE_SIZE = 25
local RESULTS = {
    [Boost.Status.COMPLETED] = true,
    [Boost.Status.FAILED] = true,
    [Boost.Status.EXPIRED] = true,
    [Boost.Status.ABANDONED] = true,
    [Boost.Status.DECLINED] = true,
}

-- Filtros recibidos del cliente, reducidos a valores conocidos
function History.CleanFilter(data)
    return {
        result = RESULTS[data.result] and data.result or nil,
        class = Config.Classes[data.class] and data.class or nil,
    }
end

function History.Page(data)
    return (Security.ToInt(data.page, 0, 10000) or 0) * PAGE_SIZE
end

function History.Add(contract, result, reason, duration, money, crypto, xp, playerName)
    DB.InsertHistory({
        uid = contract.uid,
        identifier = contract.identifier,
        player_name = playerName or contract.playerName or contract.identifier,
        class = contract.class,
        model = contract.model,
        label = contract.label,
        result = result,
        reason = reason,
        duration = math.max(duration or 0, 0),
        reward_money = money or 0,
        reward_crypto = crypto or 0,
        reward_xp = xp or 0,
    })
end

Security.Register('getHistory', {}, function(_, _, identifier, data)
    local filter = History.CleanFilter(data)
    filter.identifier = identifier
    return { ok = true, history = DB.GetHistory(filter, PAGE_SIZE, History.Page(data)), pageSize = PAGE_SIZE }
end)

History.PAGE_SIZE = PAGE_SIZE
