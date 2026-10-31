Config = {}

Config.UseTarget = GetConvar('UseTarget', 'false') ==
    'true'                  -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
Config.PauseMapText =
''                          -- Text shown above the map when ESC is pressed. If left empty 'FiveM' will appear
Config.HarnessUses = 20
Config.DamageNeeded = 100.0 -- amount of damage till you can push your vehicle. 0-1000
Config.Logging = 'discord'  -- fivemanage

Config.AFK = {
    ignoredGroups = {
        ['mod'] = true,
        ['admin'] = true,
        ['god'] = true
    },
    secondsUntilKick = 1000000, -- AFK Kick Time Limit (in seconds)
    kickInCharMenu = false      -- Set to true if you want to kick players for being AFK even when they are in the character menu.
}

Config.HandsUp = {
    command = 'hu',
    keybind = 'X',
    controls = { 24, 25, 47, 58, 59, 63, 64, 71, 72, 75, 140, 141, 142, 143, 257, 263, 264 }
}

Config.Binoculars = {
    zoomSpeed = 10.0,        -- camera zoom speed
    storeBinocularsKey = 177 -- backspace by default
}

Config.DoctorIlegal = {

    itemsNeeded = {
        { name = 'medikit', amount = 1 },
    },

    infoDoctor = {
        {
            coords = vector3(0, 0, 0),
            heading = 167.14,
            needItems = true,
        },
    }

}

Config.AIResponse = {
    wantedLevels = false, -- if true, you will recieve wanted levels
    dispatchServices = {  -- AI dispatch services
        [1] = false,      -- Police Vehicles
        [2] = false,      -- Police Helicopters
        [3] = false,      -- Fire Department Vehicles
        [4] = false,      -- Swat Vehicles
        [5] = false,      -- Ambulance Vehicles
        [6] = false,      -- Police Motorcycles
        [7] = false,      -- Police Backup
        [8] = false,      -- Police Roadblocks
        [9] = false,      -- PoliceAutomobileWaitPulledOver
        [10] = false,     -- PoliceAutomobileWaitCruising
        [11] = false,     -- Gang Members
        [12] = false,     -- Swat Helicopters
        [13] = false,     -- Police Boats
        [14] = false,     -- Army Vehicles
        [15] = false      -- Biker Backup
    }
}

Config.Density = {
    parked = 0.1,
    vehicle = 0.1,
    multiplier = 0.4,
    peds = 0.8,
    scenario = 1.0
}

Config.Disable = {
    hudComponents = { 1, 2, 3, 4, 7, 9, 13, 19, 20, 21, 22 }, -- Hud Components: https://docs.fivem.net/natives/?_0x6806C51AD12B83B8
    controls = { 37 },                                        -- Controls: https://docs.fivem.net/docs/game-references/controls/
    displayAmmo = false,                                      -- false disables ammo display
    ambience = false,                                          -- disables distance sirens, distance car alarms, flight music, etc
    vestDrawable = false,                                     -- disables the vest equipped when using heavy armor
    pistolWhipping = true,                                    -- disables pistol whipping
    driveby = false,                                          -- disables driveby
}



Config.BlacklistedScenarios = {
    types = {
        'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
        'WORLD_VEHICLE_MILITARY_PLANES_BIG',
        'WORLD_VEHICLE_AMBULANCE',
        'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
        'WORLD_VEHICLE_POLICE_CAR',
        'WORLD_VEHICLE_POLICE_BIKE',

        'WORLD_VEHICLE_HELI_LIFEGUARD',
        'WORLD_VEHICLE_HELI_LIFEGUARD_PILOT',
        'WORLD_VEHICLE_HELI_LIFEGUARD_SEARCH',
        'WORLD_VEHICLE_HELI_LIFEGUARD_WRECK',

        'WORLD_VEHICLE_HELI_POLICE',
        'WORLD_VEHICLE_HELI_POLICE_PILOT',
        'WORLD_VEHICLE_HELI_POLICE_SEARCH',

        'WORLD_VEHICLE_HELI_TOURIST',
        'WORLD_VEHICLE_HELI_TOURIST_PILOT',

        'WORLD_VEHICLE_HELI_MILITARY',
        'WORLD_VEHICLE_HELI_MILITARY_PILOT',

        'WORLD_VEHICLE_HELI_CARGO',
        'WORLD_VEHICLE_HELI_CARGO_PILOT',

        'WORLD_VEHICLE_HELI_PASSENGER',
        'WORLD_VEHICLE_HELI_PILOT'
    },

    groups = {
        2017590552,
        2141866469,
        1409640232,
        'ng_planes'
    }
}

