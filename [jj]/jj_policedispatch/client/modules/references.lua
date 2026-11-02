local config = lib.load('shared.main')
local UnitsRadar = {
    serverID = GetPlayerServerId(PlayerId()),
    sentCallsign = false,
    active = {},
    color = {},
    blipId = {},
    asigned = {},
    _panic = {},
    peds = {},
    lastPos = {},
    scopeSince = {},
    __index = self
}

local showtags = false
local selectedBlip = 1
local selectedColor = 0

local function CheckPerms()
    local playerData = GetPlayerData()
    if not playerData then return end
    for k, v in pairs(config.jobsAccess) do
        if v == playerData.job.name and playerData.job.onduty then
            return true
        end
    end
end

OnDutyChange(function(duty)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    local blipPlayer = GetMainPlayerBlipId()
    local coords = GetEntityCoords(cache.ped)
    if duty then
        SetBlipScale(blipPlayer, 0.0)
        SetBlipCoords(blipPlayer, 0.0, 0.0, -1000.0)
    else
        SetBlipScale(blipPlayer, 0.7)
        SetBlipCoords(blipPlayer, coords.x, coords.y, coords.z)
    end
    lib.callback.await('jj_policedispatch:refreshReference', false, duty)
end)

OnJobUpdate(function(job)
    local blipPlayer = GetMainPlayerBlipId()
    local coords = GetEntityCoords(cache.ped)
    if job.name == "police" or job.name == "ambulance" then
        lib.callback.await('jj_policedispatch:refreshReference', false, job.onduty)
        if job.onduty then
            SetBlipScale(blipPlayer, 0.0)
            SetBlipCoords(blipPlayer, 0.0, 0.0, -1000.0)
        end
    else
        SetBlipScale(blipPlayer, 0.7)
        SetBlipCoords(blipPlayer, coords.x, coords.y, coords.z)
        lib.callback.await('jj_policedispatch:refreshReference', false, false)
    end
end)

OnPlayerLoaded(function()
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    local blipPlayer = GetMainPlayerBlipId()
    local coords = GetEntityCoords(cache.ped)
    local duty = PlayerData.job.onduty
    if duty then
        SetBlipScale(blipPlayer, 0.0)
        SetBlipCoords(blipPlayer, 0.0, 0.0, -1000.0)
    else
        SetBlipScale(blipPlayer, 0.7)
        SetBlipCoords(blipPlayer, coords.x, coords.y, coords.z)
    end
    lib.callback.await('jj_policedispatch:refreshReference', false, duty)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local PlayerData = GetPlayerData()
        if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
        local blipPlayer = GetMainPlayerBlipId()
        local coords = GetEntityCoords(cache.ped)
        local duty = PlayerData.job.onduty
        if duty then
            SetBlipScale(blipPlayer, 0.0)
            SetBlipCoords(blipPlayer, 0.0, 0.0, -1000.0)
        else
            SetBlipScale(blipPlayer, 0.7)
            SetBlipCoords(blipPlayer, coords.x, coords.y, coords.z)
        end
        lib.callback.await('jj_policedispatch:refreshReference', false, duty)
    end
end)

lib.addKeybind({
    name = 'references:showtagsgps',
    description = 'Ver unidades en el GPS',
    defaultKey = 'NUMPAD7',
    onPressed = function(self)
        if CheckPerms() then
            showtags = not showtags
            DisplayPlayerNameTagsOnBlips(showtags)
        end
    end
})

function UnitsRadar:updateAll(activeBlips)
    for k, v in pairs(activeBlips) do
        if v.coords then self:update(v.source, v.coords.x, v.coords.y, v.coords.z, v.heading, v.type, v.number, v.asig, v.bId, v.department) end
    end
end

local SCOPE_ENTER_DELAY = 2000

local function getLocalPed(playerID)
    local player = GetPlayerFromServerId(playerID)
    local ped = (player ~= -1) and GetPlayerPed(player) or 0
    if ped ~= 0 and DoesEntityExist(ped) then
        return ped
    end
end

