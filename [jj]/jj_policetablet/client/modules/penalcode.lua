local utils = require "client.utils.functions"

RegisterNuiCallback("getPenalCodes", function(data, cb)
    local incidents = lib.callback.await("jj_policetablet:callback:getPenalCodes", false)
    cb(incidents)
end)

RegisterNuiCallback("createPenalCode", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createPenalCode", false, data)
    cb(result)
end)

RegisterNuiCallback("updatePenalCode", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:updatePenalCode", false, data)
    cb(result)
end)

RegisterNuiCallback("deletePenalCode", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deletePenalCode", false, data.id)
    cb(result)
end)

RegisterNuiCallback("createChapter", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createChapter", false, data)
    cb(result)
end)

RegisterNuiCallback("updateChapter", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:updateChapter", false, data)
    cb(result)
end)

RegisterNuiCallback("deleteChapter", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deleteChapter", false, data)
    cb(result)
end)