return {
    defaultOpenCharSlot = 1,
    creationSpawn = vector4(-67.02, -832.17, 222.00, 67.59), -- Donde aparece un personaje nuevo si useZoneSelectorOnCreate es false
    useZoneSelectorOnCreate = true, -- Un personaje nuevo elige dónde aparecer con el selector de zonas

    starterItems = {
        { name = "phone",           amount = 1, metadata = {} },
        {
            name = "id_card",
            amount = 1,
            metadata = function(player)
                local charinfo = player.getCharInfo()
                return {
                    id = player.identifier,
                    fullname = charinfo.firstname .. " " .. charinfo.lastname,
                    birthdate = charinfo.birthdate,
                }
            end,
        },
        { name = "croissant_mixto",        amount = 10, metadata = {} },
        { name = "refresco",               amount = 10, metadata = {} },
    },

    randomPeds = {
        ["male"] = {
            model = `mp_m_freemode_01`,
            headOverlays = {
                beard = { color = 0, style = 0, secondColor = 0, opacity = 1 },
                complexion = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                bodyBlemishes = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                blush = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                lipstick = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                blemishes = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                eyebrows = { color = 0, style = 0, secondColor = 0, opacity = 1 },
                makeUp = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                sunDamage = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                moleAndFreckles = { color = 0, style = 0, secondColor = 0, opacity = 0 },
                chestHair = { color = 0, style = 0, secondColor = 0, opacity = 1 },
                ageing = { color = 0, style = 0, secondColor = 0, opacity = 1 },
            },
            components = {
                { texture = 0, drawable = 0,  component_id = 0 },
                { texture = 0, drawable = 0,  component_id = 1 },
                { texture = 0, drawable = 0,  component_id = 2 },
                { texture = 0, drawable = 0,  component_id = 5 },
                { texture = 0, drawable = 0,  component_id = 7 },
                { texture = 0, drawable = 0,  component_id = 9 },
                { texture = 0, drawable = 0,  component_id = 10 },
                { texture = 0, drawable = 15, component_id = 11 },
                { texture = 0, drawable = 15, component_id = 8 },
                { texture = 0, drawable = 15, component_id = 3 },
                { texture = 0, drawable = 34, component_id = 6 },
                { texture = 0, drawable = 61, component_id = 4 },
            },
            props = {
                { prop_id = 0, drawable = -1, texture = -1 },
                { prop_id = 1, drawable = -1, texture = -1 },
                { prop_id = 2, drawable = -1, texture = -1 },
                { prop_id = 6, drawable = -1, texture = -1 },
                { prop_id = 7, drawable = -1, texture = -1 },
            }
        },
        ["female"] = {
            model = `mp_f_freemode_01`,
            headBlend = {
                shapeMix = 0.3,
                skinFirst = 0,
                shapeFirst = 31,
                skinSecond = 0,
                shapeSecond = 0,
                skinMix = 0,
                thirdMix = 0,
                shapeThird = 0,
                skinThird = 0,
            },
            hair = {
                color = 0,
                style = 15,
                texture = 0,
                highlight = 0
            },
            headOverlays = {
                chestHair = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                bodyBlemishes = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                beard = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                lipstick = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                complexion = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                blemishes = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                moleAndFreckles = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                makeUp = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                ageing = { secondColor = 0, opacity = 1, color = 0, style = 0 },
                eyebrows = { secondColor = 0, opacity = 1, color = 0, style = 0 },
                blush = { secondColor = 0, opacity = 0, color = 0, style = 0 },
                sunDamage = { secondColor = 0, opacity = 0, color = 0, style = 0 },
            },
            components = {
                { drawable = 0,  component_id = 0,  texture = 0 },
                { drawable = 0,  component_id = 1,  texture = 0 },
                { drawable = 0,  component_id = 2,  texture = 0 },
                { drawable = 0,  component_id = 5,  texture = 0 },
                { drawable = 0,  component_id = 7,  texture = 0 },
                { drawable = 0,  component_id = 9,  texture = 0 },
                { drawable = 0,  component_id = 10, texture = 0 },
                { drawable = 15, component_id = 3,  texture = 0 },
                { drawable = 15, component_id = 11, texture = 3 },
                { drawable = 14, component_id = 8,  texture = 0 },
                { drawable = 15, component_id = 4,  texture = 3 },
                { drawable = 35, component_id = 6,  texture = 0 },
            },
            props = {
                { prop_id = 0, drawable = -1, texture = -1 },
                { prop_id = 1, drawable = -1, texture = -1 },
                { prop_id = 2, drawable = -1, texture = -1 },
                { prop_id = 6, drawable = -1, texture = -1 },
                { prop_id = 7, drawable = -1, texture = -1 },
            }
        }
    },

    zonesSpawn = {
        {
            id = 1,
            name = "Paleto",
            garage = "paleto",
            coords = vector4(-442.13, 6038.07, 31.34, 303.85),
            image = "https://r2.fivemanage.com/apagUNR5M4izDc7a4pToR/PALETO.png",
            description = "Ideal si quieres vivir en el norte de San Andreas."
        },
        {
            id = 2,
            name = "Sandy",
            garage = "sandy",
            coords = vector4(1934.66, 3719.12, 32.56, 174.40),
            image = "https://r2.fivemanage.com/apagUNR5M4izDc7a4pToR/SANDY.png",
            description = "Ideal para los amantes del desierto."
        },
        {
            id = 3,
            name = "Aeropuerto",
            garage = "aeropuerto",
            coords = vector4(-1035.37, -2730.90, 13.76, 325.66),
            image = "https://r2.fivemanage.com/apagUNR5M4izDc7a4pToR/AEROPUERTO.png",
            description = "Ideal para los que llegan a Los Santos."
        },
        {
            id = 4,
            name = "Barrios Bajos",
            garage = "ltd_grove",
            coords = vector4(58.03, -1566.93, 29.46, 37.94),
            image = "https://r2.fivemanage.com/apagUNR5M4izDc7a4pToR/BARRIOS.png",
            description = "Ideal para los que buscan la vida urbana."
        },
        {
            id = 5,
            name = "Plaza de Cubos",
            garage = "centralgarage",
            coords = vector4(226.24, -880.97, 30.49, 334.25),
            image = "https://r2.fivemanage.com/apagUNR5M4izDc7a4pToR/CUBOS.png",
            description = "Ideal para los que buscan un ambiente más relajado."
        },
    },

    scenes = {
        -- {
        --     camCoords = vector4(62.55, -1047.99, 77.62, 320.20),
        --     effectCam = "DRUNK_SHAKE",
        --     npcModel = `s_m_y_fireman_01`,
        --     ["npc"] = {
        --         coords = vector4(70.46, -1038.38, 74.18, 246.58),
        --         animDict = 'missfinale_b_ig_5',
        --         animName = 'hold_michael_loop_fra'
        --     },
        --     ["player"] = {
        --         coords = vector4(70.46, -1038.38, 74.18, 246.58),
        --         animDict = 'missfinale_b_ig_5',
        --         animName = 'hold_michael_loop_mic'
        --     }
        -- },
        {
            camCoords = vector4(-1373.62, -475.24, 73.89, 261.88),
            effectCam = false,
            npcModel = false,
            ["player"] = {
                coords = vector4(-1369.00, -475.90, 71.05, 93.31),
                animDict = 'mini@strip_club@wade@',
                animName = 'leadin_loop_idle_a_wade'
            }
        },
    },


    startingVehicles = {

        ["car"] = {
            "asea",
            "peyote3",
            "speedo",
            "journey",
            "dilettante",
            "kalahari",
            "rancherxl",
            "hustler",
            "manana",
            "peyote",
            "surfer",
            "tornado",
            "pigalle",
            "sandking",
            "bodhi2",
            "hermes",
            "emperor",
            "moonbeam",
            "ratloader",
            "fagaloa",
            "glendale",
            "rebel",
        },

        ["motorcycle"] = {
            "bagger",
            "bati",
            "defiler",
            "sanchez",
            "esskey",
            "faggio",
            "fcr",
            "faggio2",
            "nemesis",
            "pcj",
            "ruffian",
        },

        ["custom_motorcycle"] = {
            "ratbike",
            "daemon2",
            "gargoyle",
            "hexer",
            "innovation",
            "wolfsbane",
            "zombiea",
            "zombieb",
        },
    },

    cinematicPoints = {
        -- {
        --     camCoords = vector3(-1110.09, -836.10, 21.27),
        --     camRotation = vector3(-15.0, 0.0, 210.0),
        --     camRotationEnd = vector3(-15.0, 0.0, 290.0),
        --     fov = 50.0,
        --     fovEnd = 55.0,
        --     duration = 15000,
        -- },
        {
            camCoords = vector3(-339.80, -1456.60, 39.03),
            camRotation = vector3(-10.0, 0.0, 200.0),
            camRotationEnd = vector3(-10.0, 0.0, 280.0),
            fov = 70.0,
            fovEnd = 60.0,
            duration = 15000,
        },
        {
            camCoords = vector3(2014.04, 3079.32, 55.63),
            camRotation = vector3(-12.0, 0.0, 190.0),
            camRotationEnd = vector3(-12.0, 0.0, 120.0),
            fov = 55.0,
            fovEnd = 60.0,
            duration = 15000,
        },
        {
            camCoords = vector3(841.87, 47.27, 104.18),
            camRotation = vector3(-8.0, 0.0, 220.0),
            camRotationEnd = vector3(-8.0, 0.0, 300.0),
            fov = 65.0,
            fovEnd = 55.0,
            duration = 14000,
        },
    }

}