function UnitsRadar:styleBlip(playerID)
    local blip = self.active[playerID]
    SetBlipScale(blip, 0.9)
    SetBlipSprite(blip, self.blipId[playerID])
    SetBlipHiddenOnLegend(blip, false)
    --SetBlipShowCone(blip, true) -- Mostrar cono
    ShowHeadingIndicatorOnBlip(blip, self.peds[playerID] ~= nil)
    ShowHeightOnBlip(blip, false)
    SetBlipDisplay(blip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(self.asigned[playerID])
    EndTextCommandSetBlipName(blip)
    SetBlipColour(blip, self.color[playerID])
    SetBlipCategory(blip, 7)
end

function UnitsRadar:swapBlip(playerID, ped)
    local old = self.active[playerID]
    local pos = self.lastPos[playerID]
    if ped then
        self.active[playerID] = AddBlipForEntity(ped)
    elseif pos then
        self.active[playerID] = AddBlipForCoord(pos.x, pos.y, pos.z)
    else
        return
    end
    self.peds[playerID] = ped
    self.scopeSince[playerID] = nil
    self:styleBlip(playerID)
    if old then RemoveBlip(old) end
end

function UnitsRadar:update(playerID, x, y, z, heading, type, number, asig, bId, department)
    playerID = tonumber(playerID)
    if not playerID or not x then return end

    local color = tonumber(type) or 0
    local bId = tonumber(bId) or 1

    local myData = GetPlayerData()

    if myData and ((myData.job.name ~= 'ambulance' and department == 'safmd') or (myData.job.name == 'ambulance' and department ~= 'safmd')) then
        return
    end

    if not self.peds[playerID] then
        self.lastPos[playerID] = vector3(x, y, z)
    end

    if self.active[playerID] == nil then
        self.asigned[playerID] = asig or "Sin asignar"
        self.blipId[playerID] = bId or 1
        self.color[playerID] = color or 0
        self:swapBlip(playerID, getLocalPed(playerID))
    elseif not self.peds[playerID] and not self.scopeSince[playerID] then
        SetBlipCoords(self.active[playerID], x, y, z)
    end
    if self.blipId[playerID] ~= bId or self.asigned[playerID] ~= asig then
        self.asigned[playerID] = asig or "Sin asignar"
        self.blipId[playerID] = bId
        SetBlipSprite(self.active[playerID], bId)
        SetBlipColour(self.active[playerID], color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(asig)
        EndTextCommandSetBlipName(self.active[playerID])
    end
    if self.color[playerID] ~= color then
        self.color[playerID] = color
        SetBlipColour(self.active[playerID], color)
    end
    SetBlipCategory(self.active[playerID], 7)
end

function UnitsRadar:remove(playerID, removeDistant)
    playerID = tonumber(playerID)
    if not playerID then return end

    if self.active[playerID] then
        RemoveBlip(self.active[playerID])
        self.active[playerID] = nil
    end
    self.peds[playerID] = nil
    self.lastPos[playerID] = nil
    self.scopeSince[playerID] = nil
end

CreateThread(function()
    while true do
        local now = GetGameTimer()
        for playerID, blip in pairs(UnitsRadar.active) do
            local ped = getLocalPed(playerID)
            local trackedPed = UnitsRadar.peds[playerID]

            if trackedPed then
                if ped == trackedPed then
                    UnitsRadar.lastPos[playerID] = GetEntityCoords(ped)
                else
                    UnitsRadar:swapBlip(playerID, ped)
                end
            elseif ped then
                local pos = GetEntityCoords(ped)
                UnitsRadar.lastPos[playerID] = pos
                SetBlipCoords(blip, pos.x, pos.y, pos.z)
                local since = UnitsRadar.scopeSince[playerID]
                if not since then
                    UnitsRadar.scopeSince[playerID] = now
                elseif now - since >= SCOPE_ENTER_DELAY then
                    UnitsRadar:swapBlip(playerID, ped)
                end
            else
                UnitsRadar.scopeSince[playerID] = nil
            end
        end
        Wait(100)
    end
end)

function UnitsRadar:removeAll()
    for k, v in pairs(self.active) do
        self:remove(k)
    end
end

local stopBigmap = nil
local map = false
local mapInFalse = false
local sleep = 0


lib.addKeybind({
    name = 'references:bigmap',
    description = 'Mostrar el mapa grande',
    defaultKey = 'GRAVE',
    onPressed = function(self)
        if CheckPerms() then
            map = not map
        end
    end,
})


Citizen.CreateThread(function()
    while true do
        sleep = 500
        if (map) then
            sleep = 0
            mapInFalse = false
            SetBigmapActive(true, false)
        else
            if mapInFalse == false then
                mapInFalse = true
                SetBigmapActive(false, false)
            end
        end
        Wait(sleep)
    end
end)

-- Citizen.CreateThread(function()
--     while true do
--         Wait(2000)
--         local blipPlayer = GetMainPlayerBlipId()
--         local coords = GetEntityCoords(PlayerPedId())
--         if CheckPerms() then
--             SetBlipScale(blipPlayer, 0.0)
--             SetBlipCoords(blipPlayer, 0.0, 0.0, -1000.0)
--         else
--             SetBlipScale(blipPlayer, 0.7)
--             SetBlipCoords(blipPlayer, coords.x, coords.y, coords.z)
--         end
--     end
-- end)




RegisterNetEvent('jj_policedispatch:removeUnit')
AddEventHandler('jj_policedispatch:removeUnit', function(playerID, unsubscribe)
    UnitsRadar:remove(playerID)
end)

RegisterNetEvent('jj_policedispatch:removeBlips')
AddEventHandler('jj_policedispatch:removeBlips', function()
    UnitsRadar:removeAll()
end)

RegisterNetEvent('jj_policedispatch:updateBlips')
AddEventHandler('jj_policedispatch:updateBlips', function(blips)
    UnitsRadar:updateAll(blips)
end)


OnPlayerLoaded(function()
    local t = 100
    DisplayRadar(true)
    SetBigmapActive(true, true)
    while t > 0 do
        t = t - 1
        SetRadarAsExteriorThisFrame()
        Wait(0)
    end
    SetBigmapActive(false, false)
    ToggleStealthRadar(false)
end)


AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if CheckPerms() then
            TriggerServerEvent('jj_policedispatch:addUnit', 0, 1)
        end
    end
end)

OnPlayerLoaded(function()
    if CheckPerms() then
        TriggerServerEvent('jj_policedispatch:addUnit', 0, 1)
    end
end)

local function changeBlip(id)
    selectedBlip = id
    if not cache.vehicle then
        TriggerServerEvent('jj_policedispatch:server:UpdateBlip', selectedColor, selectedBlip)
    else
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.0, true)
        local playersServerId = {}
        for k, v in pairs(players) do
            playersServerId[#playersServerId + 1] = GetPlayerServerId(v.id)
        end
        TriggerServerEvent('jj_policedispatch:server:UpdateBlipGroup', selectedColor, selectedBlip,
            playersServerId)
    end
end

local function changeColour(id)
    selectedColor = id
    if not cache.vehicle then
        TriggerServerEvent('jj_policedispatch:server:UpdateBlip', selectedColor, selectedBlip)
    else
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.0, true)
        local playersServerId = {}
        for k, v in pairs(players) do
            playersServerId[#playersServerId + 1] = GetPlayerServerId(v.id)
        end
        TriggerServerEvent('jj_policedispatch:server:UpdateBlipGroup', selectedColor, selectedBlip, playersServerId)
    end
end

RegisterNuiCallback("selectBlipId", function(data, cb)
    changeBlip(data.blipId)
    cb(true)
end)

RegisterNuiCallback("selectBlipColor", function(data, cb)
    changeColour(data.colorId)
    cb(true)
end)

RegisterNuiCallback("changeRefStatus", function(data, cb)
    if data.refTurned then
        TriggerServerEvent("jj_policedispatch:server:disableOwnReference")
    else
        TriggerServerEvent("jj_policedispatch:server:enableOwnReference")
    end
    cb(true)
end)

RegisterNetEvent('jj_policedispatch:client:refreshStatusNUI', function(blipInfo)
    SendNUIMessage({ action = "refreshBlipGroup", data = blipInfo })
end)

exports("changeColour", changeColour)
exports("getSelectedColor", function()
    return selectedColor
end)
