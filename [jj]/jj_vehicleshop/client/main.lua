local statsCache = {}
local currentDealer = nil
local allCategories = {}
local currentVehicle = nil
local currentCategory = nil
local busy = false
local coinPrices = {} -- modelo -> precio en CP de lo que se ha visto
local inMenu = false
local prevCam = nil

local function notify(message, type)
    lib.notify({ description = message, type = type or 'inform' })
end

CreateThread(function()
    for _, v in pairs(Config.Dealerships) do
        -- Los concesionarios de trabajo tienen el icono a 0: no salen en el mapa
        if v.blip.icon ~= 0 then
            local blip = AddBlipForCoord(v.blip.coords.x, v.blip.coords.y, v.blip.coords.z)
            SetBlipSprite(blip, v.blip.icon)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            SetBlipColour(blip, v.blip.color)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(v.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    for _, v in pairs(Config.AddonsVehicle) do
        AddTextEntry(v.spawnName, v.label)
    end
end)

local function getFieldFromHandling(vehicle, field)
    return GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
end

local function calculateStats(vehicle)
    local model = GetEntityModel(vehicle)
    if statsCache[model] then return statsCache[model] end

    local brand = GetLabelText(GetMakeNameFromVehicleModel(model))
    if brand == 'NULL' or brand == 'null' then
        brand = 'IMPORT'
    end

    local isMotorCycle = IsThisModelABike(model) or GetVehicleClass(vehicle) == 8
    local isBoat = IsThisModelABoat(model) or GetVehicleClass(vehicle) == 14
    local maxFlatVel = getFieldFromHandling(vehicle, 'fInitialDriveMaxFlatVel')
    local driveForce = getFieldFromHandling(vehicle, 'fInitialDriveForce')
    local clutchUpShift = getFieldFromHandling(vehicle, 'fClutchChangeRateScaleUpShift')
    local biasFront = getFieldFromHandling(vehicle, 'fDriveBiasFront')
    local dragCoeff = getFieldFromHandling(vehicle, 'fInitialDragCoeff')
    local tractionMax = getFieldFromHandling(vehicle, 'fTractionCurveMax')
    local tractionMin = getFieldFromHandling(vehicle, 'fTractionCurveMin')
    local tractionLoss = getFieldFromHandling(vehicle, 'fLowSpeedTractionLossMult')
    local reboundDamp = getFieldFromHandling(vehicle, 'fSuspensionReboundDamp')
    local antiRollBar = getFieldFromHandling(vehicle, 'fAntiRollBarForce')
    local brakeForce = getFieldFromHandling(vehicle, 'fBrakeForce')

    -- Nota de rendimiento: decide la clase del vehículo
    local ratingForce = driveForce
    if driveForce > 0 and driveForce < 1 then
        ratingForce = ratingForce * 1.1
    end
    local ratingAccel = (maxFlatVel * ratingForce) / 10
    local ratingSpeed = ((maxFlatVel / dragCoeff) * (tractionMax + tractionMin)) / 40
    local ratingHandling = (tractionMax + reboundDamp) * tractionMin
    if isMotorCycle then
        ratingSpeed = ratingSpeed * 2
        ratingHandling = ratingHandling / 2
    end
    local ratingBraking = ((tractionMin / dragCoeff) * brakeForce) * 7
    local perfRating = ((ratingAccel * 5) + ratingSpeed + ratingHandling + ratingBraking) * 15

    -- Barras de la ficha
    local drivetrainMod = biasFront > 0.5 and (1.0 - biasFront) or biasFront
    local force = driveForce
    if driveForce > 0 and driveForce < 1 then
        force = (force + drivetrainMod * 0.15) * 1.1
    end

    local lowSpeedTraction = 1.0
    if tractionLoss >= 1.0 then
        lowSpeedTraction = lowSpeedTraction + (tractionLoss - lowSpeedTraction) * 0.15
    else
        lowSpeedTraction = lowSpeedTraction - (lowSpeedTraction - tractionLoss) * 0.15
    end

    local speed = (math.ceil(maxFlatVel * 1.3) / 300) * 10
    local accel = (maxFlatVel * force + (clutchUpShift * 0.7)) / 10
    local handling = (tractionMax + (reboundDamp + antiRollBar) / 3) * (tractionMin / lowSpeedTraction) + drivetrainMod
    local braking = isBoat and 0.0 or ((tractionMin / tractionMax) * brakeForce) * 7

    local class = 'D'
    if isMotorCycle then
        class = 'M'
    elseif perfRating > 700 then
        class = 'S'
    elseif perfRating > 550 then
        class = 'A'
    elseif perfRating > 400 then
        class = 'B'
    elseif perfRating > 325 then
        class = 'C'
    end

    statsCache[model] = {
        brand = brand,
        class = class,
        info = {
            acceleration = { name = UILang.acceleration, value = accel },
            handling = { name = UILang.handling, value = handling },
            speed = { name = UILang.speed, value = speed },
            braking = { name = UILang.braking, value = braking },
        },
    }
    return statsCache[model]
end

local function deleteVehicle(vehicle)
    local tries = 0
    while vehicle and DoesEntityExist(vehicle) and tries < 50 do
        SetEntityAsMissionEntity(vehicle, false, false)
        DeleteVehicle(vehicle)
        tries = tries + 1
        Wait(10)
    end
end

local function deleteCurrentVehicle()
    deleteVehicle(currentVehicle)
    currentVehicle = nil
end

local function spawnVehicle(model, coords, networked)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then return nil end

    lib.requestModel(hash)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.h, networked, true)
    SetModelAsNoLongerNeeded(hash)

    local timeout = GetGameTimer() + 3000
    while not DoesEntityExist(vehicle) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not DoesEntityExist(vehicle) then return nil end

    SetVehicleDirtLevel(vehicle, 0.0)
    return vehicle
