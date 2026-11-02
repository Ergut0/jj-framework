-- Callbacks de jj-framework (NUI -> cliente -> servidor).
-- Todo se valida aqui: el cliente solo solicita. Respuesta: { ok, data | error, code }.

local buckets = {}

local function rateLimited(src, group)
    local cfg = Config.RateLimit[group] or Config.RateLimit.default
    local now = GetGameTimer()
    local key = ('%d:%s'):format(src, group)
    local b = buckets[key]
    if not b or now >= b.resetAt then
        buckets[key] = { count = 1, resetAt = now + cfg.window }
        return false
    end
    b.count = b.count + 1
    return b.count > cfg.max
end

AddEventHandler('playerDropped', function()
    local prefix = ('%d:'):format(source)
    for key in pairs(buckets) do
        if key:sub(1, #prefix) == prefix then buckets[key] = nil end
    end
end)

--- Registra un callback con rate limit, comprobacion de admin y manejo de errores.
---@param opts table { limit = 'default'|'money'|'admin', admin = boolean }
local function register(name, opts, handler)
    JJ.RegisterCallback('crews:srv:' .. name, function(src, cb, data)
        local function fail(code, ...)
            cb({ ok = false, code = code, error = L('err_' .. code, ...) })
        end

        if not Cache.ready then return fail('generic') end
        if rateLimited(src, opts.limit or 'default') then return fail('rate_limited') end
        if type(data) ~= 'table' then data = {} end

        if opts.admin and not Perms.IsAdmin(src) then
            print(('^1[crews]^7 intento de accion admin sin permiso: %s (id %d) -> %s'):format(GetPlayerName(src) or '?', src, name))
            return fail('no_permission')
        end

        local player = JJ.GetPlayer(src)
        if not player then return fail('generic') end
        local cid = player.identifier
        local pname = Crew.PlayerName(player)
        local ctx = {
            src = src, player = player, cid = cid, name = pname,
            actor = { cid = cid, name = pname, admin = opts.admin == true },
        }

        local ok, a, b = pcall(handler, ctx, data)
        if not ok then
            print(('^1[crews]^7 error en %s: %s'):format(name, tostring(a)))
            return fail('generic')
        end
        if a == true then return cb({ ok = true, data = b }) end
        return fail(b or 'generic')
    end)
end

-- Helpers ----------------------------------------------------------------------

--- Crew del jugador con comprobacion de congelacion y permiso
local function member(ctx, perm, allowFrozen)
    local crew = Crew.GetByCid(ctx.cid)
    if not crew then return nil, 'not_in_crew' end
    if crew.frozen and not allowFrozen then return nil, 'frozen' end
    if perm and not Perms.Has(crew, ctx.cid, perm) then return nil, 'no_permission' end
    return crew
end

local function paginate(page)
    page = Utils.Int(page, 1, 100000) or 1
    return page, Config.PageSize, (page - 1) * Config.PageSize
end

local function cidParam(v)
    local s = Utils.Str(v, 50)
    if not s or s == '' then return nil end
    return s
end

local function reasonParam(v)
    local s = Utils.Str(v, 120)
    if not s or #s < 3 then return nil end
    return s
end

local function crewParam(d)
    local id = Utils.Int(d.id, 1, 2147483647)
    return id and Crew.Get(id) or nil
end

local function decode(s)
    if type(s) ~= 'string' then return {} end
    local ok, v = pcall(json.decode, s)
    return ok and type(v) == 'table' and v or {}
end

local function buildConfig()
    return {
        locale = Config.Locale, currency = Config.Currency, createCost = Settings.createCost,
        maxMembers = Settings.maxMembers, nameMin = Settings.nameMin, nameMax = Settings.nameMax,
        tagMin = Config.TagMin, tagMax = Config.TagMax, allowLogo = Settings.allowLogo, maxRanks = Settings.maxRanks,
        permissionKeys = Config.PermissionKeys, depositAccounts = Config.DepositAccounts,
        maxTransaction = Config.MaxTransaction, pageSize = Config.PageSize, levelPoints = Config.LevelPoints,
        leaderLevel = Config.LeaderRank.level, withdrawAccount = Config.WithdrawAccount,
    }
end

-- Estado / jugador ----------------------------------------------------------------

register('getState', {}, function(ctx)
    local crew = Crew.GetByCid(ctx.cid)
    local invites = {}
    for _, inv in ipairs(DB.GetInvites(ctx.cid)) do
        local c = Crew.Get(inv.crew_id)
        if c then
            invites[#invites + 1] = {
                id = inv.id, crewId = c.id, crewName = c.name, crewTag = c.tag, color = c.color, logo = c.logo,
                invitedBy = inv.invited_by, expiresAt = inv.expires_at, members = Crew.CountMembers(c),
            }
        end
    end
    return true, {
        player = {
            citizenid = ctx.cid, name = ctx.name,
            cash = ctx.player.getMoney('cash'), bank = ctx.player.getMoney('bank'),
        },
        isAdmin = Perms.IsAdmin(ctx.src),
        crew = crew and Crew.Serialize(crew, ctx.cid) or nil,
        invites = invites,
        config = buildConfig(),
    }
end)

register('createCrew', {}, function(ctx, d)
    if Crew.GetByCid(ctx.cid) then return false, 'already_in_crew' end
    return Crew.WithLock('create', function()
        if Crew.GetByCid(ctx.cid) then return false, 'already_in_crew' end
        local ok, clean = Crew.ValidateIdentity(d)
        if not ok then return false, clean end
        local cost, account = Settings.createCost, Config.CreateAccount
        if cost > 0 then
            if (ctx.player.getMoney(account) or 0) < cost then return false, 'no_money' end
            if not ctx.player.removeMoney(account, cost, 'crew-create') then return false, 'no_money' end
        end
        local created, crew = Crew.Create(clean, { cid = ctx.cid, name = ctx.name }, ctx.actor)
        if not created then
            if cost > 0 then ctx.player.addMoney(account, cost, 'crew-create-refund') end
            return false, crew
        end
        return true, { id = crew.id }
    end)
end)

register('updateCrew', {}, function(ctx, d)
    local crew, err = member(ctx, 'editCrew')
    if not crew then return false, err end
    local ok, e = Crew.UpdateStyle(crew, d, ctx.actor)
    return ok, e
end)

register('invite', {}, function(ctx, d)
    local crew, err = member(ctx, 'invite')
    if not crew then return false, err end
    local targetId = Utils.Int(d.targetId, 1, 65535)
    if not targetId then return false, 'invalid_data' end
    local ok, e = Crew.Invite(crew, targetId, ctx.actor)
    return ok, e
end)

register('respondInvite', {}, function(ctx, d)
    local inviteId = Utils.Int(d.inviteId, 1, 2147483647)
    if not inviteId or type(d.accept) ~= 'boolean' then return false, 'invalid_data' end
    local inv = DB.GetInvite(inviteId)
    if not inv or inv.citizenid ~= ctx.cid then return false, 'invite_not_found' end
    if not d.accept then
        DB.DeleteInvite(inv.id)
        return true
    end
    if Crew.GetByCid(ctx.cid) then return false, 'already_in_crew' end
    if inv.expires_at < os.time() then
        DB.DeleteInvite(inv.id)
        return false, 'invite_expired'
    end
    local crew = Crew.Get(inv.crew_id)
    if not crew then return false, 'crew_not_found' end
    if crew.frozen then return false, 'frozen' end
    return Crew.WithLock('c:' .. crew.id, function()
        local ok, e = Crew.AddMember(crew, ctx.cid, ctx.name, nil, ctx.actor)
        return ok, e
    end)
end)

register('leave', {}, function(ctx)
    local crew, err = member(ctx, nil, true)
    if not crew then return false, err end
    if crew.leader == ctx.cid then return false, 'leader_cannot_leave' end
    local ok, e = Crew.RemoveMember(crew, ctx.cid, ctx.actor, 'member_leave')
    return ok, e
end)

register('kick', {}, function(ctx, d)
    local crew, err = member(ctx, 'kick')
    if not crew then return false, err end
    local tcid = cidParam(d.citizenid)
    if not tcid then return false, 'invalid_data' end
    if tcid == ctx.cid then return false, 'cannot_self' end
    if not crew.members[tcid] then return false, 'target_not_member' end
    if crew.leader == tcid then return false, 'leader_target' end
    if not Perms.CanManage(crew, ctx.cid, tcid) then return false, 'hierarchy' end
    local ok, e = Crew.RemoveMember(crew, tcid, ctx.actor, 'member_kick')
    return ok, e
end)

register('setRank', {}, function(ctx, d)
    local crew, err = member(ctx, 'setRank')
    if not crew then return false, err end
    local tcid, rankId = cidParam(d.citizenid), Utils.Int(d.rankId, 1, 2147483647)
    if not tcid or not rankId then return false, 'invalid_data' end
    if tcid == ctx.cid then return false, 'cannot_self' end
    if not crew.members[tcid] then return false, 'target_not_member' end
    if crew.leader == tcid then return false, 'leader_target' end
    if not Perms.CanManage(crew, ctx.cid, tcid) then return false, 'hierarchy' end
    local rank = crew.ranks[rankId]
    if not rank or rank.isLeader then return false, 'rank_invalid' end
    if rank.level >= Perms.Level(crew, ctx.cid) then return false, 'hierarchy' end
    local ok, e = Crew.SetMemberRank(crew, tcid, rankId, ctx.actor)
    return ok, e
end)

register('transferLeader', {}, function(ctx, d)
    local crew, err = member(ctx)
    if not crew then return false, err end
    if crew.leader ~= ctx.cid then return false, 'leader_only' end
    local tcid = cidParam(d.citizenid)
    if not tcid then return false, 'invalid_data' end
    local ok, e = Crew.SetLeader(crew, tcid, ctx.actor)
    return ok, e
end)

register('disband', {}, function(ctx, d)
    local crew, err = member(ctx)
    if not crew then return false, err end
    if crew.leader ~= ctx.cid then return false, 'leader_only' end
    if d.confirm ~= crew.name then return false, 'confirm_mismatch' end
    if crew.money > 0 then return false, 'bank_not_empty' end
    local ok, e = Crew.Delete(crew, ctx.actor)
    return ok, e
end)

-- Banco -----------------------------------------------------------------------------

local function amountParam(v)
    return Utils.Int(v, 1, Config.MaxTransaction)
end

register('deposit', { limit = 'money' }, function(ctx, d)
    local crew, err = member(ctx, 'deposit')
    if not crew then return false, err end
    local amount = amountParam(d.amount)
    if not amount then return false, 'amount_invalid' end
    local account
    for _, a in ipairs(Config.DepositAccounts) do
        if a == d.account then account = a end
    end
    if not account then return false, 'invalid_data' end
    return Crew.WithLock('p:' .. ctx.cid, function()
        if (ctx.player.getMoney(account) or 0) < amount then return false, 'no_money' end
        if not ctx.player.removeMoney(account, amount, 'crew-deposit') then return false, 'no_money' end
        local ok, res = Crew.ChangeMoney(crew, amount, 'deposit', ctx.actor, account)
        if not ok then
            ctx.player.addMoney(account, amount, 'crew-deposit-refund')
            return false, res
        end
        Logs.Add(crew, ctx.actor, 'bank_deposit', { amount = amount, balance = res }, false)
        Crew.RefreshMembers(crew)
        return true, { balance = res }
    end)
end)

register('withdraw', { limit = 'money' }, function(ctx, d)
    local crew, err = member(ctx, 'withdraw')
    if not crew then return false, err end
    local amount = amountParam(d.amount)
    if not amount then return false, 'amount_invalid' end
    return Crew.WithLock('p:' .. ctx.cid, function()
        local ok, res = Crew.ChangeMoney(crew, -amount, 'withdraw', ctx.actor, Config.WithdrawAccount)
        if not ok then return false, res end
        if not ctx.player.addMoney(Config.WithdrawAccount, amount, 'crew-withdraw') then
            Crew.ChangeMoney(crew, amount, 'deposit', ctx.actor, Config.WithdrawAccount)
            return false, 'generic'
        end
        Logs.Add(crew, ctx.actor, 'bank_withdraw', { amount = amount, balance = res }, false)
        Crew.RefreshMembers(crew)
        return true, { balance = res }
    end)
end)

register('getTransactions', {}, function(ctx, d)
    local crew, err = member(ctx, nil, true)
    if not crew then return false, err end
    local page, size, offset = paginate(d.page)
    local rows, total = DB.GetTransactions(crew.id, size, offset)
    local items = {}
    for i, r in ipairs(rows) do
        items[i] = {
            id = r.id, name = r.name, type = r.type, amount = r.amount, balance = r.balance_after,
            note = r.note, createdAt = r.created_at,
        }
    end
    return true, { items = items, total = total, page = page, pageSize = size }
end)

register('getActivity', {}, function(ctx, d)
    local crew, err = member(ctx, nil, true)
    if not crew then return false, err end
    local page, size, offset = paginate(d.page)
    local rows, total = DB.GetCrewLogs(crew.id, size, offset)
    local items = {}
    for i, r in ipairs(rows) do
        items[i] = { id = r.id, actor = r.actor_name, action = r.action, details = decode(r.details), createdAt = r.created_at }
    end
    return true, { items = items, total = total, page = page, pageSize = size }
end)

register('getRanking', {}, function(ctx)
    local crew = Crew.GetByCid(ctx.cid)
    local top, mine = Ranking.Get(crew and crew.id or -1)
    return true, { top = top, mine = mine }
end)

-- Rangos --------------------------------------------------------------------------------

register('createRank', {}, function(ctx, d)
    local crew, err = member(ctx, 'manageRanks')
    if not crew then return false, err end
    local ok, e = Crew.CreateRank(crew, d, ctx.actor)
    return ok, e
end)

register('updateRank', {}, function(ctx, d)
    local crew, err = member(ctx, 'manageRanks')
    if not crew then return false, err end
    local rankId = Utils.Int(d.rankId, 1, 2147483647)
    if not rankId then return false, 'invalid_data' end
    local ok, e = Crew.UpdateRank(crew, rankId, d, ctx.actor)
    return ok, e
end)

register('deleteRank', {}, function(ctx, d)
    local crew, err = member(ctx, 'manageRanks')
    if not crew then return false, err end
    local rankId = Utils.Int(d.rankId, 1, 2147483647)
    if not rankId then return false, 'invalid_data' end
    local ok, e = Crew.DeleteRank(crew, rankId, ctx.actor)
    return ok, e
end)

-- Administracion ----------------------------------------------------------------------------

local ADMIN = { admin = true, limit = 'admin' }

--- Nombre del jugador por citizenid (online o desde la tabla jj_players)
local function playerNameByCid(cid)
    local online = JJ.GetPlayerByIdentifier(cid)
    if online then return Crew.PlayerName(online) end
    local row = DB.FindPlayer(cid)
    if not row then return nil end
    return row.name ~= '' and row.name or cid
end

register('adminList', ADMIN, function(ctx, d)
    local search = Utils.Str(d.search or '', 32)
    if not search then return false, 'invalid_data' end
    search = search:lower()
    local filter = d.filter
    if filter ~= 'frozen' and filter ~= 'active' then filter = 'all' end
    local sort = d.sort
    if sort ~= 'name' and sort ~= 'members' and sort ~= 'created' and sort ~= 'money' then sort = 'points' end

    local list = {}
    for _, crew in pairs(Cache.crews) do
        local pass = true
        if filter == 'frozen' and not crew.frozen then pass = false end
        if filter == 'active' and crew.frozen then pass = false end
        if pass and search ~= '' then
            local leader = crew.members[crew.leader]
            pass = crew.name:lower():find(search, 1, true) or crew.tag:lower():find(search, 1, true)
                or tostring(crew.id) == search or (leader and leader.name:lower():find(search, 1, true))
        end
        if pass then list[#list + 1] = Crew.Summary(crew) end
    end
    table.sort(list, function(a, b)
        if sort == 'name' then return a.name:lower() < b.name:lower() end
        if a[sort] ~= b[sort] then return a[sort] > b[sort] end
        return a.id < b.id
    end)
    local page, size, offset = paginate(d.page)
    local items = {}
    for i = offset + 1, math.min(offset + size, #list) do items[#items + 1] = list[i] end
    return true, { items = items, total = #list, page = page, pageSize = size }
end)

register('adminGetCrew', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    return true, Crew.Serialize(crew)
end)

register('adminCreate', ADMIN, function(ctx, d)
    local lcid = cidParam(d.leaderCid)
    if not lcid then return false, 'invalid_data' end
    return Crew.WithLock('create', function()
        if Crew.GetByCid(lcid) then return false, 'target_in_crew' end
        local lname = playerNameByCid(lcid)
        if not lname then return false, 'player_not_found' end
        local ok, clean = Crew.ValidateIdentity(d)
        if not ok then return false, clean end
        local created, crew = Crew.Create(clean, { cid = lcid, name = lname }, ctx.actor, true)
        if not created then return false, crew end
        return true, { id = crew.id }
    end)
end)

register('adminUpdate', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    return Crew.WithLock('create', function()
        local ok, clean = Crew.ValidateIdentity(d, crew.id)
        if not ok then return false, clean end
        return Crew.UpdateIdentity(crew, clean, ctx.actor)
    end)
end)

register('adminFreeze', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew or type(d.frozen) ~= 'boolean' then return false, 'crew_not_found' end
    return Crew.SetFrozen(crew, d.frozen, ctx.actor)
end)

register('adminDelete', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    return Crew.WithLock('c:' .. crew.id, function() return Crew.Delete(crew, ctx.actor, true) end)
end)

register('adminAddMember', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    local cid = cidParam(d.citizenid)
    if not cid then return false, 'invalid_data' end
    local rankId = d.rankId ~= nil and Utils.Int(d.rankId, 1, 2147483647) or nil
    if d.rankId ~= nil and not rankId then return false, 'invalid_data' end
    return Crew.WithLock('c:' .. crew.id, function()
        local name = playerNameByCid(cid)
        if not name then return false, 'player_not_found' end
        return Crew.AddMember(crew, cid, name, rankId, ctx.actor)
    end)
end)

register('adminKick', ADMIN, function(ctx, d)
    local crew, cid = crewParam(d), cidParam(d.citizenid)
    if not crew then return false, 'crew_not_found' end
    if not cid then return false, 'invalid_data' end
    return Crew.RemoveMember(crew, cid, ctx.actor, 'member_kick')
end)

register('adminSetRank', ADMIN, function(ctx, d)
    local crew, cid, rankId = crewParam(d), cidParam(d.citizenid), Utils.Int(d.rankId, 1, 2147483647)
    if not crew then return false, 'crew_not_found' end
    if not cid or not rankId then return false, 'invalid_data' end
    return Crew.SetMemberRank(crew, cid, rankId, ctx.actor)
end)

register('adminSetLeader', ADMIN, function(ctx, d)
    local crew, cid = crewParam(d), cidParam(d.citizenid)
    if not crew then return false, 'crew_not_found' end
    if not cid then return false, 'invalid_data' end
    return Crew.SetLeader(crew, cid, ctx.actor)
end)

register('adminEditStat', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    local reason = reasonParam(d.reason)
    if not reason then return false, 'reason_required' end
    return Crew.WithLock('c:' .. crew.id, function()
        return Crew.EditStat(crew, d.stat, d.mode, d.value, ctx.actor, reason)
    end)
end)

register('adminCreateRank', ADMIN, function(ctx, d)
    local crew = crewParam(d)
    if not crew then return false, 'crew_not_found' end
    return Crew.CreateRank(crew, d, ctx.actor)
end)

register('adminUpdateRank', ADMIN, function(ctx, d)
    local crew, rankId = crewParam(d), Utils.Int(d.rankId, 1, 2147483647)
    if not crew then return false, 'crew_not_found' end
    if not rankId then return false, 'invalid_data' end
    return Crew.UpdateRank(crew, rankId, d, ctx.actor)
end)

register('adminDeleteRank', ADMIN, function(ctx, d)
    local crew, rankId = crewParam(d), Utils.Int(d.rankId, 1, 2147483647)
    if not crew then return false, 'crew_not_found' end
    if not rankId then return false, 'invalid_data' end
    return Crew.DeleteRank(crew, rankId, ctx.actor)
end)

register('adminLogs', ADMIN, function(ctx, d)
    local filters = {}
    if d.crewId ~= nil then
        filters.crewId = Utils.Int(d.crewId, 1, 2147483647)
        if not filters.crewId then return false, 'invalid_data' end
    end
    if d.action ~= nil and d.action ~= '' then
        filters.action = Utils.Str(d.action, 40)
        if not filters.action then return false, 'invalid_data' end
    end
    if d.search ~= nil and d.search ~= '' then
        filters.search = Utils.Str(d.search, 40)
        if not filters.search then return false, 'invalid_data' end
    end
    local page, size, offset = paginate(d.page)
    local rows, total = DB.GetAdminLogs(filters, size, offset)
    local items = {}
    for i, r in ipairs(rows) do
        items[i] = {
            id = r.id, crewId = r.crew_id, crewName = r.crew_name, actorCid = r.actor_cid, actor = r.actor_name,
            action = r.action, details = decode(r.details), admin = r.is_admin == 1, createdAt = r.created_at,
        }
    end
    return true, { items = items, total = total, page = page, pageSize = size }
end)

register('adminGetSettings', ADMIN, function()
    return true, { values = Settings, schema = SettingsSchema }
end)

register('adminSaveSettings', ADMIN, function(ctx, d)
    return Crew.SaveSettings(d.settings, ctx.actor)
end)
