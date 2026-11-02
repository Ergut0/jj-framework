-- Editor: abre la interfaz, aplica en vivo lo que se mueve en ella y la conecta con el servidor
Editor = {}

local editor = nil   -- { vehicle, netId, panelOnly, hidden, data }

function Editor.IsOpen() return editor ~= nil end
function Editor.IsPanelOnly() return editor ~= nil and editor.panelOnly end
function Editor.IsOpenFor(vehicle) return editor ~= nil and editor.vehicle == vehicle end

local function notify(message, kind)
    lib.notify({ description = message, type = kind or 'inform' })
end

-- Datos de los parámetros para la interfaz
local function parameterList()
    local list = {}
    for _, param in ipairs(Parameters.List) do
        list[#list + 1] = {
            key = param.key, category = param.category, label = param.label, desc = param.desc,
            step = param.step, unit = param.unit, int = param.int == true, special = param.special == true,
            alsoIn = Parameters.AlsoIn[param.key],
        }
    end
    return list
end

local function vehicleLabel(vehicle)
    local display = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local label = GetLabelText(display)
    if label == 'NULL' or label == '' then label = display end
    return label
end

local function speedThread()
    CreateThread(function()
        local factor = Config.UI.SpeedUnit == 'mph' and 2.236936 or 3.6
        while editor and editor.vehicle do
            local vehicle = editor.vehicle
            if DoesEntityExist(vehicle) then
                SendNUIMessage({
                    action = 'telemetry',
                    speed = math.floor(GetEntitySpeed(vehicle) * factor + 0.5),
                    gear = GetVehicleCurrentGear(vehicle),
                    rpm = Utils.Round(GetVehicleCurrentRpm(vehicle), 2),
                })
            end
            Wait(Config.UI.RefreshMs)
        end
    end)
end

function Editor.Open()
    if editor then
        if editor.hidden then
            editor.hidden = false
            SendNUIMessage({ action = 'show' })
            SetNuiFocus(true, true)
        end
        return
    end

    local vehicle = cache.vehicle
    local payload = {}
    if vehicle and cache.seat == -1 and NetworkGetEntityIsNetworked(vehicle) then
        payload.netId = VehToNet(vehicle)
        payload.class = GetVehicleClass(vehicle)
        payload.modelName = GetEntityArchetypeName(vehicle)
        payload.original = Handling.Original(vehicle).values
    else
        vehicle = nil
    end

    local result = lib.callback.await('jj_handling:open', false, payload)
    if not result or result.error then
        return notify(result and result.error or Config.Locales.no_permission, 'error')
    end

    editor = { vehicle = result.vehicle and vehicle or nil, netId = payload.netId, panelOnly = result.vehicle == nil, data = result }

    local message = {
        action = 'open',
        data = result,
        parameters = parameterList(),
        categories = Parameters.Categories,
        speedUnit = Config.UI.SpeedUnit,
    }

    if editor.vehicle then
        local original = Handling.Original(vehicle).values
        local allowed = {}
        for _, key in ipairs(result.allowed or {}) do allowed[key] = true end

        local presets = {}
        for _, preset in ipairs(Config.Presets) do
            presets[#presets + 1] = {
                id = preset.id, label = preset.label, desc = preset.desc,
                compatible = Handling.PresetAllowed(preset, result.vehicle.class),
                values = Handling.ResolvePreset(preset, original, result.vehicle.class, allowed, result.rules.maxRelative),
            }
        end

        message.original = original
        message.current = Handling.Read(vehicle)
        message.presets = presets
        message.vehicle = {
            label = vehicleLabel(vehicle),
            modelName = result.vehicle.modelName,
            plate = result.vehicle.plate,
            class = result.vehicle.class,
            workshop = result.vehicle.workshop,
        }
        speedThread()
    end

    SendNUIMessage(message)
    SetNuiFocus(true, true)
end

-- Cierra el editor. Lo que se probó sin aplicar se deshace: el vehículo vuelve a lo que le toca
function Editor.Close()
    if not editor then return end
    local vehicle = editor.vehicle
    editor = nil

    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    lib.callback('jj_handling:close', false, function() end, {})

    if vehicle and DoesEntityExist(vehicle) then
        if cache.vehicle == vehicle and cache.seat == -1 then
            Sync.Refresh(vehicle)
        else
            Handling.Restore(vehicle)
        end
    end
end

-- El servidor ha cambiado los temporales mientras el editor estaba abierto (por ejemplo, se acabó la prueba)
function Editor.OnStateChange(value)
    if not editor or not editor.vehicle then return end
    if not value then
        SendNUIMessage({ action = 'tempCleared' })
    end
end

RegisterNetEvent('jj_handling:client:open', Editor.Open)
RegisterKeyMapping(Config.Command, 'Editor de handling', 'keyboard', '')

-- Callbacks de la interfaz

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    Editor.Close()
end)

-- Ocultar para probar conduciendo. Se vuelve con el mismo comando
RegisterNUICallback('hide', function(_, cb)
    cb({ ok = true })
    if not editor then return end
    editor.hidden = true
    SetNuiFocus(false, false)
    lib.notify({ description = ('Prueba el vehículo. Escribe /%s para volver al editor'):format(Config.Command), type = 'inform', duration = 7000 })
end)

-- Vista previa en vivo, solo en este cliente. Lo valida igual que el servidor para no aplicar nada imposible
RegisterNUICallback('preview', function(data, cb)
    if not editor or not editor.vehicle then return cb({ ok = false }) end
    local result = editor.data
    local allowed = {}
    for _, key in ipairs(result.allowed or {}) do allowed[key] = true end

    local values, errors = Validation.Check(data.values or {}, {
        class = result.vehicle.class, allowed = allowed, maxRelative = result.rules.maxRelative,
        original = Handling.Original(editor.vehicle).values,
    })
    if not values then return cb({ ok = false, errors = errors }) end

    Handling.Apply(editor.vehicle, values)
    cb({ ok = true, warnings = Validation.Warnings(values, Handling.Original(editor.vehicle).values) })
end)

-- Peticiones que van al servidor tal cual
for _, name in ipairs({ 'applyTemp', 'restore', 'save', 'duplicate', 'delete', 'get', 'search', 'history', 'revert', 'export', 'import', 'install', 'uninstall', 'setModelDefault', 'logs', 'settings' }) do
    RegisterNUICallback(name, function(data, cb)
        local result = lib.callback.await('jj_handling:' .. name, false, data or {})
        if not result then return cb({ error = 'Sin respuesta del servidor' }) end
        cb(result)
    end)
end

RegisterNUICallback('notify', function(data, cb)
    cb({ ok = true })
    if type(data.message) == 'string' then notify(data.message:sub(1, 200), data.kind) end
end)

-- Copiar al portapapeles desde la interfaz no siempre funciona en NUI; esto lo hace desde el juego
RegisterNUICallback('copy', function(data, cb)
    cb({ ok = true })
    if type(data.text) == 'string' then lib.setClipboard(data.text) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and editor then
        SetNuiFocus(false, false)
    end
end)
