-- Efecto de la energética. Se guarda en el personaje hasta que caduca, aunque salga del servidor
local METADATA_KEY = 'recoilDrink'
local CHECK_INTERVAL = 15000

local active = {} -- source -> momento en que termina

local function setActive(src, expiresAt)
    active[src] = expiresAt
    Player(src).state:set('recoilDrink', expiresAt ~= nil, true)
end

local function clearEffect(src, player)
    if player then player.setMetadata(METADATA_KEY, nil) end
    setActive(src, nil)
end

-- La llama ox_inventory desde data/items.lua. El objeto ya se ha gastado al llegar a usedItem
exports('energyDrink', function(event, _, inventory)
    if event ~= 'usedItem' then return end

    local src = inventory.id
    local player = JJ.GetPlayer(src)
    if not player then return end

    local expiresAt = os.time() + Config.EnergyDrink.duration
    player.setMetadata(METADATA_KEY, expiresAt)
    setActive(src, expiresAt)
    JJ.Notify(src, Config.EnergyDrink.startMessage, 'success')
end)

lib.callback.register('jj_recoil:callback:getRecoilDrink', function(source)
    local player = JJ.GetPlayer(source)
    if not player then return false end

    local saved = player.getMetadata(METADATA_KEY)
    local expiresAt = tonumber(saved)
    if expiresAt and expiresAt > os.time() then
        setActive(source, expiresAt)
        return true
    end

    if expiresAt then clearEffect(source, player) end
    return false
end)

CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)
        local now = os.time()
        for src, expiresAt in pairs(active) do
            if now >= expiresAt then
                clearEffect(src, JJ.GetPlayer(src))
                JJ.Notify(src, Config.EnergyDrink.endMessage, 'inform')
            end
        end
    end
end)

AddEventHandler('jj:server:playerDropped', function(src)
    active[src] = nil
end)
