if not lib then
    return {}
end

local Clothing = {}
local ClothingConfig = lib.load('data.clothing') or {}
local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

Clothing.config = ClothingConfig
Clothing.enabled = ClothingConfig.enabled == true and ClothingConfig.slots and
    (ClothingConfig.slots.male or ClothingConfig.slots.female) ~= nil
Clothing.slotOffset = ClothingConfig.slotOffset or 1200

local canonicalSlots = ClothingConfig.slots and
    (ClothingConfig.slots.male or ClothingConfig.slots.female) or {}

if not Clothing.enabled then
    return Clothing
end

local function getReservedSlot(slotId)
    return Clothing.slotOffset + slotId + 1
end

local function cloneMetadata(metadata)
    return metadata and table.clone(metadata) or {}
end

local function serialiseInventory(inv, overrideType)
    if not inv then return nil end

    local items = table.create(inv.slots, 0)

    for slot = 1, inv.slots do
        local item = inv.items[slot]
        items[slot] = item and table.clone(item) or { slot = slot }
    end

    return {
        id = tostring(inv.id),
        type = overrideType or inv.type or 'backpack',
        label = inv.label or 'Backpack',
        slots = inv.slots,
        items = items,
        maxWeight = inv.maxWeight,
        weight = inv.weight,
    }
end

local function syncSlots(inventory, slots)
    inventory:syncSlotsWithPlayer(slots, inventory.weight)
    inventory:syncSlotsWithClients(slots, true)
end

local function refreshPlayerBackpack(playerId, backpackInventory)
    if not playerId or not backpackInventory or backpackInventory.type ~= 'backpack' then return end

    TriggerClientEvent('ox_inventory:utility:setBackpack', playerId, serialiseInventory(backpackInventory, 'backpack'))
end

local function getSlotDefinition(slotId)
    return canonicalSlots[slotId]
end

local function metadataMatchesEmpty(definition, metadata)
    if not definition or type(metadata) ~= 'table' then
        return false
    end

    local empty = type(definition.empty) == 'table' and definition.empty or nil
    if not empty then
        return false
    end

    if definition.component ~= nil and tonumber(metadata.component) ~= tonumber(definition.component) then
        return false
    end

    if definition.prop ~= nil and tonumber(metadata.prop) ~= tonumber(definition.prop) then
        return false
    end

    return tonumber(metadata.drawable) == tonumber(empty.drawable)
        and (tonumber(metadata.texture) or 0) == (tonumber(empty.texture) or 0)
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

local function metadataMatchesDefinition(metadata, definition)
    if type(metadata) ~= 'table' or not definition then
        return false
    end

    if definition.component ~= nil then
        return tonumber(metadata.component) == tonumber(definition.component)
    end

    if definition.prop ~= nil then
        return tonumber(metadata.prop) == tonumber(definition.prop)
    end

    return false
end

local function metadataMatchesPiece(metadata, pieceMetadata)
    if type(metadata) ~= 'table' or type(pieceMetadata) ~= 'table' then
        return false
    end

    if tonumber(metadata.drawable) ~= tonumber(pieceMetadata.drawable) then
        return false
    end

    if tonumber(metadata.texture) ~= tonumber(pieceMetadata.texture) then
        return false
    end

    if pieceMetadata.component ~= nil then
        return tonumber(metadata.component) == tonumber(pieceMetadata.component)
    end

    if pieceMetadata.prop ~= nil then
        return tonumber(metadata.prop) == tonumber(pieceMetadata.prop)
    end

    return false
end

local function itemAllowedForSlot(itemName, metadata, slotId)
    local definition = getSlotDefinition(slotId)
    if not definition or type(metadata) ~= 'table' then
        return false
    end

    if not metadataMatchesDefinition(metadata, definition) then
        return false
    end

    return itemName == definition.itemName or itemName == 'clothing'
end

local function setClothingMetadata(metadata, slotId, previous)
    metadata.clothingSlot = slotId

    if type(previous) == 'table' then
        metadata.previousDrawable = tonumber(previous.drawable)
        metadata.previousTexture = tonumber(previous.texture) or 0
    elseif metadata.prop ~= nil then
        metadata.previousDrawable = -1
        metadata.previousTexture = 0
    else
        metadata.previousDrawable = metadata.previousDrawable or 0
        metadata.previousTexture = metadata.previousTexture or 0
    end

    return metadata
