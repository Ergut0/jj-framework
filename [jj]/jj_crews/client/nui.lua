-- Puente NUI <-> servidor. Sin bucles: todo es dirigido por eventos (0.00 ms en idle).

UI = { isOpen = false, opening = false }

-- Acciones que la NUI puede solicitar. El servidor revalida todo (incluido admin).
local ACTIONS = {
    'getState', 'createCrew', 'updateCrew', 'invite', 'respondInvite', 'leave', 'kick', 'setRank',
    'transferLeader', 'disband', 'deposit', 'withdraw', 'getTransactions', 'getActivity', 'getRanking',
    'createRank', 'updateRank', 'deleteRank',
    'adminList', 'adminGetCrew', 'adminCreate', 'adminUpdate', 'adminFreeze', 'adminDelete', 'adminAddMember',
    'adminKick', 'adminSetRank', 'adminSetLeader', 'adminEditStat', 'adminCreateRank', 'adminUpdateRank',
    'adminDeleteRank', 'adminLogs', 'adminGetSettings', 'adminSaveSettings',
}

function UI.Open(view)
    if UI.isOpen or UI.opening then return end
    UI.opening = true
    JJ.TriggerCallback('crews:srv:getState', function(res)
        UI.opening = false
        if not res or not res.ok then
            JJ.Notify(res and res.error or L('err_generic'), 'error')
            return
        end
        if view == 'admin' and not res.data.isAdmin then
            JJ.Notify(L('n_no_admin'), 'error')
            return
        end
        UI.isOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', view = view, state = res.data })
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
        JJ.TriggerCallback('crews:srv:' .. action, function(res)
            cb(res or { ok = false, error = L('err_generic') })
        end, data)
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and UI.isOpen then SetNuiFocus(false, false) end
end)
