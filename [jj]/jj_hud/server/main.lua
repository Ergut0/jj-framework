local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local lastUse = {}

local function getNeed(player, name)
    -- En una variable: un export sin valor no devuelve ni nil, y tonumber() sin argumentos da error
    local value = player.getMetadata(name)
    return tonumber(value) or Config.Needs.Start
end

local function setNeed(player, name, value)
    player.setMetadata(name, math.max(0.0, math.min(100.0, value)) + 0.0)
end

-- Bajan con el tiempo, pero no a quien está muerto o aún no ha aparecido
CreateThread(function()
    while true do
        Wait(Config.Needs.Interval * 1000)
        for _, src in pairs(JJ.GetPlayers()) do
            local player = JJ.GetPlayer(src)
            if player and player.isSpawned() and not Player(src).state.isDead then
                setNeed(player, 'hunger', getNeed(player, 'hunger') - Config.Needs.HungerLoss)
                setNeed(player, 'thirst', getNeed(player, 'thirst') - Config.Needs.ThirstLoss)
            end
        end
    end
end)

-- Lo piden los objetos de comida y bebida de ox_inventory
RegisterNetEvent('jj_hud:server:addStatus', function(values)
    local src = source
    local player = JJ.GetPlayer(src)
    if not player or type(values) ~= 'table' then return end

    local now = os.time()
    if lastUse[src] and now - lastUse[src] < Config.Needs.UseCooldown then return end
    lastUse[src] = now

    for _, name in ipairs({ 'hunger', 'thirst' }) do
        local amount = tonumber(values[name])
        if amount and amount > 0 then
            local gain = math.min(amount / Config.Needs.ItemScale, Config.Needs.MaxPerItem)
            setNeed(player, name, getNeed(player, name) + gain)
        end
    end
end)

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)

-- Para otros recursos: comida por trabajo, curas, etc.
exports('addNeed', function(src, name, amount)
    local player = JJ.GetPlayer(src)
    if not player or (name ~= 'hunger' and name ~= 'thirst') or not tonumber(amount) then return false end
    setNeed(player, name, getNeed(player, name) + tonumber(amount))
    return true
end)
