local MEDIC_JOB = 'ambulance'
local MAX_INTERACT_DISTANCE = 5.0
local MAX_BED_DISTANCE = 10.0
local HEALTH_SAVE_INTERVAL = 30000

-- [zona][cama] = source del jugador que la ocupa
local takenBeds = {}

function Notify(src, description, type)
    TriggerClientEvent('ox_lib:notify', src, { description = description, type = type or 'inform' })
end

function IsMedicOnDuty(player)
    local job = player and player.getJob()
    return job and job.name == MEDIC_JOB and job.onDuty
end

local function isDown(player)
    return player.getMetadata('isdead') or player.getMetadata('inlaststand')
end

local function setDeathStatus(player, status)
    player.setMetadata('isdead', status == 'dead')
    player.setMetadata('inlaststand', status == 'laststand')
end

local function getDistance(src, coords)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return math.huge
    end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z))
end

local function arePlayersClose(a, b)
    local ped = GetPlayerPed(b)
    if not ped or ped == 0 then
        return false
    end
    return getDistance(a, GetEntityCoords(ped)) <= MAX_INTERACT_DISTANCE
end

-- Las camillas libres solo se pueden usar cuando no hay sanitarios de servicio
local function updateBedsAvailability(leaving)
    local medics = 0
    for _, src in pairs(JJ.GetPlayers()) do
        if src ~= leaving and IsMedicOnDuty(JJ.GetPlayer(src)) then
            medics = medics + 1
        end
    end
    GlobalState.camillasActivadas = medics == 0
end

local function getValidZone(zone)
    if type(zone) == 'string' and Config.Info.beds[zone] then
        return zone
    end
    return 'Sur'
end

local function releaseBed(src)
    for zone, beds in pairs(takenBeds) do
        for id, occupant in pairs(beds) do
            if occupant == src then
                beds[id] = nil
                TriggerClientEvent('jj_deathsystem:client:SetBed', -1, zone, id, false)
            end
        end
    end
end

local function isBedTaken(zone, id)
    local occupant = takenBeds[zone] and takenBeds[zone][id]
    return occupant ~= nil and GetPlayerName(occupant) ~= nil
end

