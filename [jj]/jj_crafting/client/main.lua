local benches = {}     -- id -> mesa
local props = {}       -- id -> objeto
local blips = {}       -- id -> blip
local permissions = {} -- id -> permisos del jugador
local moving = {}      -- id de la mesa que se está moviendo
local uiOpen = false
local currentBench = nil

exports.ox_inventory:displayMetadata('blueprint', 'Plano')

-- Nombre e imagen de un objeto, para la interfaz
local function itemInfo(name)
    local ok, item = pcall(function() return exports.ox_inventory:Items(name) end)
    if not ok or not item then
        ok, item = pcall(function() return exports.ox_inventory:Items(name:upper()) end)
    end
    item = ok and item or nil

    local image = item and item.client and item.client.image or ('%s.png'):format(item and item.name or name)
    return {
        label = item and item.label or name,
        description = item and item.description or nil,
        image = ('nui://ox_inventory/web/images/%s'):format(image),
    }
end

local function enrich(data)
    if type(data) ~= 'table' then return data end

    for _, recipe in ipairs(data.recipes or {}) do
        local info = itemInfo(recipe.name)
        recipe.label, recipe.image, recipe.description = info.label, info.image, info.description
        for _, ingredient in ipairs(recipe.ingredients) do
            local ingredientInfo = itemInfo(ingredient.name)
            ingredient.label, ingredient.image = ingredientInfo.label, ingredientInfo.image
        end
    end
    for _, job in ipairs(data.queue or {}) do
        local info = itemInfo(job.name)
        job.label, job.image = info.label, info.image
    end
    return data
end

local function can(id, flag)
    local perms = permissions[id]
    if not perms then return flag == 'canUse' end
    return perms[flag] == true or perms.isOwner == true
end

-- Interfaz

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    currentBench = nil
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

local function openBench(id)
    if uiOpen then return end
    if cache.vehicle then
        return JJ.Notify('No puedes hacerlo desde un vehículo', 'error')
    end

    local data, reason = lib.callback.await('jj_crafting:open', false, id)
    if not data then
        return JJ.Notify(reason or 'No puedes usar esta mesa', 'error')
    end

    uiOpen = true
    currentBench = id
    SendNUIMessage({ action = 'open', view = 'craft', data = enrich(data) })
    SetNuiFocus(true, true)
end

local function openManagement(id)
    if uiOpen then return end

    local data = lib.callback.await('jj_crafting:management', false, id)
    if not data then
        return JJ.Notify('No tienes permiso para gestionar esta mesa', 'error')
    end

    uiOpen = true
    currentBench = id
    SendNUIMessage({ action = 'open', view = 'manage', data = data })
    SetNuiFocus(true, true)
end

local function requestPack(id)
    local response = lib.callback.await('jj_crafting:preparePack', false, id)
    if not response or response.error then
        return JJ.Notify(response and response.error or 'No se puede recoger la mesa', 'error')
    end

    if response.confirm then
        local answer = lib.alertDialog({
            header = '¿Recoger la mesa?',
            content = 'El almacén tiene objetos. Al recogerla quedarán en el suelo.',
            centered = true,
            cancel = true,
            labels = { confirm = 'Recoger', cancel = 'Cancelar' },
        })
        if answer ~= 'confirm' then return end
    end

    TriggerServerEvent('jj_crafting:server:pack', id)
end

RegisterNUICallback('close', function(_, cb)
    closeUI()
    cb({ success = true })
end)

RegisterNUICallback('craft', function(data, cb)
    if not currentBench then return cb({ success = false }) end

    local result = lib.callback.await('jj_crafting:craft', false, currentBench, data.slot, data.amount)
    if result and result.error then JJ.Notify(result.error, 'error') end
    if result and result.made and result.made > 0 then
        JJ.Notify(result.made == 1 and 'Añadido a la cola' or ('%d trabajos añadidos a la cola'):format(result.made), 'success')
    end

    cb({ success = result ~= nil and (result.made or 0) > 0, data = result and result.id and enrich(result) or nil })
end)

