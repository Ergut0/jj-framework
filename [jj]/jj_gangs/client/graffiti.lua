local WALL_OFFSET = 0.02 -- Separación de la pared para que el dibujo no se mezcle con ella
local RAY_DISTANCE = 1000.0
local NEAR_REFRESH = 500
local TEXTURE_SIZE = 512
local TEXTURE_UNUSED_TIME = 60000 -- ms sin dibujarse hasta liberar una textura
local CONTROL_PLACE = 191 -- Enter
local CONTROL_CANCEL = 73 -- X

local PAGE_URL = ('nui://%s/html/graffiti.html'):format(GetCurrentResourceName())
-- La página tarda en cargar y los mensajes anteriores se pierden: se le repite por si acaso
local MESSAGE_DELAYS = { 300, 700, 1500, 2500 }

local SPRAY_ANIM = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_01_inspector', flags = 16 }
local ERASE_ANIM = { dict = 'amb@world_human_maid_clean@base', clip = 'base', flags = 16 }

-- Superficies donde no se puede pintar: cristal, vegetación, agua...
local FORBIDDEN_MATERIALS = {
    [1913209870] = true, [-1595148316] = true, [510490462] = true, [909950165] = true, [-1907520769] = true,
    [-1136057692] = true, [509508168] = true, [1288448767] = true, [-786060715] = true, [-1931024423] = true,
    [-1937569590] = true, [-878560889] = true, [1619704960] = true, [1550304810] = true, [951832588] = true,
    [2128369009] = true, [-356706482] = true, [1925605558] = true, [-1885547121] = true, [-1942898710] = true,
    [312396330] = true, [1635937914] = true, [-273490167] = true, [1109728704] = true, [223086562] = true,
    [1584636462] = true, [-461750719] = true, [1333033863] = true, [-1286696947] = true, [-1833527165] = true,
    [581794674] = true, [-913351839] = true, [-2041329971] = true, [-309121453] = true, [-1915425863] = true,
    [1429989756] = true, [673696729] = true, [244521486] = true, [435688960] = true, [-634481305] = true,
    [-1634184340] = true,
}

local Graffitis = {}
local blips = {}
local textures = {} -- [imagen o banda] = textura
local nearby = {}
local closest = nil
local showingPrompt = false

-- Texturas: una página web en memoria dibuja la imagen, o el nombre de la banda si no tiene imagen

local function getTextureContent(gang, url)
    if url and url ~= '' then
        return ('url:%s:%d:%s'):format(url, gang.id, gang.hex), { url = url, text = gang.label, color = gang.hex }
    end
    return ('tag:%d:%s:%s'):format(gang.id, gang.hex, gang.label), { text = gang.label, color = gang.hex }
end

local function getTexture(gang, url)
    local key, info = getTextureContent(gang, url)
    local texture = textures[key]
    if not texture then
        texture = { dui = lib.dui:new({ url = PAGE_URL, width = TEXTURE_SIZE, height = TEXTURE_SIZE }), ready = false }
        textures[key] = texture

        CreateThread(function()
            for _, delay in ipairs(MESSAGE_DELAYS) do
                Wait(delay)
                if texture.removed then return end
                texture.dui:sendMessage({ action = 'loadGraffiti', info = info })
                texture.ready = true
            end
        end)
    end

    texture.lastUsed = GetGameTimer()
    return texture.ready and texture or nil
end

local function removeUnusedTextures()
    local now = GetGameTimer()
    for key, texture in pairs(textures) do
        if now - (texture.lastUsed or 0) > TEXTURE_UNUSED_TIME then
            texture.removed = true
            texture.dui:remove()
            textures[key] = nil
        end
    end
end

