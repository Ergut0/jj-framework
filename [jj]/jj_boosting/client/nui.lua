-- Puente con la interfaz. Solo pasan las llamadas de esta lista, y el servidor las vuelve a comprobar
local ALLOWED = {
    getDashboard = true, getTransactions = true, getHistory = true, getLeaderboard = true, getStore = true,
    updateProfile = true, joinQueue = true, leaveQueue = true, acceptContract = true, declineContract = true,
    abandonContract = true, buyContract = true, buyItem = true, collectPurchase = true,
    adminOverview = true, adminSearch = true, adminProfile = true, adminAssign = true, adminSetXp = true,
    adminSetCrypto = true, adminHistory = true, adminLogs = true, adminResetStock = true, adminConfig = true,
    adminCancelContract = true,
}

local isOpen = false

function Boosting.Open(tab)
    if isOpen or Boosting.hacking then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', tab = tab, locale = Config.Locale })
end

function Boosting.Close()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    Boosting.Close()
    cb('ok')
end)

RegisterNUICallback('api', function(data, cb)
    if type(data) ~= 'table' or not ALLOWED[data.name] then
        cb({ ok = false })
        return
    end
    cb(Boosting.Call(data.name, data.payload) or { ok = false })
end)

RegisterNetEvent('jj_boosting:client:refresh', function()
    SendNUIMessage({ action = 'refresh' })
end)

-- No dejar el ratón atrapado si el recurso se para con la terminal abierta
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then SetNuiFocus(false, false) end
end)
