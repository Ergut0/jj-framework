Config = {}

-- Comandos. Todos menos ponerbandera son para administradores
Config.FlagStartCommand = 'comenzarbanderas'
Config.PlantFlagCommand = 'ponerbandera'
Config.CheckFlagsCommand = 'comprobarbanderas'
Config.FinishFlagsCommand = 'terminarbanderas'
Config.PanelCommand = 'panelbanderas'       -- Panel de administración

-- Los tiempos, el radio, el máximo y estas dos opciones se pueden cambiar desde el panel, y lo guardado ahí manda sobre lo de aquí
-- Al empezar un evento se quitan las banderas del anterior. Con false se conservan
Config.ClearOnStart = true

Config.RenderDistance = 150.0       -- No tocar
Config.RenderMarkerDistance = 75.0  -- No tocar
Config.RadiusFlag = 60.0            -- Radio de la zona de cada bandera
Config.ActionDistance = 1.5         -- No tocar

Config.SecondsBetweenPlants = 100   -- Segundos entre plante y plante de una misma banda
Config.SecondsToPlant = 10          -- Tiempo que tarda en plantar la bandera
Config.SecondsToCapture = 300       -- Segundos que tarda en capturar
Config.SecondsBetweenDefends = 450  -- Segundos que una banda está protegida tras recibir un ataque
Config.SecondsBetweenAttacks = 300  -- Segundos que una banda espera entre ataque y ataque

Config.MaxFlagsPerGang = 5

-- Durante la captura cuentan los miembros vivos de cada banda dentro de la zona:
-- si no queda ningún atacante se cancela, y si hay defensores se detiene hasta que se vayan
Config.PauseWhenDefended = true

Config.PlantAnim = {
    dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
    anim = 'machinic_loop_mechandplayer'
}

-- Todas las bandas de jj_gangs participan con su color. Aquí se puede cambiar el de alguna por su nombre
Config.DefaultProp = `stt_prop_flagpole_2a`
Config.GangStyles = {
    -- ['Los Tridentes'] = { prop = `stt_prop_flagpole_2a`, color = { 168, 85, 247 }, blipColor = 27 },
}

Config.Locales = {
    ['not_time_passed'] = 'No ha pasado el suficiente tiempo desde la última plantación de bandera',
    ['not_actived'] = 'El evento no está activo',
    ['not_gang'] = 'Tienes que pertenecer a una banda',
    ['press_to_capture'] = '[H] - Capturar la bandera',
    ['seconds_left'] = 'Capturando la bandera: %d s',
    ['contested'] = 'Captura detenida: hay defensores en la zona (%d s)',
    ['being_captured'] = 'Esta bandera ya está siendo capturada',
    ['your_flag'] = 'Esta bandera es de tu banda',
    ['defend_recently'] = 'Esta banda ha recibido un ataque reciente, debes esperar',
    ['attack_recently'] = 'Tu banda ha hecho un ataque recientemente, debes esperar',
    ['in_attack'] = 'Tu banda acaba de empezar un ataque en la posición marcada en el mapa',
    ['in_defend'] = 'Están atacando una bandera de tu banda, la posición se ha marcado en el mapa',
    ['captured'] = 'Tu banda ha capturado la bandera',
    ['lost'] = 'Tu banda ha perdido una bandera',
    ['capture_failed'] = 'La captura se ha cancelado: no queda nadie de la banda atacante en la zona',
    ['defended'] = 'Tu banda ha defendido la bandera',
    ['maximum_flags'] = 'Tu banda ya ha puesto el máximo de banderas',
    ['planting'] = 'Plantando bandera: %d s',
    ['started'] = 'Ha comenzado la captura de banderas',
    ['stopped'] = 'Ha terminado la captura de banderas',
    ['so_close'] = 'No puedes poner una bandera tan cerca de otra',
    ['flags_left'] = 'Bandera plantada. Te quedan %d',
    ['moved'] = 'Te has movido: no se ha plantado la bandera',
    ['too_far'] = 'Estás demasiado lejos de la bandera',
}
