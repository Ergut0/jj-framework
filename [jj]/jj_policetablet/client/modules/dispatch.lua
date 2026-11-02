-- Client module for Dispatch / Radio integration in the police tablet

RegisterNUICallback("dispatch_fetchRadioData", function(data, cb)
    local result = exports["jj_policedispatch"]:fetchRadioData()
    cb(result)
end)

RegisterNUICallback("dispatch_fetchMembers", function(data, cb)
    local result = exports["jj_policedispatch"]:fetchMembers()
    cb(result)
end)

RegisterNUICallback("dispatch_fetchAgentData", function(data, cb)
    local result = exports["jj_policedispatch"]:fetchAgentData()
    cb(result)
end)

RegisterNUICallback("dispatch_leaveChannel", function(data, cb)
    local result = exports["jj_policedispatch"]:leaveChannel(data)
    cb(result)
end)

RegisterNUICallback("dispatch_joinChannel", function(data, cb)
    local result = exports["jj_policedispatch"]:joinChannel(data)
    cb(result)
end)

RegisterNUICallback("dispatch_moveMember", function(data, cb)
    local result = exports["jj_policedispatch"]:moveMember(data)
    cb(result)
end)

RegisterNUICallback("dispatch_directTalkDown", function(data, cb)
    local result = exports["jj_policedispatch"]:directTalkDown(data)
    cb(result or 'ok')
end)

RegisterNUICallback("dispatch_directTalkUp", function(data, cb)
    local result = exports["jj_policedispatch"]:directTalkUp(data)
    cb(result or 'ok')
end)

RegisterNUICallback("dispatch_setStatus", function(data, cb)
    local result = exports["jj_policedispatch"]:setStatus(data)
    cb(result)
end)

RegisterNUICallback("dispatch_setMuted", function(data, cb)
    local result = exports["jj_policedispatch"]:setMuted(data)
    cb(result)
end)

RegisterNUICallback("dispatch_globalTalkDown", function(data, cb)
    local result = exports["jj_policedispatch"]:globalTalkDown(data)
    cb(result or 'ok')
end)

RegisterNUICallback("dispatch_globalTalkUp", function(data, cb)
    local result = exports["jj_policedispatch"]:globalTalkUp(data)
    cb(result or 'ok')
end)

-- Receive state syncs from jj_policedispatch and forward them directly to tablet NUI
RegisterNetEvent("jj_policetablet:client:sendNuiMessage", function(payload)
    SendNUIMessage(payload)
end)
