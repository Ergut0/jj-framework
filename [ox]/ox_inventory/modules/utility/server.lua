if not lib then
    return {}
end

local Utility = {}
local UtilityConfig = lib.load('data.utility') or {}
Utility.config = UtilityConfig

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local function isEnabled()
    return UtilityConfig.enabled and (UtilityConfig.slots or 0) > 0
end

if not isEnabled() then
    return Utility
end

local slotOffset = UtilityConfig.slotOffset or (shared.playerslots + 100)
Utility.slotOffset = slotOffset

local armorItems = UtilityConfig.armorItems or {}
local armorRepairItems = UtilityConfig.armorRepairItems or {}
local armorDamageRate = UtilityConfig.armorDamageRate or 1.0
local backpackItems = UtilityConfig.backpackItems or {}

local function arrayToSet(values)
    local set = table.create(0, #values)

    for i = 1, #values do
        local itemName = values[i]

        if type(itemName) == 'string' and itemName ~= '' then
            set[itemName] = true
        end
    end

    return set
end

local function normaliseBackpackFilter(filter)
    if type(filter) ~= 'table' then
        return nil
    end

    if #filter > 0 then
        return arrayToSet(filter)
    end

    return filter
end

for _, config in pairs(backpackItems) do
    config.blacklist = normaliseBackpackFilter(config.blacklist)
end

local function getReservedSlot(index)
    return slotOffset + index
end

local function cloneMetadata(metadata)
    return metadata and table.clone(metadata) or {}
end

local function canAccessInventory(playerInventory, inventory, source)
    if not playerInventory or not inventory then return false end
    if inventory == playerInventory then return true end
    if playerInventory.open == inventory.id or (inventory.openedBy and inventory.openedBy[source]) then return true end

    if inventory.type == 'backpack' then
        for _, slotData in pairs(playerInventory.items) do
            local metadata = slotData.metadata

            if metadata and (metadata.container == inventory.id or metadata.backpackId == inventory.id) then
                return true
            end
        end
    end

    return false
end

local function generateBackpackIdentifier(owner, reservedSlot)
    local suffix = ('%04x%04x'):format(math.random(0, 0xFFFF), math.random(0, 0xFFFF))
    return ('backpack-%s-%s'):format(reservedSlot, suffix)
end

local function getArmorValue(itemName)
    local config = armorItems[itemName]
    if not config then return end

    local value = type(config) == 'table' and config.value or config

    if not value or value <= 0 then
        return nil
    end

    return value, config
end

local function extractJobName(entry)
    if not entry then return nil end

    local entryType = type(entry)

    if entryType == 'string' then
        return entry
    elseif entryType == 'table' then
        if type(entry.name) == 'string' and entry.name ~= '' then
            return entry.name
        end

        if type(entry.job) == 'string' and entry.job ~= '' then
            return entry.job
        elseif type(entry.job) == 'table' then
            local nested = extractJobName(entry.job)
            if nested then return nested end
        end

        if type(entry.group) == 'string' and entry.group ~= '' then
            return entry.group
        end

        if type(entry.type) == 'string' and entry.type ~= '' then
            return entry.type
        end

        if type(entry.identifier) == 'string' and entry.identifier ~= '' then
            return entry.identifier
        end

        if type(entry.id) == 'string' and entry.id ~= '' then
            return entry.id
        end

        if type(entry.label) == 'string' and entry.label ~= '' then
            return entry.label
        end

        if type(entry[1]) == 'string' and entry[1] ~= '' then
            return entry[1]
        end
    end

    return nil
end

local function groupEntryActive(value)
    local valueType = type(value)

    if valueType == 'nil' then
        return false
    elseif valueType == 'boolean' then
        return value
    elseif valueType == 'number' then
        return value >= 0
    elseif valueType == 'string' then
        return value ~= ''
    elseif valueType == 'table' then
        if value.duty ~= nil and value.duty == false then
            return false
        end

        local grade = value.grade or value.rank or value.level or value.jobGrade or value.position or value.grade_level

        if type(grade) == 'number' then
            return grade >= 0
        end

        return true
    end

    return false
end

local function jobMatchesEntry(key, value, desiredLower)
    if type(key) == 'string' and key ~= '' then
        if key:lower() == desiredLower then
            return groupEntryActive(value)
        end
    end

    local name = extractJobName(value)

    if name and type(name) == 'string' and name ~= '' and name:lower() == desiredLower then
        return groupEntryActive(value)
    end

    return false
end

local function playerHasJob(inventory, jobName)
    if not inventory or not jobName then return false end

    local playerData = inventory.player
    if not playerData then return false end

    jobName = tostring(jobName)

    if jobName == '' then return false end

    local jobLower = jobName:lower()

    local directSources = {
        playerData.job,
        playerData.Job,
        playerData.primaryJob,
        playerData.mainJob,
        playerData.profession,
        playerData.group,
    }

    for i = 1, #directSources do
        local source = directSources[i]
        if source and jobMatchesEntry(nil, source, jobLower) then
            return true
        end
    end

    if type(playerData.jobs) == 'table' then
        for key, value in pairs(playerData.jobs) do
            if jobMatchesEntry(key, value, jobLower) then
                return true
            end
        end
    end

    if type(playerData.groups) == 'table' then
        for key, value in pairs(playerData.groups) do
            if jobMatchesEntry(key, value, jobLower) then
                return true
            end
        end
    end

    local stateData = playerData.state

    if type(stateData) == 'table' then
        if jobMatchesEntry(nil, stateData.job, jobLower) then
            return true
        end

        if jobMatchesEntry(nil, stateData.group, jobLower) then
            return true
        end
    end

    return false
end

local function playerHasAllowedJob(inventory, jobs)
    if not jobs then
        return true
    end

    local jobsType = type(jobs)

    if jobsType ~= 'table' then
        return playerHasJob(inventory, jobs)
    end

    local hasEntries = false

    for key, value in pairs(jobs) do
        hasEntries = true

        local jobName

        if type(key) == 'string' and key ~= '' then
            jobName = key
        else
            jobName = extractJobName(value)
        end

        if jobName and playerHasJob(inventory, jobName) then
            return true
        end
    end

    return not hasEntries
end

local function isItemAllowed(itemName, utilitySlot)
    local allowed = UtilityConfig.items and UtilityConfig.items[utilitySlot]

    if not allowed then return false end

    for i = 1, #allowed do
        if allowed[i] == itemName then
            return true
        end
    end

    return false
end

local function syncSlots(inventory, slots)
    inventory:syncSlotsWithPlayer(slots, inventory.weight)
    inventory:syncSlotsWithClients(slots, true)
end

local function validateArmorAccess(inventory, itemName)
    local config = armorItems[itemName]

    if not config then
        return true
    end

    local jobs = config.jobs

    if not jobs then
        return true
    end

    local allowed = playerHasAllowedJob(inventory, jobs)

    return allowed
end

local function setUtilityMetadata(metadata, utilitySlot, itemName, owner, reservedSlot)
    metadata.utilitySlot = utilitySlot

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[itemName]

    if backpackConfig then
        local existingId = metadata.backpackUid or metadata.backpackId

        if not existingId then
            existingId = generateBackpackIdentifier(owner, reservedSlot)
        end

        metadata.backpackUid = existingId
        metadata.backpackId = existingId
        metadata.container = metadata.backpackId
        metadata.size = { backpackConfig.slots or 0, backpackConfig.weight or 0 }
    elseif not (Items.containers and Items.containers[itemName]) then
        metadata.backpackId = nil
        metadata.backpackUid = nil
        metadata.container = nil
        metadata.size = nil
    end

    if UtilityConfig.armorItems and UtilityConfig.armorItems[itemName] then
        metadata.durability = metadata.durability or 100
    end

    return metadata
end

local function clearUtilityMetadata(metadata, itemName)
    if metadata then
        metadata.utilitySlot = nil

        if itemName and Items.containers and Items.containers[itemName] then
            return metadata
        end

        metadata.backpackId = metadata.backpackUid or metadata.backpackId
        metadata.container = nil
        metadata.size = nil
    end

    return metadata
end

local function normaliseBackpackInventory(containerId, container)
    if not container then return nil end

    if container.id == containerId and container.dbId == containerId and not container.owner then
        return container
    end

    local inventories = server and server.inventories

    if inventories and inventories[container.id] == container then
        inventories[container.id] = nil
    end

    container.id = containerId
    container.dbId = containerId
    container.owner = false
    container.changed = true

    if inventories then
        inventories[containerId] = container
    end

    return container
end

local function findLegacyBackpackInventory(containerId)
    local inventories = server and server.inventories

    if not inventories then return nil end

    for inventoryId, inv in pairs(inventories) do
        if inventoryId ~= containerId and inv and inv.type == 'backpack' and inv.dbId == containerId then
            return inv
        end
    end
end

local function ensureBackpackInventory(ownerInventory, slotData)
    if not slotData or not slotData.name or not slotData.metadata then return nil end

    local config = backpackItems[slotData.name]

    if not config then return nil end

    local containerId = slotData.metadata.container or slotData.metadata.backpackId

    if not containerId then return nil end

    local container = Inventory(containerId)

    if not container then
        container = findLegacyBackpackInventory(containerId)

        if container then
            Inventory.CloseAll(container)
            container = normaliseBackpackInventory(containerId, container)
            Inventory.Save(container)
        end
    elseif container.id ~= containerId or container.dbId ~= containerId or container.owner then
        Inventory.CloseAll(container)
        container = normaliseBackpackInventory(containerId, container)
        Inventory.Save(container)
    end

    if not container then
        local itemDef = Items(slotData.name)
        local label = (slotData.metadata and slotData.metadata.label) or (itemDef and itemDef.label) or slotData.label or 'Backpack'
        container = Inventory.Create(
            containerId,
            label,
            'backpack',
            config.slots or 0,
            0,
            config.weight or 0,
            false,
            nil
        )
    else
        if config.slots and container.slots ~= config.slots then
            Inventory.SetSlotCount(container, config.slots)
        end

        if config.weight and container.maxWeight ~= config.weight then
            Inventory.SetMaxWeight(container, config.weight)
        end
    end

    if container then
        container.label = container.label or slotData.label or 'Backpack'
        container.backpackItemName = slotData.name
        container.backpackBlacklist = config.blacklist
        container.backpackOwner = ownerInventory and ownerInventory.player and ownerInventory.id or nil
        container.time = os.time()
    end

    return container
end

local function canStoreItemInBackpack(backpackInventory, itemName)
    if not backpackInventory or backpackInventory.type ~= 'backpack' or not itemName then
        return true
    end

    local blacklist = backpackInventory.backpackBlacklist

    if blacklist and blacklist[itemName] then
        return false
    end

    return true
end

Utility.canStoreItemInBackpack = canStoreItemInBackpack

local function serialiseInventory(inv, overrideType)
    if not inv then return nil end

    local items = table.create(inv.slots, 0)

    for slot = 1, inv.slots do
        local item = inv.items[slot]

        if item then
            items[slot] = table.clone(item)
        else
            items[slot] = { slot = slot }
        end
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

local function refreshPlayerBackpack(playerId, backpackInventory)
    if not playerId or not backpackInventory or backpackInventory.type ~= 'backpack' then return end

    TriggerClientEvent('ox_inventory:utility:setBackpack', playerId, serialiseInventory(backpackInventory, 'backpack'))
end

local function generateDropId()
    while true do
        local dropId = ('drop-%06d'):format(math.random(100000, 999999))

        if not Inventory(dropId) then
            return dropId
        end

        Wait(0)
    end
end

local function createUtilityDrop(source, itemDefinition, slotData, metadata, data, reservedSlot)
    local dropSlot = tonumber(data?.toSlot) or 1
    local dropData = table.clone(slotData)

    dropData.slot = dropSlot
    dropData.metadata = metadata
    dropData.weight = Inventory.SlotWeight(itemDefinition, {
        count = slotData.count,
        metadata = metadata,
    })

    local dropId = generateDropId()
    local inventory = Inventory.Create(
        dropId,
        ('Drop %s'):format(dropId:gsub('%D', '')),
        'drop',
        shared.dropslots,
        dropData.weight,
        shared.dropweight,
        false,
        { [dropSlot] = dropData }
    )

    if not inventory then
        return false, 'Unable to create drop'
    end

    local coords = data?.coords or GetEntityCoords(GetPlayerPed(source))
    inventory.coords = coords
    Inventory.Drops[dropId] = {
        coords = inventory.coords,
        instance = data?.instance,
    }

    if AddDropProps then
        AddDropProps(dropId, {
            {
                name = slotData.name,
                count = slotData.count,
                slot = dropSlot,
            }
        }, inventory.coords, source)

        Inventory.Drops[dropId].hasPropObjects = Inventory.Drops[dropId].itemProps and #Inventory.Drops[dropId].itemProps > 0 or false
    end

    TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId], source, reservedSlot)

    return true, {
        dropId = dropId,
        slot = dropSlot,
    }
