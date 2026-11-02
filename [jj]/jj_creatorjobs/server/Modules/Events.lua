--[[
    Acciones de la interfaz: trabajos, rangos, puntos, blips, mercado, vehículos,
    opciones y teleports. La interfaz espera a que terminen antes de recargar los
    datos. Sincronizan los cambios con todos los clientes conectados.
]]

local actions = {}

local function Action(name, handler)
    actions[name] = handler
end

lib.callback.register('jj_creatorjobs:callback:action', function(source, name, data)
    local handler = type(name) == 'string' and actions[name]
    if not handler then return false end
    if not JobsReady then
        Notify(source, 'El creador de trabajos no está listo: jj-framework está anticuado', 'error')
        return false
    end
    handler(source, data)
    return true
end)

--- Un jefe solo gestiona empleados de su trabajo. El resto es de los administradores.
local function CanManageEmployees(source, jobName)
    if IsAdmin(source) then return true end
    return HasGradePermission(JJ.GetPlayer(source), jobName)
end

--- Un jefe no puede actuar sobre otro jefe ni sobre sí mismo.
local function CanTouchEmployee(source, identifier, currentGrade, jobName)
    if IsAdmin(source) then return true end
    if JJ.GetPlayer(source).identifier == identifier then return false end
    return not IsBossGrade(jobName, currentGrade)
end

--- Convierte booleanos/numéricos de la NUI a 1/0 para la base de datos.
local function ToDbBool(value)
    if value == true or value == 1 or value == '1' then return 1 end
    return 0
end

-- =============================================================
-- Trabajos
-- =============================================================

Action('createJob', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' or not data.job or not data.jobLabel then return end

    local jobName = tostring(data.job):lower():gsub('%s+', '')
    local jobLabel = tostring(data.jobLabel)
    if not jobName:match('^[%w_]+$') or jobLabel == '' then
        Notify(src, 'El nombre interno solo puede tener letras, números y guiones bajos', 'error')
        return
    end

    if Jobs[jobName] or JJ.GetJobs()[jobName] then
        Notify(src, 'Ya existe un trabajo con ese nombre', 'error')
        return
    end

    local id = MySQL.insert.await('INSERT INTO jobscreator_jobs (name, label, img, open, level, experience, money) VALUES (?, ?, ?, 1, 1, 0, 0)', {
        jobName, jobLabel, Config.ImageServer
    })
    if not id then return end

    CreateDefaultGrades(jobName)

    local job = Job.New({
        id = id,
        name = jobName,
        label = jobLabel,
        img = Config.ImageServer,
        open = 1,
        level = 1,
        experience = 0,
        money = 0,
    })
    Jobs[jobName] = job

    RegisterJobInCore(job)
    SyncBankAccounts()

    Notify(src, ('Trabajo %s creado correctamente'):format(jobLabel), 'success')

    Log(src, 'config', jobName, ('Ha creado el trabajo %s'):format(jobLabel))
end)

Action('deleteJob', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' or not data.id then return end

    local jobName = ResolveJobName(data.id)
    if not jobName then return end

    -- Los garajes del trabajo devuelven sus vehículos al garaje por defecto
    local garages = MySQL.query.await("SELECT id FROM jobscreator_points WHERE job = ? AND typePoint = 'Garaje Personal'", { jobName }) or {}
    for _, garage in ipairs(garages) do
        RemovePointGarage(garage.id)
    end

    -- Despedir a todos los empleados del trabajo
    local defaultJob = JJ.Config.DefaultJob
    MySQL.update.await('UPDATE jj_players SET job = ?, job_grade = 0 WHERE job = ?', { defaultJob, jobName })

    MySQL.query.await('DELETE FROM jobscreator_jobs WHERE name = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_grades WHERE job_name = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_points WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_blips WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_market WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_vehicles WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_perms WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_teleports WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_lonja WHERE job = ?', { jobName })
    MySQL.query.await('DELETE FROM jobscreator_compraventa WHERE job = ?', { jobName })

    Jobs[jobName] = nil
    -- jj-framework pasa al trabajo por defecto a los empleados conectados
    RemoveJobFromCore(jobName)
    SyncBankAccounts()

    Notify(src, 'Trabajo eliminado correctamente', 'success')

    Log(src, 'config', jobName, 'Ha borrado el trabajo')
end)

