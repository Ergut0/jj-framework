local JJ = exports['jj-framework']:GetCoreObject()
local PlayerJob = nil
local currentPrompt = nil
local savingVehicle = false
local systemCreated = false

-- Functions

local function Notify(description, type)
    lib.notify({ description = description, type = type or 'inform' })
end

local function setPrompt(text)
    if currentPrompt ~= text then
        currentPrompt = text
        lib.showTextUI(text)
    end
end

local function clearPrompt()
    if currentPrompt then
        currentPrompt = nil
        lib.hideTextUI()
    end
end

local function HasGarageAccess(garage)
    if garage.type == 'public' or garage.type == 'depot' then
        return true
    end
    if garage.type ~= 'job' or not PlayerJob then
        return false
    end
    if type(garage.job) == 'table' then
        for _, job in pairs(garage.job) do
            if job == PlayerJob.name then
                return true
            end
        end
        return false
    end
    return garage.job == PlayerJob.name
end

local function CheckPlayers(vehicle)
    for i = -1, 5, 1 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if seat ~= 0 then
            TaskLeaveVehicle(seat, vehicle, 0)
        end
    end
end

local function GetVehicleLabel(model)
    local label = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(model)))
    return label ~= 'NULL' and label or model
end

local function GetSpawnPoint(garage)
    local location = nil
    if #garage.spawnPoint > 1 then
        local maxTries = #garage.spawnPoint
        for _ = 1, maxTries do
            local randomIndex = math.random(1, #garage.spawnPoint)
            local chosenSpawnPoint = garage.spawnPoint[randomIndex]
            local isOccupied = IsPositionOccupied(
                chosenSpawnPoint.x,
                chosenSpawnPoint.y,
                chosenSpawnPoint.z,
                2.0,   -- range
                false,
                true,  -- checkVehicles
                false, -- checkPeds
                false,
                false,
                0,
                false
            )
            if not isOccupied then
                location = chosenSpawnPoint
                break
            end
        end
    elseif #garage.spawnPoint == 1 then
        location = garage.spawnPoint[1]
    end
    if not location then
        Notify(Lang:t('error.vehicle_occupied'), 'error')
    end
    return location
end

local function SpawnVehicle(model, location)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        return nil
    end

    lib.requestModel(hash)
    local veh = CreateVehicle(hash, location.x, location.y, location.z, location.w, true, true)
    SetModelAsNoLongerNeeded(hash)

    local timeout = GetGameTimer() + 3000
    while not DoesEntityExist(veh) and GetGameTimer() < timeout do
        Wait(50)
    end

    return DoesEntityExist(veh) and veh or nil
end

local function TakeOutVehicle(data)
    local location = GetSpawnPoint(Config.Garages[data.garage])
    if not location then return end

    local result = lib.callback.await('jj_garages:server:takeOutVehicle', false, data.plate, data.garage)
    if not result or not result.ok then
        Notify(Lang:t('error.' .. (result and result.error or 'no_spawn')), 'error')
        return
    end

    local veh = SpawnVehicle(result.model, location)
    if not veh then
        -- El servidor devuelve el vehículo a su estado anterior y el dinero del depósito
        TriggerServerEvent('jj_garages:server:spawnFailed', data.plate)
        Notify(Lang:t('error.model_missing'), 'error')
        return
    end

    SetVehicleNumberPlateText(veh, result.plate)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    Entity(veh).state:set('initVehicle', true, true)
    Entity(veh).state:set('HotWire', 'StopNeedHotWire', true)
    Entity(veh).state:set('vehPersonal', result.plate, true)

    local props = result.props
    props.plate = result.plate
    if not Config.VisuallyDamageCars then
        props.bodyHealth = 1000.0
        props.engineHealth = 1000.0
    end
    lib.setVehicleProperties(veh, props)

    if Config.Warp then
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    end
end

local function OpenGarageMenu(data)
    local result = lib.callback.await('jj_garages:server:GetGarageVehicles', false, data.indexgarage)
    if not result or #result == 0 then
        return Notify(Lang:t('error.no_vehicles'), 'error')
    end

    local formattedVehicles = {}
    for _, v in ipairs(result) do
        local _type = {
            garage = data.indexgarage,
            plate = v.plate,
        }

        local metadata = {
            { label = "Combustible", value = math.floor(v.fuel) .. "%" },
            { label = "Motor",       value = math.floor(v.engine / 10) .. "%" },
            { label = "Carrocería",  value = math.floor(v.body / 10) .. "%" },
        }

        if v.price then
            metadata[#metadata + 1] = { label = "Depósito", value = Lang:t('info.depot_price', v.price) }
        end

        formattedVehicles[#formattedVehicles + 1] = {
            icon = 'car',
            title = GetVehicleLabel(v.model),
            description = "Matrícula: " .. v.plate,
            metadata = metadata,
            onSelect = function()
                CreateThread(function()
                    TakeOutVehicle(_type)
                end)
            end,
            arrow = true,
        }
    end

    lib.registerContext({
        id = 'garage',
        title = Config.Garages[data.indexgarage].label,
        options = formattedVehicles
    })

    lib.showContext('garage')
end

local function DepositVehicle(veh, data)
    local props = lib.getVehicleProperties(veh)
    local result = lib.callback.await('jj_garages:server:parkVehicle', false, NetworkGetNetworkIdFromEntity(veh), props, data.indexgarage)

    if result and result.ok then
        Entity(veh).state:set('vehPersonal', nil, true)
        -- El servidor elimina el vehículo en cuanto los ocupantes han tenido tiempo de bajar
        CheckPlayers(veh)
        Notify(Lang:t('success.vehicle_parked'), 'success')
    else
        Notify(Lang:t('error.' .. (result and result.error or 'not_owned')), 'error')
    end

    savingVehicle = false
end

local function IsVehicleAllowed(classList, vehicle)
    if not Config.ClassSystem then return true end
    for _, class in ipairs(classList) do
        if GetVehicleClass(vehicle) == class then
            return true
        end
    end
    return false
end

local function CreateBlips(setloc)
    local Garage = AddBlipForCoord(setloc.takeVehicle.x, setloc.takeVehicle.y, setloc.takeVehicle.z)
    SetBlipSprite(Garage, setloc.blipNumber)
    SetBlipDisplay(Garage, 4)
    SetBlipScale(Garage, 0.50)
    SetBlipAsShortRange(Garage, true)
    SetBlipColour(Garage, setloc.blipColor)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(setloc.blipName)
    EndTextCommandSetBlipName(Garage)
end

local function GetPromptText(garage)
    if garage.type == 'depot' then
        return Lang:t('info.depot_e')
    elseif garage.category == Config.VehicleClass.sea then
        return Lang:t('info.sea_e')
    elseif garage.category == Config.VehicleClass.air then
        return Lang:t('info.air_e')
    elseif garage.category == Config.VehicleClass.rig then
        return Lang:t('info.rig_e')
    end
    return Lang:t('info.car_e')
end

local function OnGarageKey(index, garage)
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsUsing(ped)
    local data = { indexgarage = index }

    if currentVehicle == 0 then
        CreateThread(function()
            OpenGarageMenu(data)
        end)
        return
    end

    if GetPedInVehicleSeat(currentVehicle, -1) ~= ped then
        Notify(Lang:t('error.not_driver'), 'error')
        return
    end

    if savingVehicle or garage.type == 'depot' then return end

    if not IsVehicleAllowed(garage.category, currentVehicle) then
        Notify(Lang:t('error.not_correct_type'), 'error')
        return
    end

    savingVehicle = true
    CreateThread(function()
        DepositVehicle(currentVehicle, data)
    end)
end

local function CreateBlipsZones()
    local PlayerData = JJ.GetPlayerData()
    PlayerJob = PlayerData and PlayerData.job

    if systemCreated then return end
    systemCreated = true

    for index, garage in pairs(Config.Garages) do
        if garage.showBlip then
            CreateBlips(garage)
        end

        lib.zones.sphere({
            coords = garage.takeVehicle,
            radius = 10.0,
            debug = Config.DebugTarget,
            inside = function()
                if not HasGarageAccess(garage) then
                    clearPrompt()
                    return
                end
                setPrompt(GetPromptText(garage))
                if IsControlJustReleased(0, 38) then
                    OnGarageKey(index, garage)
                end
            end,
            onExit = clearPrompt,
        })
    end
end

-- Handlers

AddEventHandler('jj:client:playerSpawned', CreateBlipsZones)

AddEventHandler('jj:client:playerDataChanged', function(key, value)
    if key == 'job' then
        PlayerJob = value
    end
end)

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

if JJ.IsSpawned() then
    CreateThread(CreateBlipsZones)
end
