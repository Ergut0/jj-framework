-- Panel de administración. Cada llamada comprueba el permiso en el servidor y queda registrada
Settings = {}

local values = {}

function Settings.Load()
    values = {}
    for _, row in ipairs(DB.GetSettings()) do
        local ok, decoded = pcall(json.decode, row.value)
        if ok then values[row.name] = decoded end
    end
end

function Settings.Get(name)
    return values[name]
end

function Settings.Set(name, value)
    values[name] = value
    DB.SaveSetting(name, json.encode(value))
end

local ADMIN = { admin = true }
local MAX_AMOUNT = 100000000

local function audit(identifier, target, action, details)
    DB.Log('admin', identifier, target, action, details)
end

local function targetProfile(data)
    if type(data.identifier) ~= 'string' or #data.identifier > 60 then return nil end
    return DB.GetProfile(data.identifier)
end

Security.Register('adminOverview', ADMIN, function()
    local classes = {}
    for _, name in ipairs(Boost.ClassOrder) do
        local class = Config.Classes[name]
        local models = {}
        for index, entry in ipairs(class.models) do
            models[index] = { model = entry.model, label = entry.label, disabled = Settings.Get('model_disabled_' .. entry.model) == true }
        end
        classes[#classes + 1] = {
            name = name, label = class.label, disabled = Settings.Get('class_disabled_' .. name) == true,
            models = models,
        }
    end

    return {
        ok = true,
        stats = DB.GetGlobalStats(),
        active = Contracts.GetActiveList(),
        classes = classes,
        multiplier = tonumber(Settings.Get('reward_multiplier')) or 1.0,
        police = #Bridge.GetPolice(),
    }
end)

Security.Register('adminSearch', ADMIN, function(_, _, _, data)
    local term = Security.CleanText(data.term or '', 60) or ''
    local page = Security.ToInt(data.page or 0, 0, 10000) or 0
    return { ok = true, profiles = DB.SearchProfiles(term, 25, page * 25) }
end)

Security.Register('adminProfile', ADMIN, function(_, _, _, data)
    local profile = targetProfile(data)
    if not profile then return { ok = false, message = Boost.T('no_profile') } end

    local view = Progression.View(profile)
    view.identifier = profile.identifier
    return {
        ok = true,
        profile = view,
        history = DB.GetHistory({ identifier = profile.identifier }, 15, 0),
        transactions = DB.GetTransactions(profile.identifier, 15),
    }
end)

Security.Register('adminAssign', ADMIN, function(_, _, actor, data)
    local profile = targetProfile(data)
    if not profile then return { ok = false, message = Boost.T('no_profile') } end
    if not Config.Classes[data.class] then return { ok = false, message = Boost.T('invalid') } end

    local row, reason = Contracts.CreateOffer(profile.identifier, data.class, { assignedBy = actor })
    if not row then return { ok = false, message = Boost.T(reason or 'internal') } end

    audit(actor, profile.identifier, 'assign_contract', { uid = row.uid, class = row.class, model = row.model })
    return { ok = true, message = Boost.T('saved') }
end)

Security.Register('adminSetXp', ADMIN, function(_, _, actor, data)
    local profile = targetProfile(data)
    local delta = Security.ToInt(data.delta, -MAX_AMOUNT, MAX_AMOUNT)
    if not profile or not delta or delta == 0 then return { ok = false, message = Boost.T('invalid') } end

    DB.AddXp(profile.identifier, delta)
    audit(actor, profile.identifier, 'xp', { delta = delta, before = profile.xp })
    return { ok = true, message = Boost.T('saved') }
end)

Security.Register('adminSetCrypto', { admin = true, lock = true }, function(_, _, actor, data)
    local profile = targetProfile(data)
    local delta = Security.ToInt(data.delta, -MAX_AMOUNT, MAX_AMOUNT)
    if not profile or not delta or delta == 0 then return { ok = false, message = Boost.T('invalid') } end

    local reference = ('admin:%s:%d:%d'):format(actor:sub(-10), os.time(), GetGameTimer())
    if not Economy.Apply(profile.identifier, delta, 'Ajuste de administración', reference) then
        return { ok = false, message = Boost.T('no_crypto') }
    end

    audit(actor, profile.identifier, 'crypto', { delta = delta, before = profile.crypto })
    return { ok = true, message = Boost.T('saved') }
end)

Security.Register('adminHistory', ADMIN, function(_, _, _, data)
    local filter = History.CleanFilter(data)
    if type(data.identifier) == 'string' and data.identifier ~= '' then filter.identifier = data.identifier:sub(1, 60) end
    return { ok = true, history = DB.GetHistory(filter, History.PAGE_SIZE, History.Page(data)), pageSize = History.PAGE_SIZE }
end)

local LOG_CATEGORIES = { admin = true, security = true, police = true, tracker = true, contract = true, store = true, economy = true }

Security.Register('adminLogs', ADMIN, function(_, _, _, data)
    local category = LOG_CATEGORIES[data.category] and data.category or nil
    local page = Security.ToInt(data.page or 0, 0, 10000) or 0
    return { ok = true, logs = DB.GetLogs(category, 50, page * 50) }
end)

Security.Register('adminResetStock', ADMIN, function(_, _, actor)
    Store.ResetStock()
    audit(actor, nil, 'reset_stock')
    return { ok = true, message = Boost.T('saved') }
end)

-- Activar o desactivar clases y modelos, y multiplicador de recompensas
Security.Register('adminConfig', ADMIN, function(_, _, actor, data)
    if data.kind == 'class' and Config.Classes[data.name] then
        Settings.Set('class_disabled_' .. data.name, data.disabled == true)
    elseif data.kind == 'model' and type(data.name) == 'string' then
        local known = false
        for _, class in pairs(Config.Classes) do
            for _, entry in ipairs(class.models) do
                if entry.model == data.name then known = true end
            end
        end
        if not known then return { ok = false, message = Boost.T('invalid') } end
        Settings.Set('model_disabled_' .. data.name, data.disabled == true)
    elseif data.kind == 'multiplier' then
        local value = tonumber(data.value)
        if not value or value < 0.1 or value > 10 then return { ok = false, message = Boost.T('invalid') } end
        Settings.Set('reward_multiplier', value)
    else
        return { ok = false, message = Boost.T('invalid') }
    end

    audit(actor, nil, 'config', { kind = data.kind, name = data.name, disabled = data.disabled, value = data.value })
    return { ok = true, message = Boost.T('saved') }
end)

Security.Register('adminCancelContract', ADMIN, function(_, _, actor, data)
    if type(data.uid) ~= 'string' or not Contracts.Cancel(data.uid) then
        return { ok = false, message = Boost.T('not_found') }
    end
    audit(actor, nil, 'cancel_contract', { uid = data.uid })
    return { ok = true, message = Boost.T('saved') }
end)
