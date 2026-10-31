local camera = nil
local sceneNpc, scenePlayer = nil, nil
local spawned_peds = {}
local sceneRandom = nil
local cinematicCamera = nil
local cinematicActive = false
local cinematicThread = nil


local function fadeScreen(bool)
    if bool then
        DoScreenFadeOut(500)
    else
        if IsScreenFadedOut() then
            DoScreenFadeIn(500)
            while not IsScreenFadedIn() do
                Wait(0)
            end
        end
    end
end

local function cleanDataPed()
    for i, ped in pairs(spawned_peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawned_peds = {}
    if sceneNpc then
        NetworkStopSynchronisedScene(sceneNpc)
        sceneNpc = nil
    end
    if scenePlayer then
        NetworkStopSynchronisedScene(scenePlayer)
        scenePlayer = nil
    end
end

local function createCam(config)
    local sceneCoords = config.player and config.player.coords or (config.npc and config.npc.coords)
    if not sceneCoords then return end
    local hiddenZ = sceneCoords.z - 30.0
    local ped = PlayerPedId()

    SetEntityCoords(ped, sceneCoords.x, sceneCoords.y, hiddenZ, false, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)

    RequestCollisionAtCoord(sceneCoords.x, sceneCoords.y, sceneCoords.z)
    RequestAdditionalCollisionAtCoord(sceneCoords.x, sceneCoords.y, sceneCoords.z)

    local loadTime = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - loadTime) < 2000 do
        Wait(50)
    end

    camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", config.camCoords.x, config.camCoords.y, config.camCoords.z,
        0.0, 0.0, config.camCoords.w, 20.00, false, 0)
    PointCamAtCoord(camera, sceneCoords.x, sceneCoords.y, sceneCoords.z + 0.55)
    SetCamActive(camera, true)
    RenderScriptCams(1, 0, 0, 1, 1)
    if config.effectCam then
        ShakeCam(camera, config.effectCam, 0.2)
    end
end

