Config = {}
Config.AutoRespawn = false          -- true == stores cars in garage on restart | false == doesnt modify car states
Config.VisuallyDamageCars = true   -- true == damage car on spawn | false == no damage on spawn
Config.SharedGarages = false       -- true == take any car from any garage | false == only take car from garage stored in
Config.ClassSystem = false         -- true == restrict vehicles by class | false == any vehicle class in any garage
Config.Warp = true                 -- true == warp player into vehicle | false == vehicle spawns without warping
Config.DebugTarget = false
Config.DepotPrice = 500            -- precio del depósito cuando el vehículo no tiene uno propio
Config.PayWith = { 'cash', 'bank' } -- cuentas con las que se paga el depósito, en orden
Config.MaxGarageDistance = 25.0    -- distancia máxima al garaje que acepta el servidor
-- https://docs.fivem.net/natives/?_0x29439776AAA00A62
Config.VehicleClass = {
    all = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 },
    car = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 18, 22 },
    air = { 15, 16 },
    sea = { 14 },
    rig = { 10, 11, 17, 19, 20 }
}

Config.Garages = {
    garagecentral = {
        label = 'Garaje Publico',
        takeVehicle = vector3(215.67, -791.04, 30.83),
        spawnPoint = {
            vector4(228.82, -800.43, 30.58, 155.68),
            vector4(233.44, -788.55, 30.61, 159.44)
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecarreras = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1305.68, 6594.16, 10.37),
        spawnPoint = {
            vector4(1305.68, 6594.16, 10.37, 175.85)
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagerockford = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1050.74, -251.05, 37.73),
        spawnPoint = {
            vector4(-1050.74, -251.05, 37.73, 212.82)
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecrews = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-2275.01, 298.98, 156.52),
        spawnPoint = {
            vector4(-2275.01, 298.98, 156.52, 114.13),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageautoexotic = {
        label = 'Garaje Publico',
        takeVehicle = vector3(541.92, -140.08, 58.99),
        spawnPoint = {
            vector4(541.92, -140.08, 58.97, 88.61),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageuwucafe = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-588.36, -1121.05, 22.18),
        spawnPoint = {
            vector4(-588.36, -1121.05, 22.18, 356.24),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garajerex = {
        label = 'Garaje Publico',
        takeVehicle = vector3(2555.62, 2614.72, 37.96),
        spawnPoint = {
            vector4(2555.62, 2614.72, 37.96, 98.87),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagepier = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1574.68, -1008.59, 13.02),
        spawnPoint = {
            vector4(-1574.27, -1008.27, 13.02, 137.29),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegreatocean = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-3042.95, 603.57, 7.42),
        spawnPoint = {
            vector4(-3042.95, 603.57, 7.42, 188.94),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagepacific = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-3000.63, 94.42, 11.61),
        spawnPoint = {
            vector4(-3000.63, 94.42, 11.61, 139.21),
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagetequilala = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-611.08, 338.34, 85.12),
        spawnPoint = {
            vector4(-610.67, 338.30, 85.12, 265.47),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagehayes = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1393.05, -456.95, 34.48),
        spawnPoint = {
            vector4(-1393.05, -456.95, 34.48, 106.49),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecasino = {
        label = 'Garaje Publico',
        takeVehicle = vector3(890.53, -31.77, 78.76),
        spawnPoint = {
            vector4(890.87, -31.85, 78.76, 328.63),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagemirror = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1040.81, -776.59, 58.02),
        spawnPoint = {
            vector4(1041.08, -776.57, 58.02, 2.66),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageapartamentoplaya = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-695.56, -1112.63, 14.53),
        spawnPoint = {
            vector4(-695.59, -1112.70, 14.53, 303.13),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagevinewood = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-529.64, 46.95, 52.58),
        spawnPoint = {
            vector4(-529.64, 46.95, 52.58, 358.45),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagemotelruta = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1118.42, 2665.23, 38.02),
        spawnPoint = {
            vector4(1119.21, 2665.18, 38.02, 267.86),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegrappeseed = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1707.04, 4803.50, 41.79),
        spawnPoint = {
            vector4(1707.11, 4803.60, 41.79, 93.54),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagepaleto = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-194.02, 6221.20, 31.49),
        spawnPoint = {
            vector4(-194.02, 6221.18, 31.49, 186.38),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagesandy = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1885.94, 3710.84, 32.94),
        spawnPoint = {
            vector4(1885.93, 3710.83, 32.94, 215.85),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagevanilla = {
        label = 'Garaje Publico',
        takeVehicle = vector3(148.60, -1307.34, 29.20),
        spawnPoint = {
            vector4(148.60, -1307.34, 29.20, 89.00),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageobservarotio = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-409.59, 1218.21, 325.64),
        spawnPoint = {
            vector4(-409.59, 1218.21, 325.64, 166.31),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagepuerto = {
        label = 'Garaje Publico',
        takeVehicle = vector3(135.16, -3200.67, 5.86),
        spawnPoint = {
            vector4(135.07, -3200.70, 5.86, 267.25),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagevespuccicanal = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1151.79, -749.41, 19.26),
        spawnPoint = {
            vector4(-1151.76, -749.37, 19.26, 215.33),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagepillbox = {
        label = 'Garaje Publico',
        takeVehicle = vector3(280.82, -603.38, 43.10),
        spawnPoint = {
            vector4(281.77, -603.99, 43.10, 28.43),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageyellowjack = {
        label = 'Garaje Publico',
        takeVehicle = vector3(2007.27, 3072.18, 47.06),
        spawnPoint = {
            vector4(2007.27, 3072.18, 47.06, 117.55),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegrevestreet = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-55.7580, -1838.3363, 26.560),
        spawnPoint = {
            vector4(-55.7580, -1838.3363, 26.5608, 318.5810),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegymplaya = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1195.6458, -1488.4552, 4.3799),
        spawnPoint = {
            vector4(-1195.6458, -1488.4552, 4.3799, 218.2139),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagelittleseoul = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-695.6176, -982.0172, 20.3901),
        spawnPoint = {
            vector4(-695.6176, -982.0172, 20.3901, 0.4308),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagebarmotero = {
        label = 'Garaje Publico',
        takeVehicle = vector3(292.6378, 2964.6609, 42.9522),
        spawnPoint = {
            vector4(292.6378, 2964.6609, 42.9522, 87.6679),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegalaxy = {
        label = 'Garaje Publico',
        takeVehicle = vector3(367.85, 290.18, 103.37),
        spawnPoint = {
            vector4(367.85, 290.18, 103.37, 345.66),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagegolf = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1395.70, 51.67, 53.49),
        spawnPoint = {
            vector4(-1395.70, 51.67, 53.49, 189.18),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageburrito = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1384.00, -2060.79, 52.00),
        spawnPoint = {
            vector4(1384.00, -2060.79, 52.00, 106.84),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageanfiteatro = {
        label = 'Garaje Publico',
        takeVehicle = vector3(626.93, 624.01, 128.91),
        spawnPoint = {
            vector4(626.93, 624.01, 128.91, 340.19),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecochesaeropuerto = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-690.00, -1409.20, 5.00),
        spawnPoint = {
            vector4(-681.55, -1407.78, 5.00, 86.79),
            vector4(-681.25, -1403.83, 5.00, 86.79),
            vector4(-681.31, -1399.78, 5.00, 85.86),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagekebab = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1259.39, -1238.33, 5.43),
        spawnPoint = {
            vector4(-1259.39, -1238.33, 5.43, 17.14),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagerexdiner = {
        label = 'Garaje Publico',
        takeVehicle = vector3(2572.12, 2715.89, 42.41),
        spawnPoint = {
            vector4(2572.12, 2715.89, 42.41, 38.02),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageconcesionario = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-53.3, -1116.11, 26.44),
        spawnPoint = {
            vector4(-53.3, -1116.11, 26.44, 356.91),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garageairlanda = {
        label = 'Garaje Publico',
        takeVehicle = vector3(1767.98, 3307.37, 40.56),
        spawnPoint = {
            vector4(1767.98, 3307.37, 40.56, 235.91),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagebolera = {
        label = 'Garaje Publico',
        takeVehicle = vector3(810.02, -722.23, 28.67),
        spawnPoint = {
            vector4(805.06, -727.48, 27.63, 136.99),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garajerivera = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1317.95, -1153.12, 4.60),
        spawnPoint = {
            vector4(-1317.95, -1153.12, 4.60, 89.04),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagehospi = {
        label = 'Garaje Hospi',
        takeVehicle = vector3(1116.80, -1506.11, 34.69),
        spawnPoint = {
            vector4(1116.80, -1506.11, 34.69, 267.49),
        },
        showBlip = false,
        blipName = 'Garaje Hospi',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecomi = {
        label = 'Garaje Comisaria',
        takeVehicle = vector3(444.45, -1028.78, 28.69),
        spawnPoint = {
            vector4(438.80, -1026.78, 28.78, 4.73),
            vector4(442.44, -1026.37, 28.72, 9.08),
            vector4(446.06, -1025.88, 28.65, 0.15),
            vector4(449.98, -1025.50, 28.57, 5.22),
            vector4(453.43, -1025.17, 28.51, 5.16),
            vector4(457.31, -1024.83, 28.43, 5.30),
        },
        showBlip = false,
        blipName = 'Garaje Comisaria',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagecompraventa = {
        label = 'Garaje Compraventa',
        takeVehicle = vector3(1210.20, 2718.66, 38.01),
        spawnPoint = {
            vector4(1210.20, 2718.66, 38.01, 254.66),
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagemafia = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-1467.36, -24.25, 54.64),
        spawnPoint = {
            vector4(-1467.36, -24.25, 54.64, 220.35),
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagemafia2 = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-149.42, -595.90, 32.42),
        spawnPoint = {
            vector4(-155.39, -593.60, 32.42, 247.28),
            vector4(-143.04, -598.62, 32.42, 248.42),
            vector4(-143.97, -602.44, 32.42, 66.80),
            vector4(-156.46, -597.81, 32.42, 69.18),
        },
        showBlip = false,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    -- garagemafia2 = {
    --     label = 'Garaje Publico',
    --     takeVehicle = vector3(-332.35, -1284.18, 31.31),
    --     spawnPoint = {
    --         vector4(-332.35, -1284.18, 31.31, 86.36),
    --     },
    --     showBlip = false,
    --     blipName = 'Garaje Publico',
    --     blipNumber = 357,
    --     blipColor = 0,
    --     type = 'public',
    --     category = Config.VehicleClass['car']
    -- },
    garagecomisariapaleto = {
        label = 'Garaje Comisaria Paleto',
        takeVehicle = vector3(-469.23, 6022.52, 31.34),
        spawnPoint = {
            vector4(-469.23, 6022.52, 31.34, 49.78),
        },
        showBlip = false,
        blipName = 'Garaje Comisaria',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagelscustom = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-356.64, -90.79, 45.66),
        spawnPoint = {
            vector4(-356.13, -88.62, 45.02, 346.38),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garagebennys = {
        label = 'Garaje Publico',
        takeVehicle = vector3(-316.0, -1326.7, 31.36),
        spawnPoint = {
            vector4(-315.98, -1326.42, 30.74, 270.18),
        },
        showBlip = true,
        blipName = 'Garaje Publico',
        blipNumber = 357,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['car']
    },
    garajeaereosandy = {
        label = 'Garaje aereo',
        takeVehicle = vector3(1748.88, 3265.25, 41.27),
        spawnPoint = {
            vector4(1748.88, 3265.25, 41.27, 104.37),
        },
        showBlip = true,
        blipName = 'Garaje Público',
        blipNumber = 359,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['air']
    },
    garajeaereo = {
        label = 'Garaje Aeropuerto',
        takeVehicle = vector3(-1112.53, -2884.13, 13.95),
        spawnPoint = {
            vector4(-1112.53, -2884.13, 13.95, 329.11),
            vector4(-1146.36, -2864.64, 13.95, 329.61),
            vector4(-1178.50, -2845.79, 13.95, 329.61),
        },
        showBlip = true,
        blipName = 'Garaje Aeropuerto',
        blipNumber = 359,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['air']
    },
    garajeaereopuerto = {
        label = 'Garaje Aeropuerto',
        takeVehicle = vector3(-735.32, -1456.51, 5.00),
        spawnPoint = {
            vector4(-724.84, -1444.52, 5.00, 319.20),
            vector4(-745.63, -1468.80, 5.00, 319.68),
        },
        showBlip = true,
        blipName = 'Garaje Helipuerto',
        blipNumber = 359,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['air']
    },
    garajeaereoasdypuerto = {
        label = 'Garaje aereo',
        takeVehicle = vector3(1427.15, 3730.16, 32.99),
        spawnPoint = {
            vector4(1427.15, 3730.16, 32.99, 286.24),
        },
        showBlip = true,
        blipName = 'Garaje Público',
        blipNumber = 359,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['air']
    },
    garagebarcooo = {
        label = 'Garaje Barco',
        takeVehicle = vector3(-826.97, -1410.29, 1.02),
        spawnPoint = {
            vector4(-830.81, -1405.83, 0.90, 110.03),
            vector4(-824.49, -1416.83, 1.02, 110.82),
        }, 
        showBlip = true,
        blipName = 'Garaje Barco',
        blipNumber = 356,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['sea']
    },
    garagebarcooo2 = {
        label = 'Garaje Barco',
        takeVehicle = vector3(-1605.95, 5258.76, 2.09),
        spawnPoint = {
            vector4(-1597.76, 5261.87, 0.13, 18.16),
        }, 
        showBlip = true,
        blipName = 'Garaje Barco',
        blipNumber = 356,
        blipColor = 0,
        type = 'public',
        category = Config.VehicleClass['sea']
    },
    depotaereo = {
        label = 'Depósito',
        takeVehicle = vector3(-1178.36, -2845.94, 13.95),
        spawnPoint = {
            vector4(-1178.36, -2845.94, 13.95, 328.71),
        },
        showBlip = true,
        blipName = 'Depósito Aereopuerto',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['air']
    },
    depotLot = {
        label = 'Depósito',
        takeVehicle = vector3(396.06, -1614.23, 29.29),
        spawnPoint = {
            vector4(390.47, -1610.16, 29.29, 228.93),
            vector4(388.59, -1612.62, 29.29, 224.71),
            vector4(392.8, -1607.72, 29.29, 226.27)
        },
        showBlip = true,
        blipName = 'Depósito Coches',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['car']
    },
    depotComisaria = {
        label = 'Depósito',
        takeVehicle = vector3(460.74, -986.39, 21.68),
        spawnPoint = {
            vector4(457.86, -987.98, 25.68, 89.87),
            vector4(457.88, -990.95, 25.68, 88.46),
            vector4(457.97, -984.80, 25.68, 87.42),
            vector4(457.55, -982.03, 25.68, 90.42),
        },
        showBlip = false,
        blipName = 'Depósito',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['car']
    },
    depotSandy = {
        label = 'Depósito',
        takeVehicle = vector3(1825.94, 3657.83, 34.06),
        spawnPoint = {
            vector4(1825.94, 3657.83, 34.06, 209.63),
        },
        showBlip = true,
        blipName = 'Depósito',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['car']
    },
    depotPaleto = {
        label = 'Depósito',
        takeVehicle = vector3(-133.71, 6277.44, 31.37),
        spawnPoint = {
            vector4(-131.63, 6283.65, 31.35, 223.22),
            vector4(-138.98, 6276.80, 31.34, 225.55),
        },
        showBlip = true,
        blipName = 'Depósito',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['car']
    },
    depotBarcos = {
        label = 'Depósito',
        takeVehicle = vector3(-846.57, -1367.86, 1.61),
        spawnPoint = {
            vector4(-854.70, -1372.97, 1.29, 192.79),
        },
        showBlip = true,
        blipName = 'Depósito Barco',
        blipNumber = 68,
        blipColor = 0,
        type = 'depot',
        category = Config.VehicleClass['sea']
    },
}

