local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local isOpen = false
local isReady = false
local isHidden = false
local isVisible = false
local pending = {}
local suggestions = {}

local function sendToNui(data)
    if isReady then
        SendNUIMessage(data)
    else
        pending[#pending + 1] = data
    end
end

-- Sugerencias

local function addSuggestion(name, help, params, staff)
    if type(name) ~= 'string' then return end
    if name:sub(1, 1) ~= '/' then
        name = '/' .. name
    end

    -- Los comandos sin ayuda llegan del servidor y no pisan una sugerencia ya completa
    local current = suggestions[name]
    if current and (help or '') == '' then return end
    suggestions[name] = { name = name, help = help or '', params = params or {}, staff = staff or (current and current.staff) or false }
end

local function getSuggestions(access)
    local list = {}
    for _, suggestion in pairs(suggestions) do
        if access.staff or not suggestion.staff then
            list[#list + 1] = suggestion
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

for _, command in ipairs(Config.Commands) do
    for _, name in ipairs(command.names) do
        addSuggestion(name, command.help, command.params, command.staff)
    end
end

RegisterNetEvent('chat:addSuggestion', addSuggestion)

RegisterNetEvent('chat:addSuggestions', function(list)
    -- ox_lib a veces envía una sola sugerencia en lugar de una lista
    if list.name then
        list = { list }
    end
    for _, suggestion in ipairs(list) do
        addSuggestion(suggestion.name, suggestion.help, suggestion.params)
    end
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    suggestions[name] = nil
end)

-- Mensajes. Admite el formato del chat de FiveM, así funcionan los demás recursos

local function addMessage(message)
    if type(message) == 'string' then
        message = { args = { message } }
    end
    if type(message) == 'table' then
        sendToNui({ action = 'message', message = message })
    end
end

RegisterNetEvent('chat:addMessage', addMessage)

RegisterNetEvent('chatMessage', function(author, color, text)
    addMessage({ color = color, args = (author and author ~= '') and { author, text } or { text } })
end)

RegisterNetEvent('__cfx_internal:serverPrint', function(text)
    if type(text) == 'string' and text:find('%S') then
        addMessage({ channel = 'system', args = { text } })
    end
end)

RegisterNetEvent('chat:addTemplate', function() end)

local function clearChat()
    sendToNui({ action = 'clear' })
end

RegisterNetEvent('chat:clear', clearChat)

-- Abrir y cerrar

local function closeChat()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    sendToNui({ action = 'close' })
end

-- Devuelve por qué no se puede mostrar el chat, o nil si se puede
local function getHiddenReason()
    if not isReady then return 'la interfaz aún no ha cargado' end
    if isHidden then return 'está oculto con /ocultarchat' end
    if LocalPlayer.state.isLoggedIn ~= true and not JJ.IsSpawned() then return 'todavía no has entrado con un personaje' end
    if IsPauseMenuActive() then return 'el menú de pausa está abierto' end
    return nil
end

local function openChat()
    if isOpen then return end

    local reason = getHiddenReason() or (IsNuiFocused() and 'otra interfaz tiene el foco') or nil
    if reason then
        print(('[jj_chat] No se abre el chat: %s'):format(reason))
        return
    end

    isOpen = true
    SetNuiFocus(true, true)
    sendToNui({ action = 'open', suggestions = getSuggestions({ staff = false }), maxLength = Config.MaxLength })

    -- El chat se abre sin esperar al servidor: los permisos llegan justo después
    CreateThread(function()
        local access = lib.callback.await('jj_chat:server:getAccess', false)
        if access then
            sendToNui({ action = 'access', access = access, suggestions = getSuggestions(access) })
        end
    end)
end

RegisterCommand('jj_chat_open', openChat, false)
RegisterKeyMapping('jj_chat_open', 'Abrir el chat', 'keyboard', Config.DefaultKey)

RegisterNuiCallback('ready', function(_, cb)
    isReady = true
    for _, data in ipairs(pending) do
        SendNUIMessage(data)
    end
    pending = {}
    TriggerServerEvent('jj_chat:server:ready')
    cb('ok')
end)

RegisterNuiCallback('close', function(_, cb)
    closeChat()
    cb('ok')
end)

RegisterNuiCallback('submit', function(data, cb)
    closeChat()
    cb('ok')

    local text = data.text
    if type(text) ~= 'string' or not text:find('%S') then return end
    if text:sub(1, 1) == '/' then
        ExecuteCommand(text:sub(2))
    else
        TriggerServerEvent('jj_chat:server:send', data.channel, text)
    end
end)

-- Comandos locales

RegisterCommand('limpiarchat', clearChat, false)

RegisterCommand('ocultarchat', function()
    isHidden = not isHidden
end, false)

-- El chat no se ve hasta entrar con un personaje ni en el menú de pausa

CreateThread(function()
    while true do
        local visible = getHiddenReason() == nil
        if visible ~= isVisible then
            isVisible = visible
            sendToNui({ action = 'visible', visible = visible })
        end
        Wait(500)
    end
end)

-- Mismos exports que el chat de FiveM, también bajo su nombre

local function provideExport(name, callback)
    exports(name, callback)
    AddEventHandler(('__cfx_export_chat_%s'):format(name), function(setCallback)
        setCallback(callback)
    end)
end

provideExport('addMessage', addMessage)
provideExport('addSuggestion', addSuggestion)
provideExport('removeSuggestion', function(name)
    suggestions[name] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