end

local function renderCamera()
    DoScreenFadeOut(100)
    Wait(1000)
    local camCoords = Config.Dealerships[currentDealer].preview_vehicle_camera
    prevCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(prevCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(prevCam, 0.0, 0.0, camCoords.rotation)
    SetFocusPosAndVel(camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0)
    SetCamFov(prevCam, camCoords.fov)
    RenderScriptCams(true, false, 0, true, false)
    Wait(1000)
    DoScreenFadeIn(50)
end

-- Deja la cámara, el foco y el personaje como estaban
local function leaveMenu()
    inMenu = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    ClearFocus()
    RenderScriptCams(false, false, 0, true, false)
    if prevCam then
        DestroyCam(prevCam, false)
        prevCam = nil
    end
    FreezeEntityPosition(cache.ped, false)
end

local function sendCategories()
    SendNUIMessage({ action = 'setCarousel', data = { type = 'categories', elements = allCategories } })
end

-- Se llama desde el vendedor, en open_c.lua
function OpenDealership(name)
    local dealership = Config.Dealerships[name]
    if not dealership or inMenu or busy then return end

    busy = true
    local result = lib.callback.await('jj_vehicleshop:server:open', false, name)
    if not result or not result.ok then
        busy = false
        notify(Lang[result and result.error or 'no_access'], 'error')
        return
    end

    currentDealer = name
    allCategories = {}
    for _, category in ipairs(dealership.categories) do
        allCategories[#allCategories + 1] = { label = category }
    end

    lib.hideTextUI()
    inMenu = true
    FreezeEntityPosition(cache.ped, true)
    renderCamera()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openDealership', data = { state = true, lang = UILang, sign = dealership.money_sign } })
    sendCategories()
    notify(Lang.rotate_hint)
    busy = false
end

RegisterNUICallback('showCategories', function(_, cb)
    deleteCurrentVehicle()
    sendCategories()
    cb('ok')
end)

RegisterNUICallback('openCategory', function(data, cb)
    cb('ok')
    if busy then return end
    busy = true

    local vehicles = lib.callback.await('jj_vehicleshop:server:getCategory', false, data.category)
    local menu = {}
    for _, vehicle in ipairs(vehicles or {}) do
        local hash = GetHashKey(vehicle.name)
        if IsModelInCdimage(hash) then
            local label = GetLabelText(GetDisplayNameFromVehicleModel(hash)):lower()
            if label == 'carnotfound' or label == 'null' then
                label = vehicle.name
            end
            menu[#menu + 1] = { label = label, price = vehicle.price, coins = vehicle.coins, name = vehicle.name }
            coinPrices[vehicle.name] = vehicle.coins
        else
            print(('[jj_vehicleshop] El vehículo %s no existe en el juego: revisa la categoría %s'):format(vehicle.name, data.category))
        end
    end
    table.sort(menu, function(a, b) return a.label < b.label end)

    if #menu > 0 then
        currentCategory = data.category
        SendNUIMessage({ action = 'setCarousel', data = { type = 'vehicles', elements = menu } })
    else
        notify(Lang.empty_category, 'error')
    end
    busy = false
end)

RegisterNUICallback('showVehicle', function(data, cb)
    cb('ok')
    if busy then return end
    busy = true
    deleteCurrentVehicle()

    local dealership = Config.Dealerships[currentDealer]
    currentVehicle = spawnVehicle(data.name, dealership.preview_vehicle_coords, false)
    if not currentVehicle then
        busy = false
        return
    end
    Entity(currentVehicle).state:set('locked', 1, false)

    local stats = calculateStats(currentVehicle)
    local speed = GetVehicleEstimatedMaxSpeed(currentVehicle) * (Config.SpeedUnit == 'mph' and 2.236936 or 3.6)

    SendNUIMessage({
        action = 'vehData',
        data = {
            name = data.name,
            label = data.label,
            price = data.price,
            brand = stats.brand,
            class = stats.class,
            info = stats.info,
            buy = dealership.buy_vehicle,
            test = dealership.test_vehicles,
            unit = Config.SpeedUnit,
            speed = math.floor(speed + 0.5),
            seats = GetVehicleModelNumberOfSeats(GetHashKey(data.name)),
        },
    })

    -- Las flechas tienen que llegar al juego para rotar el vehículo
    SetNuiFocusKeepInput(true)
    busy = false
end)

local function formatTime(milliseconds)
    local seconds = math.ceil(milliseconds / 1000)
    return ('%d:%02d'):format(math.floor(seconds / 60), seconds % 60)
end

RegisterNUICallback('testDrive', function(data, cb)
    cb('ok')
    if busy then return end
    busy = true

    if not lib.callback.await('jj_vehicleshop:server:startTest', false, currentCategory, data.name) then
        notify(Lang.test_failed, 'error')
        busy = false
        return
    end

    local ped = cache.ped
    local prevCoords = GetEntityCoords(ped)
    local prevHeading = GetEntityHeading(ped)

    SendNUIMessage({ action = 'close' })
    DoScreenFadeOut(100)
    Wait(1000)
    deleteCurrentVehicle()
    leaveMenu()

    local vehicle = spawnVehicle(data.name, Config.Dealerships[currentDealer].test_coords, true)
    if vehicle then
        SetVehicleNumberPlateText(vehicle, Config.VehicleTestPlates)
        SetVehicleDoorsLocked(vehicle, 1)
        Entity(vehicle).state:set('hasTempKey', true, true)
        Entity(vehicle).state:set('HotWire', 'StopNeedHotWire', true)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        TriggerServerEvent('jj_vehicleshop:server:testVehicle', NetworkGetNetworkIdFromEntity(vehicle))
        Wait(1000)
        DoScreenFadeIn(50)

        local finishAt = GetGameTimer() + Config.DriveTestTime * 60000
        while GetGameTimer() < finishAt and GetPedInVehicleSeat(vehicle, -1) == ped do
            lib.showTextUI(Lang.time_left .. formatTime(finishAt - GetGameTimer()))
            Wait(250)
        end
        lib.hideTextUI()
        DoScreenFadeOut(100)
        Wait(1000)
    else
        notify(Lang.test_failed, 'error')
    end

    deleteVehicle(vehicle)
    TriggerServerEvent('jj_vehicleshop:server:endTest')
    SetEntityCoords(ped, prevCoords.x, prevCoords.y, prevCoords.z, false, false, false, false)
    SetEntityHeading(ped, prevHeading)
    Wait(1000)
    DoScreenFadeIn(1000)
    busy = false
end)

-- Muestra el diálogo de jj_paymethods sin la interfaz del concesionario por delante
local function selectPaymentMethod(price, coins)
    SendNUIMessage({ action = 'setHidden', data = true })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)

    local allowCompany = Config.Dealerships[currentDealer].company_card == true
    local ok, method = pcall(function()
        return exports.jj_paymethods:SelectMethod(price, allowCompany, coins)
    end)

    -- Pase lo que pase con el diálogo, el menú tiene que volver
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = 'setHidden', data = false })

    if not ok then
        print(('[jj_vehicleshop] No se puede abrir el pago: %s. ¿Está arrancado y actualizado jj_paymethods?'):format(method))
        notify(Lang.payment_unavailable, 'error')
        return nil
    end
    return method
