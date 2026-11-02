local uiOpen = false
JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local function GetBankMoney()
    local data = JJ.GetPlayerData()
    return data and data.accounts and data.accounts.bank or 0
end

local function GetPlate(vehicle)
    return (GetVehicleNumberPlateText(vehicle):gsub('%s+', ''):upper())
end

local function Notify(description, type)
    lib.notify({ description = description, type = type })
end
customCamMain = nil
customCamSec = nil

customConfigPosIndex = nil
customVehicle = nil
customVehiclePrice = nil
customVehicleData = nil

local renderingScriptCam = false

isOpenByAdmin = false
isOpenByT1ger = false
isOpenByPolice = false

-- Definir variable para el trabajo
local jobName = nil

CreateThread(function()
    for k, v in pairs(Config.Positions) do 
        local points = lib.points.new({
            coords = v.coords,
            distance = 4.5,
            onExit = function() 
                lib.hideTextUI()
            end,
            onEnter = function()  
                lib.showTextUI("[E] - Abrir el sistema de tuneo")
            end,
            nearby = function(self)
                DrawMarker(20, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                if self.currentDistance < 2.5 then 
                    if IsControlJustReleased(0, 38) then
                        local PlayerData = JJ.GetPlayerData()
                        if (PlayerData and PlayerData.job and PlayerData.job.name == v.whitelistJobName) or (v.whitelistJobName == false) then 
                            openUI()
                        else
                            Notify('No puedes acceder al menú', 'error')
                        end 
                    end 
                end
            end
        })
    end
end)

function updateCash()
    local whitelistJobName = nil
    if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex]) then
        whitelistJobName = Config.Positions[customConfigPosIndex].whitelistJobName
    end
    SendNUIMessage({
        type = 'update',
        what = 'cash',
        cash = GetBankMoney(),
        whitelistJobName = whitelistJobName
    })
end

function updateVehicleCard(vehicle)
    local vehicleModel = GetEntityModel(vehicle)

    local vehDisplayName = GetDisplayNameFromVehicleModel(vehicleModel)
    local vehicleLabelText = GetLabelText(vehDisplayName)
    local vehicleName = vehicleLabelText == 'NULL' and vehDisplayName or vehicleLabelText
    
    local acceleration = (GetVehicleModelAcceleration(vehicleModel) or 0.0) * 10
    local maxSpeed = (GetVehicleModelEstimatedMaxSpeed(vehicleModel) or 0.0) / 10
    local breaks = GetVehicleModelMaxBraking(vehicleModel) or 0.0
    local power = (acceleration + maxSpeed) / 2
    
    SendNUIMessage({
        type = 'update',
        what = 'card',
        vehicleName = vehicleName,
        power = power,
        acceleration = acceleration,
        maxSpeed = maxSpeed,
        breaks = breaks
    })
end

function openUI()
    if (uiOpen) then return end

    local playerPed = PlayerPedId()
    local playerVeh = GetVehiclePedIsIn(playerPed, false)
    
    if (playerVeh ~= 0 and DoesEntityExist(playerVeh)) then
        -- Verificar propiedad del vehículo si no es admin
        if not isOpenByAdmin then
            local plate = GetPlate(playerVeh)
            TriggerServerEvent('jj_tuneos:server:CheckVehicleOwnership', plate)
            -- El resto de la lógica se ejecutará en el evento de respuesta del servidor
            return
        end
        
        continueOpenUI(playerVeh)
    else
        -- Si no hay vehículo, mostrar mensaje apropiado
        if isOpenByAdmin then
            Notify('Necesitas estar dentro de un vehículo para abrir el menú de tuning', 'error')
        end
        isOpenByAdmin = false
    end
end