end

lib.callback.register('ox_inventory:utility:moveTo', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local fromSlot = tonumber(data?.fromSlot)
    local utilitySlot = tonumber(data?.utilitySlot)

    if not fromSlot or not utilitySlot then
        return false, 'Invalid utility request'
    end

    if utilitySlot < 1 or utilitySlot > (UtilityConfig.slots or 0) then
        return false, 'Invalid utility slot'
    end

    local inventory = Inventory(source)

    if not inventory then
        return false, 'Inventory unavailable'
    end

    local slotData = inventory.items[fromSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    if slotData.metadata and slotData.metadata.container then
        local openInventory = inventory.open

        if openInventory and openInventory == slotData.metadata.container then
            return false, 'Close the container before moving it'
        end
    end

    if not isItemAllowed(slotData.name, utilitySlot) then
        return false, 'This item cannot be placed in this slot'
    end

    if not validateArmorAccess(inventory, slotData.name) then
        return false, 'You are not authorised to equip this item'
    end

    local reservedSlot = getReservedSlot(utilitySlot)

    if inventory.items[reservedSlot] and reservedSlot ~= fromSlot then
        return false, 'Utility slot is already occupied'
    end

    local container
    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]

    if backpackConfig then
        container = ensureBackpackInventory(inventory, slotData)

        if container then
            container.openedBy[inventory.id] = nil

            if inventory.open == container.id or inventory.open == slotData.metadata.container then
                inventory.open = false
                inventory.containerSlot = nil
                container:set('open', false)
            end
        elseif inventory.open == slotData.metadata.container then
            inventory.open = false
            inventory.containerSlot = nil
        end
    end

    local itemDefinition = Items(slotData.name)

    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    local armorValue = getArmorValue(slotData.name)

    local armorValue = getArmorValue(slotData.name)

    local metadata = cloneMetadata(slotData.metadata)

    metadata = setUtilityMetadata(metadata, utilitySlot, slotData.name, inventory.owner, reservedSlot)

    Inventory.SetSlot(inventory, itemDefinition, -slotData.count, slotData.metadata, fromSlot)
    local _, newItem = Inventory.SetSlot(inventory, itemDefinition, slotData.count, metadata, reservedSlot)

    local container = ensureBackpackInventory(inventory, newItem)

    local updates = {
        { item = inventory.items[fromSlot] or { slot = fromSlot }, inventory = inventory.id },
        { item = newItem, inventory = inventory.id },
    }

    syncSlots(inventory, updates)

    if container then
        TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, serialiseInventory(container, 'backpack'))
    end

    if armorValue and newItem then
        local durability = tonumber(newItem.metadata and newItem.metadata.durability) or 100
        if durability < 0 then durability = 0 elseif durability > 100 then durability = 100 end

        TriggerClientEvent('ox_inventory:utility:wearArmor', inventory.id, {
            slot = reservedSlot,
            utilitySlot = utilitySlot,
            maxValue = armorValue,
            durability = durability
        })
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]
    if backpackConfig and backpackConfig.component and newItem then
        TriggerClientEvent('ox_inventory:utility:wearBackpack', inventory.id, {
            slot = reservedSlot,
            utilitySlot = utilitySlot,
            itemName = slotData.name,
            drawable = backpackConfig.component.drawable,
            texture = backpackConfig.component.texture or 0
        })
    end

    return true, { slot = reservedSlot }
