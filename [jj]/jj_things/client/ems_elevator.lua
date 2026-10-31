local points = {
    {
        label = 'Planta -1',
        coords = vec(352.16, -575.06, 28.78, 157.09),
    },

    {
        label = 'Planta 0',
        coords = vec(344.91, -573.90, 43.26, 157.09),
    },
    {
        label = 'Azotea',
        coords = vec(328.07, -575.02, 74.16, 160.94),
    },
}

local showing = false

CreateThread(function()
    local elements = {}

    for k, v in pairs(points) do
        elements[#elements + 1] = {
            icon = 'fas fa-arrow-right',
            label = v.label,
            value = v.coords
        }
    end

    lib.registerMenu({
        id = 'ems_elevator_menu',
        title = 'Ascensor',
        position = 'bottom-right',
        options = elements,
    }, function(selected)
        local selectedCoords = elements[selected].value
        local coords = GetEntityCoords(cache.ped)
        lib.hideMenu('ems_elevator_menu')
        DoScreenFadeOut(500)
        Wait(500)
        SetEntityCoords(cache.ped, selectedCoords.x, selectedCoords.y, selectedCoords.z - 1)
        SetEntityHeading(cache.ped, selectedCoords.w)
        Wait(500)
        DoScreenFadeIn(500)
    end)
end)

CreateThread(function()
    while true do
        local wait = 1000

        local coords = GetEntityCoords(cache.ped)
        for k, v in pairs(points) do
            local dist = #(coords - v.coords.xyz)

            if dist < 10 then
                wait = 0
                DrawMarker(2, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.1, 255,
                    255, 255, 100, false, false, false, true, false, false, false)

                if IsControlJustReleased(0, 38) and dist < 1.5 then
                    lib.showMenu('ems_elevator_menu')
                end
            end
        end

        Wait(wait)
    end
end)