Action('updateJob', function(src, data)
    if type(data) ~= 'table' or not data.name then return end

    local jobName = ResolveJobName(data.name)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local job = Jobs[jobName]
    if not job then return end

    local label = data.label and tostring(data.label)
    job:Update({
        label = label ~= '' and label or nil,
        img = data.img and tostring(data.img) or nil,
        level = data.level,
        experience = data.experience,
    })

    if label and label ~= '' then
        UpdateJobInCore(jobName)
        SyncBankAccounts()
    end

    Log(src, 'config', jobName, 'Ha editado los datos del trabajo')
end)

Action('setJob', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' or not data.jobName then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName or not Jobs[jobName] then
        Notify(src, 'El trabajo no existe', 'error')
        return
    end

    local player = JJ.GetPlayer(src)
    if not player then return end

    local grade = tonumber(data.id) or 0
    if not GradeExists(jobName, grade) then
        Notify(src, 'Ese rango no existe en este trabajo', 'error')
        return
    end

    if SetPlayerJobAnywhere(player.identifier, jobName, grade) then
        Log(src, 'empleados', jobName, ('Se ha puesto el rango %s'):format(GetGradeName(jobName, grade)), 'jefe')
        Notify(src, ('Trabajo establecido: %s (rango %d)'):format(jobName, grade), 'success')
    else
        Notify(src, 'No se pudo establecer el trabajo', 'error')
    end
end)

-- =============================================================
-- Rangos (grades)
-- =============================================================

Action('insertGrade', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id or not data.label then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local gradeName = tostring(data.id):lower():gsub('%s+', '')
    if gradeName == '' then return end

    local maxRow = MySQL.single.await('SELECT MAX(id) AS maxId FROM jobscreator_grades WHERE job_name = ?', { jobName })
    local nextLevel = (tonumber(maxRow and maxRow.maxId) or -1) + 1
    local salary = math.max(0, math.floor(tonumber(data.salary) or 0))

    MySQL.insert.await('INSERT INTO jobscreator_grades (id, job_name, name, label, salary, permission) VALUES (?, ?, ?, ?, ?, 0)', {
        nextLevel, jobName, gradeName, tostring(data.label), salary
    })

    UpdateJobInCore(jobName)

    Notify(src, ('Rango %s añadido al nivel %d'):format(data.label, nextLevel), 'success')

    Log(src, 'config', jobName, ('Ha creado el rango %s'):format(tostring(data.label)))
end)

Action('updateGrade', function(src, data)
    if type(data) ~= 'table' or not data.jobName or data.idGrade == nil then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local gradeLevel = tonumber(data.idGrade)
    if not gradeLevel then return end

    local salary = math.max(0, math.floor(tonumber(data.salary) or 0))
    local permission = ToDbBool(data.permission)
    local label = tostring(data.label or '')
    local gradeName = tostring(data.name or ''):lower():gsub('%s+', '')

    MySQL.update.await('UPDATE jobscreator_grades SET name = ?, label = ?, salary = ?, permission = ? WHERE job_name = ? AND id = ?', {
        gradeName, label, salary, permission, jobName, gradeLevel
    })

    UpdateJobInCore(jobName)
    SyncBankAccounts()

    Notify(src, 'Rango actualizado correctamente', 'success')

    Log(src, 'config', jobName, ('Ha editado el rango %s: sueldo $%d%s'):format(label, salary, permission == 1 and ', con permisos de jefe' or ''))
end)

