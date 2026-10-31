local func = lib.load('client.animations')
local config = lib.load('shared.cfg')

local previewCam = nil
local previewData = {
    target = nil,
    animStart = 0,
    animDuration = 1800,
    phase = 'idle',
    baseHeight = 55.0,
    threadRunning = false,
    breatheStart = 0,
}

local function destroyPreviewCam()
    if previewCam then
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
        previewCam = nil
        RenderScriptCams(false, false, 500, true, true)
    end
    previewData.phase = 'idle'
    previewData.threadRunning = false
end

local findZoneById = function(zoneId)
    for id, data in pairs(config.zonesSpawn) do
        if id == zoneId then
            return data
        end
    end
    return nil
end

local function previewSpawnLocation(locId)
    local data = findZoneById(locId)
    if not data then return end
    local c = data.coords

    func.fadeScreen(true)
    Wait(500)
    destroyPreviewCam()
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), c.x, c.y, c.z)
    SetEntityVisible(PlayerPedId(), false, 0)

    local dist       = data.previewDist or 42.0
    local height     = data.previewHeight or 18.0
    local pitch      = data.previewPitch or -8.0
    local fov        = data.previewFov or 82.0
    local sideOffset = data.previewSideOffset or 14.0

    local heading    = c.w or 0.0
    local rad        = math.rad(heading)
    local camX       = c.x - math.sin(rad) * dist + math.cos(rad) * sideOffset
    local camY       = c.y + math.cos(rad) * dist + math.sin(rad) * sideOffset
    local camZ       = c.z + height

    previewCam       = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camX, camY, camZ, pitch, 0.0, heading + 180.0, fov,
        false, 0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, true, true)
    PointCamAtCoord(previewCam, c.x, c.y, c.z + 1.0)
    previewData.phase = 'idle'
    previewData.threadRunning = false
    func.fadeScreen(false)
end

local function finalizeSpawn(zoneId)
    local zoneData = findZoneById(zoneId)
    if not zoneData then return end
    SendNUIMessage({ action = 'hideInterface', data = {} })
    SetNuiFocus(false, false)
    destroyPreviewCam()
    lib.callback.await('jj_multicharacter:server:leaveInstance', false)
    func.playSkyDrop(zoneData.coords)
    if not JJ.IsSpawned() then
        JJ.SetSpawned()
        TriggerEvent('jj_multicharacter:client:characterCreated')
    end
end

local function showZoneMenu()
    previewSpawnLocation(1)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showZonesSelector', data = {} })
end

exports('showZoneMenu', showZoneMenu)

RegisterNuiCallback('spawnZone', function(data, cb)
    local zoneId = data.zoneId
    cb('ok')
    finalizeSpawn(zoneId)
end)

RegisterNuiCallback('selectZonePreview', function(data, cb)
    local zoneId = data.zoneId
    previewSpawnLocation(zoneId)
    cb('ok')
end)
