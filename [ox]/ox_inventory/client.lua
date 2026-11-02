if not lib then return end

require 'modules.bridge.client'
require 'modules.interface.client'
require 'modules.injury.client'
require 'modules.playerinfo.client'
require 'modules.placement.client'

local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
local Utility = require 'modules.utility.client'
local Clothing = require 'modules.clothing.client'
local currentWeapon

exports('getCurrentWeapon', function()
	return currentWeapon
end)

RegisterNetEvent('ox_inventory:disarm', function(noAnim)
	currentWeapon = Weapon.Disarm(currentWeapon, noAnim)
end)

RegisterNetEvent('ox_inventory:clearWeapons', function()
	Weapon.ClearAll(currentWeapon)
end)

RegisterNetEvent('ox_inventory:utility:setBackpack', function(backpack)
	SendNUIMessage({
		action = 'setPlayerBackpack',
		data = backpack
	})
end)

local StashTarget

exports('setStashTarget', function(id, owner)
	StashTarget = id and {id=id, owner=owner}
end)

local invBusy = true

local invOpen = false
local plyState = LocalPlayer.state
local IsPedCuffed = IsPedCuffed
local playerPed = cache.ped

local dropObjects = {}
local dropObjectsByNetId = {}
local dropTargetRecords = {}
client.dropObjects = dropObjects
client.dropObjectsByNetId = dropObjectsByNetId
client.dropTargetRecords = dropTargetRecords

lib.onCache('ped', function(ped)
	playerPed = ped
	Utils.WeaponWheel()
end)

local function applyClothingSyncResponse(response)
	if not Clothing.enabled or type(response) ~= 'table' or type(response.items) ~= 'table' then return end
	if not PlayerData or type(PlayerData.inventory) ~= 'table' then return end

	for i = 1, #response.items do
		local update = response.items[i]
		local item = update and update.item

		if type(item) == 'table' and item.slot and (not update.inventory or update.inventory == cache.serverId or update.inventory == PlayerData.source or update.inventory == 'player') then
			PlayerData.inventory[item.slot] = item.name and item.count and item or nil
		end
	end

	if response.weight and response.weight ~= PlayerData.weight then
		client.setPlayerData('weight', response.weight)
	end
end

local function syncClothingInventoryFromPed(waitForAppearance)
	if not Clothing.enabled then return end



	if waitForAppearance then
		Clothing.waitForAppearance(5000)
	end

	applyClothingSyncResponse(Clothing.syncInventoryWithPed())

	if PlayerData and type(PlayerData.inventory) == 'table' then
		Clothing.syncSlotState(PlayerData.inventory)

		if waitForAppearance then
			Clothing.applyCurrentSlotState()
		end
	end
end

local clothingAppearanceSyncThread
local clothingAppearanceSignature

local function startClothingAppearanceSync()
	if clothingAppearanceSyncThread or not Clothing.enabled then return end

	clothingAppearanceSyncThread = true

	CreateThread(function()
		Wait(3000)

		while PlayerData and PlayerData.loaded do
			local signature = Clothing.getPedSignature()

			if signature and signature ~= clothingAppearanceSignature then
				clothingAppearanceSignature = signature
				syncClothingInventoryFromPed()
			end

			Wait(5000)
		end

		clothingAppearanceSyncThread = false
		clothingAppearanceSignature = nil
	end)
end

plyState:set('invBusy', true, true)
plyState:set('invHotkeys', false, false)
plyState:set('canUseWeapons', false, false)


local function canOpenInventory()
    if not PlayerData.loaded then
        return shared.info('cannot open inventory', '(player inventory has not loaded)')
    end

    if IsPauseMenuActive() then return end
	if LocalPlayer.state.inArena then return end

    if invBusy or invOpen == nil or (currentWeapon?.timer or 0) > 0 then
        return shared.info('cannot open inventory', '(is busy)')
    end

    if (PlayerData.dead or IsPedFatallyInjured(playerPed)) and LocalPlayer.state.deathState ~= 'laststand' then
        return shared.info('cannot open inventory', '(fatal injury)')
    end

    if PlayerData.cuffed or IsPedCuffed(playerPed) or LocalPlayer.state.isCuffed or LocalPlayer.state.handcuffed
        or (GetResourceState('origen_police') == 'started' and exports['origen_police']:IsHandcuffed()) then
        return shared.info('cannot open inventory', '(cuffed)')
    end

    return true
end

local function canOpenTarget(ped)
	local owner = NetworkGetEntityOwner(ped)
	local id = GetPlayerServerId(owner)

	return IsPedFatallyInjured(ped)
	or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
	or IsPedCuffed(ped)
	or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
	or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
	or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
	or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
	or Player(id).state.isLastStand
	or Player(id).state.isDead
end

local defaultInventory = {
	type = 'newdrop',
	slots = shared.playerslots,
	weight = 0,
	maxWeight = shared.playerweight,
	items = {}
}

local currentInventory = defaultInventory
local Theme = lib.load('data.ui') or {}
local Rarity = lib.load('data.rarity')
local UtilityConfig = lib.load('data.utility') or {}
local inventoryCam
local inventoryCamActive = false

local backpackItemNames = {}
for name in pairs(UtilityConfig.backpackItems or {}) do
    backpackItemNames[#backpackItemNames + 1] = name
end

RegisterNetEvent('ox_inventory:backpackLabelUpdated', function(inventoryId, label)
	SendNUIMessage({
		action = 'setBackpackLabel',
		data = { inventoryId = inventoryId, label = label }
	})
end)

RegisterNetEvent('ox_inventory:utility:updateBackpack', function(inventoryId, backpack)
    if not inventoryId then return end
    
    if PlayerData.id == inventoryId then
        SendNUIMessage({
            action = 'setPlayerBackpack',
            data = backpack
        })
    elseif currentInventory and currentInventory.id == inventoryId then
        SendNUIMessage({
            action = 'setOtherBackpack',
            data = backpack
        })
    end
end)

local function closeTrunk()
	if currentInventory?.type == 'trunk' then
		local coords = GetEntityCoords(playerPed, true)
		Utils.PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)

		CreateThread(function()
			local entity = currentInventory.entity
			local door = currentInventory.door
			Wait(900)

			if type(door) == 'table' then
				for i = 1, #door do
					SetVehicleDoorShut(entity, door[i], false)
				end
			else
				SetVehicleDoorShut(entity, door, false)
			end
		end)
	end
end

-- El crafteo está en jj_crafting: aquí ya no hay mesas
local CraftingBenches = {}
require 'modules.storage.client'
local Vehicles = lib.load('data.vehicles')
local Inventory = require 'modules.inventory.client'

function client.openInventory(inv, data)
	if invOpen then
		if not inv and currentInventory.type == 'newdrop' then
			return client.closeInventory()
		end

		if IsNuiFocused() then
			if inv == 'container' and currentInventory.id == PlayerData.inventory[data].metadata.container then
				return client.closeInventory()
			end

			if currentInventory.type == 'drop' and (not data or currentInventory.id == (type(data) == 'table' and data.id or data)) then
				return client.closeInventory()
			end

			if inv ~= 'drop' and inv ~= 'container' then
				if (data?.id or data) == currentInventory?.id then
					return warn(("script tried to open inventory, but it is already open\n%s"):format(Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())))
				else
					return client.closeInventory()
				end
			end
		end
	elseif IsNuiFocused() then		Wait(100)

	end

	if inv == 'dumpster' and cache.vehicle then
		return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
	end

	if not canOpenInventory() then
        return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
    end

    local left, right, accessError, craftingStorage

    if inv == 'player' and data ~= cache.serverId then
        local targetId, targetPed, serverId

        if not data then
            targetId, targetPed = Utils.GetClosestPlayer()
            serverId = targetId and GetPlayerServerId(targetId)
            data = serverId
        else
            serverId = type(data) == 'table' and data.id or data

            if serverId == cache.serverId then return end

            targetId = serverId and GetPlayerFromServerId(serverId)
            targetPed = targetId and GetPlayerPed(targetId)
        end

        local targetCoords = targetPed and GetEntityCoords(targetPed)

        if not targetCoords or #(targetCoords - GetEntityCoords(playerPed)) > 1.8 or (not client.hasGroup(shared.police) and not Player(serverId).state.canSteal) then
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
        end
    end

    if inv == 'shop' and invOpen == false then
        if cache.vehicle then
            return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
        end

        left, right, accessError = lib.callback.await('ox_inventory:openShop', 200, data)
	elseif inv == 'storage' then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		left, right, accessError = lib.callback.await('ox_inventory:storage:open', false, data.id)
	elseif inv == 'crafting' then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		lib.print.debug('[ox_inventory] Opening crafting bench - id:', data.id, 'index:', data.index)
		
		left, right, accessError = lib.callback.await('ox_inventory:openCraftingBench', 200, data.id, data.index)

		lib.print.debug('[ox_inventory] Crafting bench callback result - left:', left and 'exists' or 'nil', 'right:', right and 'exists' or 'nil', 'accessError:', accessError)

		if left then
			lib.print.debug('[ox_inventory] Processing crafting bench data')
			
			local craftingInfo = left.crafting
			local storagePayload = left.storage
			
			lib.print.debug('[ox_inventory] Crafting info:', craftingInfo and 'exists' or 'nil', 'Storage payload:', storagePayload and 'exists' or 'nil')
			
			craftingStorage = storagePayload
			left.crafting = nil
			left.storage = nil

			local benchTemplate = CraftingBenches[data.id]
			
			lib.print.debug('[ox_inventory] Bench template:', benchTemplate and 'exists' or 'nil')

			if not benchTemplate?.items then 
				lib.print.debug('[ox_inventory] No bench template items found for id:', data.id)
				return 
			end

			local coords, distance

			if shared.target and benchTemplate.zones then
				local zone = benchTemplate.zones[data.index]
				if zone then
					coords = zone.coords
					distance = zone.distance or 2
					lib.print.debug('[ox_inventory] Using zone coords:', coords, 'distance:', distance)
				end
			elseif benchTemplate.points then
				coords = benchTemplate.points[data.index]
				distance = 2
				lib.print.debug('[ox_inventory] Using point coords:', coords, 'distance:', distance)
			end

			if not coords then
				coords = GetEntityCoords(cache.ped)
				distance = distance or 2
				lib.print.debug('[ox_inventory] Using player coords:', coords, 'distance:', distance)
			end

			right = {
				type = 'crafting',
				id = data.id,
				label = benchTemplate.label or locale('crafting_bench'),
				index = data.index,
				slots = benchTemplate.slots,
				items = benchTemplate.items,
				coords = coords,
				distance = distance,
				storage = storagePayload,
				crafting = craftingInfo
			}
			
			lib.print.debug('[ox_inventory] Created right inventory for crafting bench:', right.type, right.id, right.label)
		end
    elseif invOpen ~= nil then
        if inv == 'policeevidence' then
            if not data then
                local input = lib.inputDialog(locale('police_evidence'), {
                    { label = locale('locker_number'), type = 'number', required = true, icon = 'calculator' }
                })

                if not input then return end

                data = input[1]
            end
        end

        left, right, accessError = lib.callback.await('ox_inventory:openInventory', false, inv, data)
    end

    if accessError then
        return lib.notify({ id = accessError, type = 'error', description = locale(accessError) })
    end

   
    if not left then
        if left == false then return false end

        if invOpen == false then
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
        end

        if invOpen then return client.closeInventory() end
    end

    if not cache.vehicle then
        if inv == 'player' then
            Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 8.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
        elseif inv ~= 'trunk' then
            Utils.PlayAnim(0, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
        end
    end

    plyState.invOpen = true

    SetInterval(client.interval, 100)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	syncClothingInventoryFromPed()
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	if currentInventory and currentInventory.type == 'crafting' then
		if craftingStorage then
			left.backpack = craftingStorage
		else
			left.backpack = nil
		end

		if currentInventory then
			currentInventory.backpack = nil
			currentInventory.otherBackpack = nil
			currentInventory.storage = craftingStorage
		end
	else
		left.backpack = left.backpack or nil

		if currentInventory then
			if currentInventory.otherBackpack then
				currentInventory.backpack = currentInventory.otherBackpack
			else
				currentInventory.backpack = nil
				currentInventory.otherBackpack = nil
			end

			currentInventory.storage = nil
		end
	end

	if Utility.enabled then
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory then
			if currentInventory.items and (currentInventory.type == 'player' or currentInventory.type == 'inspect' or currentInventory.type == 'otherplayer') then
				currentInventory.utility = Utility.collect(currentInventory.items)
			else
				currentInventory.utility = nil
			end
		end
	end

    if Clothing.enabled then
        local cfg = table.clone(Clothing.config)
        cfg.slots = Clothing.getSlots()
        left.clothingConfig = cfg
        left.clothing = Clothing.collect(PlayerData.inventory)

        if currentInventory and currentInventory.items and
           (currentInventory.type == 'player' or currentInventory.type == 'inspect' or currentInventory.type == 'otherplayer') then
            currentInventory.clothing = Clothing.collectOther(currentInventory.items)
            currentInventory.clothingConfig = cfg
        end
    end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
            leftInventory = left,
            rightInventory = currentInventory
        }
    })

    if Clothing.enabled then
        Clothing.pushAppearance()
    end

    if inv and not currentInventory.coords and inv ~= 'container' and inv ~= 'glovebox' then
        currentInventory.coords = GetEntityCoords(playerPed)
    end

    if inv == 'trunk' then
        SetTimeout(200, function()
            Utils.PlayAnim(0, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0.0, 0, 0, 0)

            local entity = data.entity or NetworkGetEntityFromNetworkId(data.netid)
            currentInventory.entity = entity
            currentInventory.door = data.door

            if not currentInventory.door then
                local vehicleHash = GetEntityModel(entity)
                local vehicleClass = GetVehicleClass(entity)
                currentInventory.door = vehicleClass == 12 and { 2, 3 } or Vehicles.Storage[vehicleHash] and 4 or 5
            end

            while currentInventory?.entity == entity and invOpen and DoesEntityExist(entity) and Inventory.CanAccessTrunk(entity) do
                Wait(100)
            end

            if invOpen then client.closeInventory() end
        end)
    end

    return true
