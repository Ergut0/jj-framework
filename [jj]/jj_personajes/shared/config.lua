Config = {}

-- Huecos de personaje de cada licencia. Un administrador los cambia con /setslots <id> <cantidad>
Config.DefaultSlots = 1
Config.MaxSlots = 5

-- Edad permitida al crear un personaje
Config.MinAge = 18
Config.MaxAge = 90

-- Escenario donde esperan los personajes.
-- center: punto medio de la fila, con w hacia donde miran. La cámara se coloca delante de ellos
Config.Stage = {
    center = vector4(-1035.37, -2730.90, 12.76, 325.66), -- Aeropuerto
    spacing = 1.7,        -- metros entre personajes
    hour = 19,            -- hora local del escenario: no cambia la hora del servidor
    minute = 30,
    weather = 'EXTRASUNNY',
    parallax = 0.18,      -- cuánto se mueve la cámara con el ratón
    ghostAlpha = 110,     -- transparencia de la silueta de los huecos libres (0-255)

    -- Animación de espera de cada personaje, por orden
    idles = {
        { dict = 'anim@heists@heist_corona@single_team', anim = 'single_team_loop_boss' },
        { dict = 'mini@strip_club@wade@', anim = 'leadin_loop_idle_a_wade' },
        { dict = 'amb@world_human_hang_out_street@male_c@idle_a', anim = 'idle_a' },
        { dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_a@', anim = 'high_center' },
        { dict = 'amb@world_human_stand_impatient@male@no_sign@idle_a', anim = 'idle_a' },
    },

    -- Saludo al seleccionarlo
    greeting = { dict = 'friends@frj@ig_1', anim = 'wave_a' },
}

-- Altura desde la que baja la cámara al entrar en la ciudad y cuánto tarda (ms)
Config.Arrival = {
    height = 500.0,
    duration = 4500,
}

-- Dónde empieza un personaje nuevo. Los que ya existen vuelven donde estaban,
-- para que salir del servidor no sirva para escapar de ningún sitio
Config.NewCharacterSpawn = vector4(-1035.37, -2730.90, 13.76, 325.66) -- Aeropuerto

-- Objetos que recibe un personaje nuevo
Config.StarterItems = {
    { name = 'phone', amount = 1 },
    {
        name = 'id_card',
        amount = 1,
        metadata = function(player)
            local charinfo = player.getCharInfo()
            -- Mismo formato que los documentos de jj_smallresources: así no se duplica al actualizarlo
            return {
                Name = player.getName(),
                Nation = charinfo.nationality ~= '' and charinfo.nationality or 'Desconocida',
                Birthdate = charinfo.birthdate,
                Gender = charinfo.gender == 0 and 'Hombre' or 'Mujer',
                ID = player.identifier,
            }
        end,
    },
    { name = 'croissant_mixto', amount = 10 },
    { name = 'refresco', amount = 10 },
}

-- Modelo y ropa de un personaje que todavía no tiene aspecto guardado
Config.BaseOutfits = {
    [0] = {
        model = `mp_m_freemode_01`,
        components = {
            { component_id = 3, drawable = 15, texture = 0 },
            { component_id = 4, drawable = 61, texture = 0 },
            { component_id = 6, drawable = 34, texture = 0 },
            { component_id = 8, drawable = 15, texture = 0 },
            { component_id = 11, drawable = 15, texture = 0 },
        },
    },
    [1] = {
        model = `mp_f_freemode_01`,
        components = {
            { component_id = 3, drawable = 15, texture = 0 },
            { component_id = 4, drawable = 15, texture = 3 },
            { component_id = 6, drawable = 35, texture = 0 },
            { component_id = 8, drawable = 14, texture = 0 },
            { component_id = 11, drawable = 15, texture = 3 },
        },
    },
}
