-- Mesas de crafteo: recetas, cola, experiencia, planos, almacén y permisos.
-- Todo lo que decide qué se fabrica y quién puede tocar una mesa se comprueba aquí
local Inventory = exports.ox_inventory
-- La configuración vive en la base de datos y se edita con /crafteoadmin.
-- data/crafting.lua solo sirve para rellenarla la primera vez
local BenchTypes = {}    -- nombre -> tipo de mesa
local Recipes = {}       -- tipo -> id -> receta
local Blueprints = {}    -- nombre -> plano
local Points = {}        -- nombre -> mesa de punto fijo
local XPConfig = {}
local PackingConfig = {}

local USE_DISTANCE = 4.0      -- metros a la mesa para usarla
local PLACE_DISTANCE = 10.0   -- metros al jugador para colocarla o moverla
local MAX_QUEUE = 10          -- trabajos en cola por jugador
local MAX_ROLE_NAME = 32

local Benches = {}          -- id -> mesa
local Placed = {}           -- id -> { id = id en la base de datos, owner, roles }
local PlacementItems = {}   -- objeto -> tipo de mesa
local PendingPlacement = {} -- source -> { type, item, slot }
local AdminMovers = {}      -- id de mesa -> source del administrador que la mueve
local XPCache = {}
local Queues = {}           -- source -> trabajos
local nextJobId = 0

local function notify(src, message, kind)
    if src and src > 0 then JJ.Notify(src, message, kind or 'inform') end
end

local function getIdentifier(src)
    local player = JJ.GetPlayer(src)
    return player and player.identifier
end

local function getSourceByIdentifier(identifier)
    local player = identifier and JJ.GetPlayerByIdentifier(identifier)
    return player and player.source
end

local function storageId(benchId)
    -- Mismo nombre que usaba ox_inventory: así se conservan los almacenes que ya existen
    return ('crafting:%s:1'):format(benchId)
end

local function benchFromStorage(id)
    local benchId = type(id) == 'string' and id:match('^crafting:(.+):1$')
    return benchId and Benches[benchId] and benchId
end

local function toVector(value)
    if type(value) == 'vector3' then return value end
    if type(value) == 'table' then
        return vec3(tonumber(value.x) or 0.0, tonumber(value.y) or 0.0, tonumber(value.z) or 0.0)
    end
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    return ped and ped ~= 0 and GetEntityCoords(ped) or nil
end

local function isNear(src, coords, distance)
    local position = playerCoords(src)
    return position ~= nil and coords ~= nil and #(position - coords) <= distance
end

-- Trabajos de la mesa: { police = 0 } exige ese trabajo con ese grado o más
local function hasGroup(src, groups)
    if not groups then return true end

    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    local minimum = job and groups[job.name]
    return minimum ~= nil and job.grade >= minimum
end

-- Bandas de la mesa: true vale para cualquier banda; una lista, para esas bandas (por nombre o id)
local function hasGang(src, gangs)
    if not gangs then return true end
    if GetResourceState('jj_gangs') ~= 'started' then return false end

    local gang = exports.jj_gangs:getGang(src)
    if not gang then return false end
    return gangs == true or gangs[gang.label] == true or gangs[gang.id] == true
end

local function hasAccess(src, bench)
    return hasGroup(src, bench.groups) and hasGang(src, bench.gangs)
end

local function decode(value)
    if type(value) ~= 'string' then return value end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or nil
end

local function trim(value)
    return type(value) == 'string' and value:match('^%s*(.-)%s*$') or nil
end

-- Roles y permisos

local function asBool(value)
    return value == true or value == 1 or value == '1'
end

