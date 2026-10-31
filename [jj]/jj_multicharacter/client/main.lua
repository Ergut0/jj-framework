local config = lib.load('shared.cfg')
local func = lib.load('client.animations')
optionVeh = nil


exports.ox_inventory:displayMetadata({
    id = 'ID',
    fullname = 'Nombre Completo',
    birthdate = 'Fecha de Nacimiento',
})


local isNuiReady = false
local isMulticharActive = false

RegisterNuiCallback('nuiReady', function(data, cb)
    isNuiReady = true
    cb({ active = isMulticharActive })
    if isMulticharActive then
        SendNUIMessage({
            action = 'showInterface',
            data = {}
        })
    end
end)

local function startLoadingCharacters()
    isMulticharActive = true
    lib.callback.await('jj_multicharacter:server:enterInstance', false)
    SendNUIMessage({
        action = 'showInterface',
        data = {}
    })
    SetNuiFocus(true, true)
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false, false)
    SetEntityInvincible(PlayerPedId(), true)
    SetEntityMaxHealth(PlayerPedId(), 200)
    func.fadeScreen(false)
    Wait(1000)
    func.startCinematic()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

RegisterNuiCallback('getAllData', function(data, cb)
    local characters = lib.callback.await('jj_multicharacter:server:setupCharacters', false) or {}
    local numCharacters = lib.callback.await('jj_multicharacter:server:GetNumberOfCharacters', false) or 1
    local zones = config.zonesSpawn
    cb({ characters = characters, zones = zones, slotsUnlocked = numCharacters })
end)

