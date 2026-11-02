local statuses = {}
local refreshQueued = false

local function decode(value)
    if type(value) ~= 'string' or value == '' then return nil end

    local success, result = pcall(json.decode, value)
    return success and result or nil
end

-- Las tablas de jj_creatorjobs pueden no existir todavía en el primer arranque
local function queryCreator(query, params)
    local success, rows = pcall(MySQL.query.await, query, params)
    return success and rows or {}
end

local function getDutyCounts()
    local counts = {}

    for _, src in pairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        if player then
            local job = player.getJob()
            if job.onDuty then
                counts[job.name] = (counts[job.name] or 0) + 1
            end
        end
    end

    return counts
end

local function getStatus(name, dutyCounts)
    if HasActiveEvent(name) then return 'in_event' end

    return (dutyCounts[name] or 0) > 0 and 'open' or 'closed'
end

local function getMarket(name)
    local market = {}

    for _, row in ipairs(queryCreator('SELECT name, price FROM jobscreator_market WHERE job = ?', { name })) do
        market[#market + 1] = { name = row.name, price = row.price }
    end

    return market
end

-- Coordenadas por defecto: el primer blip del trabajo o, si no tiene, su primer punto
local function getDefaultCoords()
    local coords = {}

    for _, query in ipairs({
        'SELECT job, x, y, z FROM jobscreator_points ORDER BY id DESC',
        'SELECT job, x, y, z FROM jobscreator_blips ORDER BY id DESC',
    }) do
        for _, row in ipairs(queryCreator(query)) do
            coords[row.job] = { x = row.x, y = row.y, z = row.z }
        end
    end

    return coords
end

local function buildBusiness(name, job, row, market, status, defaults)
    row = row or {}

    return {
        name = name,
        label = job.label or name,
        logo = row.logo or defaults.logo or '',
        description = row.description or '',
        discordUrl = row.discord_url or '',
        category = row.category,
        coords = decode(row.coords) or defaults.coords,
        categories = decode(row.categories) or {},
        promotions = decode(row.promotions) or {},
        market = market,
        status = status,
    }
end

local function getBusinesses()
    local rows, markets, logos = {}, {}, {}
    local defaultCoords = getDefaultCoords()
    local dutyCounts = getDutyCounts()

    for _, row in ipairs(MySQL.query.await('SELECT * FROM jj_bizztablet_businesses') or {}) do
        rows[row.name] = row
    end

    for _, row in ipairs(queryCreator('SELECT job, name, price FROM jobscreator_market')) do
        markets[row.job] = markets[row.job] or {}
        table.insert(markets[row.job], { name = row.name, price = row.price })
    end

    for _, row in ipairs(queryCreator('SELECT name, img FROM jobscreator_jobs')) do
        logos[row.name] = CleanUrl(row.img)
    end

    local businesses = {}
    for name, job in pairs(JJ.GetJobs()) do
        if not Config.HiddenJobs[name] then
            businesses[#businesses + 1] = buildBusiness(name, job, rows[name], markets[name] or {},
                getStatus(name, dutyCounts), { logo = logos[name], coords = defaultCoords[name] })
        end
    end

    table.sort(businesses, function(a, b) return a.label < b.label end)
    return businesses
end

local function getOneBusiness(name)
    local job = JJ.GetJobs()[name]
    if not job or Config.HiddenJobs[name] then return nil end

    local row = MySQL.single.await('SELECT * FROM jj_bizztablet_businesses WHERE name = ?', { name })
    local logo = queryCreator('SELECT img FROM jobscreator_jobs WHERE name = ?', { name })[1]

    return buildBusiness(name, job, row, getMarket(name), getStatus(name, getDutyCounts()), {
        logo = logo and CleanUrl(logo.img),
        coords = getDefaultCoords()[name],
    })
end

-- Solo se guarda el nombre y el precio: la etiqueta y la imagen salen siempre del inventario
local function cleanCategories(value, marketItems)
    local categories = {}
    if type(value) ~= 'table' then return categories end

    for index, category in ipairs(value) do
        if index > 30 then break end

        local label = type(category) == 'table' and CleanText(category.label, 60)
        if label then
            local items, seen = {}, {}

            for _, item in ipairs(type(category.items) == 'table' and category.items or {}) do
                local name = type(item) == 'table' and item.name
                local price = name and CleanPrice(item.price)

                if price and marketItems[name] and not seen[name] then
                    seen[name] = true
                    items[#items + 1] = { name = name, price = price }
                end
            end

            categories[#categories + 1] = { id = ('category-%d'):format(index), label = label, items = items }
        end
    end

    return categories
end

local function cleanPromotions(value, marketItems)
    local promotions = {}
    if type(value) ~= 'table' then return promotions end

    for index, promotion in ipairs(value) do
        if index > 30 then break end

        local item = type(promotion) == 'table' and promotion.item
        local name = type(item) == 'table' and item.name
        local original = name and CleanPrice(promotion.originalPrice)
        local promotional = name and CleanPrice(promotion.promotionalPrice)

        if original and promotional and marketItems[name] and original > 0 and promotional < original then
            promotions[#promotions + 1] = {
                id = ('promo-%d'):format(index),
                item = { name = name, price = promotional },
                originalPrice = original,
                promotionalPrice = promotional,
            }
        end
    end

    return promotions
end

local function cleanCoords(value)
    if type(value) ~= 'table' then return nil end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not x or not y or not z then return nil end

    return { x = x, y = y, z = z }
end

lib.callback.register('jj_bizztablet:getData', function(source)
    WaitForDatabase()

    local player = JJ.GetPlayer(source)
    if not player then return false end

    local job = player.getJob()

    return {
        jobs = getBusinesses(),
        events = GetEventsList(),
        currentJob = job.name,
        isBoss = job.isBoss == true,
        hasPerms = HasPerms(source),
    }
end)

lib.callback.register('jj_bizztablet:updateBusiness', function(source, data)
    WaitForDatabase()

    local player = JJ.GetPlayer(source)
    local name = type(data) == 'table' and data.name
    if not player or type(name) ~= 'string' or not JJ.GetJobs()[name] or Config.HiddenJobs[name] then
        return { success = false, error = 'El negocio no existe' }
    end

    local job = player.getJob()
    local admin = HasPerms(source)
    if not admin and not (job.name == name and job.isBoss) then
        return { success = false, error = 'No tienes permiso para editar este negocio' }
    end

    local discordUrl = nil
    if data.discordUrl and data.discordUrl ~= '' then
        discordUrl = CleanDiscordUrl(data.discordUrl)
        if not discordUrl then
            return { success = false, error = 'El enlace de Discord no es válido' }
        end
    end

    local row = MySQL.single.await('SELECT logo, category, coords FROM jj_bizztablet_businesses WHERE name = ?', { name }) or {}
    local logo, category, coords = row.logo, row.category, row.coords

    -- El logo, la categoría y la ubicación solo los cambia un administrador
    if admin then
        logo = CleanUrl(data.logo)
        category = Config.Categories[data.category] and data.category or nil
        local newCoords = cleanCoords(data.coords)
        coords = newCoords and json.encode(newCoords) or nil
    end

    local marketItems = {}
    for _, item in ipairs(getMarket(name)) do
        marketItems[item.name] = true
    end

    MySQL.query.await([[INSERT INTO jj_bizztablet_businesses
        (name, logo, description, discord_url, category, coords, categories, promotions)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE logo = VALUES(logo), description = VALUES(description),
        discord_url = VALUES(discord_url), category = VALUES(category), coords = VALUES(coords),
        categories = VALUES(categories), promotions = VALUES(promotions)]], {
        name,
        logo,
        CleanText(data.description, 1000),
        discordUrl,
        category,
        coords,
        json.encode(cleanCategories(data.categories, marketItems)),
        json.encode(cleanPromotions(data.promotions, marketItems)),
    })

    TriggerClientEvent('jj_bizztablet:updateJob', -1, getOneBusiness(name))

    return { success = true }
end)

lib.callback.register('jj_bizztablet:getRandomEmployee', function(source, name)
    local numbers = {}

    for _, src in pairs(JJ.GetPlayers()) do
        local player = JJ.GetPlayer(src)
        if player and src ~= source then
            local job = player.getJob()
            if job.name == name and job.onDuty then
                local success, number = pcall(function()
                    return exports['lb-phone']:GetEquippedPhoneNumber(src)
                end)
                if success and number then
                    numbers[#numbers + 1] = number
                end
            end
        end
    end

    return numbers[#numbers > 0 and math.random(#numbers) or 0]
end)

local function refreshStatuses()
    local dutyCounts = getDutyCounts()

    for name in pairs(JJ.GetJobs()) do
        local status = getStatus(name, dutyCounts)
        if statuses[name] and statuses[name] ~= status then
            TriggerClientEvent('jj_bizztablet:updateJobStatus', -1, name, status)
        end
        statuses[name] = status
    end
end

-- Varios cambios seguidos solo envían un aviso
function QueueStatusRefresh()
    if refreshQueued then return end

    refreshQueued = true
    SetTimeout(1000, function()
        refreshQueued = false
        refreshStatuses()
    end)
end

AddEventHandler('jj:server:dutyChanged', QueueStatusRefresh)
AddEventHandler('jj:server:jobChanged', QueueStatusRefresh)
AddEventHandler('jj:server:playerLoaded', QueueStatusRefresh)
AddEventHandler('jj:server:playerDropped', QueueStatusRefresh)

-- Los eventos empiezan y terminan sin que nadie haga nada
CreateThread(function()
    WaitForDatabase()

    while true do
        refreshStatuses()
        Wait(60000)
    end
end)
