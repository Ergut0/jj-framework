-- Puente NUI <-> servidor. Sin bucles: todo es dirigido por eventos (0.00 ms en idle).

UI = { isOpen = false, opening = false }

-- Acciones que la NUI puede solicitar. El servidor revalida todo (incluido admin).
local ACTIONS = {
    'getState', 'listTracks', 'getTrack', 'getLeaderboard', 'getPilotRanking', 'getCrewRanking', 'getStats', 'getHistory',
    'getLastResult', 'getRaceResults', 'listRaces', 'createRace', 'joinRace', 'leaveRace', 'setReady', 'startRace', 'kickPlayer',
    'invitePlayer', 'listCrews', 'challengeCrew', 'respondChallenge', 'cancelChallenge',
    'adminListTracks', 'adminGetTrack', 'adminSaveTrack', 'adminDuplicateTrack', 'adminToggleTrack', 'adminDeleteTrack',
    'adminExportTrack', 'adminImportTrack', 'adminTestTrack', 'adminLeaderboard', 'adminListRaces', 'adminCancelRace',
    'adminKickPlayer', 'adminListEvents', 'adminSaveEvent', 'adminCancelEvent', 'adminListResults', 'adminVoidResult',
    'adminApproveResult', 'adminVoidRecord', 'adminGetSettings', 'adminSaveSettings', 'adminLogs',
}

function Notify(text, kind, ms)
    JJ.Notify(text, kind or 'primary', ms or 5000)
end

--- Abre el panel. `view` = 'player' | 'admin'; `extra` se reenvia a la NUI (pestana inicial, resultados, borrador...)
function UI.Open(view, extra)
    if UI.isOpen or UI.opening then return end
    UI.opening = true
    JJ.TriggerCallback('races:srv:getState', function(res)
        UI.opening = false
        if not res or not res.ok then
            Notify(res and res.error or L('err_generic'), 'error')
            return
        end
        if view == 'admin' and not res.data.isAdmin then
            Notify(L('n_no_admin'), 'error')
            return
        end
        UI.isOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', view = view, state = res.data, extra = extra })
    end, {})
end

function UI.Close()
    if not UI.isOpen then return end
    UI.isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function UI.Refresh()
    if UI.isOpen then SendNUIMessage({ action = 'refresh' }) end
end

RegisterNUICallback('close', function(_, cb)
    UI.Close()
    cb({ ok = true })
end)

for _, action in ipairs(ACTIONS) do
    RegisterNUICallback(action, function(data, cb)
        if not UI.isOpen then return cb({ ok = false, error = L('err_generic') }) end
        JJ.TriggerCallback('races:srv:' .. action, function(res)
            -- Una prueba de circuito cierra el panel para poder conducir
            if action == 'adminTestTrack' and res and res.ok then UI.Close() end
            cb(res or { ok = false, error = L('err_generic') })
        end, data)
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and UI.isOpen then SetNuiFocus(false, false) end
end)
