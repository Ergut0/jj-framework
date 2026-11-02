Utils = {}

-- Traduccion con fallback a ingles y a la propia clave
function L(key, ...)
    local str = (Locales[Config.Locale] and Locales[Config.Locale][key]) or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        return ok and res or str
    end
    return str
end

function Utils.Debug(...)
    if Config.Debug then print('^3[races]^7', ...) end
end

function Utils.Trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Devuelve una cadena recortada y con espacios colapsados, o nil si no es valida
function Utils.Str(v, maxLen)
    if type(v) ~= 'string' then return nil end
    if #v > (maxLen or 255) then return nil end
    v = Utils.Trim(v):gsub('%s+', ' ')
    if v:find('[%c]') then return nil end
    return v
end

-- Texto sin caracteres que puedan interpretarse como marcado
function Utils.PlainStr(v, maxLen)
    local s = Utils.Str(v, maxLen)
    if not s or s:find('[<>"`]') then return nil end
    return s
end

-- Devuelve un entero dentro de rango o nil
function Utils.Int(v, min, max)
    if type(v) ~= 'number' or v ~= v then return nil end
    if v == math.huge or v == -math.huge then return nil end
    if v ~= math.floor(v) then return nil end
    if min and v < min then return nil end
    if max and v > max then return nil end
    return math.tointeger(v) or v
end

-- Devuelve un numero finito dentro de rango o nil
function Utils.Num(v, min, max)
    if type(v) ~= 'number' or v ~= v then return nil end
    if v == math.huge or v == -math.huge then return nil end
    if min and v < min then return nil end
    if max and v > max then return nil end
    return v + 0.0
end

function Utils.Bool(v)
    if type(v) == 'boolean' then return v end
    return nil
end

function Utils.Clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function Utils.Round(v, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(v * m + 0.5) / m
end

function Utils.IsHexColor(c)
    return type(c) == 'string' and c:match('^#%x%x%x%x%x%x$') ~= nil
end

function Utils.DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Utils.DeepCopy(v) end
    return out
end

function Utils.Contains(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

function Utils.Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function Utils.Dist3(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Utils.Dist2(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Hash de modelo normalizado a 32 bits sin signo (GetEntityModel y GetHashKey pueden diferir en signo)
function Utils.NormHash(h)
    if type(h) ~= 'number' then return nil end
    h = math.tointeger(h)
    if not h then return nil end
    return h & 0xFFFFFFFF
end

-- Formatea milisegundos como m:ss.mmm
function Utils.FormatTime(ms)
    if type(ms) ~= 'number' or ms < 0 then return '--:--.---' end
    ms = math.floor(ms)
    local minutes = ms // 60000
    local seconds = (ms % 60000) // 1000
    return ('%d:%02d.%03d'):format(minutes, seconds, ms % 1000)
end

function Utils.IsPointToPoint(category)
    return Config.PointToPointCategories[category] == true
end
