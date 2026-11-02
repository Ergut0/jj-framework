if not lib then return end
lib.locale()

local Items = require 'modules.items.client'
local Utils = require 'modules.utils.client'
local createBlip = Utils.CreateBlip

local Config = lib.load('data.storage') or {}
local StorageTypes = Config.types or {}
local StaticUnits = Config.units or {}
local PackingConfig = Config.packing or {}

local StorageUnits = {}
local UnitProps = {}
local UnitPoints = {}
local UnitZones = {}
local UnitTargetEntities = {}
local UnitMoving = {}
local UnitPermissions = {}
local markerColour = { 30, 120, 200 }
local currentResource = cache and cache.resource or GetCurrentResourceName()

local function getUnitPermissions(id)
	return UnitPermissions[id]
end

local function setUnitPermissionsCache(id, data)
	if not id or type(data) ~= 'table' then return end

	UnitPermissions[id] = {
		canUse = data.canUse ~= false,
		canMove = data.canMove == true,
		canPack = data.canPack == true,
		canManage = data.canManage == true,
		isOwner = data.isOwner == true,
		roleId = data.roleId,
		roleName = data.roleName,
	}
end

local function unitHasPermission(id, flag)
	local perms = UnitPermissions[id]
	if not perms then
		return flag == 'use'
	end

	if perms.isOwner then
		return true
	end

	if flag == 'use' then
		return perms.canUse or false
	elseif flag == 'move' then
		return perms.canMove or false
	elseif flag == 'pack' then
		return perms.canPack or false
	elseif flag == 'manage' then
		return perms.canManage or false
	end

	return false
end

local function attemptOpenUnit(id)
	if not unitHasPermission(id, 'use') then
		lib.notify({ type = 'error', description = 'You do not have permission to access this storage.' })
		return
	end

	client.openInventory('storage', { id = id })
end

local function openUnitPermissionsUI(id)
	if not unitHasPermission(id, 'manage') then
		lib.notify({ type = 'error', description = 'You do not have permission to manage this storage.' })
		return
	end

	local payload, err = lib.callback.await('ox_inventory:storage:getBenchPermissions', false, id)
	if not payload then
		if err then
			lib.notify({ type = 'error', description = locale(err) or tostring(err) })
		end
		return
	end

	SendNUIMessage({
		action = 'openBenchPermissions',
		data = payload,
	})
	SetNuiFocus(true, true)

	if payload.playerPermissions then
		setUnitPermissionsCache(id, payload.playerPermissions)
	end
end

local function requestPackUnit(id)
	local response, err = lib.callback.await('ox_inventory:storage:preparePackUnit', false, id)

	if not response then
		lib.notify({ type = 'error', description = err and locale(err) or tostring(err or 'Unable to pack this storage.') })
		return
	end

	if response.confirm then
		local result = lib.alertDialog({
			header = locale('storage_pack_confirm_title') or 'Pack storage?',
			content = locale('storage_pack_confirm_items') or 'This storage contains items. Packing it will drop the contents nearby. Continue?',
			centered = true,
			cancel = true,
			labels = {
				confirm = locale('ui_confirm') or 'Confirm',
				cancel = locale('ui_cancel') or 'Cancel',
			},
		})

		if result ~= 'confirm' then return end
	end

	TriggerServerEvent('ox_inventory:storage:packUnit', id, response.confirm == true)
end

