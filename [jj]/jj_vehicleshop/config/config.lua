Config = {
    Categories = {}, -- No editar/eliminar esto.
    DriveTestTime = 1, -- Tiempo (en minutos) para la prueba de conducción del vehículo.
    VehicleTestPlates = "TEST", -- Matricula utilizada para la prueba de conducción del vehículo (máximo 8 caracteres).
    SpeedUnit = "kph", -- "mph" o "kph" (millas o kilómetros)
    UseTarget = false, -- Solo compatible con ox_target
    VipAce = "jj.vip", -- Permiso necesario para los concesionarios con isVip = true
    MaxPedDistance = 6.0, -- Distancia máxima al vendedor para abrir el concesionario
}

Config.AddonsVehicle = {
}

Config.Peds = {
    {
        npc = "a_m_y_smartcaspat_01",
        coords = vector3(-57.14, -1098.88, 25.42),
        heading = 22,
        concesionario = "normal_conce",
        isVip = false,
        restricted = false
    },
    {
        npc = "a_m_y_business_03",
        coords = vector3(2507.00, 4097.15, 37.71),   
        heading = 62.74,
        concesionario = "normal_conce2",
        isVip = false,
        restricted = false
    },
    -- {
    --     npc = "a_m_y_smartcaspat_01",
    --     coords = vector3(-27.61, -1102.96, 25.48),
    --     heading = 74.40,
    --     concesionario = "vip_conce",
    --     isVip = true, 
    --     restricted = {"vip"}
    -- },
    {
        npc = "s_f_y_cop_01",
        coords = vector3(445.64, -979.58, 24.68),
        heading = 269.25,
        concesionario = "police_conce",
        isVip = false,
        restricted = {"police", "sheriff"}
    },
    -- Descomenta también sheriff_conce en Config.Dealerships para usarlo
    -- {
    --     npc = "s_f_y_sheriff_01",
    --     coords = vector3(1039.23, 2742.75, 37.72),
    --     heading = 278.01,
    --     concesionario = "sheriff_conce",
    --     isVip = false,
    --     restricted = {"police", "sheriff"}
    -- },
    {
        npc = "s_m_m_paramedic_01",
        coords = vector3(1130.81, -1593.79, 33.70),
        heading = 321.92,
        concesionario = "ambulance_conce",
        isVip = false,
        restricted = {"ambulance"}
    },
    {
        npc = "a_m_y_surfer_01",
        coords = vector3(-812.99, -1407.42, 4.00), -- -812.99, -1407.42, 5.00, 341.63
        heading = 341.63,
        concesionario = "conce_barcos",
        isVip = false,
        restricted = false
    },
    {
        npc = "s_m_m_pilot_01",
        coords = vector3(-1089.39, -2860.32, 12.95), 
        heading = 160.69,
        concesionario = "conce_avion",
        isVip = false,
        restricted = false
    },
}

