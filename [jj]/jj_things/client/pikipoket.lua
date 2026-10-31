local SETTINGS = {
    Debug = false,

    Target = {
        prefer = 'ox_target',
        distance = 2.0
    },

    PickPocket = {
        TargetIcon = 'fa-solid fa-hand-holding-dollar',
        ClientCooldownMs = 2500,
        ProgressMs = 1500,
        NotifyTitle = 'Carterismo',

        Animation = {
            Dict = 'mp_arresting',
            Name = 'a_uncuff',
            Flag = 49
        },

        SkillCheck = {
            Enabled = true,
            Difficulty = { 'medium', 'medium' },
            Keys = { 'w', 'a', 's', 'd' }
        },

        Labels = {
            target = 'Robar cartera',
            progress = 'Robando cartera...'
        },

        Messages = {
            failed = 'Te ha pillado intentando robarle.',
            invalid = 'No puedes robar a esta persona.',
            cooldown = 'Espera un poco antes de volver a intentarlo.',
            cancelled = 'Accion cancelada.'
        }
    }
}

local RESOURCE_PREFIX = 'pickpocket_standalone'
local busy = false
local localCooldown = 0

local function Debug(msg)
    if SETTINGS.Debug then
        print(('[%s] %s'):format(RESOURCE_PREFIX, msg))
    end
end

local function Notify(message, ntype)
    lib.notify({
        title = SETTINGS.PickPocket.NotifyTitle,
        description = message,
        type = ntype or 'inform'
    })
end

local function GetTargetSystem()
    local prefer = SETTINGS.Target.prefer or 'ox_target'
    local hasOx = GetResourceState('ox_target') == 'started'
    local hasQb = GetResourceState('qb-target') == 'started'

    if prefer == 'qb-target' and hasQb then return 'qb' end
    if prefer == 'ox_target' and hasOx then return 'ox' end
    if hasOx then return 'ox' end
    if hasQb then return 'qb' end

    return nil
end

local function IsValidPedTarget(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not IsEntityAPed(entity) then return false end
    if IsPedAPlayer(entity) then return false end
    if not IsPedHuman(entity) then return false end
    if IsPedDeadOrDying(entity, true) then return false end
    if IsPedInAnyVehicle(entity, false) then return false end
    if busy then return false end
    local pedType = GetPedType(entity)
    if pedType == 28 or pedType == 27 or pedType == 6 or pedType == 29 then return false end
    if IsEntityAMissionEntity(entity) then return false end

    local state = Entity(entity).state
    if state and state.hk_pickpocket_robbed then return false end

    local ped = PlayerPedId()
    if IsPedDeadOrDying(ped, true) or IsPedInAnyVehicle(ped, false) then return false end

    local maxDistance = SETTINGS.Target.distance or 2.0
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > (maxDistance + 0.35) then return false end

    return true
end

local function EnsureNetId(entity)
    if not NetworkGetEntityIsNetworked(entity) then
        NetworkRegisterEntityAsNetworked(entity)
        local timeout = GetGameTimer() + 750
        while not NetworkGetEntityIsNetworked(entity) and GetGameTimer() < timeout do
            Wait(0)
        end
    end

    local netId = PedToNet(entity)
    if not netId or netId == 0 then return nil end
    SetNetworkIdCanMigrate(netId, true)
    return netId
end

local function LoadAnimDict(dict)
    if not dict or dict == '' then return false end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasAnimDictLoaded(dict)
end

local function DoAggressivePed(netId)
    local npc = NetToPed(netId)
    if not npc or npc == 0 or not DoesEntityExist(npc) then return end

    local ped = PlayerPedId()
    local timeout = GetGameTimer() + 1000
    NetworkRequestControlOfEntity(npc)
    while not NetworkHasControlOfEntity(npc) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(npc)
        Wait(0)
    end

    ClearPedTasksImmediately(npc)
    SetBlockingOfNonTemporaryEvents(npc, false)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 5, true)
    SetPedCombatAttributes(npc, 46, true)
    SetPedCombatAbility(npc, 1)
    SetPedCombatMovement(npc, 2)
    SetPedCombatRange(npc, 0)
    SetPedKeepTask(npc, true)
    TaskCombatPed(npc, ped, 0, 16)
end

RegisterNetEvent('pickpocket_standalone:result', function(data)
    busy = false

    data = data or {}

    if data.aggressive and data.netId then
        DoAggressivePed(data.netId)
    end

    if data.message then
        Notify(data.message, data.type or 'inform')
    end
end)

local function StartPickPocket(entity)
    if not IsValidPedTarget(entity) then
        Notify(SETTINGS.PickPocket.Messages.invalid, 'error')
        return
    end

    if GetGameTimer() < localCooldown then
        Notify(SETTINGS.PickPocket.Messages.cooldown, 'error')
        return
    end

    local netId = EnsureNetId(entity)
    if not netId then
        Notify(SETTINGS.PickPocket.Messages.invalid, 'error')
        return
    end

    busy = true
    localCooldown = GetGameTimer() + (SETTINGS.PickPocket.ClientCooldownMs or 2500)

    local ped = PlayerPedId()
    local anim = SETTINGS.PickPocket.Animation
    if LoadAnimDict(anim.Dict) then
        TaskPlayAnim(ped, anim.Dict, anim.Name, 4.0, -4.0, -1, anim.Flag, 0.0, false, false, false)
    end

    local finished = lib.progressBar({
        duration = SETTINGS.PickPocket.ProgressMs or 1500,
        label = SETTINGS.PickPocket.Labels.progress,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    })

    ClearPedTasks(ped)

    if not finished then
        busy = false
        Notify(SETTINGS.PickPocket.Messages.cancelled, 'error')
        return
    end

    if SETTINGS.PickPocket.SkillCheck.Enabled then
        local ok = lib.skillCheck(SETTINGS.PickPocket.SkillCheck.Difficulty, SETTINGS.PickPocket.SkillCheck.Keys)
        if not ok then
            busy = false
            TriggerServerEvent('pickpocket_standalone:attempt', netId, true)
            return
        end
    end

    busy = false
    TriggerServerEvent('pickpocket_standalone:attempt', netId, false)
end

CreateThread(function()
    Wait(1000)

    local target = GetTargetSystem()
    if not target then
        print(('^1[%s] No se encontro ox_target ni qb-target.^0'):format(RESOURCE_PREFIX))
        return
    end

    local label = SETTINGS.PickPocket.Labels.target
    local icon = SETTINGS.PickPocket.TargetIcon
    local distance = SETTINGS.Target.distance or 2.0

    if target == 'ox' then
        exports.ox_target:addGlobalPed({
            {
                name = 'pickpocket_standalone',
                icon = icon,
                label = label,
                distance = distance,
                canInteract = function(entity)
                    return IsValidPedTarget(entity)
                end,
                onSelect = function(data)
                    StartPickPocket(data.entity)
                end
            }
        })
        Debug('Registrado con ox_target')
    elseif target == 'qb' then
        exports['qb-target']:AddGlobalPed({
            options = {
                {
                    icon = icon,
                    label = label,
                    action = function(entity)
                        StartPickPocket(entity)
                    end,
                    canInteract = function(entity)
                        return IsValidPedTarget(entity)
                    end
                }
            },
            distance = distance
        })
        Debug('Registrado con qb-target')
    end
end)