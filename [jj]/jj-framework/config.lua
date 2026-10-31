Config = {}

Config.Locale = 'es'

-- Con jj_multicharacter cada licencia tiene varios personajes y ese recurso se encarga de cargarlos y hacerlos aparecer.
-- Sin él, ponlo en false: cada licencia tiene un personaje que se carga al conectar
Config.Multicharacter = true

-- Permiso ACE que da acceso a los comandos de administración
Config.AdminAce = 'jj.admin'

-- Intervalos en segundos
Config.AutosaveInterval = 300
Config.PositionInterval = 10
Config.PaycheckInterval = 900

-- Tiempo máximo de espera de un callback, en milisegundos
Config.CallbackTimeout = 10000

Config.DefaultModel = 'mp_m_freemode_01'

Config.DefaultSpawn = { x = -269.4, y = -955.3, z = 31.2, heading = 205.8 }

-- Muerte básica. Desactivada porque la gestiona jj_deathsystem: actívala solo si no usas ese recurso
Config.Death = {
    enabled = false,
    respawnTime = 10,
    respawnPoint = { x = 295.8, y = -1446.9, z = 29.9, heading = 49.0 }
}

Config.Accounts = {
    cash = { label = 'Efectivo', start = 500 },
    bank = { label = 'Banco', start = 2500 },
    black = { label = 'Dinero negro', start = 0 }
}

-- Cuenta en la que se ingresa el salario
Config.PaycheckAccount = 'bank'

Config.DefaultJob = 'unemployed'

-- Cada trabajo necesita el grado 0. isBoss marca a quienes dirigen el trabajo
Config.Jobs = {
    unemployed = {
        label = 'Desempleado',
        grades = {
            [0] = { label = 'Desempleado', salary = 0 }
        }
    },
    police = {
        label = 'Policía',
        grades = {
            [0] = { label = 'Cadete', salary = 300 },
            [1] = { label = 'Agente', salary = 450 },
            [2] = { label = 'Sargento', salary = 600 },
            [3] = { label = 'Comisario', salary = 800, isBoss = true }
        }
    },
    ambulance = {
        label = 'Paramédico',
        grades = {
            [0] = { label = 'Practicante', salary = 300 },
            [1] = { label = 'Paramédico', salary = 450 },
            [2] = { label = 'Jefe médico', salary = 750, isBoss = true }
        }
    },
    mechanic = {
        label = 'Mecánico',
        grades = {
            [0] = { label = 'Aprendiz', salary = 250 },
            [1] = { label = 'Mecánico', salary = 400 },
            [2] = { label = 'Jefe de taller', salary = 600, isBoss = true }
        }
    }
}
