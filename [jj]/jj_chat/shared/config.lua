Config = {}

Config.DefaultKey = 'T'
Config.MaxLength = 300
Config.Cooldown = 800 -- ms mínimos entre mensajes de un jugador
Config.ReportCooldown = 60 -- segundos entre reportes de un jugador
Config.DefaultMuteMinutes = 30

-- Permisos que dan acceso al canal de staff y a silenciar
Config.StaffAces = { 'jj.admin', 'jj.mod' }

-- Trabajos sin canal de trabajo
Config.NoJobChannel = { unemployed = true }

-- Distancia en metros de cada canal cercano. ooc = false lo hace global
Config.Distance = {
    say = 15.0,
    shout = 40.0,
    whisper = 3.0,
    ooc = 25.0,
}

-- Comandos que muestra el chat al escribir. Los que tienen channel envían a ese canal
Config.Commands = {
    { names = { 'gritar', 'g' }, channel = 'shout', help = 'Grita: te oyen desde más lejos', params = { { name = 'mensaje' } } },
    { names = { 'susurrar', 's' }, channel = 'whisper', help = 'Susurra: solo te oyen muy cerca', params = { { name = 'mensaje' } } },
    { names = { 'ooc', 'b' }, channel = 'ooc', help = 'Habla fuera de personaje', params = { { name = 'mensaje' } } },
    { names = { 'dep' }, channel = 'job', help = 'Canal de tu trabajo, si estás de servicio', params = { { name = 'mensaje' } } },
    { names = { 'staff' }, channel = 'staff', staff = true, help = 'Canal de staff', params = { { name = 'mensaje' } } },
    { names = { 'mp', 'pm' }, help = 'Mensaje privado', params = { { name = 'id' }, { name = 'mensaje' } } },
    { names = { 'r' }, help = 'Responde al último mensaje privado', params = { { name = 'mensaje' } } },
    { names = { 'reporte' }, help = 'Avisa al staff de un problema', params = { { name = 'mensaje' } } },
    { names = { 'silenciar' }, staff = true, help = 'Silencia a un jugador en el chat', params = { { name = 'id' }, { name = 'minutos' }, { name = 'motivo' } } },
    { names = { 'desilenciar' }, staff = true, help = 'Quita el silencio a un jugador', params = { { name = 'id' } } },
    { names = { 'limpiarchat' }, help = 'Borra tu chat' },
    { names = { 'ocultarchat' }, help = 'Oculta o muestra el chat' },
}
