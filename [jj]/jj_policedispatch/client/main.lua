local menuOpen = false

local function canOpenMenu()
    local PlayerData = GetPlayerData()
    if (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance") and PlayerData.job.onduty then return true end
    return false
end

local function threadDisabled()
    Citizen.CreateThread(function()
        while menuOpen do
            Citizen.Wait(0)
            SetFrontendActive(false)
            DisableFrontendThisFrame()
            HideHudComponentThisFrame(16)
            DisablePlayerFiring(cache.playerId, true)
            DisableControlAction(0, 1, true)   -- Look Left/Right
            DisableControlAction(0, 2, true)   -- Look Up/Down
            DisableControlAction(0, 4, true)   -- Look Left/Right (vehículo)
            DisableControlAction(0, 5, true)   -- Look Up/Down (vehículo)
            DisableControlAction(0, 24, true)  -- Attack (clic izquierdo)
            DisableControlAction(0, 25, true)  -- Aim (clic derecho)
            DisableControlAction(0, 68, true)  -- Aim (veh)
            DisableControlAction(0, 69, true)  -- Aim (clic izquierdo veh)
            DisableControlAction(0, 70, true)  -- Aim (clic derecho veh)
            DisableControlAction(0, 91, true)  -- Aim Pasajero (clic derecho veh)
            DisableControlAction(0, 92, true)  -- Aim Pasajero (clic izquierdo veh)
            DisableControlAction(0, 106, true) -- Control de coche (clic izquierdo veh)
            DisableControlAction(0, 135, true) -- Control de coche barco (clic izquierdo veh)
            DisableControlAction(0, 142, true) -- Alternador ataque (clic izquierdo veh)
            DisableControlAction(0, 144, true) -- Paracaidas
        end
    end)
end

CreateThread(function()
    while not IsLoggedIn() do
        Citizen.Wait(100)
    end
    Wait(1000)
    SendNUIMessage({ action = "playerLoaded" })
end)

-- La interfaz avisa cuando ha cargado. Al reiniciar el recurso con el personaje dentro,
-- el aviso de arriba y el de los avisos del dispatch pueden llegar antes y perderse
RegisterNUICallback('uiReady', function(_, cb)
    cb('ok')
    if not IsLoggedIn() then return end

    SendNUIMessage({ action = "playerLoaded" })
    TriggerEvent('jj_policedispatch:client:uiReady')
end)

CreateThread(function()
    lib.addKeybind({
        name = "police_menu",
        description = "Menu de radio, referencias, etc",
        defaultKey = "F5",
        onPressed = function(self)
            if not canOpenMenu() then return end
            menuOpen = not menuOpen
            SetNuiFocus(menuOpen, menuOpen)
            SetNuiFocusKeepInput(menuOpen)
            SendNUIMessage({ action = "alternMenuAction" })
            if menuOpen then
                threadDisabled()
            end
        end
    })

    RegisterNUICallback('closeMenu', function(data, cb)
        Citizen.CreateThread(function()
            local endTime = GetGameTimer() + 250
            while GetGameTimer() < endTime do
                Citizen.Wait(0)
                SetFrontendActive(false)
                DisableControlAction(0, 199, true) -- P
                DisableControlAction(0, 200, true) -- ESC
                DisableControlAction(0, 322, true) -- ESC
            end
            menuOpen = false
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end)
        cb('ok')
    end)
end)

OnJobUpdate(function(JobInfo)
    local PlayerData = GetPlayerData()
    if (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance") and PlayerData.job.onduty then
        TriggerServerEvent("jj_policedispatch:server:addPlayerFaction")
    else
        TriggerServerEvent("jj_policedispatch:server:removePlayerFaction")
    end
end)

OnDutyChange(function(duty)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    if duty then
        TriggerServerEvent("jj_policedispatch:server:addPlayerFaction")
    else
        TriggerServerEvent("jj_policedispatch:server:removePlayerFaction")
    end
end)

CreateThread(function()
    while not IsLoggedIn() do
        Citizen.Wait(100)
    end
    Wait(800)
    local PlayerData = GetPlayerData()
    if (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance") and PlayerData.job.onduty then
        TriggerServerEvent("jj_policedispatch:server:addPlayerFaction")
    else
        TriggerServerEvent("jj_policedispatch:server:removePlayerFaction")
    end
end)
