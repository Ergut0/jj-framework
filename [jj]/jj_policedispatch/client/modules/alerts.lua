local dispatchHidden = false

local alertFilters = {
    disparos = true,
    venta_drogas = true
}

local function loadAlertFilters()
    local kvp = GetResourceKvpString("jj_policedispatch:alert_filters")
    if kvp then
        local success, decoded = pcall(json.decode, kvp)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                alertFilters[k] = v
            end
        end
    end
end

local function saveAlertFilters()
    SetResourceKvp("jj_policedispatch:alert_filters", json.encode(alertFilters))
end

loadAlertFilters()

local function determineAlertType(customType)
    if customType and type(customType) == "string" and customType ~= "" then
        return customType
    end
    return "general"
end

-- Comprueba si el aviso va dirigido a mi faccion (independiente de los filtros)
local function isAlertForMe(alert)
    if not alert then return false end
    local PlayerData = GetPlayerData()
    local myFaction = PlayerData and PlayerData.job and PlayerData.job.name
    local target = alert.targetFaction or "police"
    if target ~= "all" and target ~= myFaction then
        return false
    end
    return true
end

-- Solo para avisos NUEVOS: si el filtro de ese tipo esta desactivado no salta ni suena.
-- Los filtros no se aplican al listado, para no borrar los avisos ya recibidos.
local function isAlertEnabled(alert)
    if not isAlertForMe(alert) then return false end

    local aType = alert.type or "general"
    if alertFilters[aType] == false then
        return false
    end
    return true
end

local function formatAlert(aviso)
    local formatted = {}
    for k, v in pairs(aviso) do
        formatted[k] = v
    end

    formatted.type = aviso.type or "general"

    local coords = formatted.distance
    if coords then
        local pos = vector3(coords.x, coords.y, coords.z)
        local distance = #(GetEntityCoords(cache.ped) - pos)
        formatted.distance = math.floor(distance)
        if not formatted.zone or formatted.zone == "" then
            local streetHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
            local streetName = GetStreetNameFromHashKey(streetHash)
            formatted.zone = streetName or "Ubicación desconocida"
        end
    else
        formatted.distance = 0
    end
    return formatted
end

local function formatAlerts(alerts)
    local alertsFormat = {}
    for _, aviso in pairs(alerts) do
        if isAlertForMe(aviso) then
            table.insert(alertsFormat, formatAlert(aviso))
        end
    end
    return alertsFormat
end

