local PED_MEMORY = 300000 -- ms que el cliente no vuelve a ofrecer droga al mismo NPC

local busy = false
local hasDrugs = false
local offered = {} -- [entidad] = momento de la última oferta

function IsBusy()
    return busy
end

function SetBusy(value)
    busy = value
end

-- Laboratorios

function UseLab(point)
    if busy then return end
    busy = true

    local start = lib.callback.await('jj_gangs:server:startLab', false, point.id)
    if not start or not start.ok then
        Notify(start and start.message or 'No puedes usar este laboratorio', 'error')
        busy = false
        return
    end

    local completed = lib.progressBar({
        duration = start.time,
        label = ('Preparando %s'):format(start.label),
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { scenario = 'PROP_HUMAN_BUM_BIN' },
    })

    if completed then
        local result = lib.callback.await('jj_gangs:server:finishLab', false, point.id)
        if result and result.message then
            Notify(result.message, result.ok and 'success' or 'error')
        end
    else
        TriggerServerEvent('jj_gangs:server:cancelLab')
    end
    busy = false
end

-- Venta a NPC

CreateThread(function()
    while true do
        local found = false
        for item in pairs(Config.Drugs) do
            local count = exports.ox_inventory:Search('count', item)
            if count and count > 0 then
                found = true
                break
            end
        end
        hasDrugs = found
        Wait(2000)
    end
end)

local function canOffer(entity)
    if not hasDrugs or busy or cache.vehicle then return false end
    if IsPedAPlayer(entity) or IsPedDeadOrDying(entity, true) or not IsPedHuman(entity) or IsPedInAnyVehicle(entity, false) then
        return false
    end
    return not offered[entity] or GetGameTimer() - offered[entity] > PED_MEMORY
end

local function sellTo(ped)
    if busy then return end
    busy = true
    offered[ped] = GetGameTimer()

    NetworkRequestControlOfEntity(ped)
    ClearPedTasks(ped)
    TaskStandStill(ped, Config.Sale.Time + 1000)
    TaskTurnPedToFaceEntity(ped, cache.ped, Config.Sale.Time)
    TaskTurnPedToFaceEntity(cache.ped, ped, 1000)

    local completed = lib.progressBar({
        duration = Config.Sale.Time,
        label = 'Ofreciendo droga',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
    })

    if completed then
        local netId = NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped) or 0
        local result = lib.callback.await('jj_gangs:server:sell', false, netId)

        if result and result.ok then
            if result.sold then
                local extra = result.rival and ' Este barrio paga más, pero sus dueños se han enterado.' or ''
                Notify(('Vendes %d de %s por $%d en negro.%s'):format(result.units, result.label, result.payment, extra), 'success')
            else
                Notify('No quiere comprarte nada', 'error')
                if result.police then
                    TriggerServerEvent('SendAlert:police', {
                        job = 'police',
                        title = 'Venta de droga',
                        message = 'Un vecino ha visto a alguien vendiendo droga',
                    })
                end
            end
        elseif result and result.message then
            Notify(result.message, 'error')
        end
    end

    busy = false
end

exports.ox_target:addGlobalPed({
    {
        name = 'jj_gangs_sell',
        label = 'Ofrecer droga',
        icon = 'fa-solid fa-cannabis',
        distance = 2.0,
        canInteract = canOffer,
        onSelect = function(data)
            Async(sellTo, data.entity)
        end,
    },
})
