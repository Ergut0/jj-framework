Config = {}

Config.AdminAce = 'jj.admin' -- Quién puede crear y editar bandas con /bandas

-- isBoss puede hacerlo todo. canInvite, canPromote y canKick solo sobre rangos inferiores
Config.Ranks = {
    [0] = { name = 'Oficial' },
    [1] = { name = 'Sub Jefe', canInvite = true, canPromote = true, canKick = true },
    [2] = { name = 'Jefe', isBoss = true },
}
Config.TopRank = 2

Config.InviteDistance = 10.0 -- Distancia máxima al jugador que se invita
Config.InviteTimeout = 60 -- Segundos para aceptar una invitación
Config.PointDistance = 3.0 -- Distancia a la que se usa un punto
Config.ServerPointDistance = 6.0 -- Distancia máxima que acepta el servidor

Config.DefaultRadius = 150.0
Config.MinRadius = 30.0
Config.MaxRadius = 600.0
Config.TerritoryAlpha = 110 -- Transparencia del círculo del mapa (0-255)

-- blip: color del mapa (https://docs.fivem.net/docs/game-references/blips/#blip-colors). hex: color de los grafitis
Config.Colors = {
    { label = 'Rojo', blip = 1, hex = '#e03232' },
    { label = 'Verde', blip = 2, hex = '#4bb543' },
    { label = 'Azul', blip = 3, hex = '#5ab4e6' },
    { label = 'Amarillo', blip = 5, hex = '#f0cb58' },
    { label = 'Morado', blip = 27, hex = '#a855f7' },
    { label = 'Naranja', blip = 47, hex = '#f08a24' },
    { label = 'Rosa', blip = 8, hex = '#f472b6' },
    { label = 'Blanco', blip = 0, hex = '#f4f4f5' },
}

Config.PointTypes = {
    boss = { label = 'Gestión de la banda', prompt = '[E] - Gestionar la banda', marker = 'user-tie' },
    stash = { label = 'Armario', prompt = '[E] - Abrir el armario', marker = 'box-archive' },
    wardrobe = { label = 'Ropero', prompt = '[E] - Abrir el ropero', marker = 'shirt' },
    garage = { label = 'Garaje', marker = 'warehouse' },
    lab = { label = 'Laboratorio', prompt = '[E] - Usar el laboratorio', marker = 'flask' },
}

Config.Stash = { slots = 50, weight = 500000 }

-- Recetas de los laboratorios. inputs = { { item = 'nombre', count = 1 } } si quieres que gasten materiales
Config.Labs = {
    weed = { label = 'Marihuana', output = 'weed_bag', amount = 2, time = 20000, inputs = {} },
    coke = { label = 'Cocaína', output = 'coke_bag', amount = 2, time = 30000, inputs = {} },
    meth = { label = 'Metanfetamina', output = 'meth_bag', amount = 2, time = 40000, inputs = {} },
}

-- Drogas que se venden a los NPC y su pago por unidad en dinero negro
Config.Drugs = {
    weed_bag = { label = 'Marihuana', min = 60, max = 110 },
    coke_bag = { label = 'Cocaína', min = 120, max = 200 },
    meth_bag = { label = 'Metanfetamina', min = 160, max = 260 },
}

Config.Sale = {
    Time = 3000, -- ms que dura la venta
    Cooldown = 8, -- Segundos mínimos entre ventas de un jugador
    PedCooldown = 300, -- Segundos hasta poder volver a venderle al mismo NPC
    MaxUnits = 3, -- Unidades máximas por venta
    MaxPedDistance = 5.0,
    RejectChance = 20, -- % de que el NPC no quiera comprar
    PoliceChance = 40, -- % de que avise a la policía si no quiere
    RivalMultiplier = 1.5, -- Pago en el barrio de otra banda
    OwnMultiplier = 1.0, -- Pago en el barrio propio
    NeutralMultiplier = 1.0, -- Pago fuera de cualquier barrio
    AlertCooldown = 60, -- Segundos mínimos entre avisos de venta a una banda
    BlockedJobs = { police = true, sheriff = true, ambulance = true },
}

Config.Graffiti = {
    Item = false, -- Objeto que se gasta al pintar, por ejemplo 'spray_can'. Con false, no hace falta
    MaxPerGang = 15,
    MinSpacing = 5.0, -- Distancia mínima entre grafitis
    Width = 2.0,
    Height = 2.0,
    PlaceDistance = 3.5, -- Distancia máxima del personaje a la pared
    BlipRadius = 70.0, -- Radio en metros del círculo del mapa
    BlipAlpha = 85, -- Transparencia del círculo (0-255)
    -- Webs de las que se aceptan imágenes. Cada jugador descarga la imagen, así que esa web ve su IP:
    -- con false se acepta cualquiera, y alguien podría usar una web propia para recoger esas IP
    AllowedHosts = { 'imgur.com', 'discordapp.com', 'discordapp.net', 'ibb.co', 'postimg.cc', 'fivemanage.com' },
    PaintTime = 12000, -- ms que se tarda en pintar
    EraseTime = 8000, -- ms que se tarda en borrar
    DrawDistance = 60.0,
    InteractDistance = 2.5,
    ServerDistance = 6.0, -- Distancia máxima que acepta el servidor
    AlertCooldown = 30, -- Segundos mínimos entre avisos del mismo grafiti
}

Config.AlertBlipTime = 60 -- Segundos que dura en el mapa la marca de un aviso

-- Comprobación de las URL de los grafitis, en el cliente y en el servidor

local MAX_URL_LENGTH = 500
local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, webp = true, gif = true }

local function isAllowedHost(host)
    local allowed = Config.Graffiti.AllowedHosts
    if allowed == false then return true end

    for _, name in ipairs(allowed) do
        if host == name or host:sub(-(#name + 1)) == '.' .. name then
            return true
        end
    end
    return false
end

-- Devuelve por qué no se acepta la URL, o nil si vale. Una URL vacía pinta el nombre de la banda
function GetGraffitiUrlError(url)
    if url == nil or url == '' then return nil end
    if type(url) ~= 'string' or #url > MAX_URL_LENGTH or url:find('[%s%c"\'<>\\`]') then
        return 'La URL no es válida'
    end

    local host, path = url:match('^https://([%w%.%-]+)(/[^?#]*)')
    if not host then return 'La URL tiene que empezar por https://' end

    local extension = path:match('%.(%w+)$')
    if not extension or not IMAGE_EXTENSIONS[extension:lower()] then
        return 'Tiene que ser un enlace directo a una imagen (png, jpg, webp o gif)'
    end

    if not isAllowedHost(host:lower()) then
        return ('Esa web no está permitida. Usa: %s'):format(table.concat(Config.Graffiti.AllowedHosts, ', '))
    end
    return nil
end