Action('deleteGrade', function(src, data)
    if type(data) ~= 'table' or not data.jobName or data.idGrade == nil then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local gradeLevel = tonumber(data.idGrade)
    if not gradeLevel then return end

    if gradeLevel == 0 then
        Notify(src, 'No puedes eliminar el rango base del trabajo', 'error')
        return
    end

    -- Los empleados que tenían ese rango pasan al rango base (0) antes de que desaparezca
    for _, employee in ipairs(GetJobEmployees(jobName)) do
        if employee.grade == gradeLevel then
            SetPlayerJobAnywhere(employee.identifier, jobName, 0)
        end
    end

    MySQL.query.await('DELETE FROM jobscreator_grades WHERE job_name = ? AND id = ?', { jobName, gradeLevel })
    UpdateJobInCore(jobName)
    SyncBankAccounts()

    Notify(src, 'Rango eliminado correctamente', 'success')

    Log(src, 'config', jobName, ('Ha borrado el rango de nivel %d'):format(gradeLevel))
end)

-- =============================================================
-- Empleados
-- =============================================================

Action('hirePlayer', function(src, data)
    if type(data) ~= 'table' or not data.jobName then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName or not Jobs[jobName] then
        Notify(src, 'El trabajo no existe', 'error')
        return
    end
    if not CanManageEmployees(src, jobName) then
        Notify(src, 'No tienes permisos para contratar en este trabajo', 'error')
        return
    end

    local grade = tonumber(data.grade) or 0
    if not GradeExists(jobName, grade) then
        Notify(src, 'El rango no existe en este trabajo', 'error')
        return
    end

    -- Un jefe contrata como empleado normal: los jefes los nombra un administrador
    if not IsAdmin(src) and IsBossGrade(jobName, grade) then
        Notify(src, 'Solo un administrador puede nombrar a otro jefe', 'error')
        return
    end

    -- Objetivo: id de servidor (conectado) o identificador del personaje (conectado o no)
    local target, identifier
    local targetId = tonumber(data.src)
    if targetId then
        target = JJ.GetPlayer(targetId)
        identifier = target and target.identifier
    end
    if not identifier and data.identifier then
        identifier = tostring(data.identifier)
        target = JJ.GetPlayerByIdentifier(identifier)
    end

    if not identifier or not PlayerExists(identifier) then
        Notify(src, 'El jugador no existe', 'error')
        return
    end

    -- Si no es admin y ambos están online, deben estar cerca
    if not IsAdmin(src) and target then
        local hirerCoords = GetEntityCoords(GetPlayerPed(src))
        local targetCoords = GetEntityCoords(GetPlayerPed(target.source))
        if #(hirerCoords - targetCoords) > 10.0 then
            Notify(src, 'El jugador está demasiado lejos', 'error')
            return
        end
    end

    -- No contratar si ya está en el mismo trabajo con el mismo rango
    local currentJob, currentGrade = GetPlayerJobInfo(identifier)
    if currentJob == jobName and currentGrade == grade then
        Notify(src, 'El jugador ya está contratado con ese rango', 'error')
        return
    end

    if currentJob == jobName and not CanTouchEmployee(src, identifier, currentGrade, jobName) then
        Notify(src, 'No puedes cambiar a este empleado', 'error')
        return
    end

    if SetPlayerJobAnywhere(identifier, jobName, grade) then
        local jobLabel = Jobs[jobName].label
        Log(src, 'empleados', jobName, ('Ha contratado a %s como %s'):format(GetCharacterLabel(identifier), GetGradeName(jobName, grade)), 'jefe')
        Notify(src, ('Has contratado a %s'):format(target and target.getName() or identifier), 'success')
        if target then
            Notify(target.source, ('Has sido contratado en %s'):format(jobLabel), 'success')
        end
    else
        Notify(src, 'No se pudo contratar al jugador', 'error')
    end
end)

