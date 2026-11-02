-- Todas las consultas SQL del recurso están aquí
DB = {}

local CONTRACT_COLUMNS = [[id, uid, identifier, class, model, label, plate, zone_id, spot_index, dropoff_id,
    reward_money, reward_crypto, reward_xp, status, assigned_by, expires_at, accepted_at, stolen_at, finished_at]]

-- Crea las tablas que falten a partir de sql/install.sql
function DB.Install()
    local file = LoadResourceFile(GetCurrentResourceName(), 'sql/install.sql')
    if not file then return false end

    file = file:gsub('%-%-[^\n]*', '')
    for statement in file:gmatch('[^;]+') do
        if statement:find('%S') then MySQL.query.await(statement) end
    end
    return true
end

-- Perfiles

function DB.GetProfile(identifier)
    return MySQL.single.await('SELECT * FROM jj_boosting_profiles WHERE identifier = ?', { identifier })
end

function DB.CreateProfile(identifier, name)
    return MySQL.insert.await('INSERT IGNORE INTO jj_boosting_profiles (identifier, display_name) VALUES (?, ?)', { identifier, name })
end

function DB.NameExists(name, identifier)
    return MySQL.scalar.await('SELECT 1 FROM jj_boosting_profiles WHERE display_name = ? AND identifier <> ? LIMIT 1', { name, identifier }) ~= nil
end

function DB.UpdateName(identifier, name, now)
    return MySQL.update.await('UPDATE jj_boosting_profiles SET display_name = ?, name_changed_at = ? WHERE identifier = ?', { name, now, identifier })
end

function DB.UpdateAvatar(identifier, url)
    return MySQL.update.await('UPDATE jj_boosting_profiles SET avatar_url = ? WHERE identifier = ?', { url, identifier })
end

function DB.UpdateServices(identifier, services)
    return MySQL.update.await('UPDATE jj_boosting_profiles SET services = ? WHERE identifier = ?', { services, identifier })
end

function DB.Touch(identifier)
    return MySQL.update.await('UPDATE jj_boosting_profiles SET last_activity = CURRENT_TIMESTAMP WHERE identifier = ?', { identifier })
end

-- delta puede ser negativo: la experiencia nunca baja de cero
function DB.AddXp(identifier, delta)
    return MySQL.update.await('UPDATE jj_boosting_profiles SET xp = GREATEST(CAST(xp AS SIGNED) + ?, 0) WHERE identifier = ?', { delta, identifier })
end

function DB.AddResult(identifier, completed, failed, money, crypto)
    return MySQL.update.await([[UPDATE jj_boosting_profiles
        SET completed = completed + ?, failed = failed + ?, money_earned = money_earned + ?, crypto_earned = crypto_earned + ?, last_activity = CURRENT_TIMESTAMP
        WHERE identifier = ?]], { completed, failed, money, crypto, identifier })
end

function DB.SearchProfiles(term, limit, offset)
    local pattern = ('%%%s%%'):format(term:gsub('[%%_]', ''))
    return MySQL.query.await([[SELECT identifier, display_name, xp, crypto, completed, failed, last_activity
        FROM jj_boosting_profiles WHERE display_name LIKE ? OR identifier LIKE ?
        ORDER BY last_activity DESC LIMIT ? OFFSET ?]], { pattern, pattern, limit, offset }) or {}
end

-- Criptomoneda

-- Devuelve false si la referencia ya se usó: una misma operación nunca se aplica dos veces
function DB.InsertTransaction(reference, identifier, amount, reason)
    return (MySQL.update.await('INSERT IGNORE INTO jj_boosting_transactions (reference, identifier, amount, reason) VALUES (?, ?, ?, ?)',
        { reference, identifier, amount, reason }) or 0) > 0
end

function DB.DeleteTransaction(reference)
    return MySQL.update.await('DELETE FROM jj_boosting_transactions WHERE reference = ?', { reference })
end

-- Falla sin tocar nada si el saldo quedaría en negativo
function DB.ApplyCrypto(identifier, amount)
    return (MySQL.update.await('UPDATE jj_boosting_profiles SET crypto = crypto + ? WHERE identifier = ? AND CAST(crypto AS SIGNED) + ? >= 0',
        { amount, identifier, amount }) or 0) > 0
end

function DB.GetTransactions(identifier, limit)
    return MySQL.query.await('SELECT amount, reason, created_at FROM jj_boosting_transactions WHERE identifier = ? ORDER BY id DESC LIMIT ?', { identifier, limit }) or {}
end

-- Contratos