end)

lib.callback.register('ox_inventory:utility:moveFrom', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local utilitySlot = tonumber(data?.utilitySlot)
    local toSlot = tonumber(data?.toSlot)
    local toInventoryId = data?.toInventory
    local toType = data?.toType

    if not utilitySlot then
        return false, 'Invalid utility request'
    end

    local inventory = Inventory(source)

    if not inventory then
        return false, 'Inventory unavailable'
    end

    local targetInventory = inventory

    if toInventoryId and tostring(toInventoryId) ~= tostring(inventory.id) and tostring(toInventoryId) ~= 'player' then
        targetInventory = Inventory(toInventoryId)

        if not targetInventory then
            return false, 'Target inventory unavailable'
        end

        if not canAccessInventory(inventory, targetInventory, source) then
            return false, 'You do not have access to this inventory'
        end
    end

    local reservedSlot = getReservedSlot(utilitySlot)
    local slotData = inventory.items[reservedSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)

    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    if targetInventory.type == 'backpack' and not canStoreItemInBackpack(targetInventory, slotData.name) then
        return false, 'backpack_blacklisted_item'
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]
    local isBackpack = backpackConfig ~= nil
    local armorValue = getArmorValue(slotData.name)

    if isBackpack and UtilityConfig.lockBackpackRemovalWithItems then
        local meta = slotData.metadata
        local containerId = meta and (meta.container or meta.backpackId)

        if containerId then
            local containerInventory = Inventory(containerId)

            if containerInventory then
                for slotIndex = 1, containerInventory.slots do
                    local containerSlot = containerInventory.items[slotIndex]

                    if containerSlot and containerSlot.name then
                        return false, 'backpack_not_empty'
                    end
                end
            end
        end
    end

    local metadata = cloneMetadata(slotData.metadata)
    clearUtilityMetadata(metadata, slotData.name)

    Inventory.SetSlot(inventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot)

    if toType == 'newdrop' then
        local dropSuccess, dropResponse = createUtilityDrop(source, itemDefinition, slotData, metadata, data, reservedSlot)

        if not dropSuccess then
            Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
            return false, dropResponse or 'Unable to create drop'
        end

        syncSlots(inventory, {
            { item = { slot = reservedSlot }, inventory = inventory.id }
        })

        if armorValue then
            TriggerClientEvent('ox_inventory:utility:removeArmor', inventory.id, { slot = reservedSlot })
        end

        if backpackConfig then
            TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, false)
            TriggerClientEvent('ox_inventory:utility:removeBackpack', inventory.id, { slot = reservedSlot })
        end

        return true, dropResponse
    end

    local updates = {}

    if toSlot then
        local existing = targetInventory.items[toSlot]

        if existing and existing.name then
            if existing.name ~= slotData.name or not itemDefinition.stack then
                Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
                return false, 'Target slot is occupied'
            end

            if not table.matches(existing.metadata or {}, metadata or {}) then
                Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
                return false, 'Target slot is occupied'
            end
        end

        local _, response = Inventory.SetSlot(targetInventory, itemDefinition, slotData.count, metadata, toSlot)

        if backpackConfig then
            TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, false)
        end

        if inventory.id == targetInventory.id then
            updates[#updates + 1] = { item = { slot = reservedSlot }, inventory = inventory.id }
            updates[#updates + 1] = { item = response, inventory = inventory.id }
            syncSlots(inventory, updates)
        else
            syncSlots(inventory, { { item = { slot = reservedSlot }, inventory = inventory.id } })
            syncSlots(targetInventory, { { item = response, inventory = targetInventory.id } })
        end

        if targetInventory.type == 'backpack' and not backpackConfig then
            refreshPlayerBackpack(source, targetInventory)
        end

        if armorValue then
            TriggerClientEvent('ox_inventory:utility:removeArmor', inventory.id, { slot = reservedSlot })
        end
        return true, { slot = toSlot }
    end

    local addSuccess, addResult = Inventory.AddItem(targetInventory, itemDefinition, slotData.count, metadata)

    if not addSuccess then
        Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
        return false, addResult or 'Inventory is full'
    end

    updates[#updates + 1] = { item = { slot = reservedSlot }, inventory = inventory.id }

    Wait(0)

    if backpackConfig then
        TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, false)
        Wait(0)
    end

    if inventory.id == targetInventory.id then
        if type(addResult) == 'table' then
            if addResult.slot then
                updates[#updates + 1] = { item = addResult, inventory = inventory.id }
            else
                for i = 1, #addResult do
                    updates[#updates + 1] = { item = addResult[i], inventory = inventory.id }
                end
            end
        end

        syncSlots(inventory, updates)
    else
        syncSlots(inventory, updates)

        local targetUpdates = {}

        if type(addResult) == 'table' then
            if addResult.slot then
                targetUpdates[#targetUpdates + 1] = { item = addResult, inventory = targetInventory.id }
            else
                for i = 1, #addResult do
                    targetUpdates[#targetUpdates + 1] = { item = addResult[i], inventory = targetInventory.id }
                end
            end
        end

        if #targetUpdates > 0 then
            syncSlots(targetInventory, targetUpdates)
        end
    end

    if targetInventory.type == 'backpack' and not backpackConfig then
        refreshPlayerBackpack(source, targetInventory)
    end

    if armorValue then
        TriggerClientEvent('ox_inventory:utility:removeArmor', inventory.id, { slot = reservedSlot })
    end

    if backpackConfig then
        TriggerClientEvent('ox_inventory:utility:removeBackpack', inventory.id, { slot = reservedSlot })
    end

    return true, addResult
end)

local function buildBackpackPayload(source, target)
    if source == '' then return {} end

    local payload = {}

    local function findBackpack(inv)
        if not inv then return nil, nil end

        for slotIndex = 1, (UtilityConfig.slots or 0) do
            local reservedSlot = getReservedSlot(slotIndex)
            local slotData = inv.items[reservedSlot]

            if slotData and slotData.name and slotData.metadata and UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name] then
                local container = ensureBackpackInventory(inv, slotData)

                if container then
                    return serialiseInventory(container, 'backpack'), slotIndex
                end
            end
        end

        return nil, nil
    end

    local playerInventory = Inventory(source)
    if playerInventory then
        local bp, idx = findBackpack(playerInventory)
        if bp then
            payload.backpack = bp
            payload.utilitySlot = idx
        end
    end

    if target and type(target) == 'number' then
        local otherInventory = Inventory(target)

        if otherInventory then
            local otherBp = select(1, findBackpack(otherInventory))

            if otherBp then
                payload.otherBackpack = otherBp
            end
        end
    end

    return payload
end

Utility.getBackpackPayload = buildBackpackPayload

lib.callback.register('ox_inventory:utility:getBackpack', function(source, target)
    return buildBackpackPayload(source, target)
end)

RegisterNetEvent('ox_inventory:utility:updateArmorDurability', function(slot, loss)
    local src = source
    slot = tonumber(slot)
    loss = tonumber(loss)

    if not slot or not loss or loss <= 0 then return end

    local inventory = Inventory(src)
    if not inventory then return end

    local slotData = inventory.items[slot]
    if not slotData or not slotData.name then return end

    local armorValue = getArmorValue(slotData.name)
    if not armorValue then return end

    local metadata = cloneMetadata(slotData.metadata)
    local currentDurability = tonumber(metadata.durability) or 100
    local rate = armorDamageRate > 0 and armorDamageRate or 1.0
    local durabilityLoss = loss * rate

    if durabilityLoss <= 0 then return end

    local newDurability = math.max(0, currentDurability - durabilityLoss)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, slot, metadata)

    if newDurability <= 0 then
        TriggerClientEvent('ox_inventory:utility:removeArmor', src, { slot = slot, broken = true })
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('armor_broken') })
    else
        local actualArmor = math.floor(armorValue * (newDurability / 100))
        TriggerClientEvent('ox_inventory:utility:updateArmor', src, {
            slot = slot,
            value = actualArmor,
            maxValue = armorValue,
            durability = newDurability
        })
    end
end)

RegisterNetEvent('ox_inventory:utility:syncArmorFromPed', function(slot, pedArmorValue, newDurability)
    local src = source
    slot = tonumber(slot)
    pedArmorValue = tonumber(pedArmorValue)
    newDurability = tonumber(newDurability)

    if not slot or not pedArmorValue or not newDurability then return end

    local inventory = Inventory(src)
    if not inventory then return end

    local slotData = inventory.items[slot]
    if not slotData or not slotData.name then return end

    local armorValue = getArmorValue(slotData.name)
    if not armorValue then return end

    newDurability = math.max(0, math.min(100, newDurability))

    local metadata = cloneMetadata(slotData.metadata)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, slot, metadata)
    if newDurability <= 0 or pedArmorValue <= 0 then
        TriggerClientEvent('ox_inventory:utility:removeArmor', src, { slot = slot, broken = true })
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('armor_broken') })
    end
