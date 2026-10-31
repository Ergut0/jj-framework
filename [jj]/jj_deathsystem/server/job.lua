local MEDIC_JOB = 'ambulance'

local function getBoss(src)
    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    if job and job.name == MEDIC_JOB and job.isBoss then
        return player, job
    end
end

lib.callback.register('jj_deathsystem:callback:getEmployees', function(src)
    if not getBoss(src) then return {} end

    local rows = MySQL.query.await('SELECT identifier, name, job_grade FROM jj_players WHERE job = ?', { MEDIC_JOB })
    local employees = {}

    for _, row in ipairs(rows or {}) do
        local job = JJ.Utils.BuildJob(MEDIC_JOB, row.job_grade)
        employees[#employees + 1] = {
            identifier = row.identifier,
            name = row.name,
            grade = row.job_grade,
            gradeLabel = job and job.gradeLabel or tostring(row.job_grade)
        }
    end

    return employees
end)

-- Cambia el trabajo del empleado, esté conectado o no. Solo afecta a grados inferiores al del jefe.
local function changeEmployee(src, identifier, jobName, grade)
    local _, bossJob = getBoss(src)
    if not bossJob or type(identifier) ~= 'string' or not JJ.Utils.BuildJob(jobName, grade) then
        return false
    end
    if jobName == MEDIC_JOB and tonumber(grade) >= bossJob.grade then
        Notify(src, 'No puedes asignar un rango igual o superior al tuyo', 'error')
        return false
    end

    local target = JJ.GetPlayerByIdentifier(identifier)
    if target then
        local job = target.getJob()
        if job.name ~= MEDIC_JOB or job.grade >= bossJob.grade then
            Notify(src, 'No puedes modificar a este empleado', 'error')
            return false
        end
        return target.setJob(jobName, grade)
    end

    local affected = MySQL.update.await(
        'UPDATE jj_players SET job = ?, job_grade = ? WHERE identifier = ? AND job = ? AND job_grade < ?',
        { jobName, tonumber(grade), identifier, MEDIC_JOB, bossJob.grade }
    )
    return affected > 0
end

RegisterNetEvent('jj_deathsystem:server:setEmployeeGrade', function(identifier, grade)
    local src = source
    if changeEmployee(src, identifier, MEDIC_JOB, grade) then
        Notify(src, 'Rango actualizado', 'success')
    end
end)

RegisterNetEvent('jj_deathsystem:server:firePlayer', function(identifier)
    local src = source
    if changeEmployee(src, identifier, JJ.Config.DefaultJob, 0) then
        Notify(src, 'Empleado despedido', 'success')
    end
end)

RegisterNetEvent('jj_deathsystem:server:hirePlayer', function(targetId)
    local src = source
    if not getBoss(src) then return end

    local target = JJ.GetPlayer(tonumber(targetId))
    if not target then
        Notify(src, 'Jugador no encontrado', 'error')
        return
    end

    if target.getJob().name == MEDIC_JOB then
        Notify(src, 'Ya trabaja en el hospital', 'error')
        return
    end

    target.setJob(MEDIC_JOB, 0)
    Notify(src, 'Empleado contratado', 'success')
    Notify(target.source, 'Has sido contratado en el hospital', 'success')
end)

RegisterNetEvent('jj_deathsystem:server:toggleDuty', function()
    local player = JJ.GetPlayer(source)
    if player and player.getJob().name == MEDIC_JOB then
        player.setDuty(not player.getJob().onDuty)
    end
end)

RegisterNetEvent('jj_deathsystem:createPersonalStash', function()
    local player = JJ.GetPlayer(source)
    if player and player.getJob().name == MEDIC_JOB then
        exports.ox_inventory:RegisterStash(player.identifier .. '-personal', 'Taquilla personal', 70, 40000, player.identifier, { [MEDIC_JOB] = 0 })
    end
end)

-- Solo se registran el almacén y los armarios definidos en Config.Points.inventory
CreateThread(function()
    for _, point in ipairs(Config.Points.inventory or {}) do
        if point.type == 'shop' then
            exports.ox_inventory:RegisterShop(point.name, {
                name = point.name,
                inventory = Config.Shop,
                groups = { [MEDIC_JOB] = 0 },
            })
        elseif point.type == 'inventory' then
            exports.ox_inventory:RegisterStash(point.name, point.name, 100, 200000, false, { [MEDIC_JOB] = 0 })
        end
    end
end)