end

RegisterNUICallback('buyVehicle', function(data, cb)
    cb('ok')
    if busy then return end
    busy = true

    -- El precio en CP solo se muestra: el servidor cobra el de su configuración
    local method = selectPaymentMethod(data.price, coinPrices[data.name])
    if not method then
        busy = false
        return
    end

    -- El servidor cobra el precio de su configuración, no el que se ha mostrado aquí
    local result = lib.callback.await('jj_vehicleshop:server:buy', false, currentCategory, data.name, method)
    if not result or not result.ok then
        notify(Lang[result and result.error or 'buy_failed'], 'error')
        busy = false
        return
    end

    SendNUIMessage({ action = 'close' })
    DoScreenFadeOut(0)
    Wait(400)
    deleteCurrentVehicle()
    leaveMenu()

    local spawn = Config.Dealerships[currentDealer].purchased_vehicle_spawn
    local vehicle = spawnVehicle(result.model, spawn, true)
    if vehicle then
        SetVehicleNumberPlateText(vehicle, result.plate)
        Entity(vehicle).state:set('vehPersonal', result.plate, true)
        Entity(vehicle).state:set('HotWire', 'StopNeedHotWire', true)
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
        TriggerServerEvent('jj_vehicleshop:server:delivered')
        notify(Lang.bought:format(result.plate), 'success')
    else
        notify(Lang.spawn_failed:format(result.plate))
    end

    DoScreenFadeIn(1000)
    busy = false
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    DoScreenFadeOut(0)
    Wait(400)
    deleteCurrentVehicle()
    leaveMenu()
    TriggerServerEvent('jj_vehicleshop:server:close')
    DoScreenFadeIn(1000)
    busy = false
end)