local function loadRoles(benchId)
    local record = Placed[benchId]
    if not record then return end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM ox_crafting_roles WHERE bench_id = ?', { record.id })
    if not count or count == 0 then
        MySQL.insert.await('INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, 1, 0, 0, 0)', { record.id, 'Miembro' })
        MySQL.insert.await('INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, 1, 1, 1, 1)', { record.id, 'Gestor' })
    end

    local roles, members = {}, {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM ox_crafting_roles WHERE bench_id = ? ORDER BY id', { record.id }) or {}) do
        roles[row.id] = {
            id = row.id,
            name = row.name,
            canUse = asBool(row.can_use),
            canMove = asBool(row.can_move),
            canPack = asBool(row.can_pack),
            canManage = asBool(row.can_manage),
            members = {},
        }
    end

    for _, row in ipairs(MySQL.query.await('SELECT * FROM ox_crafting_role_members WHERE bench_id = ?', { record.id }) or {}) do
        local role = roles[row.role_id]
        if role then
            role.members[#role.members + 1] = { identifier = row.identifier, addedBy = row.added_by }
            members[row.identifier] = row.role_id
        end
    end

    record.roles = { list = roles, members = members }
end

local function getPermissions(benchId, identifier)
    local record = Placed[benchId]
    if not record then
        -- Mesas fijas del mapa: solo cuentan los trabajos
        return { canUse = true, canMove = false, canPack = false, canManage = false, isOwner = false }
    end

    if identifier and record.owner == identifier then
        return { canUse = true, canMove = true, canPack = true, canManage = true, isOwner = true }
    end

    if not record.roles then loadRoles(benchId) end
    local roleId = identifier and record.roles.members[identifier]
    local role = roleId and record.roles.list[roleId]
    if not role then
        return { canUse = false, canMove = false, canPack = false, canManage = false, isOwner = false }
    end

    return { canUse = role.canUse, canMove = role.canMove, canPack = role.canPack, canManage = role.canManage, isOwner = false, roleId = role.id, roleName = role.name }
end

local PERMISSION_KEYS = { use = 'canUse', move = 'canMove', pack = 'canPack', manage = 'canManage', owner = 'isOwner' }

local function can(src, benchId, permission)
    return getPermissions(benchId, getIdentifier(src))[PERMISSION_KEYS[permission]] == true
end

local function sendPermissions(src, benchId)
    local permissions = getPermissions(benchId, getIdentifier(src))
    permissions.id = benchId
    TriggerClientEvent('jj_crafting:client:permissions', src, permissions)
end

-- Avisa a todos los conectados de sus permisos en una mesa
local function syncPermissions(benchId)
    for _, src in ipairs(JJ.GetPlayers()) do
        sendPermissions(src, benchId)
    end
end

-- Experiencia

local function getXP(identifier)
    if not XPConfig.enabled or not identifier then return 0 end
    if XPCache[identifier] == nil then
        XPCache[identifier] = MySQL.scalar.await('SELECT xp FROM ox_crafting_xp WHERE identifier = ?', { identifier }) or 0
    end
    return XPCache[identifier]
end

local function setXP(identifier, xp)
    XPCache[identifier] = xp
    MySQL.prepare.await('INSERT INTO ox_crafting_xp (identifier, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp)', { identifier, xp })

    local src = getSourceByIdentifier(identifier)
    if src then TriggerClientEvent('jj_crafting:client:xp', src, xp) end
end

local function addXP(identifier, amount)
    if XPConfig.enabled and identifier and amount and amount > 0 then
        setXP(identifier, getXP(identifier) + amount)
    end
end

-- Durabilidad: hasta 100 es un porcentaje; más de 100 es la hora en que se rompe, con degrade en minutos
local function durabilityPercent(item)
    local durability = item.metadata and item.metadata.durability
    if not durability then return 100 end
    if durability <= 100 then return math.max(0, durability) end

    local data = Inventory:Items(item.name)
    local degrade = item.metadata.degrade or (data and data.degrade)
    if not degrade or degrade <= 0 then return 0 end
    return math.max(0, (durability - os.time()) * 100 / (degrade * 60))
end

-- Gasta una fracción (0.05 = 5 %) de la durabilidad de un objeto. Si está apilado, separa uno
local function wear(inventory, item, fraction)
    local durability = item.metadata and item.metadata.durability or 100
    if durability > 100 then
        local data = Inventory:Items(item.name)
        local degrade = item.metadata.degrade or (data and data.degrade) or 0
        durability = durability - degrade * 60 * fraction
    else
        durability = durability - fraction * 100
    end
    durability = math.max(0, durability)

    if item.count > 1 then
        local metadata = table.clone(item.metadata or {})
        metadata.durability = durability
        Inventory:RemoveItem(inventory, item.name, 1, nil, item.slot)
        Inventory:AddItem(inventory, item.name, 1, metadata)
    else
        Inventory:SetDurability(inventory, item.slot, durability)
    end
end

-- Planos

local function findBlueprint(items, key)
    local blueprint = Blueprints[key]
    if not blueprint then return nil end

    for _, item in pairs(items) do
        if item.name == blueprint.item and durabilityPercent(item) > 0 then
            local value = blueprint.metadataKey and item.metadata and item.metadata[blueprint.metadataKey]
            if not blueprint.metadataKey or (value ~= nil and (not blueprint.metadataValue or value == blueprint.metadataValue)) then
                return item
            end
        end
    end
end

-- Cuántas veces se puede usar el plano antes de gastarse
local function blueprintUses(items, key)
    local item = findBlueprint(items, key)
    if not item then return 0 end

    local consume = tonumber(Blueprints[key].consume) or 0
    if consume <= 0 then return math.huge end
    return math.floor(durabilityPercent(item) / (consume * 100) + 1e-6)
end

local function giveBlueprint(target, key, value)
    local blueprint = Blueprints[key]
    if not blueprint or not blueprint.item then return false, 'Ese plano no existe' end

    local metadata = {}
    if blueprint.metadataKey then metadata[blueprint.metadataKey] = value or blueprint.metadataValue end

    local ok, reason = Inventory:AddItem(target, blueprint.item, 1, metadata)
    if not ok then return false, reason or 'No se ha podido dar el plano' end
    return true
end

-- Ingredientes

-- Elige de dónde sale cada ingrediente. Devuelve el plan o nil y el nombre del que falta.
-- Un ingrediente menor que 1 es una herramienta: gasta esa fracción de su durabilidad
local function planIngredients(items, ingredients)
    local plan = {}
    local used = {}

    for name, needs in pairs(ingredients) do
        if needs > 0 and needs < 1 then
            local found
            for _, item in pairs(items) do
                if item.name == name and not used[item.slot] and durabilityPercent(item) >= needs * 100 then
                    found = item
                    break
                end
            end
            if not found then return nil, name end
            used[found.slot] = true
            plan[#plan + 1] = { item = found, wear = needs }
        elseif needs >= 1 then
            local remaining = needs
            for _, item in pairs(items) do
                if remaining <= 0 then break end
                if item.name == name and not used[item.slot] then
                    local take = math.min(item.count, remaining)
                    remaining = remaining - take
                    used[item.slot] = true
                    plan[#plan + 1] = { item = item, count = take }
                end
            end
            if remaining > 0 then return nil, name end
        end
    end

    return plan
end

local function countItem(items, name)
    local total = 0
    for _, item in pairs(items) do
        if item.name == name then total = total + item.count end
    end
    return total
end

local function bestTool(items, name)
    local best = 0
    for _, item in pairs(items) do
        if item.name == name then best = math.max(best, durabilityPercent(item)) end
    end
    return best
end

-- Mesas

local function buildBench(id, data)
    local typeConfig = data.type and BenchTypes[data.type]
    if not typeConfig then
        warn(('No se ha podido crear la mesa "%s": el tipo "%s" no existe'):format(id, tostring(data.type)))
        return
    end

    local groups = data.groups
    if type(groups) == 'table' and #groups > 0 then
        local map = {}
        for _, name in ipairs(groups) do map[name] = 0 end
        groups = map
    end

    local gangs = data.gangs
    if type(gangs) == 'table' then
        local map = {}
        for _, value in ipairs(gangs) do map[value] = true end
        gangs = map
    elseif gangs ~= true then
        gangs = nil
    end

    local storage = typeConfig.storage or {}
    local bench = {
        id = id,
        type = data.type,
        label = data.label or typeConfig.label or data.type,
        model = data.model == nil and typeConfig.model or data.model,
        spawnRange = typeConfig.spawnRange or 50.0,
        coords = toVector(data.coords),
        heading = (tonumber(data.heading) or 0.0) + 0.0,
        groups = groups,
        gangs = gangs,
        blip = data.blip,
        dynamic = data.dynamic == true,
        source = data,
        hideLocked = typeConfig.hideLocked,
        slots = storage.slots or 30,
        maxWeight = storage.maxWeight or 100000,
    }

    Inventory:RegisterStash(storageId(id), ('Almacén · %s'):format(bench.label), bench.slots, bench.maxWeight, false, groups, bench.coords)
    Benches[id] = bench
    return bench
end

local function clientBench(bench)
    return {
        id = bench.id,
        type = bench.type,
        label = bench.label,
        model = bench.model,
        spawnRange = bench.spawnRange,
        coords = { x = bench.coords.x, y = bench.coords.y, z = bench.coords.z },
        heading = bench.heading,
        dynamic = bench.dynamic,
        blip = bench.blip,
        marker = not bench.model,
        packing = bench.dynamic and PackingConfig.enabled ~= false,
    }
end

local function broadcastBench(bench)
    TriggerClientEvent('jj_crafting:client:bench', -1, clientBench(bench))
    syncPermissions(bench.id)
end

local function removeBench(benchId)
    local bench, record = Benches[benchId], Placed[benchId]
    if not bench or not record then return false end

    local id = storageId(benchId)
    local items = Inventory:GetInventoryItems(id) or {}
    if next(items) then
        local drop = {}
        for _, item in pairs(items) do
            drop[#drop + 1] = { item.name, item.count, item.metadata }
        end
        Inventory:CustomDrop(bench.label, drop, bench.coords, bench.slots, bench.maxWeight)
    end
    Inventory:ClearInventory(id)

    Benches[benchId] = nil
    Placed[benchId] = nil
    MySQL.update.await('DELETE FROM ox_crafting_benches WHERE id = ?', { record.id })
    TriggerClientEvent('jj_crafting:client:removeBench', -1, benchId)
    return true, next(items) ~= nil
end

local function storageInUse(benchId)
    local inventory = Inventory:GetInventory(storageId(benchId))
    return inventory and inventory.openedBy and next(inventory.openedBy) ~= nil
end

local function placeRecord(row)
    local coords = decode(row.coords) or {}
    local benchId = ('placed:%s'):format(row.id)
    local bench = buildBench(benchId, {
        type = row.type,
        coords = coords,
        heading = coords.w,
        dynamic = true,
    })
    if not bench then return end

    Placed[benchId] = { id = row.id, owner = row.owner }
    loadRoles(benchId)
    return bench
end

-- Configuración en la base de datos

local function encode(value)
    if value == nil then return nil end
    return json.encode(value)
end

local function createConfigTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_crafting_settings` (
            `name` VARCHAR(32) NOT NULL,
            `value` LONGTEXT NOT NULL,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_crafting_types` (
            `name` VARCHAR(32) NOT NULL,
            `label` VARCHAR(64) NOT NULL,
            `model` VARCHAR(64) NULL,
            `spawn_range` FLOAT NOT NULL DEFAULT 50,
            `slots` INT NOT NULL DEFAULT 30,
            `max_weight` INT NOT NULL DEFAULT 100000,
            `placement_item` VARCHAR(64) NULL,
            `hide_locked` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_crafting_recipes` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `type` VARCHAR(32) NOT NULL,
            `item` VARCHAR(64) NOT NULL,
            `ingredients` LONGTEXT NOT NULL,
            `duration` INT NOT NULL DEFAULT 3000,
            `count_min` INT NOT NULL DEFAULT 1,
            `count_max` INT NOT NULL DEFAULT 1,
            `xp_required` INT NOT NULL DEFAULT 0,
            `xp_reward` INT NOT NULL DEFAULT 0,
            `blueprint` VARCHAR(32) NULL,
            `sort` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `idx_jj_crafting_recipes_type` (`type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_crafting_blueprints` (
            `name` VARCHAR(32) NOT NULL,
            `item` VARCHAR(64) NOT NULL,
            `metadata_key` VARCHAR(32) NULL,
            `metadata_value` VARCHAR(64) NULL,
            `consume` FLOAT NOT NULL DEFAULT 0,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_crafting_points` (
            `name` VARCHAR(32) NOT NULL,
            `type` VARCHAR(32) NOT NULL,
            `label` VARCHAR(64) NULL,
            `coords` LONGTEXT NOT NULL,
            `gangs` LONGTEXT NULL,
            `groups` LONGTEXT NULL,
            `blip` LONGTEXT NULL,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

local function saveSetting(name, value)
    MySQL.update.await('INSERT INTO jj_crafting_settings (name, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)', { name, json.encode(value) })
end

local function saveType(data)
    MySQL.update.await([[
        INSERT INTO jj_crafting_types (name, label, model, spawn_range, slots, max_weight, placement_item, hide_locked) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label), model = VALUES(model), spawn_range = VALUES(spawn_range), slots = VALUES(slots),
        max_weight = VALUES(max_weight), placement_item = VALUES(placement_item), hide_locked = VALUES(hide_locked)
    ]], { data.name, data.label, data.model, data.spawnRange, data.slots, data.maxWeight, data.placementItem, data.hideLocked and 1 or 0 })
end

local function saveRecipe(data)
    local values = { data.type, data.item, json.encode(data.ingredients), data.duration, data.countMin, data.countMax, data.xpRequired, data.xpReward, data.blueprint, data.sort }
    if data.id then
        values[#values + 1] = data.id
        MySQL.update.await([[
            UPDATE jj_crafting_recipes SET type = ?, item = ?, ingredients = ?, duration = ?, count_min = ?, count_max = ?,
            xp_required = ?, xp_reward = ?, blueprint = ?, sort = ? WHERE id = ?
        ]], values)
        return data.id
    end
    return MySQL.insert.await([[
        INSERT INTO jj_crafting_recipes (type, item, ingredients, duration, count_min, count_max, xp_required, xp_reward, blueprint, sort)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], values)
end

local function saveBlueprintConfig(data)
    MySQL.update.await([[
        INSERT INTO jj_crafting_blueprints (name, item, metadata_key, metadata_value, consume) VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE item = VALUES(item), metadata_key = VALUES(metadata_key), metadata_value = VALUES(metadata_value), consume = VALUES(consume)
    ]], { data.name, data.item, data.metadataKey, data.metadataValue, data.consume })
end

-- El blip no se toca desde el panel: se conserva el que tuviera
local function savePoint(data)
    MySQL.update.await([[
        INSERT INTO jj_crafting_points (name, type, label, coords, gangs, `groups`) VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE type = VALUES(type), label = VALUES(label), coords = VALUES(coords), gangs = VALUES(gangs), `groups` = VALUES(`groups`)
    ]], { data.name, data.type, data.label, json.encode(data.coords), encode(data.gangs), encode(data.groups) })
end

-- La primera vez se copia lo que había en data/crafting.lua
local function seedConfig()
    if (MySQL.scalar.await('SELECT COUNT(*) FROM jj_crafting_types') or 0) > 0 then return end

    local data = lib.load('data.crafting') or {}
    local xp, packing = data.xp or {}, data.packing or {}
    saveSetting('xp', { enabled = xp.enabled == true, hideLocked = xp.hideLocked == true, defaultReward = tonumber(xp.defaultReward) or 0 })
    saveSetting('packing', { enabled = packing.enabled ~= false, confirmWithItems = packing.confirmWithItems ~= false })

    for name, kind in pairs(data.types or {}) do
        local storage = kind.storage or {}
        saveType({
            name = name, label = kind.label or name, model = kind.model, spawnRange = kind.spawnRange or 50.0,
            slots = storage.slots or 30, maxWeight = storage.maxWeight or 100000,
            placementItem = kind.placement and kind.placement.item, hideLocked = kind.hideLocked == true,
        })
        for index, recipe in ipairs(kind.recipes or {}) do
            local count = recipe.count or 1
            saveRecipe({
                type = name, item = recipe.name, ingredients = recipe.ingredients or {}, duration = recipe.duration or 3000,
                countMin = type(count) == 'table' and count[1] or count, countMax = type(count) == 'table' and count[2] or count,
                xpRequired = recipe.xp and recipe.xp.required or 0, xpReward = recipe.xp and recipe.xp.reward or 0,
                blueprint = recipe.blueprint, sort = index,
            })
        end
    end

    for name, blueprint in pairs(data.blueprints or {}) do
        saveBlueprintConfig({ name = name, item = blueprint.item, metadataKey = blueprint.metadataKey, metadataValue = blueprint.metadataValue, consume = blueprint.consume or 0 })
    end

    for index, bench in ipairs(data.benches or {}) do
        if bench.coords then
            savePoint({
                name = bench.name or ('punto_%s'):format(index), type = bench.type, label = bench.label,
                coords = { x = bench.coords.x, y = bench.coords.y, z = bench.coords.z, w = bench.heading or 0.0 },
                gangs = bench.gangs, groups = bench.groups,
            })
        end
    end
end

local RecipeRows = {}

local function loadConfig()
    local settings = {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_crafting_settings') or {}) do
        settings[row.name] = decode(row.value)
    end
    XPConfig = settings.xp or { enabled = false }
    PackingConfig = settings.packing or { enabled = true, confirmWithItems = true }

    BenchTypes, PlacementItems = {}, {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_crafting_types') or {}) do
        BenchTypes[row.name] = {
            name = row.name,
            label = row.label,
            model = row.model,
            spawnRange = row.spawn_range,
            storage = { slots = row.slots, maxWeight = row.max_weight },
            placement = row.placement_item and { item = row.placement_item } or nil,
            hideLocked = row.hide_locked == 1 or row.hide_locked == true,
        }
        if row.placement_item then PlacementItems[row.placement_item] = row.name end
    end

    Recipes, RecipeRows = {}, {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_crafting_recipes ORDER BY sort, id') or {}) do
        RecipeRows[#RecipeRows + 1] = row
        Recipes[row.type] = Recipes[row.type] or {}
        Recipes[row.type][row.id] = {
            id = row.id,
            name = row.item,
            ingredients = decode(row.ingredients) or {},
            duration = row.duration,
            count = row.count_min == row.count_max and row.count_min or { row.count_min, row.count_max },
            xp = { required = row.xp_required, reward = row.xp_reward },
            blueprint = row.blueprint,
            sort = row.sort,
        }
    end

    Blueprints = {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_crafting_blueprints') or {}) do
        Blueprints[row.name] = { item = row.item, metadataKey = row.metadata_key, metadataValue = row.metadata_value, consume = row.consume }
    end

    Points = {}
    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_crafting_points') or {}) do
        local coords = decode(row.coords) or {}
        Points[row.name] = {
            name = row.name, type = row.type, label = row.label,
            coords = coords, heading = coords.w,
            gangs = decode(row.gangs), groups = decode(row.groups), blip = decode(row.blip),
        }
    end
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ox_crafting_benches` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `type` VARCHAR(64) NOT NULL,
            `owner` VARCHAR(64) NULL,
            `label` VARCHAR(64) NULL,
            `coords` JSON NOT NULL,
            `metadata` JSON NULL,
            `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ox_crafting_xp` (
            `identifier` VARCHAR(64) NOT NULL,
            `xp` INT NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ox_crafting_roles` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `bench_id` INT NOT NULL,
            `name` VARCHAR(64) NOT NULL,
            `can_use` TINYINT(1) NOT NULL DEFAULT 1,
            `can_move` TINYINT(1) NOT NULL DEFAULT 0,
            `can_pack` TINYINT(1) NOT NULL DEFAULT 0,
            `can_manage` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_crafting_roles_bench` (`bench_id`),
            CONSTRAINT `fk_crafting_roles_bench` FOREIGN KEY (`bench_id`) REFERENCES `ox_crafting_benches`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ox_crafting_role_members` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `bench_id` INT NOT NULL,
            `role_id` INT NOT NULL,
            `identifier` VARCHAR(64) NOT NULL,
            `added_by` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_role_members_bench` (`bench_id`),
            KEY `idx_role_members_role` (`role_id`),
            CONSTRAINT `fk_role_members_role` FOREIGN KEY (`role_id`) REFERENCES `ox_crafting_roles`(`id`) ON DELETE CASCADE,
            CONSTRAINT `fk_role_members_bench` FOREIGN KEY (`bench_id`) REFERENCES `ox_crafting_benches`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    createConfigTables()
    seedConfig()
    loadConfig()

    for name, point in pairs(Points) do
        buildBench(name, point)
    end

    for _, row in ipairs(MySQL.query.await('SELECT * FROM ox_crafting_benches') or {}) do
        placeRecord(row)
    end

    -- Quien ya estaba conectado al reiniciar el recurso recibe las mesas
    for _, src in ipairs(JJ.GetPlayers()) do
        TriggerClientEvent('jj_crafting:client:reload', src)
    end
end)

-- El almacén solo lo abre quien puede usar la mesa
Inventory:registerHook('openInventory', function(payload)
    local benchId = benchFromStorage(payload.inventoryId)
    if not benchId then return true end
    return hasAccess(payload.source, Benches[benchId]) and can(payload.source, benchId, 'use')
end, { inventoryFilter = { '^crafting:' } })

RegisterNetEvent('jj_crafting:server:requestBenches', function()
    local src = source
    local list = {}
    for benchId, bench in pairs(Benches) do
        local entry = clientBench(bench)
        entry.permissions = getPermissions(benchId, getIdentifier(src))
        -- Las mesas de una banda o un trabajo ni se ven en ox_target para los demás
        if not hasAccess(src, bench) then entry.permissions.canUse = false end
        list[#list + 1] = entry
    end
    TriggerClientEvent('jj_crafting:client:benches', src, list)
end)

-- Datos de la mesa para la interfaz

local function queuePayload(src)
    local out = {}
    for index, job in ipairs(Queues[src] or {}) do
        out[index] = {
            id = job.id,
            benchId = job.benchId,
            name = job.recipe.name,
            count = job.count,
            duration = job.duration,
            remaining = job.startedAt and math.max(0, job.startedAt + job.duration - os.time()) or nil,
        }
    end
    return out
end

local function sendQueue(src)
    TriggerClientEvent('jj_crafting:client:queue', src, queuePayload(src))
end

local function benchPayload(src, benchId)
    local bench = Benches[benchId]
    local items = Inventory:GetInventoryItems(storageId(benchId)) or {}
    local inventory = Inventory:GetInventory(storageId(benchId))
    local xp = getXP(getIdentifier(src))

    local recipes = {}
    for slot, recipe in pairs(Recipes[bench.type] or {}) do
        if not Inventory:Items(recipe.name) then goto continue end

        local ingredients = {}
        for name, needs in pairs(recipe.ingredients or {}) do
            local tool = needs < 1
            ingredients[#ingredients + 1] = {
                name = name,
                needs = tool and math.floor(needs * 100 + 0.5) or needs,
                have = tool and math.floor(bestTool(items, name)) or countItem(items, name),
                tool = tool,
            }
        end
        table.sort(ingredients, function(a, b) return a.name < b.name end)

        local required = recipe.xp and recipe.xp.required or 0
        local entry = {
            slot = slot,
            name = recipe.name,
            count = type(recipe.count) == 'table' and recipe.count or (recipe.count or 1),
            duration = (recipe.duration or 3000) / 1000,
            ingredients = ingredients,
            xpRequired = XPConfig.enabled and required or 0,
            xpReward = XPConfig.enabled and (recipe.xp and recipe.xp.reward or XPConfig.defaultReward or 0) or 0,
        }

        if recipe.blueprint then
            local uses = blueprintUses(items, recipe.blueprint)
            entry.blueprint = { key = recipe.blueprint, uses = uses == math.huge and -1 or uses }
        end

        entry.sort = recipe.sort or 0
        if not (XPConfig.enabled and (bench.hideLocked or XPConfig.hideLocked) and xp < required) then
            recipes[#recipes + 1] = entry
        end

        ::continue::
    end
    table.sort(recipes, function(a, b)
        if a.sort ~= b.sort then return a.sort < b.sort end
        return a.slot < b.slot
    end)

    return {
        id = benchId,
        label = bench.label,
        storage = {
            id = storageId(benchId),
            weight = inventory and inventory.weight or 0,
            maxWeight = bench.maxWeight,
        },
        xp = { enabled = XPConfig.enabled == true, current = xp },
        recipes = recipes,
        queue = queuePayload(src),
        permissions = getPermissions(benchId, getIdentifier(src)),
    }
end

local function checkUse(src, benchId)
    local bench = type(benchId) == 'string' and Benches[benchId]
    if not bench then return nil, 'Mesa no encontrada' end
    if not isNear(src, bench.coords, USE_DISTANCE) then return nil, 'Estás demasiado lejos de la mesa' end
    if not hasGroup(src, bench.groups) then return nil, 'Esta mesa no es para tu trabajo' end
    if not hasGang(src, bench.gangs) then return nil, 'Esta mesa es de una banda' end
    if not can(src, benchId, 'use') then return nil, 'No tienes permiso para usar esta mesa' end
    return bench
end

lib.callback.register('jj_crafting:open', function(source, benchId)
    local bench, reason = checkUse(source, benchId)
    if not bench then return nil, reason end
    return benchPayload(source, benchId)
end)

-- Cola de fabricación

local completeJob

local function startNext(src)
    local queue = Queues[src]
    local job = queue and queue[1]
    if not job or job.startedAt then return end

    job.startedAt = os.time()
    SetTimeout(job.duration * 1000, function()
        completeJob(src, job.id)
    end)
end

completeJob = function(src, jobId)
    local queue = Queues[src]
    if not queue or not queue[1] or queue[1].id ~= jobId then return end

    local job = table.remove(queue, 1)
    local bench = Benches[job.benchId]
    local name = job.recipe.name
    local metadata = job.recipe.metadata or {}

    -- El resultado va al almacén. Si no cabe, al jugador, y si tampoco, al suelo junto a la mesa
    -- Si han recogido la mesa mientras tanto, su almacén ya no cuenta
    local added = bench and Inventory:AddItem(job.storage, name, job.count, metadata)
    if not added and GetPlayerName(src) then
        added = Inventory:AddItem(src, name, job.count, metadata)
    end
    if not added then
        local coords = bench and bench.coords or job.coords
        Inventory:CustomDrop('Crafteo', { { name, job.count, metadata } }, coords)
    end

    addXP(job.identifier, job.xpReward)

    if GetPlayerName(src) then
        local item = Inventory:Items(name)
        notify(src, ('Fabricado: %s x%d'):format(item and item.label or name, job.count), 'success')
        sendQueue(src)
    end

    startNext(src)
end

local function craftOnce(src, bench, recipe, recipeSlot, identifier)
    local storage = storageId(bench.id)
    local items = Inventory:GetInventoryItems(storage) or {}

    local required = recipe.xp and recipe.xp.required or 0
    if XPConfig.enabled and getXP(identifier) < required then
        return false, ('Necesitas %d de experiencia'):format(required)
    end

    if recipe.blueprint and blueprintUses(items, recipe.blueprint) < 1 then
        return false, 'Falta el plano en el almacén de la mesa'
    end

    local plan, missing = planIngredients(items, recipe.ingredients or {})
    if not plan then
        local item = Inventory:Items(missing)
        return false, ('Falta %s en el almacén de la mesa'):format(item and item.label or missing)
    end

    for _, step in ipairs(plan) do
        if step.wear then
            wear(storage, step.item, step.wear)
        elseif not Inventory:RemoveItem(storage, step.item.name, step.count, nil, step.item.slot) then
            return false, 'No se han podido usar los materiales'
        end
    end

    if recipe.blueprint then
        local blueprint = findBlueprint(items, recipe.blueprint)
        local consume = tonumber(Blueprints[recipe.blueprint].consume) or 0
        if blueprint and consume > 0 then wear(storage, blueprint, consume) end
    end

    local count = recipe.count or 1
    if type(count) == 'table' then count = math.random(count[1], count[2]) end

    nextJobId = nextJobId + 1
    local queue = Queues[src] or {}
    Queues[src] = queue
    queue[#queue + 1] = {
        id = nextJobId,
        benchId = bench.id,
        storage = storage,
        coords = bench.coords,
        recipe = recipe,
        recipeSlot = recipeSlot,
        count = count,
        duration = (recipe.duration or 3000) / 1000,
        identifier = identifier,
        xpReward = recipe.xp and recipe.xp.reward or XPConfig.defaultReward or 0,
    }
    return true
end

lib.callback.register('jj_crafting:craft', function(source, benchId, recipeSlot, amount)
    local bench, reason = checkUse(source, benchId)
    if not bench then return { error = reason } end

    local recipe = type(recipeSlot) == 'number' and (Recipes[bench.type] or {})[recipeSlot]
    if not recipe then return { error = 'Esa receta no existe' } end

    amount = math.tointeger(tonumber(amount)) or 1
    local queued = #(Queues[source] or {})
    if amount < 1 or queued + amount > MAX_QUEUE then
        return { error = ('Solo puedes tener %d trabajos en cola'):format(MAX_QUEUE) }
    end

    local identifier = getIdentifier(source)
    local made, err = 0, nil
    for _ = 1, amount do
        local ok, message = craftOnce(source, bench, recipe, recipeSlot, identifier)
        if not ok then
            err = message
            break
        end
        made = made + 1
    end

    if made > 0 then
        startNext(source)
        sendQueue(source)
    end

    local payload = benchPayload(source, benchId)
    payload.error = err
    payload.made = made
    return payload
end)

-- Cancelar devuelve los materiales al almacén. El desgaste de herramientas y planos no se devuelve
lib.callback.register('jj_crafting:cancel', function(source, jobId)
    local queue = Queues[source]
    if not queue then return nil end

    for index, job in ipairs(queue) do
        if job.id == jobId then
            table.remove(queue, index)
            for name, needs in pairs(job.recipe.ingredients or {}) do
                if needs >= 1 and not Inventory:AddItem(job.storage, name, needs) then
                    Inventory:AddItem(source, name, needs)
                end
            end

            -- Si era el que estaba en marcha, su temporizador ya no encuentra nada y empieza el siguiente
            startNext(source)
            sendQueue(source)

            local bench = Benches[job.benchId]
            return bench and benchPayload(source, job.benchId) or {}
        end
    end
end)

-- Colocar, mover y recoger mesas

AddEventHandler('ox_inventory:usedItem', function(inventoryId, itemName, slot, _, src)
    local typeName = PlacementItems[itemName]
    if not typeName or type(src) ~= 'number' or inventoryId ~= src then return end

    local typeConfig = BenchTypes[typeName]
    PendingPlacement[src] = { type = typeName, item = itemName, slot = slot }
    TriggerClientEvent('jj_crafting:client:place', src, {
        type = typeName,
        model = typeConfig.model,
        label = typeConfig.label or typeName,
    })
end)

RegisterNetEvent('jj_crafting:server:cancelPlacement', function()
    PendingPlacement[source] = nil
end)

RegisterNetEvent('jj_crafting:server:place', function(data)
    local src = source
    local pending = PendingPlacement[src]
    PendingPlacement[src] = nil
    if not pending or type(data) ~= 'table' then return end

    local coords = toVector(data.coords)
    if not coords or not isNear(src, coords, PLACE_DISTANCE) then
        return notify(src, 'Tienes que colocarla cerca de ti', 'error')
    end

    if not Inventory:RemoveItem(src, pending.item, 1, nil, pending.slot) then
        return notify(src, 'Ya no tienes la mesa', 'error')
    end

    local typeConfig = BenchTypes[pending.type]
    local heading = (tonumber(data.heading) or 0.0) % 360.0
    local label = typeConfig.label or pending.type
    local id = MySQL.insert.await('INSERT INTO ox_crafting_benches (type, owner, label, coords, metadata) VALUES (?, ?, ?, ?, ?)', {
        pending.type, getIdentifier(src), label,
        json.encode({ x = coords.x, y = coords.y, z = coords.z, w = heading }),
        json.encode({ name = label }),
    })

    local bench = id and placeRecord({ id = id, type = pending.type, label = label, owner = getIdentifier(src), coords = { x = coords.x, y = coords.y, z = coords.z, w = heading } })
    if not bench then
        Inventory:AddItem(src, pending.item, 1)
        return notify(src, 'No se ha podido colocar la mesa', 'error')
    end

    broadcastBench(bench)
    notify(src, 'Mesa colocada', 'success')
end)

RegisterNetEvent('jj_crafting:server:requestMove', function(benchId)
    local src = source
    local bench = Benches[benchId]
    if not bench or not bench.dynamic or not can(src, benchId, 'move') or not isNear(src, bench.coords, USE_DISTANCE) then return end

    AdminMovers[benchId] = src
    TriggerClientEvent('jj_crafting:client:move', src, clientBench(bench))
end)

local function moveBench(benchId, coords, heading)
    local bench, record = Benches[benchId], Placed[benchId]
    bench.coords = coords
    bench.heading = heading
    MySQL.update.await('UPDATE ox_crafting_benches SET coords = ? WHERE id = ?', {
        json.encode({ x = coords.x, y = coords.y, z = coords.z, w = heading }), record.id,
    })
    Inventory:RegisterStash(storageId(benchId), ('Almacén · %s'):format(bench.label), bench.slots, bench.maxWeight, false, bench.groups, coords)
    broadcastBench(bench)
end

RegisterNetEvent('jj_crafting:server:move', function(benchId, data)
    local src = source
    local bench = Benches[benchId]
    if not bench or not Placed[benchId] or AdminMovers[benchId] ~= src or type(data) ~= 'table' then return end
    AdminMovers[benchId] = nil

    local coords = toVector(data.coords)
    if not coords or not isNear(src, coords, PLACE_DISTANCE) then
        TriggerClientEvent('jj_crafting:client:bench', src, clientBench(bench))
        return notify(src, 'Tienes que dejarla cerca de ti', 'error')
    end

    moveBench(benchId, coords, (tonumber(data.heading) or 0.0) % 360.0)
end)

RegisterNetEvent('jj_crafting:server:cancelMove', function(benchId)
    if AdminMovers[benchId] == source then AdminMovers[benchId] = nil end
end)

lib.callback.register('jj_crafting:preparePack', function(source, benchId)
    if PackingConfig.enabled == false then return { error = 'No se pueden recoger mesas' } end

    local bench = Benches[benchId]
    if not bench or not Placed[benchId] then return { error = 'Mesa no encontrada' } end
    if not can(source, benchId, 'pack') then return { error = 'No tienes permiso para recoger esta mesa' } end
    if storageInUse(benchId) then return { error = 'Alguien está usando el almacén' } end

    local items = Inventory:GetInventoryItems(storageId(benchId)) or {}
    return { confirm = next(items) ~= nil and PackingConfig.confirmWithItems ~= false }
end)

RegisterNetEvent('jj_crafting:server:pack', function(benchId)
    local src = source
    local bench = Benches[benchId]
    if PackingConfig.enabled == false or not bench or not Placed[benchId] then return end
    if not can(src, benchId, 'pack') or not isNear(src, bench.coords, USE_DISTANCE) then return end
    if storageInUse(benchId) then return notify(src, 'Alguien está usando el almacén', 'error') end

    local typeConfig = BenchTypes[bench.type]
    if not typeConfig or not typeConfig.placement then
        return notify(src, 'Esta mesa ya no se puede recoger', 'error')
    end
    if not Inventory:AddItem(src, typeConfig.placement.item, 1) then
        return notify(src, 'No te cabe la mesa', 'error')
    end

    local _, dropped = removeBench(benchId)
    notify(src, dropped and 'Mesa recogida. Lo que había en el almacén ha quedado en el suelo' or 'Mesa recogida', 'success')
end)

-- Gestión de la mesa

local function onlinePlayers(origin, radius)
    local list = {}
    for _, src in ipairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        if player and (not origin or isNear(src, origin, radius)) then
            list[#list + 1] = { source = src, identifier = player.identifier, name = player.getName() }
        end
    end
    return list
end

local function managementPayload(src, benchId)
    local bench, record = Benches[benchId], Placed[benchId]
    local identifier = getIdentifier(src)
    local permissions = getPermissions(benchId, identifier)
    if not bench or not record or not permissions.canManage then return nil end

    if not record.roles then loadRoles(benchId) end

    local names = {}
    for _, player in ipairs(onlinePlayers()) do names[player.identifier] = player end

    local roles = {}
    for _, role in pairs(record.roles.list) do
        local members = {}
        for _, member in ipairs(role.members) do
            local online = names[member.identifier]
            members[#members + 1] = { identifier = member.identifier, name = online and online.name or member.identifier, online = online ~= nil }
        end
        table.sort(members, function(a, b) return a.name < b.name end)
        roles[#roles + 1] = {
            id = role.id, name = role.name, members = members,
            canUse = role.canUse, canMove = role.canMove, canPack = role.canPack, canManage = role.canManage,
        }
    end
    table.sort(roles, function(a, b) return a.id < b.id end)

    local nearby = {}
    for _, player in ipairs(onlinePlayers(bench.coords, 10.0)) do
        if player.identifier ~= record.owner then
            nearby[#nearby + 1] = { id = player.source, name = player.name, roleId = record.roles.members[player.identifier] }
        end
    end

    local owner = names[record.owner]
    return {
        id = benchId,
        label = bench.label,
        owner = owner and owner.name or record.owner,
        isOwner = permissions.isOwner,
        roles = roles,
        nearby = nearby,
    }
end

local function managed(src, data)
    local benchId = type(data) == 'table' and data.benchId
    local record = benchId and Placed[benchId]
    if not record or not can(src, benchId, 'manage') then return nil end
    if not record.roles then loadRoles(benchId) end
    return benchId, record
end

local function afterChange(src, benchId)
    loadRoles(benchId)
    syncPermissions(benchId)
    return managementPayload(src, benchId)
end

local function permissionValues(permissions)
    permissions = type(permissions) == 'table' and permissions or {}
    return permissions.use and 1 or 0, permissions.move and 1 or 0, permissions.pack and 1 or 0, permissions.manage and 1 or 0
end

local function roleName(value)
    local name = trim(value) or ''
    if name == '' then name = 'Rol' end
    if utf8.len(name) == nil or utf8.len(name) > MAX_ROLE_NAME or name:find('[%c<>]') then return nil end
    return name
end

lib.callback.register('jj_crafting:management', function(source, benchId)
    return managementPayload(source, benchId)
end)

lib.callback.register('jj_crafting:createRole', function(source, data)
    local benchId, record = managed(source, data)
    if not benchId then return { error = 'No tienes permiso' } end
    local name = roleName(data.name)
    if not name then return { error = ('El nombre debe tener hasta %d letras'):format(MAX_ROLE_NAME) } end

    local use, move, pack, manage = permissionValues(data.permissions)
    MySQL.insert.await('INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)', { record.id, name, use, move, pack, manage })
    return afterChange(source, benchId)
end)

lib.callback.register('jj_crafting:updateRole', function(source, data)
    local benchId, record = managed(source, data)
    if not benchId then return { error = 'No tienes permiso' } end
    local name = roleName(data.name)
    if not name then return { error = ('El nombre debe tener hasta %d letras'):format(MAX_ROLE_NAME) } end
    if not record.roles.list[data.roleId] then return { error = 'Ese rol no existe' } end

    local use, move, pack, manage = permissionValues(data.permissions)
    MySQL.update.await('UPDATE ox_crafting_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ? AND bench_id = ?', { name, use, move, pack, manage, data.roleId, record.id })
    return afterChange(source, benchId)
end)

lib.callback.register('jj_crafting:deleteRole', function(source, data)
    local benchId, record = managed(source, data)
    if not benchId then return { error = 'No tienes permiso' } end
    local role = record.roles.list[data.roleId]
    if not role then return { error = 'Ese rol no existe' } end
    if #role.members > 0 then return { error = 'Quita antes a los miembros de este rol' } end

    MySQL.update.await('DELETE FROM ox_crafting_roles WHERE id = ? AND bench_id = ?', { data.roleId, record.id })
    return afterChange(source, benchId)
end)

-- Asigna un rol a un jugador cercano (por su id) o quita a un miembro (por su identificador)
lib.callback.register('jj_crafting:setMember', function(source, data)
    local benchId, record = managed(source, data)
    if not benchId then return { error = 'No tienes permiso' } end

    local identifier
    if type(data.target) == 'number' then
        local player = JJ.GetPlayer(data.target)
        if not player or not isNear(data.target, Benches[benchId].coords, 10.0) then return { error = 'Esa persona no está cerca de la mesa' } end
        identifier = player.identifier
    elseif type(data.identifier) == 'string' then
        identifier = data.identifier
    end
    if not identifier or identifier == record.owner then return { error = 'No se puede cambiar a esa persona' } end

    if data.roleId ~= nil and not record.roles.list[data.roleId] then return { error = 'Ese rol no existe' } end

    MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, identifier })
    if data.roleId ~= nil then
        MySQL.insert.await('INSERT INTO ox_crafting_role_members (bench_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)', { record.id, data.roleId, identifier, getIdentifier(source) })
    end
    return afterChange(source, benchId)
end)

lib.callback.register('jj_crafting:transfer', function(source, data)
    local benchId, record = managed(source, data)
    if not benchId or record.owner ~= getIdentifier(source) then return { error = 'Solo el dueño puede regalar la mesa' } end

    local target = type(data.target) == 'number' and JJ.GetPlayer(data.target)
    if not target or not isNear(data.target, Benches[benchId].coords, 10.0) then return { error = 'Esa persona no está cerca de la mesa' } end
    if target.identifier == record.owner then return { error = 'Ya es suya' } end

    MySQL.update.await('UPDATE ox_crafting_benches SET owner = ? WHERE id = ?', { target.identifier, record.id })
    MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, target.identifier })
    record.owner = target.identifier
    loadRoles(benchId)
    syncPermissions(benchId)
    return { transferred = true }
end)

-- Limpieza

AddEventHandler('jj:server:playerDropped', function(src)
    PendingPlacement[src] = nil
    for benchId, mover in pairs(AdminMovers) do
        if mover == src then AdminMovers[benchId] = nil end
    end
end)

-- Los trabajos en cola siguen aunque el jugador se vaya: el resultado acaba en el almacén.
-- La cola se borra cuando se termina el último
CreateThread(function()
    while true do
        Wait(60000)
        for src, queue in pairs(Queues) do
            if #queue == 0 and not GetPlayerName(src) then Queues[src] = nil end
        end
    end
end)

-- Administración

RegisterCommand('darplano', function(src, args)
    if src ~= 0 and not JJ.IsAdmin(src) then return notify(src, 'No tienes permiso para usar este comando', 'error') end

    local target = tonumber(args[1])
    local ok, reason = false, 'Uso: /darplano <id> <plano>'
    if target and JJ.GetPlayer(target) and args[2] then
        ok, reason = giveBlueprint(target, args[2], args[3])
    end

    local message = ok and ('Plano %s entregado'):format(args[2]) or reason
    if src == 0 then print(('[jj_crafting] %s'):format(message)) else notify(src, message, ok and 'success' or 'error') end
    if ok then notify(target, 'Has recibido un plano', 'inform') end
end, false)

exports('giveBlueprintToPlayer', giveBlueprint)

exports('GetCraftingXP', function(identifier)
    return type(identifier) == 'string' and getXP(identifier) or 0
end)

exports('SetCraftingXP', function(identifier, xp)
    if type(identifier) ~= 'string' then return false end
    xp = math.max(0, math.floor(tonumber(xp) or 0))
    setXP(identifier, xp)
    return true, xp
end)

exports('RemovePlacedBench', function(benchId)
    if storageInUse(benchId) then return false, 'storage_in_use' end
    return removeBench(benchId) and true or false
end)

local function adminView(benchId)
    local bench, record = Benches[benchId], Placed[benchId]
    if not bench or not record then return nil end
    if not record.roles then loadRoles(benchId) end

    local roles = {}
    for _, role in pairs(record.roles.list) do
        roles[#roles + 1] = { id = role.id, name = role.name, canUse = role.canUse, canMove = role.canMove, canPack = role.canPack, canManage = role.canManage, members = role.members }
    end
    table.sort(roles, function(a, b) return a.id < b.id end)

    return {
        id = benchId, persistentId = record.id, label = bench.label, type = bench.type, owner = record.owner,
        coords = { x = bench.coords.x, y = bench.coords.y, z = bench.coords.z }, heading = bench.heading,
        roles = roles, storage = storageId(benchId),
    }
end

-- Mismo uso que el export de ox_inventory, para paneles de administración
exports('AdminBench', function(action, benchId, data, actor)
    data = type(data) == 'table' and data or {}

    if action == 'list' then
        local list = {}
        for id in pairs(Placed) do list[#list + 1] = adminView(id) end
        return list
    end

    local record = benchId and Placed[benchId]
    if not record then return false, 'not_found' end

    if action == 'get' then return adminView(benchId) end

    if action == 'createRole' or action == 'updateRole' then
        local use, move, pack, manage = permissionValues(data.permissions)
        local name = roleName(data.name) or 'Rol'
        if action == 'createRole' then
            MySQL.insert.await('INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)', { record.id, name, use, move, pack, manage })
        else
            MySQL.update.await('UPDATE ox_crafting_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ? AND bench_id = ?', { name, use, move, pack, manage, tonumber(data.roleId), record.id })
        end
    elseif action == 'deleteRole' then
        MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND role_id = ?', { record.id, tonumber(data.roleId) })
        MySQL.update.await('DELETE FROM ox_crafting_roles WHERE id = ? AND bench_id = ?', { tonumber(data.roleId), record.id })
    elseif action == 'setMember' then
        local identifier = trim(data.identifier)
        if not identifier or identifier == '' then return false, 'invalid_member' end
        MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, identifier })
        if tonumber(data.roleId) then
            MySQL.insert.await('INSERT INTO ox_crafting_role_members (bench_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)', { record.id, tonumber(data.roleId), identifier, 'admin' })
        end
    elseif action == 'transfer' then
        local identifier = trim(data.identifier)
        if not identifier or identifier == '' then return false, 'invalid_member' end
        MySQL.update.await('UPDATE ox_crafting_benches SET owner = ? WHERE id = ?', { identifier, record.id })
        MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, identifier })
        record.owner = identifier
    elseif action == 'move' then
        local coords = toVector(data.coords)
        if not coords then return false, 'invalid_position' end
        moveBench(benchId, coords, (tonumber(data.heading) or 0.0) % 360.0)
    elseif action == 'gizmo' then
        if not actor then return false, 'no_actor' end
        AdminMovers[benchId] = actor
        TriggerClientEvent('jj_crafting:client:move', actor, clientBench(Benches[benchId]))
        return true
    elseif action == 'remove' then
        if storageInUse(benchId) then return false, 'storage_in_use' end
        removeBench(benchId)
        return true
    else
        return false, 'unknown_action'
    end

    loadRoles(benchId)
    syncPermissions(benchId)
    return true, adminView(benchId)
end)

-- Panel de administración: /crafteoadmin. Todo lo que llega del panel se comprueba aquí

local MAX_INGREDIENTS = 12

local function validName(value)
    return type(value) == 'string' and #value >= 1 and #value <= 32 and value:match('^[%w_]+$') ~= nil
end

local function cleanText(value, max)
    local text = trim(value)
    if not text or text == '' then return nil end
    local length = utf8.len(text)
    if not length or length > max or text:find('[%c<>]') then return nil end
    return text
end

local function itemExists(name)
    return type(name) == 'string' and Inventory:Items(name) ~= nil
end

local function int(value, min, max)
    local number = math.tointeger(tonumber(value))
    if not number or number < min or number > max then return nil end
    return number
end

local function num(value, min, max)
    local number = tonumber(value)
    if not number or number ~= number or number < min or number > max then return nil end
    return number
end

local function gangList()
    if GetResourceState('jj_gangs') ~= 'started' then return {} end
    local ok, rows = pcall(MySQL.query.await, 'SELECT id, label FROM jj_gangs ORDER BY label')
    return ok and rows or {}
end

local function jobList()
    local list = {}
    for name, job in pairs(JJ.GetJobs()) do
        list[#list + 1] = { name = name, label = job.label or name }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

local function adminData()
    local types = {}
    for name, kind in pairs(BenchTypes) do
        local count = 0
        for _ in pairs(Recipes[name] or {}) do count = count + 1 end
        types[#types + 1] = {
            name = name, label = kind.label, model = kind.model, spawnRange = kind.spawnRange,
            slots = kind.storage.slots, maxWeight = kind.storage.maxWeight,
            placementItem = kind.placement and kind.placement.item or nil, hideLocked = kind.hideLocked, recipes = count,
        }
    end
    table.sort(types, function(a, b) return a.label < b.label end)

    local recipes = {}
    for _, row in ipairs(RecipeRows) do
        local ingredients = {}
        for name, amount in pairs(decode(row.ingredients) or {}) do
            local tool = amount < 1
            ingredients[#ingredients + 1] = { name = name, tool = tool, amount = tool and math.floor(amount * 100 + 0.5) or amount }
        end
        table.sort(ingredients, function(a, b) return a.name < b.name end)
        recipes[#recipes + 1] = {
            id = row.id, type = row.type, item = row.item, ingredients = ingredients, duration = row.duration / 1000,
            countMin = row.count_min, countMax = row.count_max, xpRequired = row.xp_required, xpReward = row.xp_reward,
            blueprint = row.blueprint, sort = row.sort,
        }
    end

    local blueprints = {}
    for name, blueprint in pairs(Blueprints) do
        blueprints[#blueprints + 1] = {
            name = name, item = blueprint.item, metadataKey = blueprint.metadataKey, metadataValue = blueprint.metadataValue,
            consume = math.floor((blueprint.consume or 0) * 1000 + 0.5) / 10,
        }
    end
    table.sort(blueprints, function(a, b) return a.name < b.name end)

    local points = {}
    for name, point in pairs(Points) do
        local coords = point.coords or {}
        points[#points + 1] = {
            name = name, type = point.type, label = point.label,
            x = coords.x or 0, y = coords.y or 0, z = coords.z or 0, heading = point.heading or 0,
            anyGang = point.gangs == true, gangs = type(point.gangs) == 'table' and point.gangs or {},
            groups = type(point.groups) == 'table' and point.groups or {},
        }
    end
    table.sort(points, function(a, b) return a.name < b.name end)

    local placed = {}
    for benchId, record in pairs(Placed) do
        local bench = Benches[benchId]
        if bench then
            placed[#placed + 1] = {
                id = benchId, number = record.id, type = bench.type, label = bench.label, owner = record.owner,
                x = bench.coords.x, y = bench.coords.y, z = bench.coords.z,
            }
        end
    end
    table.sort(placed, function(a, b) return a.number < b.number end)

    return {
        types = types,
        recipes = recipes,
        blueprints = blueprints,
        points = points,
        placed = placed,
        settings = { xp = XPConfig, packing = PackingConfig },
        gangs = gangList(),
        jobs = jobList(),
    }
end

-- Vuelve a leer la configuración y rehace todas las mesas con ella
local function applyConfig()
    loadConfig()

    for id, bench in pairs(Benches) do
        if bench.dynamic then
            if not buildBench(id, bench.source) then Benches[id] = nil end
        else
            Benches[id] = nil
        end
    end

    for name, point in pairs(Points) do
        buildBench(name, point)
    end

    TriggerClientEvent('jj_crafting:client:reload', -1)
end

local adminActions = {}

adminActions.get = function() end

adminActions.saveType = function(_, data)
    if not validName(data.name) then return 'El nombre interno solo admite letras, números y _' end
    local label = cleanText(data.label, 64)
    if not label then return 'Ponle un nombre de hasta 64 letras' end

    local placementItem = data.placementItem ~= '' and data.placementItem or nil
    local model
    if placementItem then
        if not itemExists(placementItem) then return 'El objeto para colocarla no existe' end
        for name, kind in pairs(BenchTypes) do
            if name ~= data.name and kind.placement and kind.placement.item == placementItem then
                return ('Ese objeto ya coloca la mesa "%s"'):format(kind.label)
            end
        end
        model = cleanText(data.model, 64)
        if not model or not model:match('^[%w_]+$') then return 'Las mesas que se colocan necesitan un modelo' end
    end

    local spawnRange = num(data.spawnRange or 50, 5, 300)
    local slots = int(data.slots, 1, 200)
    local maxWeight = int(data.maxWeight, 1000, 10000000)
    if not spawnRange or not slots or not maxWeight then return 'Revisa la distancia, los huecos y el peso del almacén' end

    saveType({ name = data.name, label = label, model = model, spawnRange = spawnRange, slots = slots, maxWeight = maxWeight, placementItem = placementItem, hideLocked = data.hideLocked == true })
    applyConfig()
end

adminActions.deleteType = function(_, data)
    local name = data.name
    if not BenchTypes[name] then return 'Ese tipo no existe' end
    if next(Recipes[name] or {}) then return 'Borra antes sus recetas' end
    for _, point in pairs(Points) do
        if point.type == name then return 'Hay puntos de banda que usan este tipo' end
    end
    for _, bench in pairs(Benches) do
        if bench.dynamic and bench.type == name then return 'Hay mesas colocadas de este tipo' end
    end

    MySQL.update.await('DELETE FROM jj_crafting_types WHERE name = ?', { name })
    applyConfig()
end

adminActions.saveRecipe = function(_, data)
    local id = data.id ~= nil and int(data.id, 1, 2 ^ 31) or nil
    if data.id ~= nil then
        local found = false
        for _, row in ipairs(RecipeRows) do
            if row.id == id then found = true end
        end
        if not found then return 'Esa receta no existe' end
    end

    if not BenchTypes[data.type] then return 'Elige un tipo de mesa' end
    if not itemExists(data.item) then return 'El objeto que se fabrica no existe' end

    local list = type(data.ingredients) == 'table' and data.ingredients or {}
    if #list == 0 or #list > MAX_INGREDIENTS then return ('Pon entre 1 y %d materiales'):format(MAX_INGREDIENTS) end

    local ingredients = {}
    for _, ingredient in ipairs(list) do
        if type(ingredient) ~= 'table' or not itemExists(ingredient.name) then return 'Hay un material que no existe' end
        if ingredients[ingredient.name] then return 'Hay un material repetido' end
        if ingredient.tool then
            local percent = num(ingredient.amount, 1, 100)
            if not percent then return 'El desgaste de una herramienta va del 1 al 100 %' end
            ingredients[ingredient.name] = percent / 100
        else
            local amount = int(ingredient.amount, 1, 10000)
            if not amount then return 'Las cantidades de los materiales van de 1 a 10000' end
            ingredients[ingredient.name] = amount
        end
    end

    local duration = num(data.duration, 0.5, 3600)
    local countMin = int(data.countMin, 1, 1000)
    local countMax = int(data.countMax, 1, 1000)
    if not duration then return 'El tiempo va de 0,5 segundos a una hora' end
    if not countMin or not countMax or countMax < countMin then return 'Revisa cuántas unidades salen' end

    local xpRequired = int(data.xpRequired or 0, 0, 1000000)
    local xpReward = int(data.xpReward or 0, 0, 1000000)
    local sort = int(data.sort or 0, -1000, 1000)
    if not xpRequired or not xpReward or not sort then return 'Revisa la experiencia y el orden' end

    local blueprint = data.blueprint ~= '' and data.blueprint or nil
    if blueprint and not Blueprints[blueprint] then return 'Ese plano no existe' end

    saveRecipe({
        id = id, type = data.type, item = data.item, ingredients = ingredients, duration = math.floor(duration * 1000),
        countMin = countMin, countMax = countMax, xpRequired = xpRequired, xpReward = xpReward, blueprint = blueprint, sort = sort,
    })
    applyConfig()
end

adminActions.deleteRecipe = function(_, data)
    local id = int(data.id, 1, 2 ^ 31)
    if not id then return 'Esa receta no existe' end
    MySQL.update.await('DELETE FROM jj_crafting_recipes WHERE id = ?', { id })
    applyConfig()
end

adminActions.saveBlueprint = function(_, data)
    if not validName(data.name) then return 'El nombre interno solo admite letras, números y _' end
    if not itemExists(data.item) then return 'El objeto del plano no existe' end

    local metadataKey = data.metadataKey ~= '' and data.metadataKey or nil
    if metadataKey and not validName(metadataKey) then return 'La clave solo admite letras, números y _' end
    local metadataValue = metadataKey and cleanText(data.metadataValue, 64) or nil
    if metadataKey and not metadataValue then return 'Pon el valor que distingue este plano' end

    local consume = num(data.consume or 0, 0, 100)
    if not consume then return 'El desgaste por uso va del 0 al 100 %' end

    saveBlueprintConfig({ name = data.name, item = data.item, metadataKey = metadataKey, metadataValue = metadataValue, consume = consume / 100 })
    applyConfig()
end

adminActions.deleteBlueprint = function(_, data)
    if not Blueprints[data.name] then return 'Ese plano no existe' end
    for _, row in ipairs(RecipeRows) do
        if row.blueprint == data.name then return 'Hay recetas que usan este plano' end
    end
    MySQL.update.await('DELETE FROM jj_crafting_blueprints WHERE name = ?', { data.name })
    applyConfig()
end

adminActions.giveBlueprint = function(_, data)
    local target = int(data.target, 1, 100000)
    if not target or not JJ.GetPlayer(target) then return 'No hay nadie con ese id' end
    local ok, reason = giveBlueprint(target, data.name)
    if not ok then return reason end
    notify(target, 'Has recibido un plano', 'inform')
end

adminActions.savePoint = function(_, data)
    if not validName(data.name) then return 'El nombre interno solo admite letras, números y _' end
    if not BenchTypes[data.type] then return 'Elige un tipo de mesa' end

    local label = data.label ~= '' and cleanText(data.label, 64) or nil
    if data.label ~= '' and data.label ~= nil and not label then return 'El nombre visible tiene hasta 64 letras' end

    local x, y, z = num(data.x, -20000, 20000), num(data.y, -20000, 20000), num(data.z, -500, 3000)
    local heading = num(data.heading or 0, -360, 720)
    if not x or not y or not z or not heading then return 'Las coordenadas no son válidas' end

    local gangs
    if data.anyGang then
        gangs = true
    elseif type(data.gangs) == 'table' and #data.gangs > 0 then
        gangs = {}
        for _, id in ipairs(data.gangs) do
            local gangId = int(id, 1, 2 ^ 31)
            if not gangId then return 'Hay una banda que no existe' end
            gangs[#gangs + 1] = gangId
        end
    end

    local groups
    if type(data.groups) == 'table' and #data.groups > 0 then
        local jobs = JJ.GetJobs()
        groups = {}
        for _, name in ipairs(data.groups) do
            if type(name) ~= 'string' or not jobs[name] then return 'Hay un trabajo que no existe' end
            groups[#groups + 1] = name
        end
    end

    savePoint({ name = data.name, type = data.type, label = label, coords = { x = x, y = y, z = z, w = heading % 360 }, gangs = gangs, groups = groups })
    applyConfig()
end

adminActions.deletePoint = function(_, data)
    if not Points[data.name] then return 'Ese punto no existe' end
    MySQL.update.await('DELETE FROM jj_crafting_points WHERE name = ?', { data.name })
    applyConfig()
end

adminActions.saveSettings = function(_, data)
    local xp = type(data.xp) == 'table' and data.xp or {}
    local packing = type(data.packing) == 'table' and data.packing or {}
    local reward = int(xp.defaultReward or 0, 0, 1000000)
    if not reward then return 'La experiencia por defecto no es válida' end

    saveSetting('xp', { enabled = xp.enabled == true, hideLocked = xp.hideLocked == true, defaultReward = reward })
    saveSetting('packing', { enabled = packing.enabled == true, confirmWithItems = packing.confirmWithItems == true })
    applyConfig()
end

adminActions.removePlaced = function(_, data)
    if not Placed[data.id] then return 'Esa mesa no existe' end
    if storageInUse(data.id) then return 'Alguien está usando su almacén' end
    removeBench(data.id)
end

for name, handler in pairs(adminActions) do
    lib.callback.register('jj_crafting:admin:' .. name, function(source, data)
        if not JJ.IsAdmin(source) then return { error = 'No tienes permiso' } end

        local err = handler(source, type(data) == 'table' and data or {})
        if err then return { error = err } end
        return { data = adminData() }
    end)
end

RegisterCommand('crafteoadmin', function(src)
    if src == 0 then return print('[jj_crafting] Usa /crafteoadmin dentro del juego') end
    if not JJ.IsAdmin(src) then return notify(src, 'No tienes permiso para usar este comando', 'error') end
    TriggerClientEvent('jj_crafting:client:admin', src)
end, false)
