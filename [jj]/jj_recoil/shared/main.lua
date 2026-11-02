Config = {}

-- Energética que reduce el retroceso: objeto energetica_recoil de ox_inventory
Config.EnergyDrink = {
	duration = 900, -- segundos que dura
	recoilMultiplier = 0.7, -- 0.7 deja el retroceso al 70 %
	startMessage = 'Notas el pulso más firme',
	endMessage = 'El efecto de la energética se ha pasado',
}

Config.WeaponRecoil = {

	-- Pistolas
	[GetHashKey('WEAPON_HEAVYPISTOL')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_MARKSMANPISTOL')] = { recoil = 2.0 },
	[GetHashKey('WEAPON_REVOLVER')] = { recoil = 5.5 },
	[GetHashKey('WEAPON_HEAVYREVOLVER')] = { recoil = 5.5 },
	[GetHashKey('WEAPON_REVOLVER_MK2')] = { recoil = 5.5 },
	[GetHashKey('WEAPON_DOUBLEACTION')] = { recoil = 4.8 },
	[GetHashKey('WEAPON_NAVYREVOLVER')] = { recoil = 5.5 },
	[GetHashKey('WEAPON_GADGETPISTOL')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_PISTOL')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_COMBATPISTOL')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_PISTOL_MK2')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_PISTOL50')] = { recoil = 6.5 },
	[GetHashKey('WEAPON_CERAMICPISTOL')] = { recoil = 0.3 },
	[GetHashKey('WEAPON_VINTAGEPISTOL')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_SNSPISTOL_MK2')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_SNSPISTOL')] = { recoil = 3.8 },
	[GetHashKey('WEAPON_R587')] = { recoil = 1.8 },
	-- Subfusiles
	[GetHashKey('WEAPON_ASSAULTSMG')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_TECPISTOL')] = { recoil = 3.0 },
	[GetHashKey('WEAPON_MINISMG')] = { recoil = 2.2 },
	[GetHashKey('WEAPON_MACHINEPISTOL')] = { recoil = 2.8 },
	[GetHashKey('WEAPON_MICROSMG')] = { recoil = 4.2 },
	[GetHashKey('WEAPON_APPISTOL')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_GLOCK')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_COMBATPDW')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_SMG')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_SMG_MK2')] = { recoil = 3.2 },
	-- Escopetas
	[GetHashKey('WEAPON_PUMPSHOTGUN_MK2')] = { recoil = 10.2 },
	[GetHashKey('WEAPON_ASSAULTSHOTGUN')] = { recoil = 7.5 },
	[GetHashKey('WEAPON_BULLPUPSHOTGUN')] = { recoil = 8.5 },
	[GetHashKey('WEAPON_HEAVYSHOTGUN')] = { recoil = 9.5 },
	[GetHashKey('WEAPON_DBSHOTGUN')] = { recoil = 11.0 },
	[GetHashKey('WEAPON_AUTOSHOTGUN')] = { recoil = 7.0 },
	[GetHashKey('WEAPON_COMBATSHOTGUN')] = { recoil = 9.0 },
	[GetHashKey('WEAPON_MUSKET')] = { recoil = 12.0 },
	[GetHashKey('WEAPON_PUMPSHOTGUN')] = { recoil = 10.2 },
	[GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = { recoil = 10.2 },
	[GetHashKey('WEAPON_SAWNOFFSHOTGUN2')] = { recoil = 10.2 },
	-- Fusiles de asalto
	[GetHashKey('WEAPON_ASSAULTRIFLE')] = { recoil = 2.2 },
	[GetHashKey('WEAPON_AK47')] = { recoil = 2.2 },
	[GetHashKey('WEAPON_ASSAULTRIFLE_MK2')] = { recoil = 2.2 },
	[GetHashKey('WEAPON_CARBINERIFLE_MK2')] = { recoil = 1.2 },
	[GetHashKey('WEAPON_ADVANCEDRIFLE')] = { recoil = 1.6 },
	[GetHashKey('WEAPON_SPECIALCARBINE_MK2')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_BULLPUPRIFLE')] = { recoil = 2.0 },
	[GetHashKey('WEAPON_BULLPUPRIFLE_MK2')] = { recoil = 2.0 },
	[GetHashKey('WEAPON_MILITARYRIFLE')] = { recoil = 2.2 },
	[GetHashKey('WEAPON_HEAVYRIFLE')] = { recoil = 2.4 },
	[GetHashKey('WEAPON_BATTLERIFLE')] = { recoil = 2.6 },
	[GetHashKey('WEAPON_SPECIALCARBINE')] = { recoil = 3.2 },
	[GetHashKey('WEAPON_CARBINERIFLE')] = { recoil = 1.2 },
	[GetHashKey('WEAPON_TACTICALRIFLE')] = { recoil = 1.8 },
	[GetHashKey('WEAPON_COMPACTRIFLE')] = { recoil = 1.2 },
	-- Ametralladoras
	[GetHashKey('WEAPON_MG')] = { recoil = 2.8 },
	[GetHashKey('WEAPON_COMBATMG')] = { recoil = 2.6 },
	[GetHashKey('WEAPON_COMBATMG_MK2')] = { recoil = 2.6 },
	[GetHashKey('WEAPON_GUSENBERG')] = { recoil = 3.0 },
	-- Francotiradores
	[GetHashKey('WEAPON_SNIPERRIFLE')] = { recoil = 15.0 },
	[GetHashKey('WEAPON_HEAVYSNIPER')] = { recoil = 18.0 },
	[GetHashKey('WEAPON_HEAVYSNIPER_MK2')] = { recoil = 18.0 },
	[GetHashKey('WEAPON_MARKSMANRIFLE')] = { recoil = 6.0 },
	[GetHashKey('WEAPON_MARKSMANRIFLE_MK2')] = { recoil = 6.0 },
	-- Armas pesadas
	[GetHashKey('WEAPON_RPG')] = { recoil = 20.0 },
	[GetHashKey('WEAPON_GRENADELAUNCHER')] = { recoil = 10.0 },
	[GetHashKey('WEAPON_GRENADELAUNCHER_SMOKE')] = { recoil = 8.0 },
	[GetHashKey('WEAPON_MINIGUN')] = { recoil = 1.0 },
	[GetHashKey('WEAPON_FIREWORK')] = { recoil = 4.0 },
	[GetHashKey('WEAPON_RAILGUN')] = { recoil = 12.0 },
	[GetHashKey('WEAPON_HOMINGLAUNCHER')] = { recoil = 12.0 },
	[GetHashKey('WEAPON_COMPACTLAUNCHER')] = { recoil = 3.0 },

}
