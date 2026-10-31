Config = {}

Config.BillCost = 10
Config.AIHealTimer = 20
Config.RemoveItemsInRespawn = true

Config.Info = {

    ["blips"] = {
        { coords = vector3(1144.13, -1512.64, 34.84), name = "Hospital St Fiacre" },
        { coords = vector3(1102.09, 2724.66, 37.71),  name = "Hospital Sandy" },
    },

    ["beds"] = {

        ["Sur"] = {
            [1] = { coords = vector4(1145.35, -1550.06, 35.55, 90.25), taken = false },
            [2] = { coords = vector4(1145.24, -1554.20, 35.55, 90.25), taken = false },
            [3] = { coords = vector4(1140.39, -1554.23, 35.55, 268.72), taken = false },
            [4] = { coords = vector4(1140.20, -1550.16, 35.55, 268.72), taken = false },
        },

     --    ["Sur_Abajo"] = {
     --        { coords = vector4(323.24, -581.69, 29.45, 162.83), taken = false},
     --        { coords = vector4(323.24, -581.69, 29.45, 162.83), taken = false},
     --        { coords = vector4(319.03, -580.12, 29.45, 159.57), taken = false},
     --    },

        ["Norte"] = {
            [1] = { coords = vector4(1102.60, 2733.49, 39.39, 355.94), taken = false },
            [2] = { coords = vector4(1107.15, 2733.17, 39.40, 355.94), taken = false },
            [3] = { coords = vector4(1105.71, 2740.72, 39.37, 176.12), taken = false },
            [4] = { coords = vector4(1105.71, 2740.72, 39.37, 176.12), taken = false },
        },
    }, 

    ["checking"] = {

        ["Sur"] = {
            [1] = { coords = vector4(1145.49, -1541.19, 33.98, 351.87), npc = "s_m_m_doctor_01" },
        },

   --     ["Sur_Abajo"] = {
   --         [1] = { coords = vector4(341.82, -588.72, 27.78, 220.95), npc = "s_m_m_doctor_01" },
   --     },
-- 
        ["Norte"] = {
            [1] = { coords = vector4(1102.09, 2724.66, 37.71, 180.06), npc = "s_m_m_doctor_01" },
        },

    }
}

Config.BlackList = {
    WipeInventory = false,
    Weapons = true,
    Items = {
        "black_money",
        "bolsafentanilo",
        "packaged_weed",
        "packaged_dried_weed",
        "packaged_gingeritis_weed",
        "packaged_energizing_dried_weed",
        "packaged_high_quality_weed",
        "packaged_dried_high_quality_weed",
        "packaged_cooked_coke",
        "packaged_cooked_dried_coke",
        "packaged_high_quality_coke",
        "packaged_dried_high_quality_coke",
        "packaged_cooked_high_quality_coke",
        "packaged_cooked_dried_high_quality_coke",
        "packaged_default_meth",
        "ammo-9",
        "ammo-38",
        "ammo-shotgun",
        "ammo-rifle",
        "cuerpop",
        "cuerporifle",
        "cuerposmg",
        "cuerpopistola",
        "cuerpoescopeta",
    },
    SkipWeapons = {
        "WEAPON_MARKSMANPISTOL"
    },
    Jobs = {
        "police",
        "sheriff",
        "ambulance",
    },
}

Config.Shop = {
    { name = 'firstaid',                price = 0 },
    { name = 'weapon_flashlight',       price = 0 },
    { name = 'weapon_fireextinguisher', price = 0 },
    { name = 'weapon_spreader',         price = 0 },
    { name = 'weapon_saw',              price = 0 },
    { name = 'weapon_halligan',         price = 0 },
}

Config.Points = {

    -- inventory = {
    --     {coords = vector3(1135.73, -1542.87, 35.03), type = "inventory", name = "Armario Trabajo"},
    --     {coords = vector3(638.9993, 2746.4294, 47.9135), type = "inventory", name = "Armario Trabajo Sandy"},
    --     {coords = vec3(318.28, -584.79, 43.24), type = "shop", name = "Almacen"},
    --     {coords = vec3(1135.65, -1545.63, 35.03), type = "shop", name = "Almacen"},
    -- },

    -- cloakRooms = {
    --     {coords = vec3(1140.45, -1539.56, 35.03)},
    --     {coords = vec3(1676.02, 3586.28, 35.66)},
    -- },

    -- extras = {
    --     {coords = vec3(1130.67, -1587.74, 34.72)},
    --     {coords = vec3(317.2828, -553.2066, 28.7454)},
    --     {coords = vec3(1667.32, 3601.98, 34.64)},
    --     {coords = vec3(623.2252, 2831.9290, 42.6380)},
    -- },

    -- vehicles = {
    --     {coords = vec4(1140.44, -1585.26, 34.72, 180.3)},
    --     {coords = vec4(-253.7520, 6348.0718, 32.4263, 225.6570)},
    --     {coords = vec4(1677.69, 3602.83, 35.71, 30.28)},
    --     {coords = vec4(639.3844, 2799.1074, 41.9370, 334.0952)},
    -- },

    -- helicopters = {
    --     {coords = vector4(1186.2, -1552.53, 39.4, 351.16)},
    --     {coords =  vector4(1709.23, 3616.05, 37.11, 298.79)},
    --     {coords = vector4(606.63, 2773.07, 61.73, 183.72)},
    -- },

    -- -- boats = {
    -- --     {coords = vector4(337.73, -588.23, 43.94, 67.86)},
    -- -- },

    -- dutyPoints = {
    --     {coords = vec3(317.6, -582.3, 43.06)},
    --     {coords = vec3(-254.88, 6324.5, 32.58)},
    --     {coords = vec3(1673.77, 3573.88, 35.63)},
    --     {coords = vec3(639.1710, 2774.4641, 43.5551)},
    -- },

    -- bossPoints = {
    --     {coords = vector3(1128.04, -1572.93, 39.5)},
    -- }
}

Config.ListVehicles = {
    "gbemssteed",
    "gbemsesperta",
    "gbemsbisonstx",
    "gbfirevoyager",
    -- "pierce1",
}

Config.ListHelicopters = {
    "polmav",
    -- "c3fireheli",
}

Config.ListBoats = {
    "predator",
}



function IsHandCuffed()
    return LocalPlayer.state.isCuffed
end
