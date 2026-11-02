JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local locales = {
    es = {
        no_profile = 'No se ha podido cargar tu perfil',
        too_fast = 'Espera un momento antes de repetirlo',
        not_found = 'Ese contrato ya no está disponible',
        already_active = 'Ya tienes un contrato en marcha',
        class_locked = 'Todavía no tienes esa clase desbloqueada',
        no_police = 'No hay suficientes policías de servicio para este contrato',
        no_crypto = 'No tienes suficiente criptomoneda',
        not_for_sale = 'Ese contrato no está a la venta',
        offers_full = 'Ya tienes el máximo de contratos pendientes',
        no_model = 'No hay vehículos disponibles para esa clase',
        new_offer = 'Tienes un contrato nuevo en la terminal',
        queue_joined = 'Has entrado en la cola de contratos',
        queue_left = 'Has salido de la cola de contratos',
        accepted = 'Contrato aceptado: busca el vehículo en la zona marcada',
        zone_entered = 'Estás en la zona: busca un %s con matrícula %s',
        locked_hint = 'El vehículo tiene cerradura electrónica: tienes que hackearla',
        unlocked = 'Cerradura abierta',
        stolen = 'Vehículo robado: llévalo al punto de entrega',
        tracker_on = 'El vehículo lleva un rastreador activo',
        tracker_off = 'Rastreador desactivado',
        tracker_wait = 'Todavía no puedes acceder al rastreador',
        tracker_item = 'Necesitas el objeto para desactivar el rastreador',
        too_far = 'Estás demasiado lejos',
        hack_failed = 'Hackeo fallido. Intentos restantes: %d',
        hack_lost = 'Te has quedado sin intentos',
        alarm = '¡Ha saltado la alarma del vehículo!',
        deliver_far = 'El vehículo no está en el punto de entrega',
        deliver_moving = 'Para el vehículo para entregarlo',
        deliver_invalid = 'Este vehículo no es válido para el contrato',
        completed = 'Contrato completado: +%d$ · +%d %s · +%d EXP',
        failed = 'Contrato perdido',
        expired = 'El contrato ha caducado',
        given_up = 'Has abandonado el contrato',
        name_invalid = 'El nombre no es válido',
        name_taken = 'Ese nombre ya está en uso',
        name_cooldown = 'Todavía no puedes volver a cambiar el nombre',
        avatar_invalid = 'La imagen tiene que ser https y de un dominio permitido',
        saved = 'Cambios guardados',
        store_unknown = 'Ese artículo no existe',
        store_no_stock = 'No queda stock suficiente',
        store_limit = 'Has alcanzado el límite de compra de este artículo',
        store_locked = 'Necesitas desbloquear una clase superior',
        store_no_space = 'No te cabe en el inventario',
        store_bought = 'Compra realizada',
        store_pickup = 'Compra realizada: recógela en el punto de recogida',
        pickup_far = 'Tienes que estar en el punto de recogida',
        no_permission = 'No tienes permiso',
        invalid = 'Datos no válidos',
        internal = 'Ha ocurrido un error',
    },
    en = {
        no_profile = 'Your profile could not be loaded',
        too_fast = 'Wait a moment before trying again',
        not_found = 'That contract is no longer available',
        already_active = 'You already have a contract in progress',
        class_locked = 'You have not unlocked that class yet',
        no_police = 'Not enough police on duty for this contract',
        no_crypto = 'Not enough crypto',
        not_for_sale = 'That contract is not for sale',
        offers_full = 'You already have the maximum of pending contracts',
        no_model = 'No vehicles available for that class',
        new_offer = 'You have a new contract at the terminal',
        queue_joined = 'You joined the contract queue',
        queue_left = 'You left the contract queue',
        accepted = 'Contract accepted: search the marked area for the vehicle',
        zone_entered = 'You are in the area: look for a %s with plate %s',
        locked_hint = 'The vehicle has an electronic lock: you have to hack it',
        unlocked = 'Lock open',
        stolen = 'Vehicle stolen: take it to the drop-off',
        tracker_on = 'The vehicle has an active tracker',
        tracker_off = 'Tracker disabled',
        tracker_wait = 'You cannot reach the tracker yet',
        tracker_item = 'You need the item to disable the tracker',
        too_far = 'You are too far away',
        hack_failed = 'Hack failed. Attempts left: %d',
        hack_lost = 'You ran out of attempts',
        alarm = 'The vehicle alarm went off!',
        deliver_far = 'The vehicle is not at the drop-off',
        deliver_moving = 'Stop the vehicle to deliver it',
        deliver_invalid = 'This vehicle is not valid for the contract',
        completed = 'Contract completed: +$%d · +%d %s · +%d XP',
        failed = 'Contract lost',
        expired = 'The contract expired',
        given_up = 'You gave up on the contract',
        name_invalid = 'That name is not valid',
        name_taken = 'That name is already taken',
        name_cooldown = 'You cannot change your name again yet',
        avatar_invalid = 'The image has to be https and from an allowed domain',
        saved = 'Changes saved',
        store_unknown = 'That item does not exist',
        store_no_stock = 'Not enough stock left',
        store_limit = 'You reached the purchase limit for this item',
        store_locked = 'You need to unlock a higher class',
        store_no_space = 'It does not fit in your inventory',
        store_bought = 'Purchase completed',
        store_pickup = 'Purchase completed: collect it at the pick-up point',
        pickup_far = 'You have to be at the pick-up point',
        no_permission = 'You do not have permission',
        invalid = 'Invalid data',
        internal = 'Something went wrong',
    },
}

function Boost.T(key, ...)
    local text = (locales[Config.Locale] or locales.es)[key] or locales.es[key] or key
    if select('#', ...) > 0 then return text:format(...) end
    return text
end

function Boost.Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function Boost.Debug(...)
    if Config.Debug then print('[jj_boosting]', ...) end
end
