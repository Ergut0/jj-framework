local playerState = LocalPlayer.state

local function escortPlayer(ped, id)
    if not id then
        id = NetworkGetPlayerIndexFromPed(ped)
    end

    local state = lib.callback.await('jj_policejob:callback:setPlayerEscort', false, GetPlayerServerId(id),
        IsEntityAttachedToEntity(ped, cache.ped))
    if state == nil then return end

    playerState.isEscorting = not playerState.isEscorting
    lib.requestAnimDict("amb@world_human_drinking@coffee@male@base")

    CreateThread(function()
        while playerState.isEscorting do
            DisableControlAction(0, 21, true) -- Disable sprint
            DisableControlAction(0, 22, true) -- Disable jump
            if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 3) then
                TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 8.0, 8.0, -1, 49,
                    false, false, false)
            end
            Wait(1)
        end

        ClearPedTasks(PlayerPedId())
    end)
end

local function isPedTargetCuffed(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    if IsPedCuffed(entity) then return true end

    local targetPlayerIndex = NetworkGetPlayerIndexFromPed(entity)
    if targetPlayerIndex and targetPlayerIndex > 0 then
        local targetSvId = GetPlayerServerId(targetPlayerIndex)
        if targetSvId and targetSvId > 0 then
            local targetState = Player(targetSvId).state
            if targetState and targetState.isCuffed then
                return true
            end
        end
    end
    return false
end

local targetsAdded = false

local function dragTarget()
    if targetsAdded then return end
    targetsAdded = true

    Target:addGlobalPlayer({
        {
            name = 'police_escort',
            icon = "fas fa-hands-bound",
            label = "Escoltar",
            --groups = 'police',
            distance = 1.5,
            canInteract = function(entity)
                if LocalPlayer.state.isDead then return false end
                local targetSvId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                local targetState = targetSvId > 0 and Player(targetSvId).state
                local isCuffed = isPedTargetCuffed(entity)
                local isDead = targetState and targetState.isDead
                return (isCuffed or isDead) and not IsEntityAttachedToEntity(entity, cache.ped)
            end,
            onSelect = function(data)
                escortPlayer(data.entity)
                local msg = "Escolta a la persona con cuidado"
                RpAction(msg)
            end
        },
        {
            name = 'police_release',
            icon = "fas fa-hands-bound",
            label = "Soltar",
            --groups = 'police',
            distance = 1.5,
            canInteract = function(entity)
                if LocalPlayer.state.isDead then return false end
                local targetSvId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                local targetState = targetSvId > 0 and Player(targetSvId).state
                local isCuffed = isPedTargetCuffed(entity)
                local isDead = targetState and targetState.isDead
                return (isCuffed or isDead) and IsEntityAttachedToEntity(entity, cache.ped)
            end,
            onSelect = function(data)
                escortPlayer(data.entity)
                local msg = "Suelta a la persona con cuidado"
                RpAction(msg)
            end
        },
    })
end

local isEscorted = false
local function setEscorted(serverId)
    local dict = 'anim@move_m@prisoner_cuffed'
    local dict2 = 'anim@move_m@trash'

    while isEscorted do
        local player = GetPlayerFromServerId(serverId)
        local targetId = GetPlayerServerId(PlayerId())
        local ped = player > 0 and GetPlayerPed(player)

        if not ped then break end

        if not IsEntityAttachedToEntity(cache.ped, ped) then
            AttachEntityToEntity(cache.ped, ped, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, true, true, 2, true)
        end

        if not Player(targetId).state.isDead then
            if IsPedWalking(ped) then
                if not IsEntityPlayingAnim(cache.ped, dict, 'walk', 3) then
                    lib.requestAnimDict(dict)
                    TaskPlayAnim(cache.ped, dict, 'walk', 8.0, -8, -1, 1, 0.0, false, false, false)
                end
            elseif IsPedRunning(ped) or IsPedSprinting(ped) then
                if not IsEntityPlayingAnim(cache.ped, dict2, 'run', 3) then
                    lib.requestAnimDict(dict2)
                    TaskPlayAnim(cache.ped, dict2, 'run', 8.0, -8, -1, 1, 0.0, false, false, false)
                end
            else
                StopAnimTask(cache.ped, dict, 'walk', -8.0)
                StopAnimTask(cache.ped, dict2, 'run', -8.0)
            end
        end
        Wait(0)
    end

    RemoveAnimDict(dict)
    RemoveAnimDict(dict2)
end

AddStateBagChangeHandler('isEscorted', ('player:%s'):format(cache.serverId), function(_, _, value)
    isEscorted = value
    if IsEntityAttached(cache.ped) then
        DetachEntity(cache.ped, true, false)
    end
    if value then setEscorted(value) end
end)


OnPlayerLoaded(function()
    dragTarget()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if IsLoggedIn() then dragTarget() end
    end
end)
