Config = {}

Config.Debug = false

-- Trabajos que pueden usar las armerías, los vehículos de servicio y la gestión de la comisaría
Config.PoliceJobs = { police = true, sheriff = true }
-- Además de la policía, pueden esposar, escoltar y meter en vehículos
Config.AssistJobs = { ambulance = true }

Config.MaxJailMinutes = 60

-- Estado de jj_vehicles para un vehículo confiscado: no sale del depósito público, solo del policial
Config.ConfiscatedState = 3

Config.NPCCoords = {
    ["Sur"] = {
        coords = vector4(441.31, -981.97, 29.69, 116.19),
        model = "s_f_y_cop_01",
        scenario = "WORLD_HUMAN_STAND_IMPATIENT_FACILITY",
        targetLabel = "Hablar con la Oficial Anacleta",
        pedComponents = {
            {
                componentId = 2,
                drawableId = 1,
                textureId = 1
            },
            {
                componentId = 9,
                drawableId = 1,
                textureId = 0
            },
        },
        npcType = "npcPolice",
        npcLocation = "Sur",
    },

    ["Sur2"] = {
        coords = vector4(-1112.20, -824.59, 18.32, 37.77),
        model = "s_f_y_cop_01",
        scenario = "WORLD_HUMAN_STAND_IMPATIENT_FACILITY",
        targetLabel = "Hablar con la Oficial Rosaura",
        pedComponents = {
            {
                componentId = 0,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 2,
                drawableId = 2,
                textureId = 0
            },
            {
                componentId = 3,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 5,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 8,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 9,
                drawableId = 1,
                textureId = 0
            },
        },
        npcType = "npcPolice",
        npcLocation = "Sur",
    },

    -- ["Norte1"] = {
    --     coords = vector4(1061.55, 2723.38, 37.66, 180.75),
    --     model = "s_m_y_cop_01",
    --     scenario = "WORLD_HUMAN_STAND_IMPATIENT_FACILITY",
    --     targetLabel = "Hablar con el oficial Alfredo",
    --     pedComponents = {
    --         {
    --             componentId = 0,
    --             drawableId = 1,
    --             textureId = 0
    --         },
    --         {
    --             componentId = 2,
    --             drawableId = 2,
    --             textureId = 0
    --         },
    --         {
    --             componentId = 3,
    --             drawableId = 1,
    --             textureId = 0
    --         },
    --         {
    --             componentId = 5,
    --             drawableId = 1,
    --             textureId = 0
    --         },
    --         {
    --             componentId = 8,
    --             drawableId = 1,
    --             textureId = 0
    --         },
    --         {
    --             componentId = 9,
    --             drawableId = 1,
    --             textureId = 0
    --         },
    --     },
    --     pedProps = {
    --         {
    --             componentId = 1,
    --             drawableId = 0,
    --             textureId = 0
    --         },
    --     },
    --     npcType = "npcPolice",
    --     npcLocation = "Norte",
    -- },

    ["SurLocator"] = {
        coords = vector4(460.01, -1012.96, 27.24, 180.94),
        model = "s_m_m_janitor",
        scenario = "WORLD_HUMAN_JANITOR",
        targetLabel = "Pedir indicaciones a Paco",
        npcType = "npcPoliceLocator",
        npcLocation = "Sur",
    },

    ["Paleto"] = {
        coords = vector4(-448.25, 6012.44, 30.72, 315.51),
        model = "s_f_y_sheriff_01",
        scenario = "WORLD_HUMAN_COP_IDLES",
        targetLabel = "Hablar con la Oficial Anastasia",
        pedComponents = {
            {
                componentId = 2,
                drawableId = 2,
                textureId = 2
            },
            {
                componentId = 0,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 9,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 3,
                drawableId = 1,
                textureId = 0
            },
            {
                componentId = 5,
                drawableId = 1,
                textureId = 0
            },
        },
        npcType = "npcPolice",
        npcLocation = "Paleto",
    },
}

