-- Aplica el retroceso de cada arma. Con la energética activa se reduce
local function applyRecoil(reduced)
    local multiplier = reduced and Config.EnergyDrink.recoilMultiplier or 1.0
    for weapon, data in pairs(Config.WeaponRecoil) do
        SetWeaponRecoilShakeAmplitude(weapon, data.recoil * multiplier)
    end
end

-- Al entrar se recupera el efecto que quedara activo
local function restoreEffect()
    applyRecoil(lib.callback.await('jj_recoil:callback:getRecoilDrink', false) == true)
end

AddStateBagChangeHandler('recoilDrink', ('player:%s'):format(cache.serverId), function(_, _, value)
    applyRecoil(value == true)
end)

CreateThread(function()
    applyRecoil(false)
    if JJ.IsSpawned() then restoreEffect() end
end)

AddEventHandler('jj:client:playerSpawned', function()
    CreateThread(restoreEffect)
end)
