if not lib then return end
local AddDropProps
local RemoveDropProps
local ClearDropProps
local Inventory = {}
local canStoreItemInBackpack

---@type table<any, OxInventory>
local Inventories = {}
server.inventories = Inventories

---@class OxInventory
local OxInventory = {}
OxInventory.__index = OxInventory

---@param inv? inventory
function OxInventory:openInventory(inv)
	if not self?.player then return end

	inv = inv and inv ~= self and Inventory(inv) or nil --[[@as OxInventory?]]
	self.open = inv?.id or self.id

	if inv then
		inv:set('open', true)
		inv.openedBy[self.id] = true
	end

	TriggerEvent('ox_inventory:openedInventory', self.id, inv?.id)
end

---@param noEvent? boolean
function OxInventory:closeInventory(noEvent)
	if not self.player or not self.open then return end

	local inv = self.open ~= self.id and Inventory(self.open)

	if inv then
		inv.openedBy[self.id] = nil
		inv:set('open', false)
	end

	self.open = false
	self.currentShop = nil
	self.containerSlot = nil

	if not noEvent then
		TriggerClientEvent('ox_inventory:closeInventory', self.id, true)
	end

	TriggerEvent('ox_inventory:closedInventory', self.id, inv?.id)
end

---@alias updateSlot { item: SlotWithItem | { slot: number }, inventory: string|number }

---@param slots updateSlot[]
---@param weight { left?: number, right?: number } | number
function OxInventory:syncSlotsWithPlayer(slots, weight)
	TriggerClientEvent('ox_inventory:updateSlots', self.id, slots, weight)
end

---@param slots updateSlot[]
---@param syncOwner? boolean
function OxInventory:syncSlotsWithClients(slots, syncOwner, skipPlayer)
	for playerId in pairs(self.openedBy) do
		if self.id ~= playerId and playerId ~= skipPlayer then
            local target = Inventories[playerId]

            if target then
			    TriggerClientEvent('ox_inventory:updateSlots', playerId, slots, target.weight)
            end
		end
	end

	if syncOwner and self.player and self.id ~= skipPlayer then
		TriggerClientEvent('ox_inventory:updateSlots', self.id, slots, self.weight)
	end
end

local Vehicles = lib.load('data.vehicles')
local RegisteredStashes = {}

for _, stash in pairs(lib.load('data.stashes') or {}) do
	RegisteredStashes[stash.name] = {
		name = stash.name,
		label = stash.label,
		owner = stash.owner,
		slots = stash.slots,
		maxWeight = stash.weight,
		groups = stash.groups or stash.jobs,
		coords = shared.target and stash.target?.loc or stash.coords,
        distance = stash.distance or 10
	}
end

local GetVehicleNumberPlateText = GetVehicleNumberPlateText

---@param data table
---@param player table
---@param ignoreSecurityChecks boolean
---@return OxInventory | false | nil
local function loadInventoryData(data, player, ignoreSecurityChecks)
	local source = source
	local inventory

	if not data.type and type(data.id) == 'string' then
		if data.id:find('^glove') then
			data.type = 'glovebox'
		elseif data.id:find('^trunk') then
			data.type = 'trunk'
		elseif data.id:find('^evidence-') then
			data.type = 'policeevidence'
		end
	end

	if data.type == 'trunk' or data.type == 'glovebox' then
		local plate = data.id:sub(6)

		if server.trimplate then
			plate = string.strtrim(plate)
			data.id = ('%s%s'):format(data.id:sub(1, 5), plate)
		end

		inventory = Inventories[data.id]

		if not inventory then
			local entity

			if data.netid then
				entity = NetworkGetEntityFromNetworkId(data.netid)

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given netid).')
				end

                data.entityId = entity
			else
				local vehicles = GetAllVehicles()

				for i = 1, #vehicles do
					local vehicle = vehicles[i]
					local _plate = GetVehicleNumberPlateText(vehicle)

					if _plate:find(plate) then
						entity = vehicle
                        data.entityId = entity
						data.netid = NetworkGetNetworkIdFromEntity(entity)
						break
					end
				end

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given plate).')
				end
			end

			if not source then
				source = NetworkGetEntityOwner(entity)

				if not source then
					return shared.info('Failed to load vehicle inventory data (entity is unowned).')
				end
			end

			local model, class = lib.callback.await('ox_inventory:getVehicleData', source, data.netid)
			local storage = Vehicles[data.type].models[model] or Vehicles[data.type][class]
            local dbId

            if server.getOwnedVehicleId then
                dbId = server.getOwnedVehicleId(entity)
            else
                dbId = data.id:sub(6)
            end

            inventory = Inventory.Create(data.id, plate, data.type, storage[1], 0, storage[2], false, nil, nil, dbId)
		end
	elseif data.type == 'policeevidence' then
		inventory = Inventory.Create(data.id, locale('police_evidence'), data.type, 100, 0, 100000, false)
	else
		local stash = RegisteredStashes[data.id]

		if stash then
			if stash.jobs then stash.groups = stash.jobs end
			if not ignoreSecurityChecks and player and stash.groups and not server.hasGroup(player, stash.groups) then return end

			local owner

			if stash.owner then
				if stash.owner == true then
					owner = data.owner or player?.owner
				else
					owner = stash.owner
				end
			end

			inventory = Inventories[owner and ('%s:%s'):format(stash.name, owner) or stash.name]

			if not inventory then
				inventory = Inventory.Create(stash.name, stash.label or stash.name, 'stash', stash.slots, 0, stash.maxWeight, owner, nil, stash.groups)
                inventory.coords = stash.coords
                inventory.distance = stash.distance
                inventory.instance = stash.instance
			end
		end
	end

	if data.netid then
        inventory.entityId = data.entityId or NetworkGetEntityFromNetworkId(data.netid)
		inventory.netid = data.netid
	end

	return inventory or false
end

setmetatable(Inventory, {
	__call = function(self, inv, player, ignoreSecurityChecks)
        if Inventory.Lock then return false end

		if not inv then
			return self
		elseif type(inv) == 'table' then
			if inv.__index then return inv end

			return not inv.owner and Inventories[inv.id] or loadInventoryData(inv, player, ignoreSecurityChecks)
		end

		return Inventories[inv] or loadInventoryData({ id = inv }, player, ignoreSecurityChecks)
	end
})

---@cast Inventory +fun(inv: inventory, player?: inventory, ignoreSecurityChecks?: boolean): OxInventory|false|nil

---@param inv inventory
---@param owner? string | number
local function getInventory(inv, owner)
	if not inv then return Inventory end

	local type = type(inv)

	if type == 'table' or type == 'number' then
		return Inventory(inv)
	else
		return Inventory({ id = inv, owner = owner })
	end
end

exports('Inventory', getInventory)
exports('GetInventory', getInventory)

---@param inv inventory
---@param owner? string | number
---@return table?
exports('GetInventoryItems', function(inv, owner)
	return getInventory(inv, owner)?.items
end)

---@param inv inventory
---@param slotId number
---@return OxInventory?
function Inventory.GetContainerFromSlot(inv, slotId)
	local inventory = Inventory(inv)
	local slotData = inventory and inventory.items[slotId]

	if not slotData then return end

	local container = Inventory(slotData.metadata.container)

	if not container then
		container = Inventory.Create(slotData.metadata.container, slotData.label, 'container', slotData.metadata.size[1], 0, slotData.metadata.size[2], false)
	end

	return container
end

exports('GetContainerFromSlot', Inventory.GetContainerFromSlot)

---@param inv? inventory
---@param ignoreId? number|false
function Inventory.CloseAll(inv, ignoreId)
	if not inv then
		for _, data in pairs(Inventories) do
			for playerId in pairs(data.openedBy) do
				local playerInv = Inventory(playerId)

				if playerInv then playerInv:closeInventory(true) end
			end
		end

		return TriggerClientEvent('ox_inventory:closeInventory', -1, true)
	end

	inv = Inventory(inv) --[[@as OxInventory?]]

	if not inv then return end

	for playerId in pairs(inv.openedBy) do
		local playerInv = Inventory(playerId)

		if playerInv and playerId ~= ignoreId then
            playerInv:closeInventory()
        end
	end
end

---@param inv inventory
---@param k string
---@param v any
function Inventory.Set(inv, k, v)
	inv = Inventory(inv) --[[@as OxInventory]]

	if inv then
		if type(v) == 'number' then
			v = math.floor(v + 0.5)
		end

		if k == 'open' and v == false then
			if inv.type ~= 'player' then
				if inv.player then
					inv.type = 'player'
				elseif inv.type == 'drop' and not next(inv.items) and not next(inv.openedBy) then
					return Inventory.Remove(inv)
				else
					inv.time = os.time()
				end
			end

			if inv.player then
				inv.containerSlot = nil
			end
		elseif k == 'maxWeight' and v < 1000 then
			v *= 1000
		end

		inv[k] = v
	end
end

---@param inv inventory
---@param key string
function Inventory.Get(inv, key)
	inv = Inventory(inv) --[[@as OxInventory]]
	if inv then
		return inv[key]
	end
end

---@class MinimalInventorySlot
---@field name string
---@field count number
---@field slot number
---@field metadata? table

---@param inv inventory
---@return MinimalInventorySlot[] items
local function minimal(inv)
	inv = Inventory(inv) --[[@as OxInventory]]
	local inventory, count = {}, 0
	for k, v in pairs(inv.items) do
		if v.name and v.count > 0 then
			count += 1
			inventory[count] = {
				name = v.name,
				count = v.count,
				slot = k,
				metadata = next(v.metadata) and v.metadata or nil
			}
		end
	end
	return inventory
end

local Items = require 'modules.items.server'

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata any
---@param slot number
---@param suppressNotify? boolean
---@return boolean, string | SlotWithItem | nil
function Inventory.SetSlot(inv, item, count, metadata, slot, suppressNotify)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv?.slots then return false, 'invalid_inventory' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)

	if type(item) ~= 'table' then
		item = Items(item)

		if not item then return false, 'invalid_item' end
	end

	local currentSlot = inv.items[slot]
	local newCount = currentSlot and currentSlot.count + count or count
	local newWeight = currentSlot and inv.weight - currentSlot.weight or inv.weight

	if currentSlot and newCount < 1 then
		if not suppressNotify then
			TriggerClientEvent('ox_inventory:itemNotify', inv.id, { currentSlot, 'ui_removed', currentSlot.count })
		end
		currentSlot = nil
	else
		currentSlot = {name = item.name, label = item.label, weight = item.weight, slot = slot, count = newCount, description = item.description, metadata = metadata, stack = item.stack, close = item.close}
		local slotWeight = Inventory.SlotWeight(item, currentSlot)
		currentSlot.weight = slotWeight
		newWeight += slotWeight

		if not suppressNotify then
			TriggerClientEvent('ox_inventory:itemNotify', inv.id, { currentSlot, count < 0 and 'ui_removed' or 'ui_added', math.abs(count) })
		end
	end

	inv.weight = newWeight
	inv.items[slot] = currentSlot
	inv.changed = true

	return true, currentSlot
end

CreateThread(function()
    Inventory.accounts = server.accounts
    TriggerEvent('ox_inventory:loadInventory', Inventory)
end)

function Inventory.GetAccountItemCounts(inv)
    inv = Inventory(inv)

    if not inv then return end

    local accounts = table.clone(server.accounts)

	for _, v in pairs(inv.items) do
		if accounts[v.name] then
			accounts[v.name] += v.count
		end
	end

    return accounts
end

