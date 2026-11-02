RegisterNuiCallback("fetchHomeAnnounces", function(data, cb)
    local announces = lib.callback.await("jj_policetablet:callback:getHomeAnnounces", false)
    cb(announces)
end)

RegisterNuiCallback("createHomeAnnounce", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createHomeAnnounce", false, data)
    cb(result)
end)

RegisterNuiCallback("updateHomeAnnounce", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:updateHomeAnnounce", false, data)
    cb(result)
end)

RegisterNuiCallback("deleteHomeAnnounce", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deleteHomeAnnounce", false, data.id)
    cb(result)
end)

RegisterNuiCallback("fetchHomeWantedSubjects", function(data, cb)
    local wantedSubjects = lib.callback.await("jj_policetablet:callback:getHomeWantedSubjects", false)
    cb(wantedSubjects)
end)
