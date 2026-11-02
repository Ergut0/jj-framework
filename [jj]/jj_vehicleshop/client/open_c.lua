local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local PED_DISTANCE = 60.0
local INTERACT_DISTANCE = 2.5

-- El servidor lo vuelve a comprobar al abrir: esto solo evita ofrecer lo que no se puede usar
local function canUseSeller(seller)
    if not seller.restricted then return true end
    local data = JJ.GetPlayerData()
    local jobName = data and data.job and data.job.name
    for _, job in pairs(seller.restricted) do
        if job == jobName then
            return true
        end
    end
    return false
end

local function createSeller(seller)
    local hash = lib.requestModel(seller.npc)
    local ped = CreatePed(4, hash, seller.coords.x, seller.coords.y, seller.coords.z, seller.heading, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityHeading(ped, seller.heading)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    if Config.UseTarget then
        exports.ox_target:addLocalEntity(ped, {
            {
                distance = INTERACT_DISTANCE,
                label = Lang.open_target,
                icon = 'fa-solid fa-car',
                canInteract = function()
                    return canUseSeller(seller)
                end,
                onSelect = function()
                    OpenDealership(seller.concesionario)
                end,
            },
        })
    end
    return ped
end

-- El vendedor solo existe con el jugador cerca
for _, seller in ipairs(Config.Peds) do
    if Config.Dealerships[seller.concesionario] then
        local ped = nil
        local showingPrompt = false

        local function setPrompt(show)
            if show ~= showingPrompt then
                showingPrompt = show
                if show then
                    lib.showTextUI(Lang.open_prompt)
                else
                    lib.hideTextUI()
                end
            end
        end

        lib.points.new({
            coords = seller.coords,
            distance = PED_DISTANCE,
            onEnter = function()
                ped = createSeller(seller)
            end,
            onExit = function()
                setPrompt(false)
                if ped and DoesEntityExist(ped) then
                    DeleteEntity(ped)
                end
                ped = nil
            end,
            nearby = function(self)
                if Config.UseTarget then return end

                local inRange = self.currentDistance <= INTERACT_DISTANCE and canUseSeller(seller) and not IsNuiFocused()
                setPrompt(inRange)
                if inRange and IsControlJustPressed(0, 38) then
                    setPrompt(false)
                    OpenDealership(seller.concesionario)
                end
            end,
        })
    else
        print(('[jj_vehicleshop] El vendedor de %s no tiene concesionario en Config.Dealerships'):format(seller.concesionario))
    end
end
