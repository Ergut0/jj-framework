local backpackItemBlacklist = {
    'pocket',
    'backpack_small',
    'backpack_medium',
    'backpack_large',
}

return {
    enabled = true,
    slots = 8,
    slotOffset = 1000,
    enableBackpackComponents = true,  -- Set to false to disable backpack visual components
    items = {
        [1] = { 'armour', 'heavyarmour' },                              -- vest/armor
        [2] = { 'backpack_small', 'backpack_medium', 'backpack_large' }, -- backpack
        [3] = { 'phone' },                                               -- phone
        [4] = { 'parachute' },                                           -- parachute
        [5] = { 'pocket' },                                                      -- weapon slot 1
        [6] = { 'tablett', 'laptopp' },                                            -- weapon slot 2
        [7] = { 'keys'},                                                         -- utility slot 3
        [8] = { 'radio'},                                                        -- utility slot 4
    },
    labels = {
        [1] = 'Chaleco',
        [2] = 'Mochila',
        [3] = 'Movil',
        [4] = 'Paracaídas',
        [5] = 'Bolsillo',
        [6] = 'Tablet',
        [7] = 'Llaves',
        [8] = 'Radio',
    },
    icons = {
        [1] = 'vest.svg',
        [2] = 'backpack.svg',
        [3] = 'phone.svg',
        [4] = 'parachute.svg',
        [5] = 'pocket1.svg',
        [6] = 'tablet.svg',
        [7] = 'keys.svg',
        [8] = 'radio.svg',
    },
    iconSizes = {
        [1] = 50,
        [2] = 60,
        [3] = 60,
        [4] = 65,
        [5] = 65,
        [6] = 65,
        [7] = 65,
        [8] = 65,
    },
    lockBackpackRemovalWithItems = false, -- true = cannot remove backpack if it has items
    armorItems = {
        armour = {
            value = 50,
            jobs = {},
            plates = 2,
        },
        heavyarmour = {
            value = 100,
            jobs = {},
            plates = 5,
        },
    },
    armorDamageRate = 0.5,
    armorRepairItems = {
        --armor_repair_kit = 20,
        --armor_plates = 20,
    },
    backpackItems = {
        pocket = {
            slots = 1,
            weight = 50000,
            blacklist = backpackItemBlacklist,
            component = {
                drawable = 39,  -- Backpack drawable ID
                texture = 0,   -- Backpack texture variation
            },
            },
        backpack_small = {
            slots = 20,
            weight = 50000,
            blacklist = backpackItemBlacklist,
            component = {
                drawable = 39,  -- Backpack drawable ID
                texture = 0,   -- Backpack texture variation
            },
        },
        backpack_medium = {
            slots = 30,
            weight = 100000,
            blacklist = backpackItemBlacklist,
            component = {
                drawable = 45,  -- Different drawable for medium backpack
                texture = 0,
            },
        },
        backpack_large = {
            slots = 50,
            weight = 150000,
            blacklist = backpackItemBlacklist,
            component = {
                drawable = 45,  -- Different drawable for large backpack
                texture = 0,
            },
        },
    },
}