Config.BlacklistedVehs = {
    [`shamal`] = true,
    [`luxor`] = true,
    [`duster`] = true,
    [`cuban800`] = true,
    [`jet`] = true,
    [`lazer`] = true,
    [`buzzard`] = true,
    [`annihilator`] = true,
    [`savage`] = true,
    [`titan`] = true,
    [`rhino`] = true,
    [`firetruck`] = true,
    [`mule`] = true,
    [`blimp`] = true,
    [`airtug`] = true,
    [`camper`] = true,
    [`oppressor`] = true,
    [`technical3`] = true,
    [`insurgent3`] = true,
    [`apc`] = true,
    [`tampa3`] = true,
    [`trailersmall2`] = true,
    [`halftrack`] = true,
    [`hunter`] = true,
    [`vigilante`] = true,
    [`akula`] = true,
    [`barrage`] = true,
    [`khanjali`] = true,
    [`caracara`] = true,
    [`blimp3`] = true,
    [`menacer`] = true,
    [`oppressor2`] = true,
    [`scramjet`] = true,
    [`strikeforce`] = true,
    [`cerberus`] = true,
    [`cerberus2`] = true,
    [`cerberus3`] = true,
    [`scarab`] = true,
    [`scarab2`] = true,
    [`scarab3`] = true,
    [`rrocket`] = true,
    [`ruiner2`] = true,
    [`deluxo`] = true,
    [`cargoplane2`] = true,
    [`voltic2`] = true,
    [`polmav`] = false,
}

Config.BlacklistedWeapons = {
    [`WEAPON_RAILGUN`] = true,
}

Config.BlacklistedZonesVehicles = {
    -- vector3(-331.38, -1235.96, 28.35), -- zona bennys
    -- vector3(-778.83, -2054.02, 30.88), -- zona bennys 
    -- vector3(1228.15, 2710.47, 38.01), -- zona bennys
    -- vector3(-622.73, -2180.39, 9.98), -- zona compraventa
    -- vector3(-640.3, -2124.14, 8.83), -- zona compraventa 
    -- vector3(-602.84, -2077.3, 6.63), -- zona compraventa 
    -- vector3(-695.84, -2052.42, 8.93), -- zona compraventa 
    -- vector3(-692.76, -2111.22, 7.84), -- zona compraventa 
    -- vector3(-697.16, -2004.3, 8.87), -- zona compraventa 
}

Config.BlacklistedPeds = {
    [`s_m_y_ranger_01`] = true,
    [`s_m_y_sheriff_01`] = true,
    [`s_m_y_cop_01`] = true,
    [`s_f_y_sheriff_01`] = true,
    [`s_f_y_cop_01`] = true,
    [`s_m_y_hwaycop_01`] = true,
    [`s_m_y_blackops_01`] = true,
    [`s_m_y_blackops_03`] = true,
    [`s_m_y_blackops_02`] = true,
    [`csb_mweather`] = true,
}

-- Nombres que se muestran para vehículos añadidos al servidor: { hash = `modelo`, brand = 'Marca', name = 'Nombre' }
Config.VehicleLabels = {}

Config.Objects = { -- for object removal
    --{ coords = vector3(266.09, -349.35, 44.74), heading = 0, length = 200, width = 200, model = 'prop_sec_barier_02b' },
    --{ coords = vector3(285.28, -355.78, 45.13), heading = 0, length = 200, width = 200, model = 'prop_sec_barier_02a' },
}

