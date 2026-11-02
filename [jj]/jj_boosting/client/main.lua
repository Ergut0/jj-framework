-- Puntos de acceso a la terminal y estado del contrato en este cliente
Boosting = { contract = nil }

function Boosting.Call(name, data)
    return lib.callback.await('jj_boosting:' .. name, false, data or {})
end

function Boosting.Notify(message, kind)
    if not message then return end
    if Config.Notify == 'ox' then
        lib.notify({ description = message, type = kind or 'inform' })
    else
        JJ.Notify(message, kind)
    end
end

local function openFromTarget()
    Boosting.Open('home')
end

local function addAccessPoint(point)
    if point.type == 'npc' then
        local ped
        lib.points.new({
            coords = point.coords.xyz,
            distance = 60.0,
            onEnter = function()
                lib.requestModel(point.model)
                ped = CreatePed(4, joaat(point.model), point.coords.x, point.coords.y, point.coords.z - 1.0, point.coords.w, false, true)
                SetModelAsNoLongerNeeded(point.model)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = 'jj_boosting_terminal',
                        icon = 'fa-solid fa-laptop-code',
                        label = point.label,
                        distance = Config.Access.targetDistance,
                        onSelect = openFromTarget,
                    },
                })
            end,
            onExit = function()
                if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
                ped = nil
            end,
        })
    else
        exports.ox_target:addSphereZone({
            coords = point.coords,
            radius = point.radius or 1.0,
            options = {
                {
                    name = 'jj_boosting_terminal',
                    icon = 'fa-solid fa-laptop-code',
                    label = point.label,
                    distance = Config.Access.targetDistance,
                    onSelect = openFromTarget,
                },
            },
        })
    end
end

CreateThread(function()
    for _, point in ipairs(Config.Access.points) do addAccessPoint(point) end

    -- Punto de recogida de la tienda
    exports.ox_target:addSphereZone({
        coords = Config.Store.pickupPoint.coords,
        radius = 1.0,
        options = {
            {
                name = 'jj_boosting_pickup',
                icon = 'fa-solid fa-box',
                label = Config.Store.pickupPoint.label,
                distance = Config.Access.targetDistance,
                onSelect = function() Boosting.Open('store') end,
            },
        },
    })
end)

if Config.Access.command then
    RegisterCommand(Config.Access.command, function() Boosting.Open('home') end, false)
end

-- Para abrirla desde un objeto: client = { export = 'jj_boosting.openTerminal' } en data/items.lua
exports('openTerminal', function() Boosting.Open('home') end)

RegisterNetEvent('jj_boosting:client:open', function(tab)
    Boosting.Open(tab or 'home')
end)

-- Al entrar o al reiniciar el recurso, se recupera el contrato en marcha
local function restore()
    local result = Boosting.Call('getActive')
    if result and result.ok then TriggerEvent('jj_boosting:client:contract', result.active) end
end

AddEventHandler('jj:client:playerSpawned', function() CreateThread(restore) end)

CreateThread(function()
    if JJ.IsSpawned() then restore() end
end)