Config.Props = {
    { label = 'Cono Policia', model = 'prop_roadcone02a' },
    { label = 'Caja',         model = 'prop_box_wood04a' },
    { label = 'Barrera',      model = 'prop_barrier_work05' },
}

Config.weaponTints = {
    ['WEAPON_GLOCK45']         = {
        { value = 0, label = "Normal" },
        { value = 1, label = "Verde",  requiredRank = 6 },
        --{value = 2, label = "Dorado", requiredRank = 2},
        --{value = 3, label = "Rosa"},
        { value = 4, label = "Arena",  requiredRank = 6 },
        --{value = 5, label = "Azúl", requiredRank = 2},
        --{value = 6, label = "Naranja", requiredRank = 2},
        { value = 7, label = "Blanco", requiredRank = 2 }
    },
    ['WEAPON_P226']            = {
        { value = 0, label = "Normal" },
        --{value = 1, label = "Verde"},
        --{value = 2, label = "Dorado"},
        { value = 3, label = "Metal y plástico",                  requiredRank = 2 },
        { value = 4, label = "Arena y plástico",                  requiredRank = 6 },
        { value = 5, label = "Empuñadura cuero",                  requiredRank = 2 },
        { value = 6, label = "Cañón metálico",                    requiredRank = 2 },
        { value = 7, label = "Empuñadura cuero y cañón metálico", requiredRank = 2 }
    },
    ['WEAPON_ENDURANCE2']      = {
        { value = 0, label = "Normal" },
        --{value = 1, label = "Verde"},
        --{value = 2, label = "Dorado"},
        { value = 3, label = "Metálico",          requiredRank = 6 },
        { value = 4, label = "Arena y plástico",  requiredRank = 6 },
        { value = 5, label = "Empuñadura madera", requiredRank = 6 },
        { value = 6, label = "Mitad metálica",    requiredRank = 6 },
        { value = 7, label = "Metalizada",        requiredRank = 6 },
    },
    ['WEAPON_POCKETLIGHT']     = {
        { value = 0, label = "Normal" },
        { value = 1, label = "Verde",   requiredRank = 2 },
        { value = 2, label = "Dorado",  requiredRank = 2 },
        --{value = 3, label = "Rosa"},
        { value = 4, label = "Arena",   requiredRank = 2 },
        { value = 5, label = "Azúl",    requiredRank = 2 },
        { value = 6, label = "Naranja", requiredRank = 2 },
        { value = 7, label = "Blanco",  requiredRank = 2 }
    },
    ['WEAPON_GARDONE']         = {
        { value = 0, label = "Normal" },
        --{value = 1, label = "Verde"},
        --{value = 2, label = "Dorado"},
        { value = 3, label = "Metal",                            requiredRank = 2 },
        { value = 4, label = "Arena",                            requiredRank = 6 },
        { value = 5, label = "Empuñadura cuero y arma negra",    requiredRank = 2 },
        { value = 6, label = "Empuñadura cuero y arma metálica", requiredRank = 2 },
        { value = 7, label = "Metalizada",                       requiredRank = 2 }
    },
    ['WEAPON_COLBATON']        = {
        { value = 0, label = "Normal" },
        { value = 1, label = "Verde",  requiredRank = 2 },
        --{value = 2, label = "Dorado"},
        --{value = 3, label = "Rosa"},
        { value = 4, label = "Arena",  requiredRank = 2 },
        { value = 5, label = "Azul",   requiredRank = 2 },
        { value = 6, label = "Rojo",   requiredRank = 2 },
        { value = 7, label = "Blanco", requiredRank = 8 }
    },
    ['WEAPON_DP9']             = {
        { value = 0, label = "Normal" },
        --{value = 1, label = "Verde"},
        --{value = 2, label = "Dorado"},
        --{value = 3, label = "Rosa"},
        { value = 4, label = "Arena",                 requiredRank = 6 },
        { value = 5, label = "Arena con cañón negro", requiredRank = 6 },
        { value = 6, label = "Cañón metálico",        requiredRank = 6 },
        { value = 7, label = "Metalizado",            requiredRank = 2 }
    },
    ['WEAPON_TACTICALCARBINE'] = {
        { value = 0, label = "Normal" },
        --{value = 1, label = "Verde"},
        --{value = 2, label = "Dorado"},
        --{value = 3, label = "Rosa"},
        { value = 4, label = "Arena",            requiredRank = 6 },
        { value = 5, label = "Azúl",             requiredRank = 6 },
        { value = 6, label = "Detalles rojizos", requiredRank = 6 },
        { value = 7, label = "Satinado",         requiredRank = 2 }
    }
}

