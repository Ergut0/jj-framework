-- Nucleo del sistema: cache en memoria, reglas de negocio y exports.
-- Convencion: las funciones de dominio devuelven (true, dato) o (false, claveError).
-- Los permisos del actor se comprueban en callbacks.lua; aqui se validan invariantes.

Crew = {}
Cache = { crews = {}, byCid = {}, ready = false }
Settings = {}

local locks = {}

SettingsSchema = {
    maxMembers          = { t = 'int', min = 2, max = 100 },
    createCost          = { t = 'int', min = 0, max = 100000000 },
    nameMin             = { t = 'int', min = 2, max = 16 },
    nameMax             = { t = 'int', min = 8, max = 40 },
    maxRanks            = { t = 'int', min = 3, max = 20 },
    inviteExpiryMinutes = { t = 'int', min = 1, max = 10080 },
    allowLogo           = { t = 'bool' },
    bannedNames         = { t = 'list', maxItems = 200, maxLen = 32 },
}

local STATS = {
    level  = { min = 1, max = #Config.LevelPoints },
    points = { min = 0, max = 2000000000 },
    wins   = { min = 0, max = 1000000 },
    money  = { min = 0, max = Config.MaxBankBalance },
}

-- Utilidades -----------------------------------------------------------------

--- Exclusion mutua por clave (evita carreras entre peticiones que hacen yield en BD)
function Crew.WithLock(key, fn)
    if locks[key] then return false, 'busy' end
    locks[key] = true
    local ok, a, b, c = pcall(fn)
    locks[key] = nil
    if not ok then error(a, 0) end
    return a, b, c
end

local function srcOf(cid)
    local p = JJ.GetPlayerByIdentifier(cid)
    return p and p.source or nil
end
Crew.SrcOf = srcOf

function Crew.PlayerName(p)
    local n = p.getName() or ''
    return n ~= '' and n or p.identifier
end

function Crew.Get(id) return Cache.crews[id] end
function Crew.GetByCid(cid) local id = Cache.byCid[cid]; return id and Cache.crews[id] or nil end

function Crew.CountMembers(crew)
    local n = 0
    for _ in pairs(crew.members) do n = n + 1 end
    return n
end

local function countRanks(crew)
    local n = 0
    for _ in pairs(crew.ranks) do n = n + 1 end
    return n
end

local function leaderRank(crew)
    for _, r in pairs(crew.ranks) do if r.isLeader then return r end end
end

local function lowestRank(crew)
    local low
    for _, r in pairs(crew.ranks) do
        if not r.isLeader and (not low or r.level < low.level) then low = r end
    end
    return low
end

local function highestNonLeader(crew)
    local top
    for _, r in pairs(crew.ranks) do
        if not r.isLeader and (not top or r.level > top.level) then top = r end
    end
    return top
end

-- Ajustes en vivo -------------------------------------------------------------

--- Valida un valor segun el esquema. Devuelve el valor limpio o nil.
function Crew.ValidateSetting(key, v)
    local def = SettingsSchema[key]
    if not def then return nil end
    if def.t == 'int' then return Utils.Int(v, def.min, def.max) end
    if def.t == 'bool' then return Utils.Bool(v) end
    if def.t == 'list' then
        if type(v) ~= 'table' or #v > def.maxItems then return nil end
        local out = {}
        for _, item in ipairs(v) do
            local s = Utils.Str(item, def.maxLen)
            if not s or s == '' then return nil end
            out[#out + 1] = s
        end
        return out
    end
end

local function loadSettings()
    Settings = Utils.DeepCopy(Config.Settings)
    for _, row in ipairs(DB.GetSettings()) do
        local ok, val = pcall(json.decode, row.value)
        if ok then
            local clean = Crew.ValidateSetting(row.key, val)
            if clean ~= nil then Settings[row.key] = clean end
        end
    end
end

function Crew.SaveSettings(input, actor)
    if type(input) ~= 'table' then return false, 'invalid_data' end
    local clean = {}
    for key in pairs(SettingsSchema) do
        if input[key] ~= nil then
            local v = Crew.ValidateSetting(key, input[key])
            if v == nil then return false, 'setting_invalid' end
            clean[key] = v
        end
    end
    local nMin, nMax = clean.nameMin or Settings.nameMin, clean.nameMax or Settings.nameMax
    if nMin > nMax then return false, 'setting_invalid' end
    for key, v in pairs(clean) do
        DB.SetSetting(key, json.encode(v))
        Settings[key] = v
    end
    Logs.Add(nil, actor, 'settings_update', clean, true)
    return true, Settings
end

-- Carga y sincronizacion -------------------------------------------------------

local function buildCrew(row)
    return {
        id = row.id, name = row.name, tag = row.tag, color = row.color, logo = row.logo or '',
        level = row.level, points = row.points, wins = row.wins, money = row.money,
        frozen = row.frozen == 1 or row.frozen == true, leader = row.leader_cid,
        createdAt = row.created_at, ranks = {}, members = {},
    }
end

local function loadAll()
    Cache.crews, Cache.byCid = {}, {}
    for _, row in ipairs(DB.GetCrews()) do Cache.crews[row.id] = buildCrew(row) end
    for _, r in ipairs(DB.GetRanks()) do
        local crew = Cache.crews[r.crew_id]
        if crew then
            local ok, perms = pcall(json.decode, r.permissions)
            crew.ranks[r.id] = {
                id = r.id, name = r.name, level = r.level, isLeader = r.is_leader == 1,
                permissions = Perms.Sanitize(ok and perms or {}),
            }
        end
    end
    for _, m in ipairs(DB.GetMembers()) do
        local crew = Cache.crews[m.crew_id]
        if crew and crew.ranks[m.rank_id] then
            crew.members[m.citizenid] = { citizenid = m.citizenid, name = m.name, rankId = m.rank_id, joinedAt = m.joined_at }
            Cache.byCid[m.citizenid] = crew.id
        end
    end
    Ranking.Invalidate()
end

--- Publica el crew del jugador en su statebag (otros scripts pueden leerlo) y avisa al cliente
function Crew.SyncPlayer(src)
    if not src then return end
    local p = JJ.GetPlayer(src)
    if not p then return end
    local crew = Crew.GetByCid(p.identifier)
    local rank = crew and Perms.GetRank(crew, p.identifier)
    Player(src).state:set('crew', crew and {
        id = crew.id, name = crew.name, tag = crew.tag, rank = rank and rank.name or nil, rankLevel = rank and rank.level or nil,
    } or nil, true)
    TriggerClientEvent('crews:client:refresh', src)
end

function Crew.RefreshMembers(crew)
    for cid in pairs(crew.members) do
        local src = srcOf(cid)
        if src then Crew.SyncPlayer(src) end
    end
end

local function notifyCid(cid, msg, kind)
    local src = srcOf(cid)
    if src then JJ.Notify(src, msg, kind or 'primary') end
end
Crew.NotifyCid = notifyCid

-- Serializacion hacia la NUI ---------------------------------------------------

local function onlineSet()
    local set = {}
    for _, src in pairs(JJ.GetPlayers()) do
        local p = JJ.GetPlayer(src)
        if p then set[p.identifier] = true end
    end
    return set
end

function Crew.Serialize(crew, viewerCid)
    local online = onlineSet()
    local ranks, members = {}, {}
    for _, r in pairs(crew.ranks) do
        ranks[#ranks + 1] = { id = r.id, name = r.name, level = r.level, isLeader = r.isLeader, permissions = r.permissions }
    end
    table.sort(ranks, function(a, b) return a.level > b.level end)
    for _, m in pairs(crew.members) do
        local r = crew.ranks[m.rankId]
        members[#members + 1] = {
            citizenid = m.citizenid, name = m.name, rankId = m.rankId, rankLevel = r and r.level or 0,
            online = online[m.citizenid] == true, joinedAt = m.joinedAt, isLeader = crew.leader == m.citizenid,
        }
    end
    table.sort(members, function(a, b)
        if a.rankLevel ~= b.rankLevel then return a.rankLevel > b.rankLevel end
        return a.name < b.name
    end)
    local out = {
        id = crew.id, name = crew.name, tag = crew.tag, color = crew.color, logo = crew.logo,
        level = crew.level, points = crew.points, wins = crew.wins, money = crew.money,
        frozen = crew.frozen, leader = crew.leader, createdAt = crew.createdAt,
        nextLevelPoints = Config.LevelPoints[crew.level + 1], ranks = ranks, members = members,
    }
    if viewerCid then
        local rank = Perms.GetRank(crew, viewerCid)
        local perms = {}
        for _, k in ipairs(Config.PermissionKeys) do perms[k] = Perms.Has(crew, viewerCid, k) end
        out.me = {
            citizenid = viewerCid, rankId = rank and rank.id or 0, level = rank and rank.level or 0,
            isLeader = crew.leader == viewerCid, permissions = perms,
        }
    end
    return out
end

function Crew.Summary(crew)
    local leader = crew.members[crew.leader]
    return {
        id = crew.id, name = crew.name, tag = crew.tag, color = crew.color, logo = crew.logo, level = crew.level,
        points = crew.points, wins = crew.wins, money = crew.money, frozen = crew.frozen,
        members = Crew.CountMembers(crew), leaderName = leader and leader.name or '-', createdAt = crew.createdAt,
    }
end

--- Vista reducida y segura (copia) para exports
function Crew.PublicView(crew, cid)
    if not crew then return nil end
    local out = Crew.Summary(crew)
    out.leader = crew.leader
    if cid then
        local rank = Perms.GetRank(crew, cid)
        out.rank = rank and { id = rank.id, name = rank.name, level = rank.level, isLeader = rank.isLeader } or nil
    end
    return out
end

-- Validacion de identidad -------------------------------------------------------

function Crew.ValidateIdentity(data, excludeId)
    if type(data) ~= 'table' then return false, 'invalid_data' end
    local name = Utils.Str(data.name, 64)
    if not name or #name < Settings.nameMin or #name > Settings.nameMax or not name:match('^[%w][%w _%-%.]*$') then
        return false, 'name_invalid'
    end
    if Utils.IsBanned(name, Settings.bannedNames) then return false, 'name_banned' end

    local tag = Utils.Str(data.tag, 16)
    tag = tag and tag:upper() or nil
    if not tag or #tag < Config.TagMin or #tag > Config.TagMax or not tag:match('^[A-Z0-9]+$') then
        return false, 'tag_invalid'
    end
    if Utils.IsBanned(tag, Settings.bannedNames) then return false, 'name_banned' end

    local color = data.color
    if color == nil or color == '' then color = Config.DefaultColor end
    if not Utils.IsHexColor(color) then return false, 'color_invalid' end

    local logo = data.logo
    if logo == nil then logo = '' end
    logo = Utils.Str(logo, 255)
    if not logo or (logo ~= '' and not Settings.allowLogo) or not Utils.IsValidLogo(logo) then
        return false, 'logo_invalid'
    end

    local lname, ltag = name:lower(), tag:lower()
    for id, c in pairs(Cache.crews) do
        if id ~= excludeId then
            if c.name:lower() == lname then return false, 'name_taken' end
            if c.tag:lower() == ltag then return false, 'tag_taken' end
        end
    end
    return true, { name = name, tag = tag, color = color:lower(), logo = logo }
end

-- Crews ----------------------------------------------------------------------------

function Crew.Create(clean, leader, actor, isAdmin)
    local ok, id = pcall(DB.InsertCrew, clean, leader.cid)
    if not ok or not id then return false, 'name_taken' end

    local crew = buildCrew({
        id = id, name = clean.name, tag = clean.tag, color = clean.color, logo = clean.logo, level = 1,
        points = 0, wins = 0, money = 0, frozen = 0, leader_cid = leader.cid, created_at = os.time(),
    })

    local okRanks, err = pcall(function()
        local lr = Config.LeaderRank
        local leaderRankId = DB.InsertRank(id, lr.name, lr.level, true, json.encode(Perms.AllPermissions()))
        crew.ranks[leaderRankId] = { id = leaderRankId, name = lr.name, level = lr.level, isLeader = true, permissions = Perms.AllPermissions() }
        for _, r in ipairs(Config.DefaultRanks) do
            local perms = Perms.Sanitize(r.permissions)
            local rid = DB.InsertRank(id, r.name, r.level, false, json.encode(perms))
            crew.ranks[rid] = { id = rid, name = r.name, level = r.level, isLeader = false, permissions = perms }
        end
        DB.InsertMember(leader.cid, id, leaderRankId, leader.name)
        crew.members[leader.cid] = { citizenid = leader.cid, name = leader.name, rankId = leaderRankId, joinedAt = os.time() }
    end)
    if not okRanks then
        print(('^1[crews]^7 error creando crew %s: %s'):format(clean.name, tostring(err)))
        DB.DeleteCrew(id)
        return false, 'db'
    end

    Cache.crews[id] = crew
    Cache.byCid[leader.cid] = id
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'crew_create', { name = crew.name, tag = crew.tag, leader = leader.name }, isAdmin)
    TriggerEvent('crews:crewCreated', id)
    Crew.SyncPlayer(srcOf(leader.cid))
    return true, crew
end

function Crew.Delete(crew, actor, isAdmin)
    local members = {}
    for cid in pairs(crew.members) do members[#members + 1] = cid end
    DB.DeleteCrew(crew.id)
    Cache.crews[crew.id] = nil
    for _, cid in ipairs(members) do Cache.byCid[cid] = nil end
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'crew_delete', { name = crew.name, money = crew.money }, isAdmin)
    TriggerEvent('crews:crewDeleted', crew.id)
    for _, cid in ipairs(members) do
        local src = srcOf(cid)
        if src then
            Crew.SyncPlayer(src)
            JJ.Notify(src, L('n_disbanded', crew.name), 'error')
        end
    end
    return true
end

function Crew.UpdateIdentity(crew, clean, actor)
    local old = { name = crew.name, tag = crew.tag }
    DB.UpdateIdentity({ id = crew.id, name = clean.name, tag = clean.tag, color = clean.color, logo = clean.logo })
    crew.name, crew.tag, crew.color, crew.logo = clean.name, clean.tag, clean.color, clean.logo
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'crew_update', { oldName = old.name, oldTag = old.tag, name = crew.name, tag = crew.tag }, actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.UpdateStyle(crew, data, actor)
    local color = data.color
    if color == nil then color = crew.color end
    local logo = data.logo
    if logo == nil then logo = crew.logo end
    logo = Utils.Str(logo, 255)
    if not Utils.IsHexColor(color) then return false, 'color_invalid' end
    if not logo or (logo ~= '' and not Settings.allowLogo) or not Utils.IsValidLogo(logo) then return false, 'logo_invalid' end
    DB.UpdateStyle(crew.id, color:lower(), logo)
    crew.color, crew.logo = color:lower(), logo
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'crew_style', { color = crew.color }, actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.SetFrozen(crew, frozen, actor)
    DB.SetFrozen(crew.id, frozen)
    crew.frozen = frozen
    Logs.Add(crew, actor, frozen and 'crew_freeze' or 'crew_unfreeze', { name = crew.name }, true)
    for cid in pairs(crew.members) do
        notifyCid(cid, L(frozen and 'n_frozen' or 'n_unfrozen', crew.name), frozen and 'error' or 'success')
    end
    Crew.RefreshMembers(crew)
    return true
end

-- Miembros -------------------------------------------------------------------------

function Crew.AddMember(crew, cid, name, rankId, actor)
    if Cache.byCid[cid] then return false, 'target_in_crew' end
    if Crew.CountMembers(crew) >= Settings.maxMembers then return false, 'crew_full' end
    local rank = rankId and crew.ranks[rankId] or lowestRank(crew)
    if not rank or rank.isLeader then return false, 'rank_invalid' end
    local ok = pcall(DB.InsertMember, cid, crew.id, rank.id, name)
    if not ok then return false, 'db' end
    crew.members[cid] = { citizenid = cid, name = name, rankId = rank.id, joinedAt = os.time() }
    Cache.byCid[cid] = crew.id
    DB.DeleteInvitesOf(cid)
    Logs.Add(crew, actor, 'member_join', { target = name, targetCid = cid, rank = rank.name }, actor and actor.admin)
    TriggerEvent('crews:memberJoined', crew.id, cid)
    Crew.SyncPlayer(srcOf(cid))
    Crew.RefreshMembers(crew)
    return true
end

--- action: 'member_leave' | 'member_kick'
function Crew.RemoveMember(crew, cid, actor, action)
    local m = crew.members[cid]
    if not m then return false, 'target_not_member' end
    if crew.leader == cid then return false, 'leader_target' end
    DB.DeleteMember(cid)
    crew.members[cid] = nil
    Cache.byCid[cid] = nil
    Logs.Add(crew, actor, action, { target = m.name, targetCid = cid }, actor and actor.admin)
    TriggerEvent('crews:memberLeft', crew.id, cid)
    if action == 'member_kick' then notifyCid(cid, L('n_kicked', crew.name), 'error') end
    Crew.SyncPlayer(srcOf(cid))
    Crew.RefreshMembers(crew)
    return true
end

function Crew.SetMemberRank(crew, cid, rankId, actor)
    local m, rank = crew.members[cid], crew.ranks[rankId]
    if not m then return false, 'target_not_member' end
    if not rank or rank.isLeader then return false, 'rank_invalid' end
    if crew.leader == cid then return false, 'leader_target' end
    local old = crew.ranks[m.rankId]
    DB.SetMemberRank(cid, rank.id)
    m.rankId = rank.id
    Logs.Add(crew, actor, 'member_rank', { target = m.name, from = old and old.name or '-', to = rank.name }, actor and actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.SetLeader(crew, newCid, actor)
    local nm = crew.members[newCid]
    if not nm then return false, 'target_not_member' end
    if crew.leader == newCid then return false, 'cannot_self' end
    local lr, demote = leaderRank(crew), highestNonLeader(crew)
    if not lr or not demote then return false, 'rank_invalid' end
    local oldLeader = crew.members[crew.leader]
    DB.SetLeader(crew.id, newCid)
    DB.SetMemberRank(newCid, lr.id)
    if oldLeader then
        DB.SetMemberRank(oldLeader.citizenid, demote.id)
        oldLeader.rankId = demote.id
    end
    nm.rankId = lr.id
    crew.leader = newCid
    Logs.Add(crew, actor, 'leader_transfer', { from = oldLeader and oldLeader.name or '-', to = nm.name }, actor and actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

-- Rangos ---------------------------------------------------------------------------

--- El actor solo puede crear/editar rangos por debajo del suyo y conceder permisos que posee
local function checkRankAuthority(crew, actor, level, perms)
    if actor.admin or crew.leader == actor.cid then return true end
    if level >= Perms.Level(crew, actor.cid) then return false, 'hierarchy' end
    for k in pairs(perms) do
        if not Perms.Has(crew, actor.cid, k) then return false, 'no_permission' end
    end
    return true
end

local function validRankName(v)
    local name = Utils.Str(v, 24)
    if not name or #name < 2 then return nil end
    return name
end

function Crew.CreateRank(crew, data, actor)
    local name = validRankName(data.name)
    if not name then return false, 'rank_name' end
    local lr = leaderRank(crew)
    local level = Utils.Int(data.level, 1, (lr and lr.level or 99) - 1)
    if not level then return false, 'rank_invalid' end
    if countRanks(crew) >= Settings.maxRanks then return false, 'rank_limit' end
    for _, r in pairs(crew.ranks) do
        if r.level == level then return false, 'rank_level_taken' end
    end
    local perms = Perms.Sanitize(data.permissions)
    local ok, err = checkRankAuthority(crew, actor, level, perms)
    if not ok then return false, err end
    local okIns, id = pcall(DB.InsertRank, crew.id, name, level, false, json.encode(perms))
    if not okIns or not id then return false, 'db' end
    crew.ranks[id] = { id = id, name = name, level = level, isLeader = false, permissions = perms }
    Logs.Add(crew, actor, 'rank_create', { rank = name, level = level }, actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.UpdateRank(crew, rankId, data, actor)
    local rank = crew.ranks[rankId]
    if not rank then return false, 'rank_invalid' end
    if rank.isLeader then return false, 'rank_locked' end
    local name = validRankName(data.name)
    if not name then return false, 'rank_name' end
    local perms = Perms.Sanitize(data.permissions)
    local ok, err = checkRankAuthority(crew, actor, rank.level, perms)
    if not ok then return false, err end
    DB.UpdateRank(rank.id, name, json.encode(perms))
    rank.name, rank.permissions = name, perms
    Logs.Add(crew, actor, 'rank_update', { rank = name }, actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.DeleteRank(crew, rankId, actor)
    local rank = crew.ranks[rankId]
    if not rank then return false, 'rank_invalid' end
    if rank.isLeader then return false, 'rank_locked' end
    local ok, err = checkRankAuthority(crew, actor, rank.level, {})
    if not ok then return false, err end
    for _, m in pairs(crew.members) do
        if m.rankId == rank.id then return false, 'rank_in_use' end
    end
    DB.DeleteRank(rank.id)
    crew.ranks[rank.id] = nil
    Logs.Add(crew, actor, 'rank_delete', { rank = rank.name }, actor.admin)
    Crew.RefreshMembers(crew)
    return true
end

-- Banco y estadisticas ------------------------------------------------------------------

--- Cambia el saldo de forma atomica y registra la transaccion
function Crew.ChangeMoney(crew, delta, txType, actor, note)
    if delta == 0 then return true, crew.money end
    local affected = DB.ChangeMoney(crew.id, delta)
    if not affected or affected < 1 then
        return false, delta < 0 and 'insufficient_funds' or 'bank_full'
    end
    local balance = DB.GetStat('money', crew.id) or crew.money
    crew.money = balance
    DB.InsertTransaction(crew.id, actor and actor.cid, actor and actor.name, txType, delta, balance, note)
    return true, balance
end

--- Cambia level/points/wins/money. mode: 'set' | 'add'. Siempre registra motivo.
function Crew.EditStat(crew, stat, mode, value, actor, reason)
    local range = STATS[stat]
    if not range then return false, 'invalid_data' end
    if mode ~= 'set' and mode ~= 'add' then return false, 'invalid_data' end
    value = Utils.Int(value, -range.max, range.max)
    if not value then return false, 'amount_invalid' end
    local target = mode == 'set' and value or (crew[stat] + value)
    if target < range.min or target > range.max then return false, 'amount_invalid' end
    local before = crew[stat]
    if stat == 'money' then
        local ok, err = Crew.ChangeMoney(crew, target - before, 'admin', actor, reason)
        if not ok then return false, err end
    else
        DB.SetStat(stat, crew.id, target)
        crew[stat] = target
    end
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'stat_' .. stat, { from = before, to = crew[stat], reason = reason }, true)
    Crew.RefreshMembers(crew)
    return true
end

--- Suma (o resta) puntos desde otros recursos. Sube el nivel automaticamente.
function Crew.AddPoints(crew, amount, actor, reason)
    amount = Utils.Int(amount, -1000000000, 1000000000)
    if not amount or amount == 0 then return false, 'amount_invalid' end
    DB.AddPoints(crew.id, amount)
    local before = crew.points
    crew.points = DB.GetStat('points', crew.id) or before
    local newLevel = Utils.LevelFromPoints(crew.points)
    if newLevel > crew.level then
        crew.level = newLevel
        DB.SetStat('level', crew.id, newLevel)
    end
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'points_add', { amount = amount, total = crew.points, reason = reason }, false)
    TriggerEvent('crews:pointsChanged', crew.id, crew.points)
    Crew.RefreshMembers(crew)
    return true
end

function Crew.AddWins(crew, amount, actor, reason)
    amount = Utils.Int(amount, -1000000, 1000000)
    if not amount or amount == 0 then return false, 'amount_invalid' end
    DB.AddWins(crew.id, amount)
    crew.wins = DB.GetStat('wins', crew.id) or crew.wins
    Ranking.Invalidate()
    Logs.Add(crew, actor, 'wins_add', { amount = amount, total = crew.wins, reason = reason }, false)
    Crew.RefreshMembers(crew)
    return true
end

-- Invitaciones -----------------------------------------------------------------------------

function Crew.Invite(crew, targetSrc, actor)
    local target = JJ.GetPlayer(targetSrc)
    if not target then return false, 'target_not_found' end
    local tcid = target.identifier
    if tcid == actor.cid then return false, 'cannot_self' end
    if Cache.byCid[tcid] then return false, 'target_in_crew' end
    if Crew.CountMembers(crew) + DB.CountInvites(crew.id) >= Settings.maxMembers then return false, 'crew_full' end
    if DB.HasInvite(crew.id, tcid) then return false, 'invite_exists' end
    DB.InsertInvite(crew.id, tcid, actor.name, os.time() + Settings.inviteExpiryMinutes * 60)
    Logs.Add(crew, actor, 'member_invite', { target = Crew.PlayerName(target), targetCid = tcid }, false)
    JJ.Notify(targetSrc, L('n_invite_received', crew.name), 'primary', 8000)
    TriggerClientEvent('crews:client:refresh', targetSrc)
    return true
end

-- Arranque ---------------------------------------------------------------------------------------

MySQL.ready(function()
    loadSettings()
    loadAll()
    DB.PurgeInvites()
    if Config.LogRetentionDays > 0 then DB.PurgeLogs(Config.LogRetentionDays) end
    Cache.ready = true
    for _, src in pairs(JJ.GetPlayers()) do
        Crew.SyncPlayer(src)
    end
    print(('^2[crews]^7 %d crews cargados'):format((function() local n = 0 for _ in pairs(Cache.crews) do n = n + 1 end return n end)()))
end)

-- Jugador conectado: sincroniza estado y actualiza nombre guardado
AddEventHandler('jj:server:playerLoaded', function(src)
    local p = JJ.GetPlayer(src)
    if not Cache.ready or not p then return end
    local cid = p.identifier
    local crew = Crew.GetByCid(cid)
    if crew then
        local m, name = crew.members[cid], Crew.PlayerName(p)
        if m and m.name ~= name then
            m.name = name
            DB.SetMemberName(cid, name)
        end
    end
    Crew.SyncPlayer(src)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, src in pairs(JJ.GetPlayers()) do
        Player(src).state:set('crew', nil, true)
    end
end)

-- Exports -------------------------------------------------------------------------------------------

local function exportActor()
    return { cid = '', name = GetInvokingResource() or 'export' }
end

exports('GetPlayerCrew', function(src)
    local p = JJ.GetPlayer(src)
    if not p then return nil end
    local cid = p.identifier
    return Crew.PublicView(Crew.GetByCid(cid), cid)
end)

exports('GetCrewByCitizenId', function(cid)
    if type(cid) ~= 'string' then return nil end
    return Crew.PublicView(Crew.GetByCid(cid), cid)
end)

exports('IsInCrew', function(src, crewId)
    local p = JJ.GetPlayer(src)
    if not p then return false end
    local crew = Crew.GetByCid(p.identifier)
    if not crew then return false end
    return crewId == nil or crew.id == crewId
end)

exports('GetCrew', function(crewId)
    return Crew.PublicView(Crew.Get(tonumber(crewId)))
end)

exports('GetCrewMembers', function(crewId)
    local crew = Crew.Get(tonumber(crewId))
    if not crew then return nil end
    local out = {}
    for cid, m in pairs(crew.members) do out[#out + 1] = { citizenid = cid, name = m.name, rankId = m.rankId } end
    return out
end)

exports('GetAllCrews', function()
    local out = {}
    for _, c in pairs(Cache.crews) do out[#out + 1] = Crew.PublicView(c) end
    return out
end)

exports('AddCrewPoints', function(crewId, amount, reason)
    local crew = Crew.Get(tonumber(crewId))
    if not crew then return false end
    return (Crew.AddPoints(crew, amount, exportActor(), tostring(reason or '')))
end)

exports('AddCrewWin', function(crewId, amount, reason)
    local crew = Crew.Get(tonumber(crewId))
    if not crew then return false end
    return (Crew.AddWins(crew, amount or 1, exportActor(), tostring(reason or '')))
end)

--- amount positivo ingresa, negativo retira (falla si no hay fondos)
exports('AddCrewMoney', function(crewId, amount, reason)
    local crew = Crew.Get(tonumber(crewId))
    amount = Utils.Int(amount, -Config.MaxBankBalance, Config.MaxBankBalance)
    if not crew or not amount or amount == 0 then return false end
    local actor = exportActor()
    local ok = Crew.ChangeMoney(crew, amount, 'export', actor, tostring(reason or ''):sub(1, 120))
    if ok then
        Logs.Add(crew, actor, 'money_export', { amount = amount, reason = reason }, false)
        Crew.RefreshMembers(crew)
    end
    return ok
end)
