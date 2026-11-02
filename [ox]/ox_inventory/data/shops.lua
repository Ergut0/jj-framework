return {
	General = {
		name = 'Shop',
		hideAll = false, -- Hides all categories from the shop
		paymentMethods = {
			cash = true,
			bank = true,
			dirty = false,
			dirtyItem = 'black_money',
		},
		inventory = {
			{ name = 'burger', price = 10, metadata = { category = 'Food' } },
			{ name = 'water', price = 10, metadata = { category = 'Drinks' } },
			{ name = 'sprunk', price = 15, metadata = { category = 'Drinks' } },
			{ name = 'tosti', price = 5, metadata = { category = 'Food' } },
			
		}, locations = {
			vec3(25.7, -1347.3, 29.49),
			vec3(-3038.71, 585.9, 7.9),
			vec3(-3241.47, 1001.14, 12.83),
			vec3(1728.66, 6414.16, 35.03),
			vec3(1697.99, 4924.4, 42.06),
			vec3(1961.48, 3739.96, 32.34),
			vec3(547.79, 2671.79, 42.15),
			vec3(2679.25, 3280.12, 55.24),
			vec3(2557.94, 382.05, 108.62),
			vec3(373.55, 325.56, 103.56),
		}, targets = {
			{ ped = 'mp_m_shopkeep_01', loc = vec3(24.47, -1346.62, 28.5), heading = 271.66, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(-3039.54, 584.38, 6.91), heading = 17.27, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(-3242.97, 1000.01, 11.83), heading = 357.57, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(1728.07, 6415.63, 34.04), heading = 242.95, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(1697.87, 4922.96, 41.06), heading = 324.71, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(1959.82, 3740.48, 31.34), heading = 301.57, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(549.13, 2670.85, 41.16), heading = 99.39, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(2677.47, 3279.76, 54.24), heading = 335.08, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(2556.66, 380.84, 107.62), heading = 356.67, distance = 2.5 },
			{ ped = 'mp_m_shopkeep_01', loc = vec3(372.66, 326.98, 102.57), heading = 253.73, distance = 2.5 },
		}
	},

    farmacia = {
		name = 'Farmacia',
		blip = {
			id = 51, colour = 77, scale = 0.8
		}, inventory = {
			{ name = 'bandage', price = 15 },
			{ name = 'analgesicos', price = 15 }
		}, locations = {
			
			vec3(104.71, 1.40, 66.77),
		}, targets = {
			{ped = 's_m_m_doctor_01', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(104.71, 1.40, 66.77), heading = 247.40,},
		}
	},

	informatica = {
		name = 'Tienda Informatica',
		blip = {
			id = 606, colour = 77, scale = 0.8
		}, inventory = {
			{ name = 'phone', price = 100 },
			{ name = 'tablet_locales', price = 300 },
			{ name = 'laptop', price = 150 },
			{ name = 'radio', price = 600 }
		}, locations = {
			vec3(-1532.57, -400.79, 34.63),
		}, targets = {
			{ped = 's_m_m_highsec_01', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(-1530.66, -405.63, 34.63), heading = 267.44,},
			
		}
	},

	juegosdemesa = {
		name = 'Juegos de Mesa',
	    inventory = {
			{ name = 'stg_checkers', price = 250  },
			{ name = 'stg_chess', price = 250  }
			
		}, locations = {
			vec3(1177.27, 2713.71, 38.17),
		}, targets = {
	        
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1177.27, 2713.71, 38.17), heading = 182.28},
		}
	},

	tiendaderopa = {
		name = 'Tienda de Ropa',
	    inventory = {
			
			{ name = 'clothing_bag', price = 3000 },
			{ name = 'skateboard', price = 500 },
			
		}, locations = {
			vec3(1936.63, 3821.81, 32.47),
		}, targets = {
	        
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(75.48, -1394.71, 28.38), heading = 274.24},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(425.40, -804.12, 28.49), heading = 94.10},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-1449.79, -239.01, 48.81), heading = 42.01},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-164.53, -301.88, 38.73), heading = 252.85},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-823.85, -1074.57, 10.33), heading = 211.35},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-1193.27, -766.55, 16.32), heading = 216.08},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(612.85, 2763.78, 41.09), heading = 275.25},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1194.97, 2710.12, 37.22), heading = 174.97},
            {ped = 'a_m_m_prolhost_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-708.36, -152.69, 36.42), heading = 125.94},
            {ped = 's_f_m_sweatshop_01', scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(126.66, -225.02, 53.56), heading = 73.81}
		}
	},

	deporteextremo = {
		name = 'Tienda de Paracidas',
		blip = {
			id = 94, colour = 77, scale = 0.8
		}, inventory = {
			{ name = 'parachute', price = 100 },
		}, locations = {
			vec3(443.11, 5569.49, 780.19),
		}, targets = {
			{ped = 'a_m_y_dhill_01', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(443.11, 5569.49, 780.19), heading = 300,},
		}

	},

	ammunation = {
		name = 'Ammunation',
		blip = {
			id = 110, colour = 69, scale = 0.6
		}, inventory = {
			
			{ name = 'metaldetector', price = 350, metadata = { category = 'Utensilios' } },
			{ name = 'backpack_small', price = 2000, metadata = { category = 'Utensilios' } },
			{ name = 'advancedlockpick', price = 150, metadata = { category = 'Ferreteria' } },
			{ name = 'lockpick', price = 100, metadata = { category = 'Ferreteria' } },
			{ name = 'ropehook', price = 250, metadata = { category = 'Ferreteria' } },
			{ name = 'WEAPON_BAT', price = 500, metadata = { category = 'Melee Weapons' } },
			{ name = 'weapon_crowbar', price = 500, metadata = { category = 'Melee Weapons' } },
			
		}, locations = {
			
		}, targets = {
		
			{ ped = 's_m_y_ammucity_01', loc = vec3(-661.96, -933.53, 20.83), heading = 177.05, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(-1304.19, -395.12, 35.7), heading = 75.03, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(253.63, -51.02, 68.94), heading = 65.78, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(841.92, -1035.32, 27.19), heading = 1.56, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(809.68, -2159.13, 28.62), heading = 1.43, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(23.59, -1105.55, 28.8), heading = 162.91, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(-3173.31, 1088.85, 19.84), heading = 244.18, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(1692.67, 3761.38, 33.71), heading = 227.65, distance = 2.5 },
			{ ped = 's_m_y_ammucity_01', loc = vec3(-331.23, 6085.37, 30.45), heading = 228.02, distance = 2.5 },
		}
	},