local function buildUnitTargetOptions(id, unit, baseLabel, baseIcon, distance, includeOpen, includeExtras)
	local options = {}
	local optionDistance = distance or unit.targetDistance or 2.0

	if includeOpen ~= false then
		options[#options + 1] = {
			label = baseLabel or unit.label or locale('open_storage_unit') or 'Open Storage',
			icon = baseIcon or 'fas fa-box-open',
			distance = optionDistance,
			canInteract = function()
				if unit.groups and not client.hasGroup(unit.groups) then
					return false
				end
				return unitHasPermission(id, 'use')
			end,
			onSelect = function()
				attemptOpenUnit(id)
			end,
		}
	end

	if unit.dynamic and includeExtras ~= false then
		options[#options + 1] = {
			icon = 'fas fa-users-cog',
			label = 'Manage Storage',
			distance = optionDistance,
			canInteract = function()
				return unitHasPermission(id, 'manage')
			end,
			onSelect = function()
				openUnitPermissionsUI(id)
			end,
		}

		options[#options + 1] = {
			icon = 'fas fa-arrows-alt',
			label = 'Move Storage',
			distance = optionDistance,
			canInteract = function()
				return unitHasPermission(id, 'move')
			end,
			onSelect = function()
				TriggerServerEvent('ox_inventory:storage:requestMoveUnit', id)
			end,
		}

		if PackingConfig.enabled ~= false then
			options[#options + 1] = {
				icon = 'fas fa-box',
				label = 'Pack Storage',
				distance = optionDistance,
				canInteract = function()
					return unitHasPermission(id, 'pack')
				end,
				onSelect = function()
					requestPackUnit(id)
				end,
			}
		end
	end

	return options
end

local function buildUnitContextOptions(id, unit)
	local options = {}
	local label = unit.label or locale('open_storage_unit') or 'Open Storage'

	if unitHasPermission(id, 'use') then
		options[#options + 1] = {
			title = label,
			icon = 'fas fa-box-open',
			description = 'Open and access the storage inventory.',
			onSelect = function()
				attemptOpenUnit(id)
			end,
		}
	end

	if unit.dynamic then
		if unitHasPermission(id, 'manage') then
			options[#options + 1] = {
				title = 'Manage Storage',
				icon = 'fas fa-users-cog',
				description = 'Edit roles, permissions, and members.',
				onSelect = function()
					openUnitPermissionsUI(id)
				end,
			}
		end

		if unitHasPermission(id, 'move') then
			options[#options + 1] = {
				title = 'Move Storage',
				icon = 'fas fa-arrows-alt',
				description = 'Reposition this storage unit.',
				onSelect = function()
					TriggerServerEvent('ox_inventory:storage:requestMoveUnit', id)
				end,
			}
		end

		if PackingConfig.enabled ~= false and unitHasPermission(id, 'pack') then
			options[#options + 1] = {
				title = 'Pack Storage',
				icon = 'fas fa-box',
				description = 'Pack this storage unit back into an item.',
				onSelect = function()
					requestPackUnit(id)
				end,
			}
		end
	end

	return options
end

local function handleUnitInteraction(id)
	local unit = StorageUnits[id]
	if not unit then
		lib.notify({ type = 'error', description = locale('storage_not_found') or 'Storage not found.' })
		return
	end

	local options = buildUnitContextOptions(id, unit)

	if #options == 0 then
		lib.notify({ type = 'error', description = 'You do not have permission to access this storage.' })
		return
	end

	if #options == 1 then
		local entry = options[1]
		if entry and entry.onSelect then
			entry.onSelect()
		end
		return
	end

	local contextId = ('ox_inventory:storage:%s'):format(id)
	lib.registerContext({
		id = contextId,
		title = unit.label or locale('open_storage_unit') or 'Storage',
		options = options,
	})
	lib.showContext(contextId)
end

local function shallowCopy(tbl)
	if not tbl then return {} end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function removeUnitTarget(id)
	local entity = UnitTargetEntities[id]
	if entity and DoesEntityExist(entity) then
		pcall(function()
			exports.ox_target:removeLocalEntity(entity)
		end)
	end
	UnitTargetEntities[id] = nil
end

