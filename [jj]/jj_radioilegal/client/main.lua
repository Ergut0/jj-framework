local Voice = exports['pma-voice']
local playerState = LocalPlayer.state

local ESCORT_DICT = 'amb@world_human_drinking@coffee@male@base'

local radioAnimations = {
    {
        Dict = 'random@arrests',
        Anim = 'generic_radio_chatter',
        Prop = 'prop_cs_hand_radio',
        PropBone = 60309,
        PropPlacement = { 0.0750, 0.0470, 0.0110, -97.9442, 3.7058, -23.2367 },
    },
    {
        Dict = 'cellphone@str',
        Anim = 'cellphone_call_listen_a',
        Prop = 'prop_cs_hand_radio',
        PropBone = 57005,
        PropPlacement = { 0.12, 0.02, -0.02, 20.0, 70.0, 130.0 },
    },
    {
        Dict = 'anim@cop_mic_pose_002',
        Anim = 'chest_mic',
    },
}

local radioOpen = false
local joinedFrequency = nil
local radioVolume = GetResourceKvpInt('volume')
local currentAnim = GetResourceKvpInt('animation')
local radioObject = nil
local headbagObject = nil

if radioVolume < 5 or radioVolume > 100 then radioVolume = 100 end
if not radioAnimations[currentAnim] then currentAnim = 1 end

local function canAct()
    return not playerState.isCuffed and not playerState.isDead and not playerState.isLastStand
end

local function rpAction(text)
    TriggerServerEvent('jj_chat:server:send', 'say', ('* %s'):format(text))
end

-- Radio

local function applyRadioAnim()
    local animation = radioAnimations[currentAnim]
    -- Una animación que no existe en este servidor haría fallar la llamada a pma-voice
    if not DoesAnimDictExist(animation.Dict) then return false end
    Voice:setRadioTalkAnim(animation.Dict, animation.Anim)
    return true
end

local function attachRadioProp()
    local animation = radioAnimations[currentAnim]
    if not animation.Prop or radioObject then return end

    local hash = joaat(animation.Prop)
    lib.requestModel(hash)

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    radioObject = CreateObject(hash, coords.x, coords.y, coords.z + 0.2, true, true, false)

    local px, py, pz, rx, ry, rz = table.unpack(animation.PropPlacement)
    AttachEntityToEntity(radioObject, ped, GetPedBoneIndex(ped, animation.PropBone), px, py, pz, rx, ry, rz, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
end

local function removeRadioProp()
    if radioObject and DoesEntityExist(radioObject) then
        DeleteEntity(radioObject)
    end
    radioObject = nil
end

local function setTalking(id, talking)
    if radioOpen then
        SendNUIMessage({ action = 'playerTalking', id = id, talking = talking })
    end
end

-- Este evento también salta con otras radios: el prop solo se pone en la de la banda
AddEventHandler('pma-voice:radioActive', function(active)
    if not joinedFrequency then return end

    setTalking(cache.serverId, active)
    if active then attachRadioProp() else removeRadioProp() end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(id, talking)
    if joinedFrequency then setTalking(id, talking) end
end)

RegisterNetEvent('jj_radioilegal:client:sync', function(frequencies)
    if radioOpen then
        SendNUIMessage({ action = 'updateFrequencies', frequencies = frequencies })
    end
end)

RegisterNetEvent('jj_radioilegal:client:disconnected', function(message)
    joinedFrequency = nil
    removeRadioProp()
    if radioOpen then SendNUIMessage({ action = 'setFrequency', frequency = false }) end
    if message then JJ.Notify(message, 'error') end
end)

-- Panel

local function closePanel()
    if not radioOpen then return end

    radioOpen = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerServerEvent('jj_radioilegal:server:close')

    -- Que el ESC con el que se cierra no abra también el menú de pausa
    CreateThread(function()
        local timeout = GetGameTimer() + 100
        while GetGameTimer() < timeout do
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        end
    end)
end

-- Con el panel abierto se puede andar, pero no apuntar, disparar ni mover la cámara
local function whilePanelOpen()
    while radioOpen do
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 4, true)
        DisableControlAction(0, 5, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 47, true)
        DisableControlAction(0, 58, true)
        DisableControlAction(0, 68, true)
        DisableControlAction(0, 69, true)
        DisableControlAction(0, 70, true)
        DisableControlAction(0, 91, true)
        DisableControlAction(0, 92, true)
        DisableControlAction(0, 106, true)
        DisableControlAction(0, 122, true)
        DisableControlAction(0, 135, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 144, true)
        DisableControlAction(0, 200, true)
        DisableControlAction(0, 322, true)

        if not canAct() then closePanel() end
        Wait(0)
    end
end

