local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local UPDATE_INTERVAL = 250

local voiceMode = 2
local hidden = false
local minimapReady = false

local function isSpawned()
    return LocalPlayer.state.isLoggedIn == true or JJ.IsSpawned()
end

-- También lo usa el HUD del vehículo
function IsHudVisible()
    return not hidden and isSpawned()
end

-- Minimapa cuadrado, con las texturas de la carpeta stream

local function setupMinimap()
    if minimapReady then return end
    minimapReady = true

    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    RequestStreamedTextureDict('squaremap', false)
    while not HasStreamedTextureDictLoaded('squaremap') do
        Wait(150)
    end

    SetMinimapClipType(0)
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')

    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + minimapOffset - 0.01, -0.047, 0.1638, 0.183)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + minimapOffset - 0.01, 0.0, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', 0.0 + minimapOffset - 0.01, 0.012, 0.250, 0.300)

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    SetMinimapClipType(0)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end

-- Solo se ve dentro de un vehículo
local function updateMinimap()
    DisplayRadar(isSpawned() and cache.vehicle and true or false)
end

-- Hambre y sed: las guarda el servidor con el personaje

local function getNeed(metadata, name)
    return metadata and tonumber(metadata[name]) or Config.Needs.Start
end

local function getOxygen(ped, playerId)
    if not IsPedSwimmingUnderWater(ped) then return 100 end
    return math.max(0, math.min(100, GetPlayerUnderwaterTimeRemaining(playerId) * 10))
end

local function collectState()
    local ped = cache.ped
    local playerId = PlayerId()
    local data = JJ.GetPlayerData()
    local metadata = data and data.metadata

    return {
        visible = IsHudVisible(),
        mapOpened = IsPauseMenuActive(),
        health = math.max(0, GetEntityHealth(ped) - 100),
        armour = GetPedArmour(ped),
        hunger = getNeed(metadata, 'hunger'),
        thirst = getNeed(metadata, 'thirst'),
        stamina = math.max(0, 100 - GetPlayerSprintStaminaRemaining(playerId)),
        oxygen = getOxygen(ped, playerId),
        microphoneOn = NetworkIsPlayerTalking(playerId),
        micro = voiceMode * 33 + 1,
    }
end

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceMode = mode
end)

-- Lo lanza ox_inventory al usar un objeto con status, como la comida y la bebida
AddEventHandler('jj:client:statusRequested', function(values)
    TriggerServerEvent('jj_hud:server:addStatus', values)
end)

RegisterCommand('hud', function()
    hidden = not hidden
end, false)
TriggerEvent('chat:addSuggestion', '/hud', 'Oculta o muestra el HUD')

CreateThread(function()
    while true do
        if isSpawned() then
            setupMinimap()
        end
        updateMinimap()
        SendNUIMessage({ type = 'updateState', data = collectState() })
        Wait(UPDATE_INTERVAL)
    end
end)

-- Sin comer ni beber se pierde vida poco a poco, si está activado

if Config.Needs.Damage then
    CreateThread(function()
        while true do
            Wait(Config.Needs.DamageInterval * 1000)
            local data = isSpawned() and JJ.GetPlayerData()
            local metadata = data and data.metadata
            if metadata and (getNeed(metadata, 'hunger') <= 0 or getNeed(metadata, 'thirst') <= 0) then
                local health = GetEntityHealth(cache.ped)
                if health > 100 then
                    SetEntityHealth(cache.ped, health - Config.Needs.DamageAmount)
                end
            end
        end
    end)
end
