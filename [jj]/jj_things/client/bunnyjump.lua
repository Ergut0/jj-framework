local jumpCount = 0
local lastJumpTime = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local ped = PlayerPedId()

        if IsPedJumping(ped) then
            local currentTime = GetGameTimer()

            if (currentTime - lastJumpTime) < 3000 then
                jumpCount = jumpCount + 1
            else
                jumpCount = 1
            end

            lastJumpTime = currentTime

            if jumpCount >= 3 then
                ExecuteCommand('suelo')
                Wait(1000)
                ExecuteCommand('suelo')
                jumpCount = 0
            end

            while IsPedJumping(ped) do
                Citizen.Wait(0)
            end
        end
    end
end)
