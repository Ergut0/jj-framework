local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local announcements = {}
local icons = {}
local ready = false

for _, job in ipairs(Config.Jobs) do
    icons[job.name] = job.icon
end

local function reply(src, message, notifyType)
    if src == 0 then
        print(message)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = message, type = notifyType or 'inform' })
    end
end

local function broadcastAnnouncements()
    TriggerClientEvent('jj_pausemenu:updateAnnouncements', -1, announcements)
end

-- Los negocios son los trabajos de jj_creatorjobs: oxmysql devuelve open como booleano
local function getJobs()
    local success, rows = pcall(MySQL.query.await, 'SELECT name, label, open FROM jobscreator_jobs')
    local jobs = {}

    for _, row in ipairs(success and rows or {}) do
        if not Config.HiddenJobs[row.name] then
            jobs[#jobs + 1] = {
                name = row.name,
                label = row.label,
                icon = icons[row.name] or 'shop',
                open = row.open == true or row.open == 1,
            }
        end
    end

    return jobs
end

lib.callback.register('jj_pausemenu:getData', function()
    while not ready do Wait(100) end

    return { jobs = getJobs(), announcements = announcements }
end)

local function addAnnouncement(message, author)
    message = type(message) == 'string' and message:match('^%s*(.-)%s*$'):sub(1, Config.AnnouncementMaxLength) or ''
    if message == '' then return nil end

    local id = MySQL.insert.await('INSERT INTO jj_pausemenu_announcements (message, author) VALUES (?, ?)', { message, author })
    announcements[#announcements + 1] = { id = id, message = message }
    broadcastAnnouncements()

    return id
end

-- EXPORT: exports.jj_pausemenu:AddAnnouncement('Reinicio a las 18:00', 'Staff')
exports('AddAnnouncement', addAnnouncement)

RegisterCommand('addanuncio', function(src, args)
    if not JJ.IsAdmin(src) then
        reply(src, 'No tienes permiso', 'error')
        return
    end

    local author = src == 0 and 'Consola' or GetPlayerName(src)
    local id = addAnnouncement(table.concat(args, ' '), author)

    if id then
        reply(src, ('Anuncio #%d añadido al menú de pausa'):format(id), 'success')
    else
        reply(src, 'Uso: /addanuncio <mensaje>', 'error')
    end
end, false)

RegisterCommand('quitaranuncio', function(src, args)
    if not JJ.IsAdmin(src) then
        reply(src, 'No tienes permiso', 'error')
        return
    end

    local id = tonumber(args[1])

    for index, announcement in ipairs(announcements) do
        if announcement.id == id then
            MySQL.query.await('DELETE FROM jj_pausemenu_announcements WHERE id = ?', { id })
            table.remove(announcements, index)
            broadcastAnnouncements()
            reply(src, ('Anuncio #%d quitado'):format(id), 'success')
            return
        end
    end

    reply(src, 'Uso: /quitaranuncio <id>. El ID aparece al pasar el ratón por el anuncio', 'error')
end, false)

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `jj_pausemenu_announcements` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `message` VARCHAR(300) NOT NULL,
        `author` VARCHAR(100) DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    for _, row in ipairs(MySQL.query.await('SELECT id, message FROM jj_pausemenu_announcements ORDER BY id') or {}) do
        announcements[#announcements + 1] = { id = row.id, message = row.message }
    end

    ready = true
end)
