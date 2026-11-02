--[[
    Funciones compartidas del servidor: registro de trabajos en jj-framework,
    permisos, datos para la interfaz y empleados.
]]

--- Registro en memoria de los trabajos: Jobs[name] = instancia de Job
Jobs = {}

--- Cierto cuando los trabajos ya están registrados en jj-framework
JobsReady = false

--- Notificación a un jugador.
function Notify(source, msg, type)
    TriggerClientEvent('ox_lib:notify', source, { description = msg, type = type or 'inform' })
end

--- Nombre de un personaje, esté conectado o no.
function GetCharacterLabel(identifier)
    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then return player.getName() end
    return MySQL.scalar.await('SELECT name FROM jj_players WHERE identifier = ?', { identifier }) or identifier
end

function GetGradeName(jobName, grade)
    return MySQL.scalar.await('SELECT label FROM jobscreator_grades WHERE job_name = ? AND id = ?', { jobName, grade }) or ('nivel %s'):format(grade)
end

function IsAdmin(source)
    return JJ.IsAdmin(source)
end

--- Devuelve el jugador, el nombre de su trabajo y el trabajo creado, si lo es.
function GetPlayerContext(source)
    local player = JJ.GetPlayer(source)
    if not player then return nil end
    local jobData = player.getJob()
    return player, jobData.name, Jobs[jobData.name], jobData
end

--- Resuelve el nombre de un trabajo a partir de su id numérico o su nombre.
function ResolveJobName(idOrName)
    if idOrName == nil then return nil end

    if type(idOrName) == 'number' or tonumber(idOrName) ~= nil then
        local id = tonumber(idOrName)
        for name, job in pairs(Jobs) do
            if job.id == id then
                return name
            end
        end
    end

    local name = tostring(idOrName)
    if Jobs[name] then return name end
    return nil
end

--- Devuelve los rangos de un trabajo ordenados por nivel.
function GetJobGrades(jobName)
    local rows = MySQL.query.await('SELECT id, name, label, salary, permission FROM jobscreator_grades WHERE job_name = ? ORDER BY id ASC', { jobName }) or {}
    for _, row in ipairs(rows) do
        row.id = tonumber(row.id)
        row.salary = tonumber(row.salary) or 0
        row.permission = IsTrue(row.permission)
    end
    return rows
end

--- Comprueba si el jugador es jefe de ese trabajo.
function HasGradePermission(player, jobName)
    if not player then return false end
    local jobData = player.getJob()
    return jobData.name == jobName and jobData.isBoss == true
end

--- Comprueba si el trabajo del jugador tiene una opción del menú F6.
function HasJobOption(jobName, option)
    return MySQL.scalar.await('SELECT 1 FROM jobscreator_perms WHERE job = ? AND typePermission = ? LIMIT 1', { jobName, option }) ~= nil
end

local function GetGradeLabel(grades, level)
    for _, grade in ipairs(grades) do
        if grade.id == level then
            return grade.label
        end
    end
    return tostring(level)
end

--- Empleados de un trabajo. Los conectados mandan sobre la base de datos, que solo se actualiza al guardar.
function GetJobEmployees(jobName)
    local grades = GetJobGrades(jobName)
    local rows = MySQL.query.await('SELECT identifier, name, charinfo, job_grade FROM jj_players WHERE job = ?', { jobName }) or {}
    local employees = {}

    local function add(identifier, name, level, onDuty, online)
        employees[#employees + 1] = {
            identifier = identifier,
            nombre = name,
            grade = level,
            gradeLabel = GetGradeLabel(grades, level),
            onduty = onDuty,
            online = online,
        }
    end

    for _, row in ipairs(rows) do
        if not JJ.GetPlayerByIdentifier(row.identifier) then
            local charinfo = row.charinfo and json.decode(row.charinfo)
            local name = charinfo and ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '') or row.name
            add(row.identifier, name, tonumber(row.job_grade) or 0, false, false)
        end
    end

    for _, src in ipairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        local jobData = player and player.getJob()
        if jobData and jobData.name == jobName then
            local charinfo = player.getCharInfo()
            local name = charinfo and ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '') or player.getName()
            add(player.identifier, name, jobData.grade, jobData.onDuty == true, true)
        end
    end

    return employees
end

