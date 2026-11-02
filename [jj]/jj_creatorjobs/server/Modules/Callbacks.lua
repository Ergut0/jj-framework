--[[
    Callbacks del servidor: datos para la interfaz y para los puntos del trabajo.
]]

local function NormalizeIds(rows)
    for _, row in ipairs(rows) do
        row.id = tonumber(row.id)
    end
    return rows
end

--- Lo que necesita un cliente de su propio trabajo; los administradores pueden ver cualquiera.
local function ResolveOwnJob(source, jobName)
    local resolved = ResolveJobName(jobName)
    if not resolved then return nil end
    if IsAdmin(source) then return resolved end

    local player = JJ.GetPlayer(source)
    if player and player.getJob().name == resolved then
        return resolved
    end
    return nil
end

-- =============================================================
-- Interfaz
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:canOpen', function(source)
    if IsAdmin(source) then return true end
    local player, jobName, job = GetPlayerContext(source)
    return player ~= nil and job ~= nil and HasGradePermission(player, jobName)
end)

-- Administrador: lista de trabajos. Jefe: su trabajo. Cualquier otro: false
lib.callback.register('jj_creatorjobs:callback:getPanel', function(source)
    if IsAdmin(source) then
        local list = {}
        for _, job in pairs(Jobs) do
            list[#list + 1] = { id = job.id, name = job.name, label = job.label, img = job.img, open = job.open }
        end
        table.sort(list, function(a, b) return a.id < b.id end)
        return { admin = true, jobs = list, maxLevel = Config.MaxLevel, maxExp = Config.MaxExp }
    end

    local player, jobName, job = GetPlayerContext(source)
    if not player or not job or not HasGradePermission(player, jobName) then return false end
    return { admin = false, job = BuildJobData(job), maxLevel = Config.MaxLevel, maxExp = Config.MaxExp }
end)

lib.callback.register('jj_creatorjobs:callback:getJob', function(source, jobName)
    local resolved = ResolveJobName(jobName)
    if not resolved then return false end

    if not IsAdmin(source) then
        local player = JJ.GetPlayer(source)
        if not HasGradePermission(player, resolved) then return false end
    end
    return BuildJobData(Jobs[resolved])
end)

-- Registro de una empresa, para el administrador y para sus jefes
lib.callback.register('jj_creatorjobs:callback:getLogs', function(source, jobName)
    local resolved = ResolveJobName(jobName)
    if not resolved then return {} end

    if not IsAdmin(source) and not HasGradePermission(JJ.GetPlayer(source), resolved) then return {} end

    return NormalizeIds(MySQL.query.await('SELECT id, category, actor, message, created_at FROM jobscreator_logs WHERE job = ? ORDER BY id DESC LIMIT 300', { resolved }) or {})
end)

lib.callback.register('jj_creatorjobs:callback:getGlobalTeleportsAdmin', function(source)
    if not IsAdmin(source) then return {} end
    return NormalizeIds(MySQL.query.await('SELECT * FROM jobscreator_global_teleports') or {})
end)

-- =============================================================
-- Datos del trabajo del propio jugador
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:getPerms', function(source, jobName)
    local resolved = ResolveOwnJob(source, jobName)
    if not resolved then return {} end
    return NormalizeIds(MySQL.query.await('SELECT id, typePermission FROM jobscreator_perms WHERE job = ?', { resolved }) or {})
end)

lib.callback.register('jj_creatorjobs:callback:getPoints', function(source, jobName)
    local resolved = ResolveOwnJob(source, jobName)
    if not resolved then return {} end
    return NormalizeIds(MySQL.query.await('SELECT id, x, y, z, heading, typePoint, unique_identifier, radius FROM jobscreator_points WHERE job = ?', { resolved }) or {})
end)

lib.callback.register('jj_creatorjobs:callback:getMarket', function(source, jobName)
    local resolved = ResolveOwnJob(source, jobName)
    if not resolved then return {} end

    local rows = NormalizeIds(MySQL.query.await('SELECT id, name, price FROM jobscreator_market WHERE job = ?', { resolved }) or {})
    for _, row in ipairs(rows) do
        row.price = tonumber(row.price) or 0
        local itemData = exports.ox_inventory:Items(row.name)
        row.label = itemData and itemData.label or row.name
    end
    return rows
end)