function continueOpenUI(playerVeh)
    if (uiOpen) then return end
    
    customVehicle = playerVeh
    customVehicleData = lib.getVehicleProperties(customVehicle)
    FreezeEntityPosition(customVehicle, true)

    -- Actualizar información del trabajo del jugador
    local PlayerData = JJ.GetPlayerData()
    if PlayerData and PlayerData.job then
        jobName = PlayerData.job.name
    else
        jobName = nil
    end

    SetVehicleOnGroundProperly(playerVeh)

    DisplayHud(false)
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    
    customVehiclePrice = 0
    local tempVehicleModel = GetEntityModel(customVehicle)
    for model, data in pairs(Config.Vehicles) do
        if (tempVehicleModel == GetHashKey(model)) then
            customVehiclePrice = 0
            break
        end
    end

    updateCash()
    updateVehicleCard(customVehicle)
    updateMenu('main')
        SendNUIMessage({
            type = 'open',
            isOpenByAdmin = isOpenByAdmin
        })
        
        local vehPos = GetEntityCoords(customVehicle)
        local camPos = GetOffsetFromEntityInWorldCoords(customVehicle, -2.0, 5.0, 3.0)
        local headingToObject = GetHeadingFromVector_2d(vehPos.x - camPos.x, vehPos.y - camPos.y)
        
        customCamMain = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, -35.0, 0.0, headingToObject, GetGameplayCamFov(), false, 2)
        customCamSec = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, -35.0, 0.0, headingToObject, GetGameplayCamFov(), false, 2)

        SetCamActive(customCamMain, true)
        RenderScriptCams(true, true, 500, true, true)
        renderingScriptCam = true
        
        uiOpen = true

        CreateThread(function()
            while (uiOpen) do
                DisableAllControlActions(0)

                EnableControlAction(0, 1, true) -- mouse mv
                EnableControlAction(0, 2, true) -- mouse mv

                EnableControlAction(0, 86, true) -- horn
                EnableControlAction(0, 249, true) -- voice
                EnableControlAction(0, 0, true) -- Primera persona

                if (IsDisabledControlJustReleased(0, 26)) then
                    RenderScriptCams(not renderingScriptCam, true, 500, true, true)
                    renderingScriptCam = not renderingScriptCam
                end

                Wait(0)
            end
        end)
end

function closeUI(sendToUI, resetVehToDefault)
    sendToUI = sendToUI or 0
    resetVehToDefault = resetVehToDefault or 0

    DisplayHud(true)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if (sendToUI == 1) then
        SendNUIMessage({
            type = 'close'
        })
    end
        
    -- Ensure script cams are disabled safely
    if renderingScriptCam then
        RenderScriptCams(false, true, 500, true, true)
        renderingScriptCam = false
    end

    -- Destroy cams if they exist
    if customCamMain ~= nil and DoesCamExist(customCamMain) then
        DestroyCam(customCamMain, true)
        customCamMain = nil
    end
    if customCamSec ~= nil and DoesCamExist(customCamSec) then
        DestroyCam(customCamSec, true)
        customCamSec = nil
    end

    ClearFocus()

    -- Restore vehicle properties only if data and entity exist
    if resetVehToDefault == 1 and customVehicle ~= nil and customVehicleData ~= nil and DoesEntityExist(customVehicle) then
        lib.setVehicleProperties(customVehicle, customVehicleData)
    end

    -- Close doors safely
    if customVehicle ~= nil and DoesEntityExist(customVehicle) then
        openDoors(customVehicle, {0,0,0,0,0,0,0})
    end

    -- Save vehicle props only if we have data and a valid plate
    if customVehicleData ~= nil and customVehicle ~= nil and DoesEntityExist(customVehicle) then
        TriggerServerEvent('jj_tuneos:server:SaveVehicleProps', customVehicleData, GetPlate(customVehicle))
    end

    customVehiclePrice = nil

    if customVehicle ~= nil and DoesEntityExist(customVehicle) then
        FreezeEntityPosition(customVehicle, false)
    end

    customVehicle = nil
    customVehicleData = nil
    customConfigPosIndex = nil

    if (isOpenByAdmin) then
        isOpenByAdmin = false
    end
    if (isOpenByT1ger) then
        isOpenByT1ger = false
    end
    if (isOpenByPolice) then
        isOpenByPolice = false
    end
    uiOpen = false
