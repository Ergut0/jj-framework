-- El efecto de estar esposado (animación, controles) lo gestiona jj_things al cambiar el estado isCuffed
local playerState = LocalPlayer.state
local targetsAdded = false

local function canUseCuffs()
    return IsOnDuty('police', 'ambulance', 'sheriff')
end

local function cuffPlayer(ped, cuffType)
    if playerState.invBusy then return end

    local playerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
    if not playerId or playerId < 1 then return end

    local isTargetDead = Player(playerId).state.isDead

    local state = lib.callback.await('jj_policejob:callback:setPlayerCuffs', false, playerId, cuffType)
    if state == nil then return end

    playerState.invBusy = true

    local finished = false
    local function finish()
        if finished then return end
        finished = true
        if IsEntityAttached(cache.ped) then DetachEntity(cache.ped, true, false) end
        FreezeEntityPosition(cache.ped, false)
        playerState.invBusy = false
    end
    -- Si la animación se corta (muerte, desconexión del objetivo), invBusy no se queda pegado
    SetTimeout(12000, finish)

    FreezeEntityPosition(cache.ped, true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)

    if isTargetDead then
        lib.requestAnimDict('amb@medic@standing@tendtodead@idle_a')
        TaskPlayAnim(cache.ped, 'amb@medic@standing@tendtodead@idle_a', 'idle_a', 8.0, -8.0, 3000, 1, 0.0, false, false, false)
        Wait(3000)
        ClearPedTasks(cache.ped)
        RemoveAnimDict('amb@medic@standing@tendtodead@idle_a')
    else
        AttachEntityToEntity(cache.ped, ped, 11816, -0.07, -0.58, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

        local dict = state ~= false and 'mp_arrest_paired' or 'mp_arresting'
        lib.requestAnimDict(dict)

        if state == false then
            TaskPlayAnim(cache.ped, dict, 'a_uncuff', 8.0, -8, 5500, 0, 0, false, false, false)
            Wait(5500)
        else
            TaskPlayAnim(cache.ped, dict, 'cop_p2_back_right', 8.0, -8.0, 3750, 2, 0.0, false, false, false)
            Wait(3750)
        end

        RemoveAnimDict(dict)
    end

    finish()
end

local function isPedTargetCuffed(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    if IsPedCuffed(entity) then return true end

    local index = NetworkGetPlayerIndexFromPed(entity)
    if index and index ~= -1 then
        local state = Player(GetPlayerServerId(index)).state
        return state and state.isCuffed == true
    end

    return false
end

local function jailOptions()
    local options = {}
    for name, station in pairs(Config.points) do
        if station.leaveJail then
            options[#options + 1] = { label = name, value = name }
        end
    end
    return options
end

local function handCuffTarget()
    if targetsAdded then return end
    targetsAdded = true

    Target:addGlobalPlayer({
        {
            name = 'police_cuff',
            icon = 'fas fa-handcuffs',
            label = 'Esposar',
            distance = 1.5,
            canInteract = function(entity)
                return canUseCuffs() and not playerState.invBusy and not isPedTargetCuffed(entity)
            end,
            onSelect = function(data)
                cuffPlayer(data.entity, 'handcuffs')
                RpAction('Esposa a la persona con cuidado')
            end,
        },
        {
            name = 'uncuff',
            icon = 'fas fa-handcuffs',
            label = 'Desesposar',
            distance = 1.5,
            canInteract = function(entity)
                return canUseCuffs() and not playerState.invBusy and not playerState.isDead and
                    isPedTargetCuffed(entity) and not IsEntityAttachedToEntity(entity, cache.ped)
            end,
            onSelect = function(data)
                cuffPlayer(data.entity, 'uncuff')
                RpAction('Desesposa a la persona con cuidado')
            end,
        },
        {
            name = 'police_jail',
            icon = 'fas fa-handcuffs',
            label = 'Encarcelar',
            distance = 1.5,
            canInteract = function(entity)
                return IsOnDuty('police', 'sheriff') and isPedTargetCuffed(entity)
            end,
            onSelect = function(data)
                local input = lib.inputDialog('Encarcelar jugador', {
                    { type = 'number', label = 'Duración de la condena (minutos)', required = true, min = 1, max = Config.MaxJailMinutes },
                    { type = 'select', label = 'Comisaría', required = true, options = jailOptions() },
                })
                if not input then return end

                local index = NetworkGetPlayerIndexFromPed(data.entity)
                TriggerServerEvent('jj_policejob:server:jail', GetPlayerServerId(index), input[1], input[2])
            end,
        },
    })
end

OnPlayerLoaded(function()
    handCuffTarget()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and IsLoggedIn() then
        handCuffTarget()
    end
end)
