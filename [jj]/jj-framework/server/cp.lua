-- CP: monedas de donación. Son de la licencia, no del personaje, así que las comparten todos sus personajes.
-- Los cambios se hacen en la base de datos de una sola vez para que dos compras a la vez no gasten de más
local MAX_AMOUNT = 100000000

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `jj_cp` (
            `license` VARCHAR(60) NOT NULL,
            `amount` INT UNSIGNED NOT NULL DEFAULT 0,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- Licencia de un jugador conectado (por su id) o la licencia tal cual
local function resolveLicense(target)
    if type(target) == 'number' then
        return GetPlayerName(target) and GetPlayerIdentifierByType(target, 'license') or nil
    end
    if type(target) == 'string' and target:match('^license:%x+$') then
        return target
    end
end

local function validAmount(amount)
    local value = math.tointeger(tonumber(amount))
    return value and value > 0 and value <= MAX_AMOUNT and value or nil
end

local function read(license)
    return MySQL.scalar.await('SELECT amount FROM jj_cp WHERE license = ?', { license }) or 0
end

-- Todos los conectados con esa licencia ven el saldo nuevo en los menús
local function sync(license, balance)
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if GetPlayerIdentifierByType(src, 'license') == license then
            Player(src).state:set('cp', balance, true)
        end
    end
end

local function changed(license, action, amount, balance, reason)
    sync(license, balance)
    print(('[jj-framework] CP %s %s %d (saldo %d): %s'):format(license, action, amount, balance, reason or 'sin motivo'))
    TriggerEvent('jj:server:cpChanged', license, action, amount, balance, reason)
end

function JJ.GetCP(target)
    local license = resolveLicense(target)
    return license and read(license) or 0
end

-- Devuelve el saldo nuevo, o nil si no se ha podido
function JJ.AddCP(target, amount, reason)
    local license, value = resolveLicense(target), validAmount(amount)
    if not license or not value then return nil end

    MySQL.update.await('INSERT INTO jj_cp (license, amount) VALUES (?, ?) ON DUPLICATE KEY UPDATE amount = LEAST(amount + VALUES(amount), ?)', { license, value, MAX_AMOUNT })
    local balance = read(license)
    changed(license, 'add', value, balance, reason)
    return balance
end

-- Solo quita si hay saldo suficiente. Devuelve el saldo nuevo, o nil si no se ha podido
function JJ.RemoveCP(target, amount, reason)
    local license, value = resolveLicense(target), validAmount(amount)
    if not license or not value then return nil end

    local affected = MySQL.update.await('UPDATE jj_cp SET amount = amount - ? WHERE license = ? AND amount >= ?', { value, license, value })
    if not affected or affected < 1 then return nil end

    local balance = read(license)
    changed(license, 'remove', value, balance, reason)
    return balance
end

function JJ.SetCP(target, amount, reason)
    local license = resolveLicense(target)
    local value = math.tointeger(tonumber(amount))
    if not license or not value or value < 0 or value > MAX_AMOUNT then return nil end

    MySQL.update.await('INSERT INTO jj_cp (license, amount) VALUES (?, ?) ON DUPLICATE KEY UPDATE amount = VALUES(amount)', { license, value })
    changed(license, 'set', value, value, reason)
    return value
end

exports('GetCP', JJ.GetCP)
exports('AddCP', JJ.AddCP)
exports('RemoveCP', JJ.RemoveCP)
exports('SetCP', JJ.SetCP)

-- Al cargar el personaje se envía su saldo. Las CP que antes se guardaban en el personaje pasan a la licencia
AddEventHandler('jj:server:playerLoaded', function(src)
    local player = JJ.GetPlayer(src)
    if not player then return end

    local old = math.tointeger(tonumber(player.getMetadata('cp')))
    if old and old > 0 then
        player.setMetadata('cp', nil)
        JJ.AddCP(src, old, 'CP del personaje pasadas a la licencia')
    end

    Player(src).state:set('cp', JJ.GetCP(src), true)
end)

-- Comandos para administradores y para la consola, que es la que usa Tebex.
-- El jugador se indica por su id si está conectado, o por su licencia (license:xxxx)

local function reply(src, message, kind)
    if src == 0 then
        print(('[jj-framework] %s'):format(message))
    else
        JJ.Notify(src, message, kind)
    end
end

local function cpCommand(name, usage, handler)
    RegisterCommand(name, function(src, args)
        if src ~= 0 and not JJ.IsAdmin(src) then
            return reply(src, JJ.T('no_permission'), 'error')
        end

        local target = tonumber(args[1]) or args[1]
        local license = resolveLicense(target)
        if not license then
            return reply(src, ('Uso: /%s %s'):format(name, usage), 'error')
        end

        local message, ok = handler(target, args[2], src)
        reply(src, message, ok and 'success' or 'error')
    end, false)
end

local function adminName(src)
    return src == 0 and 'consola' or GetPlayerName(src)
end

cpCommand('darcp', '<id|licencia> <cantidad>', function(target, amount, src)
    local balance = JJ.AddCP(target, amount, ('/darcp de %s'):format(adminName(src)))
    if not balance then return 'La cantidad no es válida', false end

    if type(target) == 'number' then
        JJ.Notify(target, ('Has recibido %d CP. Ahora tienes %d'):format(validAmount(amount), balance), 'success')
    end
    return ('CP entregadas. Saldo: %d'):format(balance), true
end)

cpCommand('quitarcp', '<id|licencia> <cantidad>', function(target, amount, src)
    if not validAmount(amount) then return 'La cantidad no es válida', false end
    local balance = JJ.RemoveCP(target, amount, ('/quitarcp de %s'):format(adminName(src)))
    if not balance then return ('No tiene tantas CP. Saldo: %d'):format(JJ.GetCP(target)), false end
    return ('CP quitadas. Saldo: %d'):format(balance), true
end)

cpCommand('ponercp', '<id|licencia> <cantidad>', function(target, amount, src)
    local balance = JJ.SetCP(target, amount, ('/ponercp de %s'):format(adminName(src)))
    if not balance then return 'La cantidad no es válida', false end
    return ('Saldo de CP: %d'):format(balance), true
end)

cpCommand('vercp', '<id|licencia>', function(target)
    return ('Saldo de CP: %d'):format(JJ.GetCP(target)), true
end)