end

local function clearClothingMetadata(metadata)
    metadata.clothingSlot = nil
    metadata.previousDrawable = nil
    metadata.previousTexture = nil
    return metadata
end

local function findVisibleMatch(inventory, piece)
    for slot, slotData in pairs(inventory.items) do
        if slotData and slotData.name and getClothingSlot(slotData.metadata, slot) == nil then
            if (slotData.name == piece.itemName or slotData.name == 'clothing')
                and metadataMatchesDefinition(slotData.metadata, getSlotDefinition(piece.clothingSlot))
                and tonumber(slotData.metadata.drawable) == tonumber(piece.metadata.drawable)
                and tonumber(slotData.metadata.texture) == tonumber(piece.metadata.texture)
            then
                return slot, slotData
            end
        end
    end
end

local function ensureWornPiece(inventory, piece, updates)
    local slotId = tonumber(piece.clothingSlot)
    local definition = getSlotDefinition(slotId)

    if slotId == nil or not definition or type(piece.metadata) ~= 'table' then
        return
    end

    if not itemAllowedForSlot(piece.itemName, piece.metadata, slotId) then
        return
    end

    if metadataMatchesEmpty(definition, piece.metadata) then
        return
    end

    local reservedSlot = getReservedSlot(slotId)
    local equipped = inventory.items[reservedSlot]

    if equipped and equipped.name and metadataMatchesPiece(equipped.metadata, piece.metadata) then
        return
    end

    local itemDefinition = Items(piece.itemName)

    if not itemDefinition then
        return
    end

    local localUpdates = updates or {}

    -- Si la prenda que lleva puesta ya está suelta en el inventario se equipa esa: crear otra la duplicaría
    local looseSlot, looseItem = findVisibleMatch(inventory, piece)
    local metadata = setClothingMetadata(cloneMetadata(looseItem and looseItem.metadata or piece.metadata), slotId)

    if looseSlot then
        Inventory.SetSlot(inventory, Items(looseItem.name) or itemDefinition, -1, looseItem.metadata, looseSlot, true)
        localUpdates[#localUpdates + 1] = { item = inventory.items[looseSlot] or { slot = looseSlot }, inventory = inventory.id }
    end

    if equipped and equipped.name then
        local oldDefinition = Items(equipped.name)
        if oldDefinition then
            Inventory.SetSlot(inventory, oldDefinition, -equipped.count, equipped.metadata, reservedSlot, true)
            localUpdates[#localUpdates + 1] = { item = inventory.items[reservedSlot] or { slot = reservedSlot }, inventory = inventory.id }
        end
    end

    local _, created = Inventory.SetSlot(inventory, itemDefinition, 1, metadata, reservedSlot, true)
    localUpdates[#localUpdates + 1] = { item = created or { slot = reservedSlot }, inventory = inventory.id }

    if not updates then
        syncSlots(inventory, localUpdates)
    end
end

local function syncClothingFromPed(source, wornPieces)
    if type(wornPieces) ~= 'table' then return end

    local inventory = Inventory(source)
    if not inventory then return end

    local seenSlots = {}
    local updates = {}

    for i = 1, #wornPieces do
        local piece = wornPieces[i]
        local slotId = type(piece) == 'table' and tonumber(piece.clothingSlot) or nil
        local definition = slotId ~= nil and getSlotDefinition(slotId) or nil

        if slotId ~= nil and not metadataMatchesEmpty(definition, piece.metadata) then
            seenSlots[slotId] = true
            ensureWornPiece(inventory, piece, updates)
        end
    end

    for slotId, definition in pairs(canonicalSlots) do
        local numericSlot = tonumber(slotId)

        if numericSlot ~= nil and not seenSlots[numericSlot] then
            local reservedSlot = getReservedSlot(numericSlot)
            local slotData = inventory.items[reservedSlot]

            if slotData and slotData.name then
                local itemDefinition = Items(slotData.name)

                if itemDefinition then
                    if numericSlot == 7 then
                        goto continue_missing_slot
                    end

                    Inventory.SetSlot(inventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot, true)
                    updates[#updates + 1] = { item = inventory.items[reservedSlot] or { slot = reservedSlot }, inventory = inventory.id }
                end
            end
        end

        ::continue_missing_slot::
    end

    if #updates > 0 then
        syncSlots(inventory, updates)
    end

    return {
        items = updates,
        weight = inventory.weight,
    }
end

RegisterNetEvent('ox_inventory:syncClothing', function(wornPieces)
    syncClothingFromPed(source, wornPieces)
end)

lib.callback.register('ox_inventory:syncClothingFromPed', function(source, wornPieces)
    return syncClothingFromPed(source, wornPieces)
end)

lib.callback.register('ox_inventory:clothing:moveTo', function(source, data)
    if source == '' then return false, 'Clothing action unavailable' end

    local clothingSlot = tonumber(data?.toSlot or data?.clothingSlot)
    local fromSlot = tonumber(data?.fromSlot)
    local fromInventoryId = data?.fromInventory

    if clothingSlot == nil or fromSlot == nil then
        return false, 'Invalid clothing request'
    end

    local playerInventory = Inventory(source)
    if not playerInventory then
        return false, 'Inventory unavailable'
    end

    local sourceInventory = playerInventory

    if fromInventoryId and tostring(fromInventoryId) ~= tostring(playerInventory.id) and tostring(fromInventoryId) ~= 'player' then
        sourceInventory = Inventory(fromInventoryId)

        if not sourceInventory then
            return false, 'Source inventory unavailable'
        end
    end

    local sourceItem = sourceInventory.items[fromSlot]
    if not sourceItem or not sourceItem.name then
        return false, 'Item not found'
    end

    if not itemAllowedForSlot(sourceItem.name, sourceItem.metadata, clothingSlot) then
        return false, 'This item cannot be placed in this clothing slot'
    end

    local reservedSlot = getReservedSlot(clothingSlot)
    if playerInventory.items[reservedSlot] and reservedSlot ~= fromSlot then
        return false, 'Clothing slot is already occupied'
    end

    local itemDefinition = Items(sourceItem.name)
    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    local metadata = setClothingMetadata(cloneMetadata(sourceItem.metadata), clothingSlot, data.previous)

    Inventory.SetSlot(sourceInventory, itemDefinition, -sourceItem.count, sourceItem.metadata, fromSlot, true)
    local _, equippedItem = Inventory.SetSlot(playerInventory, itemDefinition, sourceItem.count, metadata, reservedSlot, true)

    local sourceUpdates = {
        { item = sourceInventory.items[fromSlot] or { slot = fromSlot }, inventory = sourceInventory.id },
    }

    if sourceInventory.id == playerInventory.id then
        sourceUpdates[#sourceUpdates + 1] = { item = equippedItem or { slot = reservedSlot }, inventory = playerInventory.id }
        syncSlots(playerInventory, sourceUpdates)
    else
        syncSlots(sourceInventory, sourceUpdates)
        syncSlots(playerInventory, {
            { item = equippedItem or { slot = reservedSlot }, inventory = playerInventory.id },
        })
    end

    refreshPlayerBackpack(source, sourceInventory)

    return true, {
        slot = reservedSlot,
        clothingSlot = clothingSlot,
        metadata = metadata,
    }
end)

lib.callback.register('ox_inventory:clothing:moveFrom', function(source, data)
    if source == '' then return false, 'Clothing action unavailable' end

    local clothingSlot = tonumber(data?.clothingSlot)
    local toSlot = tonumber(data?.toSlot)
    local toInventoryId = data?.toInventory

    if clothingSlot == nil then
        return false, 'Invalid clothing request'
    end

    local playerInventory = Inventory(source)
    if not playerInventory then
        return false, 'Inventory unavailable'
    end

    local targetInventory = playerInventory

    if toInventoryId and tostring(toInventoryId) ~= tostring(playerInventory.id) and tostring(toInventoryId) ~= 'player' then
        targetInventory = Inventory(toInventoryId)

        if not targetInventory then
            return false, 'Target inventory unavailable'
        end
    end

    local reservedSlot = getReservedSlot(clothingSlot)
    local slotData = playerInventory.items[reservedSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)
    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    local restoreMetadata = cloneMetadata(slotData.metadata)
    local targetMetadata = clearClothingMetadata(cloneMetadata(slotData.metadata))

    Inventory.SetSlot(playerInventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot, true)

    local added

    if toSlot then
        local existing = targetInventory.items[toSlot]

        if existing and existing.name then
            if existing.name ~= slotData.name or not itemDefinition.stack then
                Inventory.SetSlot(playerInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
                return false, 'Target slot is occupied'
            end

            if not table.matches(existing.metadata or {}, targetMetadata or {}) then
                Inventory.SetSlot(playerInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
                return false, 'Target slot is occupied'
            end
        end

        local success
        success, added = Inventory.SetSlot(targetInventory, itemDefinition, slotData.count, targetMetadata, toSlot, true)
    else
        local success, result = Inventory.AddItem(targetInventory, itemDefinition, slotData.count, targetMetadata, nil, nil, true)

        if not success then
            Inventory.SetSlot(playerInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
            return false, result or 'Inventory is full'
        end

        added = result
    end

    local playerUpdates = {
        { item = { slot = reservedSlot }, inventory = playerInventory.id },
    }

    if playerInventory.id == targetInventory.id then
        if type(added) == 'table' and added.slot then
            playerUpdates[#playerUpdates + 1] = { item = targetInventory.items[added.slot] or added, inventory = targetInventory.id }
        elseif type(added) == 'table' and added[1] then
            for i = 1, #added do
                playerUpdates[#playerUpdates + 1] = { item = added[i], inventory = targetInventory.id }
            end
        end

        syncSlots(playerInventory, playerUpdates)
    else
        local targetUpdates = {}

        if type(added) == 'table' and added.slot then
            targetUpdates[#targetUpdates + 1] = { item = targetInventory.items[added.slot] or added, inventory = targetInventory.id }
        elseif type(added) == 'table' and added[1] then
            for i = 1, #added do
                targetUpdates[#targetUpdates + 1] = { item = added[i], inventory = targetInventory.id }
            end
        end

        local allUpdates = {}
        for i = 1, #playerUpdates do allUpdates[#allUpdates + 1] = playerUpdates[i] end
        for i = 1, #targetUpdates do allUpdates[#allUpdates + 1] = targetUpdates[i] end

        playerInventory:syncSlotsWithPlayer(allUpdates, playerInventory.weight)
        playerInventory:syncSlotsWithClients(playerUpdates)

        if #targetUpdates > 0 then
            targetInventory:syncSlotsWithClients(targetUpdates)
        end
    end

    refreshPlayerBackpack(source, targetInventory)

    return true, {
        clothingSlot = clothingSlot,
        metadata = restoreMetadata,
        item = added,
    }
end)

lib.callback.register('ox_inventory:clothing:moveToOther', function(source, data)
    if source == '' then return false, 'Clothing action unavailable' end

    local clothingSlot = tonumber(data?.toSlot or data?.clothingSlot)
    local fromSlot = tonumber(data?.fromSlot)
    local fromInventoryId = data?.fromInventory
    local toInventoryId = data?.toInventory

    if clothingSlot == nil or fromSlot == nil or not toInventoryId then
        return false, 'Invalid clothing request'
    end

    local robberInventory = Inventory(source)
    if not robberInventory then return false, 'Inventory unavailable' end

    if tostring(robberInventory.open) ~= tostring(toInventoryId) then
        return false, 'You do not have access to this inventory'
    end

    local victimInventory = Inventory(toInventoryId)
    if not victimInventory then return false, 'Victim inventory unavailable' end

    local sourceInventory = robberInventory
    if fromInventoryId and tostring(fromInventoryId) ~= tostring(robberInventory.id) and tostring(fromInventoryId) ~= 'player' then
        sourceInventory = Inventory(fromInventoryId)
        if not sourceInventory then return false, 'Source inventory unavailable' end
    end

    local sourceItem = sourceInventory.items[fromSlot]
    if not sourceItem or not sourceItem.name then return false, 'Item not found' end

    if not itemAllowedForSlot(sourceItem.name, sourceItem.metadata, clothingSlot) then
        return false, 'This item cannot be placed in this clothing slot'
    end

    local reservedSlot = getReservedSlot(clothingSlot)
    local existing = victimInventory.items[reservedSlot]
    if existing and existing.name then
        return false, 'Clothing slot is already occupied'
    end

    local itemDefinition = Items(sourceItem.name)
    if not itemDefinition then return false, 'Item data unavailable' end

    local metadata = setClothingMetadata(cloneMetadata(sourceItem.metadata), clothingSlot, data.previous)

    Inventory.SetSlot(sourceInventory, itemDefinition, -sourceItem.count, sourceItem.metadata, fromSlot, true)
    local _, equippedItem = Inventory.SetSlot(victimInventory, itemDefinition, sourceItem.count, metadata, reservedSlot, true)

    syncSlots(sourceInventory, {
        { item = sourceInventory.items[fromSlot] or { slot = fromSlot }, inventory = sourceInventory.id },
    })

    syncSlots(victimInventory, {
        { item = equippedItem or { slot = reservedSlot }, inventory = victimInventory.id },
    })

    refreshPlayerBackpack(source, sourceInventory)

    return true, {
        slot = reservedSlot,
        clothingSlot = clothingSlot,
        metadata = metadata,
    }
end)

lib.callback.register('ox_inventory:clothing:moveFromOther', function(source, data)
    if source == '' then return false, 'Clothing action unavailable' end

    local clothingSlot = tonumber(data?.clothingSlot)
    local toSlot = tonumber(data?.toSlot)
    local fromInventoryId = data?.fromInventory
    local toInventoryId = data?.toInventory

    if clothingSlot == nil or not fromInventoryId then
        return false, 'Invalid clothing request'
    end

    local robberInventory = Inventory(source)
    if not robberInventory then return false, 'Inventory unavailable' end

    if tostring(robberInventory.open) ~= tostring(fromInventoryId) then
        return false, 'You do not have access to this inventory'
    end

    local victimInventory = Inventory(fromInventoryId)
    if not victimInventory then return false, 'Victim inventory unavailable' end

    local targetInventory = robberInventory
    if toInventoryId and tostring(toInventoryId) ~= tostring(robberInventory.id) and tostring(toInventoryId) ~= 'player' then
        targetInventory = Inventory(toInventoryId)
        if not targetInventory then return false, 'Target inventory unavailable' end
    end

    local reservedSlot = getReservedSlot(clothingSlot)
    local slotData = victimInventory.items[reservedSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)
    if not itemDefinition then return false, 'Item data unavailable' end

    local targetMetadata = clearClothingMetadata(cloneMetadata(slotData.metadata))

    Inventory.SetSlot(victimInventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot, true)

    local added
    if toSlot then
        local existing = targetInventory.items[toSlot]
        if existing and existing.name then
            if existing.name ~= slotData.name or not itemDefinition.stack then
                Inventory.SetSlot(victimInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
                return false, 'Target slot is occupied'
            end
            if not table.matches(existing.metadata or {}, targetMetadata or {}) then
                Inventory.SetSlot(victimInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
                return false, 'Target slot is occupied'
            end
        end
        local success
        success, added = Inventory.SetSlot(targetInventory, itemDefinition, slotData.count, targetMetadata, toSlot, true)
    else
        local success, result = Inventory.AddItem(targetInventory, itemDefinition, slotData.count, targetMetadata, nil, nil, true)
        if not success then
            Inventory.SetSlot(victimInventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot, true)
            return false, result or 'Inventory is full'
        end
        added = result
    end

    local victimUpdates = {
        { item = victimInventory.items[reservedSlot] or { slot = reservedSlot }, inventory = victimInventory.id },
    }
    syncSlots(victimInventory, victimUpdates)

    local robberUpdates = {}
    if type(added) == 'table' and added.slot then
        robberUpdates[#robberUpdates + 1] = { item = targetInventory.items[added.slot] or added, inventory = targetInventory.id }
    elseif type(added) == 'table' and added[1] then
        for i = 1, #added do
            robberUpdates[#robberUpdates + 1] = { item = added[i], inventory = targetInventory.id }
        end
    end

    if #robberUpdates > 0 then
        syncSlots(targetInventory, robberUpdates)
    end

    refreshPlayerBackpack(source, targetInventory)

    return true, {
        clothingSlot = clothingSlot,
        item = added,
    }
end)

return Clothing
