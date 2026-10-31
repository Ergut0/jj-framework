local timerDead = nil
playerState = LocalPlayer.state
local isProne = false
local isCrawling = false

local function mostrarPantallaDeMuerte(mensaje)
    SendNUIMessage({
        action = 'showDeathScreen',
        seconds = mensaje
    })
end

local function ocultarPantallaDeMuerte()
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
end

local function Crawl(playerPed, type, direction)
    isCrawling = true

    lib.playAnim(cache.ped, "move_injured_ground", "front_loop", 1.0, 1.0, -1, 1, 0, false, false, false)

    local time = {
        ["onfront"] = {
            ["fwd"] = 820,
            ["bwd"] = 990
        },
        ["onback"] = {
            ["fwd"] = 1200,
            ["bwd"] = 1200
        }
    }

    SetTimeout(time[type][direction], function()
        isCrawling = false
    end)
end

local function playDeadAnimation()
    local deadAnimDict = 'dead'
    local deadAnim = not LocalPlayer.state.isCuffed and 'dead_a' or 'dead_f'
    local deadVehAnimDict = 'veh@low@front_ps@idle_duck'
    local deadVehAnim = 'sit'

    if cache.vehicle then
        if not IsEntityPlayingAnim(cache.ped, deadVehAnimDict, deadVehAnim, 3) then
            lib.playAnim(cache.ped, deadVehAnimDict, deadVehAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    elseif not IsEntityPlayingAnim(cache.ped, deadAnimDict, deadAnim, 3) then
        lib.playAnim(cache.ped, deadAnimDict, deadAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
    end
end

local function playLastStandAnimation()
    local lastStandAnimDict = 'combat@damage@writhe'
    local lastStandAnim = not LocalPlayer.state.isCuffed and 'writhe_loop' or 'dead_f'
    local deadVehAnimDict = 'veh@low@front_ps@idle_duck'
    local deadVehAnim = 'sit'

    if cache.vehicle then
        if not IsEntityPlayingAnim(cache.ped, deadVehAnimDict, deadVehAnim, 3) then
            lib.playAnim(cache.ped, deadVehAnimDict, deadVehAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    elseif not IsEntityPlayingAnim(cache.ped, lastStandAnimDict, lastStandAnim, 3) and not isCrawling then
        lib.playAnim(cache.ped, lastStandAnimDict, lastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
    end
end

function revivePlayer(fromKey, zone, withoutResetStatus)
    local coords = GetEntityCoords(cache.ped)

    if fromKey then
        if LocalPlayer.state.checkingIn then
            TriggerServerEvent('jj_deathsystem:server:RespawnAtHospital', false, zone)
        else
            TriggerServerEvent('jj_deathsystem:server:RespawnAtHospital', true)
        end
    end

    local armour = GetPedArmour(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 0.5, GetEntityHeading(cache.ped), true, false)
    ClearPedBloodDamage(cache.ped)
    SetEveryoneIgnorePlayer(cache.playerId, false)
    SetEntityHealth(cache.ped, 200)
    SetEntityInvincible(cache.ped, false)
    playerState:set('isDead', false, true)
    playerState:set('isLastStand', false, true)
    playerState:set('checkingIn', false, false)
    playerState:set('dead', false, true)
    isProne = false
    SetPedConfigFlag(cache.ped, 48, false)
    TriggerServerEvent("jj_deathsystem:server:SetDeathStatus", false)
    ocultarPantallaDeMuerte()
    ClearPedTasks(cache.ped)
    SetPedArmour(cache.ped, armour)

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end
end

local function onPlayerDead()
    if LocalPlayer.state.inArena then return end
    playerState:set('isDead', true, true)
    playerState:set('isLastStand', false, true)
    -- El ped se resucita para animarlo: esto impide a ox_inventory abrirse o usar objetos
    playerState:set('dead', true, true)
    TriggerServerEvent("jj_deathsystem:server:SetDeathStatus", "dead")
    isProne = false
    local timeout = 1

    local coords = GetEntityCoords(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 0.5, GetEntityHeading(cache.ped), true, false)

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end

    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    SetEveryoneIgnorePlayer(cache.playerId, true)
    SetEntityInvincible(cache.ped, true)
    SetPedConfigFlag(cache.ped, 48, true)

    CreateThread(function()
        while playerState.isDead do
            if not IsHandCuffed() then
                if timeout > 0 then
                    timeout = timeout - 1
                    mostrarPantallaDeMuerte(timeout)
                    if timeout <= 0 then
                        local holdTime = 5000
                        local startTime = GetGameTimer()
                        while playerState.isDead do
                            if IsControlPressed(0, 38) then
                                if GetGameTimer() - startTime >= holdTime then
                                    revivePlayer(true)
                                    break
                                end
                            else
                                startTime = GetGameTimer()
                            end
                            Wait(0)
                        end
                    end
                end
            end
            Wait(1000)
        end
    end)

    CreateThread(function()
        while playerState.isDead do
            playDeadAnimation()
            Wait(1000)
        end
    end)

    CreateThread(function()
        while playerState.isDead do
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true) -- [T]
            EnableControlAction(0, 38, true)  -- [T]
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            Wait(1)
        end
    end)
end

local function onPlayerLastStand()
    if LocalPlayer.state.inArena then return end
    playerState:set('isLastStand', true, true)
    playerState:set('dead', true, true)
    TriggerServerEvent("jj_deathsystem:server:SetDeathStatus", "laststand")
    local timeout = 180
    isProne = true
    Wait(4000)

    local coords = GetEntityCoords(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 0.5, GetEntityHeading(cache.ped), true, false)

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end

    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    SetEveryoneIgnorePlayer(cache.playerId, true)
    SetPedConfigFlag(cache.ped, 48, true)

    CreateThread(function()
        while playerState.isLastStand do
            if not IsHandCuffed() then
                if timeout > 0 then
                    timeout = timeout - 1
                    mostrarPantallaDeMuerte(timeout)
                    if timeout <= 0 then
                        onPlayerDead()
                    end
                end
            end
            Wait(1000)
        end
    end)

    CreateThread(function()
        while playerState.isLastStand do
            playLastStandAnimation()
            Wait(1000)
        end
    end)

    CreateThread(function()
        while isProne do
            -- Handles forward/backward movement
            if not cache.vehicle then
                local forward, backwards = IsControlPressed(0, 32),
                    IsControlPressed(0, 33) -- INPUT_MOVE_UP_ONLY, INPUT_MOVE_DOWN_ONLY
                if not isCrawling then
                    if forward then         -- Forward
                        Crawl(cache.ped, "onfront", "fwd")
                    elseif backwards then   -- Back
                        Crawl(cache.ped, "onback", "bwd")
                    end
                end

                -- Moving left/right
                if IsControlPressed(0, 34) then -- INPUT_MOVE_LEFT_ONLY
                    if isCrawling then
                        local headingDiff = forward and 1.0 or -1.0
                        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + headingDiff)
                    end
                elseif IsControlPressed(0, 35) then -- INPUT_MOVE_RIGHT_ONLY
                    if isCrawling then
                        local headingDiff = backwards and 1.0 or -1.0
                        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + headingDiff)
                    end
                end

                -- Check if no movement keys are pressed
                if not (forward or backwards or IsControlPressed(0, 34) or IsControlPressed(0, 35)) then
                    if isCrawling then
                        StopAnimTask(cache.ped, "move_injured_ground", "front_loop")
                    end
                end
            end
            Wait(0)
        end
    end)

    CreateThread(function()
        while playerState.isLastStand do
            DisableAllControlActions(0)

            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 3, true)
            EnableControlAction(0, 4, true)
            EnableControlAction(0, 5, true)
            EnableControlAction(0, 6, true)
            EnableControlAction(0, 32, true)
            EnableControlAction(0, 33, true)
            EnableControlAction(0, 34, true)  -- [A]
            EnableControlAction(0, 35, true)  -- [D]
            EnableControlAction(0, 38, true)  -- [T]

            EnableControlAction(0, 245, true) -- [T]
            EnableControlAction(0, 270, true)
            EnableControlAction(0, 271, true)
            EnableControlAction(0, 272, true)
            EnableControlAction(0, 273, true)
            EnableControlAction(0, 249, true)
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            Wait(1)
        end
    end)
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event == 'CEventNetworkEntityDamage' then
        local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
        if not JJ.IsSpawned() then return end
        if LocalPlayer.state.inArena then return end
        if not IsEntityAPed(victim) or not victimDied or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId or not IsEntityDead(cache.ped) then return end
        if playerState.isDead then return end
        local attackerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))

        if not playerState.isLastStand and not LocalPlayer.state.inArena and not LocalPlayer.state.inRound then
            TriggerServerEvent('jj_deathsystem:server:sendLogLastStand', attackerId, weapon)
            onPlayerLastStand()
        else
            TriggerServerEvent('jj_deathsystem:server:sendLogDead', attackerId, weapon)
            onPlayerDead()
        end
    end