-- Las cuatro esquinas del grafiti, vistas de frente a la pared
function BuildGraffitiQuad(graffiti)
    local halfWidth, halfHeight = Config.Graffiti.Width / 2, Config.Graffiti.Height / 2

    local length = math.sqrt(graffiti.nx ^ 2 + graffiti.ny ^ 2)
    local rightX, rightY = -graffiti.ny / length, graffiti.nx / length

    -- Vertical de la pared: perpendicular a la normal y a la derecha
    local upX = -graffiti.nz * rightY
    local upY = graffiti.nz * rightX
    local upZ = graffiti.nx * rightY - graffiti.ny * rightX

    local baseX = graffiti.x + graffiti.nx * WALL_OFFSET
    local baseY = graffiti.y + graffiti.ny * WALL_OFFSET
    local baseZ = graffiti.z + graffiti.nz * WALL_OFFSET

    local function corner(horizontal, vertical)
        return {
            x = baseX + rightX * horizontal + upX * vertical,
            y = baseY + rightY * horizontal + upY * vertical,
            z = baseZ + upZ * vertical,
        }
    end

    return {
        topLeft = corner(-halfWidth, halfHeight),
        topRight = corner(halfWidth, halfHeight),
        bottomRight = corner(halfWidth, -halfHeight),
        bottomLeft = corner(-halfWidth, -halfHeight),
    }
end

local function drawQuad(quad, texture, alpha)
    local tl, tr, br, bl = quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft
    DrawSpritePoly(br.x, br.y, br.z, tr.x, tr.y, tr.z, tl.x, tl.y, tl.z, 255, 255, 255, alpha, texture.dui.dictName, texture.dui.txtName,
        1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0)
    DrawSpritePoly(tl.x, tl.y, tl.z, bl.x, bl.y, bl.z, br.x, br.y, br.z, 255, 255, 255, alpha, texture.dui.dictName, texture.dui.txtName,
        0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0)
end

local function drawGraffiti(graffiti)
    local gang = PublicGangs[graffiti.gang_id]
    local texture = gang and getTexture(gang, graffiti.url)
    if texture then
        drawQuad(graffiti.quad, texture, 255)
    end
end

-- Círculo en el mapa con el color de la banda

local function removeBlip(id)
    if blips[id] then
        RemoveBlip(blips[id])
        blips[id] = nil
    end
end

local function createBlip(graffiti)
    removeBlip(graffiti.id)

    local gang = PublicGangs[graffiti.gang_id]
    if not gang then return end

    local blip = AddBlipForRadius(graffiti.x, graffiti.y, graffiti.z, Config.Graffiti.BlipRadius + 0.0)
    SetBlipColour(blip, gang.blip)
    SetBlipAlpha(blip, Config.Graffiti.BlipAlpha)
    blips[graffiti.id] = blip
end

-- Los colores de las bandas pueden llegar después que los grafitis, o cambiar
function RefreshGraffitiBlips()
    for _, graffiti in pairs(Graffitis) do
        createBlip(graffiti)
    end
end

-- Sincronización

local function addGraffiti(graffiti)
    graffiti.quad = BuildGraffitiQuad(graffiti)
    Graffitis[graffiti.id] = graffiti
    createBlip(graffiti)
end

RegisterNetEvent('jj_gangs:client:graffitis', function(list)
    for id in pairs(blips) do
        removeBlip(id)
    end
    Graffitis = {}
    for _, graffiti in ipairs(list) do
        addGraffiti(graffiti)
    end
end)

RegisterNetEvent('jj_gangs:client:addGraffiti', addGraffiti)

RegisterNetEvent('jj_gangs:client:removeGraffiti', function(id)
    Graffitis[id] = nil
    removeBlip(id)
end)

local function setPrompt(show)
    if show ~= showingPrompt then
        showingPrompt = show
        if show then
            lib.showTextUI('[E] - Borrar el grafiti')
        else
            lib.hideTextUI()
        end
    end
end

-- Elegir la pared

local function getCameraDirection()
    local rotation = GetGameplayCamRot(2)
    local z, x = math.rad(rotation.z), math.rad(rotation.x)
    local horizontal = math.abs(math.cos(x))
    return -math.sin(z) * horizontal, math.cos(z) * horizontal, math.sin(x)
