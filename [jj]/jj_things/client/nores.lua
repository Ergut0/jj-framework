local warned = {}

CreateThread(function()
    
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end

    local discordid = lib.callback.await('jj_things:getDiscordID', false)

    if not warned[discordid] then
        warned[discordid] = 0
    end
  
    while true do
        local wait = 10000
        if LocalPlayer.state.isLoggedIn then
            local aspect = GetAspectRatio()
            local epsilon = 0.01
            if math.abs(aspect - 1.6) > epsilon and math.abs(aspect - 1.7777777910233) > epsilon then
                if not Config.WidescreenWhitelist[discordid] then
                    Notify('Tu resolucion no esta permitida, cambiatela o serás kickeado', 'warning', 5000)
                    warned[discordid] = warned[discordid] + 1
                    if warned[discordid] > 12 then -- 2 min
                        warned[discordid] = 0
                        TriggerServerEvent('jj_things:kickres')
                    end
                end
            end
        end
        Wait(wait)
    end
end)