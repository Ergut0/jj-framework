RegisterCommand("polidispo", function()
    ExecuteCommand("entorno Solicitud de robo")
    Notify('Solicitud de robo enviada', 'success', 7500)
end)

RegisterCommand("actualizarinfopj", function()
    TriggerServerEvent("smallresources:server:CreateID")
    TriggerServerEvent("smallresources:server:CreateDriverLicense")
end)

-- RegisterCommand("servicio", function()
--     TriggerServerEvent("QBCore:ToggleDuty")
-- end)

RegisterCommand("cachear", function()
    local coords = GetEntityCoords(cache.ped)
    local playerid, targetPed, targetCoords = lib.getClosestPlayer(coords, 3.0)

    if not playerid then
        Notify('No hay nadie cerca', 'error')
        return
    end

    local distance = GetDistanceBetweenCoords(coords, targetCoords, true)

    if distance < 2.0 then
        if lib.progressBar({
                duration = 5000,
                label = "Cacheando a la persona",
                useWhileDead = false,
                canCancel = true,
                anim = {
                    dict = "anim@gangops@facility@servers@bodysearch@",
                    clip = "player_search",
                    flags = 16,
                },
                disable = {
                    car = true,
                    combat = true,
                },
            }) then
            if IsEntityPlayingAnim(targetPed, 'missminuteman_1ig_2', 'handsup_base', 3) or IsEntityPlayingAnim(targetPed, "mp_arresting", "idle", 3) or Player(GetPlayerServerId(playerid)).state.isDead or Player(GetPlayerServerId(playerid)).state.isLastStand then
                local identifiers = lib.callback.await('jj_smallresources:getIdentifiers', false,
                    GetPlayerServerId(playerid))
                exports.ox_inventory:openInventory('player', GetPlayerServerId(playerid))
                TriggerServerEvent("jj_smallresources:server:createLongExtends", "CACHEO",
                    ("Ha cacheado a **%s**"):format(identifiers and identifiers.name or "?"), "cacheos", cache.serverId)
                ExecuteCommand('me Le cachea el cuerpo')
            else
                Notify('No puedes cachearle, mira que estés haciendo las cosas bien', 'error')
            end
        end
    else
        Notify('Te has alejado demasiado de la persona')
    end
end)

local cooldown = 0
RegisterCommand("v", function()
    if not cache.vehicle then return end

    if GetGameTimer() - cooldown < 5000 then
        Notify('Espera 5 segundos para volver a utilizar')
        return
    end
    cooldown = GetGameTimer()

    -- La categoria "police" de origen_police ya incluye police y sheriff
    TriggerServerEvent("SendAlert:police", {
        coords = GetEntityCoords(cache.ped),
        title = 'VEHICULO A ALTA VELOCIDAD',
        type = 'GENERAL',
        message = ("El vehiculo %s con matricula %s ha sido visto a alta velocidad"):format(
            GetDisplayNameFromVehicleModel(GetEntityModel(cache.vehicle)),
            GetVehicleNumberPlateText(cache.vehicle)
        ),
        job = "police",
    })
end)


RegisterCommand("fixui", function()
    lib.hideTextUI()
end)

RegisterCommand("rvoz", function()
    if exports["pma-voice"] and exports["pma-voice"].toggleVoice then
        local serverId = GetPlayerServerId(PlayerId())
        Notify("Reiniciando sistema de voz")
        local ok1, err1 = pcall(function()
            exports["pma-voice"]:toggleVoice(serverId, false)
        end)
        Wait(2000)
        local ok2, err2 = pcall(function()
            exports["pma-voice"]:toggleVoice(serverId, true)
        end)
        if ok1 and ok2 then
            Notify('Sistema de voz reiniciado', 'success', 5000)
        end
    end
end)

RegisterKeyMapping("rvoz", "Reiniciar voz", "keyboard", "F4")

local savedHair = nil
local originalHair = nil
local hairToggled = false


Citizen.CreateThread(function()
    local hair = GetResourceKvpInt("savedHair")
    savedHair = hair
    local orig = GetResourceKvpInt("originalHair")
    originalHair = orig
end)

RegisterCommand("pelo", function()
    local ped = PlayerPedId()
    local gender = "Male"
    if IsPedModel(ped, `mp_f_freemode_01`) then
        gender = "Female"
    end

    local input = exports.ox_lib:inputDialog('Guardar Peinado', { {
        type = 'number',
        label = 'Número de peinado a guardar',
        description = 'Introduce el número de peinado actual',
        required = true,
    } })
    if not input then return end
    local hairDrawable = tonumber(input[1])
    if hairDrawable then
        savedHair = hairDrawable
        SetResourceKvpInt("savedHair", hairDrawable)
        Notify("Peinado guardado: " .. tostring(savedHair), "success")
    else
        Notify("Número de peinado inválido.", "error")
    end
end, false)

function ChangeHair()
    local ped = PlayerPedId()
    local dict = "clothingtie"
    local anim = "check_out_a"
    local move = 51
    local dur = 2000


    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    TaskPlayAnim(ped, dict, anim, 3.0, 3.0, dur, move, 0, false, false, false)
    Wait(dur - 500)

    if not hairToggled then
        originalHair = GetPedDrawableVariation(ped, 2)
        SetResourceKvpInt("originalHair", originalHair)
        if savedHair then
            SetPedComponentVariation(ped, 2, savedHair, 0, 2)
            Notify("Peinado aplicado: " .. tostring(savedHair), "success")
            hairToggled = true
        else
            Notify("No tienes ningún peinado guardado.", "error")
        end
    else
        if originalHair then
            SetPedComponentVariation(ped, 2, originalHair, 0, 2)
            Notify("Peinado original restaurado: " .. tostring(originalHair), "success")
        end
        hairToggled = false
    end
end

function GetActualHair()
    local ped = PlayerPedId()
    local hairDrawable = GetResourceKvpInt("savedHair")
    return hairDrawable
end

function SetSavedHair()
    local hair = GetActualHair()
    local ped  = PlayerPedId()
    SetPedComponentVariation(ped, 2, hair, 0, 2)
end

function SecondHairActive()
    return hairToggled
end

RegisterCommand("cambiarpelo", function()
    ChangeHair()
end, false)

exports('ChangeHair', ChangeHair)
exports('GetActualHair', GetActualHair)
exports('SetSavedHair', SetSavedHair)
exports('SecondHairActive', SecondHairActive)
