RegisterNuiCallback("fetchRichTextTemplates", function(data, cb)
    local templates = lib.callback.await("jj_policetablet:callback:getTemplates", false,
        data and data.scope or "global")
    cb(templates or {})
end)

RegisterNuiCallback("createRichTextTemplate", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:createTemplate", false, data)
    cb(result or { success = false, message = "unknown_error" })
end)

RegisterNuiCallback("deleteRichTextTemplate", function(data, cb)
    local result = lib.callback.await("jj_policetablet:callback:deleteTemplate", false, data and data.id)
    cb(result or { success = false, message = "unknown_error" })
end)
