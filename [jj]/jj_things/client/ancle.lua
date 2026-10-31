ancle = false
RegisterCommand('ancla', function()
    local v = GetVehiclePedIsIn(PlayerPedId(),false)   
    if ancle == false then
        SetBoatAnchor(v, true)
        SetBoatFrozenWhenAnchored(v, true)
        Notify("¡Has anclado tu barco!")
        ancle = true
    elseif ancle == true then
        SetBoatAnchor(v, false)
        SetBoatFrozenWhenAnchored(v, false)
        Notify("¡Le has quitado la ancla tu barco!")
        ancle = false
    end
end)