function DB.InsertContract(data)
    return MySQL.insert.await([[INSERT INTO jj_boosting_contracts
        (uid, identifier, class, model, label, plate, zone_id, spot_index, dropoff_id, reward_money, reward_crypto, reward_xp, status, assigned_by, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'offered', ?, ?)]], {
        data.uid, data.identifier, data.class, data.model, data.label, data.plate, data.zone_id, data.spot_index, data.dropoff_id,
        data.reward_money, data.reward_crypto, data.reward_xp, data.assigned_by, data.expires_at,
    })
end

function DB.GetContract(uid)
    return MySQL.single.await(('SELECT %s FROM jj_boosting_contracts WHERE uid = ?'):format(CONTRACT_COLUMNS), { uid })
end

function DB.GetOffers(identifier, now)
    return MySQL.query.await(('SELECT %s FROM jj_boosting_contracts WHERE identifier = ? AND status = ? AND expires_at > ? ORDER BY id DESC'):format(CONTRACT_COLUMNS),
        { identifier, Boost.Status.OFFERED, now }) or {}
end

function DB.CountOffers(identifier, now)
    return MySQL.scalar.await('SELECT COUNT(*) FROM jj_boosting_contracts WHERE identifier = ? AND status = ? AND expires_at > ?',
        { identifier, Boost.Status.OFFERED, now }) or 0
end