CreateThread(function()
    while not IsLoggedIn() do
        Wait(100)
    end

    local PlayerData = GetPlayerData()
    if (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance") and PlayerData.job.onduty then
        local alerts = lib.callback.await("jj_policedispatch:callback:getAlerts", false)
        local alertsFormat = formatAlerts(alerts)
        SendNUIMessage({
            action = "dispatchMenuShow",
            data = alertsFormat,
        })
    end
end)

AddEventHandler('jj_policedispatch:client:uiReady', function()
    local PlayerData = GetPlayerData()
    if dispatchHidden or (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end

    local alerts = lib.callback.await("jj_policedispatch:callback:getAlerts", false)
    SendNUIMessage({
        action = "dispatchMenuShow",
        data = formatAlerts(alerts),
    })
end)

OnDutyChange(function(duty)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    if duty then
        local alerts = lib.callback.await("jj_policedispatch:callback:getAlerts", false)
        local alertsFormat = formatAlerts(alerts)
        SendNUIMessage({
            action = "dispatchMenuShow",
            data = alertsFormat,
        })
    else
        SendNUIMessage({
            action = "dispatchMenuHide",
        })
    end
end)

OnJobUpdate(function(job)
    if job.name ~= "police" and job.name ~= "ambulance" then
        SendNUIMessage({
            action = "dispatchMenuHide",
        })
        return
    end

    if job.onduty then
        local alerts = lib.callback.await("jj_policedispatch:callback:getAlerts", false)
        local alertsFormat = formatAlerts(alerts)
        SendNUIMessage({
            action = "dispatchMenuShow",
            data = alertsFormat,
        })
    end
end)

local function sendAlert(title, desc, alertType, targetFaction)
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local location = streetName or "Ubicación desconocida"
    local aType = determineAlertType(alertType)

    local alertData = {
        title = title,
        textAlert = desc,
        zone = location,
        type = aType,
        targetFaction = targetFaction or "police"
    }

    TriggerServerEvent("jj_policedispatch:server:addNewAlert", alertData)
end

exports("sendAlert", sendAlert)

local function sendAmbulanceAlert(title, desc)
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local location = streetName or "Ubicación desconocida"

    local alertData = {
        title = title or "Llamada de Auxilio",
        textAlert = desc,
        zone = location,
        type = "auxilio",
        targetFaction = "ambulance"
    }

    TriggerServerEvent("jj_policedispatch:server:addNewAlert", alertData)
end

exports("sendAmbulanceAlert", sendAmbulanceAlert)

local function sendDrugAlert(desc)
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local location = streetName or "Ubicación desconocida"

    local alertData = {
        title = "Llamada del 911",
        textAlert = desc,
        zone = location,
        type = "venta_drogas",
        targetFaction = "police"
    }

    TriggerServerEvent("jj_policedispatch:server:addNewDrugAlert", alertData)
end

exports("sendDrugAlert", sendDrugAlert)

local function sendVehicleAlert(desc, vehicle, alertType, title)
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local location = streetName or "Ubicación desconocida"
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = GetPlate(vehicle)
    local r, g, b = GetVehicleColor(vehicle)
    local aType = determineAlertType(alertType)

    local alertData = {
        title = title or "Robo de Vehículo",
        textAlert = desc,
        zone = location,
        plate = plate,
        vehModel = model,
        vehColor = {
            r = r,
            g = g,
            b = b
        },
        type = aType,
        targetFaction = "police"
    }

    TriggerServerEvent("jj_policedispatch:server:addNewAlert", alertData)
end

exports("sendVehicleAlert", sendVehicleAlert)

RegisterNetEvent('jj_policedispatch:client:alertReceived', function(alert)
    if not isAlertEnabled(alert) then return end
    local formatted = formatAlert(alert)
    SendNUIMessage({
        action = "newAlert",
        data = formatted,
    })
end)

RegisterNetEvent('jj_policedispatch:client:alertRemoved', function(alertId)
    SendNUIMessage({
        action = "deleteAlert",
        data = alertId,
    })
end)

RegisterNUICallback('getAlertFilters', function(_, cb)
    cb(alertFilters)
end)

RegisterNUICallback('changeAlertFilter', function(data, cb)
    if data and data.type then
        alertFilters[data.type] = data.enabled == true
        saveAlertFilters()
        -- No se reconstruye el listado: desactivar un filtro solo silencia los avisos
        -- nuevos de ese tipo, los que ya estaban recibidos se mantienen en el dispatch.
    end
    cb('ok')
end)

local blip = nil

RegisterNUICallback('setWaypoint', function(data, cb)
    local alert = lib.callback.await("jj_policedispatch:callback:getAlertById", false, data.id)
    if not alert then
        cb('ok')
        return
    end

    local coords = { x = alert.distance.x, y = alert.distance.y, z = alert.distance.z }
    local isPinned = data.pinned
    local alertId = data.id

    local playersToSync = {}
    if cache.vehicle then
        local nearby = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.0, true)
        for _, p in pairs(nearby) do
            playersToSync[#playersToSync + 1] = GetPlayerServerId(p.id)
        end
    end
    playersToSync[#playersToSync + 1] = GetPlayerServerId(PlayerId())

    TriggerServerEvent('jj_policedispatch:server:SyncWaypoint', coords, playersToSync, isPinned, alertId)
    cb('ok')
end)

RegisterNUICallback('syncWaypoint', function(data, cb)
    if blip then
        RemoveBlip(blip)
        blip = nil
    end
    blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipColour(blip, 1)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 1)
    cb('ok')
end)

RegisterNUICallback('resetWaypoint', function(data, cb)
    if blip then
        RemoveBlip(blip)
        blip = nil
    end
    cb('ok')
end)

RegisterNetEvent('jj_policedispatch:client:SyncWaypoint', function(coords, isPinned, alertId)
    SendNUIMessage({
        action = 'avisos:syncWayPoint',
        data = { coords = coords, pinned = isPinned, index = alertId }
    })
end)

RegisterNetEvent('jj_policedispatch:client:alertUnitAssigned', function(data)
    if data then
        SendNUIMessage({
            action = 'alertUnitAssigned',
            data = data
        })
    end
end)

RegisterNetEvent('jj_policedispatch:callback:sendAlertCommand', function(message)
    sendAlert("Llamada del 911", message)
end)

RegisterNetEvent('jj_policedispatch:callback:sendAmbulanceAlertCommand', function(message)
    sendAmbulanceAlert("Llamada de Auxilio", message)
end)

RegisterCommand('avisos', function()
    local PlayerData = GetPlayerData()
    if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end
    dispatchHidden = not dispatchHidden
    if not dispatchHidden then
        local alerts = lib.callback.await("jj_policedispatch:callback:getAlerts", false)
        local alertsFormat = formatAlerts(alerts)
        SendNUIMessage({
            action = "dispatchMenuShow",
            data = alertsFormat,
        })
    else
        SendNUIMessage({
            action = "dispatchMenuHide",
        })
    end
end, false)

exports('DeleteAlert', function(id)
    SendNUIMessage({
        action = "deleteAlert",
        data = id
    })
end)

lib.addKeybind({
    name = 'avisos:nextPage',
    description = 'Siguiente aviso en el dispatch',
    defaultKey = 'RIGHT',
    onPressed = function(self)
        local PlayerData = GetPlayerData()
        if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end
        SendNUIMessage({ action = "nextPage" })
    end
})

lib.addKeybind({
    name = 'avisos:prevPage',
    description = 'Aviso anterior en el dispatch',
    defaultKey = 'LEFT',
    onPressed = function(self)
        local PlayerData = GetPlayerData()
        if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end
        SendNUIMessage({ action = "prevPage" })
    end
})

lib.addKeybind({
    name = 'avisos:setWaypoint',
    description = 'Marcar waypoint del aviso actual',
    defaultKey = 'DELETE',
    onPressed = function(self)
        local PlayerData = GetPlayerData()
        if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end
        SendNUIMessage({ action = 'setWaypoint' })
    end
})

lib.addKeybind({
    name = 'avisos:toggleStatus',
    description = 'Alternar estado ocupado/libre en el dispatch',
    defaultKey = 'END',
    onPressed = function(self)
        local PlayerData = GetPlayerData()
        if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" or not PlayerData.job.onduty then return end
        SendNUIMessage({ action = 'toggleStatus' })
    end
})
