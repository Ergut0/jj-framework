-- Arranque y datos generales de la terminal
local ready = false

MySQL.ready(function()
    if not DB.Install() then
        print('^1[jj_boosting] No se ha podido leer sql/install.sql^7')
        return
    end

    math.randomseed(os.time())
    Settings.Load()
    Contracts.Recover()
    Store.Init()

    if Config.LogRetentionDays > 0 then DB.CleanLogs(Config.LogRetentionDays) end

    ready = true
    print('^2[jj_boosting] Listo^7')

    -- Si el recurso se reinicia con jugadores dentro, se les avisa
    TriggerClientEvent('jj_boosting:client:refresh', -1)
end)

-- Caducidad de las ofertas
CreateThread(function()
    while true do
        Wait(60000)
        if ready then DB.ExpireOffers(os.time()) end
    end
end)

local function classesView(xp)
    local list = {}
    for _, name in ipairs(Boost.ClassOrder) do
        local class = Config.Classes[name]
        local tier = Boost.GetTier(class)
        list[#list + 1] = {
            name = name,
            label = class.label,
            tier = tier.label,
            unlockXp = class.unlockXp,
            unlocked = Boost.IsClassUnlocked(name, xp),
            price = class.purchasePrice or nil,
            hack = tier.hack or nil,
            tracker = tier.tracker or nil,
            guards = (class.guards or tier.guards or 0) > 0 or nil,
            minPolice = class.minPolice,
            money = class.rewards.money,
            crypto = class.rewards.crypto,
            xp = class.rewards.xp,
        }
    end
    return list
end

Security.Register('getDashboard', {}, function(src, player, identifier)
    if not ready then return { ok = false, message = Boost.T('internal') } end

    local profile = Progression.GetProfile(player)
    if not profile then return { ok = false, message = Boost.T('no_profile') } end

    return {
        ok = true,
        locale = Config.Locale,
        cryptoName = Config.CryptoName,
        isAdmin = Bridge.IsAdmin(src, player),
        profile = Progression.View(profile),
        queued = Contracts.IsQueued(identifier),
        active = Contracts.GetActiveView(identifier),
        offers = Contracts.GetOffers(identifier),
        classes = classesView(profile.xp),
        levels = Config.Levels,
    }
end)

-- Solo el contrato en marcha, para reconectar el cliente
Security.Register('getActive', {}, function(_, _, identifier)
    return { ok = true, active = Contracts.GetActiveView(identifier) }
end)

RegisterCommand(Config.Admin.command, function(src)
    if src == 0 then return end
    local player = Bridge.GetPlayer(src)
    if not player or not Bridge.IsAdmin(src, player) then
        if player then
            Security.Flag(src, 'admin_denied', { call = 'command' })
            Bridge.Notify(src, Boost.T('no_permission'), 'error')
        end
        return
    end
    TriggerClientEvent('jj_boosting:client:open', src, 'admin')
end, false)

AddEventHandler('jj:server:playerLoaded', function(src)
    Contracts.OnPlayerLoaded(src)
end)

-- jj:server:playerDropped se lanza antes de borrar al jugador: todavía se puede leer su identificador
AddEventHandler('jj:server:playerDropped', function(src)
    Contracts.OnPlayerDropped(src)
    Security.Clean(src)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then Contracts.CleanupAll() end
end)