Action('firePlayer', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName or not Jobs[jobName] then
        Notify(src, 'El trabajo no existe', 'error')
        return
    end
    if not CanManageEmployees(src, jobName) then
        Notify(src, 'No tienes permisos para despedir en este trabajo', 'error')
        return
    end

    local identifier = tostring(data.id)

    -- Comprobar que el empleado realmente trabaja en este trabajo
    local currentJob, currentGrade = GetPlayerJobInfo(identifier)
    if currentJob ~= jobName then
        Notify(src, 'Ese jugador no trabaja en este trabajo', 'error')
        return
    end

    if not CanTouchEmployee(src, identifier, currentGrade, jobName) then
        Notify(src, 'No puedes despedir a este empleado', 'error')
        return
    end

    if SetPlayerJobAnywhere(identifier, JJ.Config.DefaultJob, 0) then
        Log(src, 'empleados', jobName, ('Ha despedido a %s'):format(GetCharacterLabel(identifier)), 'jefe')
        Notify(src, 'Empleado despedido correctamente', 'success')
        local target = JJ.GetPlayerByIdentifier(identifier)
        if target then
            Notify(target.source, 'Has sido despedido de tu trabajo', 'error')
        end
    else
        Notify(src, 'No se pudo despedir al empleado', 'error')
    end
end)

Action('promotePlayer', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id or data.gradeId == nil then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName or not Jobs[jobName] then
        Notify(src, 'El trabajo no existe', 'error')
        return
    end
    if not CanManageEmployees(src, jobName) then
        Notify(src, 'No tienes permisos para cambiar rangos en este trabajo', 'error')
        return
    end

    local grade = tonumber(data.gradeId)
    if not grade then return end

    if not GradeExists(jobName, grade) then
        Notify(src, 'Ese rango no existe en este trabajo', 'error')
        return
    end

    if not IsAdmin(src) and IsBossGrade(jobName, grade) then
        Notify(src, 'Solo un administrador puede nombrar a otro jefe', 'error')
        return
    end

    local identifier = tostring(data.id)

    -- Comprobar que el empleado trabaja en este trabajo y no tiene ya ese rango
    local currentJob, currentGrade = GetPlayerJobInfo(identifier)
    if currentJob ~= jobName then
        Notify(src, 'Ese jugador no trabaja en este trabajo', 'error')
        return
    end
    if currentGrade == grade then
        Notify(src, 'El jugador ya tiene ese rango', 'error')
        return
    end
    if not CanTouchEmployee(src, identifier, currentGrade, jobName) then
        Notify(src, 'No puedes cambiar a este empleado', 'error')
        return
    end

    if SetPlayerJobAnywhere(identifier, jobName, grade) then
        Log(src, 'empleados', jobName, ('Ha cambiado el rango de %s de %s a %s'):format(GetCharacterLabel(identifier), GetGradeName(jobName, currentGrade), GetGradeName(jobName, grade)), 'jefe')
        Notify(src, 'Rango del empleado actualizado', 'success')
        local target = JJ.GetPlayerByIdentifier(identifier)
        if target then
            Notify(target.source, ('Tu rango en %s ha cambiado'):format(Jobs[jobName].label), 'info')
        end
    else
        Notify(src, 'No se pudo cambiar el rango del empleado', 'error')
    end
end)

-- =============================================================
-- Puntos
-- =============================================================

Action('createPoint', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.typePoint then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local uniqueIdentifier = nil
    if data.typePoint == 'Inventario' then
        uniqueIdentifier = ('%s_stash_%s'):format(jobName, lib.string.random('......'):lower())
    end

    local radius = math.max(1.0, tonumber(data.radius) or 25.0)
    local id = MySQL.insert.await('INSERT INTO jobscreator_points (job, x, y, z, heading, typePoint, unique_identifier, radius) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        jobName,
        tonumber(data.x) or 0.0,
        tonumber(data.y) or 0.0,
        tonumber(data.z) or 0.0,
        tonumber(data.heading) or 0.0,
        tostring(data.typePoint),
        uniqueIdentifier,
        radius,
    })
    if not id then return end

    if uniqueIdentifier then
        RegisterPointStash(uniqueIdentifier, jobName)
    end

    local point = {
        id = id,
        job = jobName,
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        heading = tonumber(data.heading) or 0.0,
        typePoint = data.typePoint,
        unique_identifier = uniqueIdentifier,
        radius = radius,
    }
    if point.typePoint == 'Garaje Personal' then
        RegisterPointGarage(point, jobName)
    end

    TriggerClientEvent('jj_creatorjobs:client:syncAddPoint', -1, point, jobName)

    Log(src, 'config', jobName, ('Ha creado un punto de %s'):format(point.typePoint))
