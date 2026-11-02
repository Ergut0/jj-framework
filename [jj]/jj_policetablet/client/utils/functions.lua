local ANIM_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local PROP_MODEL = `prop_cs_tablet`
local tabletProp

local function startTabletAnim()
    lib.requestAnimDict(ANIM_DICT)
    lib.requestModel(PROP_MODEL)

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(PROP_MODEL, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(PROP_MODEL)
    TaskPlayAnim(ped, ANIM_DICT, 'base', 3.0, 3.0, -1, 49, 0, false, false, false)
end

local function stopTabletAnim()
    if tabletProp then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end

    StopAnimTask(cache.ped, ANIM_DICT, 'base', 1.0)
    RemoveAnimDict(ANIM_DICT)
end

local camera = false
local photo = false
local fov_max = 80.0
local fov_min = 5.0    -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0   -- speed by which the camera pans left-right
local speed_ud = 8.0   -- speed by which the camera pans up-down
local fov = (fov_max + fov_min) * 0.5

local cameraprop = nil
local photoprop = nil

local function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

local function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * (speed_ud) * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (speed_lr) * (zoomvalue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        -- Moves the entities body if they are not in a vehicle (else the whole vehicle will rotate as they look around :P)
        if not IsPedSittingInAnyVehicle(PlayerPedId()) then
            SetEntityHeading(PlayerPedId(), new_z)
        end
    end
end

local function HandleZoom(cam)
    local lPed = PlayerPedId()
    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0, 241) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 242) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
    else
        if IsControlJustPressed(0, 17) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 16) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
    end
end

local function SharedRequestAnimDict(animDict, cb)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)

        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(1)
        end
    end
    if cb ~= nil then
        cb()
    end
end

local function LoadPropDict(model)
    while not HasModelLoaded(GetHashKey(model)) do
        RequestModel(GetHashKey(model))
        Wait(10)
    end
end


local function cameraLoop()
    if not lib.callback.await('jj_policetablet:callback:canUseCamera', false) then
        Notify("No tienes permiso para hacer fotos con la tablet", "error")
        return nil
    end

    if GetResourceState('screenshot-basic') ~= 'started' then
        Notify("La cámara no está disponible: falta screenshot-basic", "error")
        return nil
    end

    local ped = PlayerPedId()
    camera = true
    local imageData = nil
    SendNUIMessage({ action = "closeTablet" })
    SetNuiFocus(false, false)

    SharedRequestAnimDict("amb@world_human_paparazzi@male@base", function()
        TaskPlayAnim(ped, "amb@world_human_paparazzi@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
    end)

    local x, y, z = table.unpack(GetEntityCoords(ped))


    local lPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(lPed)
    -- local uploadHookOrSecret = grabUploadDetails()
    Wait(500)

    SetTimecycleModifier("default")
    SetTimecycleModifierStrength(0.3)

    local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    AttachCamToEntity(cam, lPed, 0.0, 1.0, 0.8, true)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(lPed), 2)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)

    while camera and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == vehicle) do
        if IsControlJustPressed(0, 177) then
            camera = false
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            ClearPedTasks(lPed)
            if cameraprop then DeleteEntity(cameraprop) end
        elseif IsControlJustPressed(1, 176) then
            PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)

            local fmConfig = lib.callback.await('jj_policetablet:callback:getFivemanageConfig', false)
            if fmConfig and fmConfig.url and fmConfig.apiKey and fmConfig.apiKey ~= "" then
                local uploaded = false
                exports['screenshot-basic']:requestScreenshotUpload(fmConfig.url, "file", {
                    headers = {
                        Authorization = tostring(fmConfig.apiKey)
                    },
                    encoding = 'png'
                }, function(data)
                    local decoded = json.decode(data)
                    if decoded and decoded.status == "ok" and decoded.data then
                        imageData = decoded
                    else
                        print("^1[Error] Fivemanage upload failed: " .. tostring(data))
                    end
                    uploaded = true
                end)

                while not uploaded do
                    Wait(50)
                end
            end

            camera = false
            ClearPedTasks(lPed)
            Wait(100) -- You can adjust the timing if needed
            ClearTimecycleModifier()
            SetNuiFocus(true, true)
            SendNUIMessage({ action = "openTablet" })
        end

        local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
        CheckInputRotation(cam, zoomvalue)
        HandleZoom(cam)
        HideHUDThisFrame()
        Wait(0)
    end
    camera = false
    ClearTimecycleModifier()
    fov = (fov_max + fov_min) * 0.5
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
    return imageData
end


local function openTablet()
    if tabletProp then return end

    SendNUIMessage({ action = "openTablet" })
    startTabletAnim()
    SetNuiFocus(true, true)
end

local function closeTablet()
    SendNUIMessage({ action = "closeTablet" })
    stopTabletAnim()
    SetNuiFocus(false, false)
end

return {
    cameraLoop = cameraLoop,
    openTablet = openTablet,
    closeTablet = closeTablet,
    stopTabletAnim = stopTabletAnim,
}
