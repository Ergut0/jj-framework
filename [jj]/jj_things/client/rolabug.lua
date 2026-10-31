local antiRolaBugCooldown = false

local function countMovementKeys()
    local count = 0
    if IsControlPressed(0, 33) then count = count + 1 end
    if IsControlPressed(0, 34) then count = count + 1 end
    if IsControlPressed(0, 35) then count = count + 1 end
    return count
end

local function canCheckAntiRolaBug(ped)
    if not DoesEntityExist(ped) then return false end
    if IsEntityDead(ped) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    if IsPedRagdoll(ped) then return false end
    if IsPedFalling(ped) then return false end
    if IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped) then return false end
    if IsPedClimbing(ped) then return false end
    if IsPauseMenuActive() then return false end
    return true
end

CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        local playerId = PlayerId()

        if not antiRolaBugCooldown and canCheckAntiRolaBug(ped) then
            local isAiming = IsPlayerFreeAiming(playerId) or IsAimCamActive()
            local isJumping = IsControlPressed(0, 22)
            local moveCount = countMovementKeys()

            if isAiming and isJumping and moveCount >= 3 then
                antiRolaBugCooldown = true

                SetPedToRagdoll(ped, 1200, 1200, 0, false, false, false)

                CreateThread(function()
                    local endTime = GetGameTimer() + 1200
                    while GetGameTimer() < endTime do
                        DisableControlAction(0, 22, true)
                        DisableControlAction(0, 24, true)
                        DisableControlAction(0, 25, true)
                        DisableControlAction(0, 33, true)
                        DisableControlAction(0, 32, true)
                        DisableControlAction(0, 34, true)
                        DisableControlAction(0, 35, true)
                        Wait(0)
                    end
                end)

                CreateThread(function()
                    Wait(2500)
                    antiRolaBugCooldown = false
                end)
            else
                sleep = 0
            end
        end

        Wait(sleep)
    end
end)