end)

RegisterNetEvent('ox_inventory:utility:applyArmorPlate', function(data)
    local src = source
    local itemName = data and data.name
    local slot = data and data.slot

    if not itemName then return end

    local repairAmount = armorRepairItems[itemName]
    if not repairAmount or repairAmount <= 0 then
        return
    end

    local inventory = Inventory(src)
    if not inventory then
        return
    end

    local targetSlot
    local equippedArmor

    for index = 1, (UtilityConfig.slots or 0) do
        local reservedSlot = getReservedSlot(index)
        local slotData = inventory.items[reservedSlot]

        if slotData and slotData.name and getArmorValue(slotData.name) then
            targetSlot = reservedSlot
            equippedArmor = slotData
            break
        end
    end

    if not targetSlot or not equippedArmor then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('armor_not_equipped') })
        return
    end

    local metadata = cloneMetadata(equippedArmor.metadata)
    local currentDurability = tonumber(metadata.durability) or 100

    if currentDurability >= 100 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = locale('armor_already_max') })
        return
    end

    if not Inventory.RemoveItem(inventory, itemName, 1, nil, slot) then
        return
    end

    local armorConfig = UtilityConfig.armorItems and UtilityConfig.armorItems[equippedArmor.name]
    if armorConfig and armorConfig.plates and armorConfig.plates > 0 then
        repairAmount = 100 / armorConfig.plates
    end

    local newDurability = math.min(100, currentDurability + repairAmount)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, targetSlot, metadata)

    local armorValue = getArmorValue(equippedArmor.name)
    local actualArmor = math.floor(armorValue * (newDurability / 100))

    TriggerClientEvent('ox_inventory:utility:updateArmor', src, {
        slot = targetSlot,
        value = actualArmor,
        maxValue = armorValue,
        durability = newDurability
    })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = locale('armor_repaired') })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = locale('armor_repaired') })