end

RegisterNetEvent('ox_inventory:openInventory', client.openInventory)
exports('openInventory', client.openInventory)

RegisterNetEvent('ox_inventory:forceOpenInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	syncClothingInventoryFromPed()
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	if Utility.enabled then
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory then
			if currentInventory.items and (currentInventory.type == 'player' or currentInventory.type == 'inspect' or currentInventory.type == 'otherplayer') then
				currentInventory.utility = Utility.collect(currentInventory.items)
			else
				currentInventory.utility = nil
			end
		end
	end

    if Clothing.enabled then
        local cfg = table.clone(Clothing.config)
        cfg.slots = Clothing.getSlots()
        left.clothingConfig = cfg
        left.clothing = Clothing.collect(PlayerData.inventory)

        if currentInventory and currentInventory.items and
           (currentInventory.type == 'player' or currentInventory.type == 'inspect' or currentInventory.type == 'otherplayer') then
            currentInventory.clothing = Clothing.collectOther(currentInventory.items)
            currentInventory.clothingConfig = cfg
        end
    end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})

    if Clothing.enabled then
        Clothing.pushAppearance()
    end
end)

local Animations = lib.load('data.animations')
local Items = require 'modules.items.client'
local usingItem = false

lib.callback.register('ox_inventory:usingItem', function(data, noAnim)
	local item = Items[data.name]

	if item and usingItem then
		if not item.client then return true end
		item = item.client

		if type(item.anim) == 'string' then
			item.anim = Animations.anim[item.anim]
		end

		if item.prop then
			if item.prop[1] then
				for i = 1, #item.prop do
					if type(item.prop) == 'string' then
						item.prop = Animations.prop[item.prop[i]]
					end
				end
			elseif type(item.prop) == 'string' then
				item.prop = Animations.prop[item.prop]
			end
		end

		if not item.disable then
			item.disable = { combat = true }
		elseif item.disable.combat == nil then
			item.disable.combat = true
		end

		local success = (not item.usetime or noAnim or lib.progressBar({
			duration = item.usetime,
			label = item.label or locale('using', data.metadata.label or data.label),
			useWhileDead = item.useWhileDead,
			canCancel = item.cancel,
			disable = item.disable,
			anim = item.anim or item.scenario,
			prop = item.prop
		})) and not PlayerData.dead

		if success then
			if item.notification then
				lib.notify({ description = item.notification })
			end

			if item.status then
				if client.setPlayerStatus then
					client.setPlayerStatus(item.status)
				end
			end

			return true
		end
	end
end)

local function canUseItem(isAmmo)
	local ped = cache.ped

	return not usingItem
    and (not isAmmo or currentWeapon)
	and PlayerData.loaded
	and not PlayerData.dead
	and not invBusy
	and not lib.progressActive()
    and not IsPedRagdoll(ped)
    and not IsPedFalling(ped)
    and not IsPedShooting(playerPed)
end

local useSlot

local function useItem(data, cb, noAnim, fromUseSlot)
	local inventoryId = data.inventory
	local slotData

	if not canUseItem(data.ammo and true) then
        if currentWeapon then
            return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
        end

        return
    end

	if inventoryId and inventoryId ~= 'player' then
		if data.slotData and type(data.slotData) == 'table' and data.slotData.slot then
			slotData = data.slotData
		else
			local inv = lib.callback.await('ox_inventory:getInventory', 200, inventoryId)

			if not inv or not inv.items then
				return
			end

			for _, it in pairs(inv.items) do
				if it and it.slot == (data.slot or data.item and data.item.slot) then
					slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
					break
				end
			end

			if not slotData then
				for _, it in pairs(inv.items) do
					if it and it.name == (data.item and data.item.name) and it.count == (data.item and data.item.count) then
						slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
						break
					end
				end
			end

			if not slotData then return end
		end
	else
		slotData = PlayerData.inventory[data.slot]
	end

	if not slotData then return end

	slotData.metadata = slotData.metadata or {}

	if not fromUseSlot then
		local itemData = Items[slotData.name]
		local isPlayerInventory = not inventoryId
			or inventoryId == 'player'
			or inventoryId == PlayerData.id
			or inventoryId == PlayerData.source

		if isPlayerInventory and (itemData?.weapon or slotData.metadata?.container or itemData?.component) then
			return useSlot(slotData.slot, noAnim)
		end
	end

	if currentWeapon and currentWeapon.timer ~= 0 then
        if not currentWeapon.timer or currentWeapon.timer - GetGameTimer() > 100 then return end

        DisablePlayerFiring(cache.playerId, true)
    end

    if invOpen and data.close then client.closeInventory() end

    usingItem = true
    result = lib.callback.await('ox_inventory:useItem', 200, data.name, data.slot, slotData.metadata, noAnim, inventoryId)

	if result and cb then
		local success, response = pcall(cb, result and slotData)

		if not success and response then
			warn(('^1An error occurred while calling item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(slotData.name, response))
		end
	end

    if result then
        TriggerEvent('ox_inventory:usedItem', slotData.name, slotData.slot, next(slotData.metadata) and slotData.metadata, inventoryId)
    end

	Wait(500)
    usingItem = false
end

AddEventHandler('ox_inventory:usedItem', function(name, slot, metadata, inventoryId)
    TriggerServerEvent('ox_inventory:usedItemInternal', slot, inventoryId)
end)

AddEventHandler('ox_inventory:item', useItem)
exports('useItem', useItem)

function useSlot(slot, noAnim)
	local item = PlayerData.inventory[slot]
	if not item then return end

	local data = Items[item.name]
	if not data then return end

	if canUseItem(data.ammo and true) then
		if data.component and not currentWeapon then
			return lib.notify({ id = 'weapon_hand_required', type = 'error', description = locale('weapon_hand_required') })
		end

		local durability = item.metadata.durability
		local consume = data.consume
		local label = item.metadata.label or item.label

		if durability and durability <= 100 and consume then
			if durability <= 0 then
				return lib.notify({ type = 'error', description = locale('no_durability', label) })
			elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
				return lib.notify({ type = 'error', description = locale('not_enough_durability', label) })
			end
		end

		data.slot = slot

		if item.metadata.container then
			return client.openInventory('container', item.slot)
		elseif data.client then
			if invOpen and data.close then client.closeInventory() end

			if data.export then
				return data.export(data, {name = item.name, slot = item.slot, metadata = item.metadata})
			elseif data.client.event then 
				return TriggerEvent(data.client.event, data, {name = item.name, slot = item.slot, metadata = item.metadata})
			end
		end

		if data.effect then
			data:effect({name = item.name, slot = item.slot, metadata = item.metadata})
		elseif data.weapon then
			if EnableWeaponWheel or not plyState.canUseWeapons then return end

			if IsCinematicCamRendering() then SetCinematicModeActive(false) end

			if currentWeapon then
                if not currentWeapon.timer or currentWeapon.timer ~= 0 then return end

				local weaponSlot = currentWeapon.slot
				currentWeapon = Weapon.Disarm(currentWeapon)

				if weaponSlot == data.slot then return end
			end

            GiveWeaponToPed(playerPed, data.hash, 0, false, true)
            SetCurrentPedWeapon(playerPed, data.hash, false)

            if data.hash ~= GetSelectedPedWeapon(playerPed) then
                lib.print.info(('failed to equip %s (cause unknown)'):format(item.name))
                return lib.notify({ type = 'error', description = locale('cannot_use', data.label) })
            end

            RemoveWeaponFromPed(cache.ped, data.hash)

			useItem(data, function(result)
				if result then
					if invOpen then client.closeInventory() end 
                    local sleep
					currentWeapon, sleep = Weapon.Equip(item, data, noAnim)

					if sleep then Wait(sleep) end
				end
			end, noAnim, true)
		elseif currentWeapon then
			if data.ammo then
				if EnableWeaponWheel or currentWeapon.metadata.durability <= 0 then return end

				local clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
				local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
				local _, maxAmmo = GetMaxAmmo(playerPed, currentWeapon.hash)

				if maxAmmo < clipSize then clipSize = maxAmmo end

				if currentAmmo == clipSize then return end

				useItem(data, function(resp)
					if not resp or resp.name ~= currentWeapon?.ammo then return end

					if currentWeapon.metadata.specialAmmo ~= resp.metadata.type and type(currentWeapon.metadata.specialAmmo) == 'string' then
						local clipComponentKey = ('%s_CLIP'):format(Items[currentWeapon.name].model:gsub('WEAPON_', 'COMPONENT_'))
						local specialClip = ('%s_%s'):format(clipComponentKey, (resp.metadata.type or currentWeapon.metadata.specialAmmo):upper())

						if type(resp.metadata.type) == 'string' then
							if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
								if not DoesWeaponTakeWeaponComponent(currentWeapon.hash, specialClip) then
									warn('cannot use clip with this weapon')
									return
								end

								local defaultClip = ('%s_01'):format(clipComponentKey)

								if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, defaultClip) then
									warn('cannot use clip with currently equipped clip')
									return
								end

								if currentAmmo > 0 then
									warn('cannot mix special ammo with base ammo')
									return
								end

								currentWeapon.metadata.specialAmmo = resp.metadata.type

								GiveWeaponComponentToPed(playerPed, currentWeapon.hash, specialClip)
							end
						elseif HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
							if currentAmmo > 0 then
								warn('cannot mix special ammo with base ammo')
								return
							end

							currentWeapon.metadata.specialAmmo = nil

							RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, specialClip)
						end
					end

					if maxAmmo > clipSize then
						clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
					end

					currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
					local missingAmmo = clipSize - currentAmmo
					local addAmmo = resp.count > missingAmmo and missingAmmo or resp.count
					local newAmmo = currentAmmo + addAmmo

					if newAmmo == currentAmmo then return end

                    AddAmmoToPed(playerPed, currentWeapon.hash, addAmmo)

					if cache.vehicle then
						if cache.seat > -1 or IsVehicleStopped(cache.vehicle) then
							TaskReloadWeapon(playerPed, true)
                        else
                            lib.waitFor(function()
                                RefillAmmoInstantly(playerPed)

                                local _, ammo = GetAmmoInClip(playerPed, currentWeapon.hash)
                                return ammo == newAmmo or nil
                            end)
                        end
					else
						Wait(100)
						MakePedReload(playerPed)

						SetTimeout(100, function()
							while IsPedReloading(playerPed) do
								DisableControlAction(0, 22, true)
								Wait(0)
							end
						end)
					end

					lib.callback.await('ox_inventory:updateWeapon', false, 'load', newAmmo, false, currentWeapon.metadata.specialAmmo)
				end, nil, true)
			elseif data.component then
				local components = data.client.component

                if not components then return end

				local componentType = data.type
				local weaponComponents = PlayerData.inventory[currentWeapon.slot].metadata.components

				for componentIndex = 1, #weaponComponents do
					if componentType == Items[weaponComponents[componentIndex]].type then
						return lib.notify({ id = 'component_slot_occupied', type = 'error', description = locale('component_slot_occupied', componentType) })
					end
				end

				for i = 1, #components do
					local component = components[i]

					if DoesWeaponTakeWeaponComponent(currentWeapon.hash, component) then
						if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
							lib.notify({ id = 'component_has', type = 'error', description = locale('component_has', label) })
						else
							useItem(data, function(data)
								if data then
									local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', tostring(data.slot), currentWeapon.slot)

									if success then
										GiveWeaponComponentToPed(playerPed, currentWeapon.hash, component)
										TriggerEvent('ox_inventory:updateWeaponComponent', 'added', component, data.name)
									end
								end
							end, nil, true)
						end
						return
					end
				end
				lib.notify({ id = 'component_invalid', type = 'error', description = locale('component_invalid', label) })
			elseif data.allowArmed then
				useItem(data, nil, nil, true)
            else
                return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
			end
		elseif not data.ammo and not data.component then
			useItem(data, nil, nil, true)
		end
    end
