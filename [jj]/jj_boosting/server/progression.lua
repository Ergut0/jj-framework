-- Perfil y experiencia
Progression = {}

-- Nombre visible inicial: anónimo y sin repetir ninguno
local function defaultName(identifier, attempt)
    local tail = identifier:sub(-8):gsub('[^%w]', 'x')
    return attempt == 1 and ('Ghost_' .. tail) or ('Ghost_%s%d'):format(tail, math.random(100, 999))
end

-- Devuelve el perfil, creándolo si es la primera vez
function Progression.GetProfile(player)
    local identifier = Bridge.Identifier(player)
    local profile = DB.GetProfile(identifier)
    if profile then return profile end

    for attempt = 1, 3 do
        DB.CreateProfile(identifier, defaultName(identifier, attempt))
        profile = DB.GetProfile(identifier)
        if profile then return profile end
    end
end

function Progression.DecodeServices(profile)
    if type(profile.services) ~= 'string' then return {} end
    local ok, services = pcall(json.decode, profile.services)
    return ok and type(services) == 'table' and services or {}
end

function Progression.AddService(identifier, service, uses)
    local profile = DB.GetProfile(identifier)
    if not profile then return false end
    local services = Progression.DecodeServices(profile)
    services[service] = (services[service] or 0) + uses
    DB.UpdateServices(identifier, json.encode(services))
    return true
end

-- Gasta un uso de un servicio. Devuelve true si tenía
function Progression.UseService(identifier, service)
    local profile = DB.GetProfile(identifier)
    if not profile then return false end
    local services = Progression.DecodeServices(profile)
    if (services[service] or 0) <= 0 then return false end
    services[service] = services[service] - 1
    DB.UpdateServices(identifier, json.encode(services))
    return true
end

-- Datos públicos del perfil para la interfaz
function Progression.View(profile)
    local level, current, nextXp = Boost.GetLevel(profile.xp)
    return {
        name = profile.display_name,
        avatar = profile.avatar_url,
        xp = profile.xp,
        crypto = profile.crypto,
        completed = profile.completed,
        failed = profile.failed,
        moneyEarned = profile.money_earned,
        cryptoEarned = profile.crypto_earned,
        level = level,
        levelXp = current,
        nextLevelXp = nextXp,
        currentClass = Boost.GetCurrentClass(profile.xp),
        services = Progression.DecodeServices(profile),
    }
end

-- Dominio de una URL validada, o nil
function Progression.ValidAvatar(url)
    if type(url) ~= 'string' or #url > 250 then return false end
    local domain = url:match('^https://([%w%.%-]+)/[%w%-%._~/%%%?=&]+$')
    if not domain then return false end

    for _, allowed in ipairs(Config.Profile.avatarDomains) do
        if domain == allowed then return true end
    end
    return false
end

Security.Register('updateProfile', { lock = true }, function(src, player, identifier, data)
    local profile = Progression.GetProfile(player)

    if data.name ~= nil and data.name ~= profile.display_name then
        local name = Security.CleanText(data.name, Config.Profile.nameMax)
        if not name or #name < Config.Profile.nameMin or not name:match('^[%w_%-%. ]+$') then
            return { ok = false, message = Boost.T('name_invalid') }
        end
        if os.time() - profile.name_changed_at < Config.Profile.nameCooldown then
            return { ok = false, message = Boost.T('name_cooldown') }
        end
        if DB.NameExists(name, identifier) then
            return { ok = false, message = Boost.T('name_taken') }
        end
        DB.UpdateName(identifier, name, os.time())
    end

    if data.avatar ~= nil and data.avatar ~= profile.avatar_url then
        if data.avatar == '' then
            DB.UpdateAvatar(identifier, nil)
        elseif Progression.ValidAvatar(data.avatar) then
            DB.UpdateAvatar(identifier, data.avatar)
        else
            return { ok = false, message = Boost.T('avatar_invalid') }
        end
    end

    Leaderboard.Invalidate()
    return { ok = true, message = Boost.T('saved'), profile = Progression.View(DB.GetProfile(identifier)) }
end)
