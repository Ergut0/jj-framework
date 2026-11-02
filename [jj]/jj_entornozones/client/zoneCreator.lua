local glm = require 'glm'
local Freecam = exports['fivem-freecam']

local DEBUG_COLOUR = {r = 255, g = 0, b = 0, a = 150}
local DEFAULT_HEIGHT = 5
local CURSOR_COLOUR = {r = 0, g = 255, b = 0, a = 255}
local CURSOR_DELETE_COLOUR = {r = 255, g = 0, b = 0, a = 255}
local MAX_CURSOR_DISTANCE = 10
local POINTS_PADDING = 0.25

local zoneCreator = {
    active = false,
    polygon = {},
    height = DEFAULT_HEIGHT,

    deleteIndex = nil,
    cursor = nil,
    camPosition = nil,
    camRotation = nil,

    highestPoint = nil,
    lowestPoint = nil
}

local polyText = '[C] - Añadir/Quitar punto  \n [G] Finalizar  \n [Retroceso] Cancelar  \n [Scroll] Cambiar altura \n [K] Editar punto'

local function render()
    local points = zoneCreator.polygon

    local DrawLine, IsDisabledControlJustPressed, vec3 = DrawLine, IsDisabledControlJustPressed, vec3

    while zoneCreator.active do
        Wait(0)

        zoneCreator.cursor = zoneCreator.drawCursor()
        local height =  #points > 0 and points[1].z + zoneCreator.height or 0
        local base_z = (#points > 0) and (points[1].z - 2) or 0

        if zoneCreator.highestPoint and #points > 0 then
            height = zoneCreator.highestPoint.z + zoneCreator.height
        end

        for i = 1, #points do
            local point = points[i]
            local thickness = vec3(0, 0, zoneCreator.height / 2)
            local a = point + thickness
            local b = point
            local c = (points[i + 1] or points[1]) + thickness
            local d = (points[i + 1] or points[1])
            local isYellow = zoneCreator.editIndex == i
            DrawLine(a.x, a.y, height, b.x, b.y, b.z, DEBUG_COLOUR.r,  isYellow and 255 or DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  255)
            DrawLine(a.x, a.y, height, c.x, c.y, height, DEBUG_COLOUR.r,  isYellow and 255 or DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  255)
            DrawLine(b.x, b.y, b.z, d.x, d.y, d.z, DEBUG_COLOUR.r,  isYellow and 255 or DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  255)
            DrawPoly(a.x, a.y, height, b.x, b.y, b.z, c.x, c.y, height, DEBUG_COLOUR.r,  DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  DEBUG_COLOUR.a)
            DrawPoly(c.x, c.y, height, b.x, b.y, b.z, a.x, a.y, height, DEBUG_COLOUR.r,  DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  DEBUG_COLOUR.a)
            DrawPoly(b.x, b.y, b.z, c.x, c.y, height, d.x, d.y, d.z, DEBUG_COLOUR.r,  DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  DEBUG_COLOUR.a)
            DrawPoly(d.x, d.y, d.z, c.x, c.y, height, b.x, b.y, b.z, DEBUG_COLOUR.r,  DEBUG_COLOUR.g,  DEBUG_COLOUR.b,  DEBUG_COLOUR.a)
        end

        if IsDisabledControlJustPressed(0, 14) then -- H
            zoneCreator.height -= 0.5
        end

        if IsDisabledControlJustPressed(0, 15) then -- H
            zoneCreator.height += 0.5
        end

        if IsDisabledControlJustPressed(0, 58) then -- G
            for i = 1, #points do
                points[i] = vec3(points[i].x, points[i].y, base_z)
            end

            zoneCreator.destroy()
            return {
                points = points,
                -- Desde el suelo de la zona hasta la altura marcada con la rueda
                thickness = math.max(height - base_z, 2.0),
            }
        end

        if IsDisabledControlJustPressed(0, 177) then -- Retroceso
            zoneCreator.destroy()
            return nil
        end

        if IsDisabledControlJustPressed(0, 306) and zoneCreator.editIndex then -- N
            zoneCreator.editIndex = nil
            lib.hideTextUI()
            lib.showTextUI(polyText)
        end
    end
end

function zoneCreator.destroy()
    zoneCreator.active = false
    zoneCreator.freecamMode(false)
end

function zoneCreator.addPoint(point)
    if zoneCreator.editIndex then
        zoneCreator.polygon[zoneCreator.editIndex] = point
    else
        table.insert(zoneCreator.polygon, point)
    end

    if not zoneCreator.lowestPoint or not zoneCreator.highestPoint then
        zoneCreator.lowestPoint = point
        zoneCreator.highestPoint = point
        return
    end

    zoneCreator.lowestPoint = point.z < zoneCreator.lowestPoint.z and point or zoneCreator.lowestPoint
    zoneCreator.highestPoint = point.z > zoneCreator.highestPoint.z and point or zoneCreator.highestPoint
end

function zoneCreator.editPoint()
    if zoneCreator.editIndex and zoneCreator.cursor then
        zoneCreator.addPoint(zoneCreator.cursor)
        zoneCreator.editIndex = nil
        lib.hideTextUI()
        lib.showTextUI(polyText)
        return
    end

    if zoneCreator.deleteIndex then
        zoneCreator.editIndex = zoneCreator.deleteIndex

        lib.hideTextUI()
        lib.showTextUI('[K] - Establecer punto \n [N] - Cancelar establecimiento')
    else
        lib.notify({ description = 'Necesitas estar cerca de un punto', type = 'error' })
    end
end

function zoneCreator.removePoint()
    if not zoneCreator.deleteIndex then return end

    local deletedPoint = zoneCreator.polygon[zoneCreator.deleteIndex]

    local function updateExtremePoint(comparator, currentExtreme)
        if not currentExtreme or deletedPoint.z == currentExtreme.z then
            local newExtreme = nil
            for i = 1, #zoneCreator.polygon do
                if i ~= zoneCreator.deleteIndex then
                    if not newExtreme or comparator(zoneCreator.polygon[i].z, newExtreme.z) then
                        newExtreme = zoneCreator.polygon[i]
                    end
                end
            end
            return newExtreme
        end
        return currentExtreme
    end

    zoneCreator.highestPoint = updateExtremePoint(function(a, b) return a > b end, zoneCreator.highestPoint)
    zoneCreator.lowestPoint = updateExtremePoint(function(a, b) return a < b end, zoneCreator.lowestPoint)

    table.remove(zoneCreator.polygon, zoneCreator.deleteIndex)

    -- If we've removed all points, reset highest and lowest points
    if #zoneCreator.polygon == 0 then
        zoneCreator.highestPoint = nil
        zoneCreator.lowestPoint = nil
    end
end

local function tooCloseToExistingPoint(point)
    local points = zoneCreator.polygon
    for i = 1, #points do
        local checkPoint = points[i]
        if glm.distance(point, checkPoint) < POINTS_PADDING then
            return true, i
        end
    end
    return false, nil
end

local function rayCastGamePlayCamera(distance)
    local cameraRotation = zoneCreator.camRotation
	local cameraCoord = zoneCreator.camPosition
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local _, hit, endCoords, _, _ = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1,  0))
	return hit, endCoords