end
exports('useSlot', useSlot)

local function useButton(id, slot)
	if PlayerData.loaded and not invBusy and not lib.progressActive() then
		local item = PlayerData.inventory[slot]
		if not item then return end

		local data = Items[item.name]
		local buttons = data?.buttons

		if buttons and buttons[id]?.action then
			buttons[id].action(slot)
		end
	end
end

local function openNearbyInventory() client.openInventory('player') end

exports('openNearbyInventory', openNearbyInventory)

local currentInstance
local playerCoords
local Shops = require 'modules.shops.client'

function OnPlayerData(key, val)
	if key ~= 'groups' and key ~= 'ped' and key ~= 'dead' then return end

	if key == 'groups' then
		Inventory.Stashes()
		Inventory.Evidence()
		Shops.refreshShops()
	elseif key == 'dead' and val then
		currentWeapon = Weapon.Disarm(currentWeapon)
		client.closeInventory()
	end

	Utils.WeaponWheel()
end

if not Utils or not Weapon or not Items or not Inventory then return end

local invHotkeys = false

local function registerCommands()
	if client.enablestealcommand then
		RegisterCommand('steal', openNearbyInventory, false)
	end

	local function openGlovebox(vehicle)
		if not IsPedInAnyVehicle(playerPed, false) or not NetworkGetEntityIsNetworked(vehicle) then return end

		local vehicleHash = GetEntityModel(vehicle)
		local vehicleClass = GetVehicleClass(vehicle)
		local checkVehicle = Vehicles.Storage[vehicleHash]

		
		if (checkVehicle == 0 or checkVehicle == 2) or (not Vehicles.glovebox[vehicleClass] and not Vehicles.glovebox.models[vehicleHash]) then return end

		local isOpen = client.openInventory('glovebox', { netid = NetworkGetNetworkIdFromEntity(vehicle) })

		if isOpen then
			currentInventory.entity = vehicle
		end
	end

	local primary = lib.addKeybind({
		name = 'inv',
		description = locale('open_player_inventory'),
		defaultKey = client.keys[1],
		onPressed = function()
			if invOpen then
				return client.closeInventory()
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local closest = lib.points.getClosestPoint()

			if closest and closest.currentDistance < 1.2 and (not closest.instance or closest.instance == currentInstance) then
				if closest.inv == 'crafting' then
					return client.openInventory('crafting', { id = closest.id, index = closest.index })
				elseif closest.inv ~= 'license' and closest.inv ~= 'policeevidence' then
					return client.openInventory(closest.inv or 'drop', { id = closest.invId, type = closest.type })
				end
			end

			return client.openInventory()
		end
	})

	lib.addKeybind({
		name = 'inv2',
		description = locale('open_secondary_inventory'),
		defaultKey = client.keys[2],
		onPressed = function(self)
            if primary:getCurrentKey() == self:getCurrentKey() then
                return warn(("secondary inventory keybind '%s' disabled (keybind cannot match primary inventory keybind)"):format(self:getCurrentKey()))
            end

			if invOpen then return end

			if invBusy or not canOpenInventory() then
				return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
			end

			if StashTarget then
				return client.openInventory('stash', StashTarget)
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local entity, entityType = Utils.Raycast(2|16)

			if not entity then return end

			if not shared.target and entityType == 3 then
				local model = GetEntityModel(entity)

				if Inventory.Dumpsters:includes(model) then
					return Inventory.OpenDumpster(entity)
				end
			end

			if entityType ~= 2 then return end

			Inventory.OpenTrunk(entity)
		end
	})

	lib.addKeybind({
		name = 'reloadweapon',
		description = locale('reload_weapon'),
		defaultKey = 'r',
		onPressed = function(self)
			if not currentWeapon or EnableWeaponWheel or not canUseItem(true) then return end

			if currentWeapon.ammo then
				if currentWeapon.metadata.durability > 0 then
					local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

					if slotId then
						useSlot(slotId)
					end
				else
					lib.notify({ id = 'no_durability', type = 'error', description = locale('no_durability', currentWeapon.label) })
				end
			end
		end
	})

	lib.addKeybind({
		name = 'hotbar',
		description = locale('disable_hotbar'),
		defaultKey = client.keys[3],
		onPressed = function()
			if EnableWeaponWheel or IsNuiFocused() or lib.progressActive() then return end
			SendNUIMessage({ action = 'toggleHotbar' })
		end
	})

	for i = 1, 5 do
		lib.addKeybind({
			name = ('hotkey%s'):format(i),
			description = locale('use_hotbar', i),
			defaultKey = tostring(i),
			onPressed = function()
				if invOpen or EnableWeaponWheel or not invHotkeys or IsNuiFocused() then return end
				useSlot(i)
			end
		})
	end

	registerCommands = nil
end

function client.closeInventory(server)
	if not client.interval then return end

	if invOpen then
		invOpen = nil
        if Clothing.enabled then
            Clothing.disablePreview()
        end
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		if client.screenblur then TriggerScreenblurFadeOut(0) end
		closeTrunk()
		SendNUIMessage({ action = 'closeInventory' })
		SetInterval(client.interval, 200)
		Wait(200)

		if invOpen ~= nil then return end

		if currentInventory then
			TriggerServerEvent('ox_inventory:closeInventory')
		end

		currentInventory = defaultInventory
		plyState.invOpen = false
		defaultInventory.coords = nil
	end
end

RegisterNetEvent('ox_inventory:closeInventory', client.closeInventory)
exports('closeInventory', client.closeInventory)

local function updateInventory(data, weight)
	local changes = {}
	local itemCount = {}
	local playerUtilityChanged = false
	local playerClothingChanged = false

	for i = 1, #data do
		local v = data[i]

		if not v.inventory or v.inventory == cache.serverId then
			v.inventory = 'player'
			local item = v.item

			if type(item) ~= 'table' or not item.slot then
				goto update_inventory_continue
			end

			if currentWeapon?.slot == item?.slot then
				if item.count and item.metadata and item.name == currentWeapon.name then
					currentWeapon.metadata = item.metadata
					TriggerEvent('ox_inventory:currentWeapon', currentWeapon)
				else
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end

			local curItem = PlayerData.inventory[item.slot]

			if curItem and curItem.name then
				itemCount[curItem.name] = (itemCount[curItem.name] or 0) - curItem.count
			end

			if item.count then
			itemCount[item.name] = (itemCount[item.name] or 0) + item.count
			end

			changes[item.slot] = item.count and item or false
			if not item.count then item.name = nil end
			PlayerData.inventory[item.slot] = item.name and item or nil

			if Utility.enabled then
				local utilitySlot = Utility.getUtilitySlot(item.metadata, item.slot)

				if (utilitySlot and utilitySlot >= 1) or (Utility.slotOffset > 0 and item.slot and item.slot >= Utility.slotOffset) then
					playerUtilityChanged = true
				end
			end

			if Clothing.enabled and Clothing.slotOffset > 0 and item.slot and item.slot > Clothing.slotOffset then
				playerClothingChanged = true
			end
		end

		::update_inventory_continue::
	end

	local payload = {
		items = data,
		itemCount = itemCount
	}

	if Utility.enabled and playerUtilityChanged then
		payload.leftUtility = Utility.collect(PlayerData.inventory)
		Utility.refreshArmorFromInventory(PlayerData.inventory)
		Utility.refreshBackpackFromInventory(PlayerData.inventory)
	end

	if Clothing.enabled and playerClothingChanged then
		payload.leftClothing = Clothing.collect(PlayerData.inventory)
	end

	SendNUIMessage({ action = 'refreshSlots', data = payload })

    if weight ~= PlayerData.weight then client.setPlayerData('weight', weight) end

	for itemName, count in pairs(itemCount) do
		local item = Items(itemName)

        if item then
            item.count += count

            TriggerEvent('ox_inventory:itemCount', item.name, item.count)

            if count < 0 then
                if shared.framework == 'esx' then
                    TriggerEvent('esx:removeInventoryItem', item.name, item.count)
                end

                if item.client?.remove then
                    item.client.remove(item.count)
                end
            elseif count > 0 then
                if shared.framework == 'esx' then
                    TriggerEvent('esx:addInventoryItem', item.name, item.count)
                end

                if item.client?.add then
                    item.client.add(item.count)
                end
            end
        end
	end

	client.setPlayerData('inventory', PlayerData.inventory)
	TriggerEvent('ox_inventory:updateInventory', changes)
end

RegisterNetEvent('ox_inventory:updateSlots', function(items, weights)
	if source ~= '' and next(items) then updateInventory(items, weights) end
end)

RegisterNetEvent('ox_inventory:inventoryReturned', function(data)
	if source == '' then return end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	lib.notify({ description = locale('items_returned') })
	client.closeInventory()

	local num, items = 0, {}

	for _, slotData in pairs(data[1]) do
		num += 1
		items[num] = { item = slotData, inventory = cache.serverId }
	end

	updateInventory(items, data[3])
end)

RegisterNetEvent('ox_inventory:inventoryConfiscated', function(message)
	if source == '' then return end
	if message then lib.notify({ description = locale('items_confiscated') }) end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	client.closeInventory()

	local num, items = 0, {}

	for slot in pairs(PlayerData.inventory) do
		num += 1
		items[num] = { item = { slot = slot }, inventory = cache.serverId }
	end

	updateInventory(items, 0)
end)

local function nearbyDrop(point)
	if not point.instance or point.instance == currentInstance then
		DrawMarker(client.dropmarker.type, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, client.dropmarker.scale[1], client.dropmarker.scale[2], client.dropmarker.scale[3],
			client.dropmarker.colour[1], client.dropmarker.colour[2], client.dropmarker.colour[3], 222, false, false, 0, true, false, false, false)
	end
end

local dropTargetDistance = 3.5
local dropWeaponTargetMinRadius = 0.22
local dropWeaponTargetRadiusPadding = 0.05
local dropPickupBusy = false

local function getDropPropEntry(dropId, uniqueId)
	local point = client.drops and client.drops[dropId]
	local itemProps = point and point.itemProps

	if not itemProps then return end

	for i = 1, #itemProps do
		local entry = itemProps[i]

		if entry.uniqueId == uniqueId then
			return entry
		end
	end
end

local function removeDropTarget(uniqueId)
	if not uniqueId then return end

	local record = dropTargetRecords[uniqueId]

	if not record then return end

	if GetResourceState('ox_target') == 'started' then
		if record.entity and record.optionName then
			pcall(function()
				exports.ox_target:removeLocalEntity(record.entity, record.optionName)
			end)
		end

		if record.zoneId then
			pcall(function()
				exports.ox_target:removeZone(record.zoneId)
			end)
		end
	end

	dropTargetRecords[uniqueId] = nil