local function attachTargetToUnit(id, unit, entity)
	if not shared.target or entity == 0 then return end

	if UnitZones[id] then return end

	removeUnitTarget(id)

	local options = buildUnitTargetOptions(
		id,
		unit,
		unit.label or locale('open_storage_unit') or 'Open Storage',
		unit.targetIcon or 'fas fa-box-open',
		unit.targetDistance,
		true
	)

	if next(options) then
		exports.ox_target:addLocalEntity(entity, options)
		UnitTargetEntities[id] = entity
	end
end

local prompt = {
	options = { icon = 'fa-box-open' },
	message = ('**%s**  \n%s'):format(
		locale('open_storage_unit') or 'Open Storage',
		locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3))
	)
}

local function removeTargetZone(id)
	local zoneHandles = UnitZones[id]
	if not zoneHandles then return end

	if shared.target and type(zoneHandles) == 'table' then
		for _, zoneName in ipairs(zoneHandles) do
			if zoneName then
				pcall(function()
					exports.ox_target:removeZone(zoneName)
				end)
			end
		end
	end

	UnitZones[id] = nil
end

local function removeUnitPoint(id)
	local points = UnitPoints[id]
	if not points then return end

	for _, point in ipairs(points) do
		if point and point.remove then
			point:remove()
		end
	end

	UnitPoints[id] = nil
end

local function deleteUnitProp(id)
	removeUnitTarget(id)

	local entity = UnitProps[id]
	if not entity or not DoesEntityExist(entity) then
		UnitProps[id] = nil
		return
	end

	DeleteEntity(entity)
	UnitProps[id] = nil
end

local function ensureUnitProp(id, unit)
	if UnitMoving[id] then return end

	if not unit.model or not unit.spawnRange then return end

	local playerCoords = GetEntityCoords(cache.ped)
	local coords = unit.coords

	if not coords then
		if unit.points and unit.points[1] then
			local c = unit.points[1]
			coords = vec3(c.x, c.y, c.z)
		end
	end

	if not coords then return end

	local distance = #(playerCoords - coords)
	local existing = UnitProps[id]

	if distance <= unit.spawnRange then
		if existing and DoesEntityExist(existing) then
			if not UnitTargetEntities[id] then
				attachTargetToUnit(id, unit, existing)
			end
			return
		end

		local model = lib.requestModel(unit.model)
		if not model then return end

		local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)

		if object == 0 then return end

		local heading = unit.heading or unit.rotation or 0.0
		SetEntityHeading(object, heading)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityInvincible(object, true)
		SetModelAsNoLongerNeeded(model)

		UnitProps[id] = object
		attachTargetToUnit(id, unit, object)
		UnitMoving[id] = nil
	elseif existing then
		deleteUnitProp(id)
	end
end

CreateThread(function()
	while true do
		local ped = cache.ped

		if ped and ped ~= 0 then
			for id, unit in pairs(StorageUnits) do
				if unit.spawnRange and unit.model then
					ensureUnitProp(id, unit)
				end
			end
		end

		Wait(1000)
	end
end)