---@param item table
---@param slot table
function Inventory.SlotWeight(item, slot, ignoreCount)
	local weight = ignoreCount and item.weight or item.weight * (slot.count or 1)

	if not slot.metadata then slot.metadata = {} end

	if item.ammoname and slot.metadata.ammo then
		local ammoWeight = Items(item.ammoname)?.weight

		if ammoWeight then
			weight += (ammoWeight * slot.metadata.ammo)
		end
	end

    if item.hash == `WEAPON_PETROLCAN` then
        slot.metadata.weight = 15000 * (slot.metadata.ammo / 100)
    end

	if slot.metadata.components then
		for i = #slot.metadata.components, 1, -1 do
			local componentWeight = Items(slot.metadata.components[i])?.weight

			if componentWeight then
				weight += componentWeight
			end
		end
	end

	if slot.metadata.weight and not Items.containers[item.name]?.ignoreContentWeight then
		weight += ignoreCount and slot.metadata.weight or (slot.metadata.weight * (slot.count or 1))
	end

	return weight
end

---@param items table
function Inventory.CalculateWeight(items)
	local weight = 0
	for _, v in pairs(items) do
		local item = Items(v.name)
		if item then
			weight = weight + Inventory.SlotWeight(item, v)
		end
	end
	return weight
end

