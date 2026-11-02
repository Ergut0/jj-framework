RegisterNuiCallback('getRanksSettings', function(data, cb)
    local ranks = lib.callback.await('jj_policetablet:callback:getRanksSettings', false)
    cb(ranks or {})
end)

RegisterNuiCallback('saveRankPermissions', function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:saveRankPermissions', false, data)
    cb(result or { success = false, message = 'unknown_error' })
end)
