AddEventHandler('jj:client:playerSpawned', function()
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 228, false) -- CanLosePropsOnDamage
    SetPedConfigFlag(ped, 258, false) -- CanLoseHelmetOnDamage
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 228, false) -- CanLosePropsOnDamage
    SetPedConfigFlag(ped, 258, false) -- CanLoseHelmetOnDamage
end)

CreateThread(function()
    while true do
        Wait(100)
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        SetPlayerHealthRechargeLimit(PlayerId(), 0.0)
    end
end)

lib.onCache('ped', function(ped)
    SetPedConfigFlag(ped, 228, false) -- CanLosePropsOnDamage
    SetPedConfigFlag(ped, 258, false) -- CanLoseHelmetOnDamage
end)