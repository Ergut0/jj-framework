-- Minijuego de hackeo. La partida y la corrección están en el servidor
function Boosting.StartHack(kind)
    if Boosting.hacking then return end

    local result = Boosting.Call('hackStart', { kind = kind })
    if not result or not result.ok then
        Boosting.Notify(result and result.message, 'error')
        return
    end

    Boosting.hacking = kind
    if kind == 'lock' then TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true) end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'hack', hack = result.hack, locale = Config.Locale })
end

RegisterNUICallback('hackSubmit', function(data, cb)
    local result = Boosting.Call('hackSubmit', { token = data and data.token, answer = data and data.answer })
    cb(result or { ok = false })
end)

RegisterNUICallback('hackClose', function(_, cb)
    if Boosting.hacking == 'lock' then ClearPedTasks(cache.ped) end
    Boosting.hacking = nil
    SetNuiFocus(false, false)
    cb('ok')
end)
