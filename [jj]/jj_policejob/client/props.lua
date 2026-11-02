local function isPolice()
    local PlayerData = GetPlayerData()
    return PlayerData and PlayerData.job and PlayerData.job.name == 'police' or false
end

local function spawnProp(propModel)
    local success = lib.requestModel(propModel)
    if not success then
        print('Failed to load model', propModel)
        return
    end

    local playerPed = cache.ped
    local coords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    local propCoords = coords + forwardVector * 1.5
    local prop = CreateObject(propModel, propCoords.x, propCoords.y, propCoords.z, false, false, false)
    SetEntityAlpha(prop, 150, false)
    SetEntityCollision(prop, false, false)
    PlaceObjectOnGroundProperly(prop)

    local placing = true
    local placed = false

    while placing do
        Wait(0)
        local playerCoords = GetEntityCoords(playerPed)
        local newPropCoords = playerCoords + forwardVector * 1.5
        SetEntityCoords(prop, newPropCoords.x, newPropCoords.y, newPropCoords.z, false, false, false, true)
        PlaceObjectOnGroundProperly(prop)
        lib.showTextUI(
            "ㅤㅤㅤㅤㅤ**CONTROLES**ㅤㅤㅤㅤㅤ  \n [ENTER] para colocar  \n [BACKSPACE] para cancelar  \n [LEFT] para rotar a la izquierda  \n [RIGHT] para rotar a la derecha",
            {
                position = 'right-center',
                style = {
                    borderRadius = 5,
                    color = '#F8F9FA',
                },
            })

        if IsControlJustPressed(0, 191) then     -- Enter key
            placing = false
            local finalPropCoords = vector3(newPropCoords.x, newPropCoords.y, newPropCoords.z - 1)
            local heading = GetEntityHeading(prop)
            DeleteEntity(prop)
            
            local finalprop = CreateObject(propModel, finalPropCoords.x, finalPropCoords.y, finalPropCoords.z, true, true, false)
            
            local timeout = GetGameTimer() + 2000
            while not DoesEntityExist(finalprop) and GetGameTimer() < timeout do
                Wait(10)
            end
            
            if DoesEntityExist(finalprop) then
                local netId = NetworkGetNetworkIdFromEntity(finalprop)
                SetNetworkIdCanMigrate(netId, true)
                SetNetworkIdExistsOnAllMachines(netId, true)
                
                SetEntityHeading(finalprop, heading)
                PlaceObjectOnGroundProperly(finalprop)
                
                FreezeEntityPosition(finalprop, true)
                SetEntityInvincible(finalprop, true)
                SetEntityCanBeDamaged(finalprop, false)
                SetEntityProofs(finalprop, true, true, true, true, true, true, true, true)
                SetEntityCollision(finalprop, true, false) -- Colisión activa pero no física
                SetEntityHasGravity(finalprop, false)
                SetEntityAsMissionEntity(finalprop, true, true)
                
                Entity(finalprop).state:set('isPropPolice', true, true)
                
                lib.playAnim(cache.ped, "random@domestic", "pickup_low")
                placed = true
            end
        elseif IsControlJustPressed(0, 194) then -- Backspace key
            placing = false
            DeleteObject(prop)
        elseif IsControlPressed(0, 174) then -- Left arrow key
            local heading = GetEntityHeading(prop)
            SetEntityHeading(prop, heading + 1.0)
        elseif IsControlPressed(0, 175) then -- Right arrow key
            local heading = GetEntityHeading(prop)
            SetEntityHeading(prop, heading - 1.0)
        end
    end
    lib.hideTextUI()
    return placed
end

CreateThread(function()
    while not IsLoggedIn() do
        Wait(100)
    end

    local propMapping = {
        [GetHashKey("prop_mp_cone_02")] = "prop_mp_cone_02",
        [GetHashKey("prop_barrier_work05")] = "prop_barrier_work05",
        [GetHashKey("prop_parking_sign_1")] = "prop_parking_sign_1",
        [GetHashKey("prop_mp_barrier_02b")] = "prop_mp_barrier_02b",
        [GetHashKey("prop_air_conelight")] = "prop_air_conelight"
    }


    local targetModels = {}
    for hash, name in pairs(propMapping) do
        table.insert(targetModels, hash)
    end

    exports.ox_target:addModel(targetModels, {
        {
            name = 'jj_policejob:pickUpProp',
            icon = 'fas fa-hand',
            label = 'Recoger objeto',
            distance = 2.5,
            canInteract = function(entity, distance, coords, name, boneName)
                if not DoesEntityExist(entity) then return false end
                if not isPolice() then return false end
                local state = Entity(entity).state
                return state and state.isPropPolice == true
            end,
            onSelect = function(data)
                if not DoesEntityExist(data.entity) then return end
                if not isPolice() then return end

                -- El servidor valida el trabajo, borra el objeto y devuelve el item
                local netId = NetworkGetNetworkIdFromEntity(data.entity)
                lib.playAnim(cache.ped, "random@domestic", "pickup_low")
                TriggerServerEvent('jj_policejob:server:pickUpProp', netId)
            end
        }
    })
end)


exports("spawnProp", function(data, slot)
    if not isPolice() then
        lib.notify({
            title = 'Error',
            description = 'Solo la policía puede colocar este objeto',
            type = 'error'
        })
        return
    end

    local success = spawnProp(data.name)
    if success and data then exports.ox_inventory:useItem(data) end
end)
