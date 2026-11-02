JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

function HasPerms(src)
    if JJ.IsAdmin(src) then return true end

    local license = GetPlayerIdentifierByType(src, 'license')
    for _, allowed in ipairs(Config.Licenses) do
        if allowed == license then return true end
    end

    return false
end

-- Corta el texto y devuelve nil si queda vacío
function CleanText(value, maxLength)
    if type(value) ~= 'string' then return nil end

    local text = value:match('^%s*(.-)%s*$')
    if text == '' then return nil end

    return text:sub(1, maxLength)
end

-- Solo direcciones web: la imagen se carga en la pantalla de todos los jugadores
function CleanUrl(value)
    local url = CleanText(value, 500)
    if not url or not url:match('^https?://[^%s"\'<>]+$') then return nil end

    return url
end

-- El enlace se abre en el navegador de quien lo pulsa: solo se admite Discord
function CleanDiscordUrl(value)
    local url = CleanUrl(value)
    if not url then return nil end

    if url:match('^https://discord%.gg/') or url:match('^https://discord%.com/') or url:match('^https://www%.discord%.com/') then
        return url
    end

    return nil
end

function CleanPrice(value)
    local price = tonumber(value)
    if not price or price ~= price or price < 0 or price > 1000000000 then return nil end

    return math.floor(price)
end