local function NormalizeIds(rows)
    for _, row in ipairs(rows) do
        row.id = tonumber(row.id)
    end
    return rows
end

--- Construye el objeto completo de un trabajo para la interfaz.
function BuildJobData(job)
    local jobName = job.name

    local items = NormalizeIds(MySQL.query.await('SELECT id, name, price FROM jobscreator_market WHERE job = ?', { jobName }) or {})
    for _, item in ipairs(items) do
        item.price = tonumber(item.price) or 0
        local itemData = exports.ox_inventory:Items(item.name)
        item.label = itemData and itemData.label or item.name
    end

    local vehicles = NormalizeIds(MySQL.query.await('SELECT id, name, livery FROM jobscreator_vehicles WHERE job = ?', { jobName }) or {})
    for _, vehicle in ipairs(vehicles) do
        vehicle.livery = tonumber(vehicle.livery) or 0
    end

    local teleports = NormalizeIds(MySQL.query.await('SELECT * FROM jobscreator_teleports WHERE job = ?', { jobName }) or {})
    for _, teleport in ipairs(teleports) do
        teleport.job_only = IsTrue(teleport.job_only)
        teleport.on_duty_only = IsTrue(teleport.on_duty_only)
        teleport.allow_vehicle = IsTrue(teleport.allow_vehicle)
    end

    return {
        id = job.id,
        name = job.name,
        label = job.label,
        img = job.img,
        open = job.open,
        level = job.level,
        experience = job.experience,
        money = job:GetMoney(),
        employees = GetJobEmployees(jobName),
        grades = GetJobGrades(jobName),
        items = items,
        points = NormalizeIds(MySQL.query.await('SELECT id, x, y, z, heading, typePoint, radius FROM jobscreator_points WHERE job = ?', { jobName }) or {}),
        blips = NormalizeIds(MySQL.query.await('SELECT id, x, y, z, label, blipsprite, blipcolor FROM jobscreator_blips WHERE job = ?', { jobName }) or {}),
        vehicles = vehicles,
        perms = NormalizeIds(MySQL.query.await('SELECT id, typePermission FROM jobscreator_perms WHERE job = ?', { jobName }) or {}),
        teleports = teleports,
    }
end

--- Crea los rangos por defecto de un trabajo.
function CreateDefaultGrades(jobName)
    local defaults = {
        { 0, 'empleado', 'Empleado', 0, 600 },
        { 1, 'encargado', 'Encargado', 0, 900 },
        { 2, 'jefe', 'Jefe', 1, 1200 },
    }
    for _, g in ipairs(defaults) do
        MySQL.insert.await('INSERT INTO jobscreator_grades (id, job_name, name, label, salary, permission) VALUES (?, ?, ?, ?, ?, ?)', {
            g[1], jobName, g[2], g[3], g[5], g[4]
        })
    end
end

--- Pide a fd_banking que cree o borre las cuentas de empresa según los trabajos actuales.
function SyncBankAccounts()
    TriggerEvent('fd_banking:UpdateObject')
end

--- Registra o actualiza un trabajo en jj-framework. Con nóminas de la sociedad,
--- el framework ve el sueldo a 0 para no pagarlo también.
function RegisterJobInCore(job)
    local grades = GetJobGrades(job.name)

    if #grades == 0 then
        CreateDefaultGrades(job.name)
        grades = GetJobGrades(job.name)
    end

    local coreGrades = {}
    local bossGrade = nil
    for _, grade in ipairs(grades) do
        coreGrades[grade.id] = {
            label = grade.label,
            salary = Config.SocietyPaycheck and 0 or grade.salary,
            isBoss = grade.permission,
        }
        if grade.permission and (not bossGrade or grade.id < bossGrade) then
            bossGrade = grade.id
        end
    end

    if not JJ.RegisterJob(job.name, { label = job.label, grades = coreGrades }) then
        print(('[jj_creatorjobs] No se ha podido registrar "%s": ya existe en la configuración de jj-framework.'):format(job.name))
        return false
    end

    -- Sin un rango de jefe, nadie puede abrir la caja fuerte
    RegisterBossStash(job, bossGrade or 1000)
    return true
end

function UpdateJobInCore(jobName)
    local job = Jobs[jobName]
    if not job then return false end
    return RegisterJobInCore(job)
end