end)

lib.callback.register('ox_inventory:utility:moveFromOtherUtilitySlot', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local utilitySlot = tonumber(data?.utilitySlot)
    local toSlot = tonumber(data?.toSlot)
    local fromInventoryId = data?.fromInventory
    local toInventoryId = data?.toInventory

    if not utilitySlot or not fromInventoryId then
        return false, 'Invalid utility request'
    end

    local robberInventory = Inventory(source)
    if not robberInventory then return false, 'Robber inventory not found' end

    if robberInventory.open ~= fromInventoryId then
        return false, 'You do not have access to this inventory'
    end

    local victimInventory = Inventory(fromInventoryId)
    if not victimInventory then return false, 'Victim inventory not found' end

    local targetInventory = toInventoryId and Inventory(toInventoryId) or robberInventory
    if not targetInventory then return false, 'Target inventory not found' end
    if not canAccessInventory(robberInventory, targetInventory, source) then
        return false, 'You do not have access to this inventory'
    end

    local reservedSlot = getReservedSlot(utilitySlot)
    local slotData = victimInventory.items[reservedSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)
    if not itemDefinition then return false, 'Item data unavailable' end

    if targetInventory.type == 'backpack' and not canStoreItemInBackpack(targetInventory, slotData.name) then
        return false, 'backpack_blacklisted_item'
    end

    local metadata = cloneMetadata(slotData.metadata)
    clearUtilityMetadata(metadata, slotData.name)

    local addSuccess, addResult

    if toSlot then
        local existing = targetInventory.items[toSlot]
        if existing and existing.name then
            if existing.name ~= slotData.name or not itemDefinition.stack then
                return false, 'Target slot is occupied'
            end
            if not table.matches(existing.metadata or {}, metadata or {}) then
                return false, 'Target slot is occupied'
            end
        end
        addSuccess, addResult = Inventory.SetSlot(targetInventory, itemDefinition, slotData.count, metadata, toSlot)
        if addResult then addResult = { slot = toSlot } end
    else
        addSuccess, addResult = Inventory.AddItem(targetInventory, itemDefinition, slotData.count, metadata)
    end

    if not addSuccess then return false, addResult or 'Inventory is full' end

    Inventory.SetSlot(victimInventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot)

    local updates = {
        { item = { slot = reservedSlot }, inventory = victimInventory.id },
    }
    syncSlots(victimInventory, updates)

    local targetUpdates = {
        { item = addResult and (addResult.slot and { slot = addResult.slot, name = itemDefinition.name, count = slotData.count, metadata = metadata } or addResult) or { slot = toSlot, name = itemDefinition.name, count = slotData.count, metadata = metadata }, inventory = targetInventory.id }
    }

    if addResult then
        local finalSlot = addResult.slot or (type(addResult) == 'table' and addResult.slot) or toSlot
        if finalSlot then
             targetUpdates = { { item = targetInventory.items[finalSlot], inventory = targetInventory.id } }
        end
    end

    syncSlots(targetInventory, targetUpdates)

    if targetInventory.type == 'backpack' then
        refreshPlayerBackpack(source, targetInventory)
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]
    local armorValue = getArmorValue(slotData.name)

    if backpackConfig then
         TriggerClientEvent('ox_inventory:utility:setBackpack', victimInventory.id, false)
         TriggerClientEvent('ox_inventory:utility:updateBackpack', source, victimInventory.id, false)
         TriggerClientEvent('ox_inventory:utility:removeBackpack', victimInventory.id, { slot = reservedSlot })
    end

    if armorValue then
         TriggerClientEvent('ox_inventory:utility:removeArmor', victimInventory.id, { slot = reservedSlot })
    end

    return true, addResult
