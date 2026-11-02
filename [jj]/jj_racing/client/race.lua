-- Carrera en curso (cliente): salida, checkpoints, marcadores, HUD y finalizacion.
-- El cliente solo detecta el paso por los checkpoints y lo reporta; el servidor decide
-- el orden, los tiempos, las posiciones y los premios. Los bucles solo existen durante una carrera.

Race = {}

local S = { active = false }

local function sendHud(action, data)
    SendNUIMessage({ action = 'hud:' .. action, data = data })
end

function Race.IsActive()
    return S.active
end

-- Blips ---------------------------------------------------------------------------------------

local function removeBlip(b)
    if b and DoesBlipExist(b) then RemoveBlip(b) end
end

local function clearBlips()
    removeBlip(S.blipNext)
    removeBlip(S.blipAfter)
    S.blipNext, S.blipAfter = nil, nil
    for _, b in ipairs(S.extraBlips or {}) do removeBlip(b) end
    S.extraBlips = {}
end

local function makeBlip(cp, colour, scale, route)
    local b = AddBlipForCoord(cp.x, cp.y, cp.z)
    SetBlipSprite(b, 1)
    SetBlipColour(b, colour)
    SetBlipScale(b, scale)
    SetBlipAsShortRange(b, false)
    if route then
        SetBlipRoute(b, true)
        SetBlipRouteColour(b, colour)
    end
    return b
end

local function currentTargets()
    local cur = S.normals[S.nextSeq]
    local after
    if S.nextSeq < S.total then
        after = S.normals[S.nextSeq + 1]
    elseif S.lap < S.laps then
        after = S.normals[1]
    end
    return cur, after
end

local function isFinish()
    return S.nextSeq == S.total and S.lap == S.laps
end