local function setupTargetInteractions(id, data)
	if UnitZones[id] then
		removeTargetZone(id)
	end

	if UnitTargetEntities[id] then
		removeUnitTarget(id)
	end

	removeUnitPoint(id)

	local handles = {}

	if shared.target then
		data.points = nil

		if data.zones then
			for i = 1, #data.zones do
				local zone = shallowCopy(data.zones[i])
				zone.name = ('storageunit_%s:%s'):format(id, i)
				zone.id = id
				zone.options = buildUnitTargetOptions(
					id,
					data,
					zone.label or locale('open_storage_unit') or 'Open Storage',
					zone.icon or 'fas fa-box-open',
					zone.distance,
					true
				)

				exports.ox_target:addBoxZone(zone)
				handles[#handles + 1] = zone.name

				if data.blip then
					createBlip(data.blip, zone.coords)
				end
			end
		elseif data.coords then
			local coords = data.coords
			if type(coords) == 'table' then
				coords = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
			end

			if coords then
				local zoneName = ('storageunit_%s:dynamic'):format(id)
				local radius = data.targetRadius or 1.5

				exports.ox_target:addSphereZone({
					name = zoneName,
					coords = coords,
					radius = radius,
					debug = data.debugTarget,
					options = buildUnitTargetOptions(
						id,
						data,
						data.label or locale('open_storage_unit') or 'Open Storage',
						'fas fa-box-open',
						radius,
						true
					)
				})

				handles[#handles + 1] = zoneName

				if data.blip then
					createBlip(data.blip, coords)
				end
			end
		end
	else
		if data.points then
			local points = {}

			for i = 1, #data.points do
				local coords = data.points[i]

				points[#points + 1] = lib.points.new({
					coords = coords,
					distance = 16,
					unitid = id,
					prompt = prompt,
					marker = markerColour,
					nearby = Utils.nearbyMarker,
					onInteract = function()
						handleUnitInteraction(id)
					end
				})

				if data.blip then
					createBlip(data.blip, coords)
				end
			end

			UnitPoints[id] = points
		elseif data.coords then
			local coords = data.coords
			local point = lib.points.new({
				coords = coords,
				distance = 16,
				unitid = id,
				prompt = prompt,
				marker = markerColour,
				nearby = Utils.nearbyMarker,
				onInteract = function()
					handleUnitInteraction(id)
				end
			})

			UnitPoints[id] = { point }

			if data.blip then
				createBlip(data.blip, coords)
			end
		end
	end

	if next(handles) then
		UnitZones[id] = handles
	else
		UnitZones[id] = nil
	end
end

local function registerUnit(id, unitData)
	if StorageUnits[id] then
		removeTargetZone(id)
		removeUnitTarget(id)
		removeUnitPoint(id)
		deleteUnitProp(id)
	end

	unitData.groups = unitData.groups or unitData.jobs or unitData.job or unitData.gangs or unitData.gang

	local typeId = unitData.type or unitData.typeId
	local typeConfig = typeId and StorageTypes[typeId]
	if typeConfig then
		unitData.label = unitData.label or typeConfig.label
		unitData.model = unitData.model or typeConfig.model
		unitData.spawnRange = unitData.spawnRange or typeConfig.spawnRange
	end

	if unitData.coords then
		if type(unitData.coords) == 'table' then
			unitData.coords = vec3(unitData.coords.x or 0.0, unitData.coords.y or 0.0, unitData.coords.z or 0.0)
		end
	end

	StorageUnits[id] = unitData

	if unitData.permissions then
		setUnitPermissionsCache(id, unitData.permissions)
		unitData.permissions = nil
	end

	setupTargetInteractions(id, unitData)
	UnitMoving[id] = nil
end

local function removeUnit(id)
	removeTargetZone(id)
	removeUnitPoint(id)
	removeUnitTarget(id)
	deleteUnitProp(id)
	UnitPermissions[id] = nil
	StorageUnits[id] = nil
end

local function startPlacement(data)
	if type(data) ~= 'table' then return end

	local typeName = data.type
	local typeConfig = typeName and StorageTypes[typeName]
	if not typeConfig then return end

	local model = data.model or typeConfig.model
	if not model then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:storage:placementCancelled')
		return
	end

	local hash = lib.requestModel(model)

	if not hash then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:storage:placementCancelled')
		return
	end

	local ped = cache.ped
	local offset = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
	local ghost = CreateObject(hash, offset.x, offset.y, offset.z, false, false, false)

	if ghost == 0 then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:storage:placementCancelled')
		return
	end

	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetEntityHeading(ghost, GetEntityHeading(ped))
	SetModelAsNoLongerNeeded(hash)

	local confirmed = exports.ox_inventory:useGizmo(ghost, (typeConfig and typeConfig.label) or (unit and unit.label)) == true

	if not DoesEntityExist(ghost) then
		if not confirmed then
			TriggerServerEvent('ox_inventory:storage:placementCancelled')
		end
		return
	end

	local coords = GetEntityCoords(ghost)
	local heading = GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:storage:placeUnit', {
			type = typeName,
			coords = { x = coords.x, y = coords.y, z = coords.z },
			heading = heading,
			label = typeConfig.label,
			inventory = data.inventory,
		})
	else
		TriggerServerEvent('ox_inventory:storage:placementCancelled')
	end
