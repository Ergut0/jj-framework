local points = {

    -- {
    --     label = 'Planta 0',
    --     coords = vec(306.57, -599.47, 43.29, 337.28),
    -- },

    -- {
    --     label = 'Planta 1',
    --     coords = vec(306.65, -599.26, 49.51, 343.82),
    -- },

    -- {
    --     label = 'Planta 5',
    --     coords = vec(306.46, -599.32, 69.22, 341.53),
    -- },
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
--         id = 'ambulance_elevator_menu',
--         title = 'Ascensor',
--         position = 'bottom-right',
--         options = elements,
--     }, function(selected)
--         local selectedCoords = elements[selected].value
--         local coords = GetEntityCoords(cache.ped)
--         lib.hideMenu('ambulance_elevator_menu')
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
--                     lib.showMenu('ambulance_elevator_menu')
--                 end
--             end
--         end

--         Wait(wait)
--     end
-- end)