RegisterNUICallback('cancel', function(data, cb)
    local result = lib.callback.await('jj_crafting:cancel', false, data.id)
    cb({ success = result ~= nil, data = result and result.id and enrich(result) or nil })
end)

RegisterNUICallback('openStorage', function(data, cb)
    cb({ success = true })
    local id = currentBench
    closeUI()
    if id then exports.ox_inventory:openInventory('stash', ('crafting:%s:1'):format(id)) end
end)

local function managementCallback(name)
    RegisterNUICallback(name, function(data, cb)
        if not currentBench then return cb({ success = false }) end

        data.benchId = currentBench
        local result = lib.callback.await('jj_crafting:' .. name, false, data)
        if not result or result.error then
            JJ.Notify(result and result.error or 'No se ha podido hacer', 'error')
            return cb({ success = false })
        end

        if result.transferred then
            JJ.Notify('La mesa ya no es tuya', 'success')
            closeUI()
            return cb({ success = true })
        end

        cb({ success = true, data = result })
    end)
end

for _, name in ipairs({ 'createRole', 'updateRole', 'deleteRole', 'setMember', 'transfer' }) do
    managementCallback(name)
end

RegisterNetEvent('jj_crafting:client:queue', function(queue)
    if not uiOpen then return end
    SendNUIMessage({ action = 'queue', data = enrich({ queue = queue }).queue })
end)

RegisterNetEvent('jj_crafting:client:xp', function(xp)
    if uiOpen then SendNUIMessage({ action = 'xp', data = xp }) end
end)

-- Panel de administración

local ADMIN_ACTIONS = {
    saveType = true, deleteType = true, saveRecipe = true, deleteRecipe = true,
    saveBlueprint = true, deleteBlueprint = true, giveBlueprint = true,
    savePoint = true, deletePoint = true, saveSettings = true, removePlaced = true,
}

