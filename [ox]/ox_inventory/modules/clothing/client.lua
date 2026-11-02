if not lib then
    return {}
end

local Clothing = {}
local ClothingConfig = lib.load('data.clothing') or {}

Clothing.config = ClothingConfig
Clothing.enabled = ClothingConfig.enabled == true and ClothingConfig.slots and
    (ClothingConfig.slots.male or ClothingConfig.slots.female) ~= nil
Clothing.slotOffset = ClothingConfig.slotOffset or 1200

local FEMALE_PED_HASH = GetHashKey('mp_f_freemode_01')

local function getGenderSlots()
    local ped = cache.ped
    if ped and ped ~= 0 and GetEntityModel(ped) == FEMALE_PED_HASH then
        return ClothingConfig.slots.female or ClothingConfig.slots.male or {}
    end
    return ClothingConfig.slots.male or ClothingConfig.slots.female or {}
end

local PREVIEW_SCREEN_X = 0.90
local PREVIEW_SCREEN_Y = 0.50
local PREVIEW_DISTANCE = 3.5

local previewPed
local previewEnabled = false
local appliedSlots = {}
local currentSlotItems = {}
local applyMetadata
local syncingFromPed = false

local function getAppearanceTargetPed()
    return cache.ped
end

local function getReservedSlot(slotId)
    return Clothing.slotOffset + slotId + 1
end

local function cloneSlot(slotData)
    return slotData and table.clone(slotData) or nil
end

local function cloneMetadata(metadata)
    return type(metadata) == 'table' and table.clone(metadata) or nil
end

local function getClothingSlot(metadata, slot)
    local clothingSlot = metadata and tonumber(metadata.clothingSlot)

    if clothingSlot ~= nil then
        return clothingSlot
    end

    if slot and slot > Clothing.slotOffset then
        return slot - Clothing.slotOffset - 1
    end
end

local function getDefinition(slotId)
    return getGenderSlots()[slotId]
end

