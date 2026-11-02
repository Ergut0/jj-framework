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
    if Config.Debug then print('^3[crews]^7', ...) end
end

function Utils.Trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Devuelve una cadena recortada y con espacios colapsados, o nil si no es valida
function Utils.Str(v, maxLen)
    if type(v) ~= 'string' then return nil end
    if #v > (maxLen or 255) then return nil end
    v = Utils.Trim(v):gsub('%s+', ' ')
    -- Fuera caracteres de control
    if v:find('[%c]') then return nil end
    return v
end

-- Devuelve un entero dentro de rango o nil
function Utils.Int(v, min, max)
    if type(v) ~= 'number' or v ~= v then return nil end
    if v ~= math.floor(v) then return nil end
    if min and v < min then return nil end
    if max and v > max then return nil end
    return math.tointeger(v) or v
end

function Utils.Bool(v)
    if type(v) == 'boolean' then return v end
    return nil
end

function Utils.IsHexColor(c)
    return type(c) == 'string' and c:match('^#%x%x%x%x%x%x$') ~= nil
end

-- Normaliza para comparar nombres prohibidos (leet, espacios, simbolos)
local leet = { ['0'] = 'o', ['1'] = 'i', ['3'] = 'e', ['4'] = 'a', ['5'] = 's', ['7'] = 't', ['@'] = 'a', ['$'] = 's' }
function Utils.Normalize(s)
    s = s:lower():gsub('[01345 7@$]', function(c) return leet[c] or '' end)
    return (s:gsub('[^%a]', ''))
end

function Utils.IsBanned(name, banned)
    local n = Utils.Normalize(name)
    for _, word in ipairs(banned or {}) do
        local w = Utils.Normalize(tostring(word))
        if w ~= '' and n:find(w, 1, true) then return true end
    end
    return false
end

-- Valida URL del logo: https, sin espacios/comillas, host opcionalmente en lista blanca
function Utils.IsValidLogo(url)
    if url == '' then return true end
    if type(url) ~= 'string' or #url > 255 then return false end
    if url:find('[%s"\'<>\\]') then return false end
    local host = url:match('^https://([^/:?#]+)')
    if not host then return false end
    local hosts = Config.LogoHosts
    if hosts and #hosts > 0 then
        host = host:lower()
        for _, h in ipairs(hosts) do
            if host == h:lower() then return true end
        end
        return false
    end
    return true
end

function Utils.DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = Utils.DeepCopy(v) end
    return out
end

function Utils.LevelFromPoints(points)
    local level = 1
    for i, req in ipairs(Config.LevelPoints) do
        if points >= req then level = i end
    end
    return level
end
