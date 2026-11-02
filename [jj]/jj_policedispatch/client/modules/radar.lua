local config = lib.load('shared.main')
local radarOpen = false
local radarLocked = false
local radarThread = nil

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

local function canUseRadar()
    if not CheckPerms() then return false end
    if not cache.vehicle then return false end
    return true
end

lib.addKeybind({
    name = "radar_toggle",
    description = "Mostrar / Ocultar radar de policía",
    defaultKey = "PAGEUP",
    onPressed = function(self)
        if not canUseRadar() then return end
        radarOpen = not radarOpen
        SendNUIMessage({
            action = "radarShow",
            data = radarOpen
        })
    end
})

lib.addKeybind({
    name = "radar_lock",
    description = "Bloquear / Desbloquear radar de policía",
    defaultKey = "I",
    onPressed = function(self)
        if not canUseRadar() then return end
        radarLocked = not radarLocked
        SendNUIMessage({
            action = "setRadarLock",
            data = { locked = radarLocked }
        })
        lib.notify({
            title = "Radar",
            description = radarLocked and "Radar congelado" or "Radar activo",
            type = "info"
        })
    end
})

RegisterNUICallback("toggleRadarLock", function(data, cb)
    radarLocked = data.locked
    SendNUIMessage({
        action = "setRadarLock",
        data = { locked = radarLocked }
    })
    cb("ok")
end)

lib.onCache('vehicle', function(value)
    if value and CheckPerms() then
        if radarOpen then
            SendNUIMessage({
                action = "radarShow",
                data = true
            })
        end

        if not radarThread then
            radarThread = true
            CreateThread(function()
                while cache.vehicle do
                    Wait(500)
                    if radarOpen and not radarLocked then
                        local vehicle = cache.vehicle
                        if vehicle and DoesEntityExist(vehicle) then
                            local myCoords = GetEntityCoords(vehicle)
                            local nearbyVehicles = lib.getNearbyVehicles(myCoords, 80.0, true)

                            local frontVeh, rearVeh = nil, nil
                            local minFrontDist, minRearDist = 80.0, 80.0

                            for _, v in pairs(nearbyVehicles) do
                                local otherVeh = v.vehicle or v.id
                                if otherVeh and DoesEntityExist(otherVeh) and otherVeh ~= vehicle then
                                    local otherCoords = GetEntityCoords(otherVeh)
                                    local relPos = GetOffsetFromEntityGivenWorldCoords(vehicle, otherCoords.x,
                                    otherCoords.y, otherCoords.z)

                                    if math.abs(relPos.x) < 5.0 then
                                        local dist = math.abs(relPos.y)
                                        if relPos.y > 0 and dist < minFrontDist then
                                            minFrontDist = dist
                                            frontVeh = otherVeh
                                        elseif relPos.y < 0 and dist < minRearDist then
                                            minRearDist = dist
                                            rearVeh = otherVeh
                                        end
                                    end
                                end
                            end

                            local frontData, rearData = nil, nil

                            if frontVeh then
                                local speed = GetEntitySpeed(frontVeh) * 3.6
                                local plate = GetVehicleNumberPlateText(frontVeh) or ""
                                plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
                                local modelHash = GetEntityModel(frontVeh)
                                local displayName = GetDisplayNameFromVehicleModel(modelHash)
                                local modelName = string.lower(displayName)
                                local classLabel = GetVehicleClassLabel(modelName)
                                local isCod9 = Entity(frontVeh).state.isCod9
                                if isCod9 == nil then isCod9 = false end
                                frontData = {
                                    speed = speed,
                                    plate = plate,
                                    model = string.upper(modelName),
                                    classLabel = string.upper(classLabel),
                                    isCod9 = isCod9
                                }
                            end

                            if rearVeh then
                                local speed = GetEntitySpeed(rearVeh) * 3.6
                                local plate = GetVehicleNumberPlateText(rearVeh) or ""
                                plate = string.gsub(plate, "^%s*(.-)%s*$", "%1")
                                local modelHash = GetEntityModel(rearVeh)
                                local displayName = GetDisplayNameFromVehicleModel(modelHash)
                                local modelName = string.lower(displayName)
                                local classLabel = GetVehicleClassLabel(modelName)
                                local isCod9 = Entity(rearVeh).state.isCod9
                                if isCod9 == nil then isCod9 = false end
                                rearData = {
                                    speed = speed,
                                    plate = plate,
                                    model = string.upper(modelName),
                                    classLabel = string.upper(classLabel),
                                    isCod9 = isCod9
                                }
                            end

                            SendNUIMessage({
                                action = "updateRadarData",
                                data = {
                                    front = frontData,
                                    rear = rearData
                                }
                            })
                        end
                    end
                end
                radarThread = nil
            end)
        end
    else
        if radarOpen then
            SendNUIMessage({
                action = "radarShow",
                data = false
            })
        end
    end
end)
