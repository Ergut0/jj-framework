-- Registro de cambios: base de datos, consola y webhook de Discord opcional
Logs = {}

Logs.Labels = {
    open = 'Editor abierto',
    apply = 'Cambios temporales',
    restore = 'Valores restaurados',
    expire = 'Prueba terminada',
    create = 'Perfil creado',
    update = 'Perfil editado',
    duplicate = 'Perfil duplicado',
    delete = 'Perfil borrado',
    revert = 'Versión restaurada',
    import = 'Perfil importado',
    export = 'Perfil exportado',
    install = 'Perfil instalado',
    uninstall = 'Perfil desinstalado',
    model_default = 'Perfil de serie',
    model_default_removed = 'Perfil de serie quitado',
    settings = 'Ajustes globales',
}

local COLORS = { delete = 15158332, model_default = 10181046, settings = 10181046, apply = 3447003, restore = 9807270 }

local function webhookUrl()
    local convar = GetConvar('jj_handling_webhook', '')
    if convar ~= '' then return convar end
    return Config.Logs.Webhook or ''
end

local function clean(text)
    return (tostring(text or '-'):gsub('@', '@\226\128\139'):gsub('[`*_~|]', ''))
end

local function sendWebhook(action, actorName, target, summary)
    local url = webhookUrl()
    if url == '' then return end

    local payload = {
        username = 'jj_handling',
        allowed_mentions = { parse = {} },
        embeds = { {
            title = Logs.Labels[action] or action,
            color = COLORS[action] or 5763719,
            fields = {
                { name = 'Quién', value = clean(actorName):sub(1, 250), inline = true },
                { name = 'Objetivo', value = clean(target):sub(1, 250), inline = true },
                { name = 'Detalles', value = clean(summary):sub(1, 1000), inline = false },
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }
    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Resumen legible de los parámetros cambiados, para el webhook y la consola
local function summarize(details)
    if type(details) ~= 'table' then return tostring(details or '') end
    local parts = {}
    for key, value in pairs(details) do
        if type(value) == 'table' then
            local inner = {}
            for k, v in pairs(value) do inner[#inner + 1] = ('%s=%s'):format(k, tostring(v)) end
            table.sort(inner)
            parts[#parts + 1] = ('%s: %s'):format(key, table.concat(inner, ', '))
        else
            parts[#parts + 1] = ('%s: %s'):format(key, tostring(value))
        end
    end
    table.sort(parts)
    return table.concat(parts, ' | ')
end

-- actor: { identifier, name } o nil para el sistema
function Logs.Add(action, actor, target, details)
    actor = actor or { identifier = 'system', name = 'Sistema' }
    local summary = summarize(details)

    if Config.Logs.Database then
        DB.InsertLog(action, actor.identifier, actor.name, target and tostring(target):sub(1, 64) or nil, details and json.encode(details) or nil)
    end
    if Config.Logs.Console then
        print(('[jj_handling] %s · %s · %s · %s'):format(Logs.Labels[action] or action, actor.name, tostring(target or '-'), summary:sub(1, 300)))
    end
    sendWebhook(action, actor.name, target, summary)
end