end)

Action('updatePoint', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    local previous = MySQL.scalar.await('SELECT typePoint FROM jobscreator_points WHERE id = ? AND job = ?', { id, jobName })
    if not previous then return end

    local point = {
        id = id,
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        heading = tonumber(data.heading) or 0.0,
        typePoint = tostring(data.typePoint),
    }

    -- Un inventario conserva su identificador; si un punto pasa a serlo, necesita uno nuevo
    local uniqueIdentifier = point.typePoint == 'Inventario' and previous ~= 'Inventario'
        and ('%s_stash_%s'):format(jobName, lib.string.random('......'):lower()) or nil

    MySQL.update.await('UPDATE jobscreator_points SET x = ?, y = ?, z = ?, heading = ?, typePoint = ?, radius = ?, unique_identifier = COALESCE(?, unique_identifier) WHERE id = ? AND job = ?', {
        point.x, point.y, point.z, point.heading, point.typePoint,
        math.max(1.0, tonumber(data.radius) or 25.0),
        uniqueIdentifier,
        id,
        jobName,
    })

    if uniqueIdentifier then
        RegisterPointStash(uniqueIdentifier, jobName)
    end

    if previous == 'Garaje Personal' and point.typePoint ~= 'Garaje Personal' then
        RemovePointGarage(id)
    elseif point.typePoint == 'Garaje Personal' then
        RegisterPointGarage(point, jobName)
    end

    TriggerClientEvent('jj_creatorjobs:client:syncUpdatePoint', -1, id, data, jobName)

    Log(src, 'config', jobName, ('Ha editado un punto de %s'):format(point.typePoint))
end)

Action('deletePoint', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    local point = MySQL.single.await('SELECT typePoint FROM jobscreator_points WHERE id = ? AND job = ?', { id, jobName })
    if not point then return end

    if point.typePoint == 'Garaje Personal' then
        RemovePointGarage(id)
    end

    MySQL.query.await('DELETE FROM jobscreator_points WHERE id = ?', { id })
    TriggerClientEvent('jj_creatorjobs:client:syncDeletePoint', -1, id, jobName, point.typePoint)

    Log(src, 'config', jobName, ('Ha borrado un punto de %s'):format(point.typePoint))
end)

-- =============================================================
-- Blips
-- =============================================================

Action('createBlip', function(src, data)
    if type(data) ~= 'table' or not data.job then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = MySQL.insert.await('INSERT INTO jobscreator_blips (job, x, y, z, label, blipsprite, blipcolor) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        jobName,
        tonumber(data.x) or 0.0,
        tonumber(data.y) or 0.0,
        tonumber(data.z) or 0.0,
        tostring(data.labelBlip or jobName),
        tonumber(data.valueBlip) or 1,
        tonumber(data.colorBlip) or 1,
    })
    if not id then return end

    local blip = {
        id = id,
        job = jobName,
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        label = tostring(data.labelBlip or jobName),
        blipsprite = tonumber(data.valueBlip) or 1,
        blipcolor = tonumber(data.colorBlip) or 1,
        open = Jobs[jobName] and Jobs[jobName].open or false,
    }
    TriggerClientEvent('jj_creatorjobs:client:syncAddBlip', -1, blip, jobName)

    Log(src, 'config', jobName, ('Ha creado el blip %s'):format(blip.label))
end)

Action('updateBlip', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    MySQL.update.await('UPDATE jobscreator_blips SET x = ?, y = ?, z = ?, label = ?, blipsprite = ?, blipcolor = ? WHERE id = ? AND job = ?', {
        tonumber(data.x) or 0.0,
        tonumber(data.y) or 0.0,
        tonumber(data.z) or 0.0,
        tostring(data.labelBlip or jobName),
        tonumber(data.valueBlip) or 1,
        tonumber(data.colorBlip) or 1,
        id,
        jobName,
    })

    TriggerClientEvent('jj_creatorjobs:client:syncDeleteBlip', -1, id)

    local blip = {
        id = id,
        job = jobName,
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        label = tostring(data.labelBlip or jobName),
        blipsprite = tonumber(data.valueBlip) or 1,
        blipcolor = tonumber(data.colorBlip) or 1,
        open = Jobs[jobName] and Jobs[jobName].open or false,
    }
    TriggerClientEvent('jj_creatorjobs:client:syncAddBlip', -1, blip, jobName)

    Log(src, 'config', jobName, ('Ha editado el blip %s'):format(blip.label))
end)

