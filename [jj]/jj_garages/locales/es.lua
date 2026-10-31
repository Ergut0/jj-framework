local Translations = {
    error = {
        no_vehicles = '¡No hay vehículos en esta ubicación!',
        not_depot = 'Tu vehículo no está en el depósito o esta fuera del garaje',
        not_owned = 'Este vehículo no puede ser almacenado',
        not_correct_type = 'No puedes guardar este tipo de vehículo aquí',
        not_enough = 'No hay suficiente dinero',
        not_driver = 'Debes ser el conductor del vehículo',
        no_access = 'No tienes acceso a este garaje',
        no_spawn = 'Área demasiado concurrida',
        vehicle_occupied = 'No hay espacio disponible para sacar el vehículo',
        vehicle_out = 'El vehículo esta fuera, no puedes sacarlo',
        vehicle_busy = 'Espera un momento antes de volver a intentarlo',
        model_missing = 'El modelo del vehículo no está instalado',
        too_far = 'Estás demasiado lejos del garaje',
        player_not_found = 'Jugador no encontrado',
        invalid_vehicle = 'Modelo de vehículo no válido',
        no_permission = 'No tienes permiso para usar este comando',
    },
    success = {
        vehicle_parked = 'Vehículo Almacenado',
        vehicle_given = 'Vehículo entregado con matrícula %s',
    },
    info = {
        car_e = '[E] - Garaje',
        sea_e = '[E] - Garaje de barcos',
        air_e = '[E] - Hangar',
        rig_e = '[E] - Lote de plataforma',
        depot_e = '[E] - Depósito',
        depot_price = 'Precio: $%s',
    }
}

Lang = {}

function Lang:t(key, ...)
    local value = Translations
    for part in key:gmatch('[^.]+') do
        value = value and value[part]
    end
    if type(value) ~= 'string' then
        return key
    end
    return select('#', ...) > 0 and value:format(...) or value
end
