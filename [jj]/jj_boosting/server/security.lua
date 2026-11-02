-- Toda llamada del cliente pasa por Security.Register: jugador cargado, límite de frecuencia y permisos
Security = {}

local lastCall = {}
local blocked = {}

function Security.Flag(src, action, details)
    local player = Bridge.GetPlayer(src)
    DB.Log('security', player and Bridge.Identifier(player) or tostring(src), nil, action, details)
end

local function throttled(src, name, delay)
    local now = GetGameTimer()
    local calls = lastCall[src]
    if not calls then
        calls = {}
        lastCall[src] = calls
    end

    if calls[name] and now - calls[name] < delay then
        blocked[src] = (blocked[src] or 0) + 1
        if blocked[src] == Config.RateLimit.flagAfter then
            Security.Flag(src, 'rate_limit', { call = name })
        end
        return true
    end

    calls[name] = now
    blocked[src] = 0
    return false
end

-- Evita que dos llamadas del mismo jugador se solapen en operaciones con dinero o estado
local busy = {}

function Security.Lock(src)
    if busy[src] then return false end
    busy[src] = true
    return true
end

function Security.Unlock(src)
    busy[src] = nil
end

---@param name string
---@param options { delay?: number, admin?: boolean, lock?: boolean }
---@param handler fun(src: number, player: table, identifier: string, data: table): any
function Security.Register(name, options, handler)
    local delay = options.delay or Config.RateLimit.default

    lib.callback.register('jj_boosting:' .. name, function(src, data)
        local player = Bridge.GetPlayer(src)
        if not player then return { ok = false, message = Boost.T('no_profile') } end

        if options.admin and not Bridge.IsAdmin(src, player) then
            Security.Flag(src, 'admin_denied', { call = name })
            return { ok = false, message = Boost.T('no_permission') }
        end

        if throttled(src, name, delay) then
            return { ok = false, message = Boost.T('too_fast') }
        end

        if type(data) ~= 'table' then data = {} end

        if options.lock and not Security.Lock(src) then
            return { ok = false, message = Boost.T('too_fast') }
        end

        local ok, result = pcall(handler, src, player, Bridge.Identifier(player), data)

        if options.lock then Security.Unlock(src) end

        if not ok then
            print(('^1[jj_boosting] Error en %s: %s^7'):format(name, tostring(result)))
            return { ok = false, message = Boost.T('internal') }
        end

        return result
    end)
end

function Security.Clean(src)
    lastCall[src] = nil
    blocked[src] = nil
    busy[src] = nil
end

-- Texto recibido del cliente
function Security.CleanText(value, maxLength)
    if type(value) ~= 'string' then return nil end
    local text = value:gsub('[%c<>]', ''):match('^%s*(.-)%s*$')
    if text == '' or #text > maxLength then return nil end
    return text
end

function Security.ToInt(value, minimum, maximum)
    local parsed = tonumber(value)
    local number = parsed and math.tointeger(parsed)
    if not number or number < minimum or number > maximum then return nil end
    return number
end
