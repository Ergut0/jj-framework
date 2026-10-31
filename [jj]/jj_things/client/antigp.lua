local MAX_DISTANCE = 300.0 -- alcance del rayo de la camara
local OBSTACLE_DISTANCE = 15.0 -- solo cuentan obstaculos a esta distancia del arma
local TOLERANCE = 0.1 -- margen entre el punto apuntado y la colision desde el arma
local OBSTACLE_FLAGS = 19 -- mapa + vehiculos + objetos

local currentWeapon = cache.weapon
local running = false

local function getCamDirection()
    local rot = GetGameplayCamRot(2)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function raycast(from, to, flags, ignore)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 7)
    local _, hit, coords, _, entity = GetShapeTestResult(handle)
    hit = hit == 1 or hit == true
    -- props enganchados al propio ped (escudos, mochilas...) no cuentan
    if hit and entity ~= 0 and DoesEntityExist(entity) and IsEntityAttachedToEntity(entity, ignore) then
        return false, coords
    end
    return hit, coords
end

local function getGunCoords(ped)
    local weapon = GetCurrentPedWeaponEntityIndex(ped)
    if weapon ~= 0 and DoesEntityExist(weapon) then
        return GetEntityCoords(weapon)
    end
    return GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0)
end

local function getAimCoords(ped)
    local camCoords = GetGameplayCamCoord()
    local farCoords = camCoords + getCamDirection() * MAX_DISTANCE
    local hit, coords = raycast(camCoords, farCoords, -1, ped)
    return hit and coords or farCoords
end

local function getObstacleCoords(ped, aimCoords)
    local gunCoords = getGunCoords(ped)

    -- arma atravesando la pared: queda al otro lado y su rayo ya no la detecta
    local hit, coords = raycast(GetPedBoneCoords(ped, 40269, 0.0, 0.0, 0.0), gunCoords, OBSTACLE_FLAGS, ped)
    if hit then return coords end

    local offset = aimCoords - gunCoords
    local distance = #offset
    local destination = aimCoords
    if distance > OBSTACLE_DISTANCE then
        destination = gunCoords + offset / distance * OBSTACLE_DISTANCE
    end

    hit, coords = raycast(gunCoords, destination, OBSTACLE_FLAGS, ped)
    if hit and #(coords - aimCoords) > TOLERANCE then return coords end
end

local function drawCross(coords)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 0, 0, 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('X')
    EndTextCommandDisplayText(0.0, -0.018)
    ClearDrawOrigin()
end

local function canCheckAntiGp(ped)
    if cache.vehicle then return false end
    if not IsPedArmed(ped, 4) then return false end
    if IsEntityDead(ped) then return false end
    if IsPedRagdoll(ped) then return false end
    return true
end

local function startLoop()
    if running then return end
    running = true
    CreateThread(function()
        while currentWeapon do
            local sleep = 250
            local ped = PlayerPedId()
            local playerId = PlayerId()

            if canCheckAntiGp(ped) then
                sleep = 0
                local isAiming = IsPlayerFreeAiming(playerId)
                local isShooting = IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)

                if isAiming or isShooting then
                    local obstacleCoords = getObstacleCoords(ped, getAimCoords(ped))

                    if obstacleCoords then
                        DisablePlayerFiring(playerId, true)
                        DisableControlAction(0, 24, true)
                        DisableControlAction(0, 257, true)
                        drawCross(obstacleCoords)
                    end
                end
            end

            Wait(sleep)
        end
        running = false
    end)
end

lib.onCache('weapon', function(weapon)
    currentWeapon = weapon
    if weapon then startLoop() end
end)

if currentWeapon then startLoop() end
