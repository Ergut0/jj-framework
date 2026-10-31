
local function OpenNPC()
    lib.registerContext({
        id = 'conce',
        title = 'Concesionario',
        options = {
            {
                title = 'Llaves de vehículos',
                description = 'Crear las copias de las llaves de los coches',
                icon = 'car',
                event = 'jj_keysystem:OpenCreateKeysMenu',
                arrow = true,
            },
            {
                title = 'Cambiar cerradura del vehículo',
                description = 'Cambia la cerradura del vehículo',
                icon = 'key',
                event = 'jj_keysystem:OpenChangePlatesMenu',
                arrow = true,
            }
        }
      })
    lib.showContext('conce')
end

exports('OpenNPC', OpenNPC)

RegisterNetEvent('jj_keysystem:OpenCreateKeysMenu', function()
    local vehicles = lib.callback.await('jj_keysystem:server:getMyCars')
    local options = {}

    for _, vehicle in pairs(vehicles) do
        local plate = vehicle.plate
        local vehicleLabel = GetDisplayNameFromVehicleModel(GetHashKey(vehicle.model))

        options[#options+1] = {
            icon = "key",
            title = vehicle.plate .. " - " .. vehicleLabel,
            description = "Crear una copia de la llave del vehículo",
            onSelect = function()
                TriggerServerEvent("jj_keysystem:server:CreateKey", plate)
            end
        }
    end

    lib.registerContext({
        id = 'my_cars_menu',
        title = 'Mis Coches',
        options = options
    })

    lib.showContext('my_cars_menu')
end)

RegisterNetEvent('jj_keysystem:OpenChangePlatesMenu', function()
    local vehicles = lib.callback.await('jj_keysystem:server:getMyCars', 1000)
    local options = {}
    for _, vehicle in pairs(vehicles) do
        local vehicleLabel = GetDisplayNameFromVehicleModel(GetHashKey(vehicle.model))

        options[#options+1] = {
            icon = "key",
            title = vehicle.plate .. " - " .. vehicleLabel,
            description = "Cambiar la cerradura del vehículo",
            onSelect = function()
                TriggerServerEvent("jj_keysystem:server:ChangeSerial", vehicle.plate)
            end
        }
    end

    lib.registerContext({
        id = 'my_cars_menu2',
        title = 'Mis Coches',
        options = options
    })
    lib.showContext('my_cars_menu2')
end)

-- ox_inventory envía los datos del objeto y, después, el hueco en el que está
RegisterNetEvent('jj_keysystem:useKey', function(_, slotData)
    local slot = slotData and slotData.slot
    if slot then
        TriggerEvent("ox_inventory:closeInventory")
        local input = lib.inputDialog('Personalizador de llaves', {
            {type = 'input', label = 'Apodo de la llave', description = 'Nombre del apodo'},
        })
        if input then
            TriggerServerEvent("jj_keysystem:server:SetMetadata", slot, input[1])
        end
    end
end)



local npcCreated = false

local function CreateNPC()
    if npcCreated then return end

    local coords = Config.NPC.coords
    local model = Config.NPC.model
    if not lib.requestModel(model) then
        print("No se pudo cargar el modelo del NPC")
        return
    end
    npcCreated = true

    local npc = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetEntityVisible(npc, true)
    TaskStartScenarioInPlace(npc, "WORLD_HUMAN_STAND_MOBILE", 0, true)

    if Config.Target then
        exports.ox_target:addLocalEntity(npc, {
            {
                distance = 2.0,
                name = 'npcKeys',
                icon = 'fa-solid fa-key',
                label = 'Cerrajero',
                onSelect = function()
                    OpenNPC()
                end,
            },
        })
    else
        lib.points.new({
            coords = vector3(coords.x, coords.y, coords.z),
            distance = 2.5,
            onEnter = function()
                lib.showTextUI("E - Hablar con el cerrajero")
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            nearby = function()
                if IsControlJustPressed(0, 38) then
                    OpenNPC()
                end
            end,
        })
    end
end

OnPlayerReady(CreateNPC)
