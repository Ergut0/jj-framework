-- Blips de la zona y de la entrega, e indicador en pantalla. Todo se borra al terminar el contrato
local zoneBlip, zoneArea, dropBlip, dropPoint
local dropTextShown = false
local MARKER_DISTANCE = 80.0

local function removeZone()
    if zoneBlip then RemoveBlip(zoneBlip) end
    if zoneArea then RemoveBlip(zoneArea) end
    zoneBlip, zoneArea = nil, nil
end

local function removeDropoff()
    if dropBlip then RemoveBlip(dropBlip) end
    if dropPoint then dropPoint:remove() end
    if dropTextShown then lib.hideTextUI() end
    dropBlip, dropPoint, dropTextShown = nil, nil, false
end

local function showZone(zone)
    if zoneBlip then return end

    zoneArea = AddBlipForRadius(zone.x, zone.y, zone.z, zone.radius)
    SetBlipColour(zoneArea, 27)
    SetBlipAlpha(zoneArea, 110)

    zoneBlip = AddBlipForCoord(zone.x, zone.y, zone.z)
    SetBlipSprite(zoneBlip, 225)
    SetBlipColour(zoneBlip, 27)
    SetBlipRoute(zoneBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(zone.label)
    EndTextCommandSetBlipName(zoneBlip)
end

local function deliver()
    local result = Boosting.Call('deliver')
    if result and not result.ok then Boosting.Notify(result.message, 'error') end
end

local function showDropoff(dropoff)
    if dropBlip then return end

    dropBlip = AddBlipForCoord(dropoff.x, dropoff.y, dropoff.z)
    SetBlipSprite(dropBlip, 38)
    SetBlipColour(dropBlip, 27)
    SetBlipScale(dropBlip, 1.0)
    SetBlipRoute(dropBlip, true)
    SetBlipRouteColour(dropBlip, 27)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(dropoff.label)
    EndTextCommandSetBlipName(dropBlip)

    local setText = function(show)
        if show == dropTextShown then return end
        dropTextShown = show
        if show then lib.showTextUI('[E] Entregar el vehículo') else lib.hideTextUI() end
    end

    dropPoint = lib.points.new({
        coords = vector3(dropoff.x, dropoff.y, dropoff.z),
        distance = math.max(MARKER_DISTANCE, dropoff.radius),
        onExit = function() setText(false) end,
        nearby = function(self)
            DrawMarker(1, dropoff.x, dropoff.y, dropoff.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, dropoff.radius * 2.0, dropoff.radius * 2.0, 1.5, 147, 51, 234, 90, false, false, 2, false, nil, nil, false)

            local inside = self.currentDistance <= dropoff.radius
            setText(inside)
            if inside and IsControlJustPressed(0, 38) then deliver() end
        end,
    })
end

RegisterNetEvent('jj_boosting:client:contract', function(contract)
    Boosting.contract = contract
    SendNUIMessage({ action = 'hud', contract = contract, trackerKey = Config.Tracker.key })
    SendNUIMessage({ action = 'refresh' })

    if not contract then
        removeZone()
        removeDropoff()
        Boosting.OnVehicle(nil)
        return
    end

    if contract.status == Boost.Status.SEARCHING then
        showZone(contract.zone)
    elseif contract.status == Boost.Status.LOCATED then
        -- La zona se queda en el mapa, pero deja de guiar: el vehículo hay que encontrarlo a pie de calle
        showZone(contract.zone)
        SetBlipRoute(zoneBlip, false)
        Boosting.OnVehicle(contract)
    elseif contract.status == Boost.Status.STOLEN then
        removeZone()
        showDropoff(contract.dropoff)
        Boosting.OnVehicle(contract)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    removeZone()
    removeDropoff()
end)
