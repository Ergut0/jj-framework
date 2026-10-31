
local debugPrint = function(...) 
    if Config.Debug then 
        print("[DEBUG] ", ...) 
    end 
end

local Effect = {
    runningShake = false,
    runningAudio = false,
    runningMovement = false,
    runningScreenEffect = false,
}

local function doEffect(drunk)
    if not drunk then
        debugPrint("No drunk recibido")
        return
    end
    if drunk <= 0 then return end 

    if drunk >= 50 and not Effect.runningShake then
        ShakeGameplayCam("DRUNK_SHAKE", 1.0)
        Effect.runningShake = true
        debugPrint("El jugador ha recibido", drunk, "de alcohol y se ha aplicado un efecto de temblor en la cámara")
    elseif drunk < 50 and Effect.runningShake then
        StopGameplayCamShaking(true)
        Effect.runningShake = false
        debugPrint("El jugador ha reducido el alcohol y se ha eliminado el efecto de temblor en la cámara")
    end

    if drunk >= 60 and not Effect.runningAudio then
        StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
        Effect.runningAudio = true
        debugPrint("El jugador ha recibido", drunk, "de alcohol y se ha aplicado un efecto de sonido distorsionado")
    elseif drunk < 60 and Effect.runningAudio then
        StopAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
        Effect.runningAudio = false
        debugPrint("El jugador ha reducido el alcohol y se ha eliminado el efecto de sonido distorsionado")
    end

    if drunk >= 80 and not Effect.runningMovement then
        SetPedMoveRateOverride(PlayerPedId(), 0.8)
        lib.requestAnimSet("move_m@drunk@verydrunk")
        SetPedMovementClipset(PlayerPedId(), "move_m@drunk@verydrunk", 1.0)
        Effect.runningMovement = true
        debugPrint("El jugador ha recibido", drunk, "de alcohol y se ha aplicado un efecto de movimiento lento y descoordinado")
    elseif drunk < 80 and Effect.runningMovement then
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
        ResetPedMovementClipset(PlayerPedId(), 0.0)
        Effect.runningMovement = false
        debugPrint("El jugador ha reducido el alcohol y se ha eliminado el efecto de movimiento lento y descoordinado")
    end

    if drunk >= 70 and not Effect.runningScreenEffect then
        StartScreenEffect("DrugsMichaelAliensFight", 0, true)
        Effect.runningScreenEffect = true
        debugPrint("El jugador ha recibido", drunk, "de alcohol y se ha aplicado un efecto visual en la pantalla")
    elseif drunk < 70 and Effect.runningScreenEffect then
        StopScreenEffect("DrugsMichaelAliensFight")
        Effect.runningScreenEffect = false
        debugPrint("El jugador ha reducido el alcohol y se ha eliminado el efecto visual en la pantalla")
    end

    TriggerServerEvent("consumables:server:updateDrunk", drunk) 
end

CreateThread(function()
    while true do
        if LocalPlayer.state['isLoggedIn'] then 
            doEffect(GetPlayerData().metadata.drunk)
        end 
        Wait(3000)
    end
end)