-- /registrarcoche: lo pide el servidor después de comprobar el permiso
RegisterNetEvent('jj_vehicleshop:client:registerCurrent', function()
    if source == '' then return end
    local vehicle = cache.vehicle
    if not vehicle then
        notify(Lang.register_no_vehicle, 'error')
        return
    end

    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
    local plate = lib.callback.await('jj_vehicleshop:server:registerCurrent', false, model)
    if plate then
        SetVehicleNumberPlateText(vehicle, plate)
        Entity(vehicle).state:set('vehPersonal', plate, true)
        Entity(vehicle).state:set('HotWire', 'StopNeedHotWire', true)
        notify(Lang.registered:format(plate), 'success')
    end
end)

-- Con el menú abierto, solo las flechas mueven el vehículo
CreateThread(function()
    while true do
        if inMenu then
            DisableAllControlActions(0)
            EnableControlAction(0, 174, true)
            EnableControlAction(0, 175, true)
            if currentVehicle then
                FreezeEntityPosition(currentVehicle, true)
                if IsControlPressed(0, 174) then
                    SetEntityHeading(currentVehicle, GetEntityHeading(currentVehicle) + 1.0)
                elseif IsControlPressed(0, 175) then
                    SetEntityHeading(currentVehicle, GetEntityHeading(currentVehicle) - 1.0)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and inMenu then
        deleteCurrentVehicle()
        leaveMenu()
    end
end)
