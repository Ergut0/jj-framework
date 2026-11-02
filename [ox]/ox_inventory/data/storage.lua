return {
	packing = {
		enabled = true,
		confirmWithItems = true,
	},
	types = {
		small = {
			label = 'Small Storage Crate',
			model = 'prop_box_wood05a',
			spawnRange = 35.0,
			storage = {
				slots = 10,
				maxWeight = 50000,
			},
			placement = {
				item = 'storage_small',
				returnItem = true,
			},
		},
		medium = {
			label = 'Medium Storage Crate',
			model = 'sf_prop_v_43_safe_s_bk_01a',
			spawnRange = 50.0,
			storage = {
				slots = 35,
				maxWeight = 100000,
			},
			placement = {
				item = 'storage_medium',
				returnItem = true,
			},
		},
		large = {
			label = 'Large Storage Safe',
			model = 'xm3_prop_xm3_safe_01a',
			spawnRange = 50.0,
			storage = {
				slots = 50,
				maxWeight = 200000,
			},
			placement = {
				item = 'storage_large',
				returnItem = true,
			},
		},
	},
	units = {
		
		-- {
		-- 	name = 'general_store_storage',
		-- 	type = 'small',
		-- 	label = 'General Store Storage',
		-- 	groups = { shopkeeper = 0 },
		-- 	points = {
		-- 		vec3(24.47, -1347.37, 29.5),
		-- 	},
		-- 	blip = { id = 473, colour = 2, scale = 0.7 },
		-- },

		-- {
		-- 	name = 'pillbox_medical_storage',
		-- 	type = 'medium',
		-- 	label = 'Medical Supplies',
		-- 	groups = { ambulance = 0 },
		-- 	points = {
		-- 		vec3(12.14, -595.22, 30.63),
		-- 	},
		-- 	blip = { id = 473, colour = 3, scale = 0.7 },
		-- },

		-- {
		-- 	name = 'police_station_safe',
		-- 	type = 'large',
		-- 	label = 'Evidence Safe',
		-- 	groups = { police = 0 },
		-- 	points = {
		-- 		vec3(457.26, -987.11, 30.69),
		-- 	},
		-- 	blip = { id = 473, colour = 29, scale = 0.7 },
		-- },
		
	},
}
