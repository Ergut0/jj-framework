local isOpen = false
local toggles = { noclip = false, god = false, invisible = false, players = false }

-- Interfaz

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMenu()
    if isOpen then return end
    if not lib.callback.await('jj_admin:server:canOpen', false) then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

RegisterCommand(Config.Command, openMenu, false)
RegisterKeyMapping(Config.Command, 'Menú de administración', 'keyboard', Config.DefaultKey)

RegisterNuiCallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNuiCallback('getData', function(_, cb)
    local data = lib.callback.await('jj_admin:server:getData', false)
    if data then
        data.toggles = toggles
    end
    cb(data or false)
end)

RegisterNuiCallback('getItems', function(_, cb)
    cb(lib.callback.await('jj_admin:server:getItems', false) or {})
end)

RegisterNuiCallback('getBans', function(_, cb)
    cb(lib.callback.await('jj_admin:server:getBans', false) or {})
end)

RegisterNuiCallback('getLogs', function(_, cb)
    cb(lib.callback.await('jj_admin:server:getLogs', false) or {})
end)

RegisterNuiCallback('getCoords', function(_, cb)
    local coords = GetEntityCoords(cache.ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(cache.ped) })
end)

RegisterNuiCallback('action', function(data, cb)
    local result = lib.callback.await('jj_admin:server:action', false, data.action, data.payload)
    cb(result or { ok = false, message = 'Sin respuesta del servidor' })
    if result and result.close then
        closeMenu()
    end
end)

-- Noclip

local NOCLIP_SPEEDS = { slow = 0.4, normal = 1.2, fast = 4.0 }

local function noclipLoop()
    local entity = cache.vehicle or cache.ped
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)

    while toggles.noclip do
        entity = cache.vehicle or cache.ped
        local speed = NOCLIP_SPEEDS.normal
        if IsControlPressed(0, 21) then speed = NOCLIP_SPEEDS.fast end
        if IsControlPressed(0, 36) then speed = NOCLIP_SPEEDS.slow end

        local rotation = GetGameplayCamRot(2)
        local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
        local forward = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
        local right = vector3(math.cos(yaw), math.sin(yaw), 0.0)
        local position = GetEntityCoords(entity)

        if IsControlPressed(0, 32) then position = position + forward * speed end
        if IsControlPressed(0, 33) then position = position - forward * speed end
        if IsControlPressed(0, 35) then position = position + right * speed end
        if IsControlPressed(0, 34) then position = position - right * speed end
        if IsControlPressed(0, 44) then position = position + vector3(0.0, 0.0, speed) end
        if IsControlPressed(0, 38) then position = position - vector3(0.0, 0.0, speed) end

        SetEntityCoordsNoOffset(entity, position.x, position.y, position.z, true, true, true)
        SetEntityHeading(entity, rotation.z)
        Wait(0)
    end

    entity = cache.vehicle or cache.ped
    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
end

-- Espectar

local function spectate(target, coords, name)
    local ped = cache.ped
    local original = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 30.0, false, false, false, false)

    local timeout = GetGameTimer() + 5000
    local player = GetPlayerFromServerId(target)
    while player == -1 and GetGameTimer() < timeout do
        Wait(100)
        player = GetPlayerFromServerId(target)
    end

    if player ~= -1 then
        local targetPed = GetPlayerPed(player)
        NetworkSetInSpectatorMode(true, targetPed)
        lib.showTextUI(('Espectando a %s - [E] Salir'):format(name))

        local nextUpdate = 0
        local spectating = true
        while spectating do
            if IsControlJustPressed(0, 38) then
                spectating = false
            end
            -- El propio ped sigue al objetivo para que siga dentro del alcance de red
            if GetGameTimer() > nextUpdate then
                nextUpdate = GetGameTimer() + 3000
                CreateThread(function()
                    local current = lib.callback.await('jj_admin:server:spectateCoords', false)
                    if current then
                        SetEntityCoords(ped, current.x, current.y, current.z - 30.0, false, false, false, false)
                    else
                        spectating = false
                    end
                end)
            end
            Wait(0)
        end

        NetworkSetInSpectatorMode(false, targetPed)
        lib.hideTextUI()
    else
        lib.notify({ description = 'No se ha podido encontrar al jugador', type = 'error' })
    end

    TriggerServerEvent('jj_admin:server:stopSpectate')
    SetEntityCoords(ped, original.x, original.y, original.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, toggles.god)
    SetEntityVisible(ped, not toggles.invisible, false)
end

-- Ver jugadores: nombres cercanos y blips en el mapa

local playerBlips = {}
local playerList = {}

local function clearPlayerBlips()
    for _, blip in pairs(playerBlips) do
        RemoveBlip(blip)
    end
    playerBlips = {}
    playerList = {}
end

local function updatePlayerBlips(list)
    local seen = {}
    for _, info in ipairs(list) do
        seen[info.id] = true
        local blip = playerBlips[info.id]
        if blip then
            SetBlipCoords(blip, info.x, info.y, info.z)
        else
            blip = AddBlipForCoord(info.x, info.y, info.z)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 5)
            SetBlipScale(blip, 0.7)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(('[%s] %s'):format(info.id, info.name))
            EndTextCommandSetBlipName(blip)
            playerBlips[info.id] = blip
        end
    end
    for id, blip in pairs(playerBlips) do
        if not seen[id] then
            RemoveBlip(blip)
            playerBlips[id] = nil
        end
    end
    playerList = list
end

