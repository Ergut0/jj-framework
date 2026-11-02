Perms = {}

--- Comprueba permiso de administrador (jj-framework + ACE). Siempre en el servidor.
function Perms.IsAdmin(src)
    if type(src) ~= 'number' or src <= 0 then return false end
    return JJ.IsAdmin(src) or IsPlayerAceAllowed(tostring(src), Config.AdminAce)
end

--- Nombre legible del personaje (o su identificador si no tiene)
function Perms.PlayerName(p)
    local n = p.getName() or ''
    return n ~= '' and n or p.identifier
end
