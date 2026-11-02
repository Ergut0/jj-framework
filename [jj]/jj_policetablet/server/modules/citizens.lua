local INVOICE_PAID = { [2] = true, [4] = true }

local CITIZEN_QUERY = [[
    SELECT p.id, p.identifier, p.name, p.charinfo, c.image_url, c.wanted, c.dangerous
    FROM jj_players p
    LEFT JOIN jj_policetablet_citizens c ON c.citizenid = p.identifier
]]

local function toCitizen(row)
    local citizen = CitizenFromRow(row, row)
    citizen.isWanted = IsTrue(row.wanted)
    citizen.isDangerous = IsTrue(row.dangerous)
    return citizen
end

local function toCitizens(rows)
    local citizens = {}
    for index, row in ipairs(rows or {}) do
        citizens[index] = toCitizen(row)
    end
    return citizens
end

local function ensureCitizen(citizenid)
    MySQL.query.await('INSERT IGNORE INTO jj_policetablet_citizens (citizenid) VALUES (?)', { citizenid })
end

local function canAccess(source)
    return HasPerm(source, 'citizens.access')
end

local function getNotes(kind, reference)
    local rows = MySQL.query.await('SELECT id, title, description, pinged, author, date FROM jj_policetablet_notes WHERE kind = ? AND reference = ? ORDER BY id DESC', { kind, reference }) or {}
    for _, row in ipairs(rows) do
        row.pinged = IsTrue(row.pinged)
    end
    return rows
end

local function getBills(citizenid)
    local rows = MySQL.query.await([[SELECT id, amount, title, jail_time, payed, date, agent_name AS agentName, agent_badge AS agentBadge, id_article
        FROM jj_policetablet_bills WHERE citizenid = ? ORDER BY id DESC]], { citizenid }) or {}
    for _, row in ipairs(rows) do
        row.payed = IsTrue(row.payed)
    end
    return rows
end

lib.callback.register('jj_policetablet:callback:getCitizens', function(source)
    WaitForDatabase()
    if not canAccess(source) then return {} end
    return toCitizens(MySQL.query.await(CITIZEN_QUERY .. ' ORDER BY p.name LIMIT 50'))
end)

local function filterCitizens(term)
    local pattern = SearchPattern(term)
    return toCitizens(MySQL.query.await(CITIZEN_QUERY .. ' WHERE p.name LIKE ? OR p.identifier LIKE ? ORDER BY p.name LIMIT 50', { pattern, pattern }))
end

lib.callback.register('jj_policetablet:callback:getCitizensByFilter', function(source, term)
    return canAccess(source) and filterCitizens(term) or {}
end)

lib.callback.register('jj_policetablet:callback:getCitizensIncidents', function(source, term)
    return GetAgent(source) and filterCitizens(term) or {}
end)

lib.callback.register('jj_policetablet:callback:getCitizenById', function(source, citizenid)
    if not canAccess(source) or type(citizenid) ~= 'string' then return nil end

    local row = MySQL.single.await(CITIZEN_QUERY .. ' WHERE p.identifier = ?', { citizenid })
    if not row then return nil end

    local citizen = toCitizen(row)
    citizen.phoneNumber = GetPhoneNumber(citizenid)
    citizen.notes = getNotes('citizen', citizenid)
    citizen.bills = getBills(citizenid)
    citizen.incidents = MySQL.query.await([[SELECT id, title, description, status, date, creator_name AS creatorName, creator_citizenid AS creatorCitizenid
        FROM jj_policetablet_cases WHERE kind = 'incident' AND data LIKE ? ORDER BY id DESC LIMIT 50]], { SearchPattern(citizenid) }) or {}
    for _, incident in ipairs(citizen.incidents) do
        incident.creator = { name = incident.creatorName, citizenid = incident.creatorCitizenid }
    end
    citizen.vehicles = MySQL.query.await([[SELECT v.plate, v.model, v.owner, v.serial AS chassis, v.state, t.image, t.wanted
        FROM jj_vehicles v LEFT JOIN jj_policetablet_vehicles t ON t.plate = v.plate WHERE v.owner = ?]], { citizenid }) or {}
    for index, vehicle in ipairs(citizen.vehicles) do
        vehicle.id = index
        vehicle.wanted = IsTrue(vehicle.wanted)
        vehicle.incauted = vehicle.state == 2 or vehicle.state == 3
    end
    return citizen
end)

