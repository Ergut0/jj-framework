local producing = {} -- [source] = { point, startedAt }
local lastSale = {}
local soldPeds = {} -- [netId] = hora de la última venta
local lastGangAlert = {} -- [id de banda] = hora del último aviso

-- Laboratorios

local function hasInputs(src, recipe)
    for _, input in ipairs(recipe.inputs) do
        if exports.ox_inventory:Search(src, 'count', input.item) < input.count then
            return false
        end
    end
    return true
end

local function getLab(src, pointId)
    local _, gang = GetMember(src)
    local point = gang and GetNearPoint(src, gang, pointId, 'lab')
    local recipe = point and Config.Labs[point.lab]
    if recipe then
        return point, recipe
    end
end

lib.callback.register('jj_gangs:server:startLab', function(source, pointId)
    local point, recipe = getLab(source, pointId)
    if not point then return { ok = false, message = 'No puedes usar este laboratorio' } end
    if not hasInputs(source, recipe) then return { ok = false, message = 'Te faltan materiales' } end

    producing[source] = { point = point.id, startedAt = GetGameTimer() }
    return { ok = true, label = recipe.label, time = recipe.time }
end)

lib.callback.register('jj_gangs:server:finishLab', function(source, pointId)
    local job = producing[source]
    producing[source] = nil

    local point, recipe = getLab(source, pointId)
    if not job or not point or job.point ~= point.id then return { ok = false } end
    -- La duración la cuenta el servidor: pedir el resultado antes de tiempo no da nada
    if GetGameTimer() - job.startedAt < recipe.time - 1000 then return { ok = false } end
    if not hasInputs(source, recipe) then return { ok = false, message = 'Te faltan materiales' } end

    if not exports.ox_inventory:CanCarryItem(source, recipe.output, recipe.amount) then
        return { ok = false, message = 'No puedes cargar con más' }
    end

    for _, input in ipairs(recipe.inputs) do
        exports.ox_inventory:RemoveItem(source, input.item, input.count)
    end
    exports.ox_inventory:AddItem(source, recipe.output, recipe.amount)
    return { ok = true, message = ('Has conseguido %d de %s'):format(recipe.amount, recipe.label) }
end)

RegisterNetEvent('jj_gangs:server:cancelLab', function()
    producing[source] = nil
end)

-- Venta a NPC

local function findDrug(src)
    local available = {}
    for item in pairs(Config.Drugs) do
        local count = exports.ox_inventory:Search(src, 'count', item)
        if count and count > 0 then
            available[#available + 1] = { item = item, count = count }
        end
    end
    if #available == 0 then return nil end
    return available[math.random(1, #available)]
end

-- El NPC tiene que existir y estar al lado. Los que no están en red solo los limita la espera del jugador
local function isValidPed(netId, coords)
    if type(netId) ~= 'number' or netId == 0 then return true end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return true end
    if GetEntityType(entity) ~= 1 or IsPedAPlayer(entity) then return false end
    return #(GetEntityCoords(entity) - coords) <= Config.Sale.MaxPedDistance
end

local function alertSale(gang, coords)
    local now = os.time()
    if lastGangAlert[gang.id] and now - lastGangAlert[gang.id] < Config.Sale.AlertCooldown then return end
    lastGangAlert[gang.id] = now
    AlertGang(gang.id, 'Barrio', 'Están vendiendo droga en vuestro barrio', coords)
end

lib.callback.register('jj_gangs:server:sell', function(source, netId)
    local player, sellerGang = GetMember(source)
    if not player then return { ok = false } end

    local coords = GetPedCoords(source)
    if not coords then return { ok = false } end
    if Config.Sale.BlockedJobs[player.getJob().name] then
        return { ok = false, message = 'No puedes hacer esto con tu trabajo' }
    end

    local now = os.time()
    if lastSale[source] and now - lastSale[source] < Config.Sale.Cooldown then
        return { ok = false, message = 'Espera un poco antes de volver a vender' }
    end
    if not isValidPed(netId, coords) then return { ok = false } end
    if type(netId) == 'number' and netId ~= 0 and soldPeds[netId] and now - soldPeds[netId] < Config.Sale.PedCooldown then
        return { ok = false, message = 'Esta persona ya te ha comprado' }
    end

    local drug = findDrug(source)
    if not drug then return { ok = false, message = 'No llevas droga' } end

    lastSale[source] = now
    if type(netId) == 'number' and netId ~= 0 then
        soldPeds[netId] = now
    end

    local territory = FindTerritory(coords)

    -- La venta se nota en el barrio aunque el NPC no quiera comprar
    if territory and (not sellerGang or territory.id ~= sellerGang.id) then
        alertSale(territory, coords)
    end

    if math.random(1, 100) <= Config.Sale.RejectChance then
        return { ok = true, sold = false, police = math.random(1, 100) <= Config.Sale.PoliceChance }
    end

    local units = math.random(1, math.min(Config.Sale.MaxUnits, drug.count))
    local definition = Config.Drugs[drug.item]
    local multiplier = Config.Sale.NeutralMultiplier
    if territory then
        multiplier = sellerGang and territory.id == sellerGang.id and Config.Sale.OwnMultiplier or Config.Sale.RivalMultiplier
    end
    local payment = 0
    for _ = 1, units do
        payment = payment + math.random(definition.min, definition.max)
    end
    payment = math.floor(payment * multiplier)

    if not exports.ox_inventory:RemoveItem(source, drug.item, units) then
        return { ok = false, message = 'No llevas droga' }
    end
    player.addMoney('black', payment, 'jj_gangs_sale')

    return {
        ok = true,
        sold = true,
        label = definition.label,
        units = units,
        payment = payment,
        rival = multiplier == Config.Sale.RivalMultiplier and territory ~= nil,
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    producing[src] = nil
    lastSale[src] = nil
end)