end

local function startMoveUnit(data)
	if type(data) ~= 'table' then return end

	local unitId = data.id
	if not unitId then return end

	local unit = StorageUnits[unitId]
	if not unit then return end

	UnitMoving[unitId] = true

	local model = data.model or unit.model
	if not model then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		ensureUnitProp(unitId, unit)
		UnitMoving[unitId] = nil
		return
	end

	deleteUnitProp(unitId)

	local coordsData = data.coords or {}
	local coords = vec3(coordsData.x or 0.0, coordsData.y or 0.0, coordsData.z or 0.0)
	local heading = data.heading or 0.0

	local hash = lib.requestModel(model)
	if not hash then
		ensureUnitProp(unitId, unit)
		UnitMoving[unitId] = nil
		return
	end

	local ghost = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
	if ghost == 0 then
		ensureUnitProp(unitId, unit)
		UnitMoving[unitId] = nil
		return
	end

	local confirmed = false

	SetEntityHeading(ghost, heading)
	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetModelAsNoLongerNeeded(hash)

	confirmed = exports.ox_inventory:useGizmo(ghost, (typeConfig and typeConfig.label) or (unit and unit.label)) == true

	if not DoesEntityExist(ghost) then
		if not confirmed then
			ensureUnitProp(unitId, unit)
		end
		UnitMoving[unitId] = nil
		return
	end

	local newCoords = GetEntityCoords(ghost)
	local newHeading = GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:storage:moveUnit', unitId, {
			coords = { x = newCoords.x, y = newCoords.y, z = newCoords.z },
			heading = newHeading,
		})
	else
		ensureUnitProp(unitId, unit)
	end

	UnitMoving[unitId] = nil
end

RegisterNetEvent('ox_inventory:storage:startPlacement', startPlacement)
RegisterNetEvent('ox_inventory:storage:startMove', startMoveUnit)

RegisterNetEvent('ox_inventory:storage:updatePermissions', function(payload)
	if type(payload) ~= 'table' or not payload.id then return end

	if payload.removed then
		UnitPermissions[payload.id] = nil
		return
	end

	setUnitPermissionsCache(payload.id, payload)
end)

RegisterNetEvent('ox_inventory:storage:addUnit', function(unit)
	if not unit or type(unit) ~= 'table' then return end

	local id = unit.id or unit.name
	if not id then return end

	if unit.removed then
		removeUnit(id)
		return
	end

	if unit.coords then
		unit.coords = vec3(unit.coords.x, unit.coords.y, unit.coords.z)
	end

	registerUnit(id, unit)
end)

RegisterNetEvent('ox_inventory:storage:removeUnit', function(unitId)
	if not unitId then return end
	removeUnit(unitId)
end)

local function registerStaticUnits()
	if type(StaticUnits) ~= 'table' then return end

	for index, unit in ipairs(StaticUnits) do
		local id = unit.name or ('storage_static_%s'):format(index)
		registerUnit(id, unit)
	end
end

CreateThread(function()
	registerStaticUnits()
	TriggerServerEvent('ox_inventory:storage:requestUnits')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= currentResource then return end

	local ids = {}
	for id in pairs(StorageUnits) do
		ids[#ids + 1] = id
	end

	for i = 1, #ids do
		removeUnit(ids[i])
	end

	table.wipe(StorageUnits)
	table.wipe(UnitZones)
	table.wipe(UnitPoints)
	table.wipe(UnitTargetEntities)
	table.wipe(UnitProps)
end)