end

local function castRay(startX, startY, startZ, dirX, dirY, dirZ)
    local handle = StartShapeTestRay(startX, startY, startZ, startX + dirX * RAY_DISTANCE, startY + dirY * RAY_DISTANCE, startZ + dirZ * RAY_DISTANCE, 1, cache.ped)
    local _, hit, coords, normal, material = GetShapeTestResultEx(handle)
    return hit == 1 or hit == true, coords, normal, material
end

local function isSameSurface(center, normal, coords, otherNormal)
    if math.abs(normal.x - otherNormal.x) >= 0.01 or math.abs(normal.y - otherNormal.y) >= 0.01 or math.abs(normal.z - otherNormal.z) >= 0.01 then
        return false
    end
    local offset = (coords.x - center.x) * normal.x + (coords.y - center.y) * normal.y + (coords.z - center.z) * normal.z
    return math.abs(offset) < 0.1
end

-- Devuelve la pared a la que apunta la cámara, si es lisa y está al lado del personaje. El rayo sale
-- de la cámara, que en tercera persona ya está a varios metros: la distancia se mide desde el personaje
local function findWall()
    local camera = GetGameplayCamCoord()
    local dirX, dirY, dirZ = getCameraDirection()

    local hit, coords, normal, material = castRay(camera.x, camera.y, camera.z, dirX, dirY, dirZ)
    if not hit or math.abs(normal.z) > 0.5 or FORBIDDEN_MATERIALS[material] then return nil end

    local ped = GetEntityCoords(cache.ped)
    local dx, dy, dz = coords.x - ped.x, coords.y - ped.y, coords.z - ped.z
    if math.sqrt(dx * dx + dy * dy + dz * dz) > Config.Graffiti.PlaceDistance then return nil end

    -- Rayos alrededor del central: la zona del grafiti tiene que ser una misma pared
    for _, offset in ipairs({ { 0.0, 0.0, 0.2 }, { 1.0, 0.0, 0.0 }, { -1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, -1.0, 0.0 } }) do
        local otherHit, otherCoords, otherNormal = castRay(camera.x + offset[1], camera.y + offset[2], camera.z + offset[3], dirX, dirY, dirZ)
        if not otherHit or not isSameSurface(coords, normal, otherCoords, otherNormal) then return nil end
    end

    return { x = coords.x, y = coords.y, z = coords.z, nx = normal.x, ny = normal.y, nz = normal.z }
end

-- Devuelve el sitio elegido, o nil si cancela
local function chooseSpot(url)
    local gang = PublicGangs[MyGang.id]
    local spot = nil
    local choosing = true

    lib.showTextUI('[Enter] - Colocar aquí  \n[X] - Cancelar')

    while choosing do
        spot = findWall()
        if spot then
            local texture = gang and getTexture(gang, url)
            if texture then
                drawQuad(BuildGraffitiQuad(spot), texture, 150)
            end
        end

        if spot and IsControlJustPressed(0, CONTROL_PLACE) then
            choosing = false
        elseif IsControlJustPressed(0, CONTROL_CANCEL) then
            spot = nil
            choosing = false
        end
        Wait(0)
    end

    lib.hideTextUI()
    return spot
end

-- Pintar

local function askForUrl()
    local input = lib.inputDialog('Pintar grafiti', {
        {
            type = 'input',
            label = 'URL de la imagen',
            description = 'Enlace directo a una imagen. Déjalo vacío para pintar el nombre de la banda',
            placeholder = 'https://i.imgur.com/ejemplo.png',
        },
    })
    if not input then return false end
    return true, input[1] or ''
end

