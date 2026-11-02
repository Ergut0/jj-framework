if not lib then return end
lib.locale()

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local StorageConfig = lib.load('data.storage') or {}
local StorageTypes = StorageConfig.types or {}
local StaticUnits = StorageConfig.units or {}
local PackingConfig = StorageConfig.packing or {}

local StorageUnits = {}
local PlacedUnits = {}
local PlacementItems = {}
local PendingPlacement = {}
local AdminMovers = {}
local StorageInventories = {}

local getPlayerIdentifier

local function asBool(value)
	return value == true or value == 1 or value == '1'
end

local function getDefaultRoleDefinitions()
	return {
		{
			name = locale('crafting_role_member') or 'Member',
			can_use = 1,
			can_move = 0,
			can_pack = 0,
			can_manage = 0,
		},
		{
			name = locale('crafting_role_manager') or 'Manager',
			can_use = 1,
			can_move = 1,
			can_pack = 1,
			can_manage = 1,
		},
	}
end

local function getUnitRecord(unitId)
	return PlacedUnits[unitId]
end

local function ensureDefaultRoles(persistentId)
	if not persistentId then return end

	local existing = MySQL.scalar.await('SELECT COUNT(*) FROM ox_storage_roles WHERE unit_id = ?', { persistentId })

	if existing and existing > 0 then
		return
	end

	for _, roleData in ipairs(getDefaultRoleDefinitions()) do
		MySQL.insert.await(
			'INSERT INTO ox_storage_roles (unit_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)',
			{ persistentId, roleData.name, roleData.can_use, roleData.can_move, roleData.can_pack, roleData.can_manage }
		)
	end
end

