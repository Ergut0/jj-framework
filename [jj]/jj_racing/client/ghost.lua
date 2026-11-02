-- Modo fantasma / colisiones configurables. Solo corre durante una carrera y solo si hace falta:
--  * circuitos con colisiones desactivadas: fantasma durante toda la carrera
--  * resto de circuitos: fantasma breve tras la salida (Config.Ghost.startSeconds)

Ghost = {}

local active = false
local token = 0

local function resolve(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return nil end
    local e = NetworkGetEntityFromNetworkId(netId)
    if e and e ~= 0 and DoesEntityExist(e) then return e end
    return nil
end

local function resetAlpha(entities)
    for e in pairs(entities) do
        if DoesEntityExist(e) then ResetEntityAlpha(e) end
    end
end

function Ghost.Stop()
    active = false
    token = token + 1
end

---@param racers table lista { pid, netId }
---@param collisions boolean el circuito tiene colisiones
---@param you integer id de servidor del jugador
function Ghost.Start(racers, collisions, you)
    if not Config.Ghost.enabled then return end
    if collisions and Config.Ghost.startSeconds <= 0 then return end
    token = token + 1
    local mine = token
    active = true
    local endAt = collisions and (GetGameTimer() + Config.Ghost.startSeconds * 1000) or nil

    CreateThread(function()
        local entities, refreshAt = {}, 0
        while active and token == mine do
            local now = GetGameTimer()
            if endAt and now >= endAt then break end

            -- Los vehiculos rivales se resuelven una vez por segundo
            if now >= refreshAt then
                refreshAt = now + 1000
                resetAlpha(entities)
                entities = {}
                for _, r in ipairs(racers) do
                    if r.pid ~= you then
                        local e = resolve(r.netId)
                        if e then
                            entities[e] = true
                            SetEntityAlpha(e, Config.Ghost.alpha, false)
                        end
                    end
                end
            end

            local mineVeh = GetVehiclePedIsIn(PlayerPedId(), false)
            if mineVeh ~= 0 then
                for e in pairs(entities) do
                    SetEntityNoCollisionEntity(mineVeh, e, true)
                    SetEntityNoCollisionEntity(e, mineVeh, true)
                end
            end
            Wait(0)
        end
        resetAlpha(entities)
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then Ghost.Stop() end
end)
