Config = {}

-- Licencias (license:xxxx) que pueden editar cualquier negocio, además de los administradores del framework
Config.Licenses = {}

-- Trabajos que no aparecen en la tablet
Config.HiddenJobs = {
    unemployed = true,
}

Config.Categories = {
    mechanics = true,
    leisure = true,
    food = true,
    services = true,
}

-- Los eventos terminados o cancelados se borran pasados estos días
Config.EventRetentionDays = 30
-- Eventos sin terminar que puede tener a la vez un mismo trabajo
Config.MaxActiveEventsPerJob = 10
-- Duración máxima de un evento, en horas
Config.MaxEventHours = 72
