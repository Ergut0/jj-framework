if not math.groupdigits then
	function math.groupdigits(number, separator)
		if lib and lib.math and lib.math.groupdigits then
			return lib.math.groupdigits(number, separator)
		end
		local sep = separator or ','
		local num = tonumber(number) or 0
		local sign = num < 0 and '-' or ''
		local s = tostring(math.abs(num))
		local int, frac = s:match('^(%d+)(%.%d+)$')
		int = int or s
		local grouped = int:reverse():gsub('(%d%d%d)', '%1' .. sep):reverse():gsub('^' .. sep, '')
		if frac then grouped = grouped .. frac end
		return sign .. grouped
	end
end

if not lib then return end

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local Utility = require 'modules.utility.server'
local TriggerEventHooks = require 'modules.hooks.server'
local Shops = {}
local locations = shared.target and 'targets' or 'locations'

local function normalisePaymentMethods(properties)
	local methods = properties.paymentMethods or properties.payments or {}

	return {
		cash = methods.cash ~= false,
		bank = methods.bank ~= false,
		dirty = methods.dirty == true or methods.black_money == true or properties.allowDirtyMoney == true,
		dirtyItem = methods.dirtyItem or methods.dirtyMoneyItem or methods.blackMoneyItem or properties.dirtyMoneyItem or 'black_money',
	}
end

local function generateSerialText(length)
	local text

	repeat
		local chars = {}

		for i = 1, length do
			chars[i] = string.char(math.random(65, 90))
		end

		text = table.concat(chars)
	until text ~= 'POL' and text ~= 'EMS'

	return text
end

local function generateWeaponSerial(text)
	if text and text:len() > 3 then
		return text
	end

	return ('%s%s%s'):format(math.random(100000, 999999), text == nil and generateSerialText(3) or text, math.random(100000, 999999))
end

local function prepareShopMetadata(inv, item, metadata)
	if not item.weapon then return metadata end

	if type(metadata) ~= 'table' then metadata = {} end
	if not metadata.durability then metadata.durability = 100 end
	if not metadata.ammo and item.ammoname then metadata.ammo = 0 end
	if not metadata.components then metadata.components = {} end

	if metadata.registered ~= false and (metadata.ammo or item.name == 'WEAPON_STUNGUN') then
		local playerName = inv and inv.player and inv.player.name
		metadata.registered = type(metadata.registered) == 'string' and metadata.registered or playerName
		metadata.serial = generateWeaponSerial(metadata.serial)
	end

	return metadata
end

---@class OxShopItem
---@field slot number
---@field weight number

local function setupShopItems(id, shopType, shopName, groups)
	local shop = id and Shops[shopType][id] or Shops[shopType] --[[@as OxShop]]

	for i = 1, shop.slots do
		local slot = shop.items[i]

		if slot.grade and not groups then
			slot.grade = nil
		end

		local Item = Items(slot.name)

		if Item then
			---@type OxShopItem
			slot = {
				name = Item.name,
				slot = i,
				weight = Item.weight,
				count = slot.count,
				price = (server.randomprices and (not slot.currency or slot.currency == 'money')) and (math.ceil(slot.price * (math.random(80, 120)/100))) or slot.price or 0,
				metadata = slot.metadata,
				license = slot.license,
				currency = slot.currency,
				grade = slot.grade
			}

			if slot.metadata then
				slot.weight = Inventory.SlotWeight(Item, slot, true)
			end

			shop.items[i] = slot
		end
	end
end

---@param shopType string
---@param properties OxShop
local function registerShopType(shopType, properties)
	local shopLocations = properties[locations] or properties.locations
	local paymentMethods = normalisePaymentMethods(properties)

	if shopLocations then
		properties.paymentMethods = paymentMethods
		properties.allowDirtyMoney = paymentMethods.dirty
		Shops[shopType] = properties
	else
		Shops[shopType] = {
			label = properties.name,
			id = shopType,
			groups = properties.groups or properties.jobs,
			items = properties.inventory,
			slots = #properties.inventory,
			type = 'shop',
			hideAll = properties.hideAll,
			paymentMethods = paymentMethods,
			allowDirtyMoney = paymentMethods.dirty,
		}

		setupShopItems(nil, shopType, properties.name, properties.groups or properties.jobs)
	end