Config.Shops = {
    -- {
    --     ped = "s_m_m_ammucountry",
    --     blip = {
    --         id = 110, colour = 69, scale = 0.6
    --     },
    --     coords = {
    --         vector4(23.07, -1105.64, 29.8, 147.01),
    --     },
    --     shop = {
    --         name = "Ammunation",
    --         items = {
    --             { name = 'heavyarmour', price = 6000 },
    --             { name = 'armor_plates', price = 600 },
    --             { name = 'WEAPON_KNIFE',       price = 5000 },
    --             { name = 'WEAPON_FLASHLIGHT',  price = 5000 },
    --             { name = 'WEAPON_HATCHET',     price = 5000 },
    --             { name = 'WEAPON_POOLCUE',     price = 5000 },
    --             { name = 'WEAPON_GOLFCLUB',    price = 5000 },
    --             { name = 'binoculars',         price = 500 },
    --             { name = 'lockpick',         price = 300 },
    --             { name = 'kuz_divinggeargood', price = 300 },
    --         }
    --     }
    -- },
    -- {
    --     ped = "s_m_m_ammucountry",
    --     blip = {
    --         id = 110, colour = 69, scale = 0.6
    --     },
    --     coords = {
    --         vector4(-331.40, 6085.24, 31.45, 223.93),
    --     },
    --     shop = {
    --         name = "Ammunation",
    --         items = {
    --             { name = 'heavyarmour', price = 5000 },
    --             { name = 'armor_plates', price = 400 },
    --             { name = 'WEAPON_KNIFE',       price = 4000 },
    --             { name = 'WEAPON_FLASHLIGHT',  price = 4000 },
    --             { name = 'WEAPON_HATCHET',     price = 4000 },
    --             { name = 'WEAPON_POOLCUE',     price = 4000 },
    --             { name = 'WEAPON_GOLFCLUB',    price = 4000 },
    --             { name = 'binoculars',         price = 300 },
    --             { name = 'lockpick',         price = 250 },
    --             { name = 'kuz_divinggeargood', price = 250 },
    --         }
    --     }
    -- },
    -- {
    --     ped = "s_m_m_ammucountry",
    --     blip = {
    --         id = 110, colour = 69, scale = 0.6
    --     },
    --     coords = {
    --         vector4(-1118.73, 2699.94, 18.55, 222.12),
    --     },
    --     shop = {
    --         name = "Ammunation",
    --         items = {
    --             { name = 'heavyarmour', price = 5500 },
    --             { name = 'armor_plates', price = 500 },
    --             { name = 'WEAPON_KNIFE',       price = 4500 },
    --             { name = 'WEAPON_FLASHLIGHT',  price = 4500 },
    --             { name = 'WEAPON_HATCHET',     price = 4500 },
    --             { name = 'WEAPON_POOLCUE',     price = 4500 },
    --             { name = 'WEAPON_GOLFCLUB',    price = 4500 },
    --             { name = 'binoculars',         price = 400 },
    --             { name = 'lockpick',           price = 200 },
    --             { name = 'kuz_divinggeargood', price = 200 },
    --         }
    --     }
    -- },
    -- {
    --     ped = "s_m_m_doctor_01",
    --     blip = false, -- no blip for this shop
    --     coords = {
    --         vector4(1123.48, -1500.36, 40.05, 92.15)
    --     },
    --     shop = {
    --         name = "Tienda Sanitarios",
    --         items = {
    --             { name = 'radio',          price = 0 },
    --             { name = 'weapon_stungun', price = 0 },
    --         }
    --     }
    -- },
    -- {
    --     ped = "a_m_y_skater_02",
    --     blip = {
    --         id = 36, colour = 7, scale = 0.6
    --     },
    --     coords = {
    --         vector4(501.72, 5600.84, 796.60, 178.17)
    --     },
    --     shop = {
    --         name = "Tienda de Paracaidas",
    --         items = {
    --             { name = 'parachute', price = 50 },
    --         }
    --     }
    -- },

}