end)

RegisterNetEvent('jj_deathsystem:client:KillPlayer', function()
    SetEntityHealth(cache.ped, 0)
end)

RegisterNetEvent('jj_deathsystem:client:adminHeal', function()
    SetEntityHealth(cache.ped, 200)
    ClearPedBloodDamage(cache.ped)
end)

RegisterNetEvent('jj_deathsystem:client:revive', revivePlayer)

RegisterNetEvent('jj_deathsystem:client:revivePaintBall', function()
    local coords = GetEntityCoords(cache.ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 0.5, GetEntityHeading(cache.ped), true, false)

    ClearPedBloodDamage(cache.ped)
    SetEveryoneIgnorePlayer(cache.playerId, false)
    SetEntityHealth(cache.ped, 200)
    SetEntityInvincible(cache.ped, false)
    playerState:set('isDead', false, true)
    playerState:set('isLastStand', false, true)
    playerState:set('checkingIn', false, false)
    playerState:set('dead', false, true)
    isProne = false
    SetPedConfigFlag(cache.ped, 48, false)
    TriggerServerEvent("jj_deathsystem:server:SetDeathStatus", false)
    ocultarPantallaDeMuerte()
    ClearPedTasks(cache.ped)

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end
end)

OnPlayerReady(function()
    local player = PlayerId()
    -- El modelo cambia al aparecer: se espera a que cache.ped apunte al ped definitivo
    Wait(500)
    SetEntityMaxHealth(cache.ped, 200)
    local PlayerData = JJ.GetPlayerData()
    local metadata = PlayerData and PlayerData.metadata or {}
    SetEntityHealth(cache.ped, metadata.health or 200)
    if metadata.isdead or metadata.inlaststand then
        revivePlayer(true)
    end
    SetPlayerHealthRechargeMultiplier(player, 0.0)
    SetPlayerHealthRechargeLimit(player, 0.0)
end)