end

---@param shopType string
---@param id number
local function createShop(shopType, id)
	local shop = Shops[shopType]

	if not shop then return end

	local store = (shop[locations] or shop.locations)?[id]

	if not store then return end

	local groups = shop.groups or shop.jobs
    local coords

    if shared.target then
        if store.length then
            local z = store.loc.z + math.abs(store.minZ - store.maxZ) / 2
            coords = vec3(store.loc.x, store.loc.y, z)
        else
            coords = store.coords or store.loc
        end
    else
        coords = store
    end

	shop[id] = {
		label = shop.name,
		id = shopType..' '..id,
		groups = groups,
		items = table.clone(shop.inventory),
		slots = #shop.inventory,
		type = 'shop',
		paymentMethods = shop.paymentMethods or normalisePaymentMethods(shop),
		allowDirtyMoney = (shop.paymentMethods and shop.paymentMethods.dirty) == true or shop.allowDirtyMoney == true,
		coords = coords,
		distance = shared.target and shop.targets?[id]?.distance,
		hideAll = shop.hideAll,
	}

	setupShopItems(id, shopType, shop.name, groups)

	return shop[id]
end

for shopType, shopDetails in pairs(lib.load('data.shops') or {}) do
	registerShopType(shopType, shopDetails)
end

---@param shopType string
---@param shopDetails OxShop
exports('RegisterShop', function(shopType, shopDetails)
	registerShopType(shopType, shopDetails)
end)

lib.callback.register('ox_inventory:openShop', function(source, data)
	local left, shop = Inventory(source)

	if not left then return end

	if data then
		shop = Shops[data.type]

		if not shop then return end

		if not shop.items then
			shop = (data.id and shop[data.id] or createShop(data.type, data.id))

			if not shop then return end
		end

		---@cast shop OxShop

		if shop.groups then
			local group = server.hasGroup(left, shop.groups)
			if not group then return end
		end

		if type(shop.coords) == 'vector3' and #(GetEntityCoords(GetPlayerPed(source)) - shop.coords) > 10 then
			return
		end

		local shopType, shopId = shop.id:match('^(.-) (%d+)$')
		shopType = shopType or shop.id

		local hooks <close> = TriggerEventHooks('openShop', {
			source = source,
			shopId = shopId,
			shopType = shopType,
			label = shop.label,
			slots = shop.slots,
			items = shop.items,
			groups = shop.groups,
			coords = shop.coords,
			distance = shop.distance,
			paymentMethods = shop.paymentMethods or normalisePaymentMethods(shop),
			allowDirtyMoney = shop.allowDirtyMoney == true,
		})

		if not hooks.success then return end

		---@diagnostic disable-next-line: assign-type-mismatch
		left:openInventory(left)
		left.currentShop = shop.id
	end

	local leftPayload = {
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight
	}

	if Utility.getBackpackPayload then
		local backpackPayload = Utility.getBackpackPayload(source)

		if backpackPayload then
			leftPayload.backpack = backpackPayload.backpack
			leftPayload.utilitySlot = backpackPayload.utilitySlot
		end
	end

	return leftPayload, shop
end)

local normaliseCurrency = server.normaliseCurrency or function(currency)
	if type(currency) == 'string' then
		currency = currency:lower()
	else
		currency = 'money'
	end

	if currency == 'cash' then
		return 'money'
	end

	return currency
end

local function formatCurrencyLabel(currency, price)
	if server.formatCurrencyLabel then
		return server.formatCurrencyLabel(currency, price)
	end

	local normalised = normaliseCurrency(currency)

	if normalised == 'money' then
		return ('%s%s'):format(locale('$'), math.groupdigits(price))
	end

	if normalised == 'bank' then
		return ('%s %s'):format(math.groupdigits(price), locale('bank_account') or 'Bank')
	end

	local item = Items(normalised)
	local label = item and item.label or currency
	return ('%s %s'):format(math.groupdigits(price), label)
end