end

local function pickupDropProp(dropId, uniqueId)
	if dropPickupBusy or invBusy or usingItem then return end

	dropPickupBusy = true

	local success, response = lib.callback.await('ox_inventory:pickupDropProp', false, {
		dropId = dropId,
		uniqueId = uniqueId
	})

	dropPickupBusy = false

	if success then
		Utils.PlayAnim(0, 'pickup_object', 'pickup_low', 1.0, 1.0, 800, 48, 0.0, 0, 0, 0)
	elseif response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end
end

local function getWeaponDropHash(itemName)
	if type(itemName) ~= 'string' then return false end

	local item = Items[itemName]
	local weaponHash

	if item and item.weapon then
		weaponHash = item.hash
	else
		weaponHash = joaat(itemName)
	end

	if weaponHash and weaponHash ~= 0 and IsWeaponValid(weaponHash) then
		return weaponHash
	end
end

local function isWeaponDropItem(itemName)
	return getWeaponDropHash(itemName) ~= nil
end

local function positionDropPropEntity(entity, itemName)
	PlaceObjectOnGroundProperly(entity)

	FreezeEntityPosition(entity, true)
	SetEntityCollision(entity, true, true)
end

local function getWeaponDropTargetZone(entity)
	local minDim, maxDim = GetModelDimensions(GetEntityModel(entity))
	local halfSize = (maxDim - minDim) / 2
	local coords = GetEntityCoords(entity)
	local centerLift = math.max(0.03, halfSize.z * 0.35)
	local radius = math.max(
		dropWeaponTargetMinRadius,
		math.max(halfSize.x, halfSize.y) + dropWeaponTargetRadiusPadding,
		centerLift + dropWeaponTargetRadiusPadding
	)

	return vec3(coords.x, coords.y, coords.z + centerLift), radius
end

local function ensureDropTarget(dropId, uniqueId, entity, entry)
	if GetResourceState('ox_target') ~= 'started' then
		removeDropTarget(uniqueId)
		return
	end

	if not uniqueId or entity == 0 or not DoesEntityExist(entity) then return end

	local existing = dropTargetRecords[uniqueId]
	local itemName = entry and entry.itemName
	local isWeapon = isWeaponDropItem(itemName)

	if existing and existing.entity == entity and not isWeapon and existing.optionName then return end
	if existing then removeDropTarget(uniqueId) end

	local itemLabel = itemName and Items[itemName] and Items[itemName].label or itemName or 'item'
	local optionName = ('ox_inventory_drop_%s'):format(uniqueId)

	if isWeapon then
		local coords, radius = getWeaponDropTargetZone(entity)
		local zoneId = exports.ox_target:addSphereZone({
			coords = coords,
			radius = radius,
			debug = false,
			options = {{
				name = optionName,
				icon = 'fas fa-hand',
				label = ('Coger %s'):format(itemLabel),
				distance = dropTargetDistance,
				canInteract = function(_, distance)
					return DoesEntityExist(entity) and (distance or 0) <= dropTargetDistance and not dropPickupBusy
				end,
				onSelect = function()
					pickupDropProp(dropId, uniqueId)
				end
			}}
		})

		dropTargetRecords[uniqueId] = {
			entity = entity,
			zoneId = zoneId
		}
	else
		exports.ox_target:addLocalEntity(entity, {{
			name = optionName,
			icon = 'fas fa-hand',
			label = ('Coger %s'):format(itemLabel),
			distance = dropTargetDistance,
			canInteract = function(_, distance)
				return DoesEntityExist(entity) and (distance or 0) <= dropTargetDistance and not dropPickupBusy
			end,
			onSelect = function()
				pickupDropProp(dropId, uniqueId)
			end
		}})

		dropTargetRecords[uniqueId] = {
			entity = entity,
			optionName = optionName
		}
	end
end

local function onEnterDrop(point)
	if point.instance and point.instance ~= currentInstance then return end

	point.entities = point.entities or {}

	if not client.force_drop_model and point.itemProps and next(point.itemProps) then
		for i = 1, #point.itemProps do
			local entry = point.itemProps[i]
			local uid = entry.uniqueId or ('%s_%s_%s'):format(point.invId or 'drop', entry.itemName or 'item', entry.slot or i)

			local entity = point.entities[uid]

			if not entity or not DoesEntityExist(entity) then
				local model = entry.modelp or point.model or client.dropmodel

				if not IsModelValid(model) and not IsModelInCdimage(model) then
					model = client.dropmodel
				end

				local coords = entry.coords or point.coords

				lib.requestModel(model)
				entity = CreateObject(model, coords.x, coords.y, coords.z, false, true, true)
				SetModelAsNoLongerNeeded(model)

				positionDropPropEntity(entity, entry.itemName)

				point.entities[uid] = entity
			end

			ensureDropTarget(point.invId, uid, entity, entry)
		end
	elseif point.propOnlyDrop then
		return
	elseif not point.entity then
		local model = point.model or client.dropmodel

		if client.force_drop_model then
			model = client.dropmodel
		end

        if not IsModelValid(model) and not IsModelInCdimage(model) then
            model = client.dropmodel
        end
		lib.requestModel(model)

		local entity = CreateObject(model, point.coords.x, point.coords.y, point.coords.z, false, true, true)

		SetModelAsNoLongerNeeded(model)
		positionDropPropEntity(entity)

		point.entity = entity
	end
end

local function onExitDrop(point)
	if point.entities then
		for uid, entity in pairs(point.entities) do
			removeDropTarget(uid)

			if entity and DoesEntityExist(entity) then
				Utils.DeleteEntity(entity)
			end

			point.entities[uid] = nil
		end
	end

	if point.entity then
		Utils.DeleteEntity(point.entity)
		point.entity = nil
	end
end

local function createDrop(dropId, data)
	local point = lib.points.new({
		coords = data.coords,
		distance = 16,
		invId = dropId,
		instance = data.instance,
		model = data.model or data.modelp
	})

	point.itemProps = data.itemProps
	point.hasPropObjects = data.hasPropObjects or (point.itemProps and next(point.itemProps) ~= nil) or false
	point.propOnlyDrop = point.hasPropObjects or (point.itemProps and next(point.itemProps) ~= nil) or false

	if point.itemProps and next(point.itemProps) then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	elseif point.model then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	elseif client.dropprops and not point.hasPropObjects then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	else
		if client.dropprops then
			point.distance = 30
		end

		point.nearby = nearbyDrop
	end

	point.entities = point.entities or {}
	client.drops[dropId] = point
end

RegisterNetEvent('ox_inventory:updateDropProps', function(dropId, itemProps)
	local point = client.drops and client.drops[dropId]
	if not point then return end

	point.itemProps = itemProps or {}
	point.hasPropObjects = next(point.itemProps) ~= nil
	point.entities = point.entities or {}

	if point.propOnlyDrop and not point.hasPropObjects and point.entity then
		Utils.DeleteEntity(point.entity)
		point.entity = nil
	end

	local valid = {}
	for i = 1, #point.itemProps do
		local entry = point.itemProps[i]
		if entry.uniqueId then
			valid[entry.uniqueId] = true
		end
	end

	for uid, ent in pairs(point.entities) do
		if not valid[uid] then
			removeDropTarget(uid)

			if ent and DoesEntityExist(ent) then
				Utils.DeleteEntity(ent)
			end
			point.entities[uid] = nil
		end
	end

	if point.currentDistance and point.currentDistance <= point.distance then
		onEnterDrop(point)
	end
end)

local function removeDropObject(uniqueId, netId)
	local record = uniqueId and dropObjects[uniqueId]
	local point

	if not record and netId then
		local uid = dropObjectsByNetId[netId]

		if uid then
			uniqueId = uid
			record = dropObjects[uid]
		end
	end

	if uniqueId then
		removeDropTarget(uniqueId)

		for dropId, p in pairs(client.drops or {}) do
			if p.entities and p.entities[uniqueId] then
				point = p
				break
			end
		end
	end

	if record and netId and record.netId and record.netId ~= netId then
		record = nil
	end

	if record then
		local entity = record.entity

		if not entity or not DoesEntityExist(entity) then
			local resolvedNetId = record.netId or netId
			entity = resolvedNetId and NetworkGetEntityFromNetworkId(resolvedNetId) or entity
		end

		if entity and DoesEntityExist(entity) then
			Utils.DeleteEntity(entity)
		end

		if record.netId then
			dropObjectsByNetId[record.netId] = nil
		end

		if uniqueId then
			dropObjects[uniqueId] = nil
		end

		if record.dropId then
			point = point or (client.drops and client.drops[record.dropId])

			if point and point.entities then
				point.entities[uniqueId] = nil

				if not next(point.entities) then
					point.hasPropObjects = false
				end
			end
		end
	else
		if netId then
			dropObjectsByNetId[netId] = nil
			local entity = NetworkGetEntityFromNetworkId(netId)

			if entity and DoesEntityExist(entity) then
				Utils.DeleteEntity(entity)
			end
		end

		if point and point.entities and uniqueId then
			local ent = point.entities[uniqueId]

			if ent and DoesEntityExist(ent) then
				Utils.DeleteEntity(ent)
			end

			point.entities[uniqueId] = nil
		end
	end

	if point and point.itemProps and uniqueId then
		for i = #point.itemProps, 1, -1 do
			if point.itemProps[i].uniqueId == uniqueId then
				table.remove(point.itemProps, i)
				break
			end
		end

		if not point.entities or not next(point.entities) then
			point.hasPropObjects = false
		end
	end
end

local function spawnDropProp(dropId, uniqueId, model, coords)
	if uniqueId and dropObjects[uniqueId] then
		removeDropObject(uniqueId)
	end

	if type(model) == 'string' then
		model = joaat(model)
	end

	if client.force_drop_model then
		model = client.dropmodel
	end

	if not model or model == 0 or (not IsModelValid(model) and not IsModelInCdimage(model)) then
		model = client.dropmodel
	end

	lib.requestModel(model)

	local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

	if not DoesEntityExist(entity) then
		SetModelAsNoLongerNeeded(model)
		return
	end

	SetEntityHeading(entity, math.random(0, 359))
	SetModelAsNoLongerNeeded(model)
	positionDropPropEntity(entity, getDropPropEntry(dropId, uniqueId)?.itemName)

	local netId = NetworkGetNetworkIdFromEntity(entity)
	local record = {
		netId = netId,
		entity = entity,
		dropId = dropId
	}

	dropObjects[uniqueId] = record

	if netId and netId ~= 0 then
		dropObjectsByNetId[netId] = uniqueId
	end

	local point = client.drops and client.drops[dropId]

	if point then
		point.hasPropObjects = true
		point.entities = point.entities or {}

		if point.entity then
			Utils.DeleteEntity(point.entity)
			point.entity = nil
		end

		point.entities[uniqueId] = entity
	end

	ensureDropTarget(dropId, uniqueId, entity, getDropPropEntry(dropId, uniqueId))

	return netId, entity
end

RegisterNetEvent('ox_inventory:createDrop', function(dropId, data, owner, slot)
	if client.drops then
		createDrop(dropId, data)
	end

	if owner == cache.serverId then
		if currentWeapon?.slot == slot then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end

		if invOpen and #(GetEntityCoords(playerPed) - data.coords) <= 1 then
			if not cache.vehicle then
				client.openInventory('drop', dropId)
			else
				SendNUIMessage({
					action = 'setupInventory',
					data = { rightInventory = currentInventory }
				})
			end
		end
	end
end)

RegisterNetEvent('ox_inventory:createDropProp', function(data)
	if not data or not data.coords then return end

	local uniqueId = data.uniqueId
	if not uniqueId then return end

	local dropId = data.dropId
	local netId, entity = spawnDropProp(dropId, uniqueId, data.modelp, data.coords)

	if entity then
		local finalCoords = GetEntityCoords(entity)
		TriggerServerEvent('ox_inventory:registerDropProp', uniqueId, netId or 0, finalCoords)
	end
end)

