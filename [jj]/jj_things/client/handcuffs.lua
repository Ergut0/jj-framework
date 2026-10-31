local Inventory = exports.ox_inventory
local playerState = LocalPlayer.state
local Wait = Wait
local TaskPlayAnim = TaskPlayAnim

local function cuffPlayer(ped, cuffType)
    local playerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
   
    local state = lib.callback.await('jj_things:setPlayerCuffs', 200, playerId, cuffType)

    if state == nil then return end

    playerState.invBusy = true

    FreezeEntityPosition(cache.ped, true)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    AttachEntityToEntity(cache.ped, ped, 11816, -0.07, -0.58, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)

    local dict = state ~= false and 'mp_arrest_paired' or 'mp_arresting'

    if state == false then
        lib.requestAnimDict(dict)
        TaskPlayAnim(cache.ped, dict, 'a_uncuff', 8.0, -8, 5500, 0, 0, false, false, false)
        Wait(5500)
    else
        if state then
            lib.requestAnimDict(dict)
            TaskPlayAnim(cache.ped, dict, 'cop_p2_back_right', 8.0, -8.0, 3750, 2, 0.0, false, false, false)
            Wait(3750)
        end
    end

    DetachEntity(cache.ped, true, false)
    FreezeEntityPosition(cache.ped, false)
    RemoveAnimDict(dict)

    playerState.invBusy = false
end

local IsPedCuffed = IsPedCuffed
local IsEntityAttached = IsEntityAttached

local function canUncuff(cuffType)
    if cuffType then
        local PlayerData = GetPlayerData()
        if Inventory:Search('count', 'llave_negra') > 0 or PlayerData.job and PlayerData.job.name == "police" then
            return true
        end
    end
    return false
end


local function useHandcuffs()
    local ped = cache.ped
    local idPlayer, pedPlayer, playerCoords = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.0, false)

    if not pedPlayer then return end 

    local targetSvId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(pedPlayer))
    local targetState = Player(targetSvId).state
    if IsPedCuffed(pedPlayer) or targetState.isCuffed then return end
    cuffPlayer(pedPlayer, 'handcuffs')
end

local function useUncuff()
    local ped = cache.ped
    local idPlayer, pedPlayer, playerCoords = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.0, false)

    if not pedPlayer then return end 

    local targetSvId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(pedPlayer))
    local targetState = Player(targetSvId).state

    if not canUncuff(targetState.isCuffed) and not IsPedCuffed(pedPlayer) and IsEntityAttached(pedPlayer) then return end
    cuffPlayer(pedPlayer, 'uncuff')
end

exports('useHandcuffs', useHandcuffs)
exports('useUncuff', useUncuff)


local isCuffed = playerState.isCuffed
local IsEntityPlayingAnim = IsEntityPlayingAnim
local DisablePlayerFiring = DisablePlayerFiring
local DisableControlAction = DisableControlAction

local function whileCuffed()
    local dict = 'mp_arresting'
    local requested = false
    while isCuffed ~= false do
        if not IsEntityPlayingAnim(cache.ped, dict, 'idle', 3) then
            if not requested then
                lib.requestAnimDict(dict)
                requested = true
            end
            TaskPlayAnim(cache.ped, dict, 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
        end

        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 23, true)
        DisableAllControlActions(0)

        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 3, true)
        EnableControlAction(0, 4, true)
        EnableControlAction(0, 5, true)
        EnableControlAction(0, 6, true)

        EnableControlAction(0, 21, true)

        EnableControlAction(0, 30, true)
        EnableControlAction(0, 31, true)
        EnableControlAction(0, 32, true)
        EnableControlAction(0, 33, true)
        EnableControlAction(0, 34, true)
        EnableControlAction(0, 35, true)

        EnableControlAction(0, 245, true) -- [T]
        EnableControlAction(0, 249, true)

        EnableControlAction(0, 270, true)
        EnableControlAction(0, 271, true)
        EnableControlAction(0, 272, true)
        EnableControlAction(0, 273, true)

        Wait(0)
    end

    ClearPedTasks(cache.ped)
    RemoveAnimDict(dict)
end

AddStateBagChangeHandler('isCuffed', ('player:%s'):format(cache.serverId), function(_, _, value)
    local ped = cache.ped

    SetEnableHandcuffs(ped, value)
    SetEnableBoundAnkles(ped, value)

    if isCuffed ~= value then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        FreezeEntityPosition(ped, true)

        if value ~= false then
            playerState.invBusy = true
            if value then
                lib.requestAnimDict('mp_arrest_paired')
                TaskPlayAnim(ped, 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750, 2, 0, false, false, false)
                Wait(3750)
                RemoveAnimDict('mp_arrest_paired')
            end
        else
            lib.requestAnimDict('mp_arresting')
            TaskPlayAnim(ped, 'mp_arresting', 'b_uncuff', 8.0, -8, 5500, 0, 0, false, false, false)
            Wait(5500)
            playerState.invBusy = false
        end
        FreezeEntityPosition(ped, false)
    end

    isCuffed = value

    if value then
        CreateThread(whileCuffed)
    end
end)