end)

lib.callback.register('ox_inventory:utility:moveToOtherUtilitySlot', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local utilitySlot = tonumber(data?.toSlot)
    local fromSlot = tonumber(data?.fromSlot)
    local fromInventoryId = data?.fromInventory
    local toInventoryId = data?.toInventory

    if not utilitySlot or not fromInventoryId then
        return false, 'Invalid utility request'
    end

    local robberInventory = Inventory(source)
    if not robberInventory then return false, 'Robber inventory not found' end

    if robberInventory.open ~= toInventoryId then
        return false, 'You do not have access to this inventory'
    end

    local victimInventory = Inventory(toInventoryId)
    if not victimInventory then return false, 'Victim inventory not found' end

    local sourceInventory = fromInventoryId == robberInventory.id and robberInventory or Inventory(fromInventoryId)
    if not sourceInventory then return false, 'Source inventory not found' end
    if not canAccessInventory(robberInventory, sourceInventory, source) then
        return false, 'You do not have access to this inventory'
    end

    local reservedSlot = getReservedSlot(utilitySlot)
    local slotData = sourceInventory.items[fromSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)
    if not itemDefinition then return false, 'Item data unavailable' end

    if UtilityConfig.whitelist and not UtilityConfig.whitelist[slotData.name] then
        return false, 'Item not allowed in utility slot'
    end

    if victimInventory.items[reservedSlot] then
        return false, 'Target slot is occupied'
    end

    local metadata = cloneMetadata(slotData.metadata)

    metadata = setUtilityMetadata(metadata, utilitySlot, slotData.name, victimInventory.owner, reservedSlot)

    local startCount = slotData.count
    local success, result = Inventory.RemoveItem(sourceInventory, itemDefinition, slotData.count, slotData.metadata, fromSlot)

    if not success then
        return false, 'Failed to remove item from source'
    end

    local addSuccess, addResult = Inventory.SetSlot(victimInventory, itemDefinition, startCount, metadata, reservedSlot)

    if not addSuccess then
        Inventory.AddItem(sourceInventory, itemDefinition, startCount, slotData.metadata, fromSlot)
        Inventory.SetSlot(sourceInventory, itemDefinition, startCount, slotData.metadata, fromSlot)
        Inventory.SetSlot(sourceInventory, itemDefinition, startCount, slotData.metadata, fromSlot)
        return false, 'Failed to place item in utility slot'
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]

    local sourceUpdates = {
        { item = { slot = fromSlot }, inventory = sourceInventory.id }
    }
    syncSlots(sourceInventory, sourceUpdates)

    if sourceInventory.type == 'backpack' then
        refreshPlayerBackpack(source, sourceInventory)
    end

    local targetUpdates = {
        { item = victimInventory.items[reservedSlot] or { slot = reservedSlot }, inventory = victimInventory.id }
    }
    syncSlots(victimInventory, targetUpdates)

    local armorValue = getArmorValue(slotData.name)

    if backpackConfig then
        local existingId = metadata.container or metadata.backpackId
        local existingContainer = existingId and Inventory(existingId)
        if existingContainer then
            Inventory.CloseAll(existingContainer)
        end

        local newItem = victimInventory.items[reservedSlot]
        local container = ensureBackpackInventory(victimInventory, newItem)

        if container then
            local serialized = serialiseInventory(container, 'backpack')
            TriggerClientEvent('ox_inventory:utility:setBackpack', victimInventory.id, serialized)
            TriggerClientEvent('ox_inventory:utility:updateBackpack', source, victimInventory.id, serialized)
        end

        if backpackConfig.component then
            TriggerClientEvent('ox_inventory:utility:wearBackpack', victimInventory.id, {
                slot = reservedSlot,
                utilitySlot = utilitySlot,
                itemName = slotData.name,
                drawable = backpackConfig.component.drawable,
                texture = backpackConfig.component.texture or 0
            })
        end
    end

    if armorValue then
        local newItem = victimInventory.items[reservedSlot]
        if newItem then
            local durability = tonumber(newItem.metadata and newItem.metadata.durability) or 100
            if durability < 0 then durability = 0 elseif durability > 100 then durability = 100 end

            TriggerClientEvent('ox_inventory:utility:wearArmor', victimInventory.id, {
                slot = reservedSlot,
                utilitySlot = utilitySlot,
                maxValue = armorValue,
                durability = durability
            })
        end
    end

    return true, addResult