RegisterNetEvent('ox_inventory:updateDropProp', function(data)
	if not data or not data.uniqueId or not data.netId or data.netId == 0 then return end

	local dropId = data.dropId
	local uniqueId = data.uniqueId
	local netId = data.netId
	local coords = data.coords

	local entity = NetworkGetEntityFromNetworkId(netId)

	if entity and DoesEntityExist(entity) then
		dropObjects[uniqueId] = {
			netId = netId,
			entity = entity,
			dropId = dropId
		}

		dropObjectsByNetId[netId] = uniqueId

		if coords then
			SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
		end

		positionDropPropEntity(entity, getDropPropEntry(dropId, uniqueId)?.itemName)

		local point = client.drops and client.drops[dropId]

		if point then
			point.hasPropObjects = true
			point.entities = point.entities or {}
			point.entities[uniqueId] = entity

			ensureDropTarget(dropId, uniqueId, entity, getDropPropEntry(dropId, uniqueId))
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDrop', function(dropId)
	if client.drops then
		local point = client.drops[dropId]

		if point then
			if point.entities then
				for uniqueId in pairs(point.entities) do
					removeDropObject(uniqueId)
				end
			end

			client.drops[dropId] = nil
			point:remove()

			if point.entity then Utils.DeleteEntity(point.entity) end
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDropProp', function(netId, uniqueId)
	removeDropObject(uniqueId, netId)
end)

local function setStateBagHandler(stateId)
	AddStateBagChangeHandler('invOpen', stateId, function(_, _, value)
		invOpen = value
	end)

	AddStateBagChangeHandler('invBusy', stateId, function(_, _, value)
		invBusy = value
	end)

    AddStateBagChangeHandler('canUseWeapons', stateId, function(_, _, value)
        if not value and currentWeapon then
            currentWeapon = Weapon.Disarm(currentWeapon)
        end
    end)

	AddStateBagChangeHandler('instance', stateId, function(_, _, value)
		currentInstance = value

		if client.drops then
			for dropId, point in pairs(client.drops) do
				if point.instance then
					if point.instance ~= value then
						if point.entity then
							Utils.DeleteEntity(point.entity)
							point.entity = nil
						end

						point:remove()
					else
						createDrop(dropId, point)
					end
				end
			end
		end
	end)

	AddStateBagChangeHandler('dead', stateId, function(_, _, value)
		Utils.WeaponWheel()
		PlayerData.dead = value
	end)

	AddStateBagChangeHandler('invHotkeys', stateId, function(_, _, value)
		invHotkeys = value
	end)

	setStateBagHandler = nil
end

RegisterNetEvent('txcl:heal', function()
    if source == '' then return end

    PlayerData.dead = false
end)

lib.onCache('seat', function(seat)
	if seat then
		local hasWeapon = GetCurrentPedVehicleWeapon(cache.ped)

		if hasWeapon then
			return Utils.WeaponWheel(true)
		end
	end

	Utils.WeaponWheel(false)
end)

lib.onCache('vehicle', function()
	if invOpen and (not currentInventory.entity or currentInventory.entity == cache.vehicle) then
		return client.closeInventory()
	end
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function(currentDrops, inventory, weight, player)
	if source == '' then return end

	PlayerData = player
	PlayerData.id = cache.playerId
	PlayerData.source = cache.serverId
    PlayerData.maxWeight = shared.playerweight

	setmetatable(PlayerData, {
		__index = function(self, key)
			if key == 'ped' then
				return PlayerPedId()
			end
		end
	})

	if setStateBagHandler then setStateBagHandler(('player:%s'):format(cache.serverId)) end

	TriggerServerEvent('ox_inventory:storage:refreshPermissions')

	local ItemData = table.create(0, #Items)

	for _, v in pairs(Items) do
		local buttons = v.buttons and {} or nil

		if buttons then
			for i = 1, #v.buttons do
				buttons[i] = {label = v.buttons[i].label, group = v.buttons[i].group}
			end
		end

		ItemData[v.name] = {
			label = v.label,
			stack = v.stack,
			close = v.close,
			count = 0,
			description = v.description,
			buttons = buttons,
			ammoName = v.ammoname,
			image = v.client?.image,
            rarity = v.rarity or "common",
            weapon = v.weapon or nil,
            component = v.component or nil,
            type = v.type or nil,
		}
	end

	for _, data in pairs(inventory) do
		local item = Items[data.name]

		if item then
			item.count += data.count
			ItemData[data.name].count += data.count
			local add = item.client?.add

			if add then
				add(item.count)
			end
		end
	end

	local phone = Items.phone

	if phone and phone.count < 1 then
		pcall(function()
			return exports.npwd:setPhoneDisabled(true)
		end)
	end

	client.setPlayerData('inventory', inventory)
	client.setPlayerData('weight', weight)

	if Clothing.enabled then
		syncClothingInventoryFromPed(true)

		for _, item in pairs(Items) do
			item.count = 0

			if ItemData[item.name] then
				ItemData[item.name].count = 0
			end
		end

		for _, data in pairs(PlayerData.inventory) do
			local item = Items[data.name]

			if item then
				item.count += data.count
				ItemData[data.name].count += data.count
			end
		end
	end

	currentWeapon = nil
	Weapon.ClearAll()

	local locales = lib.getLocales()

	local uiLocales = {}

	for k, v in pairs(locales) do
		if type(v) == 'string' then
			uiLocales[k] = v
		end
	end

	uiLocales['$'] = locales['$']
	uiLocales.ammo_type = locales.ammo_type

	client.drops = currentDrops

	for dropId, data in pairs(currentDrops) do
		createDrop(dropId, data)
	end

	for dropId, data in pairs(currentDrops) do
		local props = data.itemProps

		if props then
			for i = 1, #props do
				local entry = props[i]
				local uniqueId = entry.uniqueId

				if uniqueId then
					local coords = entry.coords or data.coords
					local model = entry.modelp or data.modelp
					local netId = entry.netId
					local entity

					if netId and NetworkDoesNetworkIdExist(netId) then
						entity = NetworkGetEntityFromNetworkId(netId)
					end

					if entity and DoesEntityExist(entity) then
						dropObjects[uniqueId] = {
							netId = netId,
							entity = entity,
							dropId = dropId
						}

						if netId and netId ~= 0 then
							dropObjectsByNetId[netId] = uniqueId
						end

						local point = client.drops and client.drops[dropId]

						if point then
							point.hasPropObjects = true
							point.entities = point.entities or {}
							point.entities[uniqueId] = entity
						end
					else
					end
				end
			end
		end
	end

	local hasTextUi
	local uiOptions = { icon = 'fa-id-card' }

	local function nearbyLicense(point)
		if point.isClosest and point.currentDistance < 1.2 then
			if not hasTextUi then
				hasTextUi = point
				lib.showTextUI(point.message, uiOptions)
			end

			if IsControlJustReleased(0, 38) then
				lib.callback('ox_inventory:buyLicense', 1000, function(success, message)
					if success ~= nil then
						lib.notify({
							id = message,
							type = success == false and 'error' or 'success',
							description = locale(message, locale('license', point.type:gsub("^%l", string.upper)))
						})
					end
				end, point.invId)
			end
		elseif hasTextUi == point then
			hasTextUi = nil
			lib.hideTextUI()
		end
	end

	for id, data in pairs(lib.load('data.licenses') or {}) do
		lib.points.new({
			coords = data.coords,
			distance = 16,
			inv = 'license',
			type = data.name,
			price = data.price,
			invId = id,
			nearby = nearbyLicense,
			message = ('**%s**  \n%s'):format(locale('purchase_license', data.name), locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
		})
	end

	while not client.uiLoaded do Wait(50) end

	SendNUIMessage({
		action = 'init',
		data = {
			locale = uiLocales,
			items = ItemData,
			leftInventory = {
				id = cache.playerId,
				slots = shared.playerslots,
				items = PlayerData.inventory,
				maxWeight = shared.playerweight,
				weight = PlayerData.weight,
			},
			imagepath = client.imagepath,
			theme = Theme,
            rarity = Rarity,
            config = {
                disableUseInBackpack = Theme.disableUseInBackpack == true,
                backpackItems = backpackItemNames,
                allowItemRename = Theme.allowItemRename ~= false,
                allowBackpackRename = Theme.allowBackpackRename ~= false,
            }
		}
	})

	PlayerData.loaded = true

	if Clothing.enabled then
		startClothingAppearanceSync()
	end

	if not client.disablesetupnotification then
		lib.notify({ description = 'Inventario listo' })
	end
	Shops.refreshShops()
	Inventory.Stashes()
	Inventory.Evidence()

	if registerCommands then registerCommands() end

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	client.onLogin()

	client.interval = SetInterval(function()
        local canSteal = canOpenTarget(playerPed)

        if canSteal ~= plyState.canSteal then
            plyState:set('canSteal', canSteal, true)
        end

		if invOpen == false then
			playerCoords = GetEntityCoords(playerPed)

			if currentWeapon and IsPedUsingActionMode(playerPed) then
				SetPedUsingActionMode(playerPed, false, -1, 'DEFAULT_ACTION')
			end

		elseif invOpen == true then
			if not canOpenInventory() then
				client.closeInventory()
			else
				playerCoords = GetEntityCoords(playerPed)

				if currentInventory and not currentInventory.ignoreSecurityChecks then
                    local maxDistance = (currentInventory.distance or currentInventory.type == 'stash' and 4.8 or 1.8) + 0.2

					if currentInventory.type == 'otherplayer' then
						local id = GetPlayerFromServerId(currentInventory.id)
						local ped = GetPlayerPed(id)
						local pedCoords = GetEntityCoords(ped)

						print(id, #(playerCoords - pedCoords) > maxDistance, client.hasGroup(shared.police), Player(currentInventory.id).state.canSteal)
						if not id or #(playerCoords - pedCoords) > maxDistance or (not client.hasGroup(shared.police) and not Player(currentInventory.id).state.canSteal) then
							client.closeInventory()
							print('1')
							lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
						else
							TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 50)
						end

					elseif currentInventory.coords and (#(playerCoords - currentInventory.coords) > maxDistance or canOpenTarget(playerPed)) then
						client.closeInventory()
							print('2')

						lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
					end
				end
			end
		end

		if client.parachute and GetPedParachuteState(playerPed) ~= -1 then
			Utils.DeleteEntity(client.parachute[1])
			client.parachute = false
		end

		if EnableWeaponWheel then return end

		local weaponHash = GetSelectedPedWeapon(playerPed)

		if currentWeapon and not LocalPlayer.state.inArena then
			if weaponHash ~= currentWeapon.hash and currentWeapon.timer then
				local weaponCount = Items[currentWeapon.name]?.count

				if weaponCount > 0 then
					SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
					SetAmmoInClip(playerPed, currentWeapon.hash, currentWeapon.metadata.ammo)
					SetPedCurrentWeaponVisible(playerPed, true, false, false, false)

					weaponHash = GetSelectedPedWeapon(playerPed)
				end

				if weaponHash ~= currentWeapon.hash then
                    lib.print.info(('%s was forcibly unequipped (caused by game behaviour or another resource)'):format(currentWeapon.name))
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end
		elseif client.weaponmismatch and not client.ignoreweapons[weaponHash] and not LocalPlayer.state.inArena then
			local weaponType = GetWeapontypeGroup(weaponHash)

			if weaponType ~= 0 and weaponType ~= `GROUP_UNARMED` then
				Weapon.Disarm(currentWeapon, true)
			end
		end
	end, 200)

	local playerId = cache.playerId
	local EnableKeys = client.enablekeys
	local DisablePlayerVehicleRewards = DisablePlayerVehicleRewards
	local DisableAllControlActions = DisableAllControlActions
	local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
	local EnableControlAction = EnableControlAction
	local DisablePlayerFiring = DisablePlayerFiring
	local HudWeaponWheelIgnoreSelection = HudWeaponWheelIgnoreSelection
	local DisableControlAction = DisableControlAction
	local IsPedShooting = IsPedShooting
	local IsControlJustReleased = IsControlJustReleased

	client.tick = SetInterval(function()
		DisablePlayerVehicleRewards(playerId)

		if invOpen then
			DisableAllControlActions(0)
			HideHudAndRadarThisFrame()

			for i = 1, #EnableKeys do
				EnableControlAction(0, EnableKeys[i], true)
			end

			if currentInventory.type == 'drop' or currentInventory.type == 'newdrop' then
				EnableControlAction(0, 30, true)
				EnableControlAction(0, 31, true)
			end
		else
			if invBusy then
				DisableControlAction(0, 23, true)
				DisableControlAction(0, 36, true)
			end

			if usingItem or invOpen or IsPedCuffed(playerPed) then
				DisablePlayerFiring(playerId, true)
			end

			if not EnableWeaponWheel then
				HudWeaponWheelIgnoreSelection()
				DisableControlAction(0, 37, true)
			end

			if currentWeapon and currentWeapon.timer then
				DisableControlAction(0, 80, true)
				DisableControlAction(0, 140, true)

				if currentWeapon.metadata.durability <= 0 or not currentWeapon.timer then
					DisablePlayerFiring(playerId, true)
				elseif client.aimedfiring and not currentWeapon.melee and currentWeapon.group ~= `GROUP_PETROLCAN` and not IsPlayerFreeAiming(playerId) then
					DisablePlayerFiring(playerId, true)
				end

				local weaponAmmo = currentWeapon.metadata.ammo

				if not invBusy and currentWeapon.timer ~= 0 and currentWeapon.timer < GetGameTimer() then
					currentWeapon.timer = 0

					if weaponAmmo then
						TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', weaponAmmo)

						if client.autoreload and currentWeapon.ammo and GetAmmoInPedWeapon(playerPed, currentWeapon.hash) == 0 then
							local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

							if slotId then
								CreateThread(function() useSlot(slotId) end)
							end
						end

					elseif currentWeapon.metadata.durability then
						TriggerServerEvent('ox_inventory:updateWeapon', 'melee', currentWeapon.melee)
						currentWeapon.melee = 0
					end
				elseif weaponAmmo then
					if IsPedShooting(playerPed) then
						local currentAmmo
						local durabilityDrain = Items[currentWeapon.name].durability

						if currentWeapon.group == `GROUP_PETROLCAN` or currentWeapon.group == `GROUP_FIREEXTINGUISHER` then
							currentAmmo = weaponAmmo - durabilityDrain < 0 and 0 or weaponAmmo - durabilityDrain
							currentWeapon.metadata.durability = currentAmmo
							currentWeapon.metadata.ammo = (weaponAmmo < currentAmmo) and 0 or currentAmmo

							if currentAmmo <= 0 then
								SetPedInfiniteAmmo(playerPed, false, currentWeapon.hash)
							end
						else
							currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)

							if currentAmmo < weaponAmmo then
								currentAmmo = (weaponAmmo < currentAmmo) and 0 or currentAmmo
								currentWeapon.metadata.ammo = currentAmmo
								currentWeapon.metadata.durability = currentWeapon.metadata.durability - (durabilityDrain * math.abs((weaponAmmo or 0.1) - currentAmmo))
							end
						end

						if currentAmmo <= 0 then
							if cache.vehicle then
								TaskSwapWeapon(playerPed, true)
							end

							currentWeapon.timer = GetGameTimer() + 200
						else currentWeapon.timer = GetGameTimer() + (GetWeaponTimeBetweenShots(currentWeapon.hash) * 1000) + 100 end
					end
				elseif currentWeapon.throwable then
					if not invBusy and IsControlPressed(0, 24) then
						invBusy = 1

						CreateThread(function()
							local weapon = currentWeapon

							while currentWeapon and (not IsPedWeaponReadyToShoot(cache.ped) or IsDisabledControlPressed(0, 24)) and GetSelectedPedWeapon(playerPed) == weapon.hash do
								Wait(0)
							end

							if GetSelectedPedWeapon(playerPed) == weapon.hash then Wait(700) end

							while IsPedPlantingBomb(playerPed) do Wait(0) end

							TriggerServerEvent('ox_inventory:updateWeapon', 'throw', nil, weapon.slot)
							plyState:set('invBusy', false, true)

							currentWeapon = nil

							RemoveWeaponFromPed(playerPed, weapon.hash)
							TriggerEvent('ox_inventory:currentWeapon')
						end)
					end
				elseif currentWeapon.melee and IsControlJustReleased(0, 24) and IsPedPerformingMeleeAction(playerPed) then
					currentWeapon.melee += 1
					currentWeapon.timer = GetGameTimer() + 200
				end
			end
		end
	end)

	plyState:set('invBusy', false, true)
	plyState:set('invOpen', false, false)
	plyState:set('invHotkeys', true, false)
	plyState:set('canUseWeapons', true, false)
	collectgarbage('collect')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if shared.resource == resourceName then
		client.onLogout()
	end
end)

RegisterNetEvent('ox_inventory:viewInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
    currentInventory.type = 'inspect'
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	if Utility.enabled then
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory then
			if currentInventory.items and right and (right.type == 'player' or right.type == 'otherplayer') then
				currentInventory.utility = Utility.collect(currentInventory.items)
			else
				currentInventory.utility = nil
			end
		end
	end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})
end)

