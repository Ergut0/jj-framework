
OnPlayerReady(function()
	exports.ox_inventory:displayMetadata({
		Car = 'Vehículo',
		Plate = 'Matrícula',
		Owner = 'Dueño',
		Serial = 'Serial',
	})
	TriggerServerEvent('jj_keysystem:server:removeTemporalKeys')
end)


RegisterCommand('ivehiculo', function()
	local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, true)
	if not vehicle then return end
	TriggerEvent("jj_carlock:client:onToggleVehicleLock", GetPlate(vehicle), vehicle)
end)

RegisterKeyMapping('ivehiculo', 'Interactuar con el vehiculo', 'keyboard', 'U')


RegisterNetEvent("jj_carlock:client:onToggleVehicleLock", function(plate, vehicle)
	if not vehicle then return end
	local vehPersonal = Entity(vehicle).state.vehPersonal
	if (not vehPersonal or vehPersonal ~= plate) and not Entity(vehicle).state.hasTempKey then return end
	local hasKey = lib.callback.await('jj_keysystem:checkOwnership', 2500, plate)
	if not hasKey then return end
	local vehLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
	local lockable = IsVehicleDoorDamaged(vehicle, 0) == false
	local vehID = NetworkGetNetworkIdFromEntity(vehicle)
	local doorStatus = GetVehicleDoorLockStatus(vehicle)
	local anim = "anim@mp_player_intmenu@key_fob@"
	local animDict = "fob_click"
	if lockable then
		lib.requestAnimDict(anim)
		TaskPlayAnim(cache.ped, anim, animDict, 8.0, 8.0, 800, 48, 1, false, false, false)
		if doorStatus == 1 or doorStatus == 0 then
			TriggerServerEvent('jj_keysystem:setDoors', vehID, 2)
			Entity(vehicle).state:set('locked', 2, true)
			Notify("Has cerrado el vehiculo", "success")
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
		elseif doorStatus == 2 then
			TriggerServerEvent('jj_keysystem:setDoors', vehID, 1)
			Entity(vehicle).state:set('locked', 1, true)
			Notify("Has abierto el vehiculo", "success")
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
		end
		Entity(vehicle).state:set('HotWire', 'StopNeedHotWire', true)
	else
		Notify("No puedes bloquear este vehículo la puerta esta dañada", "error")
	end
end)


exports('lockpickVehicle', function(data, slot)
	if LocalPlayer.state.insideWareImport then return end
	local playerPed  = PlayerPedId()
	local coords     = GetEntityCoords(playerPed)
	local vehicle    = lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0, true)
	if not vehicle then return end
	local vehID      = NetworkGetNetworkIdFromEntity(vehicle)
	local LoopedAnim = true

	exports.ox_inventory:useItem(data, function(data)
		if data then
			local loadAnim = lib.requestAnimDict("veh@break_in@0h@p_m_one@", 1000)

			if not loadAnim then return end

			CreateThread(function()
				while LoopedAnim do
					TaskPlayAnim(PlayerPedId(), "veh@break_in@0h@p_m_one@", "low_force_entry_ds", 3.0, 3.0, -1, 16, 0, 0,
						0, 0)
					Wait(1000)
				end
			end)

			-- 2na_lockpick es opcional: sin él se usa la prueba de habilidad de ox_lib
			local success
			if GetResourceState('2na_lockpick') == 'started' then
				success = exports["2na_lockpick"]:createGame(3, 5)
			else
				success = lib.skillCheck({ 'easy', 'easy', 'medium' }, { 'w', 'a', 's', 'd' })
			end

			Config.PoliceCall(vehicle)
			if success then
				SetVehicleFuelLevel(vehicle, 100.0)
				TriggerServerEvent('jj_keysystem:server:lockpicked', vehID)
				Entity(vehicle).state:set('locked', 1, true)
				Notify('¡Vehículo desbloqueado!', "success", 5000)
				ClearPedTasksImmediately(playerPed)
				LoopedAnim = false
			else
				ClearPedTasksImmediately(playerPed)
				LoopedAnim = false
			end
		end
	end)
end)
