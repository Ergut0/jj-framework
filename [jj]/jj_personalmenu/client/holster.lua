local Weapons = {}
local OtherPlayersWeapons = {}
local componentitems = {}
local menuOptions = {}
local handgunFlag = GetResourceKvpString("holster:pistol") or 'backhandgun'
local rifleFlag = GetResourceKvpString("holster:rifle") or 'assault'
local flagSelected = nil
local animWeapon = {}
local wHidden = false
local lastWeapon = nil
local holstered = true

local function GetCoords(cat)
	--for i = 1, #Config.weaponCategoryOffsets, 1 do
	--if Config.weaponCategoryOffsets[i].category == cat then
	if Config.weaponCategoryOffsets[cat] then
		
		if Config.Debug then
			print("[DEBUG]: Getting coords for category:", cat)
			print(json.encode(Config.weaponCategoryOffsets[cat], {depth = 3, indent = true}))
			print("==============================")
		end

		if GetEntityArchetypeName(cache.ped) == "mp_f_freemode_01" then
			return Config.weaponCategoryOffsets[cat].coordsFemale.bone, Config.weaponCategoryOffsets[cat].coordsFemale.x,
				Config.weaponCategoryOffsets[cat].coordsFemale.y, Config.weaponCategoryOffsets[cat].coordsFemale.z,
				Config.weaponCategoryOffsets[cat].coordsFemale.xRot, Config.weaponCategoryOffsets[cat].coordsFemale.yRot,
				Config.weaponCategoryOffsets[cat].coordsFemale.zRot
		else
			return Config.weaponCategoryOffsets[cat].coordsMale.bone, Config.weaponCategoryOffsets[cat].coordsMale.x,
				Config.weaponCategoryOffsets[cat].coordsMale.y, Config.weaponCategoryOffsets[cat].coordsMale.z,
				Config.weaponCategoryOffsets[cat].coordsMale.xRot, Config.weaponCategoryOffsets[cat].coordsMale.yRot,
				Config.weaponCategoryOffsets[cat].coordsMale.zRot
		end
		
		--return weaponCategoryOffsets[i].bone, weaponCategoryOffsets[i].x, weaponCategoryOffsets[i].y,
		--	weaponCategoryOffsets[i].z, weaponCategoryOffsets[i].xRot, weaponCategoryOffsets[i].yRot,
		--	weaponCategoryOffsets[i].zRot
	end
	--end
end

