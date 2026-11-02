-- Niveles de acceso: mecánico, admin y superadmin. Todo se decide aquí, nunca en el cliente
Permissions = {}

-- Ajustes globales que el superadmin cambia desde el panel. Se guardan y pisan a config.lua
Permissions.Settings = {
    autoApply = Config.AutoApply,
    testMinutes = Config.TestMinutes,
    mechanicMaxRelative = Config.Levels.mechanic.maxRelative,
    mechanicSave = Config.Levels.mechanic.saveProfiles,
    mechanicInstall = Config.Levels.mechanic.install,
}

do
    local ok, saved = pcall(json.decode, GetResourceKvpString('settings') or '{}')
    if ok and type(saved) == 'table' then
        for key, value in pairs(saved) do
            if Permissions.Settings[key] ~= nil and type(value) == type(Permissions.Settings[key]) then
                Permissions.Settings[key] = value
            end
        end
    end
end

function Permissions.SaveSettings(values)
    local settings = Permissions.Settings
    if type(values.autoApply) == 'boolean' then settings.autoApply = values.autoApply end
    if type(values.mechanicSave) == 'boolean' then settings.mechanicSave = values.mechanicSave end
    if type(values.mechanicInstall) == 'boolean' then settings.mechanicInstall = values.mechanicInstall end
    local minutes = tonumber(values.testMinutes)
    if minutes and Utils.IsFiniteNumber(minutes) then settings.testMinutes = math.floor(math.max(0, math.min(240, minutes))) end
    local relative = tonumber(values.mechanicMaxRelative)
    if relative and Utils.IsFiniteNumber(relative) then settings.mechanicMaxRelative = Utils.Round(math.max(0.05, math.min(2, relative)), 2) end

    SetResourceKvp('settings', json.encode(settings))
    return settings
end

local function mechanicLevel(src)
    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    if not job then return nil end
    local minGrade = Config.MechanicJobs[job.name]
    if not minGrade or (job.grade or 0) < minGrade then return nil end
    if Config.MechanicRequiresDuty and job.onDuty == false then return nil end
    return job.name
end

-- Devuelve el nivel ('superadmin', 'admin', 'mechanic' o nil) y sus reglas
function Permissions.Get(src)
    local level
    if IsPlayerAceAllowed(tostring(src), Config.SuperAdminAce) then
        level = 'superadmin'
    elseif JJ.IsAdmin(src) then
        level = 'admin'
    elseif mechanicLevel(src) then
        level = 'mechanic'
    end
    if not level then return nil end

    local rules = Utils.Copy(Config.Levels[level])
    if level == 'mechanic' then
        rules.maxRelative = Permissions.Settings.mechanicMaxRelative
        rules.saveProfiles = rules.saveProfiles and Permissions.Settings.mechanicSave
        rules.install = rules.install and Permissions.Settings.mechanicInstall
    end
    return level, rules
end

-- Parámetros que puede tocar con esas reglas: { clave = true }
function Permissions.AllowedParams(rules)
    local categories = {}
    if rules.categories ~= 'all' then
        for _, category in ipairs(rules.categories or {}) do categories[category] = true end
    end
    local excluded = {}
    for _, key in ipairs(rules.exclude or {}) do excluded[key] = true end

    local allowed = {}
    for _, param in ipairs(Parameters.List) do
        local inCategory = rules.categories == 'all' or categories[param.category]
        for _, extra in ipairs(Parameters.AlsoIn[param.key] or {}) do
            if categories[extra] then inCategory = true end
        end
        if inCategory and not excluded[param.key] then allowed[param.key] = true end
    end
    return allowed
end

-- Taller en el que está el vehículo y que el jugador puede usar
function Permissions.Workshop(src, vehicle)
    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    local coords = GetEntityCoords(vehicle)

    for index, workshop in ipairs(Config.Workshops) do
        local jobAllowed = not workshop.jobs
        for _, name in ipairs(workshop.jobs or {}) do
            if job and job.name == name then jobAllowed = true end
        end
        if jobAllowed and #(coords - workshop.coords) <= workshop.radius then
            return index, workshop
        end
    end
    return nil
end

-- Datos de quien hace la acción, para guardar autor y registros
function Permissions.Actor(src)
    local player = JJ.GetPlayer(src)
    local data = player and player.getData()
    return {
        identifier = data and data.identifier or ('src:%d'):format(src),
        name = (player and player.getName()) or GetPlayerName(src) or ('Jugador %d'):format(src),
    }
end