end

function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end


function zoneCreator.drawCursor()
    zoneCreator.camPosition = Freecam:GetPosition()
    zoneCreator.camRotation = Freecam:GetRotation()
    local hit, coords = rayCastGamePlayCamera(MAX_CURSOR_DISTANCE)

    if hit then
        local color = CURSOR_COLOUR

        local tooClose, existingIndex = tooCloseToExistingPoint(coords)
        if tooClose then
            zoneCreator.cursor = coords
            zoneCreator.deleteIndex = existingIndex
            color = CURSOR_DELETE_COLOUR
        else
            zoneCreator.deleteIndex = nil
        end

        local position = zoneCreator.camPosition

        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false)
    end

    return hit and coords or nil
end


function zoneCreator.freecamMode(bool)
    if bool then
        Freecam:SetActive(true)
        Freecam:SetKeyboardSetting('BASE_MOVE_MULTIPLIER', 0.1)
        Freecam:SetKeyboardSetting('FAST_MOVE_MULTIPLIER', 15)
        Freecam:SetKeyboardSetting('SLOW_MOVE_MULTIPLIER', 2)
        Freecam:SetFov(45.0)
    else
        Freecam:SetActive(false)
        Freecam:SetKeyboardSetting('BASE_MOVE_MULTIPLIER', 5)
        Freecam:SetKeyboardSetting('FAST_MOVE_MULTIPLIER', 10)
        Freecam:SetKeyboardSetting('SLOW_MOVE_MULTIPLIER', 10)
    end
end

RegisterCommand('+usePoint', function()
    if not zoneCreator.active then return end

    if not zoneCreator.cursor then return end

    if zoneCreator.deleteIndex then
        zoneCreator.removePoint()
    else
        zoneCreator.addPoint(zoneCreator.cursor)
    end
end, false)

RegisterCommand('+editPoint', function()
    if not zoneCreator.active then return end
    if not zoneCreator.cursor then return end


    zoneCreator.editPoint()

end, false)

-- Las teclas con + necesitan su comando con -, aunque no haga nada al soltarlas
RegisterCommand('-usePoint', function() end, false)
RegisterCommand('-editPoint', function() end, false)

RegisterKeyMapping('+editPoint', 'Zonas de entorno: editar punto', 'keyboard', 'k')
RegisterKeyMapping('+usePoint', 'Zonas de entorno: añadir o quitar punto', 'keyboard', 'c')

local function polyCreator()
    zoneCreator.freecamMode(false)
    Wait(100)

    lib.showTextUI(polyText)
    zoneCreator.active = true
    zoneCreator.polygon = {}
    zoneCreator.thickness = DEFAULT_HEIGHT
    zoneCreator.freecamMode(true)
    local result = render()
    lib.hideTextUI()
    return result and #result.points > 2 and result or nil
end

return {
    polyCreator = polyCreator
}