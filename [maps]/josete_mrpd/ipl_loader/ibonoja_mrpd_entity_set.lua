local interiors = {
    {
        ipl = 'interior_MRPD_milo_',
        coords = { x = 457.204, y = -996.1261, z = 36.0902 },
        entitySets = {
            { name = 'toilet_cells', enable = true},
        }
    },
}

CreateThread(function()
    UpdateIPL()
end)

function UpdateIPL()
    for _, interior in ipairs(interiors) do
        if not interior.ipl or not interior.coords or not interior.entitySets then
            print('^5[IBONOJA]^7 ^1Error while loading interior.^7')
            return
        end
        RequestIpl(interior.ipl)
        local interiorID = GetInteriorAtCoords(interior.coords.x, interior.coords.y, interior.coords.z)
        if IsValidInterior(interiorID) then
            for __, entitySet in ipairs(interior.entitySets) do
                if entitySet.enable then
                    EnableInteriorProp(interiorID, entitySet.name)
                    if entitySet.color then
                        SetInteriorPropColor(interiorID, entitySet.name, entitySet.color)
                    end
                else
                    DisableInteriorProp(interiorID, entitySet.name)
                end
            end
            RefreshInterior(interiorID)
        end
    end
    print("^5[IBONOJA]^7 Interiors datas loaded.")
end


RegisterNetEvent('ibonoja:setEntitySets', function(data)
    if not data then return end
    for k, v in pairs(data) do
        for _, v2 in ipairs(interiors) do
            for __, v3 in ipairs(v2.entitySets) do
                if v3.name == v.name then
                    v3.enable = v.enable
                    if v.color then
                        v3.color = v.color
                    end
                end
            end
        end
    end
    UpdateIPL()
end)