-- Cambia de estado solo si sigue en el esperado. Es lo que impide completar un contrato dos veces
function DB.TransitionContract(uid, from, to, fields)
    local sets, params = { 'status = ?' }, { to }
    for _, name in ipairs({ 'expires_at', 'accepted_at', 'stolen_at', 'finished_at' }) do
        if fields and fields[name] then
            sets[#sets + 1] = name .. ' = ?'
            params[#params + 1] = fields[name]
        end
    end
    params[#params + 1] = uid
    params[#params + 1] = from

    return (MySQL.update.await(('UPDATE jj_boosting_contracts SET %s WHERE uid = ? AND status = ?'):format(table.concat(sets, ', ')), params) or 0) > 0
end

-- Al arrancar no hay vehículos: los contratos en marcha se pierden. Devuelve cuáles eran
function DB.GetInterrupted()
    return MySQL.query.await(('SELECT %s FROM jj_boosting_contracts WHERE status IN (?, ?, ?)'):format(CONTRACT_COLUMNS),
        { Boost.Status.SEARCHING, Boost.Status.LOCATED, Boost.Status.STOLEN }) or {}
end

function DB.ExpireOffers(now)
    return MySQL.update.await('UPDATE jj_boosting_contracts SET status = ?, finished_at = ? WHERE status = ? AND expires_at <= ?',
        { Boost.Status.EXPIRED, now, Boost.Status.OFFERED, now })
end

-- Historial

function DB.InsertHistory(data)
    return MySQL.insert.await([[INSERT IGNORE INTO jj_boosting_history
        (contract_uid, identifier, player_name, class, model, label, result, reason, duration, reward_money, reward_crypto, reward_xp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], {
        data.uid, data.identifier, data.player_name, data.class, data.model, data.label, data.result, data.reason, data.duration,
        data.reward_money, data.reward_crypto, data.reward_xp,
    })
end

function DB.GetHistory(filter, limit, offset)
    local where, params = {}, {}
    if filter.identifier then
        where[#where + 1] = 'identifier = ?'
        params[#params + 1] = filter.identifier
    end
    if filter.result then
        where[#where + 1] = 'result = ?'
        params[#params + 1] = filter.result
    end
    if filter.class then
        where[#where + 1] = 'class = ?'
        params[#params + 1] = filter.class
    end
    params[#params + 1] = limit
    params[#params + 1] = offset

    local clause = #where > 0 and ('WHERE ' .. table.concat(where, ' AND ')) or ''
    return MySQL.query.await(('SELECT contract_uid, identifier, player_name, class, model, label, result, reason, duration, reward_money, reward_crypto, reward_xp, created_at FROM jj_boosting_history %s ORDER BY id DESC LIMIT ? OFFSET ?'):format(clause), params) or {}
end

function DB.GetGlobalStats()
    return MySQL.single.await([[SELECT
        (SELECT COUNT(*) FROM jj_boosting_profiles) AS profiles,
        (SELECT COUNT(*) FROM jj_boosting_history WHERE result = 'completed') AS completed,
        (SELECT COUNT(*) FROM jj_boosting_history WHERE result <> 'completed') AS lost,
        (SELECT COALESCE(SUM(reward_money), 0) FROM jj_boosting_history) AS money,
        (SELECT COALESCE(SUM(crypto), 0) FROM jj_boosting_profiles) AS crypto]])
end

-- Clasificación. La columna sale de una lista cerrada, nunca del cliente
local LEADERBOARD_COLUMNS = { xp = 'xp', completed = 'completed', crypto_earned = 'crypto_earned' }

function DB.GetLeaderboard(sort, limit)
    local column = LEADERBOARD_COLUMNS[sort] or 'xp'
    return MySQL.query.await(('SELECT identifier, display_name, avatar_url, xp, completed, crypto_earned, last_activity FROM jj_boosting_profiles ORDER BY %s DESC, identifier LIMIT ?'):format(column), { limit }) or {}
end

-- Tienda

function DB.SetStock(itemId, remaining)
    return MySQL.update.await('INSERT INTO jj_boosting_store_stock (item_id, remaining) VALUES (?, ?) ON DUPLICATE KEY UPDATE remaining = VALUES(remaining)', { itemId, remaining })
end

function DB.GetStock()
    return MySQL.query.await('SELECT item_id, remaining FROM jj_boosting_store_stock') or {}
end

-- Compras simultáneas: solo pasa quien encuentra unidades suficientes
function DB.TakeStock(itemId, quantity)
    return (MySQL.update.await('UPDATE jj_boosting_store_stock SET remaining = remaining - ? WHERE item_id = ? AND remaining >= ?', { quantity, itemId, quantity }) or 0) > 0
end

function DB.ReturnStock(itemId, quantity)
    return MySQL.update.await('UPDATE jj_boosting_store_stock SET remaining = remaining + ? WHERE item_id = ?', { quantity, itemId })
end

function DB.InsertPurchase(reference, identifier, itemId, quantity, price, status)
    return MySQL.insert.await('INSERT INTO jj_boosting_store_purchases (reference, identifier, item_id, quantity, price, status) VALUES (?, ?, ?, ?, ?, ?)',
        { reference, identifier, itemId, quantity, price, status })
end

function DB.GetPendingPurchases(identifier)
    return MySQL.query.await("SELECT id, item_id, quantity, created_at FROM jj_boosting_store_purchases WHERE identifier = ? AND status = 'pending' ORDER BY id", { identifier }) or {}
end

function DB.GetPurchase(id, identifier)
    return MySQL.single.await("SELECT id, item_id, quantity FROM jj_boosting_store_purchases WHERE id = ? AND identifier = ? AND status = 'pending'", { id, identifier })
end

function DB.MarkCollected(id, status)
    return (MySQL.update.await("UPDATE jj_boosting_store_purchases SET status = ?, collected_at = CURRENT_TIMESTAMP WHERE id = ? AND status = 'pending'", { status or 'collected', id }) or 0) > 0
end

function DB.RevertCollected(id)
    return MySQL.update.await("UPDATE jj_boosting_store_purchases SET status = 'pending', collected_at = NULL WHERE id = ?", { id })
end

-- Compras de cada jugador desde que arrancó el recurso, para el límite por jugador
function DB.GetPurchasedSince(identifier, since)
    return MySQL.query.await('SELECT item_id, SUM(quantity) AS total FROM jj_boosting_store_purchases WHERE identifier = ? AND created_at >= FROM_UNIXTIME(?) GROUP BY item_id', { identifier, since }) or {}
end

-- Ajustes del panel

function DB.GetSettings()
    return MySQL.query.await('SELECT name, value FROM jj_boosting_settings') or {}
end

function DB.SaveSetting(name, value)
    return MySQL.update.await('INSERT INTO jj_boosting_settings (name, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)', { name, value })
end

-- Registros

function DB.Log(category, actor, target, action, details)
    Boost.Debug(category, actor or '-', target or '-', action)
    MySQL.insert('INSERT INTO jj_boosting_logs (category, actor, target, action, details) VALUES (?, ?, ?, ?, ?)',
        { category, actor, target, action, details and json.encode(details) or nil })
end

function DB.GetLogs(category, limit, offset)
    if category then
        return MySQL.query.await('SELECT category, actor, target, action, details, created_at FROM jj_boosting_logs WHERE category = ? ORDER BY id DESC LIMIT ? OFFSET ?', { category, limit, offset }) or {}
    end
    return MySQL.query.await('SELECT category, actor, target, action, details, created_at FROM jj_boosting_logs ORDER BY id DESC LIMIT ? OFFSET ?', { limit, offset }) or {}
end

function DB.CleanLogs(days)
    return MySQL.update.await('DELETE FROM jj_boosting_logs WHERE created_at < (NOW() - INTERVAL ? DAY)', { days })
end
