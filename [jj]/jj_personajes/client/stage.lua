-- El escenario: los personajes en fila y la cámara que viaja entre ellos
Stage = {}

local CAMERA_SPEED = 2.6
local cfg = Config.Stage

local spots = {}
local camera = nil
local running = false

local camPos, camLook, camFov
local targetPos, targetLook, targetFov

local radians = math.rad(cfg.center.w)
local forward = vector3(-math.sin(radians), math.cos(radians), 0.0)
-- Derecha vista desde la cámara, que mira a los personajes de frente
local screenRight = vector3(-math.cos(radians), -math.sin(radians), 0.0)
local center = vector3(cfg.center.x, cfg.center.y, cfg.center.z)

local function loadCollision(coords, timeout)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    RequestAdditionalCollisionAtCoord(coords.x, coords.y, coords.z)

    local limit = GetGameTimer() + timeout
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < limit do
        Wait(50)
    end
end

local function fade(out, time)
    if out then
        DoScreenFadeOut(time)
        while not IsScreenFadedOut() do Wait(0) end
    else
        DoScreenFadeIn(time)
    end
end

Stage.fade = fade

local function hidePlayer(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
end

local function playAnim(ped, animation, flag)
    if not animation or not DoesAnimDictExist(animation.dict) then return end
    if not pcall(lib.requestAnimDict, animation.dict) then return end

    TaskPlayAnim(ped, animation.dict, animation.anim, 8.0, -8.0, -1, flag, 0.0, false, false, false)
    RemoveAnimDict(animation.dict)
end

-- Aplica el aspecto guardado con illenium-appearance. Si no hay, usa la ropa básica de shared/config.lua
function Stage.applyAppearance(ped, skin, gender)
    if skin and GetResourceState('illenium-appearance') == 'started' then
        local ok = pcall(function()
            local appearance = type(skin) == 'string' and json.decode(skin) or skin
            exports['illenium-appearance']:setPedAppearance(ped, appearance)
        end)
        if ok then return end
    end

    SetPedDefaultComponentVariation(ped)
    for _, component in ipairs(Config.BaseOutfits[gender == 1 and 1 or 0].components) do
        SetPedComponentVariation(ped, component.component_id, component.drawable, component.texture, 0)
    end
end

local function removePed(spot)
    if spot.ped and DoesEntityExist(spot.ped) then
        DeleteEntity(spot.ped)
    end
    spot.ped = nil
end

local function spawnPed(spot, model)
    removePed(spot)

    -- Un modelo que ya no exista en el servidor no puede dejar sin personaje el escenario
    if not IsModelInCdimage(model) or not pcall(lib.requestModel, model) then
        model = Config.BaseOutfits[0].model
        lib.requestModel(model)
    end

    local coords = spot.coords
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, cfg.center.w, false, false)
    SetModelAsNoLongerNeeded(model)

    SetEntityHeading(ped, cfg.center.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityCollision(ped, false, false)

    spot.ped = ped
    return ped
end

function Stage.setCharacter(index, character)
    local spot = spots[index]
    if not spot then return end

    local ped = spawnPed(spot, character.model)
    Stage.applyAppearance(ped, character.skin, character.gender)
    playAnim(ped, cfg.idles[(index - 1) % #cfg.idles + 1], 1)
    spot.character = true
end

-- Hueco libre: una silueta translúcida
function Stage.setGhost(index, gender)
    local spot = spots[index]
    if not spot then return end

    local ped = spawnPed(spot, Config.BaseOutfits[gender == 1 and 1 or 0].model)
    SetPedDefaultComponentVariation(ped)
    SetEntityAlpha(ped, cfg.ghostAlpha, false)
    spot.character = false
end

-- Al crear un personaje, la silueta se vuelve sólida y cambia con lo que elige el jugador
function Stage.setDraft(index, gender)
    local spot = spots[index]
    if not spot then return end

    local ped = spawnPed(spot, Config.BaseOutfits[gender == 1 and 1 or 0].model)
    Stage.applyAppearance(ped, nil, gender)
    playAnim(ped, cfg.idles[1], 1)
end

local function setTarget(position, look, fov)
    targetPos, targetLook, targetFov = position, look, fov
    if not camPos then
        camPos, camLook, camFov = position, look, fov
    end
end

function Stage.overview()
    local total = #spots
    setTarget(
        center + forward * (3.5 + total * 0.9) + vector3(0.0, 0.0, 1.25),
        center + vector3(0.0, 0.0, 0.95),
        45.0
    )
end

function Stage.focus(index, greet)
    local spot = spots[index]
    if not spot then return end

    -- El personaje queda a la derecha para dejar sitio a su expediente
    local side = screenRight * 0.35
    setTarget(
        spot.coords - side + forward * 2.6 + vector3(0.0, 0.0, 0.95),
        spot.coords - side + vector3(0.0, 0.0, 0.85),
        38.0
    )

    if greet and spot.character and spot.ped then
        playAnim(spot.ped, cfg.greeting, 48)
    end
end

local function runCamera()
    local last = GetGameTimer()

    while running do
        local now = GetGameTimer()
        local step = 1.0 - math.exp(-(now - last) / 1000.0 * CAMERA_SPEED)
        last = now

        camPos = camPos + (targetPos - camPos) * step
        camLook = camLook + (targetLook - camLook) * step
        camFov = camFov + (targetFov - camFov) * step

        local width, height = GetActiveScreenResolution()
        local mouseX, mouseY = GetNuiCursorPosition()
        local offsetX = (mouseX / math.max(width, 1) - 0.5) * cfg.parallax
        local offsetY = (mouseY / math.max(height, 1) - 0.5) * cfg.parallax

        local position = camPos + screenRight * offsetX - vector3(0.0, 0.0, offsetY)
        SetCamCoord(camera, position.x, position.y, position.z)
        PointCamAtCoord(camera, camLook.x, camLook.y, camLook.z)
        SetCamFov(camera, camFov)

        Wait(0)
    end
end

-- total: huecos del jugador, que marcan cuántos sitios tiene la fila
function Stage.start(total)
    NetworkOverrideClockTime(cfg.hour, cfg.minute, 0)
    SetWeatherTypeNowPersist(cfg.weather)
    SetFocusPosAndVel(center.x, center.y, center.z, 0.0, 0.0, 0.0)

    -- El jugador espera oculto bajo el escenario, que es lo que obliga a cargarlo
    hidePlayer(center - vector3(0.0, 0.0, 25.0))
    loadCollision(center, 3000)

    spots = {}
    for index = 1, total do
        local coords = center + screenRight * ((index - (total + 1) / 2) * cfg.spacing)
        local found, ground = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
        -- Solo si el suelo encontrado es el del escenario y no la calle que hay debajo
        if found and math.abs(ground - coords.z) < 3.0 then
            coords = vector3(coords.x, coords.y, ground)
        end
        spots[index] = { coords = coords }
    end

    camPos = nil
    Stage.overview()
    camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    SetCamCoord(camera, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(camera, camLook.x, camLook.y, camLook.z)
    SetCamFov(camera, camFov)
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 0, true, true)

    running = true
    CreateThread(runCamera)
end

local function destroyCamera()
    running = false
    if camera then
        SetCamActive(camera, false)
        DestroyCam(camera, true)
        camera = nil
    end
end

-- Quita el escenario. La hora y el clima vuelven a ser los del servidor
function Stage.stop()
    destroyCamera()

    for _, spot in ipairs(spots) do
        removePed(spot)
    end
    spots = {}

    NetworkClearClockTimeOverride()
    ClearWeatherTypePersist()
    ClearFocus()
end

-- Llegada: la cámara baja desde el cielo hasta el personaje
function Stage.arrive(target)
    local ped = PlayerPedId()
    local heading = (target.w or target.heading or 0.0) + 0.0
    local x, y, z = target.x + 0.0, target.y + 0.0, target.z + 0.0

    destroyCamera()

    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, heading)
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, true)
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    loadCollision(vector3(x, y, z), 3000)

    local radiansHeading = math.rad(heading)
    local groundX = x + math.sin(radiansHeading) * 2.2
    local groundY = y - math.cos(radiansHeading) * 2.2

    local skyCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', x, y, z + Config.Arrival.height, -85.0, 0.0, heading, 60.0, false, 0)
    PointCamAtCoord(skyCam, x, y, z + 0.5)

    local groundCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', groundX, groundY, z + 1.1, 0.0, 0.0, heading, 55.0, false, 0)
    PointCamAtCoord(groundCam, x, y, z + 0.8)

    SetCamActive(skyCam, true)
    RenderScriptCams(true, false, 0, true, true)

    fade(false, 600)
    Wait(600)

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    SetCamActiveWithInterp(groundCam, skyCam, Config.Arrival.duration, 1, 1)
    Wait(Config.Arrival.duration)

    RenderScriptCams(false, false, 0, true, false)
    Wait(50)

    DestroyCam(skyCam, true)
    DestroyCam(groundCam, true)
    ClearFocus()

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
end