lib.callback.register('jj_creatorjobs:callback:getVehicles', function(source, jobName)
    local resolved = ResolveOwnJob(source, jobName)
    if not resolved then return {} end

    local rows = NormalizeIds(MySQL.query.await('SELECT id, name FROM jobscreator_vehicles WHERE job = ?', { resolved }) or {})
    return rows
end)

lib.callback.register('jj_creatorjobs:callback:getTeleports', function(source, jobName)
    local resolved = ResolveOwnJob(source, jobName)
    if not resolved then return {} end

    local rows = NormalizeIds(MySQL.query.await('SELECT * FROM jobscreator_teleports WHERE job = ?', { resolved }) or {})
    for _, row in ipairs(rows) do
        row.job_only = IsTrue(row.job_only) and 1 or 0
        row.on_duty_only = IsTrue(row.on_duty_only) and 1 or 0
        row.allow_vehicle = IsTrue(row.allow_vehicle) and 1 or 0
    end
    return rows
end)

lib.callback.register('jj_creatorjobs:callback:getPublicTeleports', function()
    local rows = NormalizeIds(MySQL.query.await('SELECT * FROM jobscreator_teleports WHERE job_only = 0') or {})
    for _, row in ipairs(rows) do
        row.allow_vehicle = IsTrue(row.allow_vehicle) and 1 or 0
    end
    return rows
end)

-- La contraseña no sale del servidor
lib.callback.register('jj_creatorjobs:callback:getGlobalTeleports', function()
    local rows = NormalizeIds(MySQL.query.await('SELECT * FROM jobscreator_global_teleports') or {})
    for _, row in ipairs(rows) do
        row.hasPassword = row.password ~= nil and row.password ~= ''
        row.password = nil
    end
    return rows
end)

-- =============================================================
-- Zonas y blips globales
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:getAllZones', function()
    local rows = MySQL.query.await("SELECT job, x, y, z, radius FROM jobscreator_points WHERE typePoint = 'Zona Centro'") or {}
    local zones = {}
    for _, row in ipairs(rows) do
        zones[#zones + 1] = {
            coords = { x = row.x, y = row.y, z = row.z },
            radius = tonumber(row.radius) or 25.0,
            name = row.job,
        }
    end
    return zones
end)

lib.callback.register('jj_creatorjobs:callback:getAllBlips', function()
    local rows = NormalizeIds(MySQL.query.await('SELECT id, job, x, y, z, label, blipsprite, blipcolor FROM jobscreator_blips') or {})
    for _, row in ipairs(rows) do
        row.open = Jobs[row.job] and Jobs[row.job].open or false
    end
    return rows
end)

-- =============================================================
-- Sociedad
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:getSocietyInfo', function(source)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job or not HasGradePermission(player, jobName) then return false end
    return { money = job:GetMoney(), level = job.level, experience = job.experience }
end)

-- =============================================================
-- Compraventa
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:getVehiclesJob', function(source)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job then return {} end

    local rows = NormalizeIds(MySQL.query.await('SELECT id, vehicle, plate, price, state FROM jobscreator_compraventa WHERE job = ?', { jobName }) or {})
    for _, row in ipairs(rows) do
        row.state = tonumber(row.state) or 0
        row.price = tonumber(row.price) or 0
    end
    return rows
end)

lib.callback.register('jj_creatorjobs:callback:comprobateVehicle', function(source, plate)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job or not plate then return false end

    plate = tostring(plate):gsub('%s+', ''):upper()
    return MySQL.scalar.await('SELECT 1 FROM jobscreator_compraventa WHERE plate = ? AND job = ?', { plate, jobName }) ~= nil
end)

-- =============================================================
-- Lonja
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:getItemLonjaByType', function(source, typeLonja)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job or not typeLonja then return {} end

    local rows = NormalizeIds(MySQL.query.await('SELECT id, name, label, amount FROM jobscreator_lonja WHERE typeLonja = ? AND job = ? AND amount > 0', { typeLonja, jobName }) or {})
    for _, row in ipairs(rows) do
        row.amount = tonumber(row.amount) or 0
    end
    return rows
end)
