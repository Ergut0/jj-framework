local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

-- Al cerrar con Escape, la misma pulsación no debe volver a abrir el menú
local REOPEN_DELAY = 300

local isOpen = false
local closedAt = 0

CreateThread(function()
    SetNuiZindex(9999)

    while true do
        Wait(0)
        DisableControlAction(0, 200, true) -- Escape ya no abre el menú de pausa de GTA
    end
end)

local function closeMenu()
    isOpen = false
    closedAt = GetGameTimer()
    SetNuiFocus(false, false)
end

local function updatePlayerData(playerData)
    local charinfo = playerData.charinfo or {}
    local accounts = playerData.accounts or {}

    SendNUIMessage({
        type = 'updatePlayerData',
        data = {
            job = playerData.job and playerData.job.label or '',
            cash = accounts.cash or 0,
            bank = accounts.bank or 0,
            fullname = playerData.name or '',
            sex = charinfo.gender == 0 and 'Hombre' or 'Mujer',
            cps = tonumber(LocalPlayer.state.cp) or 0,
        },
    })
end

RegisterKeyMapping('pausemenu', 'Menú de pausa', 'keyboard', 'ESCAPE')
RegisterCommand('pausemenu', function()
    if isOpen or LocalPlayer.state.isDead or LocalPlayer.state.isLastStand then return end
    if IsPauseMenuActive() or IsNuiFocused() or lib.getOpenMenu() then return end
    if GetGameTimer() - closedAt < REOPEN_DELAY then return end

    -- Sin personaje cargado no hay nada que enseñar
    local playerData = JJ.GetPlayerData()
    if not playerData then return end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'openPauseMenu' })
    updatePlayerData(playerData)

    lib.callback('jj_pausemenu:getData', false, function(data)
        if not data then return end

        SendNUIMessage({ type = 'loadJobs', data = data.jobs })
        SendNUIMessage({ type = 'loadAnnouncements', data = data.announcements })
    end)
end, false)

RegisterNUICallback('openMap', function(_, cb)
    closeMenu()
    ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)
    cb('ok')
end)

RegisterNUICallback('openSettings', function(_, cb)
    closeMenu()
    ActivateFrontendMenu(`FE_MENU_VERSION_LANDING_MENU`, false, -1)
    cb('ok')
end)

RegisterNUICallback('closePauseMenu', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('openBusiness', function(data, cb)
    cb('ok')
    closeMenu()
    SendNUIMessage({ type = 'closePauseMenu' })

    if GetResourceState('jj_bizztablet') ~= 'started' or not exports.jj_bizztablet:openJobPage(data.name) then
        lib.notify({ description = 'La ficha de este negocio no está disponible', type = 'error' })
    end
end)

RegisterNetEvent('jj_pausemenu:updateAnnouncements', function(announcements)
    SendNUIMessage({ type = 'loadAnnouncements', data = announcements })
end)

-- Lo envía jj_creatorjobs al abrir o cerrar un negocio
RegisterNetEvent('jj_creatorjobs:client:syncBlipStatus', function(jobName, open)
    SendNUIMessage({ type = 'updateJob', data = { name = jobName, open = open } })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
