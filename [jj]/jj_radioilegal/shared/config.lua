Config = {}

-- Tecla para abrir el panel. Cada jugador puede cambiarla en los ajustes de FiveM
Config.OpenKey = 'F6'

-- Objeto de ox_inventory necesario para conectarse
Config.RadioItem = 'radio'

-- Frecuencias de cada banda
Config.Frequencies = 10

-- Canal de pma-voice = BaseChannel + id de la banda * ChannelsPerGang + frecuencia.
-- ChannelsPerGang tiene que ser mayor que Frequencies para que dos bandas no compartan canal
Config.BaseChannel = 10000
Config.ChannelsPerGang = 100

-- Metros máximos para actuar sobre otro jugador y para encontrar un vehículo
Config.ActionDistance = 3.0
Config.VehicleDistance = 6.0

-- Quien no fue esposado desde este panel solo se libera con este objeto: la banda no suelta gratis a un detenido
Config.UncuffItem = 'llave_negra'

-- Cada cuánto se comprueba que quien está en la radio sigue en la banda y conserva el objeto (ms)
Config.CheckInterval = 5000

-- Bolsa que se pone en la cabeza
Config.HeadbagModel = 'prop_money_bag_01'
