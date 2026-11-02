-- Logs de auditoria: base de datos + webhook de Discord opcional
Logs = {}

local function escapeMentions(s)
    return (tostring(s):gsub('@', '@\226\128\139')) -- zero-width space para evitar menciones
end

--- Envia un embed a Discord (si hay webhook). Solo para acciones de Config.WebhookActions.
---@param title string
---@param fields table lista { name, value, inline }
---@param color number|nil
function Logs.Webhook(title, fields, color)
    if not Config.Webhook or Config.Webhook == '' then return end
    local out = {}
    for _, f in ipairs(fields or {}) do
        out[#out + 1] = {
            name = escapeMentions(f.name):sub(1, 250),
            value = escapeMentions(f.value ~= '' and f.value or '-'):sub(1, 1000),
            inline = f.inline ~= false,
        }
    end
    local payload = {
        username = Config.WebhookName,
        allowed_mentions = { parse = {} },
        embeds = { {
            title = escapeMentions(title):sub(1, 250),
            color = color or 3447003,
            fields = out,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

--- Registra una accion.
---@param actor table|nil { cid, name }
---@param action string clave de accion (ej. 'track_save')
---@param details table|nil datos adicionales serializables
---@param isAdmin boolean|nil accion realizada desde el panel admin
function Logs.Add(actor, action, details, isAdmin)
    actor = actor or {}
    local cid, name = actor.cid or '', actor.name or ''
    details = details or {}
    CreateThread(function()
        DB.InsertLog(cid, name, action, json.encode(details), isAdmin and 1 or 0)
    end)
    if Config.WebhookActions[action] then
        local fields = {
            { name = L('wh_actor'), value = ('%s (%s)'):format(name ~= '' and name or 'system', cid ~= '' and cid or '-') },
        }
        local keys = {}
        for k in pairs(details) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local v = details[k]
            if type(v) ~= 'table' then fields[#fields + 1] = { name = k, value = tostring(v) } end
        end
        Logs.Webhook(action, fields, isAdmin and 15158332 or 3447003)
    end
    Utils.Debug('log', action, json.encode(details))
end
