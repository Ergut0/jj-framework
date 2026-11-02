-- Vehículo objetivo y protectores. El vehículo lo crea el servidor: aquí solo se interactúa con él
local currentNet
local aggroSent = false
local guardsThread = false

local function isTarget(entity)
    local contract = Boosting.contract
    return contract and contract.netId and NetworkGetEntityIsNetworked(entity)
        and NetworkGetNetworkIdFromEntity(entity) == contract.netId
end

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'jj_boosting_hack',
            icon = 'fa-solid fa-microchip',
            label = 'Hackear la cerradura',
            distance = Config.Distances.hack,
            canInteract = function(entity)
                local contract = Boosting.contract
                return contract and contract.hackRequired and contract.status == Boost.Status.LOCATED and isTarget(entity)
            end,
            onSelect = function()
                Boosting.StartHack('lock')
            end,
        },
    })
end)

local function attack(ped)
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    NetworkRequestControlOfEntity(ped)
    SetPedCombatAttributes(ped, 46, true)
    SetPedFleeAttributes(ped, 0, false)
    TaskCombatPed(ped, cache.ped, 0, 16)
end

local function aggro(nets)
    aggroSent = true
    for _, net in ipairs(nets or {}) do
        if NetworkDoesEntityExistWithNetworkId(net) then
            attack(NetworkGetEntityFromNetworkId(net))
        end
    end
end

RegisterNetEvent('jj_boosting:client:guardsAggro', aggro)

-- Solo funciona mientras hay protectores y el jugador se acerca
local function watchGuards(contract)
    if guardsThread or not contract.guards then return end
    guardsThread = true

    CreateThread(function()
        local vehiclePos
        while Boosting.contract and Boosting.contract.uid == contract.uid and not aggroSent do
            Wait(1000)
            local net = Boosting.contract and Boosting.contract.netId
            if net and NetworkDoesEntityExistWithNetworkId(net) then
                vehiclePos = GetEntityCoords(NetworkGetEntityFromNetworkId(net))
                if #(GetEntityCoords(cache.ped) - vehiclePos) < Config.Guards.aggroDistance then
                    aggro(Boosting.contract.guards)
                end
            end
        end
        guardsThread = false
    end)
end

-- Al llegar al vehículo: se coloca bien en el suelo, porque el servidor no conoce el terreno
local function settleVehicle(net)
    CreateThread(function()
        local timeout = GetGameTimer() + 60000
        while currentNet == net and GetGameTimer() < timeout do
            if NetworkDoesEntityExistWithNetworkId(net) then
                local vehicle = NetworkGetEntityFromNetworkId(net)
                NetworkRequestControlOfEntity(vehicle)
                if NetworkHasControlOfEntity(vehicle) then
                    SetVehicleOnGroundProperly(vehicle)
                    return
                end
            end
            Wait(1000)
        end
    end)
end

function Boosting.OnVehicle(contract)
    if not contract then
        currentNet = nil
        aggroSent = false
        return
    end

    if contract.netId and contract.netId ~= currentNet then
        currentNet = contract.netId
        aggroSent = false
        settleVehicle(currentNet)
    end
    watchGuards(contract)
end

RegisterNetEvent('jj_boosting:client:alarm', function(net)
    if not NetworkDoesEntityExistWithNetworkId(net) then return end
    local vehicle = NetworkGetEntityFromNetworkId(net)
    SetVehicleAlarmTimeLeft(vehicle, 30000)
    SetVehicleAlarm(vehicle, true)
    StartVehicleAlarm(vehicle)
end)
