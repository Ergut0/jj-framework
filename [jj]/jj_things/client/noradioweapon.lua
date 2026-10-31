-- local statusRadio = 0
-- local hasWeapon = false

-- RegisterNetEvent('pma-voice:radioActive', function(bool)
--     statusRadio = bool and 1 or 0
-- end)

-- lib.onCache('weapon', function(value, oldValue)
--     hasWeapon = value and true or false

--     CreateThread(function()
--         while hasWeapon do
--             if statusRadio == 1 then
--                 DisablePlayerFiring(PlayerId(), true)
--                 DisableControlAction(0, 25, true) -- INPUT_AIM
--                 DisableControlAction(0, 24, true) -- INPUT_ATTACK
--             end
--             Wait(1)
--         end
--     end)
-- end)

local statusRadio = 0
local hasWeapon = false

RegisterNetEvent('pma-voice:radioActive', function(bool)
    statusRadio = bool and 1 or 0
end)

RegisterNetEvent('origen_police:client:talking', function(playerId, talking)
    if playerId == GetPlayerServerId(PlayerId()) then
        statusRadio = talking and 1 or 0
    end
end)

lib.onCache('weapon', function(value, oldValue)
    hasWeapon = value and true or false

    CreateThread(function()
        while hasWeapon do
            if statusRadio == 1 then
                DisablePlayerFiring(PlayerId(), true)
                DisableControlAction(0, 25, true) -- INPUT_AIM
                DisableControlAction(0, 24, true) -- INPUT_ATTACK
            end
            Wait(1)
        end
    end)
end)