local function currencyParts(currency, price)
	local normalised = normaliseCurrency(currency)

	if normalised == 'money' then
		return locale('$'), math.groupdigits(price)
	end

	if normalised == 'bank' then
		return math.groupdigits(price), ' ' .. (locale('bank_account') or 'Bank')
	end

	local item = Items(normalised)
	local label = item and item.label or currency
	return math.groupdigits(price), ' ' .. label
end

local function canAffordItem(inv, currency, price)
	local balance

	if server.getCurrencyBalance then
		balance = server.getCurrencyBalance(inv, currency)
	else
		balance = Inventory.GetItemCount(inv, normaliseCurrency(currency))
	end

	local canAfford = price >= 0 and balance >= price

	if canAfford then
		return true
	end

	return {
		type = 'error',
		description = locale('cannot_afford', formatCurrencyLabel(currency, price))
	}
end

local function removeCurrency(inv, currency, price)
	if server.removeCurrency then
		return server.removeCurrency(inv, currency, price, 'ox_inventory:shop_purchase')
	end

	return Inventory.RemoveItem(inv, normaliseCurrency(currency), price)
end

local function isRequiredGrade(grade, rank)
	if type(grade) == "table" then
		for i=1, #grade do
			if grade[i] == rank then
				return true
			end
		end
		return false
	else
		return rank >= grade
	end
end