local function drawName(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.1)
    if not onScreen then return end
    SetTextScale(0.0, 0.32)
    SetTextFont(4)
    SetTextColour(250, 204, 21, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function playerNamesLoop()
    while toggles.players do
        local origin = GetEntityCoords(cache.ped)
        for _, info in ipairs(playerList) do
            local player = GetPlayerFromServerId(info.id)
            if player ~= -1 and info.id ~= cache.serverId then
                local ped = GetPlayerPed(player)
                local coords = GetEntityCoords(ped)
                if #(origin - coords) < 80.0 then
                    drawName(coords, ('[%s] %s'):format(info.id, info.name))
                end
            end
        end
        Wait(0)
    end
end

-- Teletransporte

local function teleport(x, y, z)
    local entity = cache.vehicle or cache.ped
    DoScreenFadeOut(200)
    Wait(200)
    SetEntityCoords(entity, x, y, z, false, false, false, false)
    DoScreenFadeIn(200)
end

local function teleportToWaypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        lib.notify({ description = 'Marca un punto en el mapa', type = 'error' })
        return
    end

    local coords = GetBlipInfoIdCoord(blip)
    local entity = cache.vehicle or cache.ped
    DoScreenFadeOut(200)
    Wait(200)

    -- El suelo solo se puede leer cuando el mapa de esa zona ha cargado
    local ground = nil
    for height = 1000.0, 0.0, -50.0 do
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, height, false, false, false)
        RequestCollisionAtCoord(coords.x, coords.y, height)
        Wait(50)
        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, height, false)
        if found then
            ground = z
            break
        end
    end

    SetEntityCoords(entity, coords.x, coords.y, (ground or 100.0) + 1.0, false, false, false, false)
    DoScreenFadeIn(200)
    closeMenu()
end

-- Vehículos

-- Solo se puede modificar un vehículo de red si este cliente tiene su control
local function getCurrentOrClosestVehicle()
    local vehicle = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), 6.0, true)
    if not vehicle then
        lib.notify({ description = 'No hay ningún vehículo cerca', type = 'error' })
        return nil
    end

    local timeout = GetGameTimer() + 1000
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(vehicle)
        Wait(50)
    end
    return vehicle
end

local function spawnVehicle(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        lib.notify({ description = 'Ese vehículo no existe', type = 'error' })
        return
    end
    lib.requestModel(hash)
    local coords = GetEntityCoords(cache.ped)
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), true, true)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(vehicle)
    Entity(vehicle).state:set('hasTempKey', true, true)
    TriggerServerEvent('jj_admin:server:vehicleSpawned', GetVehicleNumberPlateText(vehicle))
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    closeMenu()
end

local handlers = {
    noclip = function()
        toggles.noclip = not toggles.noclip
        if toggles.noclip then
            CreateThread(noclipLoop)
        end
    end,
    god = function()
        toggles.god = not toggles.god
        SetEntityInvincible(cache.ped, toggles.god)
    end,
    invisible = function()
        toggles.invisible = not toggles.invisible
        SetEntityVisible(cache.ped, not toggles.invisible, false)
    end,
    tpWaypoint = teleportToWaypoint,
    tpCoords = function(coords)
        teleport(coords.x, coords.y, coords.z)
    end,
    coords = function()
        local coords = GetEntityCoords(cache.ped)
        local text = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, GetEntityHeading(cache.ped))
        lib.setClipboard(text)
        lib.notify({ description = ('Copiado: %s'):format(text), type = 'success' })
    end,
    spectate = spectate,
    spawnVehicle = spawnVehicle,
    vehicleRepair = function()
        local vehicle = getCurrentOrClosestVehicle()
        if not vehicle then return end
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, 100.0)
    end,
    vehicleFlip = function()
        local vehicle = getCurrentOrClosestVehicle()
        if not vehicle then return end
        SetEntityRotation(vehicle, 0.0, 0.0, GetEntityHeading(vehicle), 2, true)
        SetVehicleOnGroundProperly(vehicle)
    end,
    vehicleDelete = function()
        local vehicle = getCurrentOrClosestVehicle()
        if not vehicle then return end
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    end,
    playersOn = function()
        toggles.players = true
        CreateThread(playerNamesLoop)
    end,
    playersUpdate = updatePlayerBlips,
    playersOff = function()
        toggles.players = false
        clearPlayerBlips()
    end,
}

RegisterNetEvent('jj_admin:client:run', function(name, ...)
    if source == '' then return end
    local handler = handlers[name]
    if handler then
        handler(...)
    end
end)

RegisterNetEvent('jj_admin:client:heal', function()
    if source == '' then return end
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    ClearPedBloodDamage(cache.ped)
end)

RegisterNetEvent('jj_admin:client:kill', function()
    if source == '' then return end
    SetEntityHealth(cache.ped, 0)
end)

-- Clima y hora fijados por un administrador

local function applyWorld()
    local weather = GlobalState.jjWeather
    if weather then
        SetWeatherOwnedByNetwork(false)
        SetWeatherTypeNowPersist(weather)
    end

    local time = GlobalState.jjTime
    if time then
        NetworkOverrideClockTime(time.hour, time.minute, 0)
    end
end

AddStateBagChangeHandler('jjWeather', 'global', function(_, _, value)
    if not value then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherOwnedByNetwork(true)
    end
end)

AddStateBagChangeHandler('jjTime', 'global', function(_, _, value)
    if not value then
        NetworkClearClockTimeOverride()
    end
end)

CreateThread(function()
    while true do
        applyWorld()
        Wait(5000)
    end
end)