RegisterNUICallback('uiLoaded', function(_, cb)
	client.uiLoaded = true
	cb(1)
end)

RegisterNUICallback('getItemData', function(itemName, cb)
	cb(Items[itemName])
end)

RegisterNUICallback('inspectWeapon', function(data, cb)
	local slot = data.slot
	local item = PlayerData.inventory[slot]

	if not item or not Items[item.name] or not Items[item.name].weapon then
		return cb(false)
	end

	local hash = Items[item.name].hash
	if not hash then return cb(false) end

	local compatibleTypes = {}
	local seen = {}
	for compName, compData in pairs(Items) do
		if compData.component and compData.type and compData.client and compData.client.component then
			for _, compHash in ipairs(compData.client.component) do
				if DoesWeaponTakeWeaponComponent(hash, compHash) then
					if not seen[compData.type] then
						seen[compData.type] = true
						compatibleTypes[#compatibleTypes + 1] = compData.type
					end
					break
				end
			end
		end
	end

	cb({ compatibleTypes = compatibleTypes })
end)

RegisterNUICallback('weaponInspect_addComponent', function(data, cb)
	cb(1)

	local componentSlot = data.componentSlot
	local weaponSlot = data.weaponSlot

	if not componentSlot or not weaponSlot then return end

	local weaponItem = PlayerData.inventory[weaponSlot]
	local componentItem = PlayerData.inventory[componentSlot]

	if not weaponItem or not componentItem then return end
	if not Items[weaponItem.name] or not Items[weaponItem.name].weapon then return end
	if not Items[componentItem.name] or not Items[componentItem.name].component then return end

	local compData = Items[componentItem.name]
	if not compData.client or not compData.client.component then return end

	local hash = Items[weaponItem.name].hash
	if not hash then return end

	local weaponComponents = weaponItem.metadata and weaponItem.metadata.components or {}
	for _, attachedComp in ipairs(weaponComponents) do
		if Items[attachedComp] and Items[attachedComp].type == compData.type then
			return lib.notify({ id = 'weapon_comp_occupied', type = 'error', description = locale('component_slot_occupied', compData.type) })
		end
	end

	local compatible = false
	for _, compHash in ipairs(compData.client.component) do
		if DoesWeaponTakeWeaponComponent(hash, compHash) then
			compatible = true
			break
		end
	end

	if not compatible then
		return lib.notify({ id = 'weapon_comp_invalid', type = 'error', description = locale('component_invalid', compData.label or componentItem.name) })
	end

	local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', tostring(componentSlot), weaponSlot)

	if success then
		if currentWeapon and currentWeapon.slot == weaponSlot then
			for _, compHash in ipairs(compData.client.component) do
				if DoesWeaponTakeWeaponComponent(hash, compHash) then
					GiveWeaponComponentToPed(playerPed, hash, compHash)
					break
				end
			end
		end
		TriggerEvent('ox_inventory:updateWeaponComponent', 'added', compData.client.component[1], componentItem.name)
	end
end)

RegisterNUICallback('removeComponent', function(data, cb)
	cb(1)

	if not currentWeapon then
		return TriggerServerEvent('ox_inventory:updateWeapon', 'component', data)
	end

	if data.slot ~= currentWeapon.slot then
		return lib.notify({ id = 'weapon_hand_wrong', type = 'error', description = locale('weapon_hand_wrong') })
	end

	local itemSlot = PlayerData.inventory[currentWeapon.slot]

    if not itemSlot then return end

	for _, component in pairs(Items[data.component].client.component) do
		if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
			for k, v in pairs(itemSlot.metadata.components) do
				if v == data.component then
					local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', {
						slot = currentWeapon.slot,
						component = data.component,
						targetSlot = data.targetSlot,
					})

					if success then
						RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, component)
						TriggerEvent('ox_inventory:updateWeaponComponent', 'removed', component, data.component)
					end

					break
				end
			end
		end
	end
end)

RegisterNUICallback('removeAmmo', function(slot, cb)
	cb(1)
	local slotData = PlayerData.inventory[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo == 0 then return end

	local success = lib.callback.await('ox_inventory:removeAmmoFromWeapon', false, slot)

	if success and slot == currentWeapon?.slot then
		SetPedAmmo(playerPed, currentWeapon.hash, 0)
	end
end)

RegisterNUICallback('useItem', function(slot, cb)
	useSlot(slot)
	cb(1)
end)

local function giveItemToTarget(serverId, slotId, count, fromInv)
	if type(slotId) ~= 'number' then return TypeError('slotId', 'number', type(slotId)) end
	if count and type(count) ~= 'number' then return TypeError('count', 'number', type(count)) end

	if slotId == currentWeapon?.slot then
		currentWeapon = Weapon.Disarm(currentWeapon)
	end

	Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)

	local notification = lib.callback.await('ox_inventory:giveItem', false, slotId, serverId, count or 0, fromInv)

	if notification then
		lib.notify({ type = 'error', description = locale(table.unpack(notification)) })
    else
        client.closeInventory()
	end
end

exports('giveItemToTarget', giveItemToTarget)

local function isGiveTargetValid(ped, coords)
    if cache.vehicle and GetVehiclePedIsIn(ped, false) == cache.vehicle then
        return true
    end

    local entity = Utils.Raycast(1|4|8|16, coords + vec3(0, 0, 0.5), 0.2)

    return entity == ped and IsEntityVisible(ped)
end