local function findBed(zone)
    local beds = Config.Info.beds[zone]
    for id in pairs(beds) do
        if not isBedTaken(zone, id) then
            return id
        end
    end
    -- Nadie se queda sin reaparecer: si están todas ocupadas, se comparte una
    return math.random(1, #beds)
end

local function sendToBed(src, zone, id, isRevive)
    releaseBed(src)
    takenBeds[zone] = takenBeds[zone] or {}
    takenBeds[zone][id] = src
    TriggerClientEvent('jj_deathsystem:client:SetBed', -1, zone, id, true)

    local bed = Config.Info.beds[zone][id]
    TriggerClientEvent('jj_deathsystem:client:SendToBed', src, id, { coords = bed.coords, model = bed.model }, isRevive, zone)
end

local function removeItemsOnRespawn(src, player)
    if not Config.RemoveItemsInRespawn then return end

    local jobName = player.getJob().name
    for _, exempt in ipairs(Config.BlackList.Jobs) do
        if exempt == jobName then return end
    end

    if Config.BlackList.WipeInventory then
        -- El efectivo es un objeto de ox_inventory: se conserva para no vaciar la cuenta
        exports.ox_inventory:ClearInventory(src, 'money')
        return
    end

    local blacklisted, skipped = {}, {}
    for _, name in ipairs(Config.BlackList.Items) do
        blacklisted[name] = true
    end
    for _, name in ipairs(Config.BlackList.SkipWeapons) do
        skipped[name:upper()] = true
    end

    for slot, item in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
        local upperName = item.name:upper()
        local isWeapon = Config.BlackList.Weapons and upperName:sub(1, 7) == 'WEAPON_' and not skipped[upperName]
        if blacklisted[item.name] or isWeapon then
            exports.ox_inventory:RemoveItem(src, item.name, item.count, item.metadata, slot)
        end
    end
end

RegisterNetEvent('jj_deathsystem:server:SetDeathStatus', function(status)
    local player = JJ.GetPlayer(source)
    if player and (status == 'dead' or status == 'laststand' or status == false) then
        setDeathStatus(player, status)
    end
end)

local function logDeath(src, attackerId, weapon, kind)
    local attacker = tonumber(attackerId)
    print(('[jj_deathsystem] %s (%s) -> %s, atacante: %s, arma: %s'):format(
        GetPlayerName(src), src, kind, attacker and GetPlayerName(attacker) or 'ninguno', tostring(weapon)))
    TriggerEvent('jj_deathsystem:server:playerDown', src, kind, attacker, weapon)
end

RegisterNetEvent('jj_deathsystem:server:sendLogLastStand', function(attackerId, weapon)
    logDeath(source, attackerId, weapon, 'laststand')
end)

RegisterNetEvent('jj_deathsystem:server:sendLogDead', function(attackerId, weapon)
    logDeath(source, attackerId, weapon, 'dead')
end)

-- fromDeath: reaparición tras morir. Si no, es una revisión pagada en el mostrador del hospital
RegisterNetEvent('jj_deathsystem:server:RespawnAtHospital', function(fromDeath, zone)
    local src = source
    local player = JJ.GetPlayer(src)
    if not player then return end

    if fromDeath then
        if not isDown(player) then return end
        setDeathStatus(player, false)
        removeItemsOnRespawn(src, player)
        -- Si no puede pagar, reaparece igualmente
        player.removeMoney('bank', Config.BillCost, 'hospital_bill')
        zone = getValidZone(Player(src).state.actualZone)
    else
        zone = getValidZone(zone)
        local isNearCounter = false
        for _, check in pairs(Config.Info.checking[zone] or {}) do
            if getDistance(src, check.coords) <= MAX_BED_DISTANCE then
                isNearCounter = true
                break
            end
        end
        if not isNearCounter then return end
        if not player.removeMoney('bank', Config.BillCost, 'hospital_bill') then
            Notify(src, 'No tienes dinero para pagar la factura', 'error')
            return
        end
    end

    sendToBed(src, zone, findBed(zone), true)
end)

RegisterNetEvent('jj_deathsystem:server:SendToBed', function(id, zone)
    local src = source
    if not JJ.GetPlayer(src) or GlobalState.camillasActivadas == false then return end

    zone = getValidZone(zone)
    local bed = Config.Info.beds[zone][id]
    if not bed or getDistance(src, bed.coords) > MAX_BED_DISTANCE then return end

    if isBedTaken(zone, id) then
        Notify(src, 'Las camillas estan ocupadas', 'error')
        return
    end

    sendToBed(src, zone, id, false)
end)

RegisterNetEvent('jj_deathsystem:server:LeaveBed', function()
    releaseBed(source)
end)

RegisterNetEvent('jj_deathsystem:server:revive', function(target)
    local src = source
    target = tonumber(target)
    local targetPlayer = target and JJ.GetPlayer(target)
    if not IsMedicOnDuty(JJ.GetPlayer(src)) or not targetPlayer or not isDown(targetPlayer) then return end
    if not arePlayersClose(src, target) then return end
    TriggerClientEvent('jj_deathsystem:client:revive', target)
end)

RegisterNetEvent('jj_deathsystem:server:adminHeal', function(target)
    local src = source
    target = tonumber(target)
    local targetPlayer = target and JJ.GetPlayer(target)
    if not IsMedicOnDuty(JJ.GetPlayer(src)) or not targetPlayer or isDown(targetPlayer) then return end
    if not arePlayersClose(src, target) then return end
    TriggerClientEvent('jj_deathsystem:client:adminHeal', target)
end)

-- Comandos de administración: /revive, /heal y /kill [id]
local function registerAdminCommand(name, handler)
    RegisterCommand(name, function(src, args)
        if not JJ.IsAdmin(src) then
            Notify(src, 'No tienes permiso para usar este comando', 'error')
            return
        end
        local target = tonumber(args[1]) or src
        if target == 0 or not JJ.GetPlayer(target) then
            if src == 0 then
                print('[jj_deathsystem] Jugador no encontrado')
            else
                Notify(src, 'Jugador no encontrado', 'error')
            end
            return
        end
        handler(target)
    end, false)
end

registerAdminCommand('revive', function(target)
    TriggerClientEvent('jj_deathsystem:client:revive', target)
end)

registerAdminCommand('heal', function(target)
    TriggerClientEvent('jj_deathsystem:client:adminHeal', target)
end)

registerAdminCommand('kill', function(target)
    TriggerClientEvent('jj_deathsystem:client:KillPlayer', target)
end)

AddEventHandler('jj:server:playerLoaded', function()
    updateBedsAvailability()
end)

AddEventHandler('jj:server:jobChanged', function()
    updateBedsAvailability()
end)

AddEventHandler('jj:server:dutyChanged', function()
    updateBedsAvailability()
end)

-- jj-framework guarda al jugador después de este evento y lo elimina a continuación
AddEventHandler('jj:server:playerDropped', function(src)
    releaseBed(src)
    updateBedsAvailability(src)
end)

-- La vida se guarda en el metadata para restaurarla al volver a entrar
CreateThread(function()
    while true do
        Wait(HEALTH_SAVE_INTERVAL)
        for _, src in pairs(JJ.GetPlayers()) do
            local player = JJ.GetPlayer(src)
            local ped = GetPlayerPed(src)
            if player and player.isSpawned() and not isDown(player) and ped and ped ~= 0 then
                local health = GetEntityHealth(ped)
                if health > 100 and health ~= player.getMetadata('health') then
                    player.setMetadata('health', health)
                end
            end
        end
    end
end)

CreateThread(function()
    updateBedsAvailability()
end)

exports('isDead', function(src)
    local player = JJ.GetPlayer(src)
    return player ~= nil and isDown(player) == true
end)

exports('revive', function(src)
    if not JJ.GetPlayer(src) then return false end
    TriggerClientEvent('jj_deathsystem:client:revive', src)
    return true
end)
