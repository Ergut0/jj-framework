local function setWeaponDamages()
    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 0.29)
    SetWeaponDamageModifier(GetHashKey("WEAPON_GOLFCLUB"), 0.35)
    SetWeaponDamageModifier(GetHashKey("WEAPON_BAT"), 0.35)
    SetWeaponDamageModifier(GetHashKey("WEAPON_CROWBAR"), 0.35)
    SetWeaponDamageModifier(GetHashKey("WEAPON_POOLCUE"), 0.35)
    SetWeaponDamageModifier(GetHashKey("WEAPON_NIGHTSTICK"), 0.1) 
    SetWeaponDamageModifier(GetHashKey("WEAPON_SNOWBALL"), 0.0)
    SetWeaponDamageModifier(GetHashKey("WEAPON_FLASHLIGHT"), 0.1)
    SetWeaponDamageModifier(GetHashKey("WEAPON_FIREEXTINGUISHER"), 0.0)
    SetWeaponDamageModifier(GetHashKey("WEAPON_SMOKEGRENADE"), 0.0)
    SetWeaponDamageModifier(GetHashKey("WEAPON_EXTENSIBLE"), 0.35)
    SetWeaponDamageModifier(GetHashKey("WEAPON_HATCHET"), 0.33)
end


CreateThread(function()
    while true do
        setWeaponDamages()
        Wait(5000)
    end
end)
