
RegisterNetEvent('consumables:client:UseArmor', function()
    if GetPedArmour(PlayerPedId()) >= 75 then
        Notify('You already have enough armor on!')
        return
    end
    if lib.progressCircle({
            duration = 5000,
            position = "bottom",
            label = "Poniendose el chaleco",
            useWhileDead = false,
            canCancel = true,
        }) then
        local armor = exports.ox_inventory:Search("count", "armor")
        if armor >= 1 then
            TriggerServerEvent("consumables:server:useArmor")
            SetPedArmour(PlayerPedId(), 35)
        end
    end
end)

RegisterNetEvent('consumables:client:UseHeavyArmor', function()
    if GetPedArmour(PlayerPedId()) == 100 then
        Notify('You already have enough armor on!')
        return
    end
    local ped = PlayerPedId()
    if lib.progressCircle({
            duration = 5000,
            position = "bottom",
            label = "Poniendose el chaleco",
            useWhileDead = false,
            canCancel = true,
        }) then
        local armor = exports.ox_inventory:Search("count", "heavyarmor")
        if armor >= 1 then
            TriggerServerEvent("consumables:server:useHeavyArmor")
            SetPedArmour(ped, 100)
        end
    end
end)

RegisterCommand("dchaleco", function(source)
    TriggerEvent("consumables:client:ResetArmor")
end)

RegisterNetEvent('consumables:client:ResetArmor', function()
    local ped = PlayerPedId()
    local armadura = GetPedArmour(ped)
    if armadura ~= 0 then
        if lib.progressCircle({
                duration = 5000,
                position = "bottom",
                label = "Quitandose el chaleco",
                useWhileDead = false,
                canCancel = true,
            }) then
            if armadura == 100 then
                SetPedArmour(ped, 0)
                TriggerServerEvent('consumables:server:resetArmor')
            elseif armadura == 35 then
                SetPedArmour(ped, 0)
                TriggerServerEvent('consumables:server:resetNormalArmor')
            else
                Notify("El chaleco ya ha sido usado por lo tanto no puedes quitartelo.", "error", 5000)
            end
        end
    else
        Notify("No tienes ningun chaleco equipado", "error", 5000)
    end
end)


-- exports('useBandage', function(data, slot)
-- 	local maxHealth = GetEntityMaxHealth(cache.ped)
-- 	local health = GetEntityHealth(cache.ped)
-- 	exports.ox_inventory:useItem(data, function(data)
-- 		if data then
-- 			SetEntityHealth(cache.ped, math.min(maxHealth, math.floor(health + maxHealth / 16)))
-- 			lib.notify({ description = 'Te sientes mejor..' })
-- 		end
-- 	end)
-- end)

CreateThread(function()
    exports.ox_inventory:displayMetadata({
        Name = 'Nombre Completo',
        Nation = 'Nacionalidad',
        Birthdate = 'Fecha de Nacimiento',
        Gender = 'Género',
        ID = 'ID'
    })
end)

RegisterNetEvent("detector:use", function()
    local player, distance = GetClosestPlayerToMe()

    if distance > 0 and player ~= 0 then
        TriggerServerEvent("detector:setPlayer", GetPlayerServerId(player))
    end
end)

RegisterNetEvent("detector:client:domyfinguer", function()
    local PlayerData = GetPlayerData()
    local text = ("Al cabo de unos segundos saldría el resultado: %s"):format((PlayerData.name or "") .. " (" .. (PlayerData.identifier or "") .. ")")
    --UseCommand('me', "Pone el dedo en el lector")
    ExecuteCommand("do " .. text)
end)
