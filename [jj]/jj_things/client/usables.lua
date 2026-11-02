-- El saldo de CP (LocalPlayer.state.cp) lo mantiene al día jj-framework


local function useMaskGas()
    SetPedComponentVariation(cache.ped, 1, 46, 0, 1)                                -- Adjusted to ensure the mask is applied correctly
    SetEntityProofs(cache.ped, false, false, false, false, false, true, true, true) -- Reaplica inmunidad
    lib.notify({
        description = 'Te has puesto la máscara de gás, tienes 7 minutos de inmunidad',
    })

    lib.timer(60000 * 7, function()
        SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false) -- Remove inmunidad
        lib.notify({
            description = 'EL efecto de la máscara de gás ha terminado',
        })
    end)
end

exports("useMaskGas", useMaskGas)


AddEventHandler('CEventShockingGunshotFired', function(resname, ped, sss)
    local weapon = GetSelectedPedWeapon(cache.ped)
    if not weapon then return end
    if not LocalPlayer.state['isLoggedIn'] then return end

    local excludedWeapons = {
        [`weapon_stungun`] = true,
        [`weapon_ball`] = true,
        [`weapon_snowball`] = true,
        [`weapon_firework`] = true,
    }

    for weaponI, _ in pairs(excludedWeapons) do
        if weapon == weaponI then
            print('Weapon excluded')
            return
        end
    end

    if LocalPlayer.state.isShooting == true then return end

    if not DoesEntityExist(ped) then return end
    if not IsPedAPlayer(ped) then return end
    if not IsPedShooting(cache.ped) then return end

    if ped == cache.ped then
        Player(cache.serverId).state:set('isShooting', true, true)
        --print('Player is shooting', LocalPlayer.state.isShooting)

        lib.timer(30 * 60000, function()
            if Player(cache.serverId).state.isShooting then
                Player(cache.serverId).state:set('isShooting', false, true)
                --print('Player stopped shooting', LocalPlayer.state.isShooting)
            end
        end, true)
    end
end)

local function useGunPowerTest()
    local PlayerData = GetPlayerData()

    if PlayerData.job and (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "sheriff") then return end

    local playerId, playerPed, playerCoords = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
    if not playerId or not playerPed or not playerCoords then
        lib.notify({
            description = 'No hay ningún jugador cerca para realizar el test.',
            type = 'error',
        })
        return
    end

    local wasShot = Player(GetPlayerServerId(playerId)).state.isShooting

    TriggerServerEvent("jj_chat:server:executeCommand", "me", "Coge el test de pólvora y se lo acerca a la persona")

    if wasShot then
        local msg = "La persona habría dado positivo en el test de polvora."
        TriggerServerEvent("jj_chat:server:executeCommand", "do", msg)
    else
        local msg = "La persona habría dado negativo en el test de polvora."
        TriggerServerEvent("jj_chat:server:executeCommand", "do", msg)
    end
end

exports("useGunPowerTest", useGunPowerTest)

local function equipParachute()
    local chute = `GADGET_PARACHUTE`
    SetPlayerParachuteTintIndex(cache.playerId, -1)
    GiveWeaponToPed(cache.ped, chute, 0, true, false)
    SetPedGadget(cache.ped, chute, true)
    LocalPlayer.state.parachute = true
end

local function unequipParachute()
    local chute = `GADGET_PARACHUTE`
    SetPlayerParachuteTintIndex(cache.playerId, -1)
    RemoveWeaponFromPed(cache.ped, chute, true, false)
    SetPedGadget(cache.ped, chute, false)
    if LocalPlayer.state.parachute then
        TriggerServerEvent('jj_things:server:removeParachute')
    end
    LocalPlayer.state.parachute = false
end

exports('equipParachute', equipParachute)

exports('useParachute', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
        if data then
            equipParachute()
            lib.requestModel(1269906701)
            CreateParachuteBagObject(cache.ped, true, true)
        end
    end)
end)

exports('unequipParachute', unequipParachute)
exports('equipParachute', equipParachute)


RegisterCommand("quitarparacaidas", function()
    unequipParachute()
end)

RegisterNetEvent('jj_things:OpenBossPoliceMenu', function()
    local job = GetPlayerData().job
    if (Config.BossStashes[job.name] and job.isBoss) or Config.JobStashes[job.name] then
        exports.ox_inventory:openInventory("stash", ("%s-boss"):format(job.name))
    end
end)


exports('useBlunt', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
        if data then
            exports["emotes"]:EmoteCommandStart("smokeweed")

            Wait(15000)

            StartScreenEffect("DrugsMichaelAliensFightIn", 0, true)
            SetTimecycleModifier("spectator5")
            SetTimecycleModifierStrength(0.5)
            ShakeGameplayCam("DRUNK_SHAKE", 0.4)
            SetPedMotionBlur(cache.ped, true)
            ClearPedTasks(cache.ped)


            Wait(15000)

            StopScreenEffect("DrugsMichaelAliensFightIn")
            ClearTimecycleModifier()
            SetTimecycleModifierStrength(0.0)
            StopGameplayCamShaking(true)
            SetPedMotionBlur(cache.ped, false)
        end
    end)
end)


exports('useMuffing', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
        if data then
            Wait(5000)
            StartScreenEffect("DrugsMichaelAliensFightIn", 0, true)
            SetTimecycleModifier("spectator5")
            SetTimecycleModifierStrength(0.5)
            ShakeGameplayCam("DRUNK_SHAKE", 0.4)
            SetPedMotionBlur(cache.ped, true)

            Wait(15000)

            StopScreenEffect("DrugsMichaelAliensFightIn")
            ClearTimecycleModifier()
            SetTimecycleModifierStrength(0.0)
            StopGameplayCamShaking(true)
            SetPedMotionBlur(cache.ped, false)
        end
    end)
end)
