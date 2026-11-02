local Placement = {}
local DataView = require 'modules.placement.dataview'

local active = false
local gizmoActive = false
local cursorActive = false
local currentMode = 'Translate'
local isRelative = false
local currentEntity
local YAW_STEP = 2.0
local Z_STEP = 0.01
local MAX_DISTANCE = 8.0

local function raycastFromCamera()
    local ped = cache.ped
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local rotRad = vec3(math.rad(camRot.x), math.rad(camRot.y), math.rad(camRot.z))
    local direction = vec3(
        -math.sin(rotRad.z) * math.abs(math.cos(rotRad.x)),
         math.cos(rotRad.z) * math.abs(math.cos(rotRad.x)),
         math.sin(rotRad.x)
    )

    local destination = camCoords + direction * MAX_DISTANCE
    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, -1, ped, 0)
    local _, hit, endCoords = GetShapeTestResult(ray)

    if hit == 1 then
        return endCoords
    end

    return destination
end

local function pushHud(payload)
    SendNUIMessage({ action = 'setPlacementHud', data = payload })
end

local function showHud(label, controls)
    pushHud({
        visible = true,
        label = label or '',
        controls = controls or {
            { key = 'LMB',    action = 'Place' },
            { key = 'Q',      action = 'Rotate L' },
            { key = 'E',      action = 'Rotate R' },
            { key = 'Scroll', action = 'Height' },
            { key = 'R',      action = 'Reset' },
            { key = 'RMB',    action = 'Cancel' },
        },
    })
end

local function hideHud()
    pushHud({ visible = false })
end

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)

    if length == 0 then
        return 0, 0, 0
    end

    return x / length, y / length, z / length
end

local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = DataView.ArrayBuffer(60)

    view:SetFloat32(0, r[1])
        :SetFloat32(4, r[2])
        :SetFloat32(8, r[3])
        :SetFloat32(12, 0)
        :SetFloat32(16, f[1])
        :SetFloat32(20, f[2])
        :SetFloat32(24, f[3])
        :SetFloat32(28, 0)
        :SetFloat32(32, u[1])
        :SetFloat32(36, u[2])
        :SetFloat32(40, u[3])
        :SetFloat32(44, 0)
        :SetFloat32(48, a[1])
        :SetFloat32(52, a[2])
        :SetFloat32(56, a[3])
        :SetFloat32(60, 1)

    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0), view:GetFloat32(4), view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)

    x1, y1, z1 = normalize(x1, y1, z1)
    x2, y2, z2 = normalize(x2, y2, z2)
    x3, y3, z3 = normalize(x3, y3, z3)

    SetEntityMatrix(entity,
        x1, y1, z1,
        x2, y2, z2,
        x3, y3, z3,
        tx, ty, tz
    )
end

local function prepareEntity(entity)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityAlpha(entity, 150, false)
end

local function finishEntity(entity)
    if not DoesEntityExist(entity) then return end

    SetEntityAlpha(entity, 255, false)
    SetEntityDrawOutline(entity, false)
end

local function useCameraPlacement(entity, label)
    local heading = GetEntityHeading(entity)
    local zOffset = 0.0
    local cancelled = false

    showHud(label)

    while DoesEntityExist(entity) and not cancelled do
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)

        local target = raycastFromCamera()
        local groundOk, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z + 1.5, false)
        local placeZ = groundOk and groundZ or target.z
        SetEntityCoords(entity, target.x, target.y, placeZ + zOffset, false, false, false, false)
        SetEntityHeading(entity, heading)

        if IsDisabledControlJustReleased(0, 24) then
            break
        end

        if IsDisabledControlJustReleased(0, 25) or IsControlJustReleased(0, 200) or IsControlJustReleased(0, 202) then
            cancelled = true
            break
        end

        if IsControlPressed(0, 44) then
            heading = (heading + YAW_STEP) % 360.0
        elseif IsControlPressed(0, 38) then
            heading = (heading - YAW_STEP) % 360.0
        end

        if IsControlJustPressed(0, 45) then
            heading = GetEntityHeading(cache.ped)
            zOffset = 0.0
        end

        if IsControlJustPressed(0, 241) then
            zOffset = zOffset + Z_STEP * 5
        elseif IsControlJustPressed(0, 242) then
            zOffset = zOffset - Z_STEP * 5
        end

        Wait(0)
    end

    return not cancelled
end

