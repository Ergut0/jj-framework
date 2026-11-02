local utils = require("client.utils.functions")

RegisterNuiCallback("fetchReports", function(data, cb)
    local reports = lib.callback.await("jj_policetablet:callback:getReports", false)
    cb(reports)
end)

RegisterNuiCallback("createReport", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createReport", false, data)
    cb(result)
end)

RegisterNuiCallback("updateReport", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:updateReport", false, data)
    cb(result)
end)

RegisterNuiCallback("fetchReportById", function(data, cb)
    local report = lib.callback.await("jj_policetablet:callback:getReportById", false, data.id)
    cb(report)
end)

RegisterNuiCallback("deleteReport", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deleteReport", false, data.id)
    cb(result)
end)

RegisterNuiCallback("searchReports", function(data, cb)
    local reports = lib.callback.await("jj_policetablet:callback:getReportsBySearchTerm", false, data.query, data.date)
    cb(reports)
end)

RegisterNuiCallback("takeEvidencePhoto", function(data, cb)
    local image = utils.cameraLoop()
    if image and image.data and image.data.url then
        cb(image.data.url)
    else
        cb(false)
    end
end)