local function createSceneNpc(sceneRandom)
    local npcPed = sceneRandom.npcModel
    if not npcPed then return end
    lib.requestModel(npcPed)
    local nCoords = sceneRandom["npc"].coords
    local npcCreated = CreatePed(4, npcPed, nCoords.x, nCoords.y, nCoords.z, nCoords.w, false, false)
    SetModelAsNoLongerNeeded(npcPed)

    if not DoesEntityExist(npcCreated) then
        print('[jj_multicharacter] Error: Could not create NPC ped!')
        return
    end

    SetEntityHeading(npcCreated, nCoords.w)
    SetPedDefaultComponentVariation(npcCreated)
    SetEntityVisible(npcCreated, true, false)
    FreezeEntityPosition(npcCreated, true)
    SetBlockingOfNonTemporaryEvents(npcCreated, true)
    SetEntityInvincible(npcCreated, true)

    spawned_peds[#spawned_peds + 1] = npcCreated

    if sceneRandom["npc"].animDict and sceneRandom["npc"].animName then
        lib.requestAnimDict(sceneRandom["npc"].animDict)
        TaskPlayAnim(npcCreated, sceneRandom["npc"].animDict, sceneRandom["npc"].animName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end

    print('[jj_multicharacter] NPC scene created')
end

-- Aplica el aspecto guardado con illenium-appearance. Si no hay, usa la ropa básica de shared/cfg.lua
local function applyAppearance(ped, clothing, gender)
    if clothing and GetResourceState('illenium-appearance') == 'started' then
        local appearance = type(clothing) == 'string' and json.decode(clothing) or clothing
        local ok = pcall(function() exports['illenium-appearance']:setPedAppearance(ped, appearance) end)
        if ok then return end
    end

    local outfit = lib.load('shared.cfg').randomPeds[gender == 1 and 'female' or 'male']
    SetPedDefaultComponentVariation(ped)
    for _, component in ipairs(outfit.components) do
        SetPedComponentVariation(ped, component.component_id, component.drawable, component.texture, 0)
    end
    for _, prop in ipairs(outfit.props) do
        ClearPedProp(ped, prop.prop_id)
    end
end

local function createScenePed(model, sceneRandom, clothing, gender)
    if not model or model == 0 then model = `mp_m_freemode_01` end
    lib.requestModel(model)
    local pCoords = sceneRandom["player"].coords
    local myPedCreated = CreatePed(4, model, pCoords.x, pCoords.y, pCoords.z, pCoords.w, false, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(myPedCreated) then
        print('[jj_multicharacter] Error: Could not create player scene ped!')
        return
    end

    SetEntityHeading(myPedCreated, pCoords.w)
    SetPedDefaultComponentVariation(myPedCreated)
    SetEntityVisible(myPedCreated, true, false)
    FreezeEntityPosition(myPedCreated, true)
    SetBlockingOfNonTemporaryEvents(myPedCreated, true)
    SetEntityInvincible(myPedCreated, true)

    spawned_peds[#spawned_peds + 1] = myPedCreated

    applyAppearance(myPedCreated, clothing, gender)

    if sceneRandom["player"].animDict and sceneRandom["player"].animName then
        lib.requestAnimDict(sceneRandom["player"].animDict)
        TaskPlayAnim(myPedCreated, sceneRandom["player"].animDict, sceneRandom["player"].animName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end

    print('[jj_multicharacter] Player scene created')
end

local function cleanup()
    if sceneNpc then
        NetworkStopSynchronisedScene(sceneNpc)
        sceneNpc = nil
    end
    if scenePlayer then
        NetworkStopSynchronisedScene(scenePlayer)
        scenePlayer = nil
    end
    if camera then
        SetCamActive(camera, false)
        DestroyCam(camera, true)
        camera = nil
    end
    RenderScriptCams(false, false, 1, true, true)

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)

    for i, pedEntity in pairs(spawned_peds) do
        if DoesEntityExist(pedEntity) then
            DeleteEntity(pedEntity)
        end
    end
    spawned_peds = {}
    print("Cleanup done")
end

local function startCinematic(points)
    cinematicActive = true
    local config = lib.load('shared.cfg')
    local cinematicPoints = points or config.cinematicPoints

    if #cinematicPoints == 0 then
        print('[jj_multicharacter] No cinematic points configured')
        return
    end

    cinematicThread = CreateThread(function()
        local currentPoint = 1

        while cinematicActive do
            local point = cinematicPoints[currentPoint]

            DoScreenFadeOut(800)
            Wait(800)

            local camCoords = point.camCoords
            SetEntityCoords(cache.ped, camCoords.x, camCoords.y, camCoords.z, false, false, false, false)
            FreezeEntityPosition(cache.ped, true)
            SetEntityVisible(cache.ped, false, false)
            SetEntityInvincible(cache.ped, true)

            RequestCollisionAtCoord(camCoords.x, camCoords.y, camCoords.z)
            RequestAdditionalCollisionAtCoord(camCoords.x, camCoords.y, camCoords.z)

            local loadTime = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(cache.ped) and (GetGameTimer() - loadTime) < 3000 do
                Wait(50)
            end

            if cinematicCamera then
                DestroyCam(cinematicCamera, false)
            end

            local camRot = point.camRotation

            cinematicCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
                camCoords.x, camCoords.y, camCoords.z,
                camRot.x, camRot.y, camRot.z,
                point.fov, false, 0)

            SetCamActive(cinematicCamera, true)
            RenderScriptCams(true, false, 0, true, false)

            ShakeCam(cinematicCamera, "HAND_SHAKE", 0.08)

            DoScreenFadeIn(1500)
            Wait(1500)

            local startTime = GetGameTimer()
            local duration = point.duration - 2000

            local startRotation = point.camRotation
            local endRotation = point.camRotationEnd
            local startFov = point.fov
            local endFov = point.fovEnd

            while (GetGameTimer() - startTime) < duration and cinematicActive do
                local progress = (GetGameTimer() - startTime) / duration
                local easedProgress = progress < 0.5
                    and 2 * progress * progress
                    or 1 - math.pow(-2 * progress + 2, 2) / 2

                local currentRotX = startRotation.x + (endRotation.x - startRotation.x) * easedProgress
                local currentRotY = startRotation.y + (endRotation.y - startRotation.y) * easedProgress
                local currentRotZ = startRotation.z + (endRotation.z - startRotation.z) * easedProgress
                SetCamRot(cinematicCamera, currentRotX, currentRotY, currentRotZ, 2)

                local currentFov = startFov + (endFov - startFov) * easedProgress
                SetCamFov(cinematicCamera, currentFov)

                Wait(0)
            end

            currentPoint = currentPoint % #cinematicPoints + 1
        end
    end)
end

local function stopCinematic()
    cinematicActive = false

    if cinematicThread then
        cinematicThread = nil
    end

    if cinematicCamera then
        DoScreenFadeOut(500)
        Wait(500)
        SetCamActive(cinematicCamera, false)
        DestroyCam(cinematicCamera, true)
        cinematicCamera = nil
        RenderScriptCams(false, false, 0, true, false)
    end

    print('[jj_multicharacter] Cinematic stopped')
end

local function playSkyDrop(targetCoords)
    if not targetCoords then return end
    local ped = PlayerPedId()

    cleanDataPed()
    stopCinematic()

    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    local heading = targetCoords.w or GetEntityHeading(ped) or 0.0
    SetEntityHeading(ped, heading)
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, true)

    local skyHeight = 500.0
    local skyX = targetCoords.x
    local skyY = targetCoords.y
    local skyZ = targetCoords.z + skyHeight

    local rad = math.rad(heading)
    local dist = 2.2
    local groundCamX = targetCoords.x + (math.sin(rad) * dist)
    local groundCamY = targetCoords.y - (math.cos(rad) * dist)
    local groundCamZ = targetCoords.z + 1.1

    local skyCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", skyX, skyY, skyZ, -85.0, 0.0, heading, 60.0, false, 0)
    PointCamAtCoord(skyCam, targetCoords.x, targetCoords.y, targetCoords.z + 0.5)

    local groundCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", groundCamX, groundCamY, groundCamZ, 0.0, 0.0, heading, 55.0, false, 0)
    PointCamAtCoord(groundCam, targetCoords.x, targetCoords.y, targetCoords.z + 0.8)

    SetCamActive(skyCam, true)
    RenderScriptCams(true, false, 500, true, true)

    DoScreenFadeIn(600)
    Wait(600)

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    SetCamActiveWithInterp(groundCam, skyCam, 4500, 1, 1)
    Wait(4500)

    RenderScriptCams(false, false, 0, true, false)
    Wait(50)

    if camera then
        SetCamActive(camera, false)
        DestroyCam(camera, true)
        camera = nil
    end
    DestroyCam(skyCam, true)
    DestroyCam(groundCam, true)

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
end

return {
    cleanDataPed = cleanDataPed,
    fadeScreen = fadeScreen,
    createCam = createCam,
    createSceneNpc = createSceneNpc,
    createScenePed = createScenePed,
    applyAppearance = applyAppearance,
    cleanup = cleanup,
    startCinematic = startCinematic,
    stopCinematic = stopCinematic,
    playSkyDrop = playSkyDrop,
}