RegisterNUICallback('giveItem', function(data, cb)
	cb(1)

	local sourceInventory = type(data.inventory) == 'string' and data.inventory or nil

	local function doRollback()
		if not data.returnInventory or type(data.slot) ~= 'number' or type(data.returnSlot) ~= 'number' then return end
		lib.callback.await('ox_inventory:swapItems', false, {
			fromSlot = data.slot,
			fromType = 'player',
			fromInventory = tostring(cache.playerId),
			toSlot = data.returnSlot,
			toType = 'backpack',
			toInventory = data.returnInventory,
			count = data.returnCount or 1,
		})
	end

	local function getSourceItem()
		if sourceInventory then
			local inventory = lib.callback.await('ox_inventory:getInventory', 200, sourceInventory)
			local item = inventory and inventory.items and inventory.items[data.slot]

			if item then
				item.inventory = sourceInventory
				return item
			end
		end

		return lib.callback.await('inv:getItemFromSlot', false, data.slot)
	end

    if usingItem then doRollback() return end
    local item = getSourceItem()

	if not item then doRollback() return end

	local amount = data.count
	if amount == nil or amount == 0 then
		amount = item.count or 1
	end
    local props = Items[item.name]

    local slotId = item.slot

    if slotId == currentWeapon?.slot then
        currentWeapon = Weapon.Disarm(currentWeapon)
    end

	local isWeapon = false
	local throwProps = props
	if item and item.name then
		local weaponHash = joaat(item.name)
		if IsWeaponValid(weaponHash) then
			isWeapon = true
		elseif not item.name:find('^WEAPON_') and not item.name:find('^weapon_') then
			local altHash = joaat('WEAPON_' .. item.name:upper())
			if IsWeaponValid(altHash) then
				isWeapon = true
			end
		end
	end

	if isWeapon then
		local weaponHash = getWeaponDropHash(item.name)
		local weaponModel = weaponHash and GetWeapontypeModel(weaponHash)

		if (not weaponModel or weaponModel == 0 or not IsModelValid(weaponModel) or not IsModelInCdimage(weaponModel)) then
			weaponModel = lib.callback.await('ox_inventory:resolveModelOnClient', false, item.name)
		end

		if weaponModel and weaponModel ~= 0 and IsModelValid(weaponModel) and IsModelInCdimage(weaponModel) then
			throwProps = {}

			if type(props) == 'table' then
				for k, v in pairs(props) do
					throwProps[k] = v
				end
			end

			throwProps.modelp = weaponModel
			throwProps.prop = throwProps.prop or weaponModel
		end
	end

	if throwProps and throwProps.modelp and not throwProps.disableThrow and GetResourceState('Dm-throwitems') == 'started' then
		client.closeInventory()

			lib.showTextUI('[E] give to nearby | [N] place | [ESC] cancel', {
				position = 'bottom-center',

			})

		local entity = exports["Dm-throwitems"]:throwItem(data.slot, throwProps, amount, sourceInventory)
		local canceled = false

		while DoesEntityExist(entity) do
			DisableFrontendThisFrame()

			if IsControlJustReleased(2, 200) then
				DeleteEntity(entity)
				RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')

				lib.hideTextUI()
			  plyState:set('invBusy', false, true)
			  canceled = true

			end

			if IsControlJustReleased(0, 38) then
				DeleteEntity(entity)
				RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
				lib.hideTextUI()
				plyState:set('invBusy', false, true)

				local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
				local nearbyCount = #nearbyPlayers

				if nearbyCount == 0 then
					lib.notify({ type = 'error', description = 'No nearby players found' })
					doRollback() return
				end

				if nearbyCount == 1 then
					local option = nearbyPlayers[1]

					if not isGiveTargetValid(option.ped, option.coords) then
						lib.notify({ type = 'error', description = 'Player not in valid position' })
						doRollback() return
					end

					local item = getSourceItem()
					return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, amount, item and item.inventory)
				end

				local giveList, n = {}, 0

				for i = 1, #nearbyPlayers do
					local option = nearbyPlayers[i]

					if isGiveTargetValid(option.ped, option.coords) then
						local playerName = GetPlayerName(option.id)
						option.id = GetPlayerServerId(option.id)
						option.label = ('[%s] %s'):format(option.id, playerName)
						n += 1
						giveList[n] = option
					end
				end

				if n == 0 then
					lib.notify({ type = 'error', description = 'No valid nearby players found' })
					doRollback() return
				end

				lib.registerMenu({
					id = 'ox_inventory:givePlayerList',
					title = 'Give item',
					options = giveList,
				}, function(selected)
					local item = getSourceItem()
					giveItemToTarget(giveList[selected].id, item and item.slot or data.slot, amount, item and item.inventory)
				end)

				return lib.showMenu('ox_inventory:givePlayerList')
			end

			if IsControlJustReleased(0, 306) then
				DeleteEntity(entity)
				RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
				lib.hideTextUI()
				exports["Dm-throwitems"]:placeItem(data.slot, throwProps, amount, sourceInventory)
			end

			Wait(0)
		end

		if canceled then
			doRollback() return
		end
	end

	if client.giveplayerlist then
		local coords = cache.vehicle and GetWorldPositionOfEntityBone(playerPed, 0) or GetEntityCoords(playerPed)

		local nearbyPlayers = lib.getNearbyPlayers(coords, 3.0)
        local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then doRollback() return end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then doRollback() return end

			local item = getSourceItem()
			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, amount, item and item.inventory)
		end

        local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

            if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				option.label = ('[%s] %s'):format(option.id, playerName)
				n += 1
				giveList[n] = option
			end
		end

        if n == 0 then doRollback() return end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			local item = getSourceItem()
			giveItemToTarget(giveList[selected].id, item and item.slot or data.slot, amount, item and item.inventory)
        end)

		return lib.showMenu('ox_inventory:givePlayerList')
	end

    if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				local item = getSourceItem()
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), item and item.slot or data.slot, amount, item and item.inventory)
			end
		end

		doRollback() return
	end

    local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		local item = getSourceItem()
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot, amount, item and item.inventory)
    end

	doRollback()
end)

RegisterNUICallback('giveItemNearby', function(data, cb)
	cb(1)

	local sourceInventory = type(data.inventory) == 'string' and data.inventory or nil

	local function doRollback()
		if not data.returnInventory or type(data.slot) ~= 'number' or type(data.returnSlot) ~= 'number' then return end
		lib.callback.await('ox_inventory:swapItems', false, {
			fromSlot = data.slot,
			fromType = 'player',
			fromInventory = tostring(cache.playerId),
			toSlot = data.returnSlot,
			toType = 'backpack',
			toInventory = data.returnInventory,
			count = data.returnCount or 1,
		})
	end

	local function getSourceItem()
		if sourceInventory then
			local inventory = lib.callback.await('ox_inventory:getInventory', 200, sourceInventory)
			local item = inventory and inventory.items and inventory.items[data.slot]

			if item then
				item.inventory = sourceInventory
				return item
			end
		end

		return lib.callback.await('inv:getItemFromSlot', false, data.slot)
	end

	if usingItem then doRollback() return end

	local item = getSourceItem()

	if not item then doRollback() return end

	local amount = data.count
	if amount == nil or amount == 0 then
		amount = item.count or 1
	end

	if client.giveplayerlist then
		local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
        local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then doRollback() return end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then doRollback() return end

			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, amount, item and item.inventory)
		end

        local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

            if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				option.label = ('[%s] %s'):format(option.id, playerName)
				n += 1
				giveList[n] = option
			end
		end

        if n == 0 then doRollback() return end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			giveItemToTarget(giveList[selected].id, item and item.slot or data.slot, amount, item and item.inventory)
        end)

		return lib.showMenu('ox_inventory:givePlayerList')
	end

    if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), item and item.slot or data.slot, amount, item and item.inventory)
			end
		end

		doRollback() return
	end

    local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot, amount, item and item.inventory)
    end

	doRollback()
end)

RegisterNUICallback('useButton', function(data, cb)
	useButton(data.id, data.slot)
	cb(1)
end)

RegisterNUICallback('exit', function(_, cb)
	client.closeInventory()
	cb(1)
end)

local isDraggingItem = false

RegisterNUICallback('setItemDragging', function(data, cb)
    cb(1)
    isDraggingItem = data.dragging == true
    if not isDraggingItem then return end

    CreateThread(function()
        while isDraggingItem do
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            local players = lib.getNearbyPlayers(coords, 2.0)
            local targets = {}

            for i = 1, #players do
                local p = players[i]
                if DoesEntityExist(p.ped) then
                    local headCoords = GetPedBoneCoords(p.ped, 31086, 0, 0, 0)
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z + 0.35)
                    if onScreen then
                        targets[#targets + 1] = {
                            serverId = GetPlayerServerId(p.id),
                            name     = GetPlayerName(p.id),
                            screenX  = sx,
                            screenY  = sy,
                        }
                    end
                end
            end

            SendNUIMessage({ action = 'setPlayerDropTargets', data = targets })
            Wait(50)
        end
        SendNUIMessage({ action = 'setPlayerDropTargets', data = {} })
    end)
end)

RegisterNUICallback('dropItemOnPlayer', function(data, cb)
    cb(1)
    isDraggingItem = false
    if type(data.serverId) ~= 'number' then
        lib.notify({ type = 'error', description = locale('cannot_perform') })
        return
    end
    if type(data.slot) ~= 'number' then
        lib.notify({ type = 'error', description = locale('cannot_perform') })
        return
    end
    local fromInv = type(data.inventory) == 'string' and data.inventory or nil
    local count = (data.count and data.count > 0) and data.count or 0
    giveItemToTarget(data.serverId, data.slot, count, fromInv)
end)

RegisterNUICallback('setClothingPreview', function(data, cb)
    if Clothing.enabled then
        local enabled = type(data) == 'table' and data.enabled == true
        Clothing.setPreviewEnabled(enabled)
        
        if enabled then
            Clothing.pushAppearance()
        end
    end

    cb(1)
end)

RegisterNUICallback('setClothingPreviewTarget', function(data, cb)
    if Clothing.enabled then
        Clothing.setPreviewTarget(data)
    end

    cb(1)
end)

RegisterNUICallback('moveToClothingSlot', function(data, cb)
    if not Clothing.enabled then
        cb(false)
        return
    end

    local clothingSlot = tonumber(data?.toSlot or data?.clothingSlot)

    if clothingSlot == nil then
        cb(false)
        return
    end

    data.previous = Clothing.getCurrentVariation(clothingSlot)

    local success, response = lib.callback.await('ox_inventory:clothing:moveTo', false, data)

    if success and type(response) == 'table' and response.metadata then
        Clothing.applyItem(response.metadata)
    elseif not success and response then
        lib.notify({ type = 'error', description = locale(response) or response })
    end

    cb(success and true or false)
end)

RegisterNUICallback('moveFromClothingSlot', function(data, cb)
    if not Clothing.enabled then
        cb(false)
        return
    end

    local success, response = lib.callback.await('ox_inventory:clothing:moveFrom', false, data)

    if success and type(response) == 'table' and response.metadata then
        Clothing.removeItem(response.metadata)
    elseif not success and response then
        lib.notify({ type = 'error', description = locale(response) or response })
    end

    cb(success and true or false)
end)

RegisterNUICallback('moveToOtherClothingSlot', function(data, cb)
    if not Clothing.enabled then
        cb(false)
        return
    end

    local success, response = lib.callback.await('ox_inventory:clothing:moveToOther', false, data)

    if not success and response then
        lib.notify({ type = 'error', description = locale(response) or response })
    end

    cb(success and true or false)
end)

RegisterNUICallback('moveFromOtherClothingSlot', function(data, cb)
    if not Clothing.enabled then
        cb(false)
        return
    end

    local success, response = lib.callback.await('ox_inventory:clothing:moveFromOther', false, data)

    if not success and response then
        lib.notify({ type = 'error', description = locale(response) or response })
    end

    cb(success and true or false)
end)

RegisterNetEvent('ox_inventory:crafting:updateXp', function(newXp)
	if currentInventory and currentInventory.type == 'crafting' then
		currentInventory.crafting = currentInventory.crafting or {}
		currentInventory.crafting.xp = currentInventory.crafting.xp or { enabled = true, current = 0 }
		currentInventory.crafting.xp.current = newXp

		SendNUIMessage({
			action = 'refreshSlots',
			data = {
				craftingXp = {
					xp = newXp
				}
			}
		})
	end
end)

lib.callback.register('ox_inventory:startCrafting', function(id, recipe)
	recipe = CraftingBenches[id].items[recipe]

	return lib.progressCircle({
		label = locale('crafting_item', recipe.metadata?.label or Items[recipe.name].label),
		duration = recipe.duration or 3000,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
		},
		anim = {
			dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
			clip = 'machinic_loop_mechandplayer',
		}
	})
end)

local swapActive = false

local function prepareNewDropData(data)
	if data.toType ~= 'newdrop' then
		return true
	end

	if cache.vehicle or IsPedFalling(playerPed) then
		return false
	end

	local coords = GetEntityCoords(playerPed)

	if IsEntityInWater(playerPed) then
		local destination = vec3(coords.x, coords.y, -200)
		local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 511, cache.ped, 4)

		while true do
			Wait(0)
			local retval, hit, endCoords = GetShapeTestResult(handle)

			if retval ~= 1 then
				if not hit then
					return false
				end

				data.coords = vec3(endCoords.x, endCoords.y, endCoords.z + 1.0)
				break
			end
		end
	else
		data.coords = coords
	end

	if currentInstance then
		data.instance = currentInstance
	end

	return true
end

RegisterNUICallback('swapItems', function(data, cb)
    if swapActive or not invOpen or invBusy or usingItem then return cb(false) end

    swapActive = true

	if not prepareNewDropData(data) then
		swapActive = false
		return cb(false)
	end

	if currentWeapon and data.fromType ~= data.toType then
		if (data.fromType == 'player' and data.fromSlot == currentWeapon.slot) or (data.toType == 'player' and data.toSlot == currentWeapon.slot) then
			currentWeapon = Weapon.Disarm(currentWeapon, true)
		end
	end

	local success, response, weaponSlot = lib.callback.await('ox_inventory:swapItems', false, data)
    swapActive = false

	cb(success or false)

	if success then
        if weaponSlot and currentWeapon then
            currentWeapon.slot = weaponSlot
        end

		if response then
			updateInventory(response.items, response.weight)
		end
	elseif response then
		if type(response) == 'table' then
			SendNUIMessage({ action = 'refreshSlots', data = { items = response } })
		else
			lib.notify({ type = 'error', description = locale(response) })
		end
	end
end)

