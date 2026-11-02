local utils = require "client.utils.functions"
local federalCoords = {
    enter = vector4(1627.47, 2492.37, 45.56, 322.24),
    exit = vector4(477.45, -979.67, 27.98, 0.44),
}

local function getExitCoords()
    if GetResourceState('jj_policejob') == 'started' then
        local ok, coords = pcall(function()
            return exports.jj_policejob:getLeaveJail()
        end)
        if ok and coords then return coords end
    end
    return federalCoords.exit
end
local timerActive = nil
local releasingPlayer = false -- NUEVO: evita que la zona reaccione durante una salida legítima

RegisterNuiCallback('sendToFederal', function(data, cb)
    local response = lib.callback.await('jj_policetablet:callback:sendToFederal', false, data)
    cb(response)
end)

RegisterNuiCallback('getJailedPlayers', function(data, cb)
    local jailedPlayers = lib.callback.await('jj_policetablet:callback:getJailedPlayers', false)
    cb(jailedPlayers)
end)

RegisterNuiCallback('releaseJailedPlayer', function(data, cb)
    local response = lib.callback.await('jj_policetablet:callback:releaseJailedPlayer', false, data)
    cb(response)
end)

local function sendToCoords(coords)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or coords.h or 0.0)
    Wait(600)
    DoScreenFadeIn(500)
end

-- NUEVO: único punto de salida "legítima", protege el onExit mientras el metadata sincroniza
local function releaseFromFederal()
    releasingPlayer = true
    sendToCoords(getExitCoords())
    -- damos margen a que PlayerData.metadata llegue actualizado antes de rearmar el chequeo
    SetTimeout(10000, function()
        releasingPlayer = false
    end)
end

RegisterNetEvent('jj_policetablet:client:teleportToFederal', function(time)
    releasingPlayer = false
    sendToCoords(federalCoords.enter)
    if timerActive then
        timerActive:forceEnd(false)
        timerActive = nil
    end

    timerActive = lib.timer(time * 60000, function()
        timerActive = nil
        lib.hideTextUI()
        TriggerServerEvent("jj_policetablet:server:resetJail") -- avisamos primero
        releaseFromFederal()
    end, true)

    CreateThread(function()
        while timerActive do
            local timeLeft = timerActive:getTimeLeft()
            if timeLeft then
                local totalSec = math.floor(timeLeft.s or (timeLeft.ms and (timeLeft.ms / 1000)) or 0)
                local mins = math.floor(totalSec / 60)
                local secs = totalSec % 60
                local formattedTime = string.format("%02d:%02d", mins, secs)

                lib.showTextUI(("Tiempo restante: %s"):format(formattedTime), {
                    position = "top-center",
                    icon = "fa-solid fa-stopwatch"
                })
            end
            Wait(1000)
        end
        lib.hideTextUI()
    end)
end)

RegisterNetEvent('jj_policetablet:client:teleportToRelease', function()
    if timerActive then
        timerActive:forceEnd(false)
        timerActive = nil
    end
    lib.hideTextUI()
    releaseFromFederal()
end)

CreateThread(function()
    while not LocalPlayer.state['isLoggedIn'] do
        Wait(1000)
    end

    local PlayerData = GetPlayerData()
    if PlayerData.metadata.injail and PlayerData.metadata.injail > 0 then
        TriggerEvent("jj_policetablet:client:teleportToFederal", PlayerData.metadata.injail)
    end

    lib.zones.poly({
        points = {
            vector3(1642.97, 2773.99, 0),
            vector3(1568.07, 2687.83, 0),
            vector3(1532.16, 2589.37, 0),
            vector3(1540.37, 2472.44, 0),
            vector3(1654.26, 2397.56, 0),
            vector3(1768.14, 2407.82, 0),
            vector3(1834.84, 2488.85, 0),
            vector3(1860.49, 2584.24, 0),
            vector3(1859.46, 2689.88, 0),
            vector3(1775.33, 2773.99, 0)
        },
        thickness = 1500,
        onExit = function()
            if releasingPlayer then return end -- NUEVO
            local PlayerData = GetPlayerData()
            if PlayerData.metadata.injail and PlayerData.metadata.injail > 0 then
                sendToCoords(federalCoords.enter)
            end
        end,
    })
end)