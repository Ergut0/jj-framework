local Voice = exports['pma-voice']
local playerState = LocalPlayer.state

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

if radioVolume < 5 or radioVolume > 100 then radioVolume = 100 end
if not radioAnimations[currentAnim] then currentAnim = 1 end

local function canAct()
    return not playerState.isCuffed and not playerState.isDead and not playerState.isLastStand
end

-- Voz

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
        SendNUIMessage({ action = 'talking', own = id == cache.serverId, id = id, talking = talking })
    end
end

-- Este evento también salta con otras radios: el prop solo se pone en esta
AddEventHandler('pma-voice:radioActive', function(active)
    if not joinedFrequency then return end

    setTalking(cache.serverId, active)
    if active then attachRadioProp() else removeRadioProp() end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(id, talking)
    if joinedFrequency and id ~= cache.serverId then setTalking(id, talking) end
end)

RegisterNetEvent('jj_radio:client:count', function(count)
    if radioOpen then
        SendNUIMessage({ action = 'count', count = count })
    end
end)

RegisterNetEvent('jj_radio:client:invites', function(invites)
    if radioOpen then
        SendNUIMessage({ action = 'invites', invites = invites })
    end
end)

RegisterNetEvent('jj_radio:client:disconnected', function(message)
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
    TriggerServerEvent('jj_radio:server:close')

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

-- Con el panel abierto se puede andar, pero no apuntar, disparar ni mover la cámara.
-- Los números se reservan para el teclado de la radio
local function whilePanelOpen()
    while radioOpen do
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 4, true)
        DisableControlAction(0, 5, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 37, true)
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
        for control = 157, 165 do
            DisableControlAction(0, control, true)
        end

        if not canAct() then closePanel() end
        Wait(0)
    end
end

local function openPanel()
    if radioOpen or not JJ.IsSpawned() then return end

    if not canAct() then
        JJ.Notify('No puedes realizar esta acción ahora', 'error')
        return
    end

    local data = lib.callback.await('jj_radio:open', false)
    if not data then return end

    radioOpen = true
    SendNUIMessage({
        action = 'open',
        frequency = data.frequency or false,
        lastFrequency = tonumber(GetResourceKvpString('frequency')) or false,
        count = data.count,
        min = data.min,
        max = data.max,
        maxSaved = data.maxSaved,
        maxLabel = data.maxLabel,
        saved = data.saved,
        invites = data.invites,
        volume = radioVolume,
        animIndex = currentAnim - 1,
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    CreateThread(whilePanelOpen)
end

-- Se abre con el objeto del inventario: client = { export = 'jj_radio.openRadio' } en data/items.lua
exports('openRadio', function()
    openPanel()
end)

RegisterNUICallback('closeRadio', function(_, cb)
    closePanel()
    cb({ success = true })
end)

-- Avisa del motivo si el servidor rechaza la acción y devuelve si la ha aceptado
local function accepted(result, fallback)
    if result and result.ok then return true end
    JJ.Notify(result and result.message or fallback, 'error')
    return false
end

local function connected(result)
    joinedFrequency = result.frequency
    SetResourceKvp('frequency', tostring(result.frequency))
    Voice:setRadioVolume(radioVolume)
    applyRadioAnim()
end

-- Mientras se escribe un nombre, las letras no pueden mover al personaje
RegisterNUICallback('setTyping', function(data, cb)
    if radioOpen then SetNuiFocusKeepInput(not (data and data.typing)) end
    cb({ success = true })
end)

RegisterNUICallback('joinFrequency', function(data, cb)
    Voice:setVoiceProperty('radioEnabled', true)

    local result = lib.callback.await('jj_radio:join', false, tonumber(data and data.frequency))
    if not accepted(result, 'No se ha podido conectar') then
        cb({ success = false })
        return
    end

    connected(result)
    cb({ success = true, frequency = result.frequency, count = result.count })
end)

RegisterNUICallback('saveFrequency', function(data, cb)
    local result = lib.callback.await('jj_radio:save', false, tonumber(data and data.frequency), data and data.label)
    if not accepted(result, 'No se ha podido guardar') then
        cb({ success = false })
        return
    end
    cb({ success = true, saved = result.saved })
end)

RegisterNUICallback('deleteFrequency', function(data, cb)
    local result = lib.callback.await('jj_radio:delete', false, tonumber(data and data.frequency))
    if not accepted(result, 'No se ha podido borrar') then
        cb({ success = false })
        return
    end
    cb({ success = true, saved = result.saved })
end)

RegisterNUICallback('invitePlayer', function(data, cb)
    local result = lib.callback.await('jj_radio:invite', false, tonumber(data and data.target))
    if not accepted(result, 'No se ha podido invitar') then
        cb({ success = false })
        return
    end
    JJ.Notify('Invitación enviada', 'success')
    cb({ success = true })
end)

RegisterNUICallback('answerInvite', function(data, cb)
    local accept = data and data.accept == true
    if accept then Voice:setVoiceProperty('radioEnabled', true) end

    local result = lib.callback.await('jj_radio:answerInvite', false, tonumber(data and data.frequency), accept)
    if not accepted(result, 'No se ha podido responder') then
        cb({ success = false })
        return
    end

    if accept then connected(result) end
    cb({ success = true, frequency = result.frequency, count = result.count, saved = result.saved })
end)

RegisterNUICallback('leaveFrequency', function(_, cb)
    joinedFrequency = nil
    removeRadioProp()
    TriggerServerEvent('jj_radio:server:leave')
    cb({ success = true })
end)

local function changeVolume(amount)
    radioVolume = math.max(5, math.min(100, radioVolume + amount))
    SetResourceKvpInt('volume', radioVolume)
    Voice:setRadioVolume(radioVolume)
end

RegisterNUICallback('volumeUp', function(_, cb)
    changeVolume(5)
    cb({ volume = radioVolume })
end)

RegisterNUICallback('volumeDown', function(_, cb)
    changeVolume(-5)
    cb({ volume = radioVolume })
end)

RegisterNUICallback('setAnimation', function(data, cb)
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

-- No dejar el ratón atrapado ni objetos sueltos si el recurso se para
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    removeRadioProp()
end)
