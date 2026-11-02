local L = Config.Locales
local flags = {}      -- id -> bandera
local myGang = nil
local running = false
local planting = false
local textShown = nil

local function deleteObject(flag)
    if flag.object and DoesEntityExist(flag.object) then
        DeleteObject(flag.object)
    end
    flag.object = nil
end

local function removeFlag(flag)
    deleteObject(flag)
    if flag.blip and DoesBlipExist(flag.blip) then RemoveBlip(flag.blip) end
    flag.blip = nil
end

local function addBlip(flag)
    flag.blip = AddBlipForRadius(flag.coords.x, flag.coords.y, flag.coords.z, Config.RadiusFlag)
    SetBlipColour(flag.blip, flag.blipColor)
    SetBlipAlpha(flag.blip, 150)
end

local function spawnObject(flag)
    local ok = pcall(lib.requestModel, flag.prop)
    if not ok then return end

    flag.object = CreateObject(flag.prop, flag.coords.x, flag.coords.y, flag.coords.z, false, false, false)
    FreezeEntityPosition(flag.object, true)
    PlaceObjectOnGroundProperly(flag.object)
    SetModelAsNoLongerNeeded(flag.prop)
end

local function setText(text)
    if textShown == text then return end
    textShown = text
    if text then lib.showTextUI(text) else lib.hideTextUI() end
end

local function loop()
    if running then return end
    running = true

    CreateThread(function()
        while myGang and next(flags) do
            local sleep = 1000
            local coords = GetEntityCoords(cache.ped)
            local prompt = nil

            for _, flag in pairs(flags) do
                local distance = #(coords - flag.coords)

                if distance < Config.RenderDistance then
                    if not (flag.object and DoesEntityExist(flag.object)) then spawnObject(flag) end

                    if distance < Config.RenderMarkerDistance then
                        sleep = 0
                        local color = flag.color
                        DrawMarker(1, flag.coords.x, flag.coords.y, flag.coords.z - 3.0, 0, 0, 0, 0, 0, 0, Config.RadiusFlag * 2, Config.RadiusFlag * 2, 4.0, color[1], color[2], color[3], 120, false, false, 2, false, nil, nil, false)

                        if distance < Config.ActionDistance + 1.0 then
                            if flag.beingCaptured then
                                prompt = (flag.contested and L['contested'] or L['seconds_left']):format(flag.secondsLeft or 0)
                            elseif flag.gang == myGang then
                                prompt = L['your_flag']
                            else
                                prompt = ('%s · %s'):format(L['press_to_capture'], flag.label)
                                if IsControlJustPressed(0, 74) then -- H
                                    TriggerServerEvent('jj_flags:server:tryToCapture', flag.id)
                                end
                            end
                        end
                    end
                elseif distance > Config.RenderDistance * 1.5 then
                    deleteObject(flag)
                end
            end

            if not planting then setText(prompt) end
            Wait(sleep)
        end

        setText(nil)
        running = false
    end)
end

RegisterNetEvent('jj_flags:client:setFlags', function(list, gangId, settings)
    for _, flag in pairs(flags) do removeFlag(flag) end
    flags = {}
    myGang = gangId
    if settings and settings.radius then Config.RadiusFlag = settings.radius end

    for _, data in ipairs(list or {}) do
        data.coords = vec3(data.coords.x, data.coords.y, data.coords.z)
        flags[data.id] = data
        addBlip(data)
    end
    loop()
end)

RegisterNetEvent('jj_flags:client:updateFlag', function(data)
    if not myGang then return end
    data.coords = vec3(data.coords.x, data.coords.y, data.coords.z)

    local current = flags[data.id]
    if current then
        local changedGang = current.gang ~= data.gang
        data.object, data.blip = current.object, current.blip
        if changedGang then
            removeFlag(current)
            data.object, data.blip = nil, nil
            addBlip(data)
        end
    else
        addBlip(data)
    end

    flags[data.id] = data
    loop()
end)

RegisterNetEvent('jj_flags:client:setInMap', function(coords)
    SetNewWaypoint(coords.x, coords.y)
end)

-- Plantar: el servidor comprueba al final que no se ha movido
RegisterNetEvent('jj_flags:client:plant', function(seconds)
    if planting then return end
    planting = true

    local ped = cache.ped
    local start = GetEntityCoords(ped)
    FreezeEntityPosition(ped, true)
    pcall(lib.requestAnimDict, Config.PlantAnim.dict)
    TaskPlayAnim(ped, Config.PlantAnim.dict, Config.PlantAnim.anim, 2.0, 2.0, -1, 1, 0, false, false, false)

    local cancelled = false
    for remaining = seconds, 1, -1 do
        setText(L['planting']:format(remaining))
        Wait(1000)
        if LocalPlayer.state.isDead or #(GetEntityCoords(ped) - start) > 2.0 then
            cancelled = true
            break
        end
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    setText(nil)
    planting = false

    TriggerServerEvent(cancelled and 'jj_flags:server:cancelPlant' or 'jj_flags:server:plant')
end)

RegisterCommand(Config.PlantFlagCommand, function()
    TriggerServerEvent('jj_flags:server:requestPlant')
end, false)

-- Al entrar o salir de una banda cambian las banderas que se ven
RegisterNetEvent('jj_gangs:client:setGang', function()
    TriggerServerEvent('jj_flags:server:refresh')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and JJ.IsSpawned() then
        TriggerServerEvent('jj_flags:server:refresh')
    end
end)

-- Panel de administración. Mientras está abierto se refresca cada 2 segundos

local panelOpen = false

local function closePanel()
    panelOpen = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

RegisterNetEvent('jj_flags:client:openPanel', function()
    if panelOpen then return end

    local result = lib.callback.await('jj_flags:admin:state', false, {})
    if not result or result.error then
        return lib.notify({ description = result and result.error or 'No tienes permiso', type = 'error' })
    end

    panelOpen = true
    SendNUIMessage({ action = 'open', state = result.state })
    SetNuiFocus(true, true)

    CreateThread(function()
        while panelOpen do
            Wait(2000)
            if not panelOpen then break end
            local update = lib.callback.await('jj_flags:admin:state', false, {})
            if panelOpen and update and update.state then
                SendNUIMessage({ action = 'state', state = update.state })
            end
        end
    end)
end)

RegisterNUICallback('close', function(_, cb)
    closePanel()
    cb({ success = true })
end)

for _, name in ipairs({ 'start', 'stop', 'saveSettings', 'setExcluded', 'placeFlag', 'setOwner', 'cancelCapture', 'deleteFlag', 'deleteAll' }) do
    RegisterNUICallback(name, function(data, cb)
        local result = lib.callback.await('jj_flags:admin:' .. name, false, data)
        if not result or result.error then
            lib.notify({ description = result and result.error or 'No se ha podido hacer', type = 'error' })
            return cb({ success = false })
        end

        if result.message then lib.notify({ description = result.message, type = 'success' }) end
        cb({ success = true, state = result.state })
    end)
end

RegisterNUICallback('teleport', function(data, cb)
    cb({ success = true })
    local coords = data and data.coords
    if type(coords) ~= 'table' or not tonumber(coords.x) then return end

    closePanel()
    SetEntityCoords(cache.ped, coords.x + 2.0, coords.y, coords.z + 1.0, false, false, false, false)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if panelOpen then SetNuiFocus(false, false) end
    for _, flag in pairs(flags) do removeFlag(flag) end
    setText(nil)
    if planting then
        ClearPedTasks(cache.ped)
        FreezeEntityPosition(cache.ped, false)
    end
end)
