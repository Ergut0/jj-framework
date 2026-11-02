-- Formato antiguo del DNI inicial: los que ya se entregaron se siguen leyendo
exports.ox_inventory:displayMetadata({
    id = 'ID',
    fullname = 'Nombre Completo',
    birthdate = 'Fecha de Nacimiento',
})

local uiReady = false
local screenData = nil
local characters = {}
local draftIndex = nil
local busy = false

-- Nombre del sitio, para enseñar dónde se dejó al personaje
local function getPlace(position)
    if not position or not position.x then return nil end

    local x, y, z = position.x + 0.0, position.y + 0.0, position.z + 0.0
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(x, y, z))
    local zone = GetLabelText(GetNameOfZone(x, y, z))

    if street ~= '' and zone ~= 'NULL' then
        return ('%s, %s'):format(street, zone)
    end
    return street ~= '' and street or (zone ~= 'NULL' and zone or nil)
end

local function sendOpen()
    if not uiReady or not screenData then return end

    SendNUIMessage({ action = 'open', data = screenData })
    SetNuiFocus(true, true)
end

RegisterNUICallback('uiReady', function(_, cb)
    uiReady = true
    cb({ success = true })
    sendOpen()
end)

local function start()
    local data = lib.callback.await('jj_personajes:enter', false)
    if not data then return end

    characters = data.characters

    local list = {}
    for index, character in ipairs(characters) do
        list[index] = {
            identifier = character.identifier,
            name = character.name,
            birthdate = character.birthdate,
            nationality = character.nationality,
            gender = character.gender,
            job = character.job,
            grade = character.grade,
            cash = character.cash,
            bank = character.bank,
            secondsAgo = character.secondsAgo,
            place = getPlace(character.position),
        }
    end

    Stage.fade(true, 0)
    Stage.start(data.slots)
    for index = 1, data.slots do
        local character = characters[index]
        if character then
            Stage.setCharacter(index, character)
        else
            Stage.setGhost(index, 0)
        end
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    Stage.fade(false, 1200)

    screenData = {
        characters = list,
        slots = data.slots,
        maxSlots = Config.MaxSlots,
        minAge = data.minAge,
        maxAge = data.maxAge,
    }
    sendOpen()
end

-- Cambia el ped del jugador por el modelo y el aspecto del personaje cargado
local function setPlayerAppearance(character)
    local model = character.model
    if not IsModelInCdimage(model) or not pcall(lib.requestModel, model) then
        model = Config.BaseOutfits[character.gender == 1 and 1 or 0].model
        lib.requestModel(model)
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    Stage.applyAppearance(ped, character.skin, character.gender)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
end

local function arrive(name, target)
    local place = getPlace(target)

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'arrival', name = name, place = place })
    Stage.arrive(target)
    SendNUIMessage({ action = 'close' })
    JJ.SetSpawned()
end

RegisterNUICallback('focusSlot', function(data, cb)
    cb({ success = true })
    local index = tonumber(data and data.index)
    if index then Stage.focus(math.tointeger(index), data.greet == true) end
end)

RegisterNUICallback('enterCharacter', function(data, cb)
    if busy then return cb({ success = false }) end
    busy = true

    local character = lib.callback.await('jj_personajes:load', false, data and data.identifier)
    if not character then
        busy = false
        JJ.Notify('No se ha podido cargar el personaje. Contacta con la administración', 'error')
        return cb({ success = false })
    end

    cb({ success = true })

    Stage.fade(true, 500)
    Stage.stop()
    setPlayerAppearance(character)
    arrive(character.name, character.position)
    busy = false
end)

RegisterNUICallback('startDraft', function(data, cb)
    cb({ success = true })
    local index = tonumber(data and data.index)
    if not index then return end

    draftIndex = math.tointeger(index)
    Stage.setDraft(draftIndex, data.gender == 1 and 1 or 0)
    Stage.focus(draftIndex)
end)

RegisterNUICallback('previewGender', function(data, cb)
    cb({ success = true })
    if draftIndex then Stage.setDraft(draftIndex, data and data.gender == 1 and 1 or 0) end
end)

RegisterNUICallback('cancelDraft', function(_, cb)
    cb({ success = true })
    if draftIndex then
        Stage.setGhost(draftIndex, 0)
        draftIndex = nil
    end
end)

RegisterNUICallback('createCharacter', function(data, cb)
    if busy then return cb({ success = false }) end
    busy = true

    local result = lib.callback.await('jj_personajes:create', false, data)
    if not result or not result.character then
        busy = false
        JJ.Notify(result and result.error or 'No se ha podido crear el personaje', 'error')
        return cb({ success = false })
    end

    cb({ success = true })

    Stage.fade(true, 500)
    Stage.stop()
    setPlayerAppearance(result.character)
    lib.callback.await('jj_personajes:leave', false)
    arrive(result.character.name, Config.NewCharacterSpawn)
    busy = false
end)

CreateThread(function()
    if JJ.IsLoaded() then return end

    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
    Wait(50)
    start()
end)

-- No dejar el ratón atrapado ni la cámara puesta si el recurso se para
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    Stage.stop()
    RenderScriptCams(false, false, 0, true, false)
end)
