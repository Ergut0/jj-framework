RegisterNetEvent("jj_policejob:location:markLocation", function(location, point)
    local cfgCoords = Config.points[location]
    local locationCoords = {}
    local locationExplanation = nil
    
    
    
    local case = {
        ["vehiclePoints"] = function()
            local coords = {}
            local indicacion = ""
            for k, v in pairs(cfgCoords.vehiclePoints or {}) do
                coords[k] = v.Menu
                if v.LocatorComment then 
                    indicacion = indicacion .. v.LocatorComment .. " "
                end
            end
            return coords, indicacion
        end,
        ["extrasPoints"] = function()
            local coords = {}
            local indicacion = ""
            for k, v in pairs(cfgCoords.extrasPoints or {}) do
                coords[k] = v.Menu
                if v.LocatorComment then 
                    indicacion = indicacion .. v.LocatorComment .. " "
                end
            end
            return coords, indicacion
        end,
        ["depotPoints"] = function()
            local coords = {}
            local indicacion = ""
            for k, v in pairs(cfgCoords.depotPoints or {}) do
                coords[k] = v.Menu
                if v.LocatorComment then 
                    indicacion = indicacion .. v.LocatorComment .. " "
                end
            end
            return coords, indicacion
        end,
        ["helicopterPoints"] = function()
            local coords = {}
            local indicacion = ""
            for k, v in pairs(cfgCoords.helicopterPoints or {}) do
                coords[k] = v.Menu
                if v.LocatorComment then 
                    indicacion = indicacion .. v.LocatorComment .. " "
                end
            end
            return coords, indicacion
        end,
        ["boatPoints"] = function()
            local coords = {}
            local indicacion = ""
            for k, v in pairs(cfgCoords.boatPoints or {}) do
                coords[k] = v.Menu
                if v.LocatorComment then 
                    indicacion = indicacion .. v.LocatorComment .. " "
                end
            end
            return coords, indicacion
        end,
    }
    locationCoords, locationExplanation = case[point]()

    if locationExplanation and locationExplanation ~= "" then
        lib.notify({
            title = 'Indicaciones al punto', 
            description = locationExplanation, 
            type = 'inform',
            duration = 10 * 1000
        })
    end

    for k,v in pairs(locationCoords) do 
        TriggerEvent("jj_policejob:location:drawBlipAndMarker", v, point)
    end
end)

RegisterNetEvent("jj_policejob:location:drawBlipAndMarker", function(markerCoords, point)
    local secondsDuration = 60

    if point == "boatPoints" then 
        secondsDuration = secondsDuration * 3
    end
    local timer = lib.timer(secondsDuration * 1000, function()
        return false
    end, true)
    --if point == "boatPoints" then 
    local blip = AddBlipForCoord(markerCoords.x, markerCoords.y, markerCoords.z)
    SetBlipSprite(blip, 652)
    SetBlipColour(blip, 67)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.8)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 67)

    

    --end
    while timer:getTimeLeft('s') > 0 do 
        -- draw every frame
		Wait(0)
        DrawMarker(2, markerCoords.x, markerCoords.y, markerCoords.z + 1, 0.0, 0.0, 0.0, 0.0, 180.0,    0.0, 0.5, 0.5, 0.5, 15, 97, 99, 80, true, true, 2, nil, nil, false)
    end
    RemoveBlip(blip)
end)