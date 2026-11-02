if not lib then return end

local shopTypes = {}
local shops = {}
local createBlip = require 'modules.utils.client'.CreateBlip

for shopType, shopData in pairs(lib.load('data.shops') or {} --[[@as table<string, OxShop>]]) do
	local shop = {
		name = shopData.name,
		groups = shopData.groups or shopData.jobs,
		blip = shopData.blip,
		label = shopData.label,
        icon = shopData.icon
	}

	if shared.target then
		shop.model = shopData.model
		shop.targets = shopData.targets
	else
		shop.locations = shopData.locations
	end

	shopTypes[shopType] = shop
	local blip = shop.blip

	if blip then
		blip.name = blip.name or shop.name or shopType
	end
end

-- Un NPC creado antes de que cargue el interior queda fuera de la sala y no se dibuja al entrar
local function settleShopPed(entity, point)
	local coords = point.coords
	local timeout = GetGameTimer() + 5000

	while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < timeout and point.entity == entity do
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)
		Wait(100)
	end

	if point.entity ~= entity or not HasCollisionLoadedAroundEntity(entity) then return end

	local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)

	if interior ~= 0 then
		LoadInterior(interior)

		while not IsInteriorReady(interior) and GetGameTimer() < timeout and point.entity == entity do
			Wait(100)
		end
	end

	if point.entity ~= entity then return end

	-- Sin congelar, el juego lo coloca en la sala que le corresponde
	FreezeEntityPosition(entity, false)
	Wait(200)

	if point.entity ~= entity then return end

	SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
	SetEntityHeading(entity, point.heading or 0.0)
	FreezeEntityPosition(entity, true)

	while interior ~= 0 and point.entity == entity do
		if GetInteriorFromEntity(cache.ped) == interior and GetInteriorFromEntity(entity) ~= interior then
			ForceRoomForEntity(entity, interior, GetRoomKeyFromEntity(cache.ped))
		end

		Wait(1000)
	end
end

---@param point CPoint
local function onEnterShop(point)
	if not point.entity then
		local model = lib.requestModel(point.ped)

		if not model then return end

		local entity = CreatePed(0, model, point.coords.x, point.coords.y, point.coords.z, point.heading, false, true)

		if point.scenario then TaskStartScenarioInPlace(entity, point.scenario, 0, true) end

		SetModelAsNoLongerNeeded(model)
		FreezeEntityPosition(entity, true)
		SetEntityInvincible(entity, true)
		SetBlockingOfNonTemporaryEvents(entity, true)

		exports.ox_target:addLocalEntity(entity, {
            {
                icon = point.icon or 'fas fa-shopping-basket',
                label = point.label,
                groups = point.groups,
                onSelect = function()
                    client.openInventory('shop', { id = point.invId, type = point.type })
                end,
                iconColor = point.iconColor,
                distance = point.shopDistance or 2.0
            }
		})

		point.entity = entity
		CreateThread(function() settleShopPed(entity, point) end)
	end
end

local Utils = require 'modules.utils.client'

local function onExitShop(point)
	local entity = point.entity

	if not entity then return end

	exports.ox_target:removeLocalEntity(entity)
	Utils.DeleteEntity(entity)

	point.entity = nil
end

local function hasShopAccess(shop)
	return not shop.groups or client.hasGroup(shop.groups)
end

local function wipeShops()
	for i = 1, #shops do
		local shop = shops[i]

		if shop.zoneId then
            exports.ox_target:removeZone(shop.zoneId)
            shop.zoneId = nil
		end

		if shop.remove then
			if shop.entity then onExitShop(shop) end

			shop:remove()
		end

		if shop.blip then
			RemoveBlip(shop.blip)
		end
	end

	table.wipe(shops)
end

