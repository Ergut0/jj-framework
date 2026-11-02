local pointsFuncs = require "client.points"
local funcs = require "client.functions"
local blipsCreated = 0

-- Dice en la consola F8 qué ha creado el recurso, para saber por qué no se ve algo
RegisterCommand('policiadebug', function()
    local job = GetPlayerData().job
    local points, zones, dutyMarkers, staticMarkers = pointsFuncs.countPoints()
    print(('[jj_policejob] dentro=%s trabajo=%s servicio=%s blips=%d puntos=%d zonas=%d marcadores=%d+%d'):format(
        tostring(IsLoggedIn()), tostring(job.name), tostring(job.onduty), blipsCreated, points, zones, dutyMarkers, staticMarkers))
end, false)

CreateThread(function()
    while not IsLoggedIn() do
        Wait(100)
    end

    local PlayerData = GetPlayerData()
    for k, station in pairs(Config.points) do
        local blip = AddBlipForCoord(station.blip.coords)
        blipsCreated = blipsCreated + 1
        SetBlipSprite(blip, station.blip.sprite)
        SetBlipScale(blip, station.blip.scale)
        SetBlipColour(blip, station.blip.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(station.blip.name)
        EndTextCommandSetBlipName(blip)
        SetBlipAsShortRange(blip, true)

        for i, extraBlip in pairs(station.extraBlips or {}) do
            if Config.Debug then
                print("DEBUG: Processing extra blip:", json.encode(extraBlip))
            end
            if not extraBlip.ShowBlip then
                goto continue
            end
            if extraBlip.ShowOnlyPolice then
                if PlayerData.job.name ~= "police" or not PlayerData.job.onduty then
                    goto continue
                end
            end
            if Config.Debug then
                print("DEBUG: Player is police and on duty. Creating extra blip:", json.encode(extraBlip))
            end
            local blipExtra = AddBlipForCoord(extraBlip.coords)
            SetBlipSprite(blipExtra, extraBlip.sprite)
            SetBlipScale(blipExtra, extraBlip.scale)
            SetBlipColour(blipExtra, extraBlip.color)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(extraBlip.name)
            EndTextCommandSetBlipName(blipExtra)
            SetBlipAsShortRange(blipExtra, true)

            ::continue::
        end
    end
end)

OnDutyChange(function(duty)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" then
        return
    end
    pointsFuncs.refreshPoints(duty)
end)

OnJobUpdate(function(jobInfo)
    pointsFuncs.refreshPoints(jobInfo.name == 'police' and jobInfo.onduty)
end)


OnPlayerLoaded(function()
    local PlayerData = GetPlayerData()
    if PlayerData.job.name == 'police' and PlayerData.job.onduty then
        pointsFuncs.createDutyPoints(PlayerData.job.onduty)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local PlayerData = GetPlayerData()
        if PlayerData.job.name == 'police' and PlayerData.job.onduty then
            pointsFuncs.createDutyPoints(PlayerData.job.onduty)
        end
    end
end)

exports("getLeaveJail", function(station)
    local point = Config.points[station or "Sur"]
    return point and point.leaveJail
end)

RegisterNetEvent("jj_policejob:jail:sendToJail", function(duracion, pd_info)
    local _time = tonumber(duracion) * 60 * 1000
    if lib.progressCircle({
            duration = _time,
            label = "Cumpliendo condena",
            position = "bottom",
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                combat = true,
            },
        }) then
        Notify('Has terminado tu condena y un agente te ha sacado de la comisaria')
        SetEntityCoords(cache.ped,
            vector3(Config.points[pd_info].leaveJail.x, Config.points[pd_info].leaveJail.y,
                Config.points[pd_info].leaveJail.z))
        if LocalPlayer.state.belong then
            LocalPlayer.state:set("belong", false, true)
            TriggerServerEvent("jj_policejob:server:toggleBelongings", LocalPlayer.state.belong)
        end
    end
end)

CreateThread(function()
    while not IsLoggedIn() do
        Wait(1000)
    end

    for k, NPCPed in pairs(Config.NPCCoords) do
        if Config.Debug then
            print("DEBUG: Spawning NPC :", json.encode(NPCPed, { indent = true }))
        end
        local success = lib.requestModel(NPCPed.model)

        if not success then
            print("Failed to load model")
            return
        end

        local spawnPed = CreatePed(0, GetHashKey(NPCPed.model), NPCPed.coords, 0, false, false)
        SetEntityAsMissionEntity(spawnPed, true, true)
        FreezeEntityPosition(spawnPed, true)
        SetBlockingOfNonTemporaryEvents(spawnPed, true)
        SetEntityInvincible(spawnPed, true)
        SetPedDefaultComponentVariation(spawnPed)
        SetModelAsNoLongerNeeded(spawnPed)
        PlaceObjectOnGroundProperly(spawnPed)
        TaskStartScenarioInPlace(spawnPed, NPCPed.scenario, 0, true)

        if NPCPed.pedComponents then
            for j, pedComponent in pairs(NPCPed.pedComponents) do
                SetPedComponentVariation(spawnPed, pedComponent.componentId, pedComponent.drawableId,
                    pedComponent.textureId, 0)
            end
        end

        if NPCPed.pedProps then
            for j, pedProp in pairs(NPCPed.pedProps) do
                SetPedPropIndex(spawnPed, pedProp.componentId, pedProp.drawableId, pedProp.textureId, true)
            end
        end

        if NPCPed.multiplayerPedData then
            local mpData = NPCPed.multiplayerPedData
            SetPedHeadBlendData(spawnPed, mpData.shapeFirstID, mpData.shapeSecondID, mpData.shapeThirdID,
                mpData.skinFirstID, mpData.skinSecondId, mpData.skinThirdId, mpData.shapeMix, mpData.skinMix,
                mpData.thirdMix, false)
            if mpData.hairColor1 and mpData.hairColor2 then
                SetPedHairTint(spawnPed, mpData.hairColor1, mpData.hairColor2)
            end
            if mpData.eyebrowId and mpData.eyebrowColor then
                SetPedHeadOverlay(spawnPed, 2, mpData.eyebrowId, 1.0)
                SetPedHeadOverlayColor(spawnPed, 2, 1, mpData.eyebrowColor, mpData.eyebrowColor)
            end
        end

        if NPCPed.npcType == "npcPolice" then
            exports.ox_target:addLocalEntity(spawnPed, {
                {
                    name = "npcPolice",
                    label = NPCPed.targetLabel,
                    icon = "fas fa-user-tie",
                    distance = 15.0,
                    onSelect = function()
                        funcs.OpenNpcMenu()
                    end
                }
            })
        elseif NPCPed.npcType == "npcPoliceLocator" then
            exports.ox_target:addLocalEntity(spawnPed, {
                {
                    name = "npcPoliceLocator",
                    label = NPCPed.targetLabel,
                    icon = "fas fa-user-tie",
                    distance = 6.0,
                    onSelect = function()
                        funcs.OpenNpcLocatorMenu(NPCPed.npcLocation)
                    end
                }
            })
        end
    end
end)

