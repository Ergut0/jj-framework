-- Identifica el último susto: el temporizador de uno anterior no debe cortar el siguiente
local currentScare = 0

local function stopScare()
    currentScare = currentScare + 1
    SendNUIMessage({ action = 'stop' })
end

RegisterNetEvent('jj_sustos:client:start', function(kind, seconds)
    currentScare = currentScare + 1
    local scare = currentScare

    SendNUIMessage({ action = 'start', kind = kind, volume = Config.Volume })
    SetTimeout(seconds * 1000, function()
        if scare == currentScare then stopScare() end
    end)
end)

RegisterNetEvent('jj_sustos:client:stop', stopScare)

RegisterNetEvent('jj_sustos:client:leaveVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then TaskLeaveVehicle(ped, vehicle, 4160) end
end)

-- Solo el susto: sin daño
RegisterNetEvent('jj_sustos:client:explosion', function()
    local coords = GetEntityCoords(PlayerPedId())
    AddExplosion(coords.x, coords.y, coords.z, 31, 0.0, true, false, 1.0)
end)