Config.Dealerships = {
    ['normal_conce'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"deluxe", "vip", "drift", "compactos", "coupe", "vans", "bicicletas", "motos", "muscle", "todoterrenos", "sedan", "deportivos", "suv", "clasicos", "superdeportivos"} , -- Categorías que el concesionario puede vender.
        test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = -998.28, y = -3339.33, z = 13.94, h = 59.47}, -- Donde aparece el vehículo de prueba.
        preview_vehicle_coords = {x = -1389.67, y = -473.56, z = 78.2, h = 166.64}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -1387.92, y = -479.34, z = 78.30, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x = -16.51, y = -1103.37, z = 26.68, h = 162.53}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo. -1389.67, -479.34, 78.30
        blip = {
            label = "Concesionario PDM",
            icon = 227, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = -46.62, y = -1094.36, z = 27.3}
        }
    },

    ['normal_conce2'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"deluxe", "vip", "drift", "compactos", "coupe", "vans", "bicicletas", "motos", "muscle", "todoterrenos", "sedan", "deportivos", "suv", "clasicos", "superdeportivos"} , -- Categorías que el concesionario puede vender.
        test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = 1707.98, y = 3252.56, z = 41.03, h = 104.20}, -- Donde aparece el vehículo de prueba.
        preview_vehicle_coords = {x = -1389.67, y = -473.56, z = 78.2, h = 166.64}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -1387.92, y = -479.34, z = 78.30, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos 
        purchased_vehicle_spawn = {x = 2487.46, y=4118.38, z=38.07, h=237.27}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.     
        blip = {  
            label = "Concesionario Norte",
            icon = 227, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x =  2507.00, y=4097.15, z=38.71} 
            }
    },

    ['vip_conce'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"vip", "deluxe"}, -- Categorías que el concesionario puede vender.
        test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = -998.28, y = -3339.33, z = 13.94, h = 59.47}, -- Donde aparece el vehículo de prueba.
        preview_vehicle_coords = {x = -1389.67, y = -473.56, z = 78.2, h = 166.64}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -1387.92, y = -479.34, z = 78.30, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x = -33.82, y = -1080.45, z = 27.04, h = 68.2}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.
        blip = {
            label = "Concesionario PDM",
            icon = 227, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = -46.62, y = -1094.36, z = 27.3}
        }
    },


    ['police_conce'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        company_card = true, -- Permite pagar con la tarjeta de empresa de jj_paymethods, que no cobra nada. Sin este campo, no se ofrece
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"SAPD"}, -- Categorías que el concesionario puede vender.
        test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = -998.28, y = -3339.33, z = 13.94, h = 59.47}, -- Donde aparece el vehículo de prueba.
        preview_vehicle_coords = {x = -1389.67, y = -473.56, z = 78.2, h = 166.64}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -1387.92, y = -479.34, z = 78.30, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x = 441.82, y = -985.02, z = 25.68, h = 272.67}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo. 441.82, -985.02, 25.68, 272.67
        blip = { 
            label = "Concesionario PDM",
            icon = 0, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = -46.62, y = -1094.36, z = 27.3}
        }
    },

    -- ['sheriff_conce'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
    --     money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
    --     categories = {"SAPD"}, -- Categorías que el concesionario puede vender.
    --     test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
    --     test_coords = {x = 1054.15, y = 2743.02, z = 39.52, h = 265.99}, -- Donde aparece el vehículo de prueba. 
    --     preview_vehicle_coords = {x = 1054.15, y = 2743.02, z = 39.52, h = 265.99}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección) 
    --     preview_vehicle_camera = {x = 1053.50, y = 2734.66, z = 39.78, rotation = 120, fov = 60.0}, -- Coordenadas de la cámara, rotación y campo de visión
    --     buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
    --     purchased_vehicle_spawn = {x = 1054.15, y = 2743.02, z = 39.52, h = 265.99}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.
    --     blip = {
    --         label = "Concesionario PDM",
    --         icon = 0, -- https://docs.fivem.net/docs/game-references/blips/#blips
    --         color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
    --         scale = 0.7,
    --         coords = {x = 1054.15, y = 2743.02, z = 39.52}
    --     }
    -- },

    ['ambulance_conce'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"EMS"}, -- Categorías que el concesionario puede vender.
        test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = 1201.14, y = -1496.81, z = 34.69, h = 191.48}, -- Donde aparece el vehículo de prueba. 
        preview_vehicle_coords = {x = -1389.67, y = -473.56, z = 78.2, h = 166.64}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -1387.92, y = -479.34, z = 78.30, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x = 1132.52, y = -1588.23, z = 34.74, h = 248.05}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.
        blip = {
            label = "Concesionario PDM",
            icon = 0, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 5, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = 1054.15, y = 2743.02, z = 39.52}
        }
    },

    ['conce_barcos'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        garage = "garagebarcooo", -- Garaje de jj_garages donde queda el vehículo. Sin este campo, el garaje por defecto
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"barcos"} , -- Categorías que el concesionario puede vender.
        test_vehicles = false, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x = -737.28, y = -1369.48, z = 0, h = 139.85}, -- Donde aparece el vehículo de prueba.
        preview_vehicle_coords = {x = -737.28, y = -1369.48, z = 0, h = 139.85}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -731.56, y = -1381.16, z = 2.07, rotation = 18.96, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x = -826.19, y = -1419.12, z =  2.23, h = 110.14}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo. -- -826.19, -1419.12, 2.23, 110.14
        blip = {
            label = "Concesionario Barcos",
            icon = 427, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 3, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = -812.96, y = -1407.88, z = 0} -- -812.96, -1407.88, 5.00, 346.69
        }
    },
    ['conce_avion'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
        garage = "garajeaereopuerto", -- Garaje de jj_garages donde queda el vehículo. Sin este campo, el garaje por defecto
        money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
        categories = {"helicopteros"} , -- Categorías que el concesionario puede vender.
        test_vehicles = false, -- False si no quieres que los jugadores puedan probar los vehículos
        test_coords = {x =  -1094.18, y = -2894.18, z =  13.95, h = 148.43}, -- Donde aparece el vehículo de prueba. -1094.18, -2894.18, 13.95, 148.43
        preview_vehicle_coords = {x = -966.36, y = -3026.29, z = 13.95, h = 46.59}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
        preview_vehicle_camera = {x = -965.57, y = -3046.30, z = 16.48, rotation = 50, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
        buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
        purchased_vehicle_spawn = {x =  -1094.18, y = -2894.18, z =  13.95, h = 148.43}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.
        blip = {
            label = "Concesionario Pegassus",
            icon = 90, -- https://docs.fivem.net/docs/game-references/blips/#blips
            color = 3, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
            scale = 0.7,
            coords = {x = -1089.39, y = -2860.32, z = 13.95}
        }
    },
 --  ['conce_avionsandy'] = { -- índice clave del concesionario, debe ser único para cada concesionario.
 --      money_sign = "$", -- Para mostrar el precio del vehículo: $, €, £, ¥, etc... o dejarlo vacío ""
 --      categories = {"helicopteros"} , -- Categorías que el concesionario puede vender.
 --      test_vehicles = true, -- False si no quieres que los jugadores puedan probar los vehículos
 --      test_coords = {x = -926.16, y = -3185.62, z = 13.95, h = 61.74}, -- Donde aparece el vehículo de prueba.
 --      preview_vehicle_coords = {x = -966.36, y = -3026.29, z = 13.95, h = 46.59}, -- Coordenadas de aparición para la vista previa del vehículo (x, y, z, dirección)
 --      preview_vehicle_camera = {x = -965.57, y = -3046.30, z = 16.48, rotation = 50, fov = 58.0}, -- Coordenadas de la cámara, rotación y campo de visión
 --      buy_vehicle = true, -- Habilitar/Deshabilitar la opción de compra de vehículos
 --      purchased_vehicle_spawn = {x = 1700.83, y = 3249.77, z = 40.97, h = 104.97}, -- Donde aparecerá el vehículo/jugador después de comprar un vehículo.
 --      blip = {
 --          label = "Concesionario AeroLinea",
 --          icon = 90, -- https://docs.fivem.net/docs/game-references/blips/#blips
 --          color = 3, -- https://docs.fivem.net/docs/game-references/blips/#blip-colors
 --          scale = 0.7,
 --          coords = {x = -941.36, y = -2955.96, z = 0} 
 --      }
 --  },
}
