local Zones = {}
local showZones = false
local panelOpen = false

-- Zonas para los jugadores: al entrar sale el texto del entorno

local function notifyZone(zone)
    lib.notify({
        title = zone.label,
        icon = 'fa-solid fa-map-location-dot',
        description = zone.entorno,
        duration = (zone.duration or 10) * 1000,
        iconColor = zone.color or '#9B30FF',
    })
end

local function CreatesPolyZones()
    local zonas = lib.callback.await('jj_entornozones:getAllZones', false) or {}

    for _, zone in pairs(Zones) do
        zone:remove()
    end
    Zones = {}

    for _, v in pairs(zonas) do
        local points = {}
        for i, point in ipairs(v.coords.points) do
            points[i] = vec3(point.x, point.y, point.z)
        end

        Zones[#Zones + 1] = lib.zones.poly({
            points = points,
            thickness = v.coords.thickness or 50.0,
            -- Con "Mostrar zonas" del panel, el administrador las ve dibujadas
            debug = showZones,
            onEnter = function()
                notifyZone(v)
            end,
        })
    end
end

RegisterNetEvent('jj_entornozones:client:loadZone', CreatesPolyZones)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        CreatesPolyZones()
    end
end)

-- Las zonas se cargan al aparecer con el personaje
AddEventHandler('jj:client:playerSpawned', function()
    Wait(1000)
    CreatesPolyZones()
end)

-- Panel de administración

local function openPanel(zones)
    panelOpen = true
    SendNUIMessage({ action = 'open', zones = zones, showZones = showZones })
    SetNuiFocus(true, true)
end

local function closePanel()
    panelOpen = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

RegisterNetEvent('jj_entornozones:client:openPanel', function()
    if panelOpen then return end

    local result = lib.callback.await('jj_entornozones:admin:list', false, {})
    if not result or result.error then
        return lib.notify({ description = result and result.error or 'No tienes permiso', type = 'error' })
    end
    openPanel(result.zones)
end)

RegisterNUICallback('close', function(_, cb)
    closePanel()
    cb({ success = true })
end)

local function adminAction(name)
    RegisterNUICallback(name, function(data, cb)
        local result = lib.callback.await('jj_entornozones:admin:' .. name, false, data)
        if not result or result.error then
            lib.notify({ description = result and result.error or 'No se ha podido guardar', type = 'error' })
            return cb({ success = false })
        end

        lib.notify({ description = name == 'delete' and 'Zona borrada' or 'Zona guardada', type = 'success' })
        cb({ success = true, zones = result.zones })
    end)
end

adminAction('save')
adminAction('delete')

-- Dibuja la zona con la cámara libre y la devuelve al panel, que sigue con lo que se estaba escribiendo
RegisterNUICallback('draw', function(_, cb)
    cb({ success = true })

    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)

    local zoneData = require 'client.zoneCreator'.polyCreator()
    local zone = nil
    if zoneData then
        local points = {}
        for i, point in ipairs(zoneData.points) do
            points[i] = { x = point.x, y = point.y, z = point.z }
        end
        zone = { points = points, thickness = zoneData.thickness }
    else
        lib.notify({ description = 'Zona cancelada: necesita al menos 3 puntos', type = 'error' })
    end

    SendNUIMessage({ action = 'drawn', zone = zone })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('preview', function(data, cb)
    cb({ success = true })
    notifyZone({ label = data.label ~= '' and data.label or nil, entorno = data.text, duration = tonumber(data.duration) or 10, color = data.color })
end)

-- Lleva al administrador al centro de la zona
RegisterNUICallback('teleport', function(data, cb)
    cb({ success = true })
    local points = data and data.points
    if type(points) ~= 'table' or #points == 0 then return end

    local x, y, z = 0.0, 0.0, -math.huge
    for _, point in ipairs(points) do
        x, y = x + point.x, y + point.y
        z = math.max(z, point.z)
    end

    closePanel()
    SetEntityCoords(cache.ped, x / #points, y / #points, z + 2.0, false, false, false, false)
end)

RegisterNUICallback('toggleZones', function(data, cb)
    showZones = data and data.show == true
    CreatesPolyZones()
    cb({ success = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and panelOpen then
        SetNuiFocus(false, false)
    end
end)
