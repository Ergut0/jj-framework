local utils = require "client.utils.functions"

RegisterNuiCallback("fetchIncidents", function(data, cb)
    local incidents = lib.callback.await("jj_policetablet:callback:getIncidents", false)
    cb(incidents)
end)

RegisterNuiCallback("createIncident", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createIncident", false, data)
    cb(result)
end)

RegisterNuiCallback("updateIncident", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:updateIncident", false, data)
    cb(result)
end)

RegisterNuiCallback("fetchIncidentById", function(data, cb)
    local incident = lib.callback.await("jj_policetablet:callback:getIncidentById", false, data.id)
    cb(incident)
end)

RegisterNuiCallback("deleteIncident", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deleteIncident", false, data.id)
    cb(result)
end)

RegisterNuiCallback("searchIncidents", function(data, cb)
    local incidents = lib.callback.await("jj_policetablet:callback:getIncidentsBySearchTerm", false, data.query, data.date)
    cb(incidents)
end)

RegisterNuiCallback("getCitizensIncidents", function(data, cb)
    local citizens = lib.callback.await("jj_policetablet:callback:getCitizensIncidents", false, data)
    cb(citizens)
end)

RegisterNuiCallback("getVehiclesIncidents", function(data, cb)
    local vehicles = lib.callback.await("jj_policetablet:callback:getVehiclesIncidents", false, data)
    cb(vehicles)
end)

RegisterNuiCallback("searchAgents", function(data, cb)
    local agents = lib.callback.await("jj_policetablet:callback:searchAgents", false, data.searchTerm)
    cb(agents)
end)

RegisterNuiCallback("getFrequencyAgents", function(data, cb)
    local agents = lib.callback.await("jj_policetablet:callback:getFrequencyAgents", false)
    cb(agents)
end)

local evidenceOpen = false

RegisterNetEvent('jj_policetablet:closedInventory', function()
    if evidenceOpen then
        evidenceOpen = false
        utils.openTablet()
    end
end)

RegisterNuiCallback("openEvidenceStash", function(data, cb)
    evidenceOpen = true
    utils.closeTablet()
    local result = lib.callback.await("jj_policetablet:callback:openEvidenceStash", false, data.incidentId)
    cb(result or false)
end)