function RemoveJobFromCore(jobName)
    return JJ.RemoveJob(jobName)
end

function RegisterBossStash(job, minGrade)
    exports.ox_inventory:RegisterStash(job.name .. 'jefe', ('Caja fuerte %s'):format(job.label), 50, 100000, false, { [job.name] = minGrade })
end

function RegisterPointStash(uniqueIdentifier, jobName)
    local jobLabel = Jobs[jobName] and Jobs[jobName].label or jobName
    exports.ox_inventory:RegisterStash(uniqueIdentifier, ('Inventario %s'):format(jobLabel), 70, 100000, false, { [jobName] = 0 })
end

--- El garaje personal de un trabajo es un garaje de jj_garages, que ya gestiona sacar y guardar.
function RegisterPointGarage(point, jobName)
    if GetResourceState('jj_garages') ~= 'started' then return end
    local jobLabel = Jobs[jobName] and Jobs[jobName].label or jobName
    exports.jj_garages:registerGarage(('creatorjob_%s'):format(point.id), {
        label = ('Garaje: %s'):format(jobLabel),
        takeVehicle = vector3(point.x, point.y, point.z),
        spawnPoint = { vector4(point.x, point.y, point.z, point.heading) },
        showBlip = false,
        type = 'job',
        job = jobName,
    })
end

function RemovePointGarage(pointId)
    if GetResourceState('jj_garages') ~= 'started' then return end
    exports.jj_garages:removeGarage(('creatorjob_%s'):format(pointId))
end

function RegisterJobGarages()
    local points = MySQL.query.await("SELECT id, job, x, y, z, heading FROM jobscreator_points WHERE typePoint = 'Garaje Personal'") or {}
    for _, point in ipairs(points) do
        point.id = tonumber(point.id)
        RegisterPointGarage(point, point.job)
    end
end

--- Carga todos los trabajos de la base de datos en memoria y en jj-framework.
function LoadJobs()
    local rows = MySQL.query.await('SELECT * FROM jobscreator_jobs') or {}
    Jobs = {}

    for _, row in ipairs(rows) do
        local job = Job.New(row)
        Jobs[job.name] = job
        RegisterJobInCore(job)
    end

    JobsReady = true
    print(('[jj_creatorjobs] %d trabajos cargados.'):format(#rows))
end

--- Registra los inventarios de los puntos.
function RegisterJobStashes()
    local points = MySQL.query.await("SELECT unique_identifier, job FROM jobscreator_points WHERE typePoint = 'Inventario' AND unique_identifier IS NOT NULL") or {}
    for _, point in ipairs(points) do
        RegisterPointStash(point.unique_identifier, point.job)
    end
end

--- Cambia el trabajo de un personaje, esté conectado o no.
function SetPlayerJobAnywhere(identifier, jobName, grade)
    if not identifier or not jobName then return false end
    grade = tonumber(grade) or 0

    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then
        return player.setJob(jobName, grade) == true
    end

    local affected = MySQL.update.await('UPDATE jj_players SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, grade, identifier })
    return affected ~= nil and affected > 0
end

function PlayerExists(identifier)
    if not identifier then return false end
    if JJ.GetPlayerByIdentifier(identifier) then return true end
    return MySQL.scalar.await('SELECT 1 FROM jj_players WHERE identifier = ?', { identifier }) ~= nil
end

--- Devuelve el trabajo y el rango actuales de un personaje, esté conectado o no.
function GetPlayerJobInfo(identifier)
    local player = JJ.GetPlayerByIdentifier(identifier)
    if player then
        local jobData = player.getJob()
        return jobData.name, jobData.grade
    end
    local row = MySQL.single.await('SELECT job, job_grade FROM jj_players WHERE identifier = ?', { identifier })
    if not row then return nil, nil end
    return row.job, tonumber(row.job_grade) or 0
end

function GradeExists(jobName, gradeLevel)
    return MySQL.scalar.await('SELECT 1 FROM jobscreator_grades WHERE job_name = ? AND id = ?', { jobName, tonumber(gradeLevel) or 0 }) ~= nil
end

function IsBossGrade(jobName, gradeLevel)
    return IsTrue(MySQL.scalar.await('SELECT permission FROM jobscreator_grades WHERE job_name = ? AND id = ?', { jobName, tonumber(gradeLevel) or 0 }))
end
