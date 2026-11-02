local funcs = require "client.functions"
local pointsCreated = {}
local targetsCreated = {}
local stateBelong = false

local dutyMarkers = {}
local staticMarkers = {}
local MARKER_DISTANCE = 15.0

local addMarker = function(list, coords)
    list[#list + 1] = vector3(coords.x, coords.y, coords.z)
end

-- Punto de servicio con su marcador en el suelo
local newPoint = function(data)
    addMarker(dutyMarkers, data.coords)
    return lib.points.new(data)
end

local drawMarkers = function(list, position)
    local drawn = false
    for _, coords in ipairs(list) do
        if #(position - coords) < MARKER_DISTANCE then
            DrawMarker(20, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 147, 51, 234, 200, false, false, false, true, false, false, false)
            drawn = true
        end
    end
    return drawn
end

CreateThread(function()
    local isPolice, nextCheck = false, 0
    while true do
        if GetGameTimer() > nextCheck then
            isPolice = GetPlayerData().job.name == 'police'
            nextCheck = GetGameTimer() + 2000
        end

        local position = GetEntityCoords(cache.ped)
        local drawn = drawMarkers(dutyMarkers, position)
        if isPolice and drawMarkers(staticMarkers, position) then drawn = true end
        Wait(drawn and 0 or 500)
    end
end)

local removeAllPoints = function()
    for _, point in ipairs(pointsCreated) do
        point:remove()
    end

    for _, target in ipairs(targetsCreated) do
        exports.ox_target:removeZone(target)
    end

    pointsCreated = {}
    targetsCreated = {}
    dutyMarkers = {}
end

local createDutyPoints = function(duty)
    removeAllPoints()

    Wait(150)

    for k, v in pairs(Config.points) do
        if duty then
            if v.vehiclePoints then
                for i, j in pairs(v.vehiclePoints) do
                    local pointMenuCreated1 = newPoint({
                        coords = j.Menu,
                        distance = 3.0,
                        nearby = function(self)
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                local spawnCoords = j.Spawn
                                funcs.OpenListCars(spawnCoords)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Menu de vehículos")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointMenuCreated1

                    local pointDeleteCreated1 = newPoint({
                        coords = j.Delete,
                        distance = 3.0,
                        nearby = function(self)
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then return end
                                DeleteServiceVehicle(cache.vehicle)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Guardar vehículo")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointDeleteCreated1
                end
            end

            if v.helicopterPoints then
                for i, j in pairs(v.helicopterPoints) do
                    local pointMenuCreated2 = newPoint({
                        coords = j.Menu,
                        distance = 3.0,
                        nearby = function(self)
                            -- exports['qb-core']:HelpNotify("Menu de helicópteros")
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                local spawnCoords = j.Spawn
                                funcs.OpenListHelicopters(spawnCoords)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Menu de helicópteros")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointMenuCreated2

                    local pointDeleteCreated2 = newPoint({
                        coords = j.Delete,
                        distance = 5.0,
                        nearby = function(self)
                            -- exports['qb-core']:HelpNotify("Guardar helicóptero")
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then return end
                                DeleteServiceVehicle(cache.vehicle)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Guardar helicóptero")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointDeleteCreated2
                end
            end

            if v.boatPoints then
                for i, j in pairs(v.boatPoints) do
                    local pointMenuCreated3 = newPoint({
                        coords = j.Menu,
                        distance = 3.0,
                        nearby = function(self)
                            -- exports['qb-core']:HelpNotify("Menu de barcos")
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                local spawnCoords = j.Spawn
                                funcs.OpenListBoats(spawnCoords)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Menu de barcos")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })


                    pointsCreated[#pointsCreated + 1] = pointMenuCreated3

                    local pointDeleteCreated3 = newPoint({
                        coords = j.Delete,
                        distance = 3.0,
                        nearby = function(self)
                            -- exports['qb-core']:HelpNotify("Guardar barco")
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                if not cache.vehicle then return end
                                DeleteServiceVehicle(cache.vehicle)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Guardar barco")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointDeleteCreated3
                end
            end

            if v.depotPoints then
                for i, j in pairs(v.depotPoints) do
                    local pointMenuCreated4 = newPoint({
                        coords = j.Menu,
                        distance = 3.0,
                        nearby = function(self)
                            -- exports['qb-core']:HelpNotify("Menu de deposito")
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                local spawnCoords = j.Spawn
                                funcs.OpenDepot(spawnCoords)
                            end
                        end,
                        onEnter = function()
                            lib.showTextUI("[E] - Menu de deposito")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointMenuCreated4
                end
            end

            if v.armoryPoints then
                for i, coordsPoint in pairs(v.armoryPoints) do
                    local armory = exports.ox_target:addSphereZone({
                        coords = coordsPoint.coords,
                        radius = 2.0,
                        drawSprite = true,
                        debug = Config.Debug,
                        options = {
                            {
                                distance = 1.5,
                                name = coordsPoint.armory,
                                icon = 'fas fa-shield-alt',
                                label = coordsPoint.label,
                                onSelect = function()
                                    if coordsPoint.armory == "policeArmory" then
                                        funcs.OpenArmory(coordsPoint.armory)
                                    elseif coordsPoint.armory == "divisionsArmory" then
                                        funcs.OpenDivisionsArmory(coordsPoint.armory, coordsPoint.allowedDivisions)
                                    end
                                end,
                                canInteract = function()
                                    return funcs.GetPoliceStatus()
                                end
                            }
                        }
                    })


                    targetsCreated[#targetsCreated + 1] = armory
                end
            end

            if v.incuationPoints then
                for i, coordsPoint in pairs(v.incuationPoints) do
                    local incautions = exports.ox_target:addSphereZone({
                        coords = coordsPoint,
                        radius = 2.5,
                        drawSprite = true,
                        debug = Config.Debug,
                        options = {
                            {
                                distance = 1.5,
                                name = 'armory',
                                icon = 'fas fa-box-open',
                                label = 'Incautaciones',
                                onSelect = function()
                                    funcs.OpenIncautions()
                                end,
                                canInteract = function()
                                    return funcs.GetPoliceStatus()
                                end
                            }
                        }
                    })

                    targetsCreated[#targetsCreated + 1] = incautions
                end
            end

            if v.extrasPoints then
                for i, coordsPoint in pairs(v.extrasPoints) do
                    local pointExtrasCreated = newPoint({
                        coords = coordsPoint.Menu,
                        distance = 4.0,
                        onEnter = function()
                            lib.showTextUI("[E] - Extras")
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                        nearby = function(self)
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                funcs.VehicleExtras()
                            end
                        end,
                    })

                    pointsCreated[#pointsCreated + 1] = pointExtrasCreated
                end
            end

            -- if v.bossPoints then
            --     for i, coordsPoint in pairs(v.bossPoints) do
            --         local pointBossCreated = lib.points.new({
            --             coords = coordsPoint,
            --             distance = 1.5,
            --             onEnter = function()
            --                 lib.showTextUI("Menu de Jefe")
            --             end,
            --             nearby = function(self)
            --                 --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
            --                 if IsControlJustPressed(0, 38) then
            --                     OpenBossMenu()
            --                 end
            --             end,
            --             onExit = function()
            --                 lib.hideTextUI()
            --             end,
            --         })
            --         pointsCreated[#pointsCreated + 1] = pointBossCreated
            --     end
            -- end
        end
    end
end

local refreshPoints = function(duty)
    if not duty then
        removeAllPoints()
    else
        createDutyPoints(duty)
    end
end

-- Diagnóstico: /policiadebug
local countPoints = function()
    return #pointsCreated, #targetsCreated, #dutyMarkers, #staticMarkers
end

return {
    addStaticMarker = function(coords) addMarker(staticMarkers, coords) end,
    countPoints = countPoints,
    removeAllPoints = removeAllPoints,
    createDutyPoints = createDutyPoints,
    refreshPoints = refreshPoints
}
