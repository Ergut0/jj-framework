local BlacklistedModels = {
    [`BLIMP`] = true,

    -- Props
    [`prop_traffic_01a`] = true,
    [`prop_traffic_01b`] = true,
    [`prop_traffic_01d`] = true,
    [`prop_traffic_02a`] = true,
    [`prop_traffic_02b`] = true,
    [`prop_traffic_03a`] = true,
    [`prop_traffic_03b`] = true,
    [`prop_traffic_lightset_01`] = true,
    [`prop_streetlight_01`] = true,
    [`prop_streetlight_01b`] = true,
    [`prop_streetlight_02`] = true,
    [`prop_streetlight_03`] = true,
    [`prop_streetlight_03b`] = true,
    [`prop_streetlight_03c`] = true,
    [`prop_streetlight_03d`] = true,
    [`prop_streetlight_04`] = true,
    [`prop_streetlight_05`] = true,
    [`prop_streetlight_05_b`] = true,
    [`prop_streetlight_14a`] = true,
}

local inVeh = false
lib.onCache('vehicle', function(value)
    inVeh = value
    CreateThread(function()
        while inVeh do
            local nearObjects = lib.getNearbyObjects(GetEntityCoords(cache.ped), 40.0)
            for k, v in pairs(nearObjects) do
                local EntityModel = GetEntityModel(v.object)
                if BlacklistedModels[EntityModel] then
                    if HasObjectBeenBroken(v.object) then
                        if not IsEntityAMissionEntity(v.object) then
                            SetEntityAsMissionEntity(v.object, true, true)
                        end
                        DeleteEntity(v.object)
                    end
                end
            end
            Wait(500)
        end
    end)
end)