lib.callback.register('ox_inventory:buyItem', function(source, data)
	if data.toType == 'player' then
		if data.count == nil then data.count = 1 end

		local playerInv = Inventory(source)

		if not playerInv or not playerInv.currentShop then return end

		local shopType, shopId = playerInv.currentShop:match('^(.-) (%d-)$')

		if not shopType then shopType = playerInv.currentShop end

		if shopId then shopId = tonumber(shopId) end

		local shop = shopId and Shops[shopType][shopId] or Shops[shopType]
		local fromData = shop.items[data.fromSlot]
		local toData = playerInv.items[data.toSlot]

		if fromData then
			if fromData.count then
				if fromData.count == 0 then
					return false, false, { type = 'error', description = locale('shop_nostock') }
				elseif data.count > fromData.count then
					data.count = fromData.count
				end
			end

			if fromData.license and server.hasLicense and not server.hasLicense(playerInv, fromData.license) then
				return false, false, { type = 'error', description = locale('item_unlicensed') }
			end

			if fromData.grade then
				local _, rank = server.hasGroup(playerInv, shop.groups)
				if not isRequiredGrade(fromData.grade, rank) then
					return false, false, { type = 'error', description = locale('stash_lowgrade') }
				end
			end

			local paymentMethod = type(data.payment) == 'string' and data.payment:lower() or nil
			local currency = fromData.currency or 'money'
			local paymentMethods = shop.paymentMethods or normalisePaymentMethods(shop)
			local requestedPayment = paymentMethod or 'cash'

			if requestedPayment == 'black_money' then requestedPayment = 'dirty' end

			if requestedPayment == 'cash' and paymentMethods.cash == false then
				return false, false, { type = 'error', description = 'Cash payments are not accepted here' }
			elseif requestedPayment == 'bank' and paymentMethods.bank == false then
				return false, false, { type = 'error', description = 'Bank payments are not accepted here' }
			elseif requestedPayment == 'dirty' and paymentMethods.dirty == false then
				return false, false, { type = 'error', description = 'Dirty money payments are not accepted here' }
			elseif requestedPayment ~= 'cash' and requestedPayment ~= 'bank' and requestedPayment ~= 'dirty' then
				return false, false, { type = 'error', description = 'This payment method is not accepted here' }
			end

			if requestedPayment == 'bank' then
				if currency == 'money' or currency == 'cash' then
					currency = 'bank'
				end
			elseif requestedPayment == 'dirty' then
				if currency == 'money' or currency == 'cash' then
					currency = paymentMethods.dirtyItem or 'black_money'
				end
			elseif requestedPayment == 'cash' then
				if currency == 'cash' then
					currency = 'money'
				end
			end

			local fromItem = Items(fromData.name)

			local result = fromItem.cb and fromItem.cb('buying', fromItem, playerInv, data.fromSlot, shop)
			if result == false then return false end

			local toItem = toData and Items(toData.name)

				local requestedCount = data.count
				local templateMetadata = prepareShopMetadata(playerInv, fromItem, fromData.metadata and table.clone(fromData.metadata) or {})
				local pricePerUnit = fromData.price or 0

				local canCarry = Inventory.CanCarryItem(playerInv, fromItem, requestedCount, templateMetadata)

				if not canCarry then
					return false, false, { type = 'error', description = locale('cannot_carry') }
				end

			local function findAvailableSlot(inv, item, meta)
				for i = 1, inv.slots do
					local s = inv.items[i]
					if s == nil then
						return i
					end

					if s.name == item.name and item.stack and table.matches(s.metadata or {}, meta or {}) then
						return i
					end
				end

				return nil
			end

			local targetSlot = data.toSlot
			local targetData = toData

			local canUseTarget = (targetData == nil) or (fromItem.name == toItem?.name and fromItem.stack and table.matches(targetData.metadata or {}, templateMetadata or {}))

			if not canUseTarget then
				local found = findAvailableSlot(playerInv, fromItem, templateMetadata)

				if not found then
					return false, false, { type = 'error', description = locale('unable_stack_items') }
				end

				if fromItem.stack or requestedCount == 1 then
					data.toSlot = found
					targetSlot = found
					targetData = playerInv.items[found]
				else
					data.toSlot = nil
					targetSlot = nil
					targetData = nil
				end
			end

			if targetData == nil and not fromItem.stack and requestedCount > 1 then
				data.toSlot = nil
				targetSlot = nil
				targetData = nil
			end

			local canCarry2 = Inventory.CanCarryItem(playerInv, fromItem, requestedCount, templateMetadata)

			if not canCarry2 then
				return false, false, { type = 'error', description = locale('cannot_carry') }
			end

			local estimatedTotal = (pricePerUnit or 0) * requestedCount
			local canAfford = canAffordItem(playerInv, currency, estimatedTotal)

			if canAfford ~= true then
				return false, false, canAfford
			end

			local hooks <close> = TriggerEventHooks('buyItem', {
				source = source,
				shopType = shopType,
				shopId = shopId,
				toInventory = playerInv.id,
				toSlot = data.toSlot,
					fromSlot = fromData,
					itemName = fromData.name,
					itemLabel = fromItem.label,
					metadata = templateMetadata,
					count = requestedCount,
					price = pricePerUnit,
					totalPrice = pricePerUnit * requestedCount,
				currency = currency,
			})

			if not hooks.success then return false end

			if server.loglevel > 0 then
				local _, _, emptySlots = Inventory.GetItemSlots(playerInv, fromItem, templateMetadata, false)
			end

				if server.loglevel > 1 then
					local _, _, emptySlots = Inventory.GetItemSlots(playerInv, fromItem, templateMetadata, false)
				end

				local ok, resp = Inventory.AddItem(playerInv, fromItem.name, requestedCount, templateMetadata, data.toSlot)

			if server.loglevel > 0 then
			end

			if not ok then

				local err = type(resp) == 'string' and resp or 'unable_stack_items'
				return false, false, { type = 'error', description = locale(err) }
			end

				local added = requestedCount

				local totalPrice = (pricePerUnit or 0) * added

				local txnId = ('%s-%d-%d'):format(tostring(playerInv.id), os.time(), math.random(1000, 9999))
				if server.loglevel > 0 then
				end

				local deducted = removeCurrency(playerInv, currency, totalPrice)
				if server.loglevel > 0 then
				end

			if fromData.count then
				shop.items[data.fromSlot].count = fromData.count - added
			end

			if server.syncInventory then server.syncInventory(playerInv) end

			local part1, part2 = currencyParts(currency, totalPrice)
			local message = locale('purchased_for', added, templateMetadata?.label or fromItem.label, part1, part2)

			if server.loglevel > 0 then
				if server.loglevel > 1 or fromData.price >= 500 then
					lib.logger(playerInv.owner, 'buyItem', ('"%s" %s'):format(playerInv.label, message:lower()), ('shop:%s'):format(shop.label))
				end
			end

			return true, {resp, shop.items[data.fromSlot].count and shop.items[data.fromSlot], playerInv.weight}, { type = 'success', description = message }
		end
	end
end)

server.shops = Shops
