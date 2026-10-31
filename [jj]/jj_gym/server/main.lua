local EXERCISE_COOLDOWN = 60
local MAX_POINT_DISTANCE = 10.0
local MAX_STAT = 100

local cooldowns = {}

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_gym` (
            `identifier` VARCHAR(60) NOT NULL,
            `stamina` INT NOT NULL DEFAULT 0,
            `strength` INT NOT NULL DEFAULT 0,
            `yoga` INT NOT NULL DEFAULT 0,
            `lung` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- Comprueba que el jugador esté junto a un ejercicio que da esa estadística y esa cantidad
local function isExerciseNearby(src, stat, amount)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)

    for _, exercise in pairs(Config.Gym_Points) do
        for _, experience in ipairs(exercise.experience) do
            if experience.name == stat and experience.how_many == amount then
                for _, point in pairs(exercise.coords) do
                    if #(coords - point) <= MAX_POINT_DISTANCE then
                        return true
                    end
                end
            end
        end
    end
    return false
end

lib.callback.register('jj_gym:getStats', function(source)
    local player = JJ.GetPlayer(source)
    if not player then return nil end

    local rows = MySQL.query.await('SELECT stamina, strength, yoga, lung FROM jj_gym WHERE identifier = ?', { player.identifier })
    if rows and rows[1] then
        return rows
    end
    return { { stamina = 0, strength = 0, yoga = 0, lung = 0 } }
end)

lib.callback.register('jj_gym:modifyStats', function(source, stat, amount)
    local player = JJ.GetPlayer(source)
    -- El nombre de la estadística va dentro de la consulta: solo se aceptan las de la configuración
    if not player or type(stat) ~= 'string' or not Config.Stats[stat] then return false end
    if exports.ox_inventory:GetItemCount(source, Config.GymItem) < 1 then return false end
    if not isExerciseNearby(source, stat, amount) then return false end

    local identifier = player.identifier
    local now = os.time()
    local key = identifier .. ':' .. stat
    if cooldowns[key] and now - cooldowns[key] < EXERCISE_COOLDOWN then return false end
    cooldowns[key] = now

    MySQL.query.await(
        ('INSERT INTO jj_gym (identifier, %s) VALUES (?, ?) ON DUPLICATE KEY UPDATE %s = LEAST(%d, %s + ?)'):format(stat, stat, MAX_STAT, stat),
        { identifier, amount, amount }
    )
    return true
end)

RegisterNetEvent('jj_gym:buyMembership', function()
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then return end

    local function notify(description, type)
        TriggerClientEvent('ox_lib:notify', src, { description = description, type = type })
    end

    if exports.ox_inventory:GetItemCount(src, Config.GymItem) >= 1 then
        return notify('Ya tienes una membresía del gimnasio', 'error')
    end

    local price = Config.MembershipPrice
    if not player.removeMoney('cash', price, 'jj_gym') and not player.removeMoney('bank', price, 'jj_gym') then
        return notify('No tienes suficiente dinero', 'error')
    end

    exports.ox_inventory:AddItem(src, Config.GymItem, 1)
    notify('Has comprado la membresía del gimnasio', 'success')
end)