local function getOrderedSlotIds(filter)
    local slots = getGenderSlots()
    local ordered = {}
    local visiting = {}
    local visited = {}

    local function visit(slotId)
        slotId = tonumber(slotId)
        if not slotId or visited[slotId] or visiting[slotId] then return end

        local definition = slots[slotId]
        if not definition then return end

        visiting[slotId] = true

        if type(definition.requires) == 'table' then
            for i = 1, #definition.requires do
                visit(definition.requires[i])
            end
        end

        visiting[slotId] = nil
        visited[slotId] = true

        if not filter or filter[slotId] then
            ordered[#ordered + 1] = slotId
        end
    end

    local slotIds = {}

    for slotId in pairs(slots) do
        local numericSlot = tonumber(slotId)

        if numericSlot ~= nil then
            slotIds[#slotIds + 1] = numericSlot
        end
    end

    table.sort(slotIds)

    for i = 1, #slotIds do
        visit(slotIds[i])
    end

    return ordered
end

local function matchesEmptyVariation(definition, drawable, texture)
    if not definition then
        return false
    end

    local empty = type(definition.empty) == 'table' and definition.empty or nil
    if not empty then
        return false
    end

    return tonumber(drawable) == tonumber(empty.drawable)
        and (tonumber(texture) or 0) == (tonumber(empty.texture) or 0)
end

local function metadataMatches(left, right)
    if type(left) ~= 'table' or type(right) ~= 'table' then
        return false
    end

    return tonumber(left.component) == tonumber(right.component)
        and tonumber(left.prop) == tonumber(right.prop)
        and tonumber(left.drawable) == tonumber(right.drawable)
        and tonumber(left.texture) == tonumber(right.texture)
end

local function slotHasItem(slotData)
    return type(slotData) == 'table' and slotData.name and type(slotData.metadata) == 'table'
end

local function requirementsMet(slotId)
    local definition = getDefinition(slotId)

    if not definition or type(definition.requires) ~= 'table' then
        return true
    end

    for i = 1, #definition.requires do
        local requiredSlotId = tonumber(definition.requires[i])

        if requiredSlotId ~= nil and not slotHasItem(currentSlotItems[requiredSlotId]) then
            return false
        end
    end

    return true
end

local function collectAffectedSlots(changedSlots)
    local affected = {}

    for slotId in pairs(changedSlots) do
        local numericSlot = tonumber(slotId)

        if numericSlot ~= nil and getDefinition(numericSlot) then
            affected[numericSlot] = true
        end
    end

    for slotId, definition in pairs(getGenderSlots()) do
        if type(definition.requires) == 'table' then
            for i = 1, #definition.requires do
                local requiredSlotId = tonumber(definition.requires[i])

                if requiredSlotId ~= nil and affected[requiredSlotId] then
                    local dependentSlotId = tonumber(slotId)

                    if dependentSlotId ~= nil then
                        affected[dependentSlotId] = true
                    end

                    break
                end
            end
        end
    end

    return affected
end

local function getPreviewWorldPos()
    local camPos = GetFinalRenderedCamCoord()
    local camRot = GetFinalRenderedCamRot(2)

    local rx = math.rad(camRot.x)
    local rz = math.rad(camRot.z)

    local fwdX = -math.sin(rz) * math.cos(rx)
    local fwdY = math.cos(rz) * math.cos(rx)
    local fwdZ = math.sin(rx)

    local rightX = math.cos(rz)
    local rightY = math.sin(rz)
    local rightZ = 0.0

    local upX = math.sin(rz) * math.sin(rx)
    local upY = -math.cos(rz) * math.sin(rx)
    local upZ = math.cos(rx)

    local fov = GetFinalRenderedCamFov()
    local aspect = 16.0 / 9.0
    local tanHalfFov = math.tan(math.rad(fov * 0.5))

    local offsetRight = (PREVIEW_SCREEN_X - 0.5) * 2.0 * tanHalfFov * aspect * PREVIEW_DISTANCE
    local offsetUp = -(PREVIEW_SCREEN_Y - 0.5) * 2.0 * tanHalfFov * PREVIEW_DISTANCE

    local worldX = camPos.x + fwdX * PREVIEW_DISTANCE + rightX * offsetRight + upX * offsetUp
    local worldY = camPos.y + fwdY * PREVIEW_DISTANCE + rightY * offsetRight + upY * offsetUp
    local worldZ = camPos.z + fwdZ * PREVIEW_DISTANCE + rightZ * offsetRight + upZ * offsetUp
    local heading = math.deg(math.atan(fwdX, -fwdY)) % 360.0

    return worldX, worldY, worldZ, heading
end

local function destroyPreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
    end

    previewPed = nil
end

local AppearanceBridge = lib.load('modules.clothing.appearance_bridge')

local function copyPlayerAppearanceToPreview(playerPed, targetPed)
    if not playerPed or playerPed == 0 or not targetPed or targetPed == 0 then return end

    local appearance = AppearanceBridge.getAppearance(playerPed)

    if appearance then
        AppearanceBridge.applyFullAppearance(targetPed, appearance)
    else
        ClonePedToTarget(playerPed, targetPed)
    end

    for componentId = 0, 11 do
        SetPedComponentVariation(
            targetPed,
            componentId,
            GetPedDrawableVariation(playerPed, componentId),
            GetPedTextureVariation(playerPed, componentId),
            0
        )
    end

    for propId = 0, 13 do
        local drawable = GetPedPropIndex(playerPed, propId)

        if drawable < 0 then
            ClearPedProp(targetPed, propId)
        else
            SetPedPropIndex(targetPed, propId, drawable, GetPedPropTextureIndex(playerPed, propId), false)
        end
    end
end

local function cloneCurrentPed()
    local playerPed = cache.ped
    if not playerPed or playerPed == 0 then return end

    destroyPreviewPed()

    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local model = GetEntityModel(playerPed)

    if not model or model == 0 then return end
    if not lib.requestModel(model) then return end

    local clonedPed = CreatePed(0, model, coords.x, coords.y, coords.z, heading, false, true)
    SetModelAsNoLongerNeeded(model)

    if not clonedPed or clonedPed == 0 or not DoesEntityExist(clonedPed) then return end

    SetEntityAsMissionEntity(clonedPed, true, true)
    SetEntityCoordsNoOffset(clonedPed, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(clonedPed, heading)
    copyPlayerAppearanceToPreview(playerPed, clonedPed)
    FreezeEntityPosition(clonedPed, true)
    SetEntityInvincible(clonedPed, true)
    SetEntityCollision(clonedPed, false, false)
    SetEntityHasGravity(clonedPed, false)
    SetBlockingOfNonTemporaryEvents(clonedPed, true)
    SetPedCanRagdoll(clonedPed, false)
    SetPedDiesWhenInjured(clonedPed, false)
    ClearPedTasksImmediately(clonedPed)
    TaskStandStill(clonedPed, -1)

    previewPed = clonedPed

    CreateThread(function()
        while previewEnabled and previewPed and DoesEntityExist(previewPed) do
            local wx, wy, wz, wh = getPreviewWorldPos()
            SetEntityCoordsNoOffset(previewPed, wx, wy, wz, false, false, false)
            SetEntityHeading(previewPed, wh)
            Wait(0)
        end
    end)
end

local function refreshPreviewPed()
    if not previewEnabled then return end

    if not previewPed or not DoesEntityExist(previewPed) then
        cloneCurrentPed()
        return
    end

    local playerPed = cache.ped
    if playerPed and playerPed ~= 0 then
        copyPlayerAppearanceToPreview(playerPed, previewPed)
    end
end

local function clothingAppearanceChanged(shouldSave)
    Clothing.pushAppearance()

    if shouldSave then
        local ped = cache.ped

        if ped and ped ~= 0 then
            AppearanceBridge.saveAppearance(ped)
        end
    end
end

local function findComponent(appearance, componentId)
    if not appearance or not appearance.components then return nil end
    for _, c in ipairs(appearance.components) do
        if c.component_id == componentId then return c end
    end
end

local function findProp(appearance, propId)
    if not appearance or not appearance.props then return nil end
    for _, p in ipairs(appearance.props) do
        if p.prop_id == propId then return p end
    end
end

local function getVariationForDefinition(definition)
    local ped = getAppearanceTargetPed()
    if not ped or ped == 0 or not definition then return end

    local appearance = AppearanceBridge.getAppearance(ped)

    if definition.prop ~= nil then
        local p = findProp(appearance, definition.prop)
        if p then return { drawable = p.drawable, texture = p.texture } end
        return {
            drawable = GetPedPropIndex(ped, definition.prop),
            texture = GetPedPropTextureIndex(ped, definition.prop),
        }
    end

    if definition.component ~= nil then
        local c = findComponent(appearance, definition.component)
        if c then return { drawable = c.drawable, texture = c.texture } end
        return {
            drawable = GetPedDrawableVariation(ped, definition.component),
            texture = GetPedTextureVariation(ped, definition.component),
        }
    end
end

local function stripDefinitionOnPed(ped, definition)
    if not ped or ped == 0 or not definition then return end

    local empty = type(definition.empty) == 'table' and definition.empty or {}
    local emptyDrawable = tonumber(empty.drawable)
    local emptyTexture = tonumber(empty.texture) or 0

    if definition.prop ~= nil then
        AppearanceBridge.setProp(ped, definition.prop, (emptyDrawable ~= nil and emptyDrawable >= 0) and emptyDrawable or -1, emptyTexture)
        return
    end

    if definition.component ~= nil then
        AppearanceBridge.setComponent(ped, definition.component, emptyDrawable or 0, emptyTexture)
    end
end

local function stripDefinition(definition)
    stripDefinitionOnPed(getAppearanceTargetPed(), definition)
end

local function stripMetadataOnPed(ped, metadata)
    if not ped or ped == 0 or type(metadata) ~= 'table' then return end

    local clothingSlot = tonumber(getClothingSlot(metadata))

    if clothingSlot ~= nil then
        stripDefinitionOnPed(ped, getDefinition(clothingSlot))
        return
    end

    local emptyDrawable = tonumber(metadata.emptyDrawable)
    local emptyTexture = tonumber(metadata.emptyTexture) or 0

    if metadata.prop ~= nil then
        AppearanceBridge.setProp(ped, metadata.prop, (emptyDrawable ~= nil and emptyDrawable >= 0) and emptyDrawable or -1, emptyTexture)
        return
    end

    if metadata.component ~= nil then
        AppearanceBridge.setComponent(ped, metadata.component, emptyDrawable or 0, emptyTexture)
    end
end

local function stripMetadata(metadata)
    stripMetadataOnPed(getAppearanceTargetPed(), metadata)
end

local function applyMetadataOnPed(ped, metadata)
    if not ped or ped == 0 or type(metadata) ~= 'table' then return end

    if metadata.prop ~= nil then
        if tonumber(metadata.drawable) == nil or tonumber(metadata.texture) == nil then return end
        AppearanceBridge.setProp(ped, metadata.prop, metadata.drawable, metadata.texture)
        return
    end

    if metadata.component ~= nil then
        if tonumber(metadata.drawable) == nil or tonumber(metadata.texture) == nil then return end
        AppearanceBridge.setComponent(ped, metadata.component, metadata.drawable, metadata.texture)
    end
end

local function syncTrackedSlot(slotId, slotData)
    if slotHasItem(slotData) and requirementsMet(slotId) then
        if metadataMatches(appliedSlots[slotId], slotData.metadata) then
            return false
        end

        applyMetadata(slotData.metadata)
        appliedSlots[slotId] = cloneMetadata(slotData.metadata)

        return true
    end

    if appliedSlots[slotId] == false then
        return false
    end

    stripDefinition(getDefinition(slotId))
    appliedSlots[slotId] = false
    return true
end

applyMetadata = function(metadata)
    applyMetadataOnPed(getAppearanceTargetPed(), metadata)
end

local function restoreMetadataOnPed(ped, metadata)
    if not ped or ped == 0 or type(metadata) ~= 'table' then return end

    if metadata.prop ~= nil then
        local previousDrawable = tonumber(metadata.previousDrawable)
        local previousTexture = tonumber(metadata.previousTexture) or 0
        AppearanceBridge.setProp(ped, metadata.prop, (previousDrawable ~= nil and previousDrawable >= 0) and previousDrawable or -1, previousTexture)
        return
    end

    if metadata.component ~= nil then
        local previousDrawable = tonumber(metadata.previousDrawable) or 0
        local previousTexture = tonumber(metadata.previousTexture) or 0
        AppearanceBridge.setComponent(ped, metadata.component, previousDrawable, previousTexture)
    end
end

local function restoreMetadata(metadata)
    restoreMetadataOnPed(getAppearanceTargetPed(), metadata)
end

local function refreshAppliedSlotsCache()
    local nextApplied = {}

    local slotIds = getOrderedSlotIds()

    for i = 1, #slotIds do
        local numericSlot = slotIds[i]

        if numericSlot ~= nil then
            local slotData = currentSlotItems[numericSlot]

            if slotHasItem(slotData) and requirementsMet(numericSlot) then
                nextApplied[numericSlot] = cloneMetadata(slotData.metadata)
            else
                nextApplied[numericSlot] = false
            end
        end
    end

    appliedSlots = nextApplied
end

local function applyCurrentSlotStateToPed(ped)
    if not ped or ped == 0 then return end

    local slotIds = getOrderedSlotIds()

    for i = 1, #slotIds do
        local numericSlot = slotIds[i]
        local definition = getDefinition(numericSlot)

        if numericSlot ~= nil then
            local slotData = currentSlotItems[numericSlot]

            if slotHasItem(slotData) and requirementsMet(numericSlot) then
                applyMetadataOnPed(ped, slotData.metadata)
            else
                stripDefinitionOnPed(ped, definition)
            end
        end
    end
end

local function getPedAppearanceSnapshot()
    local ped = getAppearanceTargetPed()

    if not Clothing.enabled or not ped or ped == 0 then
        return { components = {}, props = {} }
    end

    local snapshot = { components = {}, props = {} }
    local appearance = AppearanceBridge.getAppearance(ped)
    local seenComponents = {}
    local seenProps = {}

    for _, definition in pairs(getGenderSlots()) do
        local componentId = tonumber(definition.component)
        local propId = tonumber(definition.prop)

        if componentId and not seenComponents[componentId] then
            local c = findComponent(appearance, componentId)
            snapshot.components[tostring(componentId)] = {
                drawable = c and c.drawable or GetPedDrawableVariation(ped, componentId),
                texture  = c and c.texture  or GetPedTextureVariation(ped, componentId),
            }
            seenComponents[componentId] = true
        end

        if propId and not seenProps[propId] then
            local p = findProp(appearance, propId)
            snapshot.props[tostring(propId)] = {
                drawable = p and p.drawable or GetPedPropIndex(ped, propId),
                texture  = p and p.texture  or GetPedPropTextureIndex(ped, propId),
            }
            seenProps[propId] = true
        end
    end

    return snapshot
end

local function buildWornPieces()
    local ped = cache.ped
    local pieces = {}

    if not ped or ped == 0 then return pieces end

    local appearance = AppearanceBridge.getAppearance(ped)

    for slotId, definition in pairs(getGenderSlots()) do
        local itemName = definition.itemName or 'clothing'

        if definition.prop ~= nil then
            local p = findProp(appearance, definition.prop)
            local drawable = p and p.drawable or GetPedPropIndex(ped, definition.prop)
            local texture  = p and p.texture  or GetPedPropTextureIndex(ped, definition.prop)

            if drawable >= 0 and not matchesEmptyVariation(definition, drawable, texture) then
                pieces[#pieces + 1] = {
                    clothingSlot = tonumber(slotId),
                    itemName = itemName,
                    metadata = { prop = definition.prop, drawable = drawable, texture = texture },
                }
            end
        elseif definition.component ~= nil then
            local c = findComponent(appearance, definition.component)
            local drawable = c and c.drawable or GetPedDrawableVariation(ped, definition.component)
            local texture  = c and c.texture  or GetPedTextureVariation(ped, definition.component)
            local isEmpty = matchesEmptyVariation(definition, drawable, texture)

            if not isEmpty then
                pieces[#pieces + 1] = {
                    clothingSlot = tonumber(slotId),
                    itemName = itemName,
                    metadata = { component = definition.component, drawable = drawable, texture = texture },
                }
            end
        end
    end

    return pieces
end

function Clothing.collect(items)
    if not Clothing.enabled then
        return nil
    end

    local state = {
        offset = Clothing.slotOffset,
        items = {},
    }

    for slotId in pairs(getGenderSlots()) do
        local numericSlot = tonumber(slotId)
        if numericSlot ~= nil then
            state.items[numericSlot] = { slot = getReservedSlot(numericSlot) }
        end
    end

    if not items then
        return state
    end

    for slot, slotData in pairs(items) do
        if slotData and slotData.name then
            local clothingSlot = getClothingSlot(slotData.metadata, slot)

            if clothingSlot ~= nil and state.items[clothingSlot] ~= nil then
                state.items[clothingSlot] = cloneSlot(slotData)
            end
        end
    end

    for slotId, slotData in pairs(state.items) do
        currentSlotItems[slotId] = slotHasItem(slotData) and cloneSlot(slotData) or false
    end

    return state
end

function Clothing.getSlots()
    return getGenderSlots()
end

function Clothing.collectOther(items)
    if not Clothing.enabled then
        return nil
    end

    local state = {
        offset = Clothing.slotOffset,
        items = {},
    }

    for slotId in pairs(getGenderSlots()) do
        local numericSlot = tonumber(slotId)
        if numericSlot ~= nil then
            state.items[numericSlot] = { slot = getReservedSlot(numericSlot) }
        end
    end

    if not items then
        return state
    end

    for slot, slotData in pairs(items) do
        if slotData and slotData.name then
            local clothingSlot = getClothingSlot(slotData.metadata, slot)

            if clothingSlot ~= nil and state.items[clothingSlot] ~= nil then
                state.items[clothingSlot] = cloneSlot(slotData)
            end
        end
    end

    return state
end

function Clothing.getAppearanceSnapshot()
    return getPedAppearanceSnapshot()
end

function Clothing.getCurrentVariation(slotId)
    return getVariationForDefinition(getDefinition(tonumber(slotId)))
end

function Clothing.applyItem(itemMetadata)
    local clothingSlot = tonumber(getClothingSlot(itemMetadata))

    if clothingSlot ~= nil then
        currentSlotItems[clothingSlot] = {
            name = '__equipped__',
            metadata = cloneMetadata(itemMetadata),
            slot = getReservedSlot(clothingSlot),
        }

        local affectedSlots = collectAffectedSlots({ [clothingSlot] = true })
        local appearanceChanged = false

        local orderedAffectedSlots = getOrderedSlotIds(affectedSlots)

        for i = 1, #orderedAffectedSlots do
            local slotId = orderedAffectedSlots[i]

            if syncTrackedSlot(slotId, currentSlotItems[slotId]) then
                appearanceChanged = true
            end
        end

        if appearanceChanged then
            clothingAppearanceChanged(true)
        end

        return
    end

    applyMetadata(itemMetadata)
    clothingAppearanceChanged(true)
end

function Clothing.removeItem(itemMetadata)
    local clothingSlot = tonumber(getClothingSlot(itemMetadata))

    if clothingSlot ~= nil then
        currentSlotItems[clothingSlot] = false

        local affectedSlots = collectAffectedSlots({ [clothingSlot] = true })
        local appearanceChanged = false

        local orderedAffectedSlots = getOrderedSlotIds(affectedSlots)

        for i = 1, #orderedAffectedSlots do
            local slotId = orderedAffectedSlots[i]

            if syncTrackedSlot(slotId, currentSlotItems[slotId]) then
                appearanceChanged = true
            end
        end

        if appearanceChanged then
            clothingAppearanceChanged(true)
        end

        return
    end

    stripMetadata(itemMetadata)
    clothingAppearanceChanged(true)
end

function Clothing.syncSlotState(items, shouldSave)
    if not Clothing.enabled or type(items) ~= 'table' then return end

    local changedSlots = {}

    for slot, slotData in pairs(items) do
        local numericSlot = tonumber(slot)

        if type(slotData) == 'table' then
            numericSlot = tonumber(slotData.slot) or numericSlot
        end

        local clothingSlot

        if type(slotData) == 'table' then
            clothingSlot = getClothingSlot(slotData.metadata, numericSlot)
        end

        if clothingSlot == nil and numericSlot and numericSlot > Clothing.slotOffset then
            clothingSlot = numericSlot - Clothing.slotOffset - 1
        end

        clothingSlot = tonumber(clothingSlot)

        if clothingSlot ~= nil and getDefinition(clothingSlot) then
            currentSlotItems[clothingSlot] = slotHasItem(slotData) and cloneSlot(slotData) or false
            changedSlots[clothingSlot] = true
        end
    end

    if not next(changedSlots) then return end

    local affectedSlots = collectAffectedSlots(changedSlots)

    local appearanceChanged = false

    local orderedAffectedSlots = getOrderedSlotIds(affectedSlots)

    for i = 1, #orderedAffectedSlots do
        local slotId = orderedAffectedSlots[i]

        if syncTrackedSlot(slotId, currentSlotItems[slotId]) then
            appearanceChanged = true
        end
    end

    if appearanceChanged then
        clothingAppearanceChanged(shouldSave == true)
    end
end

function Clothing.applyCurrentSlotState()
    if not Clothing.enabled then return end

    applyCurrentSlotStateToPed(getAppearanceTargetPed())
    refreshAppliedSlotsCache()
    Clothing.pushAppearance()
end

function Clothing.pushAppearance()
    if not Clothing.enabled then return end

    refreshPreviewPed()

    SendNUIMessage({
        action = 'setClothingAppearance',
        data = getPedAppearanceSnapshot(),
    })
end

function Clothing.syncInventoryWithPed()
    if not Clothing.enabled then return end

    -- Lo que el servidor cambie aquí ya viene del personaje: no es un cambio de ropa desde el inventario
    syncingFromPed = true
    local ok, response = pcall(lib.callback.await, 'ox_inventory:syncClothingFromPed', false, buildWornPieces())
    syncingFromPed = false

    if not ok then response = nil end

    if not response then
        TriggerServerEvent('ox_inventory:syncClothing', buildWornPieces())
    end

    return response
end

function Clothing.getPedSignature()
    if not Clothing.enabled then return end

    local pieces = buildWornPieces()
    local signature = {}

    for i = 1, #pieces do
        local piece = pieces[i]
        local metadata = piece.metadata or {}

        signature[#signature + 1] = ('%s:%s:%s:%s:%s'):format(
            piece.clothingSlot or '',
            piece.itemName or '',
            metadata.component or metadata.prop or '',
            metadata.drawable or '',
            metadata.texture or ''
        )
    end

    table.sort(signature)

    return table.concat(signature, '|')
end

function Clothing.waitForAppearance(timeout)
    if not Clothing.enabled then return end

    local timeoutAt = GetGameTimer() + (timeout or 5000)
    local previousSignature
    local stableCount = 0

    repeat
        Wait(250)

        local signature = Clothing.getPedSignature()

        if signature and signature == previousSignature then
            stableCount += 1
        else
            previousSignature = signature
            stableCount = 0
        end

        if stableCount >= 2 then
            return
        end
    until GetGameTimer() >= timeoutAt
end

function Clothing.setPreviewTarget(target)
    if type(target) ~= 'table' then return end

    local targetX = tonumber(target.x)
    local targetY = tonumber(target.y)

    if targetX then
        PREVIEW_SCREEN_X = math.max(0.05, math.min(0.95, targetX))
    end

    if targetY then
        PREVIEW_SCREEN_Y = math.max(0.05, math.min(0.95, targetY))
    end
end

function Clothing.setPreviewEnabled(state)
    if not Clothing.enabled then return end

    local shouldEnable = state and true or false
    if shouldEnable == previewEnabled then return end

    previewEnabled = shouldEnable

    if previewEnabled then
        SetGameplayCamRelativePitch(0.0, 1.0)
        cloneCurrentPed()
    else
        destroyPreviewPed()
        Clothing.pushAppearance()
    end
end

function Clothing.disablePreview()
    Clothing.setPreviewEnabled(false)
end

AddEventHandler('ox_inventory:clothing:appearanceChanged', function(shouldSave)
    clothingAppearanceChanged(shouldSave == true)
end)

-- Esta actualización llega antes que la respuesta de moveTo y moveFrom y deja la prenda ya aplicada,
-- así que es aquí donde hay que guardar: si no, al volver a entrar el aspecto no coincide con el inventario
AddEventHandler('ox_inventory:updateInventory', function(items)
    Clothing.syncSlotState(items, not syncingFromPed)
end)

lib.onCache('ped', function()
    if Clothing.enabled then
        SetTimeout(0, function()
            destroyPreviewPed()
            Clothing.pushAppearance()
        end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    destroyPreviewPed()
end)

return Clothing