Action('deleteBlip', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    MySQL.query.await('DELETE FROM jobscreator_blips WHERE id = ? AND job = ?', { id, jobName })
    TriggerClientEvent('jj_creatorjobs:client:syncDeleteBlip', -1, id)

    Log(src, 'config', jobName, 'Ha borrado un blip')
end)

-- =============================================================
-- Mercado
-- =============================================================

Action('createItemMarket', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.name then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local itemName = tostring(data.name):lower():gsub('%s+', '')
    if not exports.ox_inventory:Items(itemName) then
        Notify(src, ('El item "%s" no existe en ox_inventory'):format(itemName), 'error')
        return
    end

    local exists = MySQL.single.await('SELECT id FROM jobscreator_market WHERE job = ? AND name = ?', { jobName, itemName })
    if exists then
        Notify(src, 'Ese item ya está en el mercado', 'error')
        return
    end

    MySQL.insert.await('INSERT INTO jobscreator_market (job, name, price) VALUES (?, ?, ?)', {
        jobName, itemName, math.max(0, math.floor(tonumber(data.price) or 0))
    })

    Notify(src, 'Item añadido al mercado', 'success')

    Log(src, 'config', jobName, ('Ha añadido %s al mercado'):format(itemName))
end)

Action('updateItemMarket', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    MySQL.update.await('UPDATE jobscreator_market SET price = ? WHERE id = ? AND job = ?', {
        math.max(0, math.floor(tonumber(data.price) or 0)), tonumber(data.id), jobName
    })

    Log(src, 'config', jobName, 'Ha cambiado un precio del mercado')
end)

Action('deleteItemMarket', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    MySQL.query.await('DELETE FROM jobscreator_market WHERE id = ? AND job = ?', { tonumber(data.id), jobName })

    Log(src, 'config', jobName, 'Ha quitado un producto del mercado')
end)

-- =============================================================
-- Vehículos del garaje
-- =============================================================

Action('insertVehicle', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.name then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local model = tostring(data.name):lower():gsub('%s+', '')
    if not model:match('^[%w_]+$') then
        Notify(src, ('El vehículo "%s" no es válido'):format(model), 'error')
        return
    end

    local plate = lib.string.random('SPB.....'):upper()
    MySQL.insert.await('INSERT INTO jobscreator_vehicles (job, name, livery, plate) VALUES (?, ?, ?, ?)', {
        jobName, model, tonumber(data.livery) or 0, plate
    })

    Notify(src, 'Vehículo añadido al garaje', 'success')

    Log(src, 'config', jobName, ('Ha añadido el vehículo %s'):format(model))
end)

Action('deleteVehicle', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    MySQL.query.await('DELETE FROM jobscreator_vehicles WHERE id = ? AND job = ?', { tonumber(data.id), jobName })

    Log(src, 'config', jobName, 'Ha quitado un vehículo')
end)

-- =============================================================
-- Permisos del menú F6
-- =============================================================

Action('insertOption', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.type then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local permType = tostring(data.type)
    local exists = MySQL.single.await('SELECT id FROM jobscreator_perms WHERE job = ? AND typePermission = ?', { jobName, permType })
    if exists then
        Notify(src, 'Ese permiso ya existe en este trabajo', 'error')
        return
    end

    local id = MySQL.insert.await('INSERT INTO jobscreator_perms (job, typePermission) VALUES (?, ?)', { jobName, permType })
    if not id then return end

    TriggerClientEvent('jj_creatorjobs:client:syncAddPerm', -1, { id = id, typePermission = permType }, jobName)

    Log(src, 'config', jobName, ('Ha añadido %s al menú F6'):format(permType))
end)

