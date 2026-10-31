local points = {

    {
        label = 'Azotea',
        coords = vec(334.56, -598.17, 92.99, 66.93),
    },

    {
        label = 'Planta 5',
        coords = vec(338.56, -602.52, 49.49, 156.61),
    },

    {
        label = 'Planta 2',
        coords = vec(338.56, -602.52, 69.17, 156.61),
    },

    {
        label = 'Planta 0',
        coords = vec(338.57, -602.71, 43.27, 162.00)
    },

    {
        label = 'Planta -1',
        coords = vec(338.57, -602.71, 28.80, 162.00)
    }
}

-- local showing = false

-- CreateThread(function()
--     local elements = {}

--     for k, v in pairs(points) do
--         elements[#elements + 1] = {
--             icon = 'fas fa-arrow-right',
--             label = v.label,
--             value = v.coords
--         }
--     end

--     lib.registerMenu({
--         id = 'ambulance_elevator_menu2',
--         title = 'Ascensor',
--         position = 'bottom-right',
--         options = elements,
--     }, function(selected)
--         local selectedCoords = elements[selected].value
--         local coords = GetEntityCoords(cache.ped)
--         lib.hideMenu('ambulance_elevator_menu2')
--         DoScreenFadeOut(500)
--         Wait(500)
--         SetEntityCoords(cache.ped, selectedCoords.x, selectedCoords.y, selectedCoords.z - 1)
--         SetEntityHeading(cache.ped, selectedCoords.w)
--         Wait(500)
--         DoScreenFadeIn(500)
--     end)
-- end)

-- CreateThread(function()
--     while true do
--         local wait = 1000

--         local coords = GetEntityCoords(cache.ped)
--         for k, v in pairs(points) do
--             local dist = #(coords - v.coords.xyz)

--             if dist < 10 then
--                 wait = 0
--                 DrawMarker(2, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.1, 255,
--                     255, 255, 100, false, false, false, true, false, false, false)

--                 if IsControlJustReleased(0, 38) and dist < 1.5 then
--                     lib.showMenu('ambulance_elevator_menu2')
--                 end
--             end
--         end

--         Wait(wait)
--     end
-- end)
