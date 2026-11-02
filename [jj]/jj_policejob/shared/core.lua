JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

if IsDuplicityVersion() then return end

function Notify(description, notifyType, duration)
    lib.notify({ description = description, type = notifyType or 'inform', duration = duration })
end

local function normalizeJob(job)
    job = job or {}

    return {
        name = job.name,
        label = job.label,
        onduty = job.onDuty == true,
        isboss = job.isBoss == true,
        grade = { level = job.grade or 0, name = job.gradeLabel or '', isboss = job.isBoss == true },
    }
end

-- Antes de cargar el personaje devuelve datos vacíos, para que se pueda consultar en cualquier momento
function GetPlayerData()
    local data = JJ.GetPlayerData()
    if not data then
        return { job = normalizeJob(), metadata = {}, charinfo = {}, accounts = {} }
    end

    local charinfo = data.charinfo or {}
    local first, last = (data.name or ''):match('^(%S+)%s*(.*)$')

    return {
        citizenid = data.identifier,
        source = data.source,
        name = data.name,
        job = normalizeJob(data.job),
        metadata = data.metadata or {},
        accounts = data.accounts or {},
        charinfo = {
            firstname = charinfo.firstname or first or '',
            lastname = charinfo.lastname or last or '',
            gender = charinfo.gender,
            birthdate = charinfo.birthdate,
            nationality = charinfo.nationality,
        },
    }
end

-- Personaje dentro de la partida
function IsLoggedIn()
    return LocalPlayer.state['isLoggedIn'] == true or JJ.IsSpawned()
end

function IsOnDuty(...)
    local job = GetPlayerData().job
    if not job.onduty then return false end

    for _, name in ipairs({ ... }) do
        if job.name == name then return true end
    end

    return false
end

function GetPlate(vehicle)
    return (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s*(.-)%s*$', '%1')
end

local loadedHandlers, jobHandlers, dutyHandlers = {}, {}, {}
local lastJob = {}

function OnPlayerLoaded(handler) loadedHandlers[#loadedHandlers + 1] = handler end
function OnJobUpdate(handler) jobHandlers[#jobHandlers + 1] = handler end
function OnDutyChange(handler) dutyHandlers[#dutyHandlers + 1] = handler end

local function runAll(handlers, ...)
    local args = { ... }
    for _, handler in ipairs(handlers) do
        CreateThread(function() handler(table.unpack(args)) end)
    end
end

AddEventHandler('jj:client:playerSpawned', function()
    local data = JJ.GetPlayerData()
    lastJob = data and data.job or {}
    runAll(loadedHandlers)
end)

AddEventHandler('jj:client:playerDataChanged', function(key, value)
    if key ~= 'job' or not value then return end

    local jobChanged = lastJob.name ~= value.name or lastJob.grade ~= value.grade
    local dutyChanged = lastJob.onDuty ~= value.onDuty
    lastJob = value

    if jobChanged then runAll(jobHandlers, normalizeJob(value)) end
    if dutyChanged then runAll(dutyHandlers, value.onDuty == true) end
end)

Inventory = exports.ox_inventory
Target = exports.ox_target

-- Acción de rol en el chat local
function RpAction(text)
    TriggerServerEvent('jj_chat:server:send', 'say', ('* %s'):format(text))
end

-- Crea un vehículo de servicio y da sus llaves al jugador
function SpawnVehicle(model, cb, coords, isNetwork, warp)
    CreateThread(function()
        local hash = joaat(model)
        lib.requestModel(hash)

        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or GetEntityHeading(cache.ped), isNetwork ~= false, false)
        SetModelAsNoLongerNeeded(hash)

        local timeout = GetGameTimer() + 3000
        while not DoesEntityExist(vehicle) and GetGameTimer() < timeout do Wait(10) end
        if not DoesEntityExist(vehicle) then return end

        SetVehicleNumberPlateText(vehicle, ('POL%05d'):format(math.random(0, 99999)))
        SetVehicleOnGroundProperly(vehicle)
        if warp then TaskWarpPedIntoVehicle(cache.ped, vehicle, -1) end
        if cb then cb(vehicle) end

        TriggerServerEvent('jj_policejob:server:vehicleSpawned', NetworkGetNetworkIdFromEntity(vehicle))
    end)
end

function DeleteServiceVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end