local function loadUnitRoles(unitId, persistentId)
	if not persistentId then return end

	ensureDefaultRoles(persistentId)

	local roleRows = MySQL.query.await('SELECT * FROM ox_storage_roles WHERE unit_id = ? ORDER BY id ASC', { persistentId }) or {}
	local roles = {}
	local memberIndex = {}

	for _, row in ipairs(roleRows) do
		roles[row.id] = {
			id = row.id,
			unitId = row.unit_id,
			name = row.name,
			canUse = asBool(row.can_use),
			canMove = asBool(row.can_move),
			canPack = asBool(row.can_pack),
			canManage = asBool(row.can_manage),
			members = {},
		}
	end

	if next(roles) then
		local memberRows = MySQL.query.await('SELECT * FROM ox_storage_role_members WHERE unit_id = ?', { persistentId }) or {}

		for _, row in ipairs(memberRows) do
			local role = roles[row.role_id]
			if role then
				local memberEntry = {
					id = row.id,
					identifier = row.identifier,
					addedBy = row.added_by,
				}
				role.members[#role.members + 1] = memberEntry
				memberIndex[row.identifier] = row.role_id
			end
		end
	end

	local record = unitId and getUnitRecord(unitId)
	if record then
		record.roles = {
			list = roles,
			memberIndex = memberIndex,
		}
	end

	return roles, memberIndex
end

local function getUnitRolesCache(unitId)
	local record = getUnitRecord(unitId)
	if not record or not record.id then return nil end

	if not record.roles then
		loadUnitRoles(unitId, record.id)
	end

	return record.roles
end

local function getOnlineSourceByIdentifier(identifier)
	if not identifier then return nil end
	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner == identifier then
				return src
			end
		end
	end
end

local function toVector3(value)
	if not value then return nil end
	local valueType = type(value)

	if valueType == 'vector3' then
		return value
	end

	if valueType == 'table' then
		if value.coords then
			return toVector3(value.coords)
		end

		if value.x or value.y or value.z then
			return vec3(value.x or 0.0, value.y or 0.0, value.z or 0.0)
		end

		if value[1] or value[2] or value[3] then
			return vec3(value[1] or 0.0, value[2] or 0.0, value[3] or 0.0)
		end
	end

	return nil
end

local function getUnitReferenceCoords(unit)
	if not unit then return nil end

	return toVector3(unit.coords)
		or (unit.points and toVector3(unit.points[1]))
end

local function resolveIdentifier(input)
	if type(input) == 'number' then
		local inv = Inventory(input)
		return inv and inv.owner or nil, input
	end

	if type(input) == 'string' then
		local trimmed = input:gsub('^%s+', ''):gsub('%s+$', '')
		if trimmed == '' then return nil end
		if trimmed:match('^%d+$') then
			local src = tonumber(trimmed)
			if src then
				local inv = Inventory(src)
				if inv and inv.owner then
					return inv.owner, src
				end
			end
		end
		return trimmed, nil
	end

	return nil
end

local function trim(value)
	if type(value) ~= 'string' then return nil end
	local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
	return trimmed
end

local function computeUnitPermissions(unitId, identifier)
	local permissions = {
		canUse = true,
		canMove = false,
		canPack = false,
		canManage = false,
		isOwner = false,
		roleId = nil,
		roleName = nil,
	}

	if not unitId then
		return permissions
	end

	local record = getUnitRecord(unitId)

	if not record then
		return permissions
	end

	if identifier and record.owner == identifier then
		permissions.canMove = true
		permissions.canPack = true
		permissions.canManage = true
		permissions.isOwner = true
		permissions.roleId = nil
		return permissions
	end

	local rolesCache = getUnitRolesCache(unitId)

	if not rolesCache then
		permissions.canUse = false
		return permissions
	end

	local roleId = identifier and rolesCache.memberIndex and rolesCache.memberIndex[identifier] or nil
	local role = roleId and rolesCache.list and rolesCache.list[roleId]

	if not role then
		permissions.canUse = false
		return permissions
	end

	permissions.canUse = role.canUse
	permissions.canMove = role.canMove
	permissions.canPack = role.canPack
	permissions.canManage = role.canManage
	permissions.roleId = role.id
	permissions.roleName = role.name

	return permissions
end

function hasUnitPermission(subject, unitId, permission)
	if permission == 'use' and not unitId then
		return true
	end

	local identifier = subject
	if type(subject) ~= 'string' then
		identifier = getPlayerIdentifier(subject)
	end

	local record = getUnitRecord(unitId)

	if not record then
		return permission == 'use'
	end

	if identifier and record.owner == identifier then
		return true
	end

	local perms = computeUnitPermissions(unitId, identifier)

	if permission == 'use' then
		return perms.canUse
	elseif permission == 'move' then
		return perms.canMove
	elseif permission == 'pack' then
		return perms.canPack
	elseif permission == 'manage' then
		return perms.canManage
	elseif permission == 'owner' then
		return perms.isOwner
	end

	return false
end

local function canManageUnit(source, unitId)
	local record = getUnitRecord(unitId)
	if not record then return false, nil end

	local identifier = getPlayerIdentifier(source)
	if not identifier then return false, record end

	if record.owner == identifier then
		return true, record
	end

	if hasUnitPermission(identifier, unitId, 'manage') then
		return true, record
	end

	return false, record
end

local function collectOnlinePlayers(originCoords, radius)
	local players = {}
	local useRadius = originCoords and radius and radius > 0

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner then
				local include = true

				if useRadius then
					local ped = GetPlayerPed(src)
					if ped and ped ~= 0 then
						local pedCoords = GetEntityCoords(ped)
						if #(pedCoords - originCoords) > radius then
							include = false
						end
					else
						include = false
					end
				end

				if include then
					players[#players + 1] = {
						source = src,
						identifier = inv.owner,
						name = inv.player and inv.player.name or GetPlayerName(src),
					}
				end
			end
		end
	end

	return players
end

local function buildUnitPermissionsPayload(source, unitId)
	local unit = StorageUnits[unitId]
	local record = getUnitRecord(unitId)
	if not unit or not record then
		return nil, 'crafting_not_found'
	end

	local identifier = getPlayerIdentifier(source)
	if not identifier then
		return nil, 'crafting_no_permission'
	end

	local isOwner = record.owner == identifier
	if not isOwner and not hasUnitPermission(identifier, unitId, 'manage') then
		return nil, 'crafting_no_permission'
	end

	local rolesCache = getUnitRolesCache(unitId)
	if not rolesCache then
		rolesCache = { list = {}, memberIndex = {} }
	end

	local onlinePlayers = collectOnlinePlayers()
	local onlineIndex = {}
	for i = 1, #onlinePlayers do
		local player = onlinePlayers[i]
		local roleId = rolesCache.memberIndex and rolesCache.memberIndex[player.identifier]
		player.roleId = roleId
		onlineIndex[player.identifier] = player
	end

	local roles = {}
	for _, role in pairs(rolesCache.list or {}) do
		local members = {}
		for _, member in ipairs(role.members or {}) do
			local online = onlineIndex[member.identifier]
			members[#members + 1] = {
				id = member.id,
				identifier = member.identifier,
				name = online and online.name or member.identifier,
				online = online and true or false,
				serverId = online and online.source or nil,
				addedBy = member.addedBy,
			}
		end

		table.sort(members, function(a, b)
			return a.identifier < b.identifier
		end)

		roles[#roles + 1] = {
			id = role.id,
			name = role.name,
			canUse = role.canUse,
			canMove = role.canMove,
			canPack = role.canPack,
			canManage = role.canManage,
			memberCount = #members,
			members = members,
		}
	end

	table.sort(roles, function(a, b)
		return a.id < b.id
	end)

	local ownerInfo = record.owner and onlineIndex[record.owner] or nil
	local ownerName = ownerInfo and ownerInfo.name or record.owner
	local unitCoords = getUnitReferenceCoords(unit)
	local nearbyRadius = unitCoords and (unit.nearbyRadius or 10.0) or nil
	local nearbyPlayers = collectOnlinePlayers(unitCoords, nearbyRadius)

	return {
		benchId = unitId,
		benchLabel = unit.label or unitId,
		owner = {
			identifier = record.owner,
			name = ownerName,
			online = ownerInfo and true or false,
			serverId = ownerInfo and ownerInfo.source or nil,
		},
		roles = roles,
		onlinePlayers = nearbyPlayers,
		canTransfer = isOwner,
		isOwner = isOwner,
		playerPermissions = computeUnitPermissions(unitId, identifier),
	}, nil
end

local function sendUnitPermissions(playerId, unitId)
	local unit = StorageUnits[unitId]
	if not unit then return end

	local identifier = getPlayerIdentifier(playerId)
	local perms = computeUnitPermissions(unitId, identifier)

	TriggerClientEvent('ox_inventory:storage:updatePermissions', playerId, {
		id = unitId,
		canUse = perms.canUse,
		canMove = perms.canMove,
		canPack = perms.canPack,
		canManage = perms.canManage,
		isOwner = perms.isOwner,
		roleId = perms.roleId,
		roleName = perms.roleName,
	})
end

local function notifyUnitMembers(unitId, includeOwner)
	local record = getUnitRecord(unitId)
	if not record then return end

	local identifiers = {}

	if includeOwner and record.owner then
		identifiers[record.owner] = true
	end

	local cache = getUnitRolesCache(unitId)
	if cache and cache.memberIndex then
		for identifier in pairs(cache.memberIndex) do
			identifiers[identifier] = true
		end
	end

	for identifier in pairs(identifiers) do
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendUnitPermissions(targetSrc, unitId)
		end
	end
end

local function clearUnitRoles(unitId)
	local record = getUnitRecord(unitId)
	if record then
		record.roles = nil
	end
end

local function storageInventoryKey(unitId)
	return ('ox_storage:%s'):format(unitId)
end

local function deepCopy(value)
	if type(value) ~= 'table' then return value end
	if table.deepclone then
		return table.deepclone(value)
	end

	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function getOrCreateStorageInventory(unitId, unit)
	local typeConfig = unit.typeId and StorageTypes[unit.typeId]
	local storageCfg = typeConfig and typeConfig.storage or {}

	local slots = storageCfg.slots or 20
	local maxWeight = storageCfg.maxWeight or 50000
	local label = unit.label or (typeConfig and typeConfig.label) or 'Storage'

	local key = storageInventoryKey(unitId)
	local existing = StorageInventories[key]
	local inv = existing and Inventory(existing)

	if not inv then
		inv = Inventory.Create(
			key,
			label,
			'stash',
			slots,
			0,
			maxWeight,
			false,
			nil,
			nil
		)

		if inv then
			StorageInventories[key] = inv.id

			if unit.coords then
				inv.coords = unit.coords
			end
		end
	end

	return inv
end

local function storageHasItems(storage)
	return storage and storage.items and next(storage.items) ~= nil
end

local function storageIsInUse(storage)
	return storage and storage.openedBy and next(storage.openedBy) ~= nil
end

local function dropStorageContents(storage, coords, label)
	if not storageHasItems(storage) then return end

	local items = {}

	for _, item in pairs(storage.items) do
		items[#items + 1] = { item.name, item.count, item.metadata }
	end

	TriggerEvent('ox_inventory:customDrop', label or 'Storage', items, coords, storage.slots, storage.maxWeight)
	table.wipe(storage.items)
	storage.weight = 0
	storage.changed = true
	Inventory.Remove(storage)
end

local function registerUnit(unitId, unitData)
	local typeId = unitData.type or unitData.typeId
	local typeConfig = typeId and StorageTypes[typeId]

	if typeConfig then
		unitData.label = unitData.label or typeConfig.label
		unitData.model = unitData.model or typeConfig.model
		unitData.spawnRange = unitData.spawnRange or typeConfig.spawnRange
	end

	unitData.id = unitId
	unitData.typeId = typeId
	unitData.typeConfig = typeConfig

	unitData.groups = unitData.groups or unitData.jobs or unitData.job or unitData.gangs or unitData.gang

	if unitData.groups and type(unitData.groups) == 'table' and #unitData.groups > 0 then
		local groupsTable = {}
		for i = 1, #unitData.groups do
			groupsTable[unitData.groups[i]] = 0
		end
		unitData.groups = groupsTable
	end

	if unitData.coords and not unitData.points then
		local vec = unitData.coords
		if type(vec) == 'vector3' then
			unitData.points = { vec3(vec.x, vec.y, vec.z) }
		elseif type(vec) == 'table' then
			unitData.points = { vec3(vec.x or 0.0, vec.y or 0.0, vec.z or 0.0) }
		end
	end

	StorageUnits[unitId] = unitData
	return unitData
end

local function sanitiseUnitForClient(unit)
	local payload = deepCopy(unit)
	payload.typeConfig = nil
	if payload.coords and type(payload.coords) == 'vector3' then
		payload.coords = { x = payload.coords.x, y = payload.coords.y, z = payload.coords.z }
	end
	return payload
end

local function broadcastDynamicUnit(unit)
	local payload = sanitiseUnitForClient(unit)
	TriggerClientEvent('ox_inventory:storage:addUnit', -1, payload)

	local unitId = unit.id or payload.id
	if unitId then
		for _, playerId in ipairs(GetPlayers()) do
			local src = tonumber(playerId)
			if src then
				sendUnitPermissions(src, unitId)
			end
		end
	end
end

local function ensureDatabase()
	MySQL.query.await('CREATE TABLE IF NOT EXISTS `ox_storage_units` (`id` INT NOT NULL AUTO_INCREMENT, `type` VARCHAR(64) NOT NULL, `owner` VARCHAR(64) NULL, `label` VARCHAR(64) NULL, `coords` JSON NOT NULL, `metadata` JSON NULL, `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')

	MySQL.query.await('CREATE TABLE IF NOT EXISTS `ox_storage_roles` (`id` INT NOT NULL AUTO_INCREMENT, `unit_id` INT NOT NULL DEFAULT 0, `name` VARCHAR(64) NOT NULL, `can_use` TINYINT(1) NOT NULL DEFAULT 1, `can_move` TINYINT(1) NOT NULL DEFAULT 0, `can_pack` TINYINT(1) NOT NULL DEFAULT 0, `can_manage` TINYINT(1) NOT NULL DEFAULT 0, `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (`id`), KEY `idx_storage_roles_unit` (`unit_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')

	MySQL.query.await('CREATE TABLE IF NOT EXISTS `ox_storage_role_members` (`id` INT NOT NULL AUTO_INCREMENT, `unit_id` INT NOT NULL DEFAULT 0, `role_id` INT NOT NULL DEFAULT 0, `identifier` VARCHAR(64) NOT NULL, `added_by` VARCHAR(64) NULL, `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`), KEY `idx_storage_role_members_unit` (`unit_id`), KEY `idx_storage_role_members_role` (`role_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4')

	local hasUnitIdInRoles = MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ox_storage_roles' AND COLUMN_NAME = 'unit_id'")
	if not hasUnitIdInRoles or hasUnitIdInRoles == 0 then
		MySQL.query.await('ALTER TABLE `ox_storage_roles` ADD COLUMN `unit_id` INT NOT NULL DEFAULT 0 AFTER `id`')
		MySQL.query.await('ALTER TABLE `ox_storage_roles` ADD INDEX `idx_storage_roles_unit` (`unit_id`)')
	end

	local hasUnitIdInMembers = MySQL.scalar.await("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ox_storage_role_members' AND COLUMN_NAME = 'unit_id'")
	if not hasUnitIdInMembers or hasUnitIdInMembers == 0 then
		MySQL.query.await('ALTER TABLE `ox_storage_role_members` ADD COLUMN `unit_id` INT NOT NULL DEFAULT 0 AFTER `id`')
		MySQL.query.await('ALTER TABLE `ox_storage_role_members` ADD INDEX `idx_storage_role_members_unit` (`unit_id`)')
	end
end

local function registerPlacementItems()
	for typeName, typeConfig in pairs(StorageTypes) do
		local placement = typeConfig.placement

		if placement and placement.item and not PlacementItems[placement.item] then
			PlacementItems[placement.item] = typeName
		end
	end
end

local function registerStaticUnits()
	if type(StaticUnits) ~= 'table' then return end

	for index, unit in ipairs(StaticUnits) do
		local unitId = unit.name or ('storage_static_%s'):format(index)
		registerUnit(unitId, deepCopy(unit))
	end
end

local function loadPersistentUnits()
	local rows = MySQL.query.await('SELECT * FROM ox_storage_units') or {}

	for _, row in ipairs(rows) do
		local coords = type(row.coords) == 'string' and json.decode(row.coords) or row.coords or {}
		local metadata = type(row.metadata) == 'string' and json.decode(row.metadata) or row.metadata or {}

		local vec = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
		local heading = coords.w or metadata.heading or 0.0
		local unitId = ('storage:placed:%s'):format(row.id)

		local unitData = {
			name = metadata.name or unitId,
			type = row.type,
			label = row.label,
			coords = vec,
			heading = heading,
			owner = row.owner,
			dynamic = true,
			persistentId = row.id,
		}

		local unit = registerUnit(unitId, unitData)

		if unit then
			unit.dynamic = true
			unit.heading = heading
			unit.coords = vec
			unit.persistentId = row.id

			PlacedUnits[unitId] = {
				id = row.id,
				owner = row.owner,
				type = unit.typeId,
				coords = vec,
			}

			loadUnitRoles(unitId, row.id)
			broadcastDynamicUnit(unit)
		end
	end
end

function getPlayerIdentifier(source)
	local inv = Inventory(source)
	if inv and inv.owner then
		return inv.owner
	end
	return ('player:%s'):format(source)
end

CreateThread(function()
	ensureDatabase()
	registerPlacementItems()
	registerStaticUnits()
	loadPersistentUnits()
end)

AddEventHandler('ox_inventory:usedItem', function(invId, itemName, slot, metadata, source)
	local typeName = PlacementItems[itemName]
	if not typeName then return end

	local playerInventory = Inventory(invId)
	if not playerInventory then return end

	local typeConfig = StorageTypes[typeName]
	if not typeConfig then return end

	PendingPlacement[invId] = {
		type = typeName,
		item = itemName,
		slot = slot,
	}

	TriggerClientEvent('ox_inventory:storage:startPlacement', source, {
		type = typeName,
		item = itemName,
		slot = slot,
		model = typeConfig.model,
		label = typeConfig.label or typeName,
		spawnRange = typeConfig.spawnRange,
		inventory = invId,
	})
end)

RegisterNetEvent('ox_inventory:storage:requestUnits', function()
	local src = source

	for unitId, unit in pairs(StorageUnits) do
		if unit.dynamic then
			TriggerClientEvent('ox_inventory:storage:addUnit', src, sanitiseUnitForClient(unit))
			sendUnitPermissions(src, unitId)
		end
	end
end)

RegisterNetEvent('ox_inventory:storage:refreshPermissions', function()
	local src = source

	for unitId, unit in pairs(StorageUnits) do
		if unit.dynamic then
			sendUnitPermissions(src, unitId)
		end
	end
end)

RegisterNetEvent('ox_inventory:storage:placementCancelled', function()
	PendingPlacement[source] = nil
end)

RegisterNetEvent('ox_inventory:storage:placeUnit', function(data)
	local src = source

	if type(data) ~= 'table' then return end

	local pending = PendingPlacement[data.inventory]
	if not pending then return end

	local typeName = data.type
	local typeConfig = typeName and StorageTypes[typeName]

	if not typeConfig or not typeConfig.placement or typeConfig.placement.item ~= pending.item then
		PendingPlacement[data.inventory] = nil
		return
	end

	local coords = data.coords
	if type(coords) ~= 'table' then
		PendingPlacement[data.inventory] = nil
		return
	end

	local vec = vector3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
	local heading = data.heading or 0.0

	local removed = Inventory.RemoveItem(data.inventory, pending.item, 1, nil, pending.slot)
	if not removed then
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') })
		return
	end

	local identifier = getPlayerIdentifier(src)
	local label = data.label or typeConfig.label or typeName

	local dbId = MySQL.insert.await('INSERT INTO ox_storage_units (type, owner, label, coords, metadata) VALUES (?, ?, ?, ?, ?)', {
		typeName,
		identifier,
		label,
		json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
		json.encode({ name = label }),
	})

	if not dbId or dbId < 1 then
		Inventory.AddItem(src, pending.item, 1)
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') })
		return
	end

	local unitId = ('storage:placed:%s'):format(dbId)
	local unitData = {
		name = label,
		type = typeName,
		label = label,
		coords = vec,
		heading = heading,
		owner = identifier,
		dynamic = true,
		persistentId = dbId,
	}

	local unit = registerUnit(unitId, unitData)

	if unit then
		unit.dynamic = true
		unit.heading = heading
		unit.coords = vec
		unit.persistentId = dbId

		PlacedUnits[unitId] = {
			id = dbId,
			owner = identifier,
			type = unit.typeId,
			coords = vec,
		}

		loadUnitRoles(unitId, dbId)
		broadcastDynamicUnit(unit)
		lib.notify(src, { type = 'success', description = locale('storage_unit_placed') or 'Storage unit placed.' })
	else
		Inventory.AddItem(src, pending.item, 1)
	end

	PendingPlacement[data.inventory] = nil
end)

RegisterNetEvent('ox_inventory:storage:requestMoveUnit', function(unitId)
	local src = source
	local unit = unitId and StorageUnits[unitId]
	if not unit or not unit.dynamic then return end

	local record = PlacedUnits[unitId]
	if not record then return end

	if not hasUnitPermission(src, unitId, 'move') then return end

	local coords = unit.coords or vec3(0.0, 0.0, 0.0)

	TriggerClientEvent('ox_inventory:storage:startMove', src, {
		id = unitId,
		model = unit.model,
		coords = { x = coords.x, y = coords.y, z = coords.z },
		heading = unit.heading or 0.0,
		label = unit.label or unitId,
		spawnRange = unit.spawnRange,
	})
end)

RegisterNetEvent('ox_inventory:storage:moveUnit', function(unitId, payload)
	local src = source
	local unit = unitId and StorageUnits[unitId]
	if not unit or not unit.dynamic then return end

	local record = PlacedUnits[unitId]
	if not record then return end

	if not hasUnitPermission(src, unitId, 'move') and AdminMovers[unitId] ~= src then return end
	AdminMovers[unitId] = nil

	if type(payload) ~= 'table' or not payload.coords then return end

	local coords = payload.coords
	local vec = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
	local heading = payload.heading or 0.0

	unit.coords = vec
	unit.heading = heading
	record.coords = vec

	if record.id then
		MySQL.update.await('UPDATE ox_storage_units SET coords = ? WHERE id = ?', {
			json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
			record.id
		})
	end

	broadcastDynamicUnit(unit)
end)

lib.callback.register('ox_inventory:storage:preparePackUnit', function(source, unitId)
	if PackingConfig.enabled == false then return nil, 'storage_pack_disabled' end

	local unit = unitId and StorageUnits[unitId]
	if not unit or not unit.dynamic then return nil, 'storage_not_found' end
	if not PlacedUnits[unitId] then return nil, 'storage_not_found' end
	if not hasUnitPermission(source, unitId, 'pack') then return nil, 'crafting_no_permission' end

	local storage = getOrCreateStorageInventory(unitId, unit)
	if storageIsInUse(storage) then return nil, 'storage_in_use' end

	return {
		confirm = storageHasItems(storage) and PackingConfig.confirmWithItems ~= false,
	}
end)

RegisterNetEvent('ox_inventory:storage:packUnit', function(unitId, confirmed)
	local src = source
	if PackingConfig.enabled == false then return end

	local unit = unitId and StorageUnits[unitId]
	if not unit or not unit.dynamic then return end

	local record = PlacedUnits[unitId]
	if not record then return end

	if not hasUnitPermission(src, unitId, 'pack') then return end

	local typeConfig = unit.typeConfig or (unit.typeId and StorageTypes[unit.typeId])
	if not typeConfig or not typeConfig.placement or not typeConfig.placement.item then return end

	local storageKey = storageInventoryKey(unitId)
	local storage = getOrCreateStorageInventory(unitId, unit)

	if storageIsInUse(storage) then
		lib.notify(src, { type = 'error', description = locale('storage_in_use') or 'This storage is currently in use.' })
		return
	end

	local hasItems = storageHasItems(storage)
	if hasItems and PackingConfig.confirmWithItems ~= false and confirmed ~= true then return end

	local added = Inventory.AddItem(src, typeConfig.placement.item, 1)
	if not added then
		lib.notify(src, { type = 'error', description = locale('cannot_perform') })
		return
	end

	if hasItems then
		dropStorageContents(storage, unit.coords, unit.label or 'Storage')
	elseif storage then
		Inventory.Remove(storage)
	end
	StorageInventories[storageKey] = nil

	StorageUnits[unitId] = nil
	PlacedUnits[unitId] = nil
	MySQL.update.await('DELETE FROM ox_storage_units WHERE id = ?', { record.id })
	clearUnitRoles(unitId)

	TriggerClientEvent('ox_inventory:storage:removeUnit', -1, unitId)
	TriggerClientEvent('ox_inventory:storage:updatePermissions', -1, { id = unitId, removed = true })

	lib.notify(src, { type = 'success', description = locale('storage_unit_packed') or 'Storage packed up.' })

	if hasItems then
		lib.notify(src, { type = 'inform', description = locale('storage_contents_dropped') or 'Storage contents dropped nearby.' })
	end
end)

lib.callback.register('ox_inventory:storage:open', function(source, unitId)
	local unit = StorageUnits[unitId]
	if not unit then return nil, nil, 'crafting_not_found' end

	local identifier = getPlayerIdentifier(source)
	if not hasUnitPermission(identifier, unitId, 'use') then
		return nil, nil, 'crafting_no_permission'
	end

	local left = Inventory(source)
	if not left then return end

	left:closeInventory(true)

	local storageInv = getOrCreateStorageInventory(unitId, unit)
	if not storageInv then return nil, nil, 'cannot_perform' end

	if unit.groups and not server.hasGroup(left, unit.groups) then
		return nil, nil, 'inventory_right_access'
	end

	local playerPed = left.player and left.player.ped
	if playerPed and unit.coords then
		if #(GetEntityCoords(playerPed) - unit.coords) > 10 then
			return nil, nil, 'inventory_right_access'
		end
	end

	left:openInventory(storageInv)

	storageInv.openedBy = storageInv.openedBy or {}
	storageInv.openedBy[source] = true

	local leftResponse = {
		id = left.id,
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight,
	}

	local rightResponse = {
		id = storageInv.id,
		label = storageInv.label,
		type = storageInv.type,
		slots = storageInv.slots,
		weight = storageInv.weight,
		maxWeight = storageInv.maxWeight,
		items = storageInv.items,
		coords = unit.coords,
	}

	return leftResponse, rightResponse
end)

lib.callback.register('ox_inventory:storage:getBenchPermissions', function(source, unitId)
	if type(unitId) ~= 'string' then
		return false, 'crafting_not_found'
	end

	local payload, err = buildUnitPermissionsPayload(source, unitId)
	if not payload then
		return false, err or 'crafting_no_permission'
	end

	return payload
end)

lib.callback.register('ox_inventory:storage:createRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local unitId = data.benchId
	local name = trim(data.name) or ''
	local permissions = data.permissions or {}

	if type(unitId) ~= 'string' then
		return false, 'crafting_not_found'
	end

	local allowed, record = canManageUnit(source, unitId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	if name == '' then
		name = locale('crafting_role_new') or 'Role'
	end

	local canUse = permissions.use and 1 or 0
	local canMove = permissions.move and 1 or 0
	local canPack = permissions.pack and 1 or 0
	local canManage = permissions.manage and 1 or 0

	MySQL.insert.await('INSERT INTO ox_storage_roles (unit_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)', {
		record.id,
		name,
		canUse,
		canMove,
		canPack,
		canManage,
	})

	loadUnitRoles(unitId, record.id)
	notifyUnitMembers(unitId, true)

	return buildUnitPermissionsPayload(source, unitId)
end)

lib.callback.register('ox_inventory:storage:updateRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local unitId = data.benchId
	local roleId = data.roleId
	local name = trim(data.name) or ''
	local permissions = data.permissions or {}

	if type(unitId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageUnit(source, unitId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local roleRow = MySQL.single.await('SELECT unit_id FROM ox_storage_roles WHERE id = ?', { roleId })
	if not roleRow or roleRow.unit_id ~= record.id then
		return false, 'crafting_not_found'
	end

	if name == '' then
		name = locale('crafting_role_new') or 'Role'
	end

	local canUse = permissions.use and 1 or 0
	local canMove = permissions.move and 1 or 0
	local canPack = permissions.pack and 1 or 0
	local canManage = permissions.manage and 1 or 0

	MySQL.update.await('UPDATE ox_storage_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ?', {
		name,
		canUse,
		canMove,
		canPack,
		canManage,
		roleId,
	})

	loadUnitRoles(unitId, record.id)
	notifyUnitMembers(unitId, true)

	return buildUnitPermissionsPayload(source, unitId)
end)

lib.callback.register('ox_inventory:storage:deleteRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local unitId = data.benchId
	local roleId = data.roleId
	if type(unitId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageUnit(source, unitId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local rolesCache = getUnitRolesCache(unitId)
	local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
	if not role then
		return false, 'crafting_not_found'
	end

	if role.members and #role.members > 0 then
		return false, 'crafting_role_has_members'
	end

	MySQL.update.await('DELETE FROM ox_storage_roles WHERE id = ? AND unit_id = ?', { roleId, record.id })

	loadUnitRoles(unitId, record.id)
	notifyUnitMembers(unitId, true)

	return buildUnitPermissionsPayload(source, unitId)
end)

lib.callback.register('ox_inventory:storage:setMemberRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local unitId = data.benchId
	local roleId = data.roleId
	local target = data.target

	if type(unitId) ~= 'string' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageUnit(source, unitId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local identifier, resolvedSource = resolveIdentifier(target)
	if not identifier then
		return false, 'crafting_invalid_member'
	end

	local rolesCache = getUnitRolesCache(unitId)
	local previousRoleId = rolesCache and rolesCache.memberIndex and rolesCache.memberIndex[identifier]

	MySQL.update.await('DELETE FROM ox_storage_role_members WHERE unit_id = ? AND identifier = ?', { record.id, identifier })

	if roleId and type(roleId) == 'number' then
		local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
		if not role then
			return false, 'crafting_not_found'
		end

		MySQL.insert.await('INSERT INTO ox_storage_role_members (unit_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)', {
			record.id,
			roleId,
			identifier,
			getPlayerIdentifier(source),
		})
	end

	loadUnitRoles(unitId, record.id)
	notifyUnitMembers(unitId, true)

	local payload, err = buildUnitPermissionsPayload(source, unitId)
	if resolvedSource then
		sendUnitPermissions(resolvedSource, unitId)
	elseif previousRoleId then
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendUnitPermissions(targetSrc, unitId)
		end
	end

	return payload, err
end)

lib.callback.register('ox_inventory:storage:transferOwnership', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local unitId = data.benchId
	local target = data.target

	if type(unitId) ~= 'string' then
		return false, 'invalid_data'
	end

	local record = getUnitRecord(unitId)
	if not record then
		return false, 'crafting_not_found'
	end

	local identifier = getPlayerIdentifier(source)
	if record.owner ~= identifier then
		return false, 'crafting_no_permission'
	end

	local newOwner, newOwnerSrc = resolveIdentifier(target)
	if not newOwner then
		return false, 'crafting_invalid_member'
	end

	record.owner = newOwner
	local unit = StorageUnits[unitId]
	if unit then
		unit.owner = newOwner
	end

	if record.id then
		MySQL.update.await('UPDATE ox_storage_units SET owner = ? WHERE id = ?', { newOwner, record.id })
	end

	notifyUnitMembers(unitId, true)

	if newOwnerSrc then
		sendUnitPermissions(newOwnerSrc, unitId)
	end

	return buildUnitPermissionsPayload(source, unitId)
end)

local function roleName(value)
	local name = trim(value)
	return name and name ~= '' and name or 'Role'
end

local function adminUnitView(unitId)
	local unit = StorageUnits[unitId]
	local record = PlacedUnits[unitId]
	if not unit or not record then return nil end

	local cache = getUnitRolesCache(unitId) or { list = {} }
	local roles = {}

	for _, role in pairs(cache.list or {}) do
		local members = {}

		for _, member in ipairs(role.members or {}) do
			members[#members + 1] = { identifier = member.identifier, addedBy = member.addedBy }
		end

		roles[#roles + 1] = {
			id = role.id,
			name = role.name,
			canUse = role.canUse,
			canMove = role.canMove,
			canPack = role.canPack,
			canManage = role.canManage,
			members = members,
		}
	end

	table.sort(roles, function(a, b) return a.id < b.id end)

	local coords = unit.coords or record.coords

	return {
		id = unitId,
		persistentId = record.id,
		label = unit.label,
		type = unit.typeId,
		owner = record.owner,
		coords = coords and { x = coords.x, y = coords.y, z = coords.z } or nil,
		heading = unit.heading or 0.0,
		roles = roles,
	}
end

local function adminMoveUnit(unitId, coords, heading)
	local unit = StorageUnits[unitId]
	local record = PlacedUnits[unitId]
	local vec = vec3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)

	heading = (tonumber(heading) or 0.0) % 360.0
	unit.coords = vec
	unit.heading = heading
	record.coords = vec

	local storageId = StorageInventories[storageInventoryKey(unitId)]
	local storage = storageId and Inventory(storageId)

	if storage then
		storage.coords = vec
	end

	MySQL.update.await('UPDATE ox_storage_units SET coords = ? WHERE id = ?', {
		json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
		record.id
	})

	broadcastDynamicUnit(unit)
end

exports('AdminStorageUnit', function(action, unitId, data, actor)
	data = type(data) == 'table' and data or {}

	if action == 'list' then
		local list = {}

		for id in pairs(PlacedUnits) do
			local view = adminUnitView(id)
			if view then list[#list + 1] = view end
		end

		return list
	end

	local unit = unitId and StorageUnits[unitId]
	local record = unitId and PlacedUnits[unitId]

	if not unit or not record or not record.id then return false, 'not_found' end

	if action == 'get' then
		local view = adminUnitView(unitId)
		local ok, storage = pcall(getOrCreateStorageInventory, unitId, unit)
		view.storage = ok and storage and storage.id or nil
		return view
	end

	if action == 'createRole' then
		local permissions = type(data.permissions) == 'table' and data.permissions or {}

		MySQL.insert.await('INSERT INTO ox_storage_roles (unit_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)', {
			record.id, roleName(data.name),
			permissions.use and 1 or 0, permissions.move and 1 or 0, permissions.pack and 1 or 0, permissions.manage and 1 or 0,
		})
	elseif action == 'updateRole' then
		local roleRow = MySQL.single.await('SELECT unit_id FROM ox_storage_roles WHERE id = ?', { tonumber(data.roleId) })
		if not roleRow or roleRow.unit_id ~= record.id then return false, 'role_not_found' end

		local permissions = type(data.permissions) == 'table' and data.permissions or {}

		MySQL.update.await('UPDATE ox_storage_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ?', {
			roleName(data.name),
			permissions.use and 1 or 0, permissions.move and 1 or 0, permissions.pack and 1 or 0, permissions.manage and 1 or 0,
			tonumber(data.roleId),
		})
	elseif action == 'deleteRole' then
		MySQL.update.await('DELETE FROM ox_storage_role_members WHERE unit_id = ? AND role_id = ?', { record.id, tonumber(data.roleId) })
		MySQL.update.await('DELETE FROM ox_storage_roles WHERE id = ? AND unit_id = ?', { tonumber(data.roleId), record.id })
	elseif action == 'setMember' then
		local identifier = trim(data.identifier)
		if not identifier or identifier == '' then return false, 'invalid_member' end

		MySQL.update.await('DELETE FROM ox_storage_role_members WHERE unit_id = ? AND identifier = ?', { record.id, identifier })

		if tonumber(data.roleId) then
			MySQL.insert.await('INSERT INTO ox_storage_role_members (unit_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)', {
				record.id, tonumber(data.roleId), identifier, 'admin',
			})
		end

		loadUnitRoles(unitId, record.id)

		local target = getOnlineSourceByIdentifier(identifier)
		if target then sendUnitPermissions(target, unitId) end
	elseif action == 'transfer' then
		local identifier = trim(data.identifier)
		if not identifier or identifier == '' or identifier == record.owner then return false, 'invalid_member' end

		local previous = record.owner

		MySQL.update.await('UPDATE ox_storage_units SET owner = ? WHERE id = ?', { identifier, record.id })
		MySQL.update.await('DELETE FROM ox_storage_role_members WHERE unit_id = ? AND identifier = ?', { record.id, identifier })

		record.owner = identifier
		unit.owner = identifier

		loadUnitRoles(unitId, record.id)

		local previousSource = previous and getOnlineSourceByIdentifier(previous)
		if previousSource then sendUnitPermissions(previousSource, unitId) end
	elseif action == 'move' then
		if type(data.coords) ~= 'table' then return false, 'invalid_position' end
		adminMoveUnit(unitId, data.coords, data.heading)
	elseif action == 'gizmo' then
		if not actor then return false, 'no_actor' end

		local coords = unit.coords or vec3(0.0, 0.0, 0.0)
		AdminMovers[unitId] = actor

		TriggerClientEvent('ox_inventory:storage:startMove', actor, {
			id = unitId,
			model = unit.model,
			coords = { x = coords.x, y = coords.y, z = coords.z },
			heading = unit.heading or 0.0,
			label = unit.label or unitId,
			spawnRange = unit.spawnRange,
		})

		return true
	elseif action == 'remove' then
		local storageKey = storageInventoryKey(unitId)
		local ok, storage = pcall(getOrCreateStorageInventory, unitId, unit)
		storage = ok and storage or nil

		if storageIsInUse(storage) then return false, 'storage_in_use' end

		if storageHasItems(storage) then
			dropStorageContents(storage, unit.coords, unit.label or 'Storage')
		elseif storage then
			Inventory.Remove(storage)
		end

		StorageInventories[storageKey] = nil
		StorageUnits[unitId] = nil
		PlacedUnits[unitId] = nil
		MySQL.update.await('DELETE FROM ox_storage_units WHERE id = ?', { record.id })
		clearUnitRoles(unitId)

		TriggerClientEvent('ox_inventory:storage:removeUnit', -1, unitId)
		TriggerClientEvent('ox_inventory:storage:updatePermissions', -1, { id = unitId, removed = true })

		return true
	else
		return false, 'unknown_action'
	end

	loadUnitRoles(unitId, record.id)
	notifyUnitMembers(unitId, true)

	return true, adminUnitView(unitId)
end)
