Perms = {}

local valid = {}
for _, k in ipairs(Config.PermissionKeys) do valid[k] = true end

--- Comprueba permiso de administrador (jj-framework + ACE). Siempre en el servidor.
function Perms.IsAdmin(src)
    if type(src) ~= 'number' or src <= 0 then return false end
    return JJ.IsAdmin(src) or IsPlayerAceAllowed(tostring(src), Config.AdminAce)
end

--- Deja solo claves de permiso conocidas con valor true
function Perms.Sanitize(t)
    local out = {}
    if type(t) ~= 'table' then return out end
    for k in pairs(valid) do
        if t[k] == true then out[k] = true end
    end
    return out
end

function Perms.AllPermissions()
    local out = {}
    for k in pairs(valid) do out[k] = true end
    return out
end

function Perms.GetRank(crew, cid)
    local m = crew.members[cid]
    return m and crew.ranks[m.rankId] or nil, m
end

function Perms.IsLeader(crew, cid) return crew.leader == cid end

function Perms.Has(crew, cid, perm)
    if crew.leader == cid then return true end
    local rank = Perms.GetRank(crew, cid)
    return rank ~= nil and rank.permissions[perm] == true
end

function Perms.Level(crew, cid)
    local rank = Perms.GetRank(crew, cid)
    return rank and rank.level or 0
end

--- El actor solo puede actuar sobre miembros de rango estrictamente inferior
function Perms.CanManage(crew, actorCid, targetCid)
    return Perms.Level(crew, actorCid) > Perms.Level(crew, targetCid)
end
