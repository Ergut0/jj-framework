JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

MyGang = nil
PublicGangs = {} -- [id] = datos públicos de la banda

local territoryBlips = {}
local activePoints = {}
local worldLoaded = false

local READY_RETRY = 2000
local READY_ATTEMPTS = 30

function Notify(description, kind)
    lib.notify({ description = description, type = kind or 'inform' })
end

-- Los callbacks de los menús de ox_lib no pueden esperar: lo que espera va en su propio hilo
function Async(callback, ...)
    local args = { ... }
    CreateThread(function()
        callback(table.unpack(args))
    end)
end

-- Barrios: un círculo en el mapa para cada banda, visible para todos

local function clearTerritories()
    for _, blip in ipairs(territoryBlips) do
        RemoveBlip(blip)
    end
    territoryBlips = {}
end

local function createTerritory(gang)
    if gang.radius <= 0 then return end

    local area = AddBlipForRadius(gang.x, gang.y, gang.z, gang.radius + 0.0)
    SetBlipColour(area, gang.blip)
    SetBlipAlpha(area, Config.TerritoryAlpha)
    SetBlipHighDetail(area, true)
    territoryBlips[#territoryBlips + 1] = area

    -- El círculo no tiene nombre: esta marca es la que lo muestra en el mapa
    local center = AddBlipForCoord(gang.x, gang.y, gang.z)
    SetBlipSprite(center, 310)
    SetBlipColour(center, gang.blip)
    SetBlipScale(center, 0.6)
    SetBlipAsShortRange(center, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Barrio: %s'):format(gang.label))
    EndTextCommandSetBlipName(center)
    territoryBlips[#territoryBlips + 1] = center
end

RegisterNetEvent('jj_gangs:client:world', function(gangs, loaded)
    worldLoaded = worldLoaded or loaded == true
    PublicGangs = {}
    clearTerritories()
    for _, gang in ipairs(gangs) do
        PublicGangs[gang.id] = gang
        createTerritory(gang)
    end
    RefreshGraffitiBlips()
end)

-- Puntos de la banda

local actions = {
    boss = function()
        Async(OpenBossMenu)
    end,
    stash = function(point)
        TriggerServerEvent('jj_gangs:server:openStash', point.id)
    end,
    wardrobe = function()
        TriggerEvent('illenium-appearance:client:openOutfitMenu')
    end,
    lab = function(point)
        Async(UseLab, point)
    end,
}

local function clearPoints()
    for _, active in ipairs(activePoints) do
        if active.showingPrompt then
            lib.hideTextUI()
        end
        active.point:remove()
    end
    activePoints = {}
end

local function createPoint(data)
    -- El garaje lo dibuja y lo gestiona jj_garages
    local action = actions[data.type]
    if not action then return end

    local definition = Config.PointTypes[data.type]
    local active = { showingPrompt = false }

    local function setPrompt(show)
        if show ~= active.showingPrompt then
            active.showingPrompt = show
            if show then
                lib.showTextUI(definition.prompt)
            else
                lib.hideTextUI()
            end
        end
    end

    active.point = lib.points.new({
        coords = vector3(data.x, data.y, data.z),
        distance = 8.0,
        onExit = function()
            setPrompt(false)
        end,
        nearby = function(self)
            DrawMarker(2, data.x, data.y, data.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 250, 204, 21, 170, false, true, 2, false, nil, nil, false)

            local inRange = self.currentDistance <= Config.PointDistance and not IsNuiFocused() and not IsBusy()
            setPrompt(inRange)
            if inRange and IsControlJustPressed(0, 38) then
                setPrompt(false)
                action(data)
            end
        end,
    })
    activePoints[#activePoints + 1] = active
end

RegisterNetEvent('jj_gangs:client:setGang', function(gang)
    clearPoints()
    MyGang = gang
    if gang then
        for _, point in ipairs(gang.points) do
            createPoint(point)
        end
    end
end)

-- Banda del jugador para otros recursos, como el menú personal, o nil si no tiene
exports('getGang', function()
    if not MyGang then return nil end
    local rank = Config.Ranks[MyGang.rank] or {}
    return {
        id = MyGang.id,
        name = MyGang.label,
        label = MyGang.label,
        rank = MyGang.rank,
        rankName = rank.name,
        isBoss = rank.isBoss == true,
    }
end)

-- Avisos a la banda: notificación con la calle y una marca temporal en el mapa

local function getStreetName(coords)
    local street = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(street)
end

RegisterNetEvent('jj_gangs:client:alert', function(alert)
    local coords = alert.coords
    lib.notify({
        title = alert.title,
        description = ('%s, en %s'):format(alert.message, getStreetName(coords)),
        type = 'warning',
        duration = 10000,
    })

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(alert.title)
    EndTextCommandSetBlipName(blip)
    SetTimeout(Config.AlertBlipTime * 1000, function()
        RemoveBlip(blip)
    end)
end)

-- Arranque

-- Al reiniciar el recurso, este cliente puede pedir los datos antes de que el servidor los haya leído
local function ready()
    worldLoaded = false
    CreateThread(function()
        for _ = 1, READY_ATTEMPTS do
            TriggerServerEvent('jj_gangs:server:ready')
            Wait(READY_RETRY)
            if worldLoaded then return end
        end
        print('[jj_gangs] El servidor no ha enviado los datos de las bandas')
    end)
end

AddEventHandler('jj:client:playerSpawned', ready)

if JJ.IsSpawned() or LocalPlayer.state.isLoggedIn == true then
    ready()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearPoints()
    end
end)