Config.basicEquipment = { -- POR HACER
    { item = 'WEAPON_GLOCK45',      amount = 1,  serial = ("POL - " .. math.random(1000, 9999)) },
    { item = 'WEAPON_STUNGUNGREEN', amount = 1,  serial = ("POL - " .. math.random(1000, 9999)) },
    { item = 'WEAPON_COLBATON',     amount = 1,  serial = ("POL - " .. math.random(1000, 9999)) },
    { item = 'WEAPON_POCKETLIGHT',  amount = 1,  serial = ("POL - " .. math.random(1000, 9999)) },
    { item = 'ammo-38',             amount = 250 },
    { item = 'heavyarmour',         amount = 1 },
    { item = 'armor_plates',        amount = 3 },
    { item = 'detector',      amount = 1 },
    { item = 'police_cad',          amount = 1 },
    { item = 'lspd_badge',          amount = 1 },
    { item = 'megaphone',           amount = 1 }
}

Config.itemsArmory = { -- POR HACER

    ["policeArmory"] = {
        { name = 'WEAPON_GLOCK45',         components = { "at_flashlight" },              serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_DP9',             components = { "at_flashlight" },              serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_ENDURANCE2',      serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_STUNGUNGREEN',    serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_STUNGUNYELLOW',   serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_STUNGUNBLACK',    serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_COLBATON',        serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_NIGHTSTICK',      serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_POCKETLIGHT',     serial = ("POL - " .. math.random(1000, 9999)) },
        -- { name = 'WEAPON_LESSLETHAL',      serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_WARDEN',          serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_MP9',             serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_TACTICALCARBINE', components = { "at_flashlight" },              serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'ammo-38' },
        -- { name = 'ammo-rubber' },
        { name = 'ammo-rifle2' },
        { name = 'ammo-shotgun' },
        { name = 'armor_plates' },
        { name = 'cinturon_tactico' },
        { name = 'detector' },
        { name = 'heavyarmour' },
        { name = 'at_flashlight' },
        { name = 'colbaton_grip' },
        { name = 'pocketlight_uv' },
        { name = 'parachute' },
        { name = 'prop_mp_cone_02' },
        { name = 'prop_barrier_work05' },
        { name = 'prop_parking_sign_1' },
        { name = 'prop_mp_barrier_02b' },
        { name = 'prop_air_conelight' },
        { name = 'lspd_badge' },
        { name = 'police_cad' },
        { name = 'megaphone' },

    },

    ["divisionsArmory"] = { -- POR HACER
        { name = 'WEAPON_P226',       serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_ENDURANCE2', serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'WEAPON_VECTOR',     serial = ("POL - " .. math.random(1000, 9999)) },
        { name = 'ammo-38' },
    }
}

Config.startVehicles = { -- LISTO
    "hvstanier"
}

Config.points = { -- LISTO
    ["Sur"] = {
        blip = {
            coords = vector3(438.50, -1020.30, 28.71),
            sprite = 60,
            color = 29,
            scale = 0.9,
            name = "Comisaria Mission Row"
        },

        leaveJail = vector4(477.39, -979.88, 27.98, 2.41),

        vehiclePoints = {
            {
                Menu = vector3(457.75, -979.62, 25.68), -- Nueva comi 
                Delete = vector3(458.47, -990.88, 25.68),
                Spawn = vector4(457.50, -983.54, 25.68, 89.03),
            },
            {
                Menu = vector3(441.96, -979.40, 25.68), -- Nueva comi 
                Delete = vector3(442.05, -987.89, 25.68),
                Spawn = vector4(442.27, -983.59, 25.68, 90.50),
            },
            {
                Menu = vector3(425.60, -979.27, 25.68), -- Nueva comi 
                Delete = vector3(425.49, -988.23, 25.68),
                Spawn = vector4(425.59, -983.68, 25.68, 268.22),
            },
            {
                Menu = vector3(457.30, -1024.26, 28.43), -- Nueva commi 
                Delete = vector3(449.74, -1024.69, 28.57),
                Spawn = vector4(453.58, -1024.69, 28.51, 7.02),
            },
            {
                Menu = vector3(-1852.01, 2905.13, 32.81), -- Zancudo
                Delete = vector3(-1863.39, 2911.50, 32.81),
                Spawn = vector4(-1863.39, 2911.50, 32.81, 59.04),
            },
            {
                Menu = vector3(-1122.92, -862.76, 13.57), -- Vespucci
                Delete = vector3(-1115.32, -857.67, 13.54),
                Spawn = vector4(-1125.66, -865.12, 13.56, 42.31),
            },
            {
                Menu = vector3(829.16, -1345.54, 26.09), -- La mesa 
                Delete = vector3(826.66, -1332.84, 26.11),
                Spawn = vector4(828.68, -1350.68, 26.10, 76.24),
            },
            {
                Menu = vector3(-448.34, 5994.53, 31.34), -- Paleto 
                Delete = vector3(-454.65, 6001.87, 31.34),
                Spawn = vector4(-450.74, 5998.19, 31.34, 84.89),
            },
            {
                Menu = vector3(531.25, -27.59, 70.63), -- Vinewood
                Delete = vector3(537.96, -40.34, 70.78),
                Spawn = vector4(537.96, -40.34, 70.78, 211.03),
            },
            {
                Menu = vector3(-555.35, -145.75, 38.13), 
                Delete = vector3(-573.90, -136.82, 36.44),
                Spawn = vector4(-546.54, -143.13, 38.27, 239.14),
            },
            {
                Menu = vector3(388.60, -1612.66, 29.28),
                Delete = vector3(396.59, -1623.56, 29.29),
                Spawn = vector4(392.60, -1620.33, 29.29, 321.56),
            },
            {
                Menu = vector3(300.13, -573.96, 43.26),
                Delete = vector3(291.09, -588.39, 43.19),
                Spawn = vector4(293.90, -572.18, 43.16, 63.92),
            },
            {
                Menu = vector3(311.76, -555.87, 28.88),
                Delete = vector3(327.40, -548.50, 28.75),
                Spawn = vector4(317.78, -552.82, 28.75, 272.21),
            },
        },

        depotPoints = {
            {
                Menu = vector3(436.44, -986.49, 30.71),
                Spawn = vector4(408.48, -993.42, 29.27, 58.19),
            },
        },

        helicopterPoints = {
            {
                Menu = vector3(474.64, -1000.73, 39.07),
                Delete = vector3(469.21, -995.52, 39.07),
                Spawn = vector4(469.21, -995.52, 39.07, 95.78),
            },
            {
                Menu = vector3(450.35, -991.67, 43.69),
                Delete = vector3(444.70, -986.89, 43.69),
                Spawn = vector4(444.70, -986.89, 43.69, 88.79),
            },
            {
                Menu = vector3(-1928.88, 3018.55, 32.81),
                Delete = vector3(-1957.73, 3042.53, 32.81),
                Spawn = vector4(-1928.88, 3018.55, 32.81, 327.93),
            },
            {
                Menu = vector3(-455.47, 5984.42, 31.31),
                Delete = vector3(-475.35, 5988.46, 31.34),
                Spawn = vector4(-475.35, 5988.46, 31.34, 315.06),
            },
            {
                Menu = vector3(570.82, 5.24, 103.23),
                Delete = vector3(579.82, 12.05, 103.23),
                Spawn = vector4(579.82, 12.05, 103.23, 359.73),
            },
            {
                Menu = vector3(-1106.63, -835.46, 37.68),
                Delete = vector3(-1095.50, -835.17, 37.67),
                Spawn = vector4(-1095.50, -835.17, 37.67, 127.46),
            },
        },

        boatPoints = {
            {
                Menu = vector3(-780.04, -1496.43, 1.65),
                Delete = vector3(-791.99, -1500.92, 0.12),
                Spawn = vector4(-791.99, -1500.92, 0.12, 109.89),
            },
            {
                Menu = vector3(712.89, 4101.81, 35.79),
                Delete = vector3(697.13, 4111.89, 30.24),
                Spawn = vector4(697.13, 4111.89, 30.24, 180.11),
            },
            {
                Menu = vector3(-1630.67, -1131.93, 1.58),
                Delete = vector3(-1645.26, -1164.79, 0.40),
                Spawn = vector4(-1645.26, -1164.79, 0.40, 139.70),
            },
            {
                Menu = vector3(1294.37, -3342.18, 5.90),
                Delete = vector3(1318.31, -3343.40, 1.08),
                Spawn = vector4(1318.31, -3343.40, 1.08, 269.11),
            },
        },

        armoryPoints = {
            {
                coords = vector3(-1836.30, 3028.95, 32.81),
                label = "Armeria RTD",
                armory = "policeArmory",
            },
            {
                coords = vector3(481.30, -1005.71, 30.69),
                label = "Armeria",
                armory = "policeArmory",
            },
            {
                coords = vector3(481.38, -1001.25, 30.69),
                label = "Armeria Mission Row",
                armory = "policeArmory",
            },
            {
                coords = vector3(447.5818, -976.6341, 34.8175),
                label = "Armeria Jefes",
                armory = "policeArmory",
            },
            {
                coords = vector3(-444.67, 6010.44, 31.72),
                label = "Armeria Paleto",
                armory = "policeArmory",
            },
            -- {
            --     -- coords pendiente de configurar
            --     label = "Armeria Division",
            --     armory = "divisionsArmory",
            --     allowedDivisions = {
            --         "SEB",
            --         "METRO",
            --         "DB",
            --         "SCUB"
            --     }
            -- },
        },

        cloakroomPoints = {
            { coords = vector3(468.15, -999.67, 30.69), radius = 3.0 },
            --{ coords = vector3(479.26, -988.02, 30.71), radius = 3.0 },
            --{ coords = vector3(467.99, -999.99, 18.67), radius = 3.0 },
        },

        incuationPoints = {
            vector3(474.07, -1005.92, 26.21),
        },

        -- Pendiente de configurar
        dutyPoints = {
            -- vector3(-1064.61, -816.47, 11.03),
            -- vector3(-1102.94, -829.97, 19.56),
        },

        -- Pendiente de configurar
        fingerprintPoints = {
            vector3(475.92, -1012.08, 26.21),
        },

        -- Pendiente de configurar
        belongingsPoints = {
            -- vector3(-1067.95, -814.35, 10.73),
        },

        -- Pendiente de configurar
        bossPoints = {
            -- vector3(634.18, -9.71, 87.80),
        },

        -- Pendiente de configurar
        ascensorPoints = {
            -- ["Izquierdo"] = {
            --     { label = "Atico",     coords = vector4(602.51, -18.20, 101.34, 339.79) },
            --     { label = "Planta 2",  coords = vector4(613.21, -10.86, 87.80, 341.43) },
            --     { label = "Planta 1",  coords = vector4(613.08, -10.63, 83.64, 334.70) },
            --     { label = "Planta -1", coords = vector4(613.09, -11.02, 75.05, 337.32) },
            -- },
            -- ["Derecho"] = {
            --     { label = "Atico",     coords = vector4(598.19, -16.61, 101.34, 337.45) },
            --     { label = "Planta 2",  coords = vector4(608.49, -8.95, 87.80, 340.60) },
            --     { label = "Planta 1",  coords = vector4(608.42, -9.27, 83.64, 338.55) },
            --     { label = "Planta -1", coords = vector4(608.49, -9.19, 75.05, 338.77) },
            -- },
        },

        extrasPoints = {
            { Menu = vector3(-478.78, 6027.90, 31.34) },
            { Menu = vector3(428.46, -1027.16, 28.97) },
            { Menu = vector3(433.76, -971.03, 25.68) },
            { Menu = vector3(-1128.52, -837.90, 13.57) },
            { Menu = vector3(823.68, -1368.86, 26.14) },
            { Menu = vector3(291.85, -592.86, 43.12) },
            { Menu = vector3(315.93, -544.96, 28.754) },
            { Menu = vector3(542.47, -49.99, 70.36) },
            { Menu = vector3(-578.88, -141.76, 36.81) },
            { Menu = vector3(441.97, -971.07, 25.68) },
            { Menu = vector3(442.32, -1025.37, 28.71) },
            { Menu = vector3(449.73, -971.07, 25.68) },
            { Menu = vector3(319.79, -541.96, 28.75) },
        },
    },
}


Config.carModels = {
    { model = "hvsentinel5",          label = "sentinel 5" },
    { model = "hvbuffaloXT4",       label = "Bravado" },
    { model = "hvcoqd5",          label = "Coquette D5" },
    { model = "hvvigzx2",         label = "Vigero" },   
    { model = "hvShinobi",           label = "Police Shinobi" },
    { model = "hvBF400",          label = "BF400" },
    { model = "hvkomoda2",          label = "komoda" },
    { model = "hvpdalamo",          label = "dalamo 4x4" },
    { model = "hvdominatorgtr",          label = "Dominator GTR" },
    { model = "hvnagv2",          label = "Moto Montaña" },
    { model = "hvomnisegt",          label = "Omnisegt" },
    { model = "hvpolstang",          label = "Police Mustang" },
    { model = "hvterminus",          label = "Terminus" }
}


Config.helicopterModels = {
    {
        model = "swathel",
        label = "Helicoptero del SWAT",
        liverys = {
            {
                label = "SWAT",
                value = 0
            },
        },
    },
    {
        model = "hvpdconada",
        label = "Police Conada",
        liverys = {
            {
                label = "LSPD",
                value = 0
            },
            {
                label = "LSSD",
                value = 1
            },
            {
                label = "Trooper",
                value = 2
            },
            {
                label = "SWAT",
                value = 3
            },
            {
                label = "RRPP",
                value = 4
            },
            {
                label = "Liso",
                value = 5
            },
        },
    },
    {
        model = "hvpolmav",
        label = "Police Maverick",
        liverys = {
            {
                label = "LSPD",
                value = 0
            },
            {
                label = "LSSD",
                value = 1
            },
            {
                label = "Trooper",
                value = 2
            },
        },
    },
    {
        model = "2vd_supervolito",
        label = "Police SuperVolito",
        liverys = {
            {
                label = "LSPD",
                value = 0
            },
            {
                label = "LSSD",
                value = 1
            },
            {
                label = "SAHP",
                value = 2
            },
            {
                label = "Blanca",
                value = 3
            },
        },
    },
    {
        model = "hvannihilator",
        label = "Helicoptero SWAT",
        liverys = {
            {
                label = "SWAT LSPD",
                value = 0
            },
            {
                label = "SWAT LSSD",
                value = 1
            },
        },
    },
    {
        model = "hvbuzz2",
        label = "Buzzard SWAT",
        liverys = {
            {
                label = "SWAT LSPD",
                value = 0
            },
            {
                label = "SWAT LSSD",
                value = 1
            },
        },
    },
    {
        model = "hvcargobob5",
        label = "Helicoptero transporte SWAT",
        liverys = {
            {
                label = "SWAT LSPD",
                value = 0
            },
            {
                label = "SWAT LSSD",
                value = 1
            },
        },
    },
}

Config.boatModels = {
    { model = "hvpredator", label = "Predator policial" },
    { model = "largeboat",  label = "Barco Rescate" },
    { model = "nkdinghy4",  label = "Lancha Dinghy" },
    { model = "hvswatdinghy", label = "Dinghy" },
}