end

function updateMenu(menuId)
    if (menuId == nil or Config.Menus[menuId] == nil) then 
        return 
    end

    local menu = clearMenu(Config.Menus[menuId])
    local newOptions = optionsShouldShow(menu)

    if isOpenByPolice then
        local filteredOptions = {}
        for _, option in ipairs(newOptions) do
            if option.openSubMenu ~= 'upgrade' then
                table.insert(filteredOptions, option)
            end
        end
        newOptions = filteredOptions
    end

    local whitelistJobName = nil
    if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex]) then
        whitelistJobName = Config.Positions[customConfigPosIndex].whitelistJobName
    end

    SendNUIMessage({
        type = 'update',
        what = 'menu',
        menuId = menuId,
        options = newOptions,
        menuTitle = menu.title,
        defaultOption = menu.defaultOption,
        whitelistJobName = whitelistJobName
    })
end


RegisterNUICallback('uiReady', function(data, cb)
    updateUICurrentJob()
    cb('ok')
end)

RegisterNUICallback('handle', function(data, cb)
    cb('ok')
    if (data.type == 'close') then
        closeUI(0, 1)
    elseif (data.type == 'update') then
        if (data.what == 'menu') then
            if (data.user == 'hover') then
                if (not data or not data.menuId or not data.menuIndex) then
                    return
                end
                
                local menu = Config.Menus[data.menuId]
                
                if (not menu) then
                    return
                end
                
                playSound('SELECT', 'HUD_FREEMODE_SOUNDSET')

                local newOptions = optionsShouldShow(menu)

                if (data.color ~= nil) then
                    local tempModType = string.sub(data.menuId, #'mod_' + 1)
                    SetVehicleModData(customVehicle, tempModType, data.color)

                    -- if (tempModType == 'tyreSmokeColor') then
                    --     -- burnout
                    -- end

                    return
                end

                local menuOption = newOptions[data.menuIndex + 1]
                if (menuOption.onHover ~= nil) then
                    menuOption.onHover()
                end
            elseif (data.user == 'enter') then
                if (not data.menuId or not data.menuIndex) then
                    return
                end
                
                local menu = Config.Menus[data.menuId]
                
                if (not menu) then
                    return
                end

                local newOptions = optionsShouldShow(menu)
                local menuOption = newOptions[data.menuIndex + 1]

                local canBuyMod = true

                -- Si el tuning gratuito está habilitado, omitir verificación de precios
                if Config.FreeTuning then
                    canBuyMod = true
                elseif ((not isOpenByAdmin) and menuOption and menuOption.price) then
                    if (menuOption.price == -1) then
                        canBuyMod = false
                    elseif (menuOption.price > 0) then
                        canBuyMod = false

                        menuOption.priceMult = menuOption.priceMult or 1
                        local tempPrice = menuOption.price or math.floor(customVehiclePrice * menuOption.priceMult / 100)
                        if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex] and jobName ~= Config.Positions[customConfigPosIndex].whitelistJobName) then
                            tempPrice = tempPrice * 2
                        end

                        if (GetBankMoney() >= tempPrice) then
                            canBuyMod = true

                            if (tempPrice > 0) then 
                                TriggerServerEvent('jj_tuneos:server:ChargeMoney', tempPrice, 'bank')
                            end
                        else
                            canBuyMod = false
                        end
                    end
                end

                if (canBuyMod == false) then
                    playSound('ATM_WINDOW', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
                    return
                end

                playSound('Zoom_In', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')

                if (data.color ~= nil) then
                    local tempModType = string.sub(data.menuId, #'mod_' + 1)
                    
                    local tempPrice = 0

                    if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex] and jobName ~= Config.Positions[customConfigPosIndex].whitelistJobName) then
                        tempPrice = tempPrice * 2
                    end

                    -- Si el tuning gratuito está habilitado o es admin, no cobrar
                    if not isOpenByAdmin and not Config.FreeTuning then
                        if (GetBankMoney() >= tempPrice) then
                            if (tempPrice > 0) then
                                TriggerServerEvent('jj_tuneos:server:ChargeMoney', tempPrice, 'bank')
                            end
                        else
                            playSound('ATM_WINDOW', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
                            return
                        end
                    end

                    customVehicleData = lib.getVehicleProperties(customVehicle)
                    playCustomSound('spray')
                    openColorPicker(data.colorTitle, tempModType, data.isCustom, data.priceMult)

                    return
                end

                if (not menuOption) then
                    return
                end
                
                if (menuOption.onSelect ~= nil) then
                    menuOption.onSelect()
                end

                if (menuOption.openSubMenu ~= nil) then
                    updateMenu(menuOption.openSubMenu)
                end

                if (menuOption.modType ~= nil) then
                    createMenu(data.menuId, menuOption)
                    updateMenu('mod_' .. menuOption.modType)
                end
            elseif (data.user == 'backspace') then
                if (not data.menuId) then
                    return
                end

                local menu = Config.Menus[data.menuId]
                
                if (not menu) then
                    return
                end

                playSound('Zoom_In', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')
                
                local newOptions = optionsShouldShow(menu)
                
                if (data.menuIndex) then
                    local menuOption = newOptions[data.menuIndex + 1]
                    if (menuOption) then
                        if (menuOption.onBack ~= nil) then
                            menuOption.onBack()
                        end
                    end
                end

                if (menu.onBack ~= nil) then
                    menu.onBack()
                end
                
                if customVehicle ~= nil and customVehicleData ~= nil and DoesEntityExist(customVehicle) then
                    lib.setVehicleProperties(customVehicle, customVehicleData)
                end
                openDoors(customVehicle, {0,0,0,0,0,0,0})
            end
        end
    end
end)

function optionsShouldShow(menu)
    local newOptions = {}
    
    for i = 1, #menu.options, 1 do
        local shouldShow = true

        if (menu.options[i].modType ~= nil) then
            if (GetNumVehicleModData(customVehicle, menu.options[i].modType) < 0) then
                shouldShow = false
            end
        end
        
        if (shouldShow and menu.options[i].openSubMenu ~= nil) then
            local subMenu = Config.Menus[menu.options[i].openSubMenu]
            local tempShouldShow = false
            for i = 1, #subMenu.options, 1 do
                if (subMenu.options[i].modType ~= nil) then
                    if (GetNumVehicleModData(customVehicle, subMenu.options[i].modType) >= 0 or subMenu.options[i].openSubMenu ~= nil) then
                        tempShouldShow = true
                        break
                    end
                end
            end

            shouldShow = tempShouldShow
        end

        if (not isOpenByAdmin) then
            if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex] and jobName ~= Config.Positions[customConfigPosIndex].whitelistJobName) then
                if (menu.options[i].openSubMenu == 'upgrade') then
                    shouldShow = false
                end
            end
        end

        if (shouldShow == true) then
            table.insert(newOptions, menu.options[i])
        end
    end

    return newOptions
