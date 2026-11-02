return {
    -- Set to false to completely disable the rarity system (all items treated as common)
    Enabled = false,


    Levels = {
        common = {
            label      = 'Common',
            text       = '#ffffff',
            color      = '#636363',
            background = 'radial-gradient(#00000050, #51515150)',
            animation  = false,
        },
        uncommon = {
            label      = 'Uncommon',
            text       = '#84cc16',
            color      = '#84cc16',
            background = 'radial-gradient(#00000050, #84cc1615)',
            animation  = false,
        },
        rare = {
            label      = 'Rare',
            text       = '#0ea5e9',
            color      = '#0ea5e9',
            background = 'radial-gradient(#00000000, #0ea5e920)',
            animation  = false,
        },
        epic = {
            label      = 'Epic',
            text       = '#c026d3',
            color      = '#c026d3',
            background = 'radial-gradient(#00000000, #be185d25)',
            animation  = false,
        },
        legendary = {
            label      = 'Legendary',
            text       = '#eab308',
            color      = '#eab308',
            background = 'radial-gradient(#00000000, #a1620725)',
            animation  = true,
        },
    }
}
