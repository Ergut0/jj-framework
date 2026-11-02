local config = lib.load('shared.main')

local function CheckPerms()
    local playerData = GetPlayerData()
    if not playerData or not playerData.job then return false end
    for k, v in pairs(config.jobsAccess) do
        if v == playerData.job.name and playerData.job.onduty then
            return true
        end
    end
    return false
end

local activeSpeedZones = {}

function GetFrontVehicle(maxDistance)
    maxDistance = maxDistance or 20.0

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)
    local targetCoords = pedCoords + (forwardVector * maxDistance)

    -- Raycast más simple y efectivo
    local rayHandle = StartShapeTestCapsule(
        pedCoords.x, pedCoords.y, pedCoords.z,
        targetCoords.x, targetCoords.y, targetCoords.z,
        2.0, -- Radio del cápsula
        10,  -- Tipo de intersección: vehículos
        ped, -- Ignorar el ped
        0
    )

    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and DoesEntityExist(entityHit) and GetEntityType(entityHit) == 2 then
        return entityHit
    end

    return nil
end

local function GetLocationString()
    local coords = GetEntityCoords(cache.ped or PlayerPedId())
    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)

    if street == nil or street == "" then
        local zone = GetNameOfZone(coords.x, coords.y, coords.z)
        street = GetLabelText(zone)
    end

    return street or "Desconocida"
end

local function GetRadioCommand()
    local playerData = GetPlayerData()
    if playerData and playerData.job and playerData.job.name == "ambulance" then
        return "rems"
    end
    return "rpol"
end

RegisterNUICallback('triggerTool', function(data, cb)
    local action = data.action
    local agentName = data.agentName or "Agente"
    local agentRank = data.agentRank or "Oficial"
    local radioCmd = GetRadioCommand()

    if action == "10.3" or action == "10.6" or action == "254-V" or action == "VEH 488" or action == "VEH 487" then
        local location = GetLocationString()
        local veh = GetFrontVehicle(60.0)
        if not veh then
            lib.notify({
                title = "CODIGOS",
                description = "No hay ningún vehículo delante del jugador.",
                type = "error"
            })
            cb('ok')
            return
        end
        local modelName = "[Vehículo desconocido]"
        local plate = "[Matrícula desconocida]"

        if veh then
            local modelHash = GetEntityModel(veh)
            local displayName = GetDisplayNameFromVehicleModel(modelHash)
            local label = GetLabelText(displayName)

            if label and label ~= "NULL" then
                modelName = label
            else
                modelName = string.lower(displayName)
                modelName = modelName:gsub("^%l", string.upper)
            end

            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate then
                plate = string.gsub(vehPlate, "^%s*(.-)%s*$", "%1")
            end
        end

        local cmd = ""
        if action == "10.3" then
            cmd = string.format("%s El vehículo implicado en el aviso de %s es un %s [%s]", radioCmd, location, modelName, plate)
        elseif action == "10.6" then
            cmd = string.format("%s realiza un 10.6 a un %s [%s] en %s", radioCmd, modelName, plate, location)
        elseif action == "254-V" then
            cmd = string.format("%s inicia un 254-V a un %s [%s] en %s", radioCmd, modelName, plate, location)
        elseif action == "VEH 488" then
            cmd = string.format("%s Vehículo implicado en el 488 de %s : %s [%s]", radioCmd, location, modelName, plate)
        elseif action == "VEH 487" then
            cmd = string.format("%s Vehículo implicado en el 487 de %s : %s [%s]", radioCmd, location, modelName, plate)
        end

        ExecuteCommand(cmd)
    elseif action == "444" then
        ExecuteCommand(string.format("entorno [444] Agente implicado en tiroteo en peligro - %s", agentName))
        exports["jj_policedispatch"]:changeColour(1)
    elseif action == "QRR" then
        ExecuteCommand(string.format("entorno [QRR] Agente en peligro - %s", agentName))
        exports["jj_policedispatch"]:changeColour(1)
    elseif action == "10.20" then
        ExecuteCommand(string.format("entorno [10.20] %s %s", agentRank, agentName))
    elseif action == "10.8" then
        ExecuteCommand(string.format("%s A la espera de asignación.", radioCmd))
    elseif action == "10.10" then
        ExecuteCommand(string.format("%s Realiza su 10.10. Buen servicio!", radioCmd))
    elseif action == "COD 7" then
        ExecuteCommand(string.format("%s Realiza una parada técnica.", radioCmd))
    elseif action == "COD 2" then
        ExecuteCommand(string.format("%s Inicia patrullaje ordinario.", radioCmd))
    elseif action == "QAB" then
        ExecuteCommand(string.format("%s Todos los agentes del Táctico han quedado abatidos, pueden pasar a realizar el traslado a inmediaciones del Hospital.", radioCmd))
    elseif action == "stop_traffic" then
        local pos = GetEntityCoords(cache.ped or PlayerPedId())
        TriggerServerEvent('jj_policedispatch:server:StopTraffic', pos)
        lib.notify({ title = "Tráfico parado", description = "Se ha creado un corte de tráfico de 90m.", type = "success" })
    elseif action == "resume_traffic" then
        local pos = GetEntityCoords(cache.ped or PlayerPedId())
        TriggerServerEvent('jj_policedispatch:server:ResumeTraffic', pos)
        lib.notify({
            title = "Tráfico reanudado",
            description = "Eliminando cortes de tráfico cercanos...",
            type = "success"
        })
    end

    cb('ok')
end)

RegisterNetEvent('jj_policedispatch:client:AddSpeedZone', function(id, coords)
    local szId = AddRoadNodeSpeedZone(coords.x, coords.y, coords.z, 90.0, 0.0, false)

    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, 90.0)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 128)

    activeSpeedZones[id] = { id = szId, coords = coords, blip = blip }
end)

RegisterNetEvent('jj_policedispatch:client:RemoveSpeedZone', function(id)
    if activeSpeedZones[id] then
        RemoveRoadNodeSpeedZone(activeSpeedZones[id].id)
        if activeSpeedZones[id].blip then
            RemoveBlip(activeSpeedZones[id].blip)
        end
        activeSpeedZones[id] = nil
    end
end)

RegisterNetEvent('jj_policedispatch:client:RemoveSpeedZoneRadius', function(coords, radius)
    for id, zone in pairs(activeSpeedZones) do
        local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(zone.coords.x, zone.coords.y, zone.coords.z))
        if dist <= radius then
            RemoveRoadNodeSpeedZone(zone.id)
            if zone.blip then
                RemoveBlip(zone.blip)
            end
            activeSpeedZones[id] = nil
        end
    end
end)


lib.addKeybind({
    name = 'tools:envia_10_20',
    description = 'Enviar 10.20 (Ubicación)',
    defaultKey = '',
    onPressed = function(self)
        if CheckPerms() then
            local PlayerData = GetPlayerData()
            local agentName = ("%s %s"):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
            local agentRank = PlayerData.job.grade.name

            ExecuteCommand(string.format("entorno [10.20] %s %s", agentRank, agentName))
        end
    end
})