Action('deletePerm', function(src, data)
    if type(data) ~= 'table' or not data.jobName or not data.id then return end

    local jobName = ResolveJobName(data.jobName)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    MySQL.query.await('DELETE FROM jobscreator_perms WHERE id = ? AND job = ?', { id, jobName })
    TriggerClientEvent('jj_creatorjobs:client:syncDeletePerm', -1, id, jobName)

    Log(src, 'config', jobName, 'Ha quitado una opción del menú F6')
end)

-- =============================================================
-- Teleports de trabajo
-- =============================================================

Action('createTeleport', function(src, data)
    if type(data) ~= 'table' or not data.job then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local teleport = {
        job = jobName,
        label = tostring(data.label or 'Teleport'),
        entrance_x = tonumber(data.entrance_x) or 0.0,
        entrance_y = tonumber(data.entrance_y) or 0.0,
        entrance_z = tonumber(data.entrance_z) or 0.0,
        entrance_heading = tonumber(data.entrance_heading) or 0.0,
        exit_x = tonumber(data.exit_x) or 0.0,
        exit_y = tonumber(data.exit_y) or 0.0,
        exit_z = tonumber(data.exit_z) or 0.0,
        exit_heading = tonumber(data.exit_heading) or 0.0,
        job_only = ToDbBool(data.job_only),
        on_duty_only = ToDbBool(data.on_duty_only),
        allow_vehicle = ToDbBool(data.allow_vehicle),
    }

    local id = MySQL.insert.await([[INSERT INTO jobscreator_teleports
        (job, label, entrance_x, entrance_y, entrance_z, entrance_heading, exit_x, exit_y, exit_z, exit_heading, job_only, on_duty_only, allow_vehicle)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        teleport.job, teleport.label,
        teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading,
        teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading,
        teleport.job_only, teleport.on_duty_only, teleport.allow_vehicle,
    })
    if not id then return end

    teleport.id = id
    TriggerClientEvent('jj_creatorjobs:client:syncAddTeleport', -1, teleport, jobName)

    Log(src, 'config', jobName, ('Ha creado el teleport %s'):format(teleport.label))
end)

Action('updateTeleport', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    local teleport = {
        id = id,
        job = jobName,
        label = tostring(data.label or 'Teleport'),
        entrance_x = tonumber(data.entrance_x) or 0.0,
        entrance_y = tonumber(data.entrance_y) or 0.0,
        entrance_z = tonumber(data.entrance_z) or 0.0,
        entrance_heading = tonumber(data.entrance_heading) or 0.0,
        exit_x = tonumber(data.exit_x) or 0.0,
        exit_y = tonumber(data.exit_y) or 0.0,
        exit_z = tonumber(data.exit_z) or 0.0,
        exit_heading = tonumber(data.exit_heading) or 0.0,
        job_only = ToDbBool(data.job_only),
        on_duty_only = ToDbBool(data.on_duty_only),
        allow_vehicle = ToDbBool(data.allow_vehicle),
    }

    MySQL.update.await([[UPDATE jobscreator_teleports SET
        label = ?, entrance_x = ?, entrance_y = ?, entrance_z = ?, entrance_heading = ?,
        exit_x = ?, exit_y = ?, exit_z = ?, exit_heading = ?,
        job_only = ?, on_duty_only = ?, allow_vehicle = ?
        WHERE id = ? AND job = ?]], {
        teleport.label,
        teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading,
        teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading,
        teleport.job_only, teleport.on_duty_only, teleport.allow_vehicle,
        id, jobName,
    })

    TriggerClientEvent('jj_creatorjobs:client:syncUpdateTeleport', -1, id, teleport, jobName)

    Log(src, 'config', jobName, ('Ha editado el teleport %s'):format(teleport.label))
end)

Action('deleteTeleport', function(src, data)
    if type(data) ~= 'table' or not data.job or not data.id then return end

    local jobName = ResolveJobName(data.job)
    if not jobName then return end
    if not IsAdmin(src) then return end

    local id = tonumber(data.id)
    if not id then return end

    MySQL.query.await('DELETE FROM jobscreator_teleports WHERE id = ? AND job = ?', { id, jobName })
    TriggerClientEvent('jj_creatorjobs:client:syncDeleteTeleport', -1, id, jobName)

    Log(src, 'config', jobName, 'Ha borrado un teleport')
end)

-- =============================================================
-- Teleports globales
-- =============================================================

Action('createGlobalTeleport', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' then return end

    local teleport = {
        label = tostring(data.label or 'Teleport'),
        entrance_x = tonumber(data.entrance_x) or 0.0,
        entrance_y = tonumber(data.entrance_y) or 0.0,
        entrance_z = tonumber(data.entrance_z) or 0.0,
        entrance_heading = tonumber(data.entrance_heading) or 0.0,
        exit_x = tonumber(data.exit_x) or 0.0,
        exit_y = tonumber(data.exit_y) or 0.0,
        exit_z = tonumber(data.exit_z) or 0.0,
        exit_heading = tonumber(data.exit_heading) or 0.0,
        password = data.password and tostring(data.password) or nil,
        bucket = tonumber(data.bucket) or 0,
    }

    local id = MySQL.insert.await([[INSERT INTO jobscreator_global_teleports
        (label, entrance_x, entrance_y, entrance_z, entrance_heading, exit_x, exit_y, exit_z, exit_heading, password, bucket)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        teleport.label,
        teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading,
        teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading,
        teleport.password, teleport.bucket,
    })
    if not id then return end

    teleport.id = id
    TriggerClientEvent('jj_creatorjobs:client:syncAddGlobalTeleport', -1, teleport)

    Log(src, 'config', nil, ('Ha creado el teleport global %s'):format(teleport.label))
end)

Action('updateGlobalTeleport', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' or not data.id then return end

    local id = tonumber(data.id)
    if not id then return end

    local teleport = {
        id = id,
        label = tostring(data.label or 'Teleport'),
        entrance_x = tonumber(data.entrance_x) or 0.0,
        entrance_y = tonumber(data.entrance_y) or 0.0,
        entrance_z = tonumber(data.entrance_z) or 0.0,
        entrance_heading = tonumber(data.entrance_heading) or 0.0,
        exit_x = tonumber(data.exit_x) or 0.0,
        exit_y = tonumber(data.exit_y) or 0.0,
        exit_z = tonumber(data.exit_z) or 0.0,
        exit_heading = tonumber(data.exit_heading) or 0.0,
        password = data.password and tostring(data.password) or nil,
        bucket = tonumber(data.bucket) or 0,
    }

    MySQL.update.await([[UPDATE jobscreator_global_teleports SET
        label = ?, entrance_x = ?, entrance_y = ?, entrance_z = ?, entrance_heading = ?,
        exit_x = ?, exit_y = ?, exit_z = ?, exit_heading = ?, password = ?, bucket = ?
        WHERE id = ?]], {
        teleport.label,
        teleport.entrance_x, teleport.entrance_y, teleport.entrance_z, teleport.entrance_heading,
        teleport.exit_x, teleport.exit_y, teleport.exit_z, teleport.exit_heading,
        teleport.password, teleport.bucket,
        id,
    })

    TriggerClientEvent('jj_creatorjobs:client:syncUpdateGlobalTeleport', -1, teleport)

    Log(src, 'config', nil, ('Ha editado el teleport global %s'):format(teleport.label))
end)

Action('deleteGlobalTeleport', function(src, data)
    if not IsAdmin(src) then return end
    if type(data) ~= 'table' or not data.id then return end

    local id = tonumber(data.id)
    if not id then return end

    MySQL.query.await('DELETE FROM jobscreator_global_teleports WHERE id = ?', { id })
    TriggerClientEvent('jj_creatorjobs:client:syncDeleteGlobalTeleport', -1, id)

    Log(src, 'config', nil, 'Ha borrado un teleport global')
end)