function Inventory.CalculateWeightInSlotRange(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv?.slots then return 0 end

	local weight = 0

	for slot = 1, inv.slots do
		local slotData = inv.items[slot]

		if slotData then
			local item = Items(slotData.name)

			if item then
				weight += slotData.weight or Inventory.SlotWeight(item, slotData)
			end
		end
	end

	return weight
end

local activeIdentifiers = {}

local function hasActiveInventory(playerId, owner)
	local activePlayer = activeIdentifiers[owner]

	if activePlayer then
        if activePlayer == playerId then
            error('attempted to load active player\'s inventory a secondary time', 0)
        end

		local inventory = Inventory(activePlayer)

		if inventory then
			local endpoint = GetPlayerEndpoint(activePlayer)

			if endpoint then
				DropPlayer(playerId, ("Character identifier '%s' is already active."):format(owner))

				print(('kicked player.%s (charid is already in use)'):format(playerId), json.encode({
					oldId = activePlayer,
					newId = playerId,
					charid = owner,
					endpoint = endpoint,
					playerName = GetPlayerName(activePlayer),
					fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
					license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
				}, {
					indent = true,
                    sort_keys = true
				}))

				return true
			end

			Inventory.CloseAll(inventory)
			db.savePlayer(owner, json.encode(inventory:minimal()))
			Inventory.Remove(inventory)
			Wait(100)
		end
	end

	activeIdentifiers[owner] = playerId
end

RegisterCommand('clearActiveIdentifier', function(source, args)
    if source ~= 0 then return end

	local activePlayer = activeIdentifiers[args[1]] or activeIdentifiers[tonumber(args[1])]
    local inventory = activePlayer and Inventory(activePlayer)

    if not inventory then return end

    local endpoint = GetPlayerEndpoint(activePlayer)

    if endpoint then
        DropPlayer(activePlayer, 'Kicked')

        print(('kicked player.%s (clearActiveIdentifier)'):format(activePlayer), json.encode({
            oldId = activePlayer,
            charid = inventory.owner,
            endpoint = endpoint,
            playerName = GetPlayerName(activePlayer),
            fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
            license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
        }, {
            indent = true,
            sort_keys = true
        }))
    end

    Inventory.CloseAll(inventory)
    db.savePlayer(inventory.owner, json.encode(inventory:minimal()))
    Inventory.Remove(inventory)
end, true)

---@param id string|number
---@param label string|nil
---@param invType string
---@param slots number
---@param weight number
---@param maxWeight number
---@param owner string | number | boolean
---@param items? table
---@param dbId? string | number
---@return OxInventory?
function Inventory.Create(id, label, invType, slots, weight, maxWeight, owner, items, groups, dbId)
	if invType == 'player' and hasActiveInventory(id, owner) then return end

	local self = {
		id = id,
		label = label or id,
		type = invType,
		slots = slots,
		weight = weight,
		maxWeight = maxWeight or shared.playerweight,
		owner = owner,
		items = type(items) == 'table' and items,
		open = false,
		set = Inventory.Set,
		get = Inventory.Get,
		minimal = minimal,
		time = os.time(),
		groups = groups,
		openedBy = {},
        dbId = dbId
	}

	if invType == 'drop' or invType == 'temp' or invType == 'dumpster' then
		self.datastore = true
	else
		self.changed = false

		if invType ~= 'glovebox' and invType ~= 'trunk' then
			self.dbId = id

			if invType ~= 'player' and owner and type(owner) ~= 'boolean' then
				self.id = ('%s:%s'):format(self.id, owner)
			end
		end
	end

	if not items then
		self.items, self.weight = Inventory.Load(self.dbId, invType, owner)
	elseif weight == 0 and next(items) then
		self.weight = Inventory.CalculateWeight(items)
	end

	Inventories[self.id] = setmetatable(self, OxInventory)
	return Inventories[self.id]
end

---@param inv inventory
function Inventory.Remove(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local ownedBackpacks

	if inv.type == 'drop' then
		ClearDropProps(inv.id)
		TriggerClientEvent('ox_inventory:removeDrop', -1, inv.id)
		Inventory.Drops[inv.id] = nil
	elseif inv.player then
		activeIdentifiers[inv.owner] = nil

		for _, itemData in pairs(inv.items) do
			if itemData and itemData.metadata then
				local containerId = itemData.metadata.container or itemData.metadata.backpackId
				if containerId then
					local backpack = Inventories[containerId]
					if backpack and backpack.type == 'backpack' then
						ownedBackpacks = ownedBackpacks or {}
						ownedBackpacks[#ownedBackpacks + 1] = backpack
					end
				end
			end
		end
	end

    for playerId in pairs(inv.openedBy) do
        if inv.id ~= playerId then
            local target = Inventories[playerId]

            if target then
                target:closeInventory()
            end
        end
    end

    if not inv.datastore and (inv.changed or inv.player) then
        Inventory.Save(inv)
    end

	Inventories[inv.id] = nil

	if ownedBackpacks then
		for i = 1, #ownedBackpacks do
			local backpack = ownedBackpacks[i]

			if backpack then
				Inventory.Remove(backpack)
			end
		end
	end
end

exports('RemoveInventory', Inventory.Remove)

---@param oldPlate string
---@param newPlate string
function Inventory.UpdateVehicle(oldPlate, newPlate)
	oldPlate = oldPlate:upper()
	newPlate = newPlate:upper()

	if server.trimplate then
		oldPlate = string.strtrim(oldPlate)
		newPlate = string.strtrim(newPlate)
	end

	local trunk = Inventory(('trunk%s'):format(oldPlate))
	local glove = Inventory(('glove%s'):format(oldPlate))

	if trunk then
		Inventory.CloseAll(trunk)

		Inventories[trunk.id] = nil
		trunk.label = newPlate
		trunk.dbId = type(trunk.id) == 'number' and trunk.dbId or newPlate
		trunk.id = ('trunk%s'):format(newPlate)
		Inventories[trunk.id] = trunk
	end

	if glove then
		Inventory.CloseAll(glove)

		Inventories[glove.id] = nil
		glove.label = newPlate
		glove.dbId = type(glove.id) == 'number' and glove.dbId or newPlate
		glove.id = ('glove%s'):format(newPlate)
		Inventories[glove.id] = glove
	end
end

exports('UpdateVehicle', Inventory.UpdateVehicle)

function Inventory.Save(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv or inv.datastore then return end

    local buffer, n = {}, 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, os.time()) then
            n += 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
    end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false

    if inv.player then
        return shared.framework ~= 'esx' and db.savePlayer(inv.owner, data)
    elseif inv.type == 'trunk' then
        return db.saveTrunk(inv.dbId, data)
    elseif inv.type == 'glovebox' then
        return db.saveGlovebox(inv.dbId, data)
    end

    return db.saveStash(inv.owner, inv.dbId, data)
end

---@alias RandomLoot { [1]: string, [2]: number, [3]: number, [4]?: number }

---@param loot RandomLoot[]
---@param items RandomLoot[]
---@param size number
---@return RandomLoot
local function randomItem(loot, items, size)
    local itemIndex = math.random(1, size)
    local selectedItem = nil

    for _ = 1, size do
        selectedItem = loot[itemIndex]
        local found = false

        for i = 1, #items do
            if items[i][1] == selectedItem[1] then
                found = true
                break
            end
        end

        if not found then break end

        itemIndex = ((itemIndex - 1) % size) + 1
    end

    return selectedItem
end

---@param loot RandomLoot[]
---@return RandomLoot[]
local function randomLoot(loot)
    ---@type RandomLoot[]
    local items = {}
    local size = #loot
    local itemCount = math.random(0, 3)

    for _ = 1, itemCount do
        if #items >= size then break end

        local item = randomItem(loot, items, size)

        if item and math.random(1, 100) <= (item[4] or 80) then
            local count = math.random(item[2], item[3])

            if count > 0 then
                items[#items + 1] = { item[1], count }
            end
        end
    end

    return items
end

---@param inv inventory
---@param invType string
---@param items? table
---@return table returnData, number totalWeight
local function generateItems(inv, invType, items)
	if items == nil then
		if invType == 'dumpster' then
			items = randomLoot(server.dumpsterloot)
		elseif invType == 'vehicle' then
			items = randomLoot(server.vehicleloot)
		end
	end

	if not items then
		items = {}
	end

	local returnData, totalWeight = table.create(#items, 0), 0
	for i = 1, #items do
		local v = items[i]
		local item = Items(v[1])
		if not item then
			warn('unable to generate', v[1], 'item does not exist')
		else
			local metadata, count = Items.Metadata(inv, item, v[3] or {}, v[2])
			local weight = Inventory.SlotWeight(item, {count=count, metadata=metadata})
			totalWeight = totalWeight + weight
			returnData[i] = {name = item.name, label = item.label, weight = weight, slot = i, count = count, description = item.description, metadata = metadata, stack = item.stack, close = item.close}
		end
	end

	return returnData, totalWeight
end

---@param id string|number
---@param invType string
---@param owner string | number | boolean
function Inventory.Load(id, invType, owner)
    if not invType then return end

	local result

    if invType == 'trunk' or invType == 'glovebox' then
        result = id and (invType == 'trunk' and db.loadTrunk(id) or db.loadGlovebox(id))

        if not result then
            if server.randomloot then
                return generateItems(id, 'vehicle')
            end
        else
            result = result[invType]
        end
	elseif invType == 'dumpster' then
		if server.randomloot then
			return generateItems(id, invType)
		end
	elseif id then
		result = db.loadStash(owner or '', id)
		if invType == 'backpack' then
			result = db.migrateBackpack(id) or result
		end
	end

	local returnData, weight = {}, 0

	if result and type(result) == 'string' then
		result = json.decode(result)
	end

	if result then
		local ostime = os.time()

		for _, v in pairs(result) do
			local item = Items(v.name)
			if item then
				v.metadata = Items.CheckMetadata(v.metadata or {}, item, v.name, ostime)
				local slotWeight = Inventory.SlotWeight(item, v)
				weight += slotWeight
				returnData[v.slot] = {name = item.name, label = item.label, weight = slotWeight, slot = v.slot, count = v.count, description = item.description, metadata = v.metadata, stack = item.stack, close = item.close}
			end
		end
	end

	return returnData, weight
end

local function assertMetadata(metadata)
	if metadata and type(metadata) ~= 'table' then
		metadata = metadata and { type = metadata or nil }
	end

	return metadata
end

---@param inv inventory
---@param item table | string
---@param metadata? any
---@param returnsCount? boolean
---@return table | number | nil
function Inventory.GetItem(inv, item, metadata, returnsCount)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		item = returnsCount and item or table.clone(item)
		inv = Inventory(inv) --[[@as OxInventory]]
		local count = 0

		if inv then
			local ostime = os.time()
			metadata = assertMetadata(metadata)

			for _, v in pairs(inv.items) do
				if v.name == item.name and (not metadata or table.contains(v.metadata, metadata)) and not Items.UpdateDurability(inv, v, item, nil, ostime) then
                    count += v.count
				end
			end
		end

		if returnsCount then return count else
			item.count = count
			return item
		end
	end
end
exports('GetItem', Inventory.GetItem)

---@param fromInventory any
---@param toInventory any
---@param slot1 number
---@param slot2 number
function Inventory.SwapSlots(fromInventory, toInventory, slot1, slot2)
	local fromSlot = fromInventory.items[slot1] and table.clone(fromInventory.items[slot1]) or nil
	local toSlot = toInventory.items[slot2] and table.clone(toInventory.items[slot2]) or nil

	if fromSlot then fromSlot.slot = slot2 end
	if toSlot then toSlot.slot = slot1 end

	fromInventory.items[slot1], toInventory.items[slot2] = toSlot, fromSlot
	fromInventory.changed, toInventory.changed = true, true

	return fromSlot, toSlot
end
exports('SwapSlots', Inventory.SwapSlots)

function Inventory.ContainerWeight(container, metaWeight, playerInventory)
	playerInventory.weight -= container.weight
	container.weight = Items(container.name).weight

	if Items.containers[container.name]?.ignoreContentWeight then
		container.metadata.weight = nil
	else
		container.weight += metaWeight
		container.metadata.weight = metaWeight
	end

	playerInventory.weight += container.weight
end

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table
function Inventory.SetItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if item and count >= 0 then
		inv = Inventory(inv) --[[@as OxInventory]]

		if inv then
			inv.changed = true
			local itemCount = Inventory.GetItem(inv, item.name, metadata, true) --[[@as number]]

			if count > itemCount then
				count -= itemCount
				return Inventory.AddItem(inv, item.name, count, metadata)
			elseif count <= itemCount then
				itemCount -= count
				return Inventory.RemoveItem(inv, item.name, itemCount, metadata)
			end
		end
	end
end
exports('SetItem', Inventory.SetItem)

---@param inv inventory
function Inventory.GetCurrentWeapon(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if inv?.player then
		local weapon = inv.items[inv.weapon]

		if weapon and Items(weapon.name).weapon then
			return weapon
		end

		inv.weapon = nil
	end
end
exports('GetCurrentWeapon', Inventory.GetCurrentWeapon)

---@param inv inventory
---@param slotId number
---@return table? item
function Inventory.GetSlot(inv, slotId)
	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if slot and not Items.UpdateDurability(inv, slot, Items(slot.name), nil, os.time()) then
        return slot
	end
end
exports('GetSlot', Inventory.GetSlot)

---@param inv inventory
---@param slotId number
function Inventory.SetDurability(inv, slotId, durability)
	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if not slot then return end

    Items.UpdateDurability(inv, slot, Items(slot.name), durability)

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end
end
exports('SetDurability', Inventory.SetDurability)

local Utils = require 'modules.utils.server'

---@param inv inventory
---@param slotId number
---@param metadata { [string]: any }
function Inventory.SetMetadata(inv, slotId, metadata)
	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if not slot then return end

    local item = Items(slot.name)
    local imageurl = slot.metadata.imageurl
    slot.metadata = type(metadata) == 'table' and metadata or { type = metadata or nil }
    inv.changed = true

    if metadata.weight then
        inv.weight -= slot.weight
        slot.weight = Inventory.SlotWeight(item, slot)
        inv.weight += slot.weight
    end

    if metadata.durability ~= slot.metadata.durability then
        Items.UpdateDurability(inv, slot, item, metadata.durability)
    else
        inv:syncSlotsWithClients({
            {
                item = slot,
                inventory = inv.id
            }
        }, true)
    end

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end

    if metadata.imageurl ~= imageurl and Utils.IsValidImageUrl then
        if Utils.IsValidImageUrl(metadata.imageurl) then
            Utils.DiscordEmbed('Valid image URL', ('Updated item "%s" (%s) with valid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 65280)
        else
            Utils.DiscordEmbed('Invalid image URL', ('Updated item "%s" (%s) with invalid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 16711680)
            metadata.imageurl = nil
        end
    end
end

exports('SetMetadata', Inventory.SetMetadata)

---@param inv inventory
---@param slots number
function Inventory.SetSlotCount(inv, slots)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end
	if type(slots) ~= 'number' then return end

	inv.changed = true
	inv.slots = slots

	if inv.player then
        TriggerClientEvent('ox_inventory:refreshSlotCount', inv.id, {inventoryId = inv.id, slots = inv.slots})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('ox_inventory:refreshSlotCount', playerId, {inventoryId = inv.id, slots = inv.slots})
        end
	end
end

exports('SetSlotCount', Inventory.SetSlotCount)

---@param inv inventory
---@param maxWeight number
function Inventory.SetMaxWeight(inv, maxWeight)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end
	if type(maxWeight) ~= 'number' then return end

	inv.maxWeight = maxWeight

    if inv.player then
        TriggerClientEvent('ox_inventory:refreshMaxWeight', inv.id, {inventoryId = inv.id, maxWeight = inv.maxWeight})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('ox_inventory:refreshMaxWeight', playerId, {inventoryId = inv.id, maxWeight = inv.maxWeight})
        end
	end
end

exports('SetMaxWeight', Inventory.SetMaxWeight)

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table | string
---@param slot? number
---@param cb? fun(success?: boolean, response: string|SlotWithItem|nil)
---@param suppressNotify? boolean
---@return boolean? success, string|SlotWithItem|nil response
function Inventory.AddItem(inv, item, count, metadata, slot, cb, suppressNotify)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end

	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv?.slots then return false, 'invalid_inventory' end

	if inv.type == 'backpack' and not canStoreItemInBackpack(inv, item.name) then
		return false, 'backpack_blacklisted_item'
	end

	local toSlot, slotMetadata, slotCount
	local success, response = false
	count = math.floor(count + 0.5)
	metadata = assertMetadata(metadata)

	if slot then
		local slotData = inv.items[slot]
		slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

		if not slotData or (item.stack and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata)) then
			toSlot = slot
		end
	end

	if not toSlot then
		local items = inv.items
		slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

		for i = 1, inv.slots do
			local slotData = items[i]

			if item.stack and slotData ~= nil and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata) then
				toSlot = i
				break
			elseif not item.stack and not slotData then
				if not toSlot then toSlot = {} end

				toSlot[#toSlot + 1] = { slot = i, count = slotCount, metadata = slotMetadata }

				if count == slotCount then
					break
				end

				count -= 1
				slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)
			elseif not toSlot and not slotData then
				toSlot = i
			end
		end
	end

	if not toSlot then return false, 'inventory_full' end

	inv.changed = true

	local previousSlotCounts

	if inv.type == 'drop' then
		local slotType = type(toSlot)

		if slotType == 'number' then
			local slotData = inv.items[toSlot]
			previousSlotCounts = slotData and slotData.count or 0
		elseif slotType == 'table' then
			previousSlotCounts = {}

			for i = 1, #toSlot do
				local slotInfo = toSlot[i]
				local slotId = slotInfo.slot
				local slotData = inv.items[slotId]
				previousSlotCounts[slotId] = slotData and slotData.count or 0
			end
		end
	end

	local invokingResource = server.loglevel > 1 and GetInvokingResource()
	local toSlotType = type(toSlot)

	if toSlotType == 'number' then
		Inventory.SetSlot(inv, item, slotCount, slotMetadata, toSlot, suppressNotify)

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients({
			{
				item = inv.items[toSlot],
				inventory = inv.id
			}
		}, true)

		if invokingResource then
			lib.logger(inv.owner, 'addItem', ('"%s" added %sx %s to "%s"'):format(invokingResource, count, item.name, inv.label))
		end

		success = true
		response = inv.items[toSlot]
	elseif toSlotType == 'table' then
		local added = 0

		for i = 1, #toSlot do
			local data = toSlot[i]
			added += data.count
			Inventory.SetSlot(inv, item, data.count, data.metadata, data.slot, suppressNotify)
			toSlot[i] = { item = inv.items[data.slot], inventory = inv.id }
		end

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients(toSlot, true)

		if invokingResource then
			lib.logger(inv.owner, 'addItem', ('"%s" added %sx %s to "%s"'):format(invokingResource, added, item.name, inv.label))
		end

		for i = 1, #toSlot do
			toSlot[i] = toSlot[i].item
		end

		success = true
		response = toSlot
	end

	if success and inv.type == 'drop' then
		local itemsToAdd

		if toSlotType == 'number' then
			local slotItem = response

			if slotItem then
				local prev = type(previousSlotCounts) == 'number' and previousSlotCounts or 0
				local delta = slotItem.count - prev

				if delta > 0 then
					itemsToAdd = {
						{
							name = slotItem.name,
							count = delta,
							slot = slotItem.slot
						}
					}
				end
			end
		elseif toSlotType == 'table' and type(response) == 'table' then
			local idx = 0
			itemsToAdd = {}

			for i = 1, #response do
				local slotItem = response[i]

				if slotItem then
					local prev = type(previousSlotCounts) == 'table' and previousSlotCounts[slotItem.slot] or 0
					local delta = slotItem.count - prev

					if delta > 0 then
						idx += 1
						itemsToAdd[idx] = {
							name = slotItem.name,
							count = delta,
							slot = slotItem.slot
						}
					end
				end
			end

			if idx == 0 then
				itemsToAdd = nil
			end
		end

		if itemsToAdd and itemsToAdd[1] then
			AddDropProps(inv.id, itemsToAdd, inv.coords)
		end
	end

	if cb then
		return cb(success, response)
	end

	if success and inv and inv.id then
		TriggerEvent('ox_inventory:inventoryChanged', inv.id)
	end

	return success, response
end

exports('AddItem', Inventory.AddItem)

---@param inv inventory
---@param search string|number slots|1, count|2
---@param items table | string
---@param metadata? table | string
function Inventory.Search(inv, search, items, metadata)
	if items then
		inv = Inventory(inv) --[[@as OxInventory]]

		if inv then
			inv = inv.items

			if search == 'slots' then search = 1 elseif search == 'count' then search = 2 end
			if type(items) == 'string' then items = {items} end

			metadata = assertMetadata(metadata)
			local itemCount = #items
			local returnData = {}

			for i = 1, itemCount do
				local item = string.lower(items[i])
				if item:sub(0, 7) == 'weapon_' then item = string.upper(item) end

				if search == 1 then
					returnData[item] = {}
				elseif search == 2 then
					returnData[item] = 0
				end

				for _, v in pairs(inv) do
					if v.name == item then
						if not v.metadata then v.metadata = {} end

						if not metadata or table.contains(v.metadata, metadata) then
							if search == 1 then
								returnData[item][#returnData[item]+1] = inv[v.slot]
							elseif search == 2 then
								returnData[item] += v.count
							end
						end
					end
				end
			end

			if next(returnData) then return itemCount == 1 and returnData[items[1]] or returnData end
		end
	end

	return false
end
exports('Search', Inventory.Search)

---@param inv inventory
---@param item table | string
---@param metadata? table
---@param strict? boolean
function Inventory.GetItemSlots(inv, item, metadata, strict)
	if type(item) ~= 'table' then item = Items(item) end
	if not item then return end

	inv = Inventory(inv) --[[@as OxInventory]]
	if not inv?.slots then return end

	local totalCount, slots, emptySlots = 0, {}, inv.slots

	if strict == nil then strict = true end
	local tablematch = strict and table.matches or table.contains

	for k, v in pairs(inv.items) do
		if type(k) == 'number' and k >= 1 and k <= inv.slots then
			emptySlots -= 1

			if v.name == item.name then
				if metadata and v.metadata == nil then
					v.metadata = {}
				end
				if not metadata or tablematch(v.metadata, metadata) then
					totalCount = totalCount + v.count
					slots[k] = v.count
				end
			end
		end
	end

	return slots, totalCount, emptySlots
end
exports('GetItemSlots', Inventory.GetItemSlots)

---@param inv inventory
---@param item table | string
---@param count integer
---@param metadata? table | string
---@param slot? number
---@param ignoreTotal? boolean
---@param strict? boolean
---@return boolean? success, string? response
function Inventory.RemoveItem(inv, item, count, metadata, slot, ignoreTotal, strict)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end

	inv = Inventory(inv) --[[@as OxInventory]]

	local dropRemovals = inv?.type == 'drop' and {} or nil

	if count == nil then
		if slot and inv.items and inv.items[slot] then
			count = inv.items[slot].count
		else
			count = 1
		end
	end

	count = math.floor(count + 0.5)

	if count > 0 then

		if not inv?.slots then return false, 'invalid_inventory' end

		if slot then
			local slotItem = inv.items[slot]

			if not slotItem then
				return false, 'no_item_in_slot'
			end

			if count > slotItem.count then
				if not ignoreTotal then return false, 'not_enough_items_in_slot' end

				count = slotItem.count
			end
		end

		metadata = assertMetadata(metadata)
		if strict == nil then strict = true end
		local itemSlots, totalCount = Inventory.GetItemSlots(inv, item, metadata, strict)

		if not itemSlots then return false end

		if totalCount and count > totalCount then
			if not ignoreTotal then return false, 'not_enough_items' end

			count = totalCount
		end

		local removed, total, slots = 0, count, {}

		if slot and itemSlots[slot] then
			local slotData = inv.items[slot]

			if dropRemovals and slotData then
				dropRemovals[#dropRemovals + 1] = {
					name = slotData.name,
					count = count,
					slot = slot
				}
			end

			removed = count
			local ok, result = Inventory.SetSlot(inv, item, -count, inv.items[slot].metadata, slot)

			if not ok then
				error(('Failed to remove %sx %s from inventory-%s:slot-%s (%s).'):format(count, item.name, inv.id, slot, result))
			end

			slots[#slots+1] = inv.items[slot] or slot
		elseif itemSlots and totalCount > 0 then
			for k, v in pairs(itemSlots) do
			if removed < total then
				local slotItem = inv.items[k]

				if v == count then
					if dropRemovals and slotItem then
						dropRemovals[#dropRemovals + 1] = {
							name = slotItem.name,
							count = count,
							slot = slotItem.slot or k
						}
					end

					TriggerClientEvent('ox_inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = total
					inv.weight -= inv.items[k].weight
					inv.items[k] = nil
					slots[#slots+1] = inv.items[k] or k
				elseif v > count then
					if dropRemovals and slotItem then
						dropRemovals[#dropRemovals + 1] = {
							name = slotItem.name,
							count = count,
							slot = slotItem.slot or k
						}
					end

					local ok, result = Inventory.SetSlot(inv, item, -count, inv.items[k].metadata, k)

					if not ok then
						error(('Failed to remove %sx %s from inventory-%s:slot-%s (%s).'):format(count, item.name, inv.id, k, result))
					end

					slots[#slots+1] = inv.items[k] or k
					removed = total
					count = v - count
				else
					if dropRemovals and slotItem then
						dropRemovals[#dropRemovals + 1] = {
							name = slotItem.name,
							count = v,
							slot = slotItem.slot or k
						}
					end

					TriggerClientEvent('ox_inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = removed + v
					count = count - v
					inv.weight -= inv.items[k].weight
					inv.items[k] = nil
					slots[#slots+1] = k
				end
				else break end
			end
		end

		if removed > 0 then
			inv.changed = true

			if inv.player and server.syncInventory then
				server.syncInventory(inv)
			end

			local array = table.create(#slots, 0)

			for k, v in pairs(slots) do
				array[k] = {item = type(v) == 'number' and { slot = v } or v, inventory = inv.id}
			end

			inv:syncSlotsWithClients(array, true)

			local invokingResource = server.loglevel > 1 and GetInvokingResource()

			if invokingResource then
			end

			if dropRemovals then
				for i = 1, #dropRemovals do
					local entry = dropRemovals[i]

					if entry and entry.name and entry.count and entry.count > 0 then
						RemoveDropProps(inv.id, entry.name, entry.slot, entry.count)
					end
				end
			end

			return true
		end
	end

	return false, 'not_enough_items'
end
exports('RemoveItem', Inventory.RemoveItem)

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table | string
function Inventory.CanCarryItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		inv = Inventory(inv) --[[@as OxInventory]]

		if inv then
			local metadataFilter = type(metadata) == 'table' and metadata or { type = metadata or nil }
			local itemSlots, _, emptySlots = Inventory.GetItemSlots(inv, item, metadataFilter)

			if not itemSlots then
				return
			end

			local weight = metadata and metadata.weight or item.weight

			if metadata and Items.containers[item.name]?.ignoreContentWeight then
				weight = item.weight
			end

			local carryWeight = inv.player and Inventory.CalculateWeightInSlotRange(inv) or inv.weight
			local requestedCount = count or 1

			if next(itemSlots) or emptySlots > 0 then
				if not item.stack and emptySlots < requestedCount then
					return false
				end

				if weight == 0 then
					return true
				end

				local newWeight = carryWeight + (weight * requestedCount)

				if newWeight > inv.maxWeight then
					return false
				end

				return true
			end
		end
	end
end
exports('CanCarryItem', Inventory.CanCarryItem)

---@param inv inventory
---@param item table | string
function Inventory.CanCarryAmount(inv, item)
    if type(item) ~= 'table' then item = Items(item) end
	inv = Inventory(inv) --[[@as OxInventory]]

    if inv and item then
		local currentWeight = inv.player and Inventory.CalculateWeightInSlotRange(inv) or inv.weight
		local availableWeight = inv.maxWeight - currentWeight
		return math.floor(availableWeight / item.weight)
    end
end

exports('CanCarryAmount', Inventory.CanCarryAmount)

---@param inv inventory
---@param weight number
function Inventory.CanCarryWeight(inv, weight)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local currentWeight = inv.player and Inventory.CalculateWeightInSlotRange(inv) or inv.weight
	local availableWeight = inv.maxWeight - currentWeight
	local canHold = availableWeight >= weight
	return canHold, availableWeight
end
exports('CanCarryWeight', Inventory.CanCarryWeight)

---@param inv inventory
---@param firstItem string
---@param firstItemCount number
---@param testItem string
---@param testItemCount number
function Inventory.CanSwapItem(inv, firstItem, firstItemCount, testItem, testItemCount)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local firstItemData = Inventory.GetItem(inv, firstItem)
	local testItemData = Inventory.GetItem(inv, testItem)

	if firstItemData and testItemData and firstItemData.count >= firstItemCount then
		local currentWeight = inv.player and Inventory.CalculateWeightInSlotRange(inv) or inv.weight
		local weightWithoutFirst = currentWeight - (firstItemData.weight * firstItemCount)
		local weightWithTest = weightWithoutFirst + (testItemData.weight * testItemCount)
		return weightWithTest <= inv.maxWeight
	end
end
exports('CanSwapItem', Inventory.CanSwapItem)

---@param name string
---@param count number
---@param metadata { [string]: any }
---@param slot number
RegisterServerEvent('ox_inventory:removeItem', function(name, count, metadata, slot)
	Inventory.RemoveItem(source, name, count, metadata, slot)
end)

Inventory.Drops = {}

exports('GetDrops', function()
	local drops = {}

	for dropId, drop in pairs(Inventory.Drops) do
		local inventory = Inventories[dropId]

		drops[#drops + 1] = {
			id = dropId,
			coords = drop.coords,
			instance = drop.instance,
			label = inventory and inventory.label or dropId,
			weight = inventory and inventory.weight or 0,
			maxWeight = inventory and inventory.maxWeight or 0,
			slots = inventory and inventory.slots or 0,
		}
	end

	return drops
end)

local dropPropConfig = {
	enabled = true,
	oneItemOneProp = GetConvarInt('inventory:oneitemoneprop', 1) == 1,
	defaultModel = "hei_prop_hei_paper_bag"
}

local function normaliseModel(model)
	if type(model) == 'number' then
		return model
	elseif type(model) == 'string' and model ~= '' then
		return model
	end

	return dropPropConfig.defaultModel
end

local function setupDropEntry(dropId)
	local drop = Inventory.Drops[dropId]

	if drop then
		drop.itemProps = drop.itemProps or {}
		drop.propLookup = drop.propLookup or {}
		drop.netLookup = drop.netLookup or {}
		drop.oneItemOneProp = drop.oneItemOneProp ~= nil and drop.oneItemOneProp or dropPropConfig.oneItemOneProp
		drop.hasPropObjects = dropPropConfig.enabled and drop.hasPropObjects ~= false or false
	end

	return drop
end

local function GenerateUniqueItemId(dropId, itemName, slotRef, index)
	return ('%s_%s_%s_%d_%d'):format(dropId, itemName or 'unknown', slotRef or 'slot', index or 1, math.random(10000, 99999))
end

local function CalculateItemPosition(baseCoords, index, totalItems, baseZ)
	if index == 1 then
		return vector3(baseCoords.x, baseCoords.y, baseZ or baseCoords.z)
	end

	local zoneType = math.random(1, 3)
	local radius

	if zoneType == 1 then
		radius = 0.15 + math.random() * 0.25
	elseif zoneType == 2 then
		radius = 0.4 + math.random() * 0.3
	else
		radius = 0.7 + math.random() * 0.4
	end

	local angle = math.random() * 360
	local radians = math.rad(angle)
	local scatterX = (math.random() - 0.5) * 0.25
	local scatterY = (math.random() - 0.5) * 0.25

	return vector3(
		baseCoords.x + (radius * math.cos(radians)) + scatterX,
		baseCoords.y + (radius * math.sin(radians)) + scatterY,
		baseZ or baseCoords.z
	)
end

function GetDropItemModel(itemName, src)
	local src = source or src
	local isWeapon = false
	if type(itemName) == 'string' then
		if itemName:upper():find('^WEAPON_') then
			isWeapon = true
		end
	elseif type(itemName) == 'number' then
		if itemName:upper():find('^WEAPON_') then
			isWeapon = true
		end
	end

	if src and isWeapon then
		local resolvedWeaponModel = lib.callback.await('ox_inventory:resolveModelOnClient', src, itemName)
		if resolvedWeaponModel and resolvedWeaponModel ~= 0 then
			return resolvedWeaponModel
		end
	end

    local item = Items(itemName)
    if item then
        if type(item.client) == 'table' then
            local clientData = item.client

            if clientData.dropModel then
                return normaliseModel(clientData.dropModel)
            end

            local prop = clientData.prop
            if type(prop) == 'table' and prop.modelp then
                return normaliseModel(prop.modelp)
            elseif prop then
                return normaliseModel(prop)
            end

            if clientData.modelp then
                return normaliseModel(clientData.modelp)
            end
        elseif item.client then
            return normaliseModel(item.client)
        end

        if item.modelp and not item.weapon then
            return normaliseModel(item.modelp)
        end
    end

    return dropPropConfig.defaultModel
end

AddDropProps = function(dropId, items, baseCoords, targetSource, modelOverride)
	if not dropPropConfig.enabled or not items then return end

	local drop = setupDropEntry(dropId)

	if not drop then return end

	local coords = baseCoords or drop.coords

	if not coords then return end

	local baseZ = drop.baseZ or coords.z
	local currentCount = #drop.itemProps

	for i = 1, #items do
		local itemData = items[i]
		local itemName = itemData.name

		if itemName then
			local amount = itemData.count or itemData.amount or 1
			local slot = itemData.slot or itemData.slotRef
			local model = modelOverride or GetDropItemModel(itemName, targetSource)
			local createCount = drop.oneItemOneProp and 1 or amount

			for index = 1, createCount do
				local uniqueId = GenerateUniqueItemId(dropId, itemName, slot, index)

				if not drop.propLookup[uniqueId] then
					currentCount += 1

					local position = CalculateItemPosition(coords, currentCount, currentCount + 10, baseZ)
					local entry = {
						uniqueId = uniqueId,
						itemName = itemName,
						slot = slot,
						modelp = model,
						coords = position,
						netId = nil,
						propIndex = index
					}

					drop.itemProps[#drop.itemProps + 1] = entry
					drop.propLookup[uniqueId] = entry
				end
			end
		end
	end

	drop.hasPropObjects = drop.hasPropObjects or #drop.itemProps > 0
	Inventory.Drops[dropId].itemProps = drop.itemProps

	TriggerClientEvent('ox_inventory:updateDropProps', -1, dropId, drop.itemProps)
end

RemoveDropProps = function(dropId, itemName, slot, amount)
	if not dropPropConfig.enabled then return end

	local drop = Inventory.Drops[dropId]

	if not drop or not drop.itemProps then return end

	local required = drop.oneItemOneProp and 1 or (amount or 1)
	local removed = 0

	for index = #drop.itemProps, 1, -1 do
		local entry = drop.itemProps[index]

		if entry.itemName == itemName and (slot == nil or entry.slot == slot) then
			local netId = entry.netId

			drop.propLookup[entry.uniqueId] = nil
			table.remove(drop.itemProps, index)
			removed += 1

			TriggerClientEvent('ox_inventory:removeDropProp', -1, nil, entry.uniqueId)

			if removed >= required then
				break
			end
		end
	end

	if #drop.itemProps == 0 then
		drop.baseZ = nil
		drop.hasPropObjects = false
	end
end

ClearDropProps = function(dropId)
	if not dropPropConfig.enabled then return end

	local drop = Inventory.Drops[dropId]

	if not drop or not drop.itemProps then return end

	for index = #drop.itemProps, 1, -1 do
		local entry = drop.itemProps[index]

		drop.propLookup[entry.uniqueId] = nil
		drop.itemProps[index] = nil

		TriggerClientEvent('ox_inventory:removeDropProp', -1, nil, entry.uniqueId)
	end

	drop.itemProps = {}
	drop.propLookup = {}
	drop.baseZ = nil
	drop.hasPropObjects = false
	drop.netLookup = {}
end

RegisterNetEvent('ox_inventory:registerDropProp', function(uniqueId, netId, finalCoords)
	if not uniqueId or not netId then return end

	for dropId, drop in pairs(Inventory.Drops) do
		if drop.propLookup then
			local entry = drop.propLookup[uniqueId]

			if entry then
				local previousNetId = entry.netId
				entry.netId = netId
				drop.hasPropObjects = true

				if previousNetId and drop.netLookup then
					drop.netLookup[previousNetId] = nil

					if previousNetId ~= netId then
						TriggerClientEvent('ox_inventory:removeDropProp', -1, previousNetId, uniqueId)
					end
				end

				if finalCoords then
					entry.coords = finalCoords

					if not drop.baseZ then
						drop.baseZ = finalCoords.z
					end
				end

				drop.netLookup = drop.netLookup or {}
				drop.netLookup[netId] = uniqueId

				TriggerClientEvent('ox_inventory:updateDropProp', -1, {
					dropId = dropId,
					uniqueId = uniqueId,
					netId = netId,
					coords = entry.coords
				})
				return
			end
		end
	end
end)
---@param prefix string?
---@return string
local function generateInvId(prefix)
	while true do
		local invId = ('%s-%s'):format(prefix or 'drop', math.random(100000, 999999))

		if not Inventories[invId] then return invId end

		Wait(0)
	end
end

local function CustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('%s %s'):format(prefix, dropId:gsub('%D', '')), 'drop', slots or shared.dropslots, 0, maxWeight or shared.dropweight, false, {})

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', items)
	inventory.coords = coords
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = instance,
		model = model,
	}

	local dropData = setupDropEntry(dropId)

	if dropPropConfig.enabled and dropData and inventory.items and next(inventory.items) ~= nil then
		local propItems, count = {}, 0

		for slot, item in pairs(inventory.items) do
			count += 1
			propItems[count] = {
				name = item.name,
				count = item.count,
				slot = slot
			}
		end

		if count > 0 then
			AddDropProps(dropId, propItems, inventory.coords, source, model)
		end
	end

	if dropData then
		dropData.hasPropObjects = dropPropConfig.enabled and dropData.itemProps and #dropData.itemProps > 0 or false
	end

	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

    return dropId
end

AddEventHandler('ox_inventory:customDrop', CustomDrop)
exports('CustomDrop', CustomDrop)

exports('CreateDropFromPlayer', function(playerId)
	local playerInventory = Inventory(playerId)

	if not playerInventory or not next(playerInventory.items) then return end

	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', playerInventory.slots, playerInventory.weight, playerInventory.maxWeight, false, table.clone(playerInventory.items))

	if not inventory then return end

	local coords = GetEntityCoords(GetPlayerPed(playerId))
	inventory.coords = vec3(coords.x, coords.y, coords.z-0.2)
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = Player(playerId).state.instance
	}

	local dropData = setupDropEntry(dropId)

	if dropPropConfig.enabled and dropData and inventory.items and next(inventory.items) ~= nil then
		local propItems, count = {}, 0

		for slot, item in pairs(inventory.items) do
			count += 1
			propItems[count] = {
				name = item.name,
				count = item.count,
				slot = slot
			}
		end

		if count > 0 then
			AddDropProps(dropId, propItems, inventory.coords)
		end
	end

	if dropData then
		dropData.hasPropObjects = dropPropConfig.enabled and dropData.itemProps and #dropData.itemProps > 0 or false
	end

	Inventory.Clear(playerInventory)
	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

	return dropId
end)

local TriggerEventHooks = require 'modules.hooks.server'

---@class SwapSlotData
---@field count number
---@field fromSlot number
---@field toSlot number
---@field instance any
---@field fromType string
---@field toType string
---@field coords? vector3

---@param source number
---@param fromInventory OxInventory -- inventory the item is coming from (may be a backpack, container or player)
---@param fromData SlotWithItem?
---@param data SwapSlotData
local function dropItem(source, fromInventory, fromData, data)
	if not fromData then return end

	local playerInventory = Inventory(source)

	local toData = table.clone(fromData)
	toData.slot = data.toSlot
	toData.count = data.count
	toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

	if toData.weight > shared.playerweight then return end

	local dropId = generateInvId('drop')

	local hooks <close> = TriggerEventHooks('swapItems', {
		source = source,
		fromInventory = fromInventory.id,
		fromSlot = fromData,
		fromType = fromInventory.type,
		toInventory = 'newdrop',
		toSlot = data.toSlot,
		toType = 'drop',
		count = data.count,
		action = 'move',
		dropId = dropId,
	})

	if not hooks.success then return end
	if Inventories[playerInventory.id] ~= playerInventory then hooks.success = false return end

	fromData.count -= data.count
	fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

	if fromData.count < 1 then
		fromData = nil
	else
		toData.metadata = table.clone(toData.metadata)
	end

	local slot = data.fromSlot
	fromInventory.weight -= toData.weight
	fromInventory.items[slot] = fromData

	if fromInventory.player and slot == fromInventory.weapon then
		fromInventory.weapon = nil
	end

	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', shared.dropslots, toData.weight, shared.dropweight, false, {[data.toSlot] = toData})

	if not inventory then return end

	inventory.coords = data.coords
	Inventory.Drops[dropId] = {coords = inventory.coords, instance = data.instance}
	local dropData = setupDropEntry(dropId)

	fromInventory.changed = true

	if dropPropConfig.enabled and dropData then
		AddDropProps(dropId, {
			{
				name = toData.name,
				count = data.count,
				slot = data.toSlot
			}
		}, inventory.coords)

		dropData.hasPropObjects = dropData.itemProps and #dropData.itemProps > 0 or false
	end

	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId], playerInventory and playerInventory.open and source, slot)

	if server.loglevel > 0 then
		lib.logger(playerInventory and playerInventory.owner or fromInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, toData.name, fromInventory.label, dropId))
	end

	if server.syncInventory then
		server.syncInventory(fromInventory)
	end

	return true, {
		weight = fromInventory.weight,
		items = {
			{
				item = fromData or { slot = data.fromSlot },
				inventory = fromInventory.id
			}
		}
	}
end

local GetLocks = require 'modules.locks'

canStoreItemInBackpack = function(backpackInventory, itemName)
	local Utility = require 'modules.utility.server'

	if not Utility or not Utility.canStoreItemInBackpack then
		return true
	end

	return Utility.canStoreItemInBackpack(backpackInventory, itemName)
end

lib.callback.register('ox_inventory:pickupDropProp', function(source, data)
	if type(data) ~= 'table' then return false end

	local uniqueId = data.uniqueId
	local dropId = data.dropId

	if not uniqueId or not dropId then return false end

	local playerInventory = Inventory(source)
	local drop = Inventory.Drops[dropId]

	if not playerInventory or not drop or not drop.propLookup then
		return false
	end

	local dropInventory = Inventory(dropId)
	local propEntry = drop.propLookup[uniqueId]
	local playerPed = GetPlayerPed(source)

	if not dropInventory or not propEntry or playerPed == 0 then
		return false
	end

	local playerState = Player(source).state

	if drop.instance and playerState and playerState.instance ~= drop.instance then
		return false
	end

	local slot = propEntry.slot
	local slotData = slot and dropInventory.items[slot]

	if not slotData or slotData.name ~= propEntry.itemName then
		return false
	end

	local propCoords = propEntry.coords or drop.coords or dropInventory.coords

	if not propCoords or #(GetEntityCoords(playerPed) - propCoords) > 2.5 then
		return false
	end

	local pickupCount = drop.oneItemOneProp and slotData.count or 1
	local item = Items(slotData.name)

	if not item or pickupCount < 1 then
		return false
	end

	if pickupCount > slotData.count then
		pickupCount = slotData.count
	end

	if not Inventory.CanCarryItem(playerInventory, item, pickupCount, slotData.metadata) then
		return false, 'cannot_carry'
	end

	local toSlot = Inventory.GetSlotForItem(playerInventory, slotData.name, slotData.metadata) or Inventory.GetEmptySlot(playerInventory)

	if not toSlot then
		return false, 'cannot_carry'
	end

	local activeSlots <close> = GetLocks({
		('inventory-%s:slot-%s'):format(dropInventory.id, slot),
		('inventory-%s:slot-%s'):format(playerInventory.id, toSlot)
	})

	if not activeSlots then return false end

	local hooks <close> = TriggerEventHooks('swapItems', {
		source = source,
		fromInventory = dropInventory.id,
		fromSlot = slotData,
		fromType = dropInventory.type,
		toInventory = playerInventory.id,
		toSlot = playerInventory.items[toSlot] or toSlot,
		toType = playerInventory.type,
		count = pickupCount,
		action = 'pickup',
	})

	if not hooks.success then
		return false
	end

	local added, addResponse = Inventory.AddItem(playerInventory, item, pickupCount, slotData.metadata, toSlot)

	if not added then
		if addResponse == 'inventory_full' then
			addResponse = 'cannot_carry'
		end

		return false, addResponse
	end

	local removed, removeResponse = Inventory.RemoveItem(dropInventory, item, pickupCount, slotData.metadata, slot, true)

	if not removed then
		Inventory.RemoveItem(playerInventory, item, pickupCount, slotData.metadata, toSlot, true)
		return false, removeResponse
	end

	if not next(dropInventory.items) and not next(dropInventory.openedBy) then
		Inventory.Remove(dropInventory)
	end

	if server.loglevel > 0 then
		lib.logger(playerInventory.owner, 'pickupDropProp', ('%sx %s transferred from "%s" to "%s"'):format(pickupCount, slotData.name, dropInventory.label, playerInventory.label))
	end

	return true
end)

---@param source number
---@param data SwapSlotData
lib.callback.register('ox_inventory:swapItems', function(source, data)
	if type(data) ~= 'table'
		or type(data.count) ~= 'number'
		or type(data.fromSlot) ~= 'number'
		or type(data.toSlot) ~= 'number'
		or type(data.fromType) ~= 'string'
		or type(data.toType) ~= 'string'
	then
		Utils.LogExploit(source, 'swapItems', 'Triggered event with malformed data', true)
		return
	end

	local function isBackpackType(invType)
		return invType == 'backpack' or invType == 'otherBackpack'
	end

	local involvesBackpack = isBackpackType(data.fromType) or isBackpackType(data.toType)
	local createsDrop = data.toType == 'newdrop'

	if data.fromType ~= data.toType and data.toType ~= 'player' and data.fromType ~= 'player' and not involvesBackpack and not createsDrop then
		Utils.LogExploit(source, 'swapItems', 'Triggered event with invalid data', true)
		return
	end

	data.count = math.max(1, math.floor(data.count or 1))

	local playerInventory = Inventory(source)

	if not playerInventory or not playerInventory.open then return end

	local function inventoryLinksBackpack(inventory, backpackId)
		if not inventory or type(inventory.items) ~= 'table' then return false end

		for _, slotData in pairs(inventory.items) do
			local metadata = slotData and slotData.metadata

			if metadata and (metadata.container == backpackId or metadata.backpackId == backpackId) then
				return true
			end
		end

		return false
	end

	local function hasLinkedBackpack(backpackId)
		if inventoryLinksBackpack(playerInventory, backpackId) then return true end

		local openInventory = playerInventory.open and Inventories[playerInventory.open]

		return inventoryLinksBackpack(openInventory, backpackId)
	end

	local function resolveInventory(invType, invId)
		if invType == 'player' then
			return playerInventory
		end

		if invId then
			local resolved = Inventory(invId)

			if resolved then
				return resolved
			end
		end

		return Inventory(playerInventory.open)
	end

	local toInventory = resolveInventory(data.toType, data.toInventory)
	local fromInventory = resolveInventory(data.fromType, data.fromInventory)

	if not fromInventory or not toInventory then
		playerInventory:closeInventory()
		return
	end

	local function canAccessBackpack(inventory)
		if not inventory then return false end

		local openedForPlayer = inventory.openedBy and inventory.openedBy[source]

		if inventory.type == 'backpack' then
			return openedForPlayer or hasLinkedBackpack(inventory.id)
		end

		return openedForPlayer
	end

	local function canAccessDrop(inventory)
		return inventory
			and inventory.type == 'drop'
			and (playerInventory.open == inventory.id or (inventory.openedBy and inventory.openedBy[source]))
	end

	local function canAccessInventory(inventory, requestedType)
		if requestedType == 'player' then
			return inventory == playerInventory
		end

		if requestedType == 'newdrop' then
			return true
		end

		if requestedType == 'inspect' or not inventory then
			return false
		end

		if isBackpackType(requestedType) then
			return canAccessBackpack(inventory)
		end

		if inventory.type == 'drop' then
			return canAccessDrop(inventory)
		end

		return playerInventory.open == inventory.id or (inventory.openedBy and inventory.openedBy[source])
	end

	if not canAccessInventory(fromInventory, data.fromType) then
		Utils.LogExploit(source, 'swapItems', 'Triggered inventory source without access', true)
		return
	end

	if not canAccessInventory(toInventory, data.toType) then
		Utils.LogExploit(source, 'swapItems', 'Triggered inventory target without access', true)
		return
	end

	if createsDrop and data.fromType ~= 'player' and fromInventory.type ~= 'backpack' then
		return false
	end

    if data.toType == 'inspect' or data.fromType == 'inspect' then return end

	local activeSlots <close> = GetLocks({
		('inventory-%s:slot-%s'):format(fromInventory.id, data.fromSlot),
		('inventory-%s:slot-%s'):format(toInventory.id, data.toSlot)
	})

	if not activeSlots then
		return false, {
			{
				item = toInventory.items[data.toSlot] or { slot = data.toSlot },
				inventory = toInventory.id
			},
			{
				item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
				inventory = fromInventory.id
			}
		}
	end

	local sameInventory = fromInventory.id == toInventory.id
	local fromOtherPlayer = fromInventory.player and fromInventory ~= playerInventory
	local toOtherPlayer = toInventory.player and toInventory ~= playerInventory

	local function notifyTarget(inventory)
		if inventory == playerInventory then return end

		if inventory.player then return inventory.id end

		if inventory.type ~= 'backpack' then return end

		local ownerId = inventory.backpackOwner

		if not ownerId or ownerId == playerInventory.id then return end

		local owner = Inventories[ownerId]

		if owner and owner.player and inventoryLinksBackpack(owner, inventory.id) then
			return ownerId
		end
	end

	local fromNotifyTarget = notifyTarget(fromInventory)
	local toNotifyTarget = not sameInventory and notifyTarget(toInventory) or nil
	local toData = toInventory.items[data.toSlot]
	local function getCapacityWeight(inv)
		return inv.player and Inventory.CalculateWeightInSlotRange(inv) or inv.weight
	end

	---@return boolean
	local function partiesPresent()
		return Inventories[playerInventory.id] == playerInventory
			and Inventories[fromInventory.id] == fromInventory
			and Inventories[toInventory.id] == toInventory
	end

	if not sameInventory and (fromInventory.type == 'policeevidence' or (toInventory.type == 'policeevidence' and toData)) then
		local group, rank = server.hasGroup(playerInventory, shared.police)

		if not group or server.evidencegrade > rank then
			return false, 'evidence_cannot_take'
		end
	end

	if toInventory and (data.toType == 'newdrop' or fromInventory ~= toInventory or data.fromSlot ~= data.toSlot) then
		local fromData = fromInventory.items[data.fromSlot]

		if not fromData then
		return false, {
			{
				item = { slot = data.fromSlot },
				inventory = fromInventory.id
			},
			{
				item = toData or { slot = data.toSlot },
				inventory = toInventory.id
			}
		}
	end

    if data.count > fromData.count then
        data.count = fromData.count
    end

	local fromInitialCount = fromData and fromData.count or 0
	local fromInitialName = fromData and fromData.name or nil
	local toInitialCount = toData and toData.count or 0
	local toInitialName = toData and toData.name or nil

	if data.toType == 'newdrop' then
		return dropItem(source, fromInventory, fromData, data)
	end

		if fromData then
            if fromData.metadata.container and toInventory.type == 'container' then return false end
            if toData and toData.metadata.container and fromInventory.type == 'container' then return false end

			local container, containerItem = (not sameInventory and playerInventory.containerSlot) and (fromInventory.type == 'container' and fromInventory or toInventory)

			if container then
				containerItem = playerInventory.items[playerInventory.containerSlot]
			end

			local hookPayload = {
				source = source,
				fromInventory = fromInventory.id,
				fromSlot = fromData,
				fromType = fromInventory.type,
				toInventory = toInventory.id,
				toSlot = toData or data.toSlot,
				toType = toInventory.type,
				count = data.count,
			}

			if toData and ((toData.name ~= fromData.name) or not toData.stack or (not table.matches(toData.metadata, fromData.metadata))) then

				local toWeight = not sameInventory and (toInventory.weight - toData.weight + fromData.weight) or 0
				local fromWeight = not sameInventory and (fromInventory.weight + toData.weight - fromData.weight) or 0
				local toCapacityWeight = not sameInventory and (getCapacityWeight(toInventory) - toData.weight + fromData.weight) or 0
				local fromCapacityWeight = not sameInventory and (getCapacityWeight(fromInventory) + toData.weight - fromData.weight) or 0
				hookPayload.action = 'swap'

				if not sameInventory then
					if toInventory.type == 'backpack' and not canStoreItemInBackpack(toInventory, fromData.name) then
						return false, 'backpack_blacklisted_item'
					end

					if fromInventory.type == 'backpack' and not canStoreItemInBackpack(fromInventory, toData.name) then
						return false, 'backpack_blacklisted_item'
					end

					if (toCapacityWeight <= toInventory.maxWeight and fromCapacityWeight <= fromInventory.maxWeight) then
						local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

						if not hooks.success then return end
						if not partiesPresent() then hooks.success = false return end

						if containerItem then
							local toContainer = toInventory.type == 'container'
							local whitelist = Items.containers[containerItem.name]?.whitelist
							local blacklist = Items.containers[containerItem.name]?.blacklist
							local checkItem = toContainer and fromData.name or toData.name

							if (whitelist and not whitelist[checkItem]) or (blacklist and blacklist[checkItem]) then
								hooks.success = false
								return
							end

							Inventory.ContainerWeight(containerItem, toContainer and toWeight or fromWeight, playerInventory)
						end

						if fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', fromNotifyTarget, { fromData, 'ui_removed', fromData.count })
							TriggerClientEvent('ox_inventory:itemNotify', fromNotifyTarget, { toData, 'ui_added', toData.count })
						end

						if toNotifyTarget and toNotifyTarget ~= fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', toNotifyTarget, { fromData, 'ui_added', fromData.count })
							TriggerClientEvent('ox_inventory:itemNotify', toNotifyTarget, { toData, 'ui_removed', toData.count })
						end

						fromInventory.weight = fromWeight
						toInventory.weight = toWeight
						toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot) --[[@as table]]

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s" for %sx %s'):format(fromData.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id, toData.count, toData.name))
						end
					else return false, 'cannot_carry' end
				else
					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot)
				end

			elseif toData and toData.name == fromData.name and table.matches(toData.metadata, fromData.metadata) then
				local originalFromCount, originalToCount = fromData.count, toData.count
				local fromCount, toCount = originalFromCount - data.count, originalToCount + data.count
				local originalFromWeight = fromData.weight

				fromData.count, toData.count = fromCount, toCount
				local fromSlotWeight = Inventory.SlotWeight(Items(fromData.name), fromData)
				local toSlotWeight = Inventory.SlotWeight(Items(toData.name), toData)
				fromData.count, toData.count = originalFromCount, originalToCount

				local totalWeight = toInventory.weight - toData.weight + toSlotWeight
				local totalCapacityWeight = getCapacityWeight(toInventory) - toData.weight + toSlotWeight

				if fromInventory.type == 'container' or sameInventory or totalCapacityWeight <= toInventory.maxWeight then
					hookPayload.action = 'stack'

					if not sameInventory and toInventory.type == 'backpack' and not canStoreItemInBackpack(toInventory, fromData.name) then
						return false, 'backpack_blacklisted_item'
					end

					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					fromData.count, toData.count = fromCount, toCount
					toData.weight = toSlotWeight

					if not sameInventory then
						fromInventory.weight = fromInventory.weight - originalFromWeight + fromSlotWeight
						toInventory.weight = totalWeight

						if container then
							Inventory.ContainerWeight(containerItem, toInventory.type == 'container' and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', fromNotifyTarget, { fromData, 'ui_removed', data.count })
						end

						if toNotifyTarget and toNotifyTarget ~= fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', toNotifyTarget, { toData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id))
						end
					end

					fromData.weight = fromSlotWeight
				else
					return false, 'cannot_carry'
				end
			elseif data.count <= fromData.count then
				toData = table.clone(fromData)
				toData.count = data.count
				toData.slot = data.toSlot
				toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

				if fromInventory.type == 'container' or sameInventory or (getCapacityWeight(toInventory) + toData.weight <= toInventory.maxWeight) then
					hookPayload.action = 'move'

					if not sameInventory and toInventory.type == 'backpack' and not canStoreItemInBackpack(toInventory, fromData.name) then
						return false, 'backpack_blacklisted_item'
					end

					local hooks <close> = TriggerEventHooks('swapItems', hookPayload)

					if not hooks.success then return end
					if not partiesPresent() then hooks.success = false return end

					if not sameInventory then
						local toContainer = toInventory.type == 'container'

						if container then
							if toContainer and containerItem then
								local whitelist = Items.containers[containerItem.name]?.whitelist
								local blacklist = Items.containers[containerItem.name]?.blacklist

								if (whitelist and not whitelist[fromData.name]) or (blacklist and blacklist[fromData.name]) then
									hooks.success = false
									return
								end
							end
						end

						fromInventory.weight -= toData.weight
						toInventory.weight += toData.weight

						if container then
							Inventory.ContainerWeight(containerItem, toContainer and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', fromNotifyTarget, { fromData, 'ui_removed', data.count })
						end

						if toNotifyTarget and toNotifyTarget ~= fromNotifyTarget then
							TriggerClientEvent('ox_inventory:itemNotify', toNotifyTarget, { fromData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s transferred from "%s" to "%s"'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id))
						end
					end

					fromData.count -= data.count
					fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

					if fromData.count > 0 then
						toData.metadata = table.clone(toData.metadata)
					end
				else return false, 'cannot_carry_other' end
			end

			if fromData and fromData.count < 1 then fromData = nil end

			---@type updateSlot[]
			local items = {}

			if fromInventory.player and not fromOtherPlayer then
				if toInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			if toInventory.player and not toOtherPlayer then
				if fromInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			fromInventory.items[data.fromSlot] = fromData
			toInventory.items[data.toSlot] = toData

			items[#items + 1] = {
				item = toInventory.items[data.toSlot] or { slot = data.toSlot },
				inventory = toInventory.id
			}

			items[#items + 1] = {
				item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
				inventory = fromInventory.id
			}

			if fromInventory.type == 'drop' then
				local finalFromItem = fromInventory.items[data.fromSlot]
				local finalFromCount = finalFromItem and finalFromItem.count or 0
				local fromDiff = finalFromCount - fromInitialCount

				if fromDiff > 0 and finalFromItem then
					AddDropProps(fromInventory.id, {
						{
							name = finalFromItem.name,
							count = fromDiff,
							slot = data.fromSlot
						}
					}, fromInventory.coords)
				elseif fromDiff < 0 and fromInitialName then
					RemoveDropProps(fromInventory.id, fromInitialName, data.fromSlot, -fromDiff)
				end
			end

			if toInventory.type == 'drop' then
				local finalToItem = toInventory.items[data.toSlot]
				local finalToCount = finalToItem and finalToItem.count or 0
				local toDiff = finalToCount - toInitialCount

				if toDiff > 0 and finalToItem then
					AddDropProps(toInventory.id, {
						{
							name = finalToItem.name,
							count = toDiff,
							slot = data.toSlot
						}
					}, toInventory.coords)
				elseif toDiff < 0 and toInitialName then
					RemoveDropProps(toInventory.id, toInitialName, data.toSlot, -toDiff)
				end
			end

			if fromInventory.changed ~= nil then fromInventory.changed = true end
			if toInventory.changed ~= nil then toInventory.changed = true end

            CreateThread(function()
                if sameInventory then
                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = fromInventory.id
                        },
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true, source)
                else
                    toInventory:syncSlotsWithClients({
                        {
                            item = toInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = toInventory.id
                        }
                    }, true, source)

                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true, source)
                end
            end)

			if server.syncInventory then
				if fromInventory.player then
					server.syncInventory(fromInventory)
				end

				if toInventory.player and not sameInventory then
					server.syncInventory(toInventory)
				end
			end

			local weaponSlot

			if toInventory.weapon == data.toSlot then
				if not sameInventory then
					toInventory.weapon = nil
					TriggerClientEvent('ox_inventory:disarm', toInventory.id)
				else
					weaponSlot = data.fromSlot
					toInventory.weapon = weaponSlot
				end
			end

			if fromInventory.weapon == data.fromSlot then
				if not sameInventory then
					fromInventory.weapon = nil
					TriggerClientEvent('ox_inventory:disarm', fromInventory.id)
				elseif not weaponSlot then
					weaponSlot = data.toSlot
					fromInventory.weapon = weaponSlot
				end
			end

			return containerItem and containerItem.weight or true, { weight = playerInventory.weight, items = items }, weaponSlot
		end
	end
end)

function Inventory.Confiscate(source)
	local inv = Inventory(source)

	if inv?.player then
		db.saveStash(inv.owner, inv.owner, json.encode(minimal(inv)))
		table.wipe(inv.items)
		inv.weight = 0
		inv.changed = true

		TriggerClientEvent('ox_inventory:inventoryConfiscated', inv.id)

		if server.syncInventory then server.syncInventory(inv) end
	end
end
exports('ConfiscateInventory', Inventory.Confiscate)

function Inventory.Return(source)
	local inv = Inventory(source)

	if not inv?.player then return end

	local items = MySQL.scalar.await('SELECT data FROM ox_inventory WHERE name = ?', { inv.owner })

    if not items then return end

	MySQL.update.await('DELETE FROM ox_inventory WHERE name = ?', { inv.owner })

    items = json.decode(items)
    local inventory, totalWeight = {}, 0

    if table.type(items) == 'array' then
        for i = 1, #items do
            local data = items[i]
            if type(data) == 'number' then break end

            local item = Items(data.name)

            if item then
                local weight = Inventory.SlotWeight(item, data)
                totalWeight = totalWeight + weight
                inventory[data.slot] = {name = data.name, label = item.label, weight = weight, slot = data.slot, count = data.count, description = item.description, metadata = data.metadata, stack = item.stack, close = item.close}
            end
        end
    end

    inv.changed = true
    inv.weight = totalWeight
    inv.items = inventory

    TriggerClientEvent('ox_inventory:inventoryReturned', source, { inventory, totalWeight })

    if server.syncInventory then server.syncInventory(inv) end
end

exports('ReturnInventory', Inventory.Return)

---@param inv inventory
---@param keep? string | string[] an item or list of items to ignore while clearing items
function Inventory.Clear(inv, keep)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv or not next(inv.items) then return end

	local updateSlots = {}
	local newWeight = 0
	local inc = 0
	local isPlayer = inv.player ~= nil

	if keep or isPlayer then
		local keptItems = {}
		local keepType = keep and type(keep) or nil

		for slot, v in pairs(inv.items) do
			local shouldKeep = false

			if isPlayer and v.metadata and v.metadata.clothingSlot ~= nil then
				shouldKeep = true
			end

			if not shouldKeep and keep then
				if keepType == 'string' then
					shouldKeep = v.name == keep
				elseif keepType == 'table' and table.type(keep) == 'array' then
					for i = 1, #keep do
						if v.name == keep[i] then
							shouldKeep = true
							break
						end
					end
				end
			end

			if shouldKeep then
				keptItems[v.slot] = v
				newWeight += v.weight
			else
				inc += 1
				updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
			end
		end

		table.wipe(inv.items)
		inv.items = keptItems
	else
		for slot in pairs(inv.items) do
			inc += 1
			updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
		end

		table.wipe(inv.items)
	end

	inv.weight = newWeight
	inv.changed = true

	inv:syncSlotsWithClients(updateSlots, true)

	if not inv.player then
		if inv.open then
			local playerInv = Inventory(inv.open)

			if not playerInv then return end

			playerInv:closeInventory()
		end

		inv:openInventory(inv)

		return
	end

	if server.syncInventory then server.syncInventory(inv) end

	inv.weapon = nil
end

exports('ClearInventory', Inventory.Clear)

---@param inv inventory
---@return integer?
function Inventory.GetEmptySlot(inv)
	local inventory = Inventory(inv)

	if not inventory then return end

	local items = inventory.items

	for i = 1, inventory.slots do
		if not items[i] then
			return i
		end
	end
end

exports('GetEmptySlot', Inventory.GetEmptySlot)

---@param inv inventory
---@param itemName string
---@param metadata any
function Inventory.GetSlotForItem(inv, itemName, metadata)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local items = inventory.items
	local emptySlot

	for i = 1, inventory.slots do
		local slotData = items[i]

		if not slotData and not emptySlot then
			emptySlot = i
		end

		if item.stack and slotData and slotData.name == item.name and table.matches(slotData.metadata, metadata) then
			return i
		end
	end

	return emptySlot
end

exports('GetSlotForItem', Inventory.GetSlotForItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return SlotWithItem?
function Inventory.GetSlotWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                return slotData
            end
		end
	end
end

exports('GetSlotWithItem', Inventory.GetSlotWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number?
function Inventory.GetSlotIdWithItem(inv, itemName, metadata, strict)
	return Inventory.GetSlotWithItem(inv, itemName, metadata, strict)?.slot
end

exports('GetSlotIdWithItem', Inventory.GetSlotIdWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return SlotWithItem[]?
function Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local response = {}
	local n = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                n += 1
                response[n] = slotData
            end
		end
	end

	return response
end

exports('GetSlotsWithItem', Inventory.GetSlotsWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number[]?
function Inventory.GetSlotIdsWithItem(inv, itemName, metadata, strict)
	local items = Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)

	if items then
		---@cast items +number[]
		for i = 1, #items do
			items[i] = items[i].slot
		end

		return items
	end
end

exports('GetSlotIdsWithItem', Inventory.GetSlotIdsWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number
function Inventory.GetItemCount(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return 0 end

	metadata = assertMetadata(metadata)
	local count = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
			count += slotData.count
		end
	end

	return count
end

exports('GetItemCount', Inventory.GetItemCount)

---@alias InventorySaveData { [1]: MinimalInventorySlot, [2]: string | number, [3]: string | number | nil }

---@param inv OxInventory
---@param buffer table
---@param time integer
---@return integer?
---@return InventorySaveData?
local function prepareInventorySave(inv, buffer, time)
    local shouldSave = not inv.datastore and inv.changed
    local n = 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, time) and shouldSave then
            n += 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
	end

    if not shouldSave then return end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false
    table.wipe(buffer)

    if inv.player then
        if shared.framework == 'esx' then return end

        return 1, { data, inv.owner }
    end

    if inv.type == 'trunk' then
        return 2, { data, inv.dbId }
    end

    if inv.type == 'glovebox' then
        return 3, { data, inv.dbId }
    end

    return 4, { data, inv.owner and tostring(inv.owner) or '', inv.dbId }
end

local isSaving = false
local inventoryClearTime = GetConvarInt('inventory:cleartime', 5) * 60

local function saveInventories(clearInventories)
	if isSaving then return end

	local time = os.time()
	local parameters = { {}, {}, {}, {} }
	local total = { 0, 0, 0, 0, 0 }
    local buffer = {}

	for _, inv in pairs(Inventories) do
        local index, data = prepareInventorySave(inv, buffer, time)

        if index and data then
            total[5] += 1

            if index == 4 and server.bulkstashsave then
                for i = 1, 3 do
					total[index] += 1
                    parameters[index][total[index]] = data[i]
                end
            else
				total[index] += 1
                parameters[index][total[index]] = data
            end
        end
	end

    if total[5] > 0 then
        isSaving = true
        local ok, err = pcall(db.saveInventories, parameters[1], parameters[2], parameters[3], parameters[4], total)
        isSaving = false

        if not ok and err then return lib.print.error(err) end
    end

    if not clearInventories then return end

    for _, inv in pairs(Inventories) do
        if not inv.open and not inv.player and inv.type ~= 'backpack' then
            if inv.type == 'glovebox' or inv.type == 'trunk' then
                if NetworkGetEntityFromNetworkId(inv.netid) ~= inv.entityId then
                    Inventory.Remove(inv)
                end
            elseif time - inv.time >= inventoryClearTime then
                Inventory.Remove(inv)
            end
        end
    end
end

lib.cron.new('*/5 * * * *', function()
    saveInventories(true)
end)

function Inventory.SaveInventories(lock, clearInventories)
	Inventory.Lock = lock or nil

	Inventory.CloseAll()
    saveInventories(clearInventories)
end

AddEventHandler('playerDropped', function()
	server.playerDropped(source)

	if GetNumPlayerIndices() == 0 then
		Inventory.SaveInventories(false, true)
	end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
	Inventory.SaveInventories(true, false)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining ~= 60 then return end

	Inventory.SaveInventories(true, true)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == shared.resource then
		Inventory.SaveInventories(true, false)
	end
end)

RegisterServerEvent('ox_inventory:closeInventory', function()
	local inventory = Inventories[source]

	if inventory?.open then
		local secondary = Inventories[inventory.open]

		if secondary then
			secondary:closeInventory()
		end

		inventory:closeInventory(true)
	end
end)

local function giveItem(playerId, slot, target, count, fromInv)
	slot = tonumber(slot)
	target = tonumber(target)
	count = tonumber(count) or 0

	if not slot or not target then return end

	local playerInventory = Inventory(playerId)
	if not playerInventory then return end

	local fromInventory
	if fromInv and type(fromInv) == 'string' then
		fromInventory = Inventory(fromInv)
	end

	if not fromInventory then
		fromInventory = playerInventory
	end

	if fromInventory ~= playerInventory then
		local canAccessSource = playerInventory.open == fromInventory.id or (fromInventory.openedBy and fromInventory.openedBy[playerId])

		if not canAccessSource and fromInventory.type == 'backpack' then
			for _, itemData in pairs(playerInventory.items) do
				local itemMetadata = itemData.metadata

				if itemMetadata and (itemMetadata.container == fromInventory.id or itemMetadata.backpackId == fromInventory.id) then
					canAccessSource = true
					break
				end
			end
		end

		if not canAccessSource then
			return { 'cannot_give', count or 1, 'item' }
		end
	end
	local toInventory = Inventory(target)

	if count <= 0 then
		local slotData = fromInventory.items[slot]
		count = slotData and slotData.count or 1
	end

	if toInventory?.player then
		local data = fromInventory.items[slot]

		if not data then return { 'cannot_give', count, 'item' } end

        local targetState = Player(target).state

        if targetState.invBusy then
            return { 'cannot_give', count, data.label }
        end

		local item = Items(data.name)

		local canCarry = Inventory.CanCarryItem(toInventory, item, count, data.metadata)
		local distanceOk = true

		if playerInventory.player and toInventory.player then
			if #(GetEntityCoords(playerInventory.player.ped) - GetEntityCoords(toInventory.player.ped)) > 15 then
				distanceOk = false
			end
		end

		if not item or data.count < count or not canCarry or not distanceOk then
			return { 'cannot_give', count, data.label }
		end

		local toSlot = Inventory.GetSlotForItem(toInventory, data.name, data.metadata)

		if not toSlot then return { 'cannot_give', count, data.label } end

        local activeSlots <close> = GetLocks({
            ('inventory-%s:slot-%s'):format(fromInventory.id, slot),
            ('inventory-%s:slot-%s'):format(toInventory.id, toSlot)
        })

		if not activeSlots then
			return { 'cannot_give', count, data.label }
		end

		local hooks <close> = TriggerEventHooks('swapItems', {
			source = fromInventory.id,
			fromInventory = fromInventory.id,
			fromType = fromInventory.type,
			toInventory = toInventory.id,
			toType = toInventory.type,
			count = count,
			action = 'give',
			fromSlot = data,
		})

		if hooks.success then
			local sourceMetadata = data.metadata
			if Inventory.RemoveItem(fromInventory, item, count, sourceMetadata, slot) then
				if Inventory.AddItem(toInventory, item, count, sourceMetadata, toSlot) then
					if server.loglevel > 0 then
						lib.logger(fromInventory.owner, 'giveItem', ('"%s" gave %sx %s to "%s"'):format(fromInventory.label, count, data.name, toInventory.label))
					end

					local Utility = require('modules.utility.server')
					local UtilityConfig = Utility.config or {}
					local isBackpack = UtilityConfig and UtilityConfig.backpackItems and UtilityConfig.backpackItems[data.name]
					if isBackpack and data.metadata and data.metadata.backpackId then
					    local existingBackpack = Utility.ensureBackpackInventory(fromInventory, data)

					    if existingBackpack then
					        Inventory.CloseAll(existingBackpack)
					        existingBackpack.changed = true

					        Inventory.Save(existingBackpack)
					    end
					end

                    TriggerClientEvent('ox_inventory:playGiveAnim', toInventory.id)

					return
				end

				hooks.success = false
				Inventory.AddItem(fromInventory, item, count, sourceMetadata, slot)
			end
		end

		return { 'cannot_give', count, data.label }
	end
end

lib.callback.register('ox_inventory:giveItem', giveItem)
RegisterServerEvent('ox_inventory:giveItem', function(...) giveItem(source, ...) end)

local function updateWeapon(source, action, value, slot, specialAmmo)
	local inventory = Inventory(source)

	if not inventory then return end

	if not action then
		inventory.weapon = nil
		return
	end

	local vtype = type(value)

	if vtype == 'table' and action == 'component' then
		local item = inventory.items[value.slot]

		if item then
			if item.metadata.components then
				for k, v in pairs(item.metadata.components) do
					if v == value.component then
						if not Inventory.AddItem(inventory, value.component, 1, nil, value.targetSlot) then return end

						table.remove(item.metadata.components, k)
						inventory:syncSlotsWithPlayer({
							{ item = item }
						}, inventory.weight)

			            if server.syncInventory then server.syncInventory(inventory) end

						return true
					end
				end
			end
		end
	else
		if not slot then slot = inventory.weapon end

		local weapon = inventory.items[slot]

		if weapon and weapon.metadata then
			local item = Items(weapon.name)

			if not item.weapon then
				inventory.weapon = nil
				return
			end

			if vtype == 'number' and value < 0 then
				value = 0
			end

			if action == 'load' and weapon.metadata.durability > 0 then
				local ammo = Items(weapon.name).ammoname
				local diff = value - (weapon.metadata.ammo or 0)

				if not Inventory.RemoveItem(inventory, ammo, diff, specialAmmo) then return end

				weapon.metadata.ammo = value
				weapon.metadata.specialAmmo = specialAmmo
				weapon.weight = Inventory.SlotWeight(item, weapon)
			elseif action == 'throw' then
				if not Inventory.RemoveItem(inventory, weapon.name, 1, weapon.metadata, weapon.slot) then return end
			elseif action == 'component' then
				if vtype == 'number' then
					if not Inventory.AddItem(inventory, weapon.metadata.components[value], 1) then return false end

					table.remove(weapon.metadata.components, value)
					weapon.weight = Inventory.SlotWeight(item, weapon)
				elseif vtype == 'string' then
					local component = inventory.items[tonumber(value)]

					if not Inventory.RemoveItem(inventory, component.name, 1) then return false end

					table.insert(weapon.metadata.components, component.name)
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'ammo' then
				if item.hash == `WEAPON_FIREEXTINGUISHER` or item.hash == `WEAPON_PETROLCAN` or item.hash == `WEAPON_HAZARDCAN` or item.hash == `WEAPON_FERTILIZERCAN` then
					local safeValue = math.max(0, math.min(100, math.floor(value)))
					weapon.metadata.durability = safeValue
					weapon.metadata.ammo = safeValue
				elseif value < weapon.metadata.ammo then
					local durability = Items(weapon.name).durability * math.abs((weapon.metadata.ammo or 0.1) - value)
					weapon.metadata.ammo = value
					weapon.metadata.durability = weapon.metadata.durability - durability
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'melee' then
				weapon.metadata.durability = weapon.metadata.durability - ((Items(weapon.name).durability or 1) * value)
			end

            if (weapon.metadata.durability or 0) < 0 then
                weapon.metadata.durability = 0
            end

            if item.hash == `WEAPON_PETROLCAN` then
                weapon.weight = Inventory.SlotWeight(item, weapon)
            end

			if action ~= 'throw' then
				inventory:syncSlotsWithPlayer({
					{ item = weapon }
				}, inventory.weight)
			end

			if server.syncInventory then server.syncInventory(inventory) end

			return true
		end
	end
end

lib.callback.register('ox_inventory:updateWeapon', updateWeapon)

RegisterNetEvent('ox_inventory:updateWeapon', function(action, value, slot, specialAmmo)
	updateWeapon(source, action, value, slot, specialAmmo)
end)

lib.callback.register('ox_inventory:removeAmmoFromWeapon', function(source, slot)
	local inventory = Inventory(source)

	if not inventory then return end

	local slotData = inventory.items[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo < 1 then return end

	local item = Items(slotData.name)

	if not item or not item.ammoname then return end

	local specialAmmo = slotData.metadata.specialAmmo and { type = slotData.metadata.specialAmmo } or nil

	if Inventory.AddItem(inventory, item.ammoname, slotData.metadata.ammo, specialAmmo) then
		slotData.metadata.ammo = 0
		slotData.weight = Inventory.SlotWeight(item, slotData)

		inventory:syncSlotsWithPlayer({
			{ item = slotData }
		}, inventory.weight)

		if server.syncInventory then server.syncInventory(inventory) end

		return true
	end
end)

local function checkStashProperties(properties)
	local name = properties.name
	local slots = properties.slots
	local maxWeight = properties.maxWeight
	local coords = properties.coords

	if type(name) ~= 'string' then
		error(('received %s for stash name (expected string)'):format(type(name)))
	end

	if type(slots) ~= 'number' then
		error(('received %s for stash slots (expected number)'):format(type(slots)))
	end

	if type(maxWeight) ~= 'number' then
		error(('received %s for stash maxWeight (expected number)'):format(type(maxWeight)))
	end

	if coords then
		local typeof = type(coords)

		if typeof ~= 'vector3' then
			if typeof == 'table' and table.type(coords) ~= 'array' then
				coords = vec3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
			else
				if table.type(coords) == 'array' then
					for i = 1, #coords do
						coords[i] = vec3(coords[i].x, coords[i].y, coords[i].z)
					end
				else
					error(('received %s for stash coords (expected vector3 or array of vector3)'):format(typeof))
				end
			end
		end
	end

	return name, slots, maxWeight, coords
end

---@param name string stash identifier when loading from the database
---@param label string display name when inventory is open
---@param slots number
---@param maxWeight number
---@param owner? string|number|boolean
---@param groups? table<string, number>
---@param coords? vector3|table<vector3>
local function registerStash(name, label, slots, maxWeight, owner, groups, coords, instance)
	name, slots, maxWeight, coords = checkStashProperties({
		name = name,
		slots = slots,
		maxWeight = maxWeight,
		coords = coords,
	})

	local curStash = RegisteredStashes[name]

	if curStash then
		for _, stash in pairs(Inventories) do
			if stash.type == 'stash' and stash.dbId == name then
				stash.label = label or stash.label
				stash.owner = (owner and owner ~= true) and stash.owner or owner
				stash.slots = slots or stash.slots
				stash.maxWeight = maxWeight or stash.maxWeight
				stash.groups = groups or stash.groups
				stash.coords = coords or stash.coords
				stash.instance = instance or stash.instance
			end
		end
	end

	RegisteredStashes[name] = {
		name = name,
		label = label,
		owner = owner,
		slots = slots,
		maxWeight = maxWeight,
		groups = groups,
		coords = coords,
		instance = instance
	}
end

exports('RegisterStash', registerStash)

---@param properties TemporaryStashProperties
function Inventory.CreateTemporaryStash(properties)
	properties.name = generateInvId('temp')

	local name, slots, maxWeight, coords = checkStashProperties(properties)
	local inventory = Inventory.Create(name, properties.label, 'temp', slots, 0, maxWeight, properties.owner, {}, properties.groups)

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', properties.items)
	inventory.coords = coords
	inventory.instance = properties.instance

	return inventory.id
end

exports('CreateTemporaryStash', Inventory.CreateTemporaryStash)

function Inventory.InspectInventory(playerId, invId)
	local inventory = invId ~= playerId and Inventory(invId)
	local playerInventory = Inventory(playerId)

	if playerInventory and inventory then
		playerInventory:openInventory(inventory)
		TriggerClientEvent('ox_inventory:viewInventory', playerId, playerInventory, inventory)
	end
end

exports('InspectInventory', Inventory.InspectInventory)

return Inventory
