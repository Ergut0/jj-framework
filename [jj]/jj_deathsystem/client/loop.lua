local damaged = false
local fatal = false 


local function setHurt()
    damaged = true
    RequestAnimSet("move_m@injured")
    SetPedMovementClipset(PlayerPedId(), "move_m@injured", true)
end

local function setFatalVitality()
    fatal = true 
    RequestAnimSet("move_m@drunk@a")
    SetPedMovementClipset(PlayerPedId(), "move_m@drunk@a", true)
end

local function setNotHurt()
    damaged = false
    fatal = false 
    ResetPedMovementClipset(PlayerPedId())
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
end

CreateThread(function ()
    while true do
        local Sleep = 2000
        local Ped = PlayerPedId()
        if GetEntityHealth(Ped) <= 149 and GetEntityHealth(Ped) >= 106 then
            setHurt()
        elseif GetEntityHealth(Ped) <= 105 then
            setFatalVitality()
        elseif damaged or fatal and GetEntityHealth(Ped) > 150 then
            setNotHurt()
        end
        Wait(Sleep)
    end
end)