local function updateBlips()
    clearBlips()
    if S.finished then return end
    local cur, after = currentTargets()
    if cur then S.blipNext = makeBlip(cur, Config.Markers.blipColour, 0.95, true) end
    if after then S.blipAfter = makeBlip(after, 0, 0.6, false) end
    for _, sc in ipairs(S.shortcutsFrom[S.nextSeq - 1] or {}) do
        S.extraBlips[#S.extraBlips + 1] = makeBlip(sc, 5, 0.7, false)
    end
    for _, pit in ipairs(S.pits) do
        S.extraBlips[#S.extraBlips + 1] = makeBlip(pit, 3, 0.7, false)
    end
end

-- Marcadores ------------------------------------------------------------------------------------

local function drawCheckpoint(cp, col, finish)
    DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cp.radius * 2.0, cp.radius * 2.0, cp.height, col.r, col.g, col.b, col.a, false, false, 2, false, nil, nil, false)
    if finish then
        DrawMarker(4, cp.x, cp.y, cp.z + cp.height * 0.5 + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 3.0, 255, 255, 255, 200, true, true, 2, false, nil, nil, false)
    else
        DrawMarker(20, cp.x, cp.y, cp.z + cp.height * 0.5 + 1.5, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 2.0, 2.0, 2.0, col.r, col.g, col.b, 220, true, true, 2, false, nil, nil, false)
    end
end

local function drawSmall(cp, col)
    DrawMarker(1, cp.x, cp.y, cp.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cp.radius * 2.0, cp.radius * 2.0, cp.height * 0.6, col.r, col.g, col.b, col.a, false, false, 2, false, nil, nil, false)
end

-- Reporte de checkpoints -------------------------------------------------------------------------------

local function report(cp, kind)
    local now = GetGameTimer()
    if S.reported[cp.idx] and now - S.reported[cp.idx] < 1500 then return end
    S.reported[cp.idx] = now
    TriggerServerEvent('races:server:checkpoint', kind, cp.idx)

    if kind == 'pit' then return end
    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    -- Avance optimista: el servidor reconcilia con el evento `progress`
    if kind == 'sc' then
        S.nextSeq = cp.linkTo
    else
        S.nextSeq = cp.seq + 1
    end
    if S.nextSeq > S.total then
        if S.lap >= S.laps then
            S.awaitingFinish = true
        else
            S.lap = S.lap + 1
            S.nextSeq = 1
        end
    end
    if not S.awaitingFinish then updateBlips() else clearBlips() end
end

--- Dibuja y detecta un checkpoint. Devuelve true si esta dentro del rango de dibujado.
local function consider(pc, cp, kind, col, finish, small)
    local dx, dy = pc.x - cp.x, pc.y - cp.y
    if math.sqrt(dx * dx + dy * dy) > Config.Markers.drawDistance then return false end
    if small then drawSmall(cp, col) else drawCheckpoint(cp, col, finish) end
    if kind and dx * dx + dy * dy <= cp.radius * cp.radius and math.abs(pc.z - cp.z) <= cp.height then report(cp, kind) end
    return true
end

local function raceLoop()
    CreateThread(function()
        while S.active and S.started and not S.finished do
            local near = false
            local pc = GetEntityCoords(PlayerPedId())

            if not S.awaitingFinish then
                local cur, after = currentTargets()
                if cur and consider(pc, cur, 'cp', isFinish() and Config.Markers.finish or Config.Markers.next, isFinish()) then near = true end
                if after and consider(pc, after, nil, Config.Markers.after, false, true) then near = true end
                local shortcuts = S.shortcutsFrom[S.nextSeq - 1]
                if shortcuts then
                    for i = 1, #shortcuts do
                        if consider(pc, shortcuts[i], 'sc', Config.Markers.shortcut, false) then near = true end
                    end
                end
            end
            for i = 1, #S.pits do
                if consider(pc, S.pits[i], 'pit', Config.Markers.pit, false, true) then near = true end
            end

            Wait(near and 0 or 250)
        end
    end)
end

-- Ciclo de vida --------------------------------------------------------------------------------------------

--- Libera todo. `keepHud` mantiene el HUD visible (banner de meta) hasta que lo oculte un temporizador.
function Race.Cleanup(keepHud)
    local wasActive = S.active
    S.active = false
    clearBlips()
    if S.vehicle and DoesEntityExist(S.vehicle) then FreezeEntityPosition(S.vehicle, false) end
    if Ghost then Ghost.Stop() end
    if wasActive and not keepHud then sendHud('hide') end
    S = { active = false }
end

local function prepare(p)
    local receivedAt = GetGameTimer()
    if S.active then Race.Cleanup(false) end
    UI.Close()

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end

    S = {
        active = true, started = false, finished = false, lobbyId = p.lobbyId, laps = p.laps, total = p.normals, lap = 1, nextSeq = 1,
        collisions = p.collisions, you = p.you, vehicle = veh, reported = {}, extraBlips = {}, shortcutsFrom = {}, pits = {}, normals = {},
        mode = p.mode,
    }
    for _, cp in ipairs(p.checkpoints) do
        if cp.kind == 'normal' then
            S.normals[cp.seq] = cp
        elseif cp.kind == 'shortcut' then
            S.shortcutsFrom[cp.linkFrom] = S.shortcutsFrom[cp.linkFrom] or {}
            table.insert(S.shortcutsFrom[cp.linkFrom], cp)
        elseif cp.kind == 'pit' and p.pit then
            S.pits[#S.pits + 1] = cp
        end
    end

    -- Colocacion en la parrilla (con fundido para ocultar el salto)
    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do Wait(10) end
    local s = p.slot
    SetEntityCoordsNoOffset(veh, s.x, s.y, s.z, false, false, false)
    SetEntityHeading(veh, s.h)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    FreezeEntityPosition(veh, true)
    SetGameplayCamRelativeHeading(0.0)
    Wait(250)
    DoScreenFadeIn(400)

    updateBlips()
    sendHud('show', {
        locale = Config.Locale, trackName = p.trackName, laps = p.laps, totalCp = p.normals, mode = p.mode,
        you = p.you,
    })

    -- Cuenta atras: solo es visual; la salida la da el servidor con `go`
    local endAt = receivedAt + p.countdown
    CreateThread(function()
        local last = -1
        while S.active and not S.started do
            local remaining = endAt - GetGameTimer()
            local n = math.ceil(remaining / 1000)
            if n ~= last and n > 0 then
                last = n
                sendHud('countdown', { n = n })
                PlaySoundFrontend(-1, '3_2_1', 'HUD_MINI_GAME_SOUNDSET', true)
            end
            if remaining < -8000 then
                Notify(L('err_generic'), 'error')
                Race.Cleanup(false)
                return
            end
            Wait(50)
        end
    end)
end

RegisterNetEvent('races:client:prepare', function(p)
    if type(p) == 'table' then prepare(p) end
end)

RegisterNetEvent('races:client:go', function(data)
    if not S.active or S.started then return end
    S.started = true
    if S.vehicle and DoesEntityExist(S.vehicle) then FreezeEntityPosition(S.vehicle, false) end
    PlaySoundFrontend(-1, 'GO', 'HUD_MINI_GAME_SOUNDSET', true)
    sendHud('go', {})
    if Ghost then Ghost.Start(data and data.racers or {}, S.collisions, S.you) end
    raceLoop()
end)

-- Progreso confirmado por el servidor (autoridad): reconcilia el avance optimista
RegisterNetEvent('races:client:progress', function(d)
    if not S.active or type(d) ~= 'table' then return end
    local localKey, serverKey = S.lap * 10000 + S.nextSeq, d.lap * 10000 + d.nextSeq
    if d.resync or serverKey > localKey then
        S.lap, S.nextSeq = d.lap, d.nextSeq
        S.awaitingFinish = false
        updateBlips()
    end
    if d.finished then
        S.finished = true
        S.awaitingFinish = false
        clearBlips()
        PlaySoundFrontend(-1, 'Checkpoint_Finish', 'HUD_MINI_GAME_SOUNDSET', true)
        sendHud('finish', { time = d.finishTime, order = d.finishOrder, bestLap = d.bestLap })
        return
    end
    if d.lapTime then PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true) end
    sendHud('progress', { lap = d.lap, cp = d.nextSeq - 1, lapTime = d.lapTime, bestLap = d.bestLap, total = d.total })
end)

RegisterNetEvent('races:client:standings', function(d)
    if S.active and type(d) == 'table' then sendHud('standings', d) end
end)

-- Pit stop: reparacion y combustible
RegisterNetEvent('races:client:pit', function()
    if not S.active then return end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return end
    if Config.Pit.repair then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
    end
    if Config.Pit.refuel then SetVehicleFuelLevel(veh, 100.0) end
    Notify(L('n_pit'), 'success', 3000)
    sendHud('pit', {})
end)

-- Descalificacion o DNF: el piloto queda fuera, la carrera sigue para el resto
RegisterNetEvent('races:client:dq', function(reason)
    if not S.active then return end
    S.finished = true
    clearBlips()
    sendHud('out', { reason = reason })
end)

RegisterNetEvent('races:client:abort', function(reason)
    Race.Cleanup(false)
    if reason == 'leave' then return end
    Notify(L(reason == 'kick' and 'n_kicked' or 'n_race_aborted'), 'error', 6000)
end)

RegisterNetEvent('races:client:end', function()
    local wasActive = S.active
    Race.Cleanup(true)
    if wasActive then
        SetTimeout(6000, function()
            if not S.active then sendHud('hide') end
        end)
    end
end)

-- Abandonar la carrera desde el juego
if Config.LeaveCommand and Config.LeaveCommand ~= '' then
    RegisterCommand(Config.LeaveCommand, function()
        JJ.TriggerCallback('races:srv:leaveRace', function(res)
            if res and not res.ok then Notify(res.error or L('err_generic'), 'error') end
        end, {})
    end, false)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Race.Cleanup(false)
    DoScreenFadeIn(0)
end)