local function openPanel()
    if not JJ.IsSpawned() then return end

    if not canAct() then
        JJ.Notify('No puedes realizar esta acción ahora', 'error')
        return
    end

    local data = lib.callback.await('jj_radioilegal:open', false)
    if not data then return end

    radioOpen = true
    SendNUIMessage({
        action = 'open',
        playerName = data.name,
        playerId = cache.serverId,
        gang = data.gang,
        frequency = data.frequency or false,
        frequencies = data.frequencies,
        volume = radioVolume,
        animIndex = currentAnim - 1,
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    CreateThread(whilePanelOpen)
end

RegisterCommand('toggleRadio', function()
    if radioOpen then closePanel() else openPanel() end
end, false)
RegisterKeyMapping('toggleRadio', 'Abrir o cerrar la radio de banda', 'keyboard', Config.OpenKey)

RegisterNUICallback('closeRadioUI', function(_, cb)
    closePanel()
    cb({ success = true })
end)

RegisterNUICallback('joinFrequency', function(data, cb)
    Voice:setVoiceProperty('radioEnabled', true)

    local result = lib.callback.await('jj_radioilegal:join', false, tonumber(data and data.frequency))
    if not result or not result.ok then
        JJ.Notify(result and result.message or 'No se ha podido conectar', 'error')
        cb({ success = false })
        return
    end

    joinedFrequency = result.frequency
    Voice:setRadioVolume(radioVolume)
    applyRadioAnim()
    cb({ success = true, frequency = result.frequency })
end)

RegisterNUICallback('leaveFrequency', function(_, cb)
    joinedFrequency = nil
    removeRadioProp()
    TriggerServerEvent('jj_radioilegal:server:leave')
    JJ.Notify('Radio desconectada', 'error')
    cb({ success = true })
end)

local function changeVolume(amount)
    local volume = math.max(5, math.min(100, radioVolume + amount))
    if volume == radioVolume then
        JJ.Notify(amount > 0 and 'Volumen máximo' or 'Volumen mínimo', 'error')
        return
    end

    radioVolume = volume
    SetResourceKvpInt('volume', volume)
    Voice:setRadioVolume(volume)
end

RegisterNUICallback('volumeUp', function(_, cb)
    changeVolume(5)
    cb({ volume = radioVolume })
end)

RegisterNUICallback('volumeDown', function(_, cb)
    changeVolume(-5)
    cb({ volume = radioVolume })
end)

RegisterNUICallback('playAnimation', function(data, cb)
    local index = tonumber(data and data.animIndex)
    local animation = index and radioAnimations[index + 1]
    if not animation then
        cb({ success = false })
        return
    end

    local previous = currentAnim
    currentAnim = math.tointeger(index + 1)
    if not applyRadioAnim() then
        currentAnim = previous
        JJ.Notify('Esa animación no está disponible', 'error')
        cb({ success = false })
        return
    end

    removeRadioProp()
    SetResourceKvpInt('animation', currentAnim)
    cb({ success = true })
end)

-- Acciones

local function getClosestPlayer()
    local id, ped = lib.getClosestPlayer(GetEntityCoords(cache.ped), Config.ActionDistance, false)
    if not id or not ped then
        JJ.Notify('No hay nadie cerca', 'error')
        return nil
    end
    return GetPlayerServerId(id), ped
end

local function notifyFailure(result)
    JJ.Notify(result and result.message or 'No se ha podido hacer', 'error')
end

local function toggleCuffs()
    if playerState.invBusy then return end

    local target, ped = getClosestPlayer()
    if not target then return end

    local targetIsDown = Player(target).state.isDead
    local result = lib.callback.await('jj_radioilegal:cuff', false, target)
    if not result or not result.ok then
        notifyFailure(result)
        return
    end

    rpAction(result.cuffed and 'Esposa a la persona' or 'Quita las esposas a la persona')

    -- El efecto sobre el esposado lo gestiona jj_things al cambiar isCuffed
    playerState.invBusy = true

    local finished = false
    local function finish()
        if finished then return end
        finished = true
        if IsEntityAttached(cache.ped) then DetachEntity(cache.ped, true, false) end
        FreezeEntityPosition(cache.ped, false)
        playerState.invBusy = false
    end
    -- Si la animación se corta, invBusy no se queda pegado
    SetTimeout(12000, finish)

    if not targetIsDown then
        FreezeEntityPosition(cache.ped, true)
        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        AttachEntityToEntity(cache.ped, ped, 11816, -0.07, -0.58, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

        local dict = result.cuffed and 'mp_arrest_paired' or 'mp_arresting'
        lib.requestAnimDict(dict)
        if result.cuffed then
            TaskPlayAnim(cache.ped, dict, 'cop_p2_back_right', 8.0, -8.0, 3750, 2, 0.0, false, false, false)
            Wait(3750)
        else
            TaskPlayAnim(cache.ped, dict, 'a_uncuff', 8.0, -8.0, 5500, 0, 0.0, false, false, false)
            Wait(5500)
        end
        RemoveAnimDict(dict)
    end

    finish()
end

-- Usa la misma escolta que jj_policejob: se puede soltar también desde ox_target
local function whileEscorting(targetPed)
    lib.requestAnimDict(ESCORT_DICT)

    while playerState.isEscorting and DoesEntityExist(targetPed) do
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
        if not IsEntityPlayingAnim(cache.ped, ESCORT_DICT, 'base', 3) then
            TaskPlayAnim(cache.ped, ESCORT_DICT, 'base', 8.0, 8.0, -1, 49, 0.0, false, false, false)
        end
        Wait(0)
    end

    playerState.isEscorting = false
    StopAnimTask(cache.ped, ESCORT_DICT, 'base', -8.0)
    RemoveAnimDict(ESCORT_DICT)
end

local function toggleEscort()
    local target, ped = getClosestPlayer()
    if not target then return end

    local state = lib.callback.await('jj_policejob:callback:setPlayerEscort', false, target, IsEntityAttachedToEntity(ped, cache.ped))
    if state == nil then
        JJ.Notify('El jugador debe estar esposado o abatido', 'error')
        return
    end

    playerState.isEscorting = state
    rpAction(state and 'Agarra a la persona' or 'Suelta a la persona')
    if state then CreateThread(function() whileEscorting(ped) end) end
end

local function findFreeSeat(vehicle)
    for seat = GetVehicleMaxNumberOfPassengers(vehicle) - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle, seat) then return seat end
    end
    return nil
end

local function vehicleAction()
    local target, ped = getClosestPlayer()
    if not target then return end

    local current = GetVehiclePedIsIn(ped, false)
    local vehicle = current ~= 0 and current or lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.VehicleDistance, false)
    if not vehicle then
        JJ.Notify('No hay ningún vehículo cerca', 'error')
        return
    end

    local seat
    if current == 0 then
        seat = findFreeSeat(vehicle)
        if not seat then
            JJ.Notify('No hay asientos libres', 'error')
            return
        end
    end

    local result = lib.callback.await('jj_radioilegal:vehicle', false, target, NetworkGetNetworkIdFromEntity(vehicle), seat)
    if not result or not result.ok then
        notifyFailure(result)
        return
    end

    if seat then playerState.isEscorting = false end
    rpAction(seat and 'Mete a la persona en el vehículo' or 'Saca a la persona del vehículo')
end

local function toggleHeadbag()
    local target = getClosestPlayer()
    if not target then return end

    local result = lib.callback.await('jj_radioilegal:headbag', false, target)
    if not result or not result.ok then
        notifyFailure(result)
        return
    end

    rpAction(result.bagged and 'Pone una bolsa en la cabeza de la persona' or 'Quita la bolsa de la cabeza de la persona')
end

RegisterCommand('headbag', function()
    if canAct() and not cache.vehicle then toggleHeadbag() end
end, false)

local actions = {
    arrastrar = toggleEscort,
    esposar = toggleCuffs,
    vehiculo = vehicleAction,
    bolsa = toggleHeadbag,
}

RegisterNUICallback('action', function(data, cb)
    cb('ok')

    local action = actions[data and data.action]
    if not action or not canAct() then return end

    if cache.vehicle then
        JJ.Notify('No puedes hacerlo dentro de un vehículo', 'error')
        return
    end

    action()
end)

-- Bolsa en la cabeza de este jugador

local function removeHeadbag()
    if headbagObject and DoesEntityExist(headbagObject) then
        DeleteEntity(headbagObject)
    end
    headbagObject = nil
    SendNUIMessage({ action = 'headbag', active = false })
end

local function putHeadbag()
    if headbagObject then return end

    local hash = joaat(Config.HeadbagModel)
    lib.requestModel(hash)

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    headbagObject = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(headbagObject, ped, GetPedBoneIndex(ped, 12844), 0.2, 0.04, 0.0, 0.0, 270.0, 60.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)

    TriggerServerEvent('jj_radioilegal:server:headbagProp', ObjToNet(headbagObject))
    SendNUIMessage({ action = 'headbag', active = true })
end

AddStateBagChangeHandler('hasHeadbag', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value then putHeadbag() else removeHeadbag() end
end)

-- No dejar el ratón atrapado ni objetos sueltos si el recurso se para
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    removeRadioProp()
    if headbagObject and DoesEntityExist(headbagObject) then DeleteEntity(headbagObject) end
end)