local function paint()
    if not MyGang then
        Notify('No estás en ninguna banda', 'error')
        return
    end
    if IsBusy() or cache.vehicle then return end
    SetBusy(true)
    setPrompt(false) -- El aviso de borrar no puede tapar los controles de colocar

    local accepted, url = askForUrl()
    if not accepted then
        SetBusy(false)
        return
    end

    local reason = GetGraffitiUrlError(url)
    if reason then
        Notify(reason, 'error')
        SetBusy(false)
        return
    end

    local spot = chooseSpot(url)
    if not spot then
        SetBusy(false)
        return
    end

    spot.url = url
    local start = lib.callback.await('jj_gangs:server:startPaint', false, spot)
    if not start or not start.ok then
        Notify(start and start.message or 'No puedes pintar aquí', 'error')
        SetBusy(false)
        return
    end

    local completed = lib.progressBar({
        duration = start.time,
        label = 'Pintando el grafiti',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = SPRAY_ANIM,
    })

    if completed then
        local result = lib.callback.await('jj_gangs:server:finishPaint', false)
        if result and result.message then
            Notify(result.message, result.ok and 'success' or 'error')
        end
    else
        TriggerServerEvent('jj_gangs:server:cancelPaint')
    end
    SetBusy(false)
end

-- Si algo falla a medias, el jugador no se puede quedar marcado como ocupado para siempre
local function runSafely(action, ...)
    local ok, reason = pcall(action, ...)
    if not ok then
        print(('^1[jj_gangs] Error con el grafiti: %s^7'):format(reason))
        Notify('No se ha podido completar el grafiti', 'error')
        lib.hideTextUI()
        SetBusy(false)
    end
end

RegisterCommand('graffiti', function()
    Async(runSafely, paint)
end, false)

-- Borrar

local function erase(graffiti)
    if IsBusy() then return end
    SetBusy(true)

    local start = lib.callback.await('jj_gangs:server:startErase', false, graffiti.id)
    if not start or not start.ok then
        Notify(start and start.message or 'No puedes borrar este grafiti', 'error')
        SetBusy(false)
        return
    end

    local completed = lib.progressBar({
        duration = start.time,
        label = 'Borrando el grafiti',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = ERASE_ANIM,
    })

    if completed then
        local result = lib.callback.await('jj_gangs:server:finishErase', false)
        if result and result.message then
            Notify(result.message, result.ok and 'success' or 'error')
        end
    else
        TriggerServerEvent('jj_gangs:server:cancelErase')
    end
    SetBusy(false)
end

-- Dibujo: la lista de cercanos se actualiza cada poco y solo se dibujan esos

local function refreshNearby(coords)
    nearby = {}
    closest = nil
    local closestDistance = Config.Graffiti.InteractDistance

    for _, graffiti in pairs(Graffitis) do
        local dx, dy, dz = graffiti.x - coords.x, graffiti.y - coords.y, graffiti.z - coords.z
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        if distance <= Config.Graffiti.DrawDistance then
            nearby[#nearby + 1] = graffiti
        end
        if distance <= closestDistance then
            closest = graffiti
            closestDistance = distance
        end
    end
end

CreateThread(function()
    local nextRefresh = 0
    while true do
        local now = GetGameTimer()
        if now >= nextRefresh then
            nextRefresh = now + NEAR_REFRESH
            refreshNearby(GetEntityCoords(cache.ped))
            removeUnusedTextures()
        end

        for _, graffiti in ipairs(nearby) do
            drawGraffiti(graffiti)
        end

        local canErase = closest ~= nil and Graffitis[closest.id] ~= nil and MyGang ~= nil
            and not cache.vehicle and not IsBusy() and not IsNuiFocused()
        setPrompt(canErase)
        if canErase and IsControlJustPressed(0, 38) then
            setPrompt(false)
            Async(runSafely, erase, closest)
        end

        Wait(#nearby > 0 and 0 or NEAR_REFRESH)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    setPrompt(false)
    for _, texture in pairs(textures) do
        texture.removed = true
        texture.dui:remove()
    end
end)