local function GetWeaponComponentsAndTint(weapon)
	local components = {}
	local hascomponents = false
	local tint = nil
	local weaponInfo = exports.ox_inventory:Search('slots', weapon)

	for _, v in pairs(weaponInfo) do
		local metadata = v.metadata
		if metadata then
			if metadata.components then
				for _, compo in pairs(metadata.components) do
					local compoItems = componentitems[compo]
					if compoItems then
						for _, info in pairs(compoItems) do
							if DoesWeaponTakeWeaponComponent(GetHashKey(weapon), info) then
								hascomponents = true
								components[#components + 1] = info
							end
						end
					end
				end
			end
			if metadata.tint then
				tint = metadata.tint
			end
		end
	end

	return hascomponents, components, tint
end

local function SetGear(weapon)
	if weapon == nil then return end
	if Weapons[weapon] ~= nil then
		print("[DEBUG] Weapon already exists in Weapons table:", weapon)
		return
	end

	local bone, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot = nil, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

	for weaponName, weaponData in pairs(Config.realWeapons) do
		if weaponName == weapon then
			local category = weaponData.category
			if category == 'handguns' or category == 'revolver' then
				flagSelected = handgunFlag
			elseif category == 'machine' or category == 'assault' or category == 'shotgun' or category == 'sniper' or category == 'heavy' then
				flagSelected = rifleFlag
			else
				flagSelected = category
			end
			bone, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot = GetCoords(flagSelected)
			break
		end
	end

	if not bone then
		--print("[ERROR] Bone not found for weapon:", weapon)
		return
	end

	local hascompo, components, tint = GetWeaponComponentsAndTint(weapon)
	local coords = GetEntityCoords(cache.ped)
	local boneIndex = GetPedBoneIndex(cache.ped, bone)

	local success, hash = pcall(function()
		return lib.requestWeaponAsset(GetHashKey(weapon), 5000, 31, 0)
	end)

	if not success or not hash or hash == 0 then
		print("[ERROR] Failed to request weapon asset for:", weapon)
		return
	end

	local weaponObj = CreateWeaponObject(GetHashKey(weapon), 0, coords.x, coords.y, coords.z, true, 1.0, 0, false, false)

	if not DoesEntityExist(weaponObj) then
		print("[ERROR] Failed to create weapon object for:", weapon)
		return
	end

	for _, component in pairs(components) do
		GiveWeaponComponentToWeaponObject(weaponObj, component)
		print("[DEBUG] Added component to weapon object:", weapon, component)
	end

	if tint then
		SetWeaponObjectTintIndex(weaponObj, tint)
	end

	SetEntityCollision(weaponObj, false, false)
	SetEntityCompletelyDisableCollision(weaponObj, true, false)
	AttachEntityToEntity(weaponObj, cache.ped, boneIndex, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot, true, false,
		false, false, 2, true)
	RemoveWeaponAsset(hash)

	Weapons[weapon:upper()] = weaponObj
	animWeapon[weapon:upper()] = flagSelected

	TriggerServerEvent('holster:server:syncWeapons', GetWeaponsDataForSync())
	if Config.Debug then
		print("[DEBUG]: Weapon successfully set:", weapon, weaponObj)
		print("==============================")
	end
end

local function RemoveGear(weapon)
	if Weapons[weapon] then
		SetEntityAsMissionEntity(Weapons[weapon], true, true)
		DeleteEntity(Weapons[weapon])
		Weapons[weapon] = nil
		TriggerServerEvent('holster:server:syncWeapons', GetWeaponsDataForSync())
	end
end

local function RemoveGears(onlyRemove)
	local saveWeapons = lib.table.deepclone(Weapons)
	for weaponName, entity in pairs(Weapons) do
		RemoveGear(weaponName)
	end
	if not onlyRemove then
		Wait(200)
		for w, e in pairs(saveWeapons) do
			SetGear(w)
		end
	end
end

exports('removeGears', RemoveGears)

local function OpenHolsterMenu()
	local myMenuOptions = {}

	for k, d in pairs(menuOptions) do
		local item = {
			label = d.menuLabel,
			icon = d.icon,
			values = d.values,
			close = d.close,
			args = d.args
		}
		myMenuOptions[#myMenuOptions + 1] = item
	end
	if Config.Debug then
		print("[DEBUG]: Holster menu options:")
		print(json.encode(myMenuOptions, { indent = true }))
		print("==============================")
	end
	lib.registerMenu({
		id = "holster_menu",
		title = "Posición de Armas",
		position = "bottom-right",
		options = myMenuOptions,
	}, function(selected, scrollIndex, args, checked)
		ExecuteCommand("holster " .. args[scrollIndex])

	end)
	lib.showMenu('holster_menu')
end

local function GetWeaponNameFromHash(hash)
	for name, _ in pairs(Config.realWeapons) do
		if GetHashKey(name) == hash then
			return name
		end
	end
	return nil
end

local function playAnimForCat(weapon, typeAnim)
	local isAniming = true
	local pos = GetEntityCoords(cache.ped)
	local rot = GetEntityHeading(cache.ped)

	local weaponName = GetWeaponNameFromHash(weapon)

	if not weaponName then return end

	local weaponCategory = animWeapon[weaponName]
	if not weaponCategory then return end

	if LocalPlayer.state.isDead then return end
	if (GetPedParachuteState(cache.ped) ~= -1 or GetPedParachuteState(cache.ped) ~= 0) and IsPedInParachuteFreeFall(cache.ped) then return end
	if IsPedInAnyVehicle(cache.ped, true) then return end
	if GetVehiclePedIsTryingToEnter(cache.ped) ~= 0 then return end

	CreateThread(function()
		while isAniming do
			DisablePlayerFiring(PlayerId(), true)
			DisableControlAction(0, 25, true) -- INPUT_AIM
			DisableControlAction(0, 24, true) -- INPUT_ATTACK
			Wait(1)
		end
	end)

	lib.requestAnimDict("rcmjosh4")
	lib.requestAnimDict("reaction@intimidation@cop@unarmed")
	lib.requestAnimDict("reaction@intimidation@1h")
	lib.requestAnimDict("combat@combat_reactions@pistol_1h_gang")
	lib.requestAnimDict("combat@combat_reactions@pistol_1h_hillbilly")
	lib.requestAnimDict("reaction@male_stand@big_variations@d")
	lib.requestAnimDict("glo@reversev2@animation")
	lib.requestAnimDict("glo@pulloutv3@animation")

	if typeAnim == "intro" then
		if weaponCategory == "backhandgun" or weaponCategory == "revolver" or weaponCategory == "assault" or weaponCategory:find("melee") or weaponCategory == "bat" then
			TaskPlayAnimAdvanced(cache.ped, "reaction@intimidation@1h", "intro", pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0,
				2000, 48, 0.325, 0, 0)
		elseif weaponCategory == "boxers" then
			TaskPlayAnimAdvanced(cache.ped, 'glo@pulloutv3@animation', 'glo@pulloutv3_clip', pos.x, pos.y, pos.z, 0, 0,
				rot,
				8.0, 3.0, 2000, 50, 0.325, 0, 0)
		elseif weaponCategory == "chesthandgun" then
			TaskPlayAnimAdvanced(cache.ped, "combat@combat_reactions@pistol_1h_gang", "0", pos.x, pos.y, pos.z, 0, 0, rot,
				8.0, 3.0, 2000, 48, 0.325, 0, 0)
		elseif weaponCategory == "leghandgun" then
			TaskPlayAnimAdvanced(cache.ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", pos.x,
				pos.y, pos.z, 0, 0, rot, 8.0, 3.0, 2000, 48, 0.325, 0, 0)
		elseif weaponCategory == "tacticalrifle" then
			TaskPlayAnimAdvanced(cache.ped, "combat@combat_reactions@pistol_1h_hillbilly", "0", pos.x, pos.y, pos.z, 0, 0,
				rot, 8.0, 3.0, 2000, 48, 0.325, 0, 0)
		else
			TaskPlayAnimAdvanced(cache.ped, "rcmjosh4", "josh_leadout_cop2", pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0,
				700,
				48, 0, 0, 0)
		end
		Citizen.Wait(1000)
		ClearPedTasks(cache.ped)
		RemoveGear(weaponName)
		if Config.Debug then
			print("[DEBUG]: Props de armas quitados")
			print("==============================")
		end
		
	elseif typeAnim == "outro" then
		if weaponCategory == "backhandgun" or weaponCategory == "revolver" or weaponCategory == "assault" or weaponCategory:find("melee") or weaponCategory == "bat" then
			TaskPlayAnimAdvanced(cache.ped, "reaction@intimidation@1h", "outro", pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0,
				2000, 48, 0.125, 0, 0)
		elseif weaponCategory == "boxers" then
			TaskPlayAnimAdvanced(cache.ped, 'glo@reversev2@animation', 'glo@reversev2_clip', pos.x, pos.y, pos.z, 0, 0,
				rot,
				8.0, 3.0, 2000, 50, 0.5, 0, 0)
		elseif weaponCategory == "chesthandgun" then
			TaskPlayAnimAdvanced(cache.ped, "combat@combat_reactions@pistol_1h_gang", "0", pos.x, pos.y, pos.z, 0, 0, rot,
				8.0, 3.0, 2000, 48, 0.125, 0, 0)
		elseif weaponCategory == "leghandgun" then
			TaskPlayAnimAdvanced(cache.ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", pos.x,
				pos.y, pos.z, 0, 0, rot, 8.0, 3.0, 2000, 48, 0.125, 0, 0)
		elseif weaponCategory == "tacticalrifle" then
			TaskPlayAnimAdvanced(cache.ped, "combat@combat_reactions@pistol_1h_gang", "0", pos.x, pos.y, pos.z, 0, 0, rot,
				8.0, 3.0, 2000, 48, 0.125, 0, 0)
		else
			TaskPlayAnimAdvanced(cache.ped, "reaction@intimidation@cop@unarmed", "outro", pos.x, pos.y, pos.z, 0, 0, rot,
				8.0, 3.0, 2000, 48, 0.125, 0, 0)
		end
		Citizen.Wait(1000)
		ClearPedTasks(cache.ped)
		SetGear(weaponName)
	end
	isAniming = false
end

exports('playAnimForCat', playAnimForCat)


function GetWeaponsDataForSync()
	local weaponsData = {}
	for weaponName, _ in pairs(Weapons) do
		local hascompo, components, tint = GetWeaponComponentsAndTint(weaponName)

		weaponsData[weaponName] = {
			category = animWeapon[weaponName],
			components = components or {},
			tint = tint
		}
	end
	return weaponsData
end

local function SetGearForOtherPlayer(ped, weapon, weaponData)
	local key = ped .. "_" .. weapon

	if OtherPlayersWeapons[key] then return end

	local category = weaponData.category
	local components = weaponData.components
	local tint = weaponData.tint

	local bone, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot = GetCoords(category)
	if not bone then return end

	local coords = GetEntityCoords(ped)
	local boneIndex = GetPedBoneIndex(ped, bone)

	local success, hash = pcall(function()
		return lib.requestWeaponAsset(GetHashKey(weapon), 5000, 31, 0)
	end)

	if not success or not hash or hash == 0 then return end

	local weaponObj = CreateWeaponObject(GetHashKey(weapon), 0, coords.x, coords.y, coords.z, true, 1.0, false)

	if not DoesEntityExist(weaponObj) then
		RemoveWeaponAsset(hash)
		return
	end

	if components and type(components) == 'table' then
		for _, component in pairs(components) do
			if type(component) == 'number' or type(component) == 'string' then
				local componentHash = type(component) == 'string' and GetHashKey(component) or component
				GiveWeaponComponentToWeaponObject(weaponObj, componentHash)
			end
		end
	end

	if tint then
		SetWeaponObjectTintIndex(weaponObj, tint)
	end

	SetEntityCollision(weaponObj, false, false)
	SetEntityAsNoLongerNeeded(weaponObj)
	SetEntityCompletelyDisableCollision(weaponObj, true, false)
	AttachEntityToEntity(weaponObj, ped, boneIndex, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot, true, false, false,
		false, 2, true)
	RemoveWeaponAsset(hash)

	OtherPlayersWeapons[key] = weaponObj
end

local function RemoveGearForOtherPlayer(ped, weapon)
	local key = ped .. "_" .. weapon
	if OtherPlayersWeapons[key] then
		SetEntityAsMissionEntity(OtherPlayersWeapons[key], true, true)
		DeleteEntity(OtherPlayersWeapons[key])
		OtherPlayersWeapons[key] = nil
	end
end

local function RemoveAllGearsForOtherPlayer(ped)
	for key, entity in pairs(OtherPlayersWeapons) do
		if key:find("^" .. ped .. "_") then
			SetEntityAsMissionEntity(entity, true, true)
			DeleteEntity(entity)
			OtherPlayersWeapons[key] = nil
			if Config.Debug then
				print("[DEBUG]: Removed weapon prop for other player:", key)
				print("==============================")
			end
		end
	end
end

local function LoadMenuOptions()
	menuOptions = Config.holsterMenuOptions
	for weaponOption, weaponData in pairs(Config.weaponCategoryOffsets) do
		if Config.holsterMenuOptions[weaponData.category] and weaponData.shownInMenu then
			table.insert(menuOptions[weaponData.category].values, weaponData.label)
			table.insert(menuOptions[weaponData.category].args, weaponOption)
		end
	end

	if Config.Debug then
		print("[DEBUG]: Loaded holster menu options:")
		print(json.encode(menuOptions, { indent = true }))
		print("==============================")
	end
	
	return menuOptions
end

AddStateBagChangeHandler('visibleWeapons', nil, function(bagName, key, value)
	if bagName == ('player:' .. GetPlayerServerId(PlayerId())) then return end

	local netId = tonumber(bagName:gsub('entity:', ''), 10)
	if not netId then return end

	local ped = NetToPed(netId)
	if not ped or not DoesEntityExist(ped) or ped == cache.ped then return end
	if Entity(ped).state.noclip then return end

	RemoveAllGearsForOtherPlayer(ped)

	if value and type(value) == 'table' then
		for weaponName, weaponData in pairs(value) do
			if weaponData.category then
				SetGearForOtherPlayer(ped, weaponName, weaponData)
			end
		end
	end
end)


lib.onCache('weapon', function(currentWeapon)
	if currentWeapon then
		playAnimForCat(currentWeapon, "intro")
		lastWeapon = currentWeapon
	else
		if lastWeapon then
			playAnimForCat(lastWeapon, "outro")
			lastWeapon = nil
		end
	end
end)

CreateThread(function()
	while not LocalPlayer.state['isLoggedIn'] do
		Citizen.Wait(1000)
	end

	Wait(2000)

	LocalPlayer.state.weaponHidden = false

	menuOptions =  LoadMenuOptions()

	local itemsdb = exports.ox_inventory:Items()
	for item, v in pairs(itemsdb) do
		if v.client and v.client.component then
			componentitems[item] = v.client.component
		end
	end

	while true do
		local itemCount = 0
		local weapons = {}
		local items = exports.ox_inventory:GetPlayerItems() or {}
		for weaponName, weaponData in pairs(Config.realWeapons) do
			for k, v in pairs(items) do
				if v.name == weaponName then
					weapons[weaponName] = true
				end
			end

			if weapons[weaponName] then
				if not Weapons[weaponName] and not wHidden and GetSelectedPedWeapon(cache.ped) ~= GetHashKey(weaponName) then
					SetGear(weaponName)
				end
			else
				if Weapons[weaponName] then
					RemoveGear(weaponName)
				end
			end
		end
		Wait(2000)
	end
end)

RegisterNetEvent('illenium-appearance:client:reloadSkin', function()
	RemoveGears(false)
	print("Skin recargada, props de armas restaurados")
end)

RegisterCommand("arma", function(source)
	local canDelete = true
	if not wHidden then
		for weaponName, entity in pairs(Weapons) do
			if not Config.realWeapons[weaponName].canHide then
				canDelete = false
			end
		end
		if not canDelete then
			Notify("No puedes esconder las armas, tienes una demasiado grande!", "error")
			return
		end
		RemoveGears(true)
		wHidden = true
		Notify("Has escondido tus armas!", "success")
		LocalPlayer.state.weaponHidden = true
		TriggerServerEvent('holster:server:syncWeapons', {})
	else
		for k, v in pairs(Config.realWeapons) do
			if exports.ox_inventory:Search('count', k) >= 1 then
				SetGear(k)
			end
		end
		Notify("Has sacado tus armas!", "success")
		wHidden = false
		LocalPlayer.state.weaponHidden = false
		TriggerServerEvent('holster:server:syncWeapons', GetWeaponsDataForSync())
	end
end)

RegisterCommand('holster', function(source, args)
	if args[1] == nil then
		OpenHolsterMenu()
	elseif args[1] == 'handguns' or args[1] == 'waisthandgun' or args[1] == 'handgunsSafariland' or args[1] == 'handgunsSafarilandF' then
		handgunFlag = args[1]
		Notify(("Has cambiado la posición de la pistola a la cadera."))
		SetResourceKvp("holster:pistol", handgunFlag)
	elseif args[1] == 'backhandgun' then
		handgunFlag = args[1]
		Notify(("Has cambiado la posición de la pistola a la espalda."))
		SetResourceKvp("holster:pistol", handgunFlag)
	elseif args[1] == 'leghandgun' or args[1] == 'hiphandgun' or args[1] == 'handguns2' or args[1] == 'leghandgunsSafariland' or args[1] == 'leghandgunsSafarilandF' then
		handgunFlag = args[1]
		Notify(("Has cambiado la posición de la pistola a la pierna."))
		SetResourceKvp("holster:pistol", handgunFlag)
	elseif args[1] == 'chesthandgun' then
		handgunFlag = args[1]
		Notify(("Has cambiado la posición de la pistola en el pecho."))
		SetResourceKvp("holster:pistol", handgunFlag)
	elseif args[1] == 'boxers' then
		handgunFlag = args[1]
		Notify(("Has cambiado la posición de la pistola a los calzoncillos."))
		SetResourceKvp("holster:pistol", handgunFlag)
	elseif args[1] == 'assault' then
		rifleFlag = args[1]
		Notify(("Has cambiado la posición de las armas largas a la espalda."))
		SetResourceKvp("holster:rifle", rifleFlag)
	elseif args[1] == 'tacticalrifle' then
		rifleFlag = args[1]
		Notify(("Has cambiado la posición de las armas largas al frente."))
		SetResourceKvp("holster:rifle", rifleFlag)
	end
	RemoveGears()
end)