CreateThread(function()
    for k, v in pairs(Config.points) do
        if v.dutyPoints then
            for i, coordsPoint in pairs(v.dutyPoints) do
                local armory = exports.ox_target:addSphereZone({
                    coords = coordsPoint,
                    radius = 2,
                    debug = Config.Debug,
                    options = {
                        {
                            distance = 2.0,
                            name = 'dutyPoint',
                            icon = 'fa-solid fa-clock',
                            label = "Entrar/Salir de servicio",
                            onSelect = function()
                                TriggerServerEvent('jj_policejob:server:toggleDuty')
                            end,
                            canInteract = function()
                                local PlayerData = GetPlayerData()
                                return PlayerData.job.name == 'police'
                            end
                        }
                    }
                })
                if Config.Debug then
                    print("Duty point created at:", coordsPoint)
                end
            end
        end

        if v.cloakroomPoints then
            for i, pointInfo in pairs(v.cloakroomPoints) do
                pointsFuncs.addStaticMarker(pointInfo.coords)
                lib.points.new({
                    coords = pointInfo.coords,
                    distance = pointInfo.radius or 2.0,
                    onEnter = function(self)
                        local PlayerData = GetPlayerData()
                        self.isPolice = PlayerData.job.name == 'police'
                        if self.isPolice then
                            lib.showTextUI("[E] Ropero")
                        end
                    end,
                    nearby = function(self)
                        if self.isPolice and IsControlJustPressed(0, 38) then
                            funcs.OpenCloakroom()
                        end
                    end,
                    onExit = function(self)
                        if self.isPolice then
                            lib.hideTextUI()
                        end
                    end,
                })
            end
        end

        if v.ascensorPoints then
            for index, info in pairs(v.ascensorPoints) do
                for i, plantas in pairs(info) do
                    local pointAscensorCreated = lib.points.new({
                        coords = plantas.coords,
                        distance = 1.5,
                        onEnter = function()
                            lib.showTextUI(("Ascensor %s"):format(index))
                        end,
                        nearby = function(self)
                            --DrawMarker(20, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                            if IsControlJustPressed(0, 38) then
                                funcs.OpenAscensor(info)
                            end
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                    })
                end
            end
        end

        if v.fingerprintPoints then
            for i, coordsPoint in pairs(v.fingerprintPoints) do
                pointsFuncs.addStaticMarker(coordsPoint)
                lib.points.new({
                    coords = coordsPoint,
                    distance = 1.5,
                    onEnter = function()
                        lib.showTextUI("[E] Lector de huellas")
                    end,
                    nearby = function()
                        if IsControlJustPressed(0, 38) then
                            TriggerEvent('detector:use')
                        end
                    end,
                    onExit = function()
                        lib.hideTextUI()
                    end,
                })
            end
        end

        if v.belongingsPoints then
            for i, coordsPoint in pairs(v.belongingsPoints) do
                local belong = exports.ox_target:addSphereZone({
                    coords = coordsPoint,
                    radius = 0.5,
                    debug = Config.Debug,
                    options = {
                        {
                            name = 'belongings',
                            icon = 'fas fa-user-secret',
                            label = 'Dejar/Recoger pertenencias',
                            onSelect = function()
                                LocalPlayer.state:set("belong", not LocalPlayer.state.belong, true)
                                TriggerServerEvent("jj_policejob:server:toggleBelongings", LocalPlayer.state.belong)
                            end
                        }
                    }
                })
            end
        end
    end
end)


AddEventHandler("jj_policejob:client:showBadge", function()
    local PlayerData = GetPlayerData()
    local badge = PlayerData.metadata.badge_number or "000"
    if PlayerData.job.name ~= "police" then return end
    if lib.progressBar({
            duration = 4000,
            label = 'Mostrando placa...',
            useWhileDead = true,
            canCancel = true,
            disable = {

            },
            anim = {
                clip = "swipe_card",
                dict = "missfbi_s4mop",
                flags = 49,
            },
        }) then
        local text = "La placa tendria el siguiente número: " .. badge
        RpAction(text)
    end
end)
