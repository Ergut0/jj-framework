RegisterNuiCallback('toggleDutyStatus', function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:toggleDutyStatus', false)
    cb(result or { success = false, message = 'unknown_error' })
end)
