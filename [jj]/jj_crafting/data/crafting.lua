-- Configuración inicial de jj_crafting. Solo se usa la primera vez, para rellenar la base de datos:
-- después todo se cambia desde el panel /crafteoadmin y este archivo ya no se lee
return {
	packing = {
		enabled = true,
		confirmWithItems = true,
	},
	xp = {
		enabled = true,
		hideLocked = true,
		defaultReward = 0
	},
	blueprints = {
		lockpick = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'lockpick',
			consume = 0.05  -- Consume 5% durability per craft
		},
		weapon_bat = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_bat',
			consume = 0.05
		},
		weapon_crowbar = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_crowbar',
			consume = 0.05
		},
		weapon_wrench = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_wrench',
			consume = 0.05
		},
		weapon_hatchet = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_hatchet',
			consume = 0.05
		},
		weapon_hammer = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_hammer',
			consume = 0.05
		},
		weapon_pistol = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_pistol',
			consume = 0.05
		},
		weapon_smg = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_smg',
			consume = 0.05
		},
	},
	-- Tipos de mesa. Los que tienen placement son mesas de civiles: se colocan con su objeto.
	-- Los que no, son mesas de un punto fijo del mapa, como las de banda de `benches`
	types = {
		basic = {
			label = 'Mesa de crafteo básica',
			model = 'prop_tool_bench02',
			spawnRange = 35.0,
			storage = {
				slots = 30,
				maxWeight = 100000
			},
			placement = {
				item = 'bench_basic',
				returnItem = true
			},
			recipes = {
				{
					name = 'bandage',
					ingredients = {
						scrapmetal = 2,
						WEAPON_HAMMER = 0.05
					},
					duration = 4000,
					count = 1,
					xp = {
						required = 0,
						reward = 3
					},
				},
				{
					name = 'phone',
					ingredients = {
						scrapmetal = 5,
						WEAPON_HAMMER = 0.05
					},
					duration = 6000,
					count = 1,
					xp = {
						required = 0,
						reward = 8
					},
				},
				{
					name = 'parachute',
					ingredients = {
						scrapmetal = 8,
						WEAPON_HAMMER = 0.05
					},
					duration = 7000,
					count = 1,
					xp = {
						required = 0,
						reward = 10
					},
				},
				{
					name = 'radio',
					ingredients = {
						scrapmetal = 6,
						WEAPON_HAMMER = 0.05
					},
					duration = 5500,
					count = 1,
					xp = {	
						required = 0,
						reward = 7
					},
				},
				{
					name = 'armor_repair_kit',
					ingredients = {
						scrapmetal = 4,
						WEAPON_HAMMER = 0.05
					},
					duration = 4500,
					count = 1,
					xp = {
						required = 0,
						reward = 5
					},
				},
				{
					name = 'backpack_small',
					ingredients = {
						scrapmetal = 10,
						WEAPON_HAMMER = 0.05
					},
					duration = 12000,	
					count = 1,
					xp = {
						required = 0,
						reward = 12
					},
				},
				{
					name = 'backpack_medium',
					ingredients = {
						scrapmetal = 15,
						WEAPON_HAMMER = 0.05
					},
					duration = 18000,	
					count = 1,
					xp = {
						required = 0,
						reward = 18
					},
				},
				{
					name = 'backpack_large',
					ingredients = {
						scrapmetal = 20,
						WEAPON_HAMMER = 0.05
					},
					duration = 24000,	
					count = 1,
					xp = {
						required = 0,
						reward = 24
					},
				},
			}
		},
		advanced = {
			label = 'Mesa de crafteo avanzada',
			model = 'xm3_prop_xm3_bench_04b',
			spawnRange = 50.0,
			storage = {
				slots = 45,
				maxWeight = 150000
			},
			placement = {
				item = 'bench_advanced',
				returnItem = true
			},
			recipes = {
				{
					name = 'weapon_bat',
					ingredients = {
						scrapmetal = 10,
						WEAPON_HAMMER = 0.05 -- Consume 5% durability per craft
					}, 
					duration = 55000,
					count = 1,
					xp = {
						required = 15,
						reward = 12
					},
					blueprint = 'weapon_bat'
				},
				{
					name = 'weapon_crowbar',
					ingredients = {
						scrapmetal = 9,
						WEAPON_HAMMER = 0.05
					},
					duration = 55000,
					count = 1,
					xp = {
						required = 20,
						reward = 12
					},
					blueprint = 'weapon_crowbar'
				},
				{
					name = 'weapon_wrench',
					ingredients = {
						scrapmetal = 7,
						WEAPON_HAMMER = 0.05
					},
					duration = 5500,
					count = 1,
					xp = {
						required = 25,
						reward = 14
					},
					blueprint = 'weapon_wrench'
				},
				{
					name = 'weapon_hatchet',
					ingredients = {
						scrapmetal = 12,
						WEAPON_HAMMER = 0.05
					},
					duration = 6500,
					count = 1,
					xp = {
						required = 28,
						reward = 16
					},
					blueprint = 'weapon_hatchet'
				},
				{
					name = 'weapon_hammer',
					ingredients = {
						scrapmetal = 8,
						WEAPON_HAMMER = 0.05
					},
					duration = 6000,
					count = 1,
					xp = {
						required = 32,
						reward = 16
					},
					blueprint = 'weapon_hammer'
				},
			}
		},
		-- Mesa de banda: sin objeto, se usa en el punto de cada banda
		gang = {
			label = 'Mesa de la banda',
			storage = {
				slots = 50,
				maxWeight = 200000
			},
			recipes = {
				{
					name = 'lockpick',
					ingredients = {
						scrapmetal = 5,
						WEAPON_HAMMER = 0.05
					},
					duration = 5000,
					count = 2,
					xp = {
						required = 0,
						reward = 5
					},
					blueprint = 'lockpick'
				},
				{
					name = 'armor_plates',
					ingredients = {
						scrapmetal = 6,
						WEAPON_HAMMER = 0.05
					},
					duration = 5000,
					count = 1,
					xp = {
						required = 0,
						reward = 6
					},
				},
				{
					name = 'armour',
					ingredients = {
						scrapmetal = 15,
						WEAPON_HAMMER = 0.05
					},
					duration = 15000,
					count = 1,
					xp = {
						required = 0,
						reward = 15
					},
				},
				{
					name = 'heavyarmour',
					ingredients = {
						scrapmetal = 25,
						WEAPON_HAMMER = 0.05
					},
					duration = 25000,	
					count = 1,
					xp = {
						required = 0,
						reward = 25
					},
				},
				{
					name = 'weapon_pistol',
					ingredients = {
						scrapmetal = 20,
						WEAPON_HAMMER = 0.05
					},
					duration = 7600,
					count = 1,
					xp = {
						required = 36,
						reward = 22
					},
					blueprint = 'weapon_pistol'
				},
				{
					name = 'weapon_smg',
					ingredients = {
						scrapmetal = 28,
						WEAPON_HAMMER = 0.05
					},
					duration = 8800,
					count = 1,
					xp = {
						required = 48,
						reward = 28
					},
					blueprint = 'weapon_smg'
				},
			}
		},
	},
-- Mesas en un punto fijo del mapa: las de banda y, si hace falta, las de un trabajo.
-- gangs = { 'Los Tridentes' } la deja para esas bandas (por su nombre o su id de jj_gangs);
-- gangs = true, para cualquier banda. groups = { 'police' } la deja para ese trabajo.
-- Solo la ven y la usan los suyos, y su almacén lo comparten todos ellos
benches = {
    -- {
    --     name = 'tridentes',
    --     type = 'gang',
    --     label = 'Taller de Los Tridentes',
    --     coords = vec3(-1155.92, -2005.34, 13.18),
    --     gangs = { 'Los Tridentes' },
    -- },
}
}