-- Todos los objetos de ox_inventory, para elegirlos en el panel
local function itemList()
    local list = {}
    for name, item in pairs(exports.ox_inventory:Items() or {}) do
        local image = item.client and item.client.image or ('%s.png'):format(name)
        list[#list + 1] = { name = name, label = item.label or name, image = ('nui://ox_inventory/web/images/%s'):format(image) }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

RegisterNetEvent('jj_crafting:client:admin', function()
    if uiOpen then return end

    local result = lib.callback.await('jj_crafting:admin:get', false, {})
    if not result or result.error then
        return JJ.Notify(result and result.error or 'No tienes permiso', 'error')
    end

    uiOpen = true
    currentBench = nil
    SendNUIMessage({ action = 'open', view = 'admin', data = result.data, items = itemList() })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('admin', function(data, cb)
    local action = data and data.action
    if not ADMIN_ACTIONS[action] then return cb({ success = false }) end

    local result = lib.callback.await('jj_crafting:admin:' .. action, false, data.payload or {})
    if not result or result.error then
        JJ.Notify(result and result.error or 'No se ha podido guardar', 'error')
        return cb({ success = false })
    end

    JJ.Notify('Guardado', 'success')
    cb({ success = true, data = result.data })
end)

RegisterNUICallback('myPosition', function(_, cb)
    local coords = GetEntityCoords(cache.ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(cache.ped) })
end)

RegisterNUICallback('teleport', function(data, cb)
    cb({ success = true })
    if data and tonumber(data.x) then
        closeUI()
        SetEntityCoords(cache.ped, data.x + 0.0, data.y + 0.0, data.z + 1.0, false, false, false, false)
    end
end)

-- Mesas en el mundo

local function removeProp(id)
    local prop = props[id]
    if prop and DoesEntityExist(prop) then
        exports.ox_target:removeLocalEntity(prop)
        DeleteEntity(prop)
    end
    props[id] = nil
end

local function targetOptions(id)
    local bench = benches[id]
    local options = {
        {
            name = 'jj_crafting:open',
            icon = 'fas fa-hammer',
            label = bench.label,
            distance = 2.5,
            canInteract = function() return can(id, 'canUse') end,
            onSelect = function() openBench(id) end,
        },
    }

    if bench.dynamic then
        options[#options + 1] = {
            name = 'jj_crafting:manage',
            icon = 'fas fa-users-cog',
            label = 'Gestionar mesa',
            distance = 2.5,
            canInteract = function() return can(id, 'canManage') end,
            onSelect = function() openManagement(id) end,
        }
        options[#options + 1] = {
            name = 'jj_crafting:move',
            icon = 'fas fa-arrows-alt',
            label = 'Mover mesa',
            distance = 2.5,
            canInteract = function() return can(id, 'canMove') end,
            onSelect = function() TriggerServerEvent('jj_crafting:server:requestMove', id) end,
        }
        if bench.packing then
            options[#options + 1] = {
                name = 'jj_crafting:pack',
                icon = 'fas fa-box',
                label = 'Recoger mesa',
                distance = 2.5,
                canInteract = function() return can(id, 'canPack') end,
                onSelect = function() requestPack(id) end,
            }
        end
    end

    return options
end

local function spawnProp(id)
    local bench = benches[id]
    if not bench.model then return end

    local ok, model = pcall(lib.requestModel, bench.model)
    if not ok or not model then return end

    local coords = bench.coords
    local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if object == 0 then return end

    SetEntityHeading(object, bench.heading or 0.0)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    SetEntityInvincible(object, true)
    props[id] = object
    exports.ox_target:addLocalEntity(object, targetOptions(id))
end

-- Mesa sin modelo: se usa una zona de ox_target en su sitio
local zones = {}

local function setZone(id)
    if zones[id] then exports.ox_target:removeZone(zones[id]) end
    zones[id] = nil

    local bench = benches[id]
    if bench and not bench.model then
        zones[id] = exports.ox_target:addSphereZone({ coords = bench.coords, radius = 1.5, options = targetOptions(id) })
    end
end

local function setBlip(id)
    if blips[id] then RemoveBlip(blips[id]) end
    blips[id] = nil

    local bench = benches[id]
    local blip = bench and bench.blip
    if not blip then return end

    local handle = AddBlipForCoord(bench.coords.x, bench.coords.y, bench.coords.z)
    SetBlipSprite(handle, blip.id or 566)
    SetBlipColour(handle, blip.colour or 27)
    SetBlipScale(handle, blip.scale or 0.8)
    SetBlipAsShortRange(handle, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blip.name or bench.label)
    EndTextCommandSetBlipName(handle)
    blips[id] = handle
end

local function addBench(data)
    data.coords = vec3(data.coords.x, data.coords.y, data.coords.z)
    removeProp(data.id)
    benches[data.id] = data
    if data.permissions then
        permissions[data.id] = data.permissions
        data.permissions = nil
    end
    setZone(data.id)
    setBlip(data.id)
end

local function deleteBench(id)
    removeProp(id)
    if zones[id] then exports.ox_target:removeZone(zones[id]) end
    if blips[id] then RemoveBlip(blips[id]) end
    zones[id], blips[id], benches[id], permissions[id] = nil, nil, nil, nil
    if currentBench == id then closeUI() end
end

RegisterNetEvent('jj_crafting:client:benches', function(list)
    for id in pairs(benches) do deleteBench(id) end
    for _, data in ipairs(list) do addBench(data) end
end)

RegisterNetEvent('jj_crafting:client:bench', function(data)
    moving[data.id] = nil
    addBench(data)
end)

RegisterNetEvent('jj_crafting:client:removeBench', deleteBench)

RegisterNetEvent('jj_crafting:client:permissions', function(data)
    if data and data.id then
        permissions[data.id] = data
        if currentBench == data.id and not data.canUse then closeUI() end
    end
end)

-- Los objetos de las mesas solo existen cerca del jugador
CreateThread(function()
    while true do
        local position = GetEntityCoords(cache.ped)
        for id, bench in pairs(benches) do
            if bench.model and not moving[id] then
                local near = #(position - bench.coords) <= bench.spawnRange
                local prop = props[id]
                if near and not (prop and DoesEntityExist(prop)) then
                    spawnProp(id)
                elseif not near and prop then
                    removeProp(id)
                end
            end
        end
        Wait(1000)
    end
end)

-- Colocar y mover con el gizmo de ox_inventory

local function ghost(model, coords, heading)
    local ok, hash = pcall(lib.requestModel, model)
    if not ok or not hash then return nil end

    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    if object == 0 then return nil end

    SetEntityHeading(object, heading)
    SetEntityAlpha(object, 150, false)
    SetEntityCollision(object, false, false)
    return object
end

local function runGizmo(object, label)
    local confirmed = exports.ox_inventory:useGizmo(object, label) == true
    if not DoesEntityExist(object) then return nil end

    local coords, heading = GetEntityCoords(object), GetEntityHeading(object)
    DeleteObject(object)
    if not confirmed then return nil end
    return { coords = { x = coords.x, y = coords.y, z = coords.z }, heading = heading }
end

RegisterNetEvent('jj_crafting:client:place', function(data)
    local start = GetEntityCoords(cache.ped) + GetEntityForwardVector(cache.ped) * 2.0
    local object = ghost(data.model, start, GetEntityHeading(cache.ped))
    local result = object and runGizmo(object, data.label)

    if result then
        TriggerServerEvent('jj_crafting:server:place', result)
    else
        TriggerServerEvent('jj_crafting:server:cancelPlacement')
    end
end)

RegisterNetEvent('jj_crafting:client:move', function(data)
    local bench = benches[data.id]
    if not bench then return end

    moving[data.id] = true
    removeProp(data.id)

    local object = ghost(bench.model, bench.coords, bench.heading or 0.0)
    local result = object and runGizmo(object, bench.label)

    if result then
        TriggerServerEvent('jj_crafting:server:move', data.id, result)
    else
        moving[data.id] = nil
        TriggerServerEvent('jj_crafting:server:cancelMove', data.id)
    end
end)

-- Carga de mesas

local function requestBenches()
    TriggerServerEvent('jj_crafting:server:requestBenches')
end

RegisterNetEvent('jj_crafting:client:reload', requestBenches)
AddEventHandler('jj:client:playerSpawned', requestBenches)

-- Al cambiar de trabajo o de banda pueden cambiar las mesas que se usan
AddEventHandler('jj:client:playerDataChanged', function(key)
    if key == 'job' then requestBenches() end
end)
RegisterNetEvent('jj_gangs:client:setGang', function() requestBenches() end)

CreateThread(function()
    if JJ.IsSpawned() then requestBenches() end
end)

-- Las mesas de punto (las de banda) se marcan en el suelo para quien puede usarlas
CreateThread(function()
    while true do
        local sleep = 1000
        local position = GetEntityCoords(cache.ped)
        for id, bench in pairs(benches) do
            if bench.marker and can(id, 'canUse') then
                local distance = #(position - bench.coords)
                if distance < 15.0 then
                    sleep = 0
                    DrawMarker(27, bench.coords.x, bench.coords.y, bench.coords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.0, 168, 85, 247, 150, false, false, 2, true, nil, nil, false)
                end
            end
        end
        Wait(sleep)
    end
end)

-- Cerrar si se aleja de la mesa
CreateThread(function()
    while true do
        Wait(500)
        if uiOpen and currentBench then
            local bench = benches[currentBench]
            if not bench or #(GetEntityCoords(cache.ped) - bench.coords) > 5.0 then closeUI() end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for id in pairs(benches) do deleteBench(id) end
end)
