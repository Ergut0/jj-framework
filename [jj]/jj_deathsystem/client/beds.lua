local isInHospitalBed = false
local canLeaveBed = false
local bedOccupyingData = nil
local bedOccupying = nil
local closestBed = nil
local bedObject = nil
local cam = nil
local Healing = 1

local inBedDict = "anim@gangops@morgue@table@"
local inBedAnim = "body_search"

local getOutDict = 'switch@franklin@bed'
local getOutAnim = 'sleep_getup_rubeyes'

local currentPrompt = nil
local inChecking = false
local actualZone = "Sur"
local zonesCreated = false
local systemCreated = false

local function setPrompt(text)
    if currentPrompt ~= text then
        currentPrompt = text
        lib.showTextUI(text)
    end
end

local function clearPrompt()
    if currentPrompt then
        currentPrompt = nil
        lib.hideTextUI()
    end
end

local function CreateZones()
    Player(cache.serverId).state:set('actualZone', "Sur", true)

    if zonesCreated then return end
    zonesCreated = true

    lib.zones.poly({
        points = {
            vector3(8364.33, -2655.58, 319.92),
            vector3(-8291.71, 4070.78, 319.92),
            vector3(-2111.16, 11231.96, 319.92),
            vector3(5793.62, 8659.23, 319.92),
        },
        thickness = 2000.0,
        onEnter = function()
            Player(cache.serverId).state:set('actualZone', "Norte", true)
        end,
        onExit = function()
            Player(cache.serverId).state:set('actualZone', "Sur", true)
        end,
        debug = false,
    })
end

