local HEADSHOT_MULTIPLIER = 1.6
local HEAD_BONE = 31086 -- SKEL_Head
local BULLET_DAMAGE_TYPE = 3
local PENDING_TIMEOUT = 1000 -- ms que se guarda un daño sin evento asociado

-- daño recibido (vida + chaleco) que aun no se ha asociado a un evento de daño
local lastVitality = 0
local pendingDamage = 0
local pendingTime = 0

local function getVitality(ped)
    return GetEntityHealth(ped) + GetPedArmour(ped)
end

local function trackDamage(ped)
    local vitality = getVitality(ped)
    if vitality < lastVitality then
        pendingDamage = pendingDamage + (lastVitality - vitality)
        pendingTime = GetGameTimer()
    end
    lastVitality = vitality
end

CreateThread(function()
    while true do
        trackDamage(cache.ped)
        if pendingDamage > 0 and GetGameTimer() - pendingTime > PENDING_TIMEOUT then
            pendingDamage = 0
        end
        Wait(0)
    end
end)

local function applyExtraDamage(ped, amount, attacker, weapon)
    local armour = GetPedArmour(ped)
    local toArmour = math.min(armour, amount)
    if toArmour > 0 then
        SetPedArmour(ped, armour - toArmour)
    end

    local toHealth = amount - toArmour
    if toHealth > 0 then
        local health = GetEntityHealth(ped) - toHealth
        -- atacante y arma para que la muerte se le siga atribuyendo a quien disparo
        SetEntityHealth(ped, health > 100 and health or 0, attacker, weapon)
    end
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim, attacker, weapon = data[1], data[2], data[7]
    local ped = cache.ped
    if victim ~= ped then return end

    trackDamage(ped)
    local damage = pendingDamage
    pendingDamage = 0

    -- data[4] (muerto) llega como 0/1 y en Lua el 0 cuenta como verdadero: se mira la muerte real del ped
    if IsEntityDead(ped) or attacker == ped or not IsEntityAPed(attacker) then return end
    if GetWeaponDamageType(weapon) ~= BULLET_DAMAGE_TYPE then return end

    local found, bone = GetPedLastDamageBone(ped)
    if not found or bone ~= HEAD_BONE then return end

    local extra = math.floor(damage * (HEADSHOT_MULTIPLIER - 1.0) + 0.5)
    if extra <= 0 then return end

    applyExtraDamage(ped, extra, attacker, weapon)
    lastVitality = getVitality(ped)
end)
