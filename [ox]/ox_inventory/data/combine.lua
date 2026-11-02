

return {
    -- Turn the combine system on or off.
    enabled = true,

    animation = {
        dict = 'amb@prop_human_parking_meter@male@base',
        clip = 'base',
        flag = 49,
    },

    -- Codex categories, shown in this order. Recipes point to these by id.
    categories = {
        { id = 'materials', label = 'Materials' },
        { id = 'mechanic',  label = 'Mechanic'  },
        { id = 'medical',   label = 'Medical'   },
        { id = 'tools',     label = 'Tools'     },
    },

    recipes = {

        {
            id = 'lockpick',
            result = 'lockpick',
            count = 1,
            category = 'tools',
            duration = 3000,
            ingredients = {
                { item = 'scrapmetal', count = 2 },
            },
        },
        {
            id = 'radio',
            result = 'radio',
            count = 1,
            category = 'tools',
            duration = 4000,
            ingredients = {
                { item = 'scrapmetal', count = 3 },
                { item = 'lockpick',   count = 1 },
            },
        },
        {
            id = 'phone',
            result = 'phone',
            count = 1,
            category = 'tools',
            duration = 5000,
            ingredients = {
                { item = 'scrapmetal', count = 5 },
                { item = 'radio',      count = 1 },
            },
        },

        {
            id = 'bandage',
            result = 'bandage',
            count = 2,
            category = 'medical',
            duration = 3000,
            ingredients = {
                { item = 'scrapmetal', count = 1 },
            },
        },

        {
            id = 'armor_plates',
            result = 'armor_plates',
            count = 1,
            category = 'mechanic',
            duration = 6000,
            ingredients = {
                { item = 'scrapmetal', count = 4 },
            },
        },
        {
            id = 'armor_repair_kit',
            result = 'armor_repair_kit',
            count = 1,
            category = 'mechanic',
            duration = 5000,
            ingredients = {
                { item = 'scrapmetal', count = 3 },
            },
        },

        {
            id = 'parachute',
            result = 'parachute',
            count = 1,
            category = 'materials',
            duration = 7000,
            ingredients = {
                { item = 'scrapmetal', count = 8 },
            },
            -- Optional custom 3x3 layout (item name, or 0 for an empty cell):
            layout = {
                'scrapmetal', 'scrapmetal', 'scrapmetal',
                'scrapmetal', 0,            'scrapmetal',
                'scrapmetal', 'scrapmetal', 'scrapmetal',
            },
        },
    },
}