RegisterNuiCallback('setActiveCharacter', function(data, cb)
    func.fadeScreen(true)
    Wait(500)
    func.stopCinematic()
    local sceneRandom = config.scenes[math.random(1, #config.scenes)]
    func.cleanDataPed()
    func.createCam(sceneRandom)
    func.createSceneNpc(sceneRandom)
    local preview = lib.callback.await('jj_multicharacter:server:getPreviewPedData', false, data.citizenid) or {}
    func.createScenePed(preview.model, sceneRandom, preview.skin, preview.gender)
    Wait(600)
    func.fadeScreen(false)
    SendNUIMessage({
        action = 'showPlayButton',
        data = {}
    })
    cb('ok')
end)

-- Cambia el ped del jugador por el modelo y el aspecto del personaje cargado
local function setPlayerAppearance(character)
    lib.requestModel(character.model)
    SetPlayerModel(PlayerId(), character.model)
    SetModelAsNoLongerNeeded(character.model)
    local ped = PlayerPedId()
    func.applyAppearance(ped, character.skin, character.gender)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
end

RegisterNuiCallback('selectCharacter', function(data, cb)
    local character = lib.callback.await('jj_multicharacter:server:loadCharacter', false, data.citizenid)
    if not character then
        lib.notify({ description = 'Error cargando el personaje, contacta con administracion', type = 'error' })
        return cb(false)
    end

    cb('ok')
    func.stopCinematic()
    isMulticharActive = false
    SendNUIMessage({ action = 'hideInterface', data = {} })
    SetNuiFocus(false, false)
    setPlayerAppearance(character)

    local position = character.position
    func.playSkyDrop(vector4(position.x + 0.0, position.y + 0.0, position.z + 0.0, (position.heading or 0) + 0.0))
    JJ.SetSpawned()
end)

RegisterNuiCallback('createCharacter', function(data, cb)
    local character, reason = nil, nil
    local result = lib.callback.await('jj_multicharacter:server:createCharacter', false, {
        firstname = data.firstName,
        lastname = data.lastName,
        nationality = data.nationality,
        gender = (data.gender == "male") and 0 or 1,
        birthdate = data.birthdate,
    })
    if result then
        character, reason = result.character, result.error
    end

    if not character then
        lib.notify({ description = reason or 'No se ha podido crear el personaje', type = 'error' })
        return cb({ ok = false })
    end

    cb({ ok = true })
    isMulticharActive = false
    func.stopCinematic()
    setPlayerAppearance(character)

    if config.useZoneSelectorOnCreate then
        exports[GetCurrentResourceName()]:showZoneMenu()
        return
    end

    SendNUIMessage({ action = 'hideInterface', data = {} })
    SetNuiFocus(false, false)
    lib.callback.await('jj_multicharacter:server:leaveInstance', false)
    func.playSkyDrop(config.creationSpawn)
    JJ.SetSpawned()
    TriggerEvent('jj_multicharacter:client:characterCreated')
end)

CreateThread(function()
    if JJ.IsLoaded() then return end
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            Wait(50)
            startLoadingCharacters()
            break
        end
    end
    while NetworkIsInTutorialSession() do
        SetEntityInvincible(PlayerPedId(), true)
        Wait(250)
    end
end)

local isTestingScene = false
local savedCoords = nil
local savedHeading = nil

RegisterNetEvent('jj_multicharacter:client:testScene', function(sceneIndex)
    local scenes = config.scenes
    if not scenes or #scenes == 0 then
        return lib.notify({
            title = 'Error',
            description = 'No hay escenas configuradas en config.scenes',
            type = 'error'
        })
    end

    if not sceneIndex and #scenes > 1 then
        local options = {}
        for i = 1, #scenes do
            options[#options + 1] = {
                title = ('Escena %d'):format(i),
                description = ('Cam Coords: %.2f, %.2f, %.2f'):format(scenes[i].camCoords.x, scenes[i].camCoords.y,
                    scenes[i].camCoords.z),
                icon = 'video',
                onSelect = function()
                    TriggerEvent('jj_multicharacter:client:testScene', i)
                end
            }
        end
        if isTestingScene then
            options[#options + 1] = {
                title = 'Detener prueba',
                description = 'Salir de la prueba de escena actual',
                icon = 'circle-stop',
                onSelect = function()
                    TriggerEvent('jj_multicharacter:client:stopScene')
                end
            }
        end

        lib.registerContext({
            id = 'multichar_test_scene_menu',
            title = 'Seleccionar Escena',
            options = options
        })
        return lib.showContext('multichar_test_scene_menu')
    end

    local index = tonumber(sceneIndex) or 1
    local scene = scenes[index]

    if not scene then
        return lib.notify({
            title = 'Error',
            description = ('La escena %d no existe. Hay %d escenas configuradas.'):format(index, #scenes),
            type = 'error'
        })
    end

    local ped = PlayerPedId()
    if not isTestingScene then
        savedCoords = GetEntityCoords(ped)
        savedHeading = GetEntityHeading(ped)
        isTestingScene = true
    end

    func.cleanDataPed()
    func.createCam(scene)

    if scene.npcModel and scene["npc"] then
        func.createSceneNpc(scene)
    end

    if scene["player"] then
        local pModel = GetEntityModel(ped)
        if not pModel or pModel == 0 then pModel = `mp_m_freemode_01` end

        local clothing = nil
        pcall(function()
            clothing = exports['illenium-appearance']:getPedAppearance(ped)
        end)

        func.createScenePed(pModel, scene, clothing, pModel == `mp_f_freemode_01` and 1 or 0)
    end

    lib.notify({
        title = 'Prueba de Escena',
        description = ('Viendo escena %d/%d. Usa /stop_scene para salir.'):format(index, #scenes),
        type = 'info',
        duration = 7500
    })
end)

RegisterNetEvent('jj_multicharacter:client:stopScene', function()
    if not isTestingScene then
        return lib.notify({
            title = 'Info',
            description = 'No estás probando ninguna escena en este momento.',
            type = 'info'
        })
    end

    func.cleanup()
    isTestingScene = false

    local ped = PlayerPedId()
    if savedCoords then
        SetEntityCoords(ped, savedCoords.x, savedCoords.y, savedCoords.z, false, false, false, false)
        if savedHeading then
            SetEntityHeading(ped, savedHeading)
        end
        savedCoords = nil
        savedHeading = nil
    end

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    lib.notify({
        title = 'Prueba Finalizada',
        description = 'Has salido de la prueba de escena.',
        type = 'success'
    })
end)