end

function createMenu(menuId, menuOption)
    local newMenuId = 'mod_' .. menuOption.modType
    
    local curOption = GetVehicleCurrentMod(customVehicle, menuOption.modType)
    local curOptionOptionIndex = curOption + 1
    if (menuOption.modType == 'windowTint') then
        curOptionOptionIndex = curOption
    end
    
    Config.Menus[newMenuId] = {
        title = menuOption.label,
        options = {},
        onBack = function()
            updateMenu(menuId)
            
            if (menuOption.onSubBack ~= nil) then 
                menuOption.onSubBack()
            end
        end,
        defaultOption = curOptionOptionIndex
    }
    
    if (menuOption.customType == 'color' or menuOption.customType == 'customColor') then
        Config.Menus[newMenuId].title = ''
        return
    end

    local startIndex = -1
    if (menuOption.modType == 'windowTint' or menuOption.modType == 'extras') then
        startIndex = 0
    end

    for i = startIndex, GetNumVehicleModData(customVehicle, menuOption.modType), 1 do
        local tempLabel = GetVehicleModIndexLabel(customVehicle, menuOption.modType, i)
        if (not tempLabel or tempLabel == 'NULL') then
            tempLabel = tostring(i) + 1
        end

        menuOption.priceMult = menuOption.priceMult or 1.0

        local tempPrice = 0
        if (curOption == i) then
            tempPrice = -1
        else
            if (type(menuOption.priceMult) == 'number') then
                tempPrice = 0
            else
                tempPrice = 0
            end
        end
        
        table.insert(Config.Menus[newMenuId].options, {
            label = tempLabel,
            img = menuOption.img,
            price = tempPrice,
            priceMult = menuOption.priceMult,
            onHover = function()
                SetVehicleModData(customVehicle, menuOption.modType, i)
            end,
            onSelect = function()
                customVehicleData = lib.getVehicleProperties(customVehicle)
                createMenu(menuId, menuOption)
                updateMenu(newMenuId)

                playCustomSound('construction')
            end
        })

        if (menuOption.modType == 11 or menuOption.modType == 18) then
            local tempOption = Config.Menus[newMenuId].options[#Config.Menus[newMenuId].options]
            tempOption.onHover = function()
                SetVehicleModData(customVehicle, menuOption.modType, i)
                TaskVehicleTempAction(PlayerPedId(), customVehicle, 31, 2000)
            end
        elseif (menuOption.modType == 'extras') then
            local tempOption = Config.Menus[newMenuId].options[#Config.Menus[newMenuId].options]
            
            local isTempExtraOn = GetVehicleCurrentMod(customVehicle, 'extras', (i + 1))
            
            tempOption.price = nil
            tempOption.onHover = nil

            tempOption.onSelect = function()
                isTempExtraOn = GetVehicleCurrentMod(customVehicle, 'extras', (i + 1))

                Config.Menus['extras_on_off'] = {
                    title = 'EXTRA ' .. tostring(i + 1),
                    options = {
                        {
                            label = 'OFF',
                            img = 'img/icons/minus.png',
                            price = tempPrice,
                            onHover = function()
                                SetVehicleModData(customVehicle, menuOption.modType, {id = (i + 1), enable = 1})
                            end,
                            onSelect = function()
                                customVehicleData = lib.getVehicleProperties(customVehicle)

                                Config.Menus['extras_on_off'].options[1].price = -1
                                Config.Menus['extras_on_off'].options[2].price = tempPrice

                                updateMenu('extras_on_off')

                                playCustomSound('construction')
                            end
                        },
                        {
                            label = 'ON',
                            img = 'img/icons/plus.png',
                            price = tempPrice,
                            onHover = function()
                                SetVehicleModData(customVehicle, menuOption.modType, {id = (i + 1), enable = 0})
                            end,
                            onSelect = function()
                                customVehicleData = lib.getVehicleProperties(customVehicle)

                                Config.Menus['extras_on_off'].options[1].price = tempPrice
                                Config.Menus['extras_on_off'].options[2].price = -1

                                updateMenu('extras_on_off')

                                playCustomSound('construction')
                            end
                        },
                    },
                    onBack = function() updateMenu(newMenuId) end,
                    defaultOption = 0
                }
                
                if (isTempExtraOn == 0) then
                    Config.Menus['extras_on_off'].options[2].price = -1
                    Config.Menus['extras_on_off'].defaultOption = 1
                else
                    Config.Menus['extras_on_off'].options[1].price = -1
                end

                updateMenu('extras_on_off')
            end
        end
    end
end

function openColorPicker(title, modType, isCustom, priceMult)
    priceMult = priceMult or 1
    
    local defaultValue
    
    if (isCustom) then
        local r, g, b = GetVehicleCurrentMod(customVehicle, modType)
        defaultValue = {r, g, b}
    else
        defaultValue = GetVehicleCurrentMod(customVehicle, modType)
    end

    local whitelistJobName = nil
    if (customConfigPosIndex and customConfigPosIndex > 0 and customConfigPosIndex <= #Config.Positions and Config.Positions[customConfigPosIndex]) then
        whitelistJobName = Config.Positions[customConfigPosIndex].whitelistJobName
    end

    SendNUIMessage({
        type = 'open',
        what = 'colorPicker',
        isOpenByAdmin = isOpenByAdmin,
        isCustom = isCustom,
        defaultValue = defaultValue,
        title = title,
        priceMult = priceMult,
        price = 0,
        whitelistJobName = whitelistJobName
    })
end

function updateUICurrentJob()
    -- Actualizar jobName en caso de que haya cambiado
    local PlayerData = JJ.GetPlayerData()
    if PlayerData and PlayerData.job then
        jobName = PlayerData.job.name
    else
        jobName = nil
    end
    
    SendNUIMessage({
        type = 'update',
        what = 'job',
        jobName = jobName
    })
end


RegisterNetEvent('jj_tuneos:OpenMenuTunningAdmin', function(data)
    isOpenByAdmin = true
    openUI()
end)

exports('openMenuTunning', function()
    isOpenByAdmin = true
    openUI()
end)

exports('openByMenuT1ger', function()
    isOpenByAdmin = true
    openUI()
end)

exports('openByMenuPolice', function()
    isOpenByAdmin = true
    isOpenByPolice = true
    openUI()
end)

RegisterNetEvent('jj_tuneos:openByMenuPolice', function(data)
    isOpenByAdmin = true
    isOpenByPolice = true
    openUI()
end)

AddEventHandler('onResourceStop', function(resource)
    if (GetCurrentServerEndpoint() == nil) then
        return
    end

	if (resource == GetCurrentResourceName()) then
        if (uiOpen) then
            DisplayHud(true)
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)

            RenderScriptCams(false, true, 500, true, true)
            if customCamMain ~= nil and DoesCamExist(customCamMain) then
                DestroyCam(customCamMain, true)
                customCamMain = nil
            end
            if customCamSec ~= nil and DoesCamExist(customCamSec) then
                DestroyCam(customCamSec, true)
                customCamSec = nil
            end
            ClearFocus()

            if customVehicle ~= nil and customVehicleData ~= nil and DoesEntityExist(customVehicle) then
                lib.setVehicleProperties(customVehicle, customVehicleData)
            end
            if customVehicle ~= nil and DoesEntityExist(customVehicle) then
                FreezeEntityPosition(customVehicle, false)
            end
        end
    end
end)

-- Client events for server communication
RegisterNetEvent('jj_tuneos:client:UpdateCash', function()
    updateCash()
end)

RegisterNetEvent('jj_tuneos:client:RejectPayment', function()
    -- Revert vehicle to previous state if payment failed
    if customVehicle ~= nil and customVehicleData ~= nil and DoesEntityExist(customVehicle) then
        lib.setVehicleProperties(customVehicle, customVehicleData)
    end
end)

RegisterNetEvent('jj_tuneos:client:OpenAdminMenu', function()
    isOpenByAdmin = true
    customConfigPosIndex = 1 -- Establecer un índice por defecto para admin
    openUI()
end)

RegisterNetEvent('jj_tuneos:client:ReceivePlayerMoney', function(money)
    -- Update UI with current money
    SendNUIMessage({
        type = 'update',
        what = 'cash',
        cash = money
    })
end)

RegisterNetEvent('jj_tuneos:client:VehicleOwned', function(owned)
    -- Handle vehicle ownership check result
    if not owned and not isOpenByAdmin then
        Notify('No eres el propietario de este vehículo', 'error')
    else
        local playerPed = PlayerPedId()
        local playerVeh = GetVehiclePedIsIn(playerPed, false)
        if (playerVeh ~= 0 and DoesEntityExist(playerVeh)) then
            continueOpenUI(playerVeh)
        end
    end
end)