---	BOOSTING

    boosting = {
		name = 'Boosting',
	    groups = {
			['admin'] = 0,
			['mafia'] = 0,
			
		},
		inventory = {
			
			{ name = 'transponder', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'hacking_device', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'boosting_spray', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'trojan_usb', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'veh_plates', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'nos_remover', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'nos_blue', price = 0, metadata = { category = 'Utensilios' } },
			{ name = 'nos_turquoise', price = 0, metadata = { category = 'Utensilios' } },
		
			
		}, locations = {
			
		}, targets = {
		
			{ ped = 's_m_y_dealer_01', loc = vec3(-2248.05, 320.45, 155.52), heading = 65, distance = 2.5 },
            
		}
	},

--- MAFIA
	--- 
	--- 
	--- 
	--- 
	ArmasMafia = {
	name = 'Armas Mafia',
	groups = {
			['mafia'] = 0,
			
		},
	inventory = {
 		{ name = 'armor_plates', price = 0, metadata = { category = 'CHALECOS' } },
		{ name = 'heavyarmour', price = 0, metadata = { category = 'CHALECOS' } },
		-- Armas blancas
		{ name = 'WEAPON_MOLOTOV', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_BAT', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_BATTLEAXE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_BOTTLE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_CROWBAR', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_DAGGER', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_HAMMER', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_HATCHET', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_KNIFE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_KNUCKLE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_MACHETE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_POOLCUE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_STONE_HATCHET', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_SWITCHBLADE', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
		{ name = 'WEAPON_WRENCH', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_MACHETECB', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_FURYNAILBAT', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_WBAT', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_KATANA', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_CARNICERO', price = 0, metadata = { category = 'ARMAS BLANCAS' } },
--		{ name = 'WEAPON_SLEDGEHUMMER', price = 0, metadata = { category = 'ARMAS BLANCAS' } },

		-- Pistolas
		{ name = 'WEAPON_APPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_CERAMICPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_COMBATPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_DOUBLEACTION', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_GADGETPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_HEAVYPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_MACHINEPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_MARKSMANPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_NAVYREVOLVER', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_PISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_PISTOL50', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_PISTOL_MK2', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_PISTOLXM3', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_REVOLVER', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_REVOLVER_MK2', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_SNSPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_SNSPISTOL_MK2', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_TECPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_VINTAGEPISTOL', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_R587', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
--		{ name = 'WEAPON_M1911', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },
		{ name = 'WEAPON_GLOCK', price = 0, metadata = { registered = false, category = 'PISTOLAS' } },

		-- Subfusiles
--		{ name = 'WEAPON_ASSAULTSMG', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
--		{ name = 'WEAPON_COMBATPDW', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
		{ name = 'WEAPON_GUSENBERG', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
		{ name = 'WEAPON_MICROSMG', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
--		{ name = 'WEAPON_MINISMG', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
		{ name = 'WEAPON_SMG', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
--		{ name = 'WEAPON_SMG_MK2', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },
		{ name = 'WEAPON_PM5', price = 0, metadata = { registered = false, category = 'SUBFUSILES' } },

		-- Escopetas
--		{ name = 'WEAPON_ASSAULTSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
--		{ name = 'WEAPON_AUTOSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
--		{ name = 'WEAPON_BULLPUPSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
--		{ name = 'WEAPON_COMBATSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
        { name = 'WEAPON_DBSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
--		{ name = 'WEAPON_HEAVYSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
		{ name = 'WEAPON_PUMPSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
--		{ name = 'WEAPON_PUMPSHOTGUN_MK2', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },
		{ name = 'WEAPON_SAWNOFFSHOTGUN', price = 0, metadata = { registered = false, category = 'ESCOPETAS' } },

		-- Fusiles
--		{ name = 'WEAPON_ADVANCEDRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
	    { name = 'WEAPON_ASSAULTRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_ASSAULTRIFLE_MK2', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_BATTLERIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_BULLPUPRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_BULLPUPRIFLE_MK2', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_CARBINERIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_CARBINERIFLE_MK2', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_COMPACTRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_HEAVYRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
		{ name = 'WEAPON_MILITARYRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_SPECIALCARBINE', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_SPECIALCARBINE_MK2', price = 0, metadata = { registered = false, category = 'FUSILES' } },
--		{ name = 'WEAPON_TACTICALRIFLE', price = 0, metadata = { registered = false, category = 'FUSILES' } },

		-- Francotiradores
--		{ name = 'WEAPON_HEAVYSNIPER', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
--		{ name = 'WEAPON_HEAVYSNIPER_MK2', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
--		{ name = 'WEAPON_MARKSMANRIFLE', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
--		{ name = 'WEAPON_MARKSMANRIFLE_MK2', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
--		{ name = 'WEAPON_PRECISIONRIFLE', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
		{ name = 'WEAPON_SNIPERRIFLE', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },
		{ name = 'WEAPON_MUSKET', price = 0, metadata = { registered = false, category = 'FRANCOTIRADORES' } },

		-- Municion
		{ name = 'ammo-22', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-38', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-44', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-45', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-50', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-9', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-musket', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-rifle', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-rifle2', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-shotgun', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-sniper', price = 0, metadata = { category = 'MUNICION' } },
		{ name = 'ammo-heavysniper', price = 0, metadata = { category = 'MUNICION' } },

		-- Accesorios
		{ name = 'at_barrel', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_clip_extended_pistol', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_flashlight', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_grip', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_bell', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_fat', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_flat', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_heavy', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_precision', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_slanted', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_split', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_squared', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_muzzle_tactical', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_advanced', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_holo', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_large', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_medium', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_nv', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_small', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_scope_thermal', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_suppressor_light', price = 0, metadata = { category = 'ACCESORIOS' } },
		{ name = 'at_suppressor_heavy', price = 0, metadata = { category = 'ACCESORIOS' } }
	},
	locations = {
		vec3(-2821.44, 1427.90, 86.97), --321.85, 298.23, 89.03 
	},
	targets = {
		{ped = 's_m_y_dealer_01', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(-319.40, -1306.41, 30.26), heading = 4.13,}, -- -319.40, -1306.41, 31.26, 4.13
		
	}
  },

MafiaUtensilios = {
	name = 'Mafia Utensilios',
	groups = {
			['mafia'] = 0,

		},
	inventory = {
		{ name = 'drill', price = 0, metadata = { category = 'ROBO' } },
		{ name = 'cortadordecristal', price = 0, metadata = { category = 'ROBO' } },
		{ name = 'screwdriverset', price = 0, metadata = { category = 'ROBO' } },
		{ name = 'hackingdevice', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'inhibidormovil', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'trojan_usb', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'electronickit', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'hacking_device', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'usbhackeo', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'transponder', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'laptop', price = 0, metadata = { category = 'HACKEO' } },
		{ name = 'lanzatermica', price = 0, metadata = { category = 'HERRAMIENTAS' } },
		{ name = 'sierragrande', price = 0, metadata = { category = 'HERRAMIENTAS' } },
		{ name = 'thermite', price = 0, metadata = { category = 'HERRAMIENTAS' } },
		{ name = 'sopleteportatil', price = 0, metadata = { category = 'HERRAMIENTAS' } },
		{ name = 'radial', price = 0, metadata = { category = 'HERRAMIENTAS' } },
		{ name = 'tarjetadeseguridad', price = 0, metadata = { category = 'ACCESOS' } },
		{ name = 'tarjetadeseguridad2', price = 0, metadata = { category = 'ACCESOS' } },
		{ name = 'tarjetadeseguridad3', price = 0, metadata = { category = 'ACCESOS' } },
		{ name = 'idfalso', price = 0, metadata = { category = 'DOCUMENTACION' } },
		{ name = 'pasaportefalso', price = 0, metadata = { category = 'DOCUMENTACION' } },
		{ name = 'spray', price = 0, metadata = { category = 'VARIOS' } },
		{ name = 'spray_remover', price = 0, metadata = { category = 'VARIOS' } },
		{ name = 'backpack_large', price = 0, metadata = { category = 'VARIOS' } },
		{ name = 'radio', price = 0, metadata = { category = 'VARIOS' } }
	},
	locations = {
		vec3(-1803.56, 486.23, 108.49)
	},
	targets = {
		{
			loc = vec3(-1803.56, 486.23, 107.49),
			heading =  161.37,
			ped = 'a_m_y_soucent_03',
			scenario = 'WORLD_HUMAN_GUARD_STAND'
		},
		{ped = 's_m_o_busker_01', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(-307.18, -1307.41, 30.26), heading = 6.14,}, -- -307.18, -1307.41, 31.26, 6.14 OBJETOS ROBOS

		
	}
},

MafiaDrogas = {
	name = 'Mafia Drogas',
	groups = {
			['mafia'] = 0,
		},
	inventory = {
		-- Cultivo marihuana
		{ name = 'weed_seed', price = 0, metadata = { category = 'BASICO MARIHUANA' } },
		{ name = 'plant_pot', price = 0, metadata = { category = 'BASICO MARIHUANA' } },
		{ name = 'fertilizer', price = 0, metadata = { category = 'CULTIVO MARIHUANA' } },
		{ name = 'default_lamp', price = 0, metadata = { category = 'LABORATORIO MARIHUANA' } },
		{ name = 'default_fan', price = 0, metadata = { category = 'LABORATORIO MARIHUANA' } },
		{ name = 'default_soil', price = 0, metadata = { category = 'BASICO MARIHUANA' } },
		{ name = 'watering_can', price = 0, metadata = { category = 'BASICO MARIHUANA' } },
		{ name = 'plant_trimmers', price = 0, metadata = { category = 'BASICO MARIHUANA' } },

		-- Marihuana procesado
		{ name = 'weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },
		{ name = 'high_quality_weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },
		{ name = 'dried_weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },
		{ name = 'dried_high_quality_weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },
		{ name = 'gingeritis_weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },
		{ name = 'energizing_dried_weed', price = 0, metadata = { category = 'MARIHUANA PROCESADO' } },

		-- Marihuana empaquetado
		{ name = 'baggy', price = 0, metadata = { category = 'EMPAQUETADO' } },
		{ name = 'drying_rack', price = 0, metadata = { category = 'EMPAQUETADO' } },
		{ name = 'default_brick_press', price = 0, metadata = { category = 'EMPAQUETADO' } },
		{ name = 'packaging_station', price = 0, metadata = { category = 'EMPAQUETADO' } },

		-- Marihuana final
		{ name = 'packaged_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'packaged_high_quality_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'packaged_dried_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'packaged_dried_high_quality_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'packaged_gingeritis_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'packaged_energizing_dried_weed', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'weed_brick', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },
		{ name = 'high_quality_weed_brick', price = 0, metadata = { category = 'PRODUCTO FINAL MARIHUANA' } },

		-- Cultivo coca
		{ name = 'coke_seed', price = 0, metadata = { category = 'CULTIVO COCAINA' } },

		-- Cocaina procesado
		{ name = 'coke_leaf', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'high_quality_coke_leaf', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'dried_coke_leaf', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'dried_high_quality_coke_leaf', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'high_quality_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'dried_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'dried_high_quality_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'cooked_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'cooked_high_quality_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'cooked_dried_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },
		{ name = 'cooked_dried_high_quality_coke', price = 0, metadata = { category = 'COCAINA PROCESADO' } },

		-- Cocaina final
		{ name = 'packaged_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_high_quality_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_dried_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_dried_high_quality_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_cooked_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_cooked_high_quality_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_cooked_dried_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'packaged_cooked_dried_high_quality_coke', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'coke_brick', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'high_quality_coke_brick', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'cooked_coke_brick', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },
		{ name = 'cooked_high_quality_coke_brick', price = 0, metadata = { category = 'PRODUCTO FINAL COCAINA' } },

		-- Meta laboratorio
		{ name = 'drug_mixer', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'drug_cauldron', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'drug_oven', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'chemistry_station', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'acetone', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'ecola', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'pills', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'phosphorus', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'gasoline', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'banana', price = 0, metadata = { category = 'LABORATORIO META' } },
		{ name = 'hammer', price = 0, metadata = { category = 'LABORATORIO META' } },

		-- Meta procesado
		{ name = 'liquid_meth', price = 0, metadata = { category = 'META PROCESADO' } },
		{ name = 'default_meth', price = 0, metadata = { category = 'META PROCESADO' } },

		-- Meta final
		{ name = 'packaged_default_meth', price = 0, metadata = { category = 'PRODUCTO FINAL META' } }
	},
	locations = {
		vec3(-1793.83, 464.31, 108.49)
	},
	targets = {
		{
			loc = vec3(-1793.83, 464.31, 107.49),
			heading =  269.35,
			ped = 'a_m_y_soucent_02',
			scenario = 'WORLD_HUMAN_GUARD_STAND'
		},
		{ped = 'ig_chef2', scenario = 'WORLD_HUMAN_AA_COFFEE',loc = vec3(-319.18, -1317.57, 30.26), heading = 44.20,}, -- -319.18, -1317.57, 31.26, 44.20  DROGA
	
	}
},

	VendingMachineDrinks = {
	name = 'Maquina Expendedora',
	inventory = {
	 		{ name = 'water', price = 20, metadata = { category = 'Drinks' } },
	 		{ name = 'sprunk', price = 20, metadata = { category = 'Drinks' } },
			{ name = 'flamingo_classic', price = 15, metadata = { category = 'Food' } },
			{ name = 'cola', price = 15, metadata = { category = 'Drinks' } },
	 	},
	 	model = {
	 		'prop_vend_soda_02', 'prop_vend_fridge01', 'prop_vend_water_01', 'prop_vend_soda_01', 'prop_vend_snak_01_tu', 'prop_vend_snak_01', 'm23_2_prop_m32_vend_drink_01a'
	 	}
	 },
	VendingCoffeDrinks = {
	name = 'Maquina de Cafes',
	inventory = {
	 		{ name = 'vasodecafe', price = 15, metadata = { category = 'Drinks' } },

	 	},
	 	model = {
	 		'prop_vend_coffe_01'
	 	}
	 },
	VendingHotdogEat = {
	name = 'Puesto de Comida',
	inventory = {
	 		{ name = 'hotdogbarato', price = 15, metadata = { category = 'Food' } },
			{ name = 'flamingo_classic', price = 15, metadata = { category = 'Food' } },
			{ name = 'cola', price = 15, metadata = { category = 'Drinks' } },
	 	},
	 	model = {
	 		'prop_hotdogstand_01', 'prop_burgerstand_01'
	 	}
	 }

	 
}
