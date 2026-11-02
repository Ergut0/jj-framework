-- Panel de administración: /bandas

local isOpen = false
local isPlacing = false

local function getPanelConfig()
    local pointTypes, labs, colors, ranks = {}, {}, {}, {}

    for value, definition in pairs(Config.PointTypes) do
        pointTypes[#pointTypes + 1] = { value = value, label = definition.label }
    end
    table.sort(pointTypes, function(a, b) return a.label < b.label end)

    for value, recipe in pairs(Config.Labs) do
        labs[#labs + 1] = { value = value, label = recipe.label }
    end
    table.sort(labs, function(a, b) return a.label < b.label end)

    for index, color in ipairs(Config.Colors) do
        colors[#colors + 1] = { value = index, label = color.label, hex = color.hex }
    end
    for rank = 0, Config.TopRank do
        ranks[#ranks + 1] = { value = rank, label = Config.Ranks[rank].name }
    end

    return {
        pointTypes = pointTypes, labs = labs, colors = colors, ranks = ranks,
        minRadius = Config.MinRadius, maxRadius = Config.MaxRadius, defaultRadius = Config.DefaultRadius,
        maxGraffitis = Config.Graffiti.MaxPerGang,
    }
end

local function showPanel(data)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data or {} })
end

local function hidePanel()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('bandas', function()
    if isOpen or isPlacing then return end
    Async(function()
        if lib.callback.await('jj_gangs:server:adminData', false) then
            showPanel()
        else
            Notify('No tienes permiso para usar este comando', 'error')
        end
    end)
end, false)

RegisterNUICallback('close', function(_, cb)
    hidePanel()
    cb('ok')
end)

RegisterNUICallback('getData', function(_, cb)
    local data = lib.callback.await('jj_gangs:server:adminData', false)
    if data then
        data.config = getPanelConfig()
    end
    cb(data or false)
end)

RegisterNUICallback('action', function(data, cb)
    local result = lib.callback.await('jj_gangs:server:admin', false, data.action, data.payload)
    cb(result or { ok = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('waypoint', function(data, cb)
    SetNewWaypoint(data.x + 0.0, data.y + 0.0)
    cb('ok')
end)

-- Modo colocar: el panel se oculta y el jugador va hasta el sitio. El servidor usa su posición real

local CANCEL_CONTROL = 177
local CONFIRM_CONTROL = 38

local function drawPlacementMarker(radius)
    local coords = GetEntityCoords(cache.ped)
    if radius then
        DrawMarker(1, coords.x, coords.y, coords.z - 30.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2.0, radius * 2.0, 90.0, 250, 204, 21, 70, false, false, 2, false, nil, nil, false)
    end
    DrawMarker(2, coords.x, coords.y, coords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.35, 0.35, 0.35, 250, 204, 21, 220, false, true, 2, false, nil, nil, false)
end

-- Devuelve true si el jugador confirma y false si cancela
local function waitForPlacement(label, radius)
    lib.showTextUI(('%s  \n[E] - Colocar aquí  \n[Retroceso] - Cancelar'):format(label))

    local confirmed = nil
    while confirmed == nil do
        DisableControlAction(0, 200, true) -- Evita el menú de pausa si cancela con Esc
        drawPlacementMarker(radius)
        if IsControlJustPressed(0, CONFIRM_CONTROL) then
            confirmed = true
        elseif IsControlJustPressed(0, CANCEL_CONTROL) or IsDisabledControlJustPressed(0, 200) then
            confirmed = false
        end
        Wait(0)
    end

    lib.hideTextUI()
    return confirmed
end

RegisterNUICallback('place', function(data, cb)
    cb('ok')
    if isPlacing then return end
    isPlacing = true
    hidePanel()

    local radius = data.payload and tonumber(data.payload.radius) or nil
    local confirmed = waitForPlacement(data.label or 'Elige el sitio', radius)
    local result = nil
    if confirmed then
        result = lib.callback.await('jj_gangs:server:admin', false, data.action, data.payload)
            or { ok = false, message = 'Sin respuesta del servidor' }
    end

    isPlacing = false
    showPanel({ result = result })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
    end
    if isPlacing then
        lib.hideTextUI()
    end
end)