local function toggleCitizenFlag(column)
    return function(source, data)
        if not canAccess(source) or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return false end

        ensureCitizen(data.citizenid)
        MySQL.update.await(('UPDATE jj_policetablet_citizens SET %s = NOT %s WHERE citizenid = ?'):format(column, column), { data.citizenid })
        return true
    end
end

lib.callback.register('jj_policetablet:callback:toggleWantedStatus', toggleCitizenFlag('wanted'))
lib.callback.register('jj_policetablet:callback:toggleDangerousStatus', toggleCitizenFlag('dangerous'))

lib.callback.register('jj_policetablet:callback:updateCitizenImage', function(source, data)
    if not canAccess(source) or type(data) ~= 'table' or type(data.citizenid) ~= 'string' then return false end

    ensureCitizen(data.citizenid)
    MySQL.update.await('UPDATE jj_policetablet_citizens SET image_url = ? WHERE citizenid = ?', { CleanUrl(data.imageUrl), data.citizenid })
    return true
end)

local function addNote(source, kind, reference, title, description)
    title = CleanText(title, 120)
    if not title or type(reference) ~= 'string' then return nil end

    local author = JJ.GetPlayer(source).getName()
    local date = Today()
    description = CleanText(description, 4000)
    local id = MySQL.insert.await('INSERT INTO jj_policetablet_notes (kind, reference, title, description, author, date) VALUES (?, ?, ?, ?, ?, ?)', {
        kind, reference, title, description, author, date,
    })

    return { id = id, title = title, description = description or '', pinged = false, author = author, date = date }
end

lib.callback.register('jj_policetablet:callback:addCitizenNote', function(source, data)
    if not canAccess(source) or type(data) ~= 'table' then return nil end
    return addNote(source, 'citizen', data.citizenid, data.title, data.description)
end)

lib.callback.register('jj_policetablet:callback:deleteCitizenNote', function(source, data)
    if not HasPerm(source, 'citizen.notes.delete') or type(data) ~= 'table' then return false end

    MySQL.query.await("DELETE FROM jj_policetablet_notes WHERE id = ? AND kind = 'citizen'", { data.noteId })
    return true
end)

lib.callback.register('jj_policetablet:callback:togglePingedStatus', function(source, data)
    if not canAccess(source) or type(data) ~= 'table' then return false end

    MySQL.update.await("UPDATE jj_policetablet_notes SET pinged = NOT pinged WHERE id = ? AND kind = 'citizen'", { data.noteId })
    return true
end)

-- Cada multa llega también como factura de fd_banking a la cuenta de la policía
local function sendInvoice(citizenid, billId, amount, title)
    if GetResourceState('fd_banking') ~= 'started' or amount <= 0 then return end

    pcall(function()
        local account = exports.fd_banking:getBusinessAccount(POLICE_JOB)
        if account then
            exports.fd_banking:addInvoice(citizenid, account.name, 1, amount, ('[POL-%d] %s'):format(billId, title):sub(1, 250), account.id, true)
        end
    end)
end

