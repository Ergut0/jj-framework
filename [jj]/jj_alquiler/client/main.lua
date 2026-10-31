local DEFAULT_IMAGE = "https://r2.fivemanage.com/Ub9OVKFDXABGBWnCQYR5Y/images/Blista-GTAV-front.webp"

local createdPoints = false
local rentedVehicle = nil

local function CreateBlip(coords, color, text)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 404)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function RentVehicle(index, model)
    if not IsModelInCdimage(GetHashKey(model)) then
        Notify("El vehículo no está instalado", "error")
        return
    end

    -- El servidor decide el precio y cobra antes de que aparezca el vehículo
    local rental = lib.callback.await('jj_alquiler:server:rent', false, index, model)
    if not rental or not rental.ok then
        Notify(rental and rental.error or "No se ha podido alquilar el vehículo", "error")
        return
    end

    rentedVehicle = SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, rental.plate)
        local timeout = GetGameTimer() + 3000
        while not NetworkGetEntityIsNetworked(veh) and GetGameTimer() < timeout do
            Wait(50)
        end
        TriggerServerEvent('jj_alquiler:server:spawned', NetworkGetNetworkIdFromEntity(veh))
    end, Config.Spawns[index].coordsSpawn)
end

local function OpenMenuList(index)
    local options = {}

    for _, car in pairs(Config.Spawns[index].listVehicles) do
        options[#options + 1] = {
            title = car.model,
            description = "Precio: $" .. car.price,
            image = car.image and car.image ~= "" and car.image or DEFAULT_IMAGE,
            onSelect = function()
                RentVehicle(index, car.model)
            end,
            arrow = true,
            icon = "bars",
        }
    end

    lib.registerContext({
        id = 'alquiler_vehiculos',
        title = 'Alquiler de vehiculos',
        options = options,
    })

    lib.showContext('alquiler_vehiculos')
end

local function createNPCandPoints()
    if createdPoints then return end
    createdPoints = true

    local model = `a_m_y_surfer_01`
    if not lib.requestModel(model) then
        return
    end

    for k, v in pairs(Config.Spawns) do
        local ped = CreatePed(4, model, v.coordsSelector.x, v.coordsSelector.y, v.coordsSelector.z - 1.0, v.coordsSelector.w or 0.0, false, false)
        SetEntityHeading(ped, v.coordsSelector.w or 0.0)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        CreateBlip(v.coordsSelector, 0, "Alquiler de Barco")

        TaskStartScenarioAtPosition(ped, "WORLD_HUMAN_CLIPBOARD", v.coordsSelector.x, v.coordsSelector.y, v.coordsSelector.z - 1.0, v.coordsSelector.w or 0.0, 0, 0, 1)

        lib.points.new({
            coords = v.coordsSelector,
            distance = 2.0,
            onEnter = function()
                lib.showTextUI('Hablar con el arrendatario')
            end,
            nearby = function()
                if IsControlJustPressed(0, 38) then
                    OpenMenuList(k)
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })

        lib.points.new({
            coords = v.deletePoint,
            distance = 2.0,
            onEnter = function()
                if cache.vehicle and cache.vehicle == rentedVehicle then
                    lib.showTextUI('Devolver vehículo')
                end
            end,
            nearby = function(self)
                -- Solo se puede devolver el vehículo alquilado, no cualquiera en el que se vaya montado
                if cache.vehicle and cache.vehicle == rentedVehicle then
                    if IsControlJustPressed(0, 38) then
                        SetEntityAsMissionEntity(rentedVehicle, true, true)
                        DeleteVehicle(rentedVehicle)
                        rentedVehicle = nil
                        lib.hideTextUI()
                    end

                    DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 100, false, false, false, true, false, false, false)
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })
    end
end

OnPlayerReady(createNPCandPoints)
