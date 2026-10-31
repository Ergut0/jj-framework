Config = {}

Config.GymItem = "gym_membership" -- Item que se necesita para poder usar el gym
Config.MembershipPrice = 50       -- Precio de la membresía. Si lo cambias, cambia también el texto del menú en client/core.lua
Config.MembershipPrice = 50       -- Precio de la membresía. Si lo cambias, cambia también el texto del menú en client/core.lua

Config.RentBike = {
    vector3(-1187.15, -1575.42, 4.34),  -- GYM SUR
    vector3(-1034.12, -2735.76, 20.17), -- AEROPUERTO
    vector3(-1026.68, -2731.52, 13.76), -- AEROPUERTO
    vector3(1311.17, 2635.61, 37.73)    -- GYM NORTE
}

Config.GymMenu = {
    vector4(-1195.29, -1577.65, 4.61, 120.03), -- GYM SUR
    vector4(1316.7, 2652.57, 37.89, 173.78)   -- GYM NORTE
}

Config.Blips = {
    { title = "Gimnasio", colour = 7, id = 311, x = -1201.2257, y = -1568.8670, z = 4.6101 }, -- GYM SUR
    { title = "Gimnasio", colour = 7, id = 311, x = 1305.41,    y = 2654.5,    z = 37.9 }, -- GYM NORTE
}

Config.wantLoopRun = true -- Si quieres el loop para correr un poco mas rapido cuando llegue al 100 de stamina

Config.Stats = {
    ["stamina"] = {
        tickRemove = 1,                  -- Cantidad de puntos que se le va a quitar a la estadistica
        executeAction = function(amount) -- amount es el valor que se le va a sumar a la estadistica
            StatSetInt(GetHashKey('MP0_STAMINA'), amount, 1)
        end,
    },
    ["strength"] = {
        tickRemove = 1, -- Cantidad de puntos que se le va a quitar a la estadistica
        executeAction = function(amount)
            StatSetInt(GetHashKey('MP0_STRENGTH'), amount, 1)
        end,
    },
    ["yoga"] = {
        tickRemove = 1, -- Cantidad de puntos que se le va a quitar a la estadistica
        executeAction = function(amount)
            -- StatSetInt(GetHashKey('MP0_SHOOTING_ABILITY'), amount, 1)
        end,
    },
    ["lung"] = {
        tickRemove = 1, -- Cantidad de puntos que se le va a quitar a la estadistica
        executeAction = function(amount)
            StatSetInt(GetHashKey('MP0_LUNG_CAPACITY'), amount, 1)
        end,
    },
}

Config.Gym_Points = {
    ["brazos"] = {             -- Nombre del punto
        label = "Hacer pesas", -- Nombre que se va a mostrar en el menu
        coords = {             -- Coordenadas donde se puede hacer la accion
            vector3(-1208.89, -1559.47, 4.61),
            vector3(-1196.91, -1566.62, 4.62),
            vector3(-1198.32, -1573.69, 4.61),
            vector3(1295.35, 2650.66, 37.89),
            vector3(1295.8, 2655.81, 37.9),
        },
        experience = { -- Experiencia
            { name = "strength", how_many = 1 }
        },
        AnimationToExecute = function() -- Animacion que se va a ejecutarf
            ClearPedTasksImmediately(cache.ped)
            StartScenarioWithProp("world_human_muscle_free_weights", `prop_curl_bar_01`)
            SetTimeout(30000, function()
                ClearPedTasksImmediately(cache.ped)
                Notify("Ahora estas un poco mas fuerte, sigue asi!")
            end)
        end,
    },
    ["abdominales"] = {
        label = "Hacer abdominales",
        coords = {
            vector3(-1198.32, -1573.69, 4.61),
            vector3(-1199.96, -1563.46, 4.62),
            vector3(-1207.56, -1566.31, 4.61),
            vector3(1300.28, 2649.17, 37.89),
            vector3(1302.83, 2649.13, 37.89),
            vector3(-1079.98, -837.81, 26.83),
        },
        experience = {
            { name = "strength", how_many = 1 }
        },
        AnimationToExecute = function()
            ExecuteCommand("emote situp")
            SetTimeout(30000, function()
                ClearPedTasksImmediately(cache.ped)
                Notify("Ahora estas un poco mas fuerte, sigue asi!")
            end)
        end,
    },
    ["flexiones"] = {
        label = "Hacer flexiones",
        coords = {
            vector3(-1206.07, -1568.27, 4.61),
            vector3(-1201.68, -1570.31, 4.61),
            vector3(1303.0, 2657.23, 37.9),
            vector3(1300.0, 2657.34, 37.9),
        },
        experience = {
            { name = "strength", how_many = 1 }
        },
        AnimationToExecute = function()
            ExecuteCommand("e pushup")
            SetTimeout(30000, function()
                ClearPedTasksImmediately(cache.ped)
                Notify("Ahora estas un poco mas fuerte, sigue asi!")
            end)
        end,
    },
    ["cardio"] = {
        label = "Hacer cardio",
        coords = {
            vector3(-1195.08, -1571.17, 4.62),
            vector3(-1201.01, -1577.57, 4.61),
            vector3(1311.76, 2656.8, 37.9),
            vector3(1313.07, 2648.63, 37.89),
            vector3(-1083.20, -839.15, 26.83),
        },
        experience = {
            { name = "stamina", how_many = 1 }
        },
        AnimationToExecute = function()
            TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_JOG_STANDING", 0, true)
            SetTimeout(30000, function()
                ClearPedTasksImmediately(cache.ped)
                Notify("Ahora estas un poco mas fuerte, sigue asi!")
            end)
        end,
    },
    ["yoga"] = {
        label = "Hacer yoga",
        coords = {
            vector3(-1229.01, -1548.96, 4.57),
            vector3(-1225.32, -1547.07, 4.62),
            vector3(-1086.13, -841.77, 26.83),
            vector3(1316.21, 2642.64, 37.68)
        },
        experience = {
            { name = "yoga", how_many = 1 }
        },
        AnimationToExecute = function()
            ExecuteCommand("e yoga")
            SetTimeout(30000, function()
                ClearPedTasksImmediately(cache.ped)
                Notify("Haz ganado paz mental quizas te sirva de algo...")
            end)
        end,
    },
}
