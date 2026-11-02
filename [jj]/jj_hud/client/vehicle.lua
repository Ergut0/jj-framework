local UPDATE_INTERVAL = 100
local STREET_INTERVAL = 500
local IDLE_INTERVAL = 500
local CONTROL_EXIT_VEHICLE = 75
local WINDSCREEN_FLAG = 32

-- En GTA el rumbo crece hacia el oeste: 0 es norte y 90 es oeste
local DIRECTIONS = { 'N', 'NO', 'O', 'SO', 'S', 'SE', 'E', 'NE' }

local belted = false
local wasInVehicle = false
local street = ''
local direction = 'N'
local nextStreetUpdate = 0

local speedFactor = Config.SpeedUnit == 'mph' and 2.236936 or 3.6
local speedLabel = Config.SpeedUnit == 'mph' and 'MPH' or 'KM/H'

-- Cinturón

local function canUseSeatbelt(vehicle)
    return vehicle and not Config.NoSeatbeltClasses[GetVehicleClass(vehicle)]
end

local function applySeatbelt()
    if Config.Seatbelt.Eject then
        SetPedConfigFlag(cache.ped, WINDSCREEN_FLAG, not belted)
    end
end

local function setSeatbelt(value)
    belted = value
    applySeatbelt()
    PlaySoundFrontend(-1, value and 'Faster_Click' or 'Slower_Click', 'RESPAWN_ONLINE_SOUNDSET', true)
end

RegisterCommand('jj_hud_seatbelt', function()
    if cache.vehicle and canUseSeatbelt(cache.vehicle) then
        setSeatbelt(not belted)
    end
end, false)
RegisterKeyMapping('jj_hud_seatbelt', 'Ponerse o quitarse el cinturón', 'keyboard', Config.Seatbelt.Key)

if Config.Seatbelt.Eject then
    SetFlyThroughWindscreenParams(Config.Seatbelt.EjectSpeed, Config.Seatbelt.EjectUnknown, Config.Seatbelt.EjectModifier, Config.Seatbelt.EjectMinDamage)
end

-- Con el cinturón puesto no se puede salir del vehículo sin quitárselo
CreateThread(function()
    while true do
        if belted then
            DisableControlAction(0, CONTROL_EXIT_VEHICLE, true)
            if IsDisabledControlJustPressed(0, CONTROL_EXIT_VEHICLE) then
                lib.notify({ description = ('Quítate el cinturón con %s para salir'):format(Config.Seatbelt.Key), type = 'error' })
            end
            Wait(0)
        else
            Wait(IDLE_INTERVAL)
        end
    end
end)

exports('isSeatbeltOn', function()
    return belted
end)

-- Datos del vehículo

local function getKind(class)
    if Config.AirClasses[class] then return 'air' end
    if class == Config.BoatClass then return 'boat' end
    return 'land'
end

local function getGear(vehicle, speed, rpm, running)
    if not running then return '-' end
    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then return 'R' end
    if speed < 1 and rpm <= 0.21 then return 'N' end
    return tostring(gear)
end

local function updateLocation(vehicle)
    local now = GetGameTimer()
    if now < nextStreetUpdate then return end
    nextStreetUpdate = now + STREET_INTERVAL

    local coords = GetEntityCoords(vehicle)
    street = GetStreetNameFromHashKey((GetStreetNameAtCoord(coords.x, coords.y, coords.z)))
    direction = DIRECTIONS[(math.floor((GetEntityHeading(vehicle) + 22.5) / 45.0) % 8) + 1]
end

-- Según la versión del juego, estos datos llegan como número o como booleano
local function isOn(value)
    return value == 1 or value == true
end

local function collectVehicle(vehicle)
    local class = GetVehicleClass(vehicle)
    local speed = GetEntitySpeed(vehicle)
    local running = GetIsVehicleEngineRunning(vehicle)
    local rpm = running and GetVehicleCurrentRpm(vehicle) or 0.0
    local _, lightsOn, highBeams = GetVehicleLightsState(vehicle)
    local kind = getKind(class)

    updateLocation(vehicle)

    return {
        speed = math.floor(speed * speedFactor + 0.5),
        unit = speedLabel,
        rpm = math.floor(rpm * 100 + 0.5),
        gear = kind == 'land' and getGear(vehicle, speed, rpm, running) or nil,
        kind = kind,
        fuel = math.floor(math.max(0.0, math.min(100.0, GetVehicleFuelLevel(vehicle))) + 0.5),
        engine = math.floor(math.max(0.0, math.min(1000.0, GetVehicleEngineHealth(vehicle))) / 10 + 0.5),
        running = running,
        lights = isOn(highBeams) and 2 or (isOn(lightsOn) and 1 or 0),
        locked = GetVehicleDoorLockStatus(vehicle) == 2,
        hasSeatbelt = canUseSeatbelt(vehicle),
        belted = belted,
        altitude = kind == 'air' and math.floor(GetEntityHeightAboveGround(vehicle) + 0.5) or nil,
        street = street,
        direction = direction,
    }
end

local function changed(a, b)
    if not a then return true end
    for key, value in pairs(b) do
        if a[key] ~= value then return true end
    end
    return false
end

CreateThread(function()
    local last = nil
    while true do
        local vehicle = cache.vehicle
        if not vehicle and belted then
            belted = false
            applySeatbelt()
        end

        if vehicle and IsHudVisible() then
            wasInVehicle = true
            local data = collectVehicle(vehicle)
            if changed(last, data) then
                SendNUIMessage({ type = 'updateVehicle', data = data })
                last = data
            end
            Wait(UPDATE_INTERVAL)
        else
            if wasInVehicle then
                wasInVehicle = false
                last = nil
                SendNUIMessage({ type = 'updateVehicle', data = false })
            end
            Wait(IDLE_INTERVAL)
        end
    end
end)
