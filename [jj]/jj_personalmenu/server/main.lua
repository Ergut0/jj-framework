-- El cliente envía sus armas visibles y se replican por state bag para que el resto cree los props
RegisterNetEvent('holster:server:syncWeapons', function(weaponsData)
    local src = source
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or type(weaponsData) ~= 'table' then return end

    -- Solo armas conocidas y datos con el formato esperado
    local clean = {}
    for weapon, data in pairs(weaponsData) do
        if type(weapon) == 'string' and Config.realWeapons[weapon]
            and type(data) == 'table' and type(data.category) == 'string'
            and Config.weaponCategoryOffsets[data.category] then
            local components = {}
            if type(data.components) == 'table' then
                for _, component in pairs(data.components) do
                    if type(component) == 'string' or type(component) == 'number' then
                        components[#components + 1] = component
                    end
                end
            end
            clean[weapon] = {
                category = data.category,
                components = components,
                tint = type(data.tint) == 'number' and data.tint or nil,
            }
        end
    end

    Entity(ped).state:set('visibleWeapons', clean, true)
end)

RegisterCommand('freecamadmin', function(src)
    if src ~= 0 and JJ.IsAdmin(src) then
        TriggerClientEvent('jj_personalmenu:ToggleAdminFreecam', src)
    end
end, false)
