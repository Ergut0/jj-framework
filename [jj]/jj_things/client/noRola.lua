local function startLoop()
    if loopstarted then return end 
    loopstarted = true 
    CreateThread(function()
        while LocalPlayer.state.isJumping do 
            Wait(0)
            if IsPlayerFreeAiming(PlayerId()) then 
                DisableControlAction(0, 22, true)
            end
        end
    end)
    SetTimeout(20000, function()
        LocalPlayer.state.isJumping = false
        loopstarted = false 
    end)
end


CreateThread(function()
    LocalPlayer.state:set("isJumping", false, false)
    while true do
        local isAiming = IsPlayerFreeAiming(PlayerId())

        if isAiming and not LocalPlayer.state.isJumping then    
            if IsControlPressed(1, 22) then 
                LocalPlayer.state.isJumping = true 
                startLoop()
            end
        end
        Wait(0)
    end
end)