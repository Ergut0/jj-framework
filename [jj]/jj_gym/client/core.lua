local cantDoExercise = false
local startLoopRun = false

local function UpdateStats()
    lib.callback('jj_gym:getStats', false, function(stats)
        if stats then
            StatSetInt(GetHashKey('MP0_SHOOTING_ABILITY'), 0, 1)
            for k, v in pairs(stats) do
                if Config.wantLoopRun then
                    if v.stamina >= 100 then
                        startLoopRun = true
                    end
                end
                for stat, value in pairs(v) do
                    if Config.Stats[stat] then
                        Config.Stats[stat].executeAction(value)
                    end
                end
            end
        end
    end)
end

CreateThread(function()
    while true do
        if startLoopRun then
            SetPedMoveRateOverride(cache.ped, 1.1)
        end
        Wait(300)
    end
end)

local ProgressColor = {
    GREEN = 'green.5',
    YELLOW = 'yellow.5',
    RED = 'red.5'
}


local function getProgressColor(percent)
    if percent >= 75 then
        return ProgressColor.GREEN
    elseif percent > 25 then
        return ProgressColor.YELLOW
    else
        return ProgressColor.RED
    end
end

-- El escenario de pesas hace que el juego cree un prop en red en la mano del jugador.
-- Se deja mientras dure la animación y se borra solo cuando el jugador ya no la está haciendo
-- (al terminar o al cancelarla), porque si no se queda en el suelo.
function StartScenarioWithProp(scenario, propModel)
    local ped = cache.ped

    -- jj_things/server/blockProps.lua no cancela los props de quien tenga este estado;
    -- la espera da tiempo a que el servidor lo reciba antes de que aparezca la pesa
    LocalPlayer.state:set('gymPesas', true, true)
    Wait(500)

    TaskStartScenarioInPlace(ped, scenario, 0, true)

    CreateThread(function()
        local props = {}
        local limit = GetGameTimer() + 5000
        while not IsPedUsingScenario(ped, scenario) and GetGameTimer() < limit do Wait(100) end

        -- solo se apuntan los props de ese modelo que estén enganchados a este jugador
        while IsPedUsingScenario(ped, scenario) do
            for _, obj in ipairs(GetGamePool('CObject')) do
                if GetEntityModel(obj) == propModel and IsEntityAttachedToEntity(obj, ped) then
                    props[obj] = true
                end
            end
            Wait(500)
        end

        for obj in pairs(props) do
            if DoesEntityExist(obj) then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end

        LocalPlayer.state:set('gymPesas', false, true)
    end)
end

-- Cada cliente ve su propia copia de la pesa de los demás jugadores, y esa copia no desaparece
-- cuando el dueño borra la suya. Por eso cada cliente limpia las pesas sueltas que queden junto
-- a los puntos de pesas; las que alguien tiene en la mano no se tocan.
CreateThread(function()
    local model = `prop_curl_bar_01`
    Wait(1000)
    while true do
        local wait = 5000
        local coords = GetEntityCoords(cache.ped)
        local near = {}
        for _, point in ipairs(Config.Gym_Points["brazos"].coords) do
            if #(coords - point) < 60.0 then near[#near + 1] = point end
        end

        if #near > 0 then
            wait = 2000
            for _, obj in ipairs(GetGamePool('CObject')) do
                if GetEntityModel(obj) == model and GetEntityAttachedTo(obj) == 0 then
                    local objCoords = GetEntityCoords(obj)
                    for i = 1, #near do
                        if #(objCoords - near[i]) < 5.0 then
                            if NetworkGetEntityIsNetworked(obj) and not NetworkHasControlOfEntity(obj) then
                                NetworkRequestControlOfEntity(obj)
                            else
                                SetEntityAsMissionEntity(obj, true, true)
                                DeleteEntity(obj)
                            end
                            break
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

local function StartExercise(_type, statsExp)
    if exports.ox_inventory:GetItemCount(Config.GymItem) >= 1 then
        if cantDoExercise then
            Notify('No puedes hacer todavía ejercicio, descansa un poco', "error")
            return
        end
        for k, stats in pairs(statsExp) do
            lib.callback.await('jj_gym:modifyStats', false, stats.name, stats.how_many)
        end
        cantDoExercise = true
        _type:AnimationToExecute()
        SetTimeout(70000, function()
            cantDoExercise = false
            Notify("Ya puedes hacer deporte de nuevo", "success")
        end)
    else
        Notify('Necesitas una membresía para hacer deporte', 'error')
    end
end

local threadStarted = false

local startThread = function()
	if threadStarted then return end
	threadStarted = true

	for _, info in pairs(Config.Blips) do
		info.blip = AddBlipForCoord(info.x, info.y, info.z)
		SetBlipSprite(info.blip, info.id)
		SetBlipDisplay(info.blip, 4)
		SetBlipScale(info.blip, 0.7)
		SetBlipColour(info.blip, 0)
		SetBlipAsShortRange(info.blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(info.title)
		EndTextCommandSetBlipName(info.blip)
	end

    for k, dataCoords in pairs(Config.RentBike) do

        local pedGym = GetHashKey("a_m_y_runner_02")
        local success = lib.requestModel(pedGym)

        if success then
            local ped = CreatePed(4, pedGym, dataCoords.x, dataCoords.y, dataCoords.z-1, dataCoords.w, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end


        local rentPoints = lib.points.new({
            coords = dataCoords,
            distance = 1.5,
            onEnter = function(self)
                lib.showTextUI("Alquilar bicicleta")
            end,
            onExit = function(self)
                lib.hideTextUI()
            end,
            nearby = function(self)
                DrawMarker(20, dataCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                if IsControlJustReleased(0, 38) then
                    OpenBikeMenu()
                end
            end
        })
    end


    for k, dataCoords in pairs(Config.GymMenu) do

        local pedGym = GetHashKey("a_m_y_runner_02")
        local success = lib.requestModel(pedGym)

        if success then
            local ped = CreatePed(4, pedGym, dataCoords.x, dataCoords.y, dataCoords.z-1, dataCoords.w, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
        end

        local gymPoints = lib.points.new({
            coords = dataCoords,
            distance = 2.0,
            onEnter = function(self)
                lib.showTextUI("Hablar con la persona")
            end,
            onExit = function(self)
                lib.hideTextUI()
            end,
            nearby = function(self)
                -- DrawMarker(20, dataCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                if IsControlJustReleased(0, 38) then
                    OpenGymMenu()
                end
            end
        })
    end

    for k, data in pairs(Config.Gym_Points) do
        local getInfoStats = k
        local getExpStats = data.experience
        for i, dataCoords in pairs(data.coords) do
            local gymPoints = lib.points.new({
                infoStat = getInfoStats,
                coords = dataCoords,
                distance = 1.5,
                onEnter = function(self)
                    lib.showTextUI(data.label)
                end,
                onExit = function(self)
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    DrawMarker(20, dataCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 255, false, false, false, true, false, false, false)
                    if IsControlJustReleased(0, 38) then
                        StartExercise(Config.Gym_Points[self.infoStat], getExpStats)
                    end
                end
            })
        end
    end
end

CreateThread(function()
    lib.registerContext({
        id = 'gym_menu',
        title = 'Gimnasio',
        canClose = true,
        options = {
            {
                title = 'Membresía',
                description = 'Consulta o compra tu membresía',
                onSelect = function()
                    lib.showContext('gym_ship_menu')
                end
            }
        }
    })

    lib.registerContext({
        id = 'gym_ship_menu',
        title = 'Gimnasio - Membresía',
        canClose = true,
        options = {
            {
                title = 'Comprar Membresía ($50)',
                description = 'Compra tu membresía del gimnasio por $50',
                onSelect = function()
                    TriggerServerEvent('jj_gym:buyMembership')
                end
            }
        }
    })

    lib.registerContext({
        id = 'bike_menu',
        title = 'Alquilar bicicleta',
        canClose = true,
        options = {
            {
                title = 'Patinete electrico',
                description = 'Tiene un precio de $100',
                onSelect = function()
                    rentBike('serv_electricscooter', 100)
                end
            },
            {
                title = 'BMX',
                description = 'Tiene un precio de $25',
                onSelect = function()
                    rentBike('bmx', 25)
                end
            },
            {
                title = 'Cruiser',
                description = 'Tiene un precio de $30',
                onSelect = function()
                    rentBike('cruiser', 30)
                end
            },
            {
                title = 'Fixter',
                description = 'Tiene un precio de $35',
                onSelect = function()
                    rentBike('fixter', 35)
                end
            },
            {
                title = 'Scorcher',
                description = 'Tiene un precio de $40',
                onSelect = function()
                    rentBike('scorcher', 40)
                end
            }
        }
    })

    function rentBike(bikeType, price)
        local payed = exports['jj_paymethods']:PayMethods(price, true)
        if payed then
            for k, v in pairs(Config.RentBike) do
                local pointCoords = v
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(pointCoords - playerCoords)
                if distance < 5.0 then
                    SpawnVehicle(bikeType, nil, playerCoords)
                    break
                end
            end
        end
    end

    function OpenGymMenu()
        lib.showContext('gym_menu')
    end

    function OpenBikeMenu()
        lib.showContext('bike_menu')
    end
end)

OnPlayerReady(function()
    UpdateStats()
    startThread()
end)