end)

Utility.ensureBackpackInventory = ensureBackpackInventory

---@param inventory OxInventory
---@return table? slotData, number? reservedSlot, number? maxArmorValue, number? utilitySlotIndex
local function findEquippedArmor(inventory)
    for index = 1, (UtilityConfig.slots or 0) do
        local reservedSlot = getReservedSlot(index)
        local slotData = inventory.items[reservedSlot]
        if slotData and slotData.name then
            local armorValue = getArmorValue(slotData.name)
            if armorValue then
                return slotData, reservedSlot, armorValue, index
            end
        end
    end
end

---@param source number
---@return boolean
function Utility.hasArmor(source)
    local inventory = Inventory(source)
    if not inventory then return false end
    return findEquippedArmor(inventory) ~= nil
end

---@param source number
---@param amount number
---@return boolean success, number|string newDurability_or_reason
function Utility.increaseArmor(source, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false, 'invalid_amount'
    end

    local inventory = Inventory(source)
    if not inventory then
        return false, 'inventory_unavailable'
    end

    local slotData, reservedSlot, armorValue = findEquippedArmor(inventory)
    if not slotData then
        return false, 'armor_not_equipped'
    end

    local metadata = cloneMetadata(slotData.metadata)
    local currentDurability = tonumber(metadata.durability) or 100

    if currentDurability >= 100 then
        return false, 'armor_already_max'
    end

    local newDurability = math.min(100, currentDurability + amount)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, reservedSlot, metadata)

    local actualArmor = math.floor(armorValue * (newDurability / 100))
    TriggerClientEvent('ox_inventory:utility:updateArmor', source, {
        slot = reservedSlot,
        value = actualArmor,
        maxValue = armorValue,
        durability = newDurability,
    })

    return true, newDurability
end

return Utility