local function refreshShops()
	wipeShops()

	local id = 0

	for type, shop in pairs(shopTypes) do
		local blip = shop.blip
		local label = shop.label or locale('open_label', shop.name)

		if shared.target then
			if shop.model then
				if not hasShopAccess(shop) then goto skipLoop end

				exports.ox_target:removeModel(shop.model, shop.name)
				exports.ox_target:addModel(shop.model, {
                    {
                        name = shop.name,
                        icon = shop.icon or 'fas fa-shopping-basket',
                        label = label,
                        onSelect = function()
                            client.openInventory('shop', { type = type })
                        end,
                        distance = 2
                    },
				})
			elseif shop.targets then
				for i = 1, #shop.targets do
					local target = shop.targets[i]
					local shopid = ('%s-%s'):format(type, i)

					if target.ped then
						id += 1

						shops[id] = lib.points.new({
							coords = target.loc,
							heading = target.heading,
							distance = 60,
							inv = 'shop',
							invId = i,
							type = type,
							blip = blip and hasShopAccess(shop) and createBlip(blip, target.loc),
							ped = target.ped,
							scenario = target.scenario,
							label = label,
							groups = shop.groups,
							icon = shop.icon or 'fas fa-shopping-basket',
							iconColor = target.iconColor,
							onEnter = onEnterShop,
							onExit = onExitShop,
							shopDistance = target.distance,
						})
					else
						if not hasShopAccess(shop) then goto nextShop end

						id += 1

						shops[id] = {
							zoneId = Utils.CreateBoxZone(target, {
                                {
                                    name = shopid,
                                    icon = shop.icon or 'fas fa-shopping-basket',
                                    label = label,
                                    groups = shop.groups,
                                    onSelect = function()
                                        client.openInventory('shop', { id = i, type = type })
                                    end,
                                    iconColor = target.iconColor,
                                    distance = target.distance
                                }
                            }),
							blip = blip and createBlip(blip, target.coords)
						}
					end

					::nextShop::
				end
			end
		elseif shop.locations then
			if not hasShopAccess(shop) then goto skipLoop end
            local shopPrompt = { icon = 'fas fa-shopping-basket' }

			for i = 1, #shop.locations do
				local coords = shop.locations[i]
				id += 1

				shops[id] = lib.points.new(coords, 16, {
					coords = coords,
					distance = 16,
					inv = 'shop',
					invId = i,
					type = type,
                    marker = client.shopmarker,
                    prompt = {
                        options = shop.icon and { icon = shop.icon } or shopPrompt,
                        message = ('**%s**  \n%s'):format(label, locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
                    },
					nearby = Utils.nearbyMarker,
					blip = blip and createBlip(blip, coords)
				})
			end
		end

		::skipLoop::
	end
end

-- Para comprobar en el juego los NPC de las tiendas cercanas: el resultado sale en F8
RegisterCommand('tiendadebug', function()
	local playerCoords = GetEntityCoords(cache.ped)
	local found = 0

	for i = 1, #shops do
		local shop = shops[i]

		if shop.ped and #(playerCoords - shop.coords) < 100.0 then
			found += 1

			local entity = shop.entity
			local exists = entity and DoesEntityExist(entity)
			print(('[tiendadebug] %s #%s %s | distancia %.1f | existe %s | visible %s | movido %.1f | interior NPC %s, punto %s, jugador %s'):format(
				shop.type, shop.invId, shop.ped, #(playerCoords - shop.coords), tostring(exists),
				tostring(exists and IsEntityVisible(entity)),
				exists and #(GetEntityCoords(entity) - shop.coords) or -1.0,
				exists and GetInteriorFromEntity(entity) or 0,
				GetInteriorAtCoords(shop.coords.x, shop.coords.y, shop.coords.z),
				GetInteriorFromEntity(cache.ped)
			))
		end
	end

	print(('[tiendadebug] target %s | puntos %d | cerca %d'):format(tostring(shared.target), #shops, found))
end, false)

return {
	refreshShops = refreshShops,
	wipeShops = wipeShops,
}