local function GetAvailableBed(bedId)
    local pos = GetEntityCoords(PlayerPedId())
    local retval = nil
    local z = LocalPlayer.state.actualZone or "Sur"

    if actualZone then
        z = actualZone
    end

    if bedId == nil then
        for k, bed in pairs(Config.Info["beds"][z]) do
            if not bed.taken then
                if #(pos - vector3(bed.coords.x, bed.coords.y, bed.coords.z)) < 500 then
                    retval = k
                    break
                end
            end
        end
    else
        local bed = Config.Info["beds"][z][bedId]
        if bed and not bed.taken then
            if #(pos - vector3(bed.coords.x, bed.coords.y, bed.coords.z)) < 500 then
                retval = bedId
            end
        end
    end
    return retval or (math.random(1, #Config.Info["beds"][z]))
end

local function SetClosestBed()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local z = LocalPlayer.state.actualZone or "Sur"
    if actualZone then
        z = actualZone
    end
    local current = nil
    local dist = nil
    for k, bed in pairs(Config.Info["beds"][z]) do
        local dist2 = #(pos - vector3(bed.coords.x, bed.coords.y, bed.coords.z))
        if current then
            if dist2 < dist then
                current = k
                dist = dist2
            end
        else
            dist = dist2
            current = k
        end
    end
    if current ~= closestBed and not isInHospitalBed then
        closestBed = current
    end
end

local function SetBedCam()
    isInHospitalBed = true
    canLeaveBed = false
    local player = PlayerPedId()

    if IsPedDeadOrDying(player) then
        local pos = GetEntityCoords(player, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(player), true, false)
    end

    if bedOccupyingData.model then
        bedObject = GetClosestObjectOfType(bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z,
            1.0, bedOccupyingData.model, false, false, false)
        FreezeEntityPosition(bedObject, true)
    end

    SetEntityCoords(player, bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z + 0.02)

    Wait(500)

    lib.requestAnimDict(inBedDict)

    CreateThread(function()
        while isInHospitalBed do
            TaskPlayAnim(player, inBedDict, inBedAnim, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
            Wait(250)
        end
    end)

    TaskPlayAnim(player, inBedDict, inBedAnim, 8.0, 1.0, -1, 1, 0, 0, 0, 0)
    SetEntityHeading(player, bedOccupyingData.coords.w)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)
    AttachCamToPedBone(cam, player, 31085, 0, 1.0, 1.0, true)
    SetCamFov(cam, 90.0)
    local heading = GetEntityHeading(player)
    heading = (heading > 180) and heading - 180 or heading + 180
    SetCamRot(cam, -45.0, 0.0, heading, 2)
end

local function LeaveBed()
    local player = PlayerPedId()
    isInHospitalBed = false

    lib.requestAnimDict(getOutDict)

    SetEntityInvincible(player, false)
    SetEntityHeading(player, bedOccupyingData.coords.w + 90)
    TaskPlayAnim(player, getOutDict, getOutAnim, 100.0, 1.0, -1, 8, -1, 0, 0, 0)
    Wait(4000)
    ClearPedTasks(player)
    TriggerServerEvent('jj_deathsystem:server:LeaveBed')
    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    cam = nil
    bedOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
end

RegisterNetEvent('jj_deathsystem:client:SetBed', function(zone, id, isTaken)
    local beds = Config.Info["beds"][zone]
    if not beds or not beds[id] then
        return
    end
    beds[id].taken = isTaken
end)

RegisterNetEvent('jj_deathsystem:checkin', function()
    if lib.progressBar({
            duration = 2000,
            label = "Haciendo la revision",
            useWhileDead = true,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            allowCuffed = true,
            allowFalling = true,
            allowRagdoll = true,
            allowSwimming = true,
        }) then
        local bedId = GetAvailableBed()
        if bedId then
            Player(cache.serverId).state:set('checkingIn', true, true)
            revivePlayer(true, actualZone)
        else
            Notify("Las camillas estan ocupadas")
        end
        inChecking = false
    else
        inChecking = false
        Notify("Cancelado")
    end
end)

RegisterNetEvent('jj_deathsystem:client:SendToBed', function(id, data, isRevive, from)
    actualZone = from
    bedOccupying = id
    bedOccupyingData = data
    Player(cache.serverId).state:set('checkingIn', false, true)
    SetBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            Notify("Estas siendo curado, espera un rato")
            Wait(Config.AIHealTimer * 1000)
            canLeaveBed = true
        else
            canLeaveBed = true
            while isInHospitalBed do
                Wait(Healing * 3000)
                if isInHospitalBed then
                    local health = GetEntityHealth(PlayerPedId())
                    if health <= 199 then
                        SetEntityHealth(PlayerPedId(), health + 1)
                    end
                end
            end
        end
    end)
end)

RegisterNetEvent('jj_deathsystem:beds', function()
    TriggerServerEvent("jj_deathsystem:server:SendToBed", closestBed, actualZone)
end)

local function InsidePointBed(infoPoint)
    actualZone = infoPoint
    if isInHospitalBed then
        if not canLeaveBed then
            clearPrompt()
            return
        end
        setPrompt("E - Para salir de la camilla")
        if IsControlJustReleased(0, 38) then
            clearPrompt()
            LeaveBed()
        end
    else
        setPrompt("E - Para subir a la camilla")
        if IsControlJustPressed(0, 38) then
            if GlobalState.camillasActivadas ~= nil and not GlobalState.camillasActivadas then
                Notify("Hay sanitarios de servicio en la zona", "error")
                return
            end
            SetClosestBed()
            TriggerEvent('jj_deathsystem:beds')
        end
    end
end

local function InsidePointCheck(infoPoint)
    actualZone = infoPoint
    setPrompt("E - Hablar con el doctor")
    if IsControlJustReleased(0, 38) then
        local PlayerData = JJ.GetPlayerData()
        if not PlayerData or PlayerData.accounts.bank < Config.BillCost then
            Notify("No tienes dinero para pagar la factura", "error")
            return
        end
        if inChecking then
            Notify("Ya estas en proceso de revision", "error")
            return
        end
        inChecking = true
        TriggerEvent('jj_deathsystem:checkin')
    end
end

local function CreateSystem()
    if systemCreated then return end
    systemCreated = true

    for zone, bedsTable in pairs(Config.Info["beds"]) do
        for k, bed in pairs(bedsTable) do
            lib.zones.box({
                coords = vector3(bed.coords.x, bed.coords.y, bed.coords.z),
                size = vector3(2.1, 2.0, 4.0),
                debug = false,
                inside = function()
                    InsidePointBed(zone)
                end,
                onExit = clearPrompt
            })
        end
    end

    for zone, checksTable in pairs(Config.Info["checking"]) do
        for k, check in pairs(checksTable) do
            lib.zones.sphere({
                coords = vector3(check.coords.x, check.coords.y, check.coords.z),
                radius = 3.0,
                debug = false,
                inside = function()
                    InsidePointCheck(zone)
                end,
                onExit = clearPrompt
            })

            local ped = check.npc
            local pedHash = GetHashKey(ped)
            lib.requestModel(pedHash)
            local npc = CreatePed(4, pedHash, check.coords.x, check.coords.y, check.coords.z, check.coords.w, false, true)
            SetEntityAsMissionEntity(npc, true, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetEntityInvincible(npc, true)
            FreezeEntityPosition(npc, true)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end
    end
end

OnPlayerReady(function()
    CreateZones()
    CreateSystem()
end)