RegisterNUICallback('moveToUtilitySlot', function(data, cb)
	local success, response = lib.callback.await('ox_inventory:utility:moveTo', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('moveFromUtilitySlot', function(data, cb)
	if not prepareNewDropData(data) then
		cb(false)
		return
	end

	local success, response = lib.callback.await('ox_inventory:utility:moveFrom', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('moveFromOtherUtilitySlot', function(data, cb)
	local success, response = lib.callback.await('ox_inventory:utility:moveFromOtherUtilitySlot', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('moveToOtherUtilitySlot', function(data, cb)
	local success, response = lib.callback.await('ox_inventory:utility:moveToOtherUtilitySlot', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('contextMoveToPlayer', function(data, cb)
	if type(data) ~= 'table' or type(data.fromSlot) ~= 'number' or type(data.toSlot) ~= 'number' then
		cb({ success = false, error = 'invalid_data' })
		return
	end

	local success, response = lib.callback.await('ox_inventory:swapItems', false, data)

	if success == false then
		cb({ success = false, error = response })
	else
		cb({ success = true, slot = data.toSlot })
	end
end)

RegisterNUICallback('contextUseItem', function(data, cb)

	if type(data) ~= 'table' or type(data.slot) ~= 'number' or type(data.item) ~= 'table' or type(data.item.name) ~= 'string' then
		cb(false)
		return
	end

	local definition = Items[data.item.name]

	if not definition then
		cb(false)
		return
	end

	local metadata = data.item.metadata or {}
	if type(metadata) == 'table' and next(metadata) == nil then
		metadata = {}
	end

	local slotData = nil

	if data.inventory and data.inventory ~= 'player' then
		local inv = lib.callback.await('ox_inventory:getInventory', 200, data.inventory)

		if not inv or not inv.items then
			cb(false)
			return
		end
		for _, it in pairs(inv.items) do
			if it and it.slot == data.item.slot then
				slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
				break
			end
		end

		if not slotData then
			for _, it in pairs(inv.items) do
				if it and it.name == data.item.name and it.count == data.item.count then
					slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
					break
				end
			end
		end

		if not slotData then
			cb(false)
			return
		end
	else
		local p = PlayerData.inventory[data.slot]
		if p then
			slotData = { slot = p.slot, name = p.name, count = p.count, weight = p.weight, metadata = p.metadata or {} }
		else
			slotData = { slot = data.item.slot, name = data.item.name, count = data.item.count, weight = data.item.weight, metadata = metadata }
		end
	end

	local itemData = {}
	for k, v in pairs(definition) do
		itemData[k] = v
	end

	local effectPayload = {
		name = slotData and slotData.name or data.item.name,
		slot = slotData and slotData.slot or data.item.slot or data.slot,
		metadata = slotData and slotData.metadata or metadata
	}

	itemData.slot = effectPayload.slot
	itemData.metadata = effectPayload.metadata
	itemData.inventory = data.inventory
	itemData.slotData = slotData

	if itemData.client then
		if invOpen and itemData.close then client.closeInventory() end

		if itemData.export then
			itemData.export(itemData, effectPayload)
			cb(true)
			return
		elseif itemData.client.event then
			TriggerEvent(itemData.client.event, itemData, effectPayload)
			cb(true)
			return
		end
	end

	if itemData.effect then
		itemData:effect(effectPayload)
	else
		useItem(itemData)
	end

	cb(true)
end)

RegisterNUICallback('renameItem', function(data, cb)
	if type(data) ~= 'table' or type(data.slot) ~= 'number' or type(data.label) ~= 'string' then
		cb(false)
		return
	end
	local label = data.label:sub(1, 32)
	TriggerServerEvent('ox_inventory:renameItem', data.slot, label)
	cb(true)
end)

RegisterNUICallback('renameBackpack', function(data, cb)
	if type(data) ~= 'table' or type(data.inventoryId) ~= 'string' or type(data.label) ~= 'string' then
		cb(false)
		return
	end
	local label = data.label:sub(1, 32)
	TriggerServerEvent('ox_inventory:renameBackpack', data.inventoryId, label)
	cb(true)
end)

RegisterNUICallback('benchPermissions:close', function(_, cb)
	SetNuiFocus(false, false)
	cb(true)
end)

RegisterNUICallback('inputFocus', function(data, cb)
	SetNuiFocusKeepInput(not data.focused)
	cb(true)
end)

local function sendBenchPermissionsResponse(cb, payload, err)
	if payload then
		cb({ success = true, data = payload })
	else
		cb({ success = false, error = err })
	end
end

local function isStorageBench(benchId)
	return type(benchId) == 'string' and benchId:sub(1, 8) == 'storage:'
end

local function benchPermissionsEvent(action, benchId)
	if isStorageBench(benchId) then
		return ('ox_inventory:storage:%s'):format(action)
	end
	return ('ox_inventory:crafting:%s'):format(action)
end

RegisterNUICallback('benchPermissions:createRole', function(data, cb)
	local event = benchPermissionsEvent('createRole', data and data.benchId)
	local payload, err = lib.callback.await(event, false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:updateRole', function(data, cb)
	local event = benchPermissionsEvent('updateRole', data and data.benchId)
	local payload, err = lib.callback.await(event, false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:deleteRole', function(data, cb)
	local event = benchPermissionsEvent('deleteRole', data and data.benchId)
	local payload, err = lib.callback.await(event, false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:setMemberRole', function(data, cb)
	local event = benchPermissionsEvent('setMemberRole', data and data.benchId)
	local payload, err = lib.callback.await(event, false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:transferOwnership', function(data, cb)
	local event = benchPermissionsEvent('transferOwnership', data and data.benchId)
	local payload, err = lib.callback.await(event, false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)
RegisterNUICallback('buyItem', function(data, cb)
	local response, data, message = lib.callback.await('ox_inventory:buyItem', 1, data)

	if data then
		local playerItems = {}

		if type(data[2]) == 'table' and data[2].slot then
			playerItems[1] = { item = data[2], inventory = cache.serverId }
		elseif type(data[2]) == 'table' then
			local n = 0
			for i = 1, #data[2] do
				if data[2][i] then
					n = n + 1
					playerItems[n] = { item = data[2][i], inventory = cache.serverId }
				end
			end
		end

		if next(playerItems) then
			updateInventory(playerItems, data[4])
		end

		if data[3] then
			SendNUIMessage({
				action = 'refreshSlots',
				data = {
					items = {
						{
							item = data[3],
							inventory = 'shop'
						}
					}
				}
			})
		end
	end

	if message then
		lib.notify(message)
	end

	cb(response)
end)

RegisterNUICallback('craftItem', function(data, cb)

	cb(true)

	local id = data.benchId or currentInventory.id
	local index = data.benchIndex or currentInventory.index
	local recipeSlot = data.recipeSlot or data.fromSlot
	local toSlot = data.toSlot
	local storageId = data.storageId or (currentInventory.storage and currentInventory.storage.id)
	local count = data.count or 1

	if not id or not recipeSlot then return end

	local success, response = lib.callback.await('ox_inventory:craftItem', 200, id, index, recipeSlot, toSlot, storageId, count)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response or 'cannot_perform') })
	end
end)

RegisterNUICallback('cancelCraft', function(data, cb)
	cb(1)
	lib.callback.await('ox_inventory:cancelCraft', 200, data.benchId, data.jobIndex)
end)

lib.callback.register('ox_inventory:getVehicleData', function(netid)
	local entity = NetworkGetEntityFromNetworkId(netid)

	if entity then
		return GetEntityModel(entity), GetVehicleClass(entity)
	end
end)

local function weaponModelFromName(name)
    local w = joaat(name)
    if IsWeaponValid(w) then
        local model = GetWeapontypeModel(w)
        return model 
    end
    if not name:find('^WEAPON_') and not name:find('^weapon_') then
        local guess = 'WEAPON_' .. name:upper()
        local g = joaat(guess)
        if IsWeaponValid(g) then
            local model = GetWeapontypeModel(g)
            return model
        end
    end
    return nil
end

lib.callback.register('ox_inventory:resolveModelOnClient', function(itemNameOrProps)
	lib.print.debug('resolveModelOnClient called with:', itemNameOrProps)
	
	if type(itemNameOrProps) == 'string' then
		lib.print.debug('Processing string item name:', itemNameOrProps)
		local model = weaponModelFromName(itemNameOrProps)
		lib.print.debug('Weapon model result:', model)
		return model
	end
	
	if type(itemNameOrProps) == 'table' and itemNameOrProps.name then
		lib.print.debug('Processing table with name:', itemNameOrProps.name)
		local model = weaponModelFromName(tostring(itemNameOrProps.name))
		lib.print.debug('Weapon model result:', model)
		return model
	end
	
	if type(itemNameOrProps) == 'table' and (itemNameOrProps.modelp or itemNameOrProps.prop) then
		lib.print.debug('Processing table with modelp/prop')
		local m = itemNameOrProps.modelp or itemNameOrProps.prop
		lib.print.debug('Raw model value:', m)
		
		if type(m) == 'table' and m.modelp then 
			lib.print.debug('Using nested modelp:', m.modelp)
			return joaat(m.modelp) 
		end
		
		if m then 
			lib.print.debug('Using direct model:', m)
			return joaat(m) 
		end
	end
	
	lib.print.debug('No model resolved, returning nil')
	return nil
end)

RegisterNetEvent('ox_inventory:playGiveAnim', function()
    Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
end)

RegisterCommand('mascara', function()
    if not Clothing.enabled then return end
    if not PlayerData or not PlayerData.loaded or not PlayerData.inventory then return end
    if invBusy or usingItem or lib.progressActive() then return end

    -- Buscar si ya tenemos una máscara equipada, o una suelta en el inventario
    local equippedSlot, equippedItem
    local looseSlot, looseItem

    for slot, item in pairs(PlayerData.inventory) do
        if item and item.name == 'mask' then
            if item.metadata and item.metadata.clothingSlot ~= nil then
                equippedSlot, equippedItem = slot, item
            elseif not looseSlot then
                looseSlot, looseItem = slot, item
            end
        end
    end

    -- Si hay una equipada -> desequipar
    if equippedItem then
		CreateThread(function()
			ExecuteCommand('e maskup')
			Wait(600)
			ExecuteCommand('e c')
		end)

        local success, response = lib.callback.await('ox_inventory:clothing:moveFrom', false, {
            clothingSlot = equippedItem.metadata.clothingSlot
        })

        if success and type(response) == 'table' and response.metadata then
            Clothing.removeItem(response.metadata)
        elseif not success and response then
            lib.notify({ type = 'error', description = locale(response) or response })
        end

        return
    end

    -- Si no hay ninguna equipada, buscamos una suelta para equipar
    if not looseItem then
        return lib.notify({ type = 'error', description = 'No tienes ninguna máscara en el inventario' })
    end

    -- Encontrar el clothingSlot correspondiente a 'mask' en la config
    local maskSlotId
    local slots = Clothing.getSlots and Clothing.getSlots()

    if slots then
        for id, def in pairs(slots) do
            if def and def.itemName == 'mask' then
                maskSlotId = tonumber(id)
                break
            end
        end
    end

    if not maskSlotId then
        return lib.notify({ type = 'error', description = 'No se ha encontrado el slot de máscara en la configuración de ropa' })
    end

	CreateThread(function()
		ExecuteCommand('e maskdown')
		Wait(600)
		ExecuteCommand('e c')
	end)

    local success, response = lib.callback.await('ox_inventory:clothing:moveTo', false, {
        fromSlot = looseSlot,
        toSlot = maskSlotId,
        previous = Clothing.getCurrentVariation and Clothing.getCurrentVariation(maskSlotId) or nil
    })

    if success and type(response) == 'table' and response.metadata then
        Clothing.applyItem(response.metadata)
    elseif not success and response then
        lib.notify({ type = 'error', description = locale(response) or response })
    end
end, false)