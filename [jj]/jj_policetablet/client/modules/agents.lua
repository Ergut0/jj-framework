local utils = require "client.utils.functions"
local hiddenAlerts = {}

RegisterNuiCallback('fetchAgents', function(data, cb)
    local agents = lib.callback.await('jj_policetablet:callback:getAgents', false)
    cb(agents)
end)

RegisterNuiCallback('fetchAgentById', function(data, cb)
    local agentData = lib.callback.await('jj_policetablet:callback:getAgentById', false, data)
    cb(agentData)
end)

RegisterNuiCallback('fetchAgentsByFilter', function(data, cb)
    local agents = lib.callback.await('jj_policetablet:callback:getAgentsByFilter', false, data)
    cb(agents)
end)

RegisterNUICallback("updateAgent", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:updateAgent', false, data)
    cb(result)
end)

RegisterNUICallback("getAgentIncidents", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:getAgentIncidents', false, data.citizenid)
    cb(result)
end)

RegisterNUICallback("getAgentBills", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:getAgentBills', false, data)
    cb(result)
end)

RegisterNUICallback("addAgentBySourceId", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:addAgentBySourceId', false, data)
    cb(result)
end)

RegisterNUICallback("fireAgent", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:fireAgent', false, data)
    cb(result)
end)

RegisterNUICallback("resetAgentWorkHours", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:resetAgentWorkHours', false, data)
    cb(result)
end)

RegisterNUICallback("addAgentInfraction", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:addAgentInfraction', false, data)
    cb(result)
end)

RegisterNUICallback("deleteAgentInfraction", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:deleteAgentInfraction', false, data)
    cb(result)
end)

RegisterNUICallback("fetchOnDutyAgents", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:getOnDutyAgents', false)
    cb(result)
end)

RegisterNUICallback("setMapWaypoint", function(data, cb)
    local coords = data.coords
    if coords and coords.x and coords.y then
        SetNewWaypoint(coords.x, coords.y)
        Notify("GPS marcado en el mapa", "success")
    end
    cb("ok")
end)

RegisterNUICallback('deleteAlert', function(data, cb)
    local id = data.id
    exports.jj_policedispatch:DeleteAlert(id)
    table.insert(hiddenAlerts, id)
    cb("ok")
end)

RegisterNUICallback('deleteAllAlerts', function(data, cb)
    for _, id in pairs(data.ids or {}) do
        exports.jj_policedispatch:DeleteAlert(id)
        table.insert(hiddenAlerts, id)
    end
    cb("ok")
end)

RegisterNUICallback("fetchOnDutyAgentDetails", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:getOnDutyAgentDetails', false, data.source)
    cb(result)
end)

RegisterNUICallback("fetchRadioHistory", function(data, cb)
    local history = lib.callback.await('jj_policedispatch:callback:getRadioHistory', false)
    cb(history or {})
end)

RegisterNUICallback("fetchDispatchAlerts", function(data, cb)
    local alerts = lib.callback.await('jj_policedispatch:callback:getAlerts', false)
    local newAlerts = {}

    for k, v in pairs(alerts) do
        local found = false

        for _, id in pairs(hiddenAlerts) do
            if v.id == id then
                found = true
            end
        end

        if not found then
            table.insert(newAlerts, v)
        end
    end

    cb(newAlerts or {})
end)

RegisterNetEvent('jj_rpchat:addMessage', function(msg, id, command, header, colorData)
    if command == "RADIO INTERNA" or command == "RPOL" or command == "RSUR" or command == "RNORTE" or command == "REMS" then
        SendNUIMessage({
            action = "newRadioMessage",
            data = {
                id = GetGameTimer(),
                tag = command,
                header = header,
                msg = msg,
                color = colorData,
                time = nil
            }
        })
    end
end)

RegisterNUICallback("assignAlertToUnit", function(data, cb)
    if data and data.alertId then
        TriggerServerEvent('jj_policedispatch:server:assignAlertToUnit', data.alertId, data.unitName)
    end
    cb("ok")
end)

RegisterNetEvent('jj_policedispatch:client:alertReceived', function(alert)
    if alert then
        SendNUIMessage({
            action = "newDispatchAlert",
            data = alert
        })
    end
end)

RegisterNetEvent('jj_policedispatch:client:alertUnitAssigned', function(data)
    if data then
        SendNUIMessage({
            action = "alertUnitAssigned",
            data = data
        })
    end
end)

RegisterNetEvent('jj_policedispatch:updateBlips', function(activeBlips)
    local agents = {}
    local mySource = GetPlayerServerId(PlayerId())
    for _, v in pairs(activeBlips) do
        if v and v.source then
            agents[#agents + 1] = {
                source = v.source,
                badge_number = v.badge_number or "000",
                asig = v.asig or ("Agente #" .. v.source),
                coords = v.coords and { x = v.coords.x, y = v.coords.y, z = v.coords.z } or { x = 0.0, y = 0.0, z = 0.0 },
                heading = v.heading or 0.0,
                is_self = v.source == mySource,
                department = v.department or "saed"
            }
        end
    end

    SendNUIMessage({
        action = "updateOnDutyAgents",
        data = agents
    })
end)

