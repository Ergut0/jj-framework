-- Logs de auditoria: base de datos + webhook de Discord opcional
Logs = {}

local function escapeMentions(s)
    return (tostring(s):gsub('@', '@\226\128\139')) -- zero-width space para evitar menciones
end

local function sendWebhook(crewName, actorName, actorCid, action, details, isAdmin)
    if not Config.Webhook or Config.Webhook == '' then return end
    local lines = {}
    for k, v in pairs(details or {}) do
        lines[#lines + 1] = ('**%s:** %s'):format(escapeMentions(k), escapeMentions(tostring(v)))
    end
    table.sort(lines)
    local payload = {
        username = Config.WebhookName,
        allowed_mentions = { parse = {} },
        embeds = { {
            title = escapeMentions(action),
            color = isAdmin and 15158332 or 3447003,
            description = table.concat(lines, '\n'),
            fields = {
                { name = 'Crew', value = escapeMentions(crewName ~= '' and crewName or '-'), inline = true },
                { name = 'Actor', value = escapeMentions(('%s (%s)'):format(actorName ~= '' and actorName or 'system', actorCid ~= '' and actorCid or '-')), inline = true },
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }
    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

--- Registra una accion.
---@param crew table|nil crew afectado (id, name)
---@param actor table|nil { cid, name }
---@param action string clave de accion (ej. 'member_kick')
---@param details table|nil datos adicionales serializables
---@param isAdmin boolean|nil accion realizada desde el panel admin (oculta a jugadores)
function Logs.Add(crew, actor, action, details, isAdmin)
    actor = actor or {}
    local crewId = crew and crew.id or 0
    local crewName = crew and crew.name or ''
    local cid, name = actor.cid or '', actor.name or ''
    CreateThread(function()
        DB.InsertLog(crewId, crewName, cid, name, action, json.encode(details or {}), isAdmin and 1 or 0)
    end)
    sendWebhook(crewName, name, cid, action, details, isAdmin)
    Utils.Debug('log', crewName, action, json.encode(details or {}))
end
