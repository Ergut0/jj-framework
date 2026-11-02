local gear = 1
local currentVehicle = nil
local currentVehicleMode = PursuitConfig.VehicleModes[1]
local hashModelMap = {}

local function fixVehicleHandling(veh)
    -- Necessary to apply the HandlingFloat
    -- Source: https://forum.cfx.re/t/cant-change-setvehiclehandlingfloat-transforming-vehicle-to-awd-fivem-bug/3393188/2
    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 0, GetVehicleMod(veh, 0), false)
    SetVehicleMod(veh, 1, GetVehicleMod(veh, 1), false)
    SetVehicleMod(veh, 2, GetVehicleMod(veh, 2), false)
    SetVehicleMod(veh, 3, GetVehicleMod(veh, 3), false)
    SetVehicleMod(veh, 4, GetVehicleMod(veh, 4), false)
    SetVehicleMod(veh, 5, GetVehicleMod(veh, 5), false)
    SetVehicleMod(veh, 6, GetVehicleMod(veh, 6), false)
    SetVehicleMod(veh, 7, GetVehicleMod(veh, 7), false)
    SetVehicleMod(veh, 8, GetVehicleMod(veh, 8), false)
    SetVehicleMod(veh, 9, GetVehicleMod(veh, 9), false)
    SetVehicleMod(veh, 10, GetVehicleMod(veh, 10), false)
    SetVehicleMod(veh, 11, GetVehicleMod(veh, 11), false)
    SetVehicleMod(veh, 12, GetVehicleMod(veh, 12), false)
    SetVehicleMod(veh, 13, GetVehicleMod(veh, 13), false)
    SetVehicleMod(veh, 15, GetVehicleMod(veh, 15), false)
    SetVehicleMod(veh, 16, GetVehicleMod(veh, 16), false)
    SetVehicleMod(veh, 25, GetVehicleMod(veh, 25), false)
    SetVehicleMod(veh, 27, GetVehicleMod(veh, 27), false)
    SetVehicleMod(veh, 28, GetVehicleMod(veh, 28), false)
    SetVehicleMod(veh, 30, GetVehicleMod(veh, 30), false)
    SetVehicleMod(veh, 33, GetVehicleMod(veh, 33), false)
    SetVehicleMod(veh, 34, GetVehicleMod(veh, 34), false)
    SetVehicleMod(veh, 35, GetVehicleMod(veh, 35), false)

    local bias = GetVehicleHandlingFloat(veh, "CHandlingData", "fDriveBiasFront")
    if bias == 0.0 then
        -- RWD
        SetVehicleWheelIsPowered(veh, 0, false)
        SetVehicleWheelIsPowered(veh, 1, false)
        SetVehicleWheelIsPowered(veh, 2, true)
        SetVehicleWheelIsPowered(veh, 3, true)
    elseif bias == 1.0 then
        -- FWD
        SetVehicleWheelIsPowered(veh, 0, true)
        SetVehicleWheelIsPowered(veh, 1, true)
        SetVehicleWheelIsPowered(veh, 2, false)
        SetVehicleWheelIsPowered(veh, 3, false)
    else
        -- AWD
        SetVehicleWheelIsPowered(veh, 0, true)
        SetVehicleWheelIsPowered(veh, 1, true)
        SetVehicleWheelIsPowered(veh, 2, true)
        SetVehicleWheelIsPowered(veh, 3, true)
    end
end

local function setupModelHashMap()
    for k, v in pairs(PursuitConfig.VehiclesConfig) do
        hashModelMap[GetHashKey(k)] = k
    end
end

local function getModelFromHash(hash)
    return hashModelMap[hash]
end

local function isValidVehicle(vehicle)
    local vehicleHash = GetEntityModel(vehicle)
    local vehicleModel = getModelFromHash(vehicleHash)
    return PursuitConfig.VehiclesConfig[vehicleModel]
end

local function getHandlingConfig(vehicleHash)
    local vehicleModel = getModelFromHash(vehicleHash)
    if PursuitConfig.VehiclesConfig[vehicleModel] then
        return PursuitConfig.VehiclesConfig[vehicleModel][currentVehicleMode]
    end
end

local function updateHandling(vehicle)
    local handlingConfig = getHandlingConfig(GetEntityModel(vehicle))
    if not handlingConfig then return end
    for k, v in pairs(handlingConfig) do
        local prefix = string.sub(k, 1, 1)
        if prefix == "f" then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", k, v + 0.0)
        elseif prefix == "n" then
            SetVehicleHandlingInt(vehicle, "CHandlingData", k, math.floor(v))
        elseif string.sub(k, 1, 3) == "vec" then
            SetVehicleHandlingVector(vehicle, "CHandlingData", k, v)
        else
            SetVehicleHandlingField(vehicle, "CHandlingData", k, v)
        end
    end
    fixVehicleHandling(vehicle)
    ModifyVehicleTopSpeed(vehicle, 1.0)
end

local function changeVehicleMode(vehicle, mode)
    local vehicleModel = getModelFromHash(GetEntityModel(vehicle))
    lib.notify({
        title = "Cambio de clase",
        description = "Modo de vehiculo cambiado a " .. mode,
        type = "success",
    })

    currentVehicleMode = mode
    currentVehicle = vehicle
    LocalPlayer.state:set('pursuitMode', mode, true)
    TriggerServerEvent('jj_policedispatch:server:vehicleModeChanged', currentVehicleMode)
end

RegisterNetEvent('jj_policedispatch:changeVehicleMode', function(mode)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped)
        if DoesEntityExist(vehicle) and isValidVehicle(vehicle) then
            changeVehicleMode(vehicle, mode)
            updateHandling(vehicle)
        end
    end
end)



AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    setupModelHashMap()
end)

OnPlayerLoaded(function()
    setupModelHashMap()
end)


-- SendNUIMessage({
--     action = 'pursuit:modeChanged',
--     data = {
--         mode = className
--     }
-- })


RegisterNUICallback('pursuit:getCurrentMode', function(data, cb)
    cb(currentVehicleMode)
end)

RegisterNUICallback('changeVehicleMode', function(data, cb)
    local mode = data.mode
    if mode then
        TriggerEvent('jj_policedispatch:changeVehicleMode', mode)
    else
        cb(false)
    end
end)