local function useDrawGizmoPlacement(entity, label)
    local confirmed = false
    local cancelled = false

    currentEntity = entity
    currentMode = 'Translate'
    isRelative = false
    cursorActive = true
    gizmoActive = true

    EnterCursorMode()
    SetEntityDrawOutline(entity, true)

    showHud(label, {
        { key = 'ENTER', action = 'Place' },
        { key = 'W',     action = 'Move' },
        { key = 'R',     action = 'Rotate' },
        { key = 'Q',     action = 'World/Local' },
        { key = 'LALT',  action = 'Ground' },
        { key = 'G',     action = 'Cursor' },
        { key = 'RMB',   action = 'Cancel' },
    })

    while gizmoActive and DoesEntityExist(entity) do
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
        DisablePlayerFiring(cache.playerId, true)

        if IsDisabledControlJustReleased(0, 25) or IsControlJustReleased(0, 200) or IsControlJustReleased(0, 202) then
            cancelled = true
            break
        end

        if IsControlJustReleased(0, 191) then
            confirmed = true
            break
        end

        local matrixBuffer = makeEntityMatrix(entity)
        local changed = Citizen.InvokeNative(0xEB2EDCA2, matrixBuffer:Buffer(), 'OxInventoryPlacement', Citizen.ReturnResultAnyway())

        if changed then
            applyEntityMatrix(entity, matrixBuffer)
        end

        Wait(0)
    end

    gizmoActive = false
    cursorActive = false
    currentEntity = nil
    LeaveCursorMode()

    return confirmed and not cancelled
end

---@param entity number
---@param label? string Optional label shown in the placement HUD (item/bench name).
function Placement.useGizmo(entity, label)
    if active then return end
    if not DoesEntityExist(entity) then return end

    active = true

    prepareEntity(entity)

    local mode = client.placementmode == 'gizmo' and 'gizmo' or 'camera'
    local confirmed = mode == 'gizmo'
        and useDrawGizmoPlacement(entity, label)
        or useCameraPlacement(entity, label)

    hideHud()
    active = false
    finishEntity(entity)

    if not confirmed then
        if DoesEntityExist(entity) then
            DeleteObject(entity)
        end
    end

    return confirmed
end

lib.addKeybind({
    name = 'ox_inventory_gizmo_select',
    description = 'Select placement gizmo',
    defaultMapper = 'MOUSE_BUTTON',
    defaultKey = 'MOUSE_LEFT',
    onPressed = function()
        if gizmoActive then ExecuteCommand('+gizmoSelect') end
    end,
    onReleased = function()
        if gizmoActive then ExecuteCommand('-gizmoSelect') end
    end
})

lib.addKeybind({
    name = 'ox_inventory_gizmo_translation',
    description = 'Placement gizmo move mode',
    defaultKey = 'W',
    onPressed = function()
        if not gizmoActive then return end
        currentMode = 'Translate'
        ExecuteCommand('+gizmoTranslation')
    end,
    onReleased = function()
        if gizmoActive then ExecuteCommand('-gizmoTranslation') end
    end
})

lib.addKeybind({
    name = 'ox_inventory_gizmo_rotation',
    description = 'Placement gizmo rotate mode',
    defaultKey = 'R',
    onPressed = function()
        if not gizmoActive then return end
        currentMode = 'Rotate'
        ExecuteCommand('+gizmoRotation')
    end,
    onReleased = function()
        if gizmoActive then ExecuteCommand('-gizmoRotation') end
    end
})

lib.addKeybind({
    name = 'ox_inventory_gizmo_local',
    description = 'Placement gizmo local/world mode',
    defaultKey = 'Q',
    onPressed = function()
        if not gizmoActive then return end
        isRelative = not isRelative
        ExecuteCommand('+gizmoLocal')
    end,
    onReleased = function()
        if gizmoActive then ExecuteCommand('-gizmoLocal') end
    end
})

lib.addKeybind({
    name = 'ox_inventory_gizmo_cursor',
    description = 'Toggle placement gizmo cursor',
    defaultKey = 'G',
    onPressed = function()
        if not gizmoActive then return end

        if cursorActive then
            LeaveCursorMode()
        else
            EnterCursorMode()
        end

        cursorActive = not cursorActive
    end,
})

lib.addKeybind({
    name = 'ox_inventory_gizmo_ground',
    description = 'Snap placement object to ground',
    defaultKey = 'LMENU',
    onPressed = function()
        if gizmoActive and currentEntity and DoesEntityExist(currentEntity) then
            PlaceObjectOnGroundProperly_2(currentEntity)
        end
    end,
})

exports('useGizmo', Placement.useGizmo)

return Placement