lib.callback.register('jj_policetablet:callback:addCitizenBills', function(source, citizenid, bills)
    if not canAccess(source) or type(citizenid) ~= 'string' or type(bills) ~= 'table' then return {} end

    local player = JJ.GetPlayer(source)
    local badge = player.getMetadata('badge_number') or '000'
    local date = Today()
    local created = {}

    for index, bill in ipairs(bills) do
        if index > 30 then break end

        local title = type(bill) == 'table' and CleanText(bill.title, 200)
        local amount = title and math.floor(tonumber(bill.amount) or -1)
        if title and amount >= 0 and amount <= 100000000 then
            local article = CleanText(tostring(bill.id_article or ''), 20)
            local jailTime = CleanText(tostring(bill.jail_time or ''), 20)
            local id = MySQL.insert.await([[INSERT INTO jj_policetablet_bills
                (citizenid, amount, title, id_article, jail_time, agent_citizenid, agent_name, agent_badge, date)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
                citizenid, amount, title, article, jailTime, player.identifier, player.getName(), badge, date,
            })

            sendInvoice(citizenid, id, amount, title)
            created[#created + 1] = {
                id = id, amount = amount, title = title, id_article = article or '', jail_time = jailTime or '',
                payed = false, date = date, agentName = player.getName(), agentBadge = badge,
            }
        end
    end

    return created
end)

lib.callback.register('jj_policetablet:callback:deleteCitizenBill', function(source, billId)
    if not HasPerm(source, 'citizen.bills.delete') then return false end

    MySQL.query.await('DELETE FROM jj_policetablet_bills WHERE id = ?', { billId })
    return true
end)

-- El banco no avisa cuando se paga una factura: se comprueba cada minuto
CreateThread(function()
    WaitForDatabase()

    while true do
        Wait(60000)

        if GetResourceState('fd_banking') == 'started' then
            local ok, rows = pcall(MySQL.query.await, [[SELECT b.id, i.status FROM jj_policetablet_bills b
                INNER JOIN fd_advanced_banking_invoices i ON i.description LIKE CONCAT('[POL-', b.id, ']%')
                WHERE b.payed = 0]])

            for _, row in ipairs(ok and rows or {}) do
                if INVOICE_PAID[row.status] then
                    MySQL.update.await('UPDATE jj_policetablet_bills SET payed = 1 WHERE id = ?', { row.id })
                end
            end
        end
    end
end)

local function getDebtors(minDebt)
    local rows = MySQL.query.await([[SELECT p.id, p.identifier, p.name, p.charinfo, c.image_url, SUM(b.amount) AS debt
        FROM jj_policetablet_bills b
        INNER JOIN jj_players p ON p.identifier = b.citizenid
        LEFT JOIN jj_policetablet_citizens c ON c.citizenid = b.citizenid
        WHERE b.payed = 0
        GROUP BY p.id, p.identifier, p.name, p.charinfo, c.image_url
        HAVING debt >= ?
        ORDER BY debt DESC LIMIT 200]], { minDebt }) or {}

    local debtors = {}
    for index, row in ipairs(rows) do
        local citizen = CitizenFromRow(row, row)
        debtors[index] = {
            id = row.id,
            citizenid = row.identifier,
            imageUrl = row.image_url,
            firstname = citizen.firstname,
            lastname = citizen.lastname,
            debt = tonumber(row.debt) or 0,
        }
    end
    return debtors
end

lib.callback.register('jj_policetablet:callback:getDebtors', function(source)
    return HasPerm(source, 'debtors.access') and getDebtors(1) or {}
end)

lib.callback.register('jj_policetablet:callback:getDebtorsByFilter', function(source, minDebt)
    return HasPerm(source, 'debtors.access') and getDebtors(tonumber(minDebt) or 0) or {}
end)

lib.callback.register('jj_policetablet:callback:openCitizenInventory', function(source, citizenid)
    if not canAccess(source) then return false end

    local target = JJ.GetPlayerByIdentifier(citizenid)
    if not target then
        TriggerClientEvent('jj_policetablet:closedInventory', source)
        TriggerClientEvent('ox_lib:notify', source, { description = 'La persona no está conectada', type = 'error' })
        return false
    end

    exports.ox_inventory:forceOpenInventory(source, 'player', target.source)
    return true
end)

AddEventHandler('ox_inventory:closedInventory', function(playerId)
    TriggerClientEvent('jj_policetablet:closedInventory', playerId)
end)

lib.callback.register('jj_policetablet:callback:getHomeWantedSubjects', function(source)
    if not GetAgent(source) then return {} end
    return toCitizens(MySQL.query.await(CITIZEN_QUERY .. ' WHERE c.wanted = 1 ORDER BY p.name LIMIT 100'))
end)
