Config = {}

-- Objeto de ox_inventory que abre la radio y hace falta para seguir conectado
Config.RadioItem = 'radio'

-- Frecuencias disponibles, con un decimal como máximo
Config.MinFrequency = 1.0
Config.MaxFrequency = 999.9

-- Canal de pma-voice = BaseChannel + frecuencia * 10.
-- Queda por encima de los canales de la policía y de las bandas para no compartir ninguno con ellos
Config.BaseChannel = 1000000

-- Tiempo mínimo entre dos cambios de frecuencia (ms)
Config.ChangeDelay = 1000

-- Frecuencias que puede guardar cada personaje y letras de su nombre
Config.MaxSaved = 20
Config.MaxLabelLength = 24

-- Tiempo mínimo entre dos guardados o borrados (ms)
Config.SaveDelay = 300

-- Tiempo mínimo entre dos invitaciones enviadas (ms)
Config.InviteDelay = 3000

-- Cuánto dura una invitación sin responder (ms) y cuántas puede tener pendientes cada jugador
Config.InviteTime = 300000
Config.MaxInvites = 5

-- Cada cuánto se comprueba que quien está conectado conserva el objeto (ms)
Config.CheckInterval = 5000
