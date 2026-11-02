local config = require "shared.main"
local Voice = exports['pma-voice']
local globalRadioActive = false
local activeGlobalSpeakers = {}


local function sendToTablet(action, data)
    TriggerEvent('jj_policetablet:client:sendNuiMessage', {
        action = action,
        data = data
    })
end

local function clearGlobalRadioSpeakers()
    for src, _ in pairs(activeGlobalSpeakers) do
        Voice:toggleVoice(src, false, 'radio')
        local data = {
            source = src,
            talking = false
        }
        SendNUIMessage({
            action = "setRadioTalking",
            data = data
        })
        sendToTablet("setRadioTalking", data)
    end
    activeGlobalSpeakers = {}
end

local baseAnimations = {
    { dict = 'cellphone@',            name = 'cellphone_call_listen_base', displayName = 'Hablar en oreja' },
    { dict = 'random@arrests',        name = 'generic_radio_enter',        displayName = 'Hablar en hombro' },
    { dict = 'anim@cop_mic_pose_002', name = 'chest_mic',                  displayName = 'Hablar en pecho' },
}

local radioAnim = {
    dict = GetResourceKvpString("radio_anim_dict") or "random@arrests",
    anim = GetResourceKvpString("radio_anim_name") or "generic_radio_enter",
}

-- El prop lo pone jj_radio; aqui solo guardamos la preferencia y se la mandamos
local radioPropEnabled = GetResourceKvpString("radio_prop_enabled") ~= "false"

CreateThread(function()
    while not IsLoggedIn() do
        Wait(600)
    end
    Wait(2000)

    local PlayerData = GetPlayerData()

    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then
        return
    end

    Voice:setRadioTalkAnim(radioAnim.dict, radioAnim.anim)
    -- jj_radio pone el prop segun la anim; sin esto al entrar usa la ultima que el guardo y sale en la mano equivocada
    TriggerEvent('jj_policedispatch:radioAnimChanged', radioAnim.dict, radioAnim.anim)
    TriggerEvent('jj_policedispatch:radioPropChanged', radioPropEnabled)
    local savedVol = GetResourceKvpString("radio_volume")
    if savedVol then
        local volNum = tonumber(savedVol)
        if volNum then
            Voice:setRadioVolume(volNum)
        end
    end
end)

local function getGlobalFreqZone(zone)
    for k, v in pairs(config.radioInfo) do
        if zone == v.zone then
            return v.globalFreq
        end
    end
    return false
end

local function connectToRadioVoice(frequency, zone)
    if LocalPlayer.state.disableRadio == 1 then return end
    local globalFreq = getGlobalFreqZone(zone)

    Voice:setRadioChannel(frequency)
    Voice:setVoiceProperty('radioEnabled', true)
    Voice:setVoiceProperty('micClicks', true)

    if globalFreq then
        TriggerServerEvent('jj_policedispatch:registerGlobalRadio', globalFreq)
        globalRadioActive = true
    else
        TriggerServerEvent('jj_policedispatch:unRegisterGlobalRadio')
        if globalRadioActive or next(activeGlobalSpeakers) then
            globalRadioActive = false
            clearGlobalRadioSpeakers()
        end
    end
end

local function disconnectFromRadioVoice()
    Voice:removePlayerFromRadio()
    Voice:setVoiceProperty('radioEnabled', false)
    Voice:setVoiceProperty('micClicks', false)
    TriggerServerEvent('jj_policedispatch:unRegisterGlobalRadio')
    if globalRadioActive or next(activeGlobalSpeakers) then
        globalRadioActive = false
        clearGlobalRadioSpeakers()
    end
end

local function muteRadioVoice(freq, isMuted, zone)
    LocalPlayer.state.disableRadio = isMuted and 1 or 0
    TriggerServerEvent('jj_policedispatch:server:setMemberMuted', isMuted)
    if isMuted then
        disconnectFromRadioVoice()
    else
        connectToRadioVoice(freq, zone)
    end
end

RegisterNuiCallback("fetchRadioData", function(data, cb)
    local formatData = {
        zones = {},
        channels = {}
    }
    local formatChannels = {}

    for i = 1, #config.radioInfo do
        local config = config.radioInfo[i]
        for _, channel in pairs(config.channels) do
            channel.zone = config.zone
            channel.members = {}
            table.insert(formatChannels, channel)
        end
        table.insert(formatData.zones, config.zone)
    end
    formatData.channels = formatChannels
    cb(formatData)
end)

RegisterNuiCallback("fetchMembers", function(data, cb)
    local agents = lib.callback.await('jj_policedispatch:callback:getMembers', false)
    cb(agents)
end)


RegisterNuiCallback("fetchAgentData", function(data, cb)
    local PlayerData = GetPlayerData()
    local color = exports['jj_policedispatch']:getSelectedColor() or 0

    local agent = {
        source = GetPlayerServerId(PlayerId()),
        id_group = LocalPlayer.state.radio_id_group or "",
        citizenid = PlayerData.citizenid,
        fullname = ("%s %s (%s)"):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname,
            PlayerData.metadata.badge_number or "000"),
        divisions = PlayerData.metadata.divisions or {},
        rank = PlayerData.job.grade.name,
        status = LocalPlayer.state.radio_status ~= false,
        isMuted = LocalPlayer.state.radio_isMuted == true,
        color = color,
    }

    cb(agent)
end)

RegisterNuiCallback("leaveChannel", function(data, cb)
    local channelId = data.id
    local zone = data.zone
    disconnectFromRadioVoice()
    local success = lib.callback.await('jj_policedispatch:callback:leaveChannel', false, channelId, zone)
    cb(success)
end)


RegisterNuiCallback("joinChannel", function(data, cb)
    local channelId = data.id
    local frequency = data.freq
    local zone = data.zone
    connectToRadioVoice(frequency, zone)
    local success = lib.callback.await('jj_policedispatch:callback:joinChannel', false, channelId, zone)
    cb(success)
end)


RegisterNuiCallback("moveMember", function(data, cb)
    local channelId = data.id
    local success = lib.callback.await('jj_policedispatch:callback:moveMember', false, data.citizenid, data.lastId,
        data.newId, data.newFreq, data.zone)
    cb(success)
end)

local isDirectTalking = false
local activeDirectTalkReceivers = {}

local function handleDirectTalkDown(data)
    if not data then return 'error' end
    local targetChannelId = data.channelId or data.id
    local targetFreq = tonumber(data.freq)
    if not targetChannelId and not targetFreq then return 'error' end

    TriggerServerEvent('jj_policedispatch:server:startDirectTalk', targetChannelId, targetFreq)
    return 'ok'
end

local function handleDirectTalkUp(data)
    TriggerServerEvent('jj_policedispatch:server:stopDirectTalk')
    return 'ok'
end

RegisterNuiCallback('directTalkDown', function(data, cb)
    local res = handleDirectTalkDown(data)
    cb(res)
end)

RegisterNuiCallback('directTalkUp', function(data, cb)
    local res = handleDirectTalkUp(data)
    cb(res)
end)

RegisterNetEvent('jj_policedispatch:client:startDirectTalkSpeaker', function(targetServerIds)
    isDirectTalking = true
    Voice:playMicClicks(true)

    local mySrc = GetPlayerServerId(PlayerId())
    local talkData = {
        source = mySrc,
        talking = true
    }
    SendNUIMessage({
        action = "setRadioTalking",
        data = talkData
    })
    sendToTablet("setRadioTalking", talkData)

    MumbleClearVoiceTargetPlayers(1)
    for _, targetSrc in ipairs(targetServerIds) do
        MumbleAddVoiceTargetPlayerByServerId(1, targetSrc)
    end

    local dict = radioAnim.dict
    local anim = radioAnim.anim
    RequestAnimDict(dict)

    CreateThread(function()
        LocalPlayer.state:set("radioActive", true, true)
        TriggerEvent("pma-voice:radioActive", true)

        while isDirectTalking do
            local ped = PlayerPedId()
            if HasAnimDictLoaded(dict) then
                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, 2.0, -1, 50, 2.0, false, false, false)
                end
            end
            SetControlNormal(0, 249, 1.0)
            SetControlNormal(1, 249, 1.0)
            SetControlNormal(2, 249, 1.0)
            Wait(0)
        end

        RemoveAnimDict(dict)
        LocalPlayer.state:set("radioActive", false, true)
        TriggerEvent("pma-voice:radioActive", false)
    end)
end)

RegisterNetEvent('jj_policedispatch:client:stopDirectTalkSpeaker', function()
    isDirectTalking = false
    Voice:playMicClicks(false)

    local mySrc = GetPlayerServerId(PlayerId())
    local talkData = {
        source = mySrc,
        talking = false
    }
    SendNUIMessage({
        action = "setRadioTalking",
        data = talkData
    })
    sendToTablet("setRadioTalking", talkData)

    MumbleClearVoiceTargetPlayers(1)
    ExecuteCommand('+radiotalk')
    Wait(50)
    ExecuteCommand('-radiotalk')
end)

RegisterNetEvent('jj_policedispatch:client:receiveDirectTalk', function(speakerSrc, enabled)
    if enabled then
        activeDirectTalkReceivers[speakerSrc] = true
        Voice:toggleVoice(speakerSrc, true, 'radio')
        Voice:playMicClicks(true)
        local data = {
            source = speakerSrc,
            talking = true
        }
        SendNUIMessage({
            action = "setRadioTalking",
            data = data
        })
        sendToTablet("setRadioTalking", data)
    else
        activeDirectTalkReceivers[speakerSrc] = nil
        Voice:toggleVoice(speakerSrc, false, 'radio')
        Voice:playMicClicks(false)
        local data = {
            source = speakerSrc,
            talking = false
        }
        SendNUIMessage({
            action = "setRadioTalking",
            data = data
        })
        sendToTablet("setRadioTalking", data)
    end
end)


RegisterNetEvent('jj_policedispatch:client:refreshChannels', function(infoChannels)
    SendNUIMessage({
        action = "refreshMembersChannels",
        data = infoChannels
    })
    sendToTablet("refreshMembersChannels", infoChannels)
end)

RegisterNetEvent('jj_policedispatch:client:joinFreqOnMove', function(freq, zone)
    connectToRadioVoice(freq, zone)
end)

RegisterNUICallback('setStatus', function(data, cb)
    if not cache.vehicle then
        TriggerServerEvent('jj_policedispatch:server:setMemberStatus', data.status)
    else
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.0, true)
        local playersServerId = {}
        for k, v in pairs(players) do
            playersServerId[#playersServerId + 1] = GetPlayerServerId(v.id)
        end
        TriggerServerEvent('jj_policedispatch:server:setMemberStatusGroup', data.status, playersServerId)
    end
    cb('ok')
end)

RegisterNetEvent('jj_policedispatch:client:memberStatusChanged', function(data)
    SendNUIMessage({
        action = 'memberStatusChanged',
        data = data,
    })
    sendToTablet("memberStatusChanged", data)
end)

RegisterNUICallback('setMuted', function(data, cb)
    local isMuted = data.isMuted
    local zone = data.zone
    local freq = data.freq
    muteRadioVoice(freq, isMuted, zone)
    cb(true)
end)

RegisterNetEvent('jj_policedispatch:client:memberMutedChanged', function(data)
    SendNUIMessage({
        action = 'memberMutedChanged',
        data = data,
    })
    sendToTablet("memberMutedChanged", data)
end)

RegisterNUICallback('changeRadioVolume', function(data, cb)
    local vol = data.volume
    if vol then
        Voice:setRadioVolume(vol)
        SetResourceKvp("radio_volume", tostring(vol))
    end
    cb('ok')
end)

RegisterNUICallback('changeRadioAnim', function(data, cb)
    local dict = data.dict
    local anim = data.name
    if dict and anim then
        radioAnim.dict = dict
        radioAnim.anim = anim
        SetResourceKvp("radio_anim_dict", dict)
        SetResourceKvp("radio_anim_name", anim)
        Voice:setRadioTalkAnim(dict, anim)
        TriggerEvent('jj_policedispatch:radioAnimChanged', dict, anim)
    end
    cb('ok')
end)

RegisterNUICallback('changeRadioProp', function(data, cb)
    radioPropEnabled = data.enabled == true
    SetResourceKvp("radio_prop_enabled", tostring(radioPropEnabled))
    TriggerEvent('jj_policedispatch:radioPropChanged', radioPropEnabled)
    cb('ok')
end)

RegisterNUICallback('getRadioProp', function(data, cb)
    cb({ enabled = radioPropEnabled })
end)

RegisterNUICallback('getRadioAnim', function(data, cb)
    local savedDict = GetResourceKvpString("radio_anim_dict") or "random@arrests"
    local savedAnim = GetResourceKvpString("radio_anim_name") or "generic_radio_enter"
    cb({
        selected = { dict = savedDict, name = savedAnim },
        animations = baseAnimations
    })
end)

RegisterNUICallback('getRadioVolume', function(data, cb)
    local currentVol = 50
    local savedVol = GetResourceKvpString("radio_volume")
    if savedVol then
        currentVol = tonumber(savedVol) or 50
    else
        local v = Voice:getRadioVolume()
        if v then
            currentVol = v
        end
        if type(currentVol) == "number" and currentVol <= 1.0 then
            currentVol = math.floor(currentVol * 100)
        end
    end
    cb(currentVol)
end)

OnJobUpdate(function(JobInfo)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    disconnectFromRadioVoice()
    TriggerServerEvent('jj_policedispatch:memberOffDuty')
end)

OnDutyChange(function(duty)
    local PlayerData = GetPlayerData()
    if PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance" then return end
    if duty then
        SendNUIMessage({
            action = "refreshData"
        })
        sendToTablet("refreshData", {})
    else
        disconnectFromRadioVoice()
        TriggerServerEvent('jj_policedispatch:memberOffDuty')
    end
end)

OnJobUpdate(function(job)
    if job.name == "police" or job.name == "ambulance" then
        SendNUIMessage({
            action = "refreshData"
        })
        sendToTablet("refreshData", {})
    end
end)

OnPlayerLoaded(function()
    SendNUIMessage({
        action = "refreshData"
    })
    sendToTablet("refreshData", {})
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(plySource, enabled)
    local data = {
        source = plySource,
        talking = enabled
    }
    SendNUIMessage({
        action = "setRadioTalking",
        data = data
    })
    sendToTablet("setRadioTalking", data)
end)

local globalRadioData = {}
RegisterNetEvent('jj_policedispatch:syncGlobalRadio', function(members)
    globalRadioData = members
end)

RegisterNetEvent('jj_policedispatch:client:memberTalking', function(src, talking)
    if talking then
        if not globalRadioActive then return end
        activeGlobalSpeakers[src] = true
        Voice:toggleVoice(src, true, 'radio')
        Voice:playMicClicks(true)
    else
        activeGlobalSpeakers[src] = nil
        Voice:toggleVoice(src, false, 'radio')
        Voice:playMicClicks(false)
    end
    local data = {
        source = src,
        talking = talking
    }
    SendNUIMessage({
        action = "setRadioTalking",
        data = data
    })
    sendToTablet("setRadioTalking", data)
end)

local radioPressed = false

local function stopGlobalRadioTalk()
    if radioPressed then
        radioPressed = false
        MumbleClearVoiceTargetPlayers(1)
        StopAnimTask(PlayerPedId(), radioAnim.dict, radioAnim.anim, -4.0)
        TriggerServerEvent('jj_policedispatch:server:memberTalking', false, globalRadioData)
    end
end

local function startGlobalRadioTalk()
    if LocalPlayer.state.isDead then return end
    if LocalPlayer.state.disableRadio == 1 then return end
    if not globalRadioActive then return end

    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job then return end
    if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end

    if not radioPressed then
        radioPressed = true
        MumbleClearVoiceTargetPlayers(1)
        for id in pairs(globalRadioData) do
            MumbleAddVoiceTargetPlayerByServerId(1, tonumber(id))
        end
        local dict = radioAnim.dict
        local anim = radioAnim.anim
        lib.requestAnimDict(dict)
        TriggerServerEvent('jj_policedispatch:server:memberTalking', true, globalRadioData)

        CreateThread(function()
            local checkFailed = false
            while radioPressed do
                local ped = PlayerPedId()
                if IsPedShooting(ped) or LocalPlayer.state.isDead or LocalPlayer.state.disableRadio == 1 or not globalRadioActive then
                    checkFailed = true
                    break
                end

                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, 2.0, -1, 50, 2.0, false,
                        false,
                        false)
                end

                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
                Wait(0)
            end

            if checkFailed then
                stopGlobalRadioTalk()
            end
        end)
    end
end

RegisterCommand('+radiotalk_jj_global', function()
    startGlobalRadioTalk()
end)

RegisterCommand('-radiotalk_jj_global', function()
    stopGlobalRadioTalk()
end)

RegisterKeyMapping('+radiotalk_jj_global', 'Hablar radio SAPD', 'keyboard', "LMENU")

local mandoTalkActive = false

local function getMandoInfo()
    for _, info in ipairs(config.radioInfo) do
        for _, channel in ipairs(info.channels) do
            if channel.id == "especiales_mando" or channel.id == "mando" then
                return channel.id, channel.freq
            end
        end
    end
    return "especiales_mando", 120
end

local function startMandoRadioTalk()
    if LocalPlayer.state.isDead then return end
    if LocalPlayer.state.disableRadio == 1 then return end

    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job then return end
    if (PlayerData.job.name ~= "police" and PlayerData.job.name ~= "ambulance") or not PlayerData.job.onduty then return end

    if not mandoTalkActive then
        mandoTalkActive = true
        local mandoId, mandoFreq = getMandoInfo()
        TriggerServerEvent('jj_policedispatch:server:startDirectTalk', mandoId, mandoFreq)
    end
end

local function stopMandoRadioTalk()
    if mandoTalkActive then
        mandoTalkActive = false
        TriggerServerEvent('jj_policedispatch:server:stopDirectTalk')
    end
end

RegisterCommand('+radiotalk_mando', function()
    startMandoRadioTalk()
end, false)

RegisterCommand('-radiotalk_mando', function()
    stopMandoRadioTalk()
end, false)

RegisterKeyMapping('+radiotalk_mando', 'Hablar a mando (Radio)', 'keyboard', '')

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Voice:removePlayerFromRadio()
        Voice:setVoiceProperty('radioEnabled', false)
    end
end)

exports("fetchRadioData", function()
    local formatData = {
        zones = {},
        channels = {}
    }
    local formatChannels = {}

    for i = 1, #config.radioInfo do
        local conf = config.radioInfo[i]
        for _, channel in pairs(conf.channels) do
            channel.zone = conf.zone
            channel.members = {}
            table.insert(formatChannels, channel)
        end
        table.insert(formatData.zones, conf.zone)
    end
    formatData.channels = formatChannels
    return formatData
end)

exports("fetchMembers", function()
    return lib.callback.await('jj_policedispatch:callback:getMembers', false)
end)

exports("fetchAgentData", function()
    local PlayerData = GetPlayerData()
    local color = exports['jj_policedispatch']:getSelectedColor() or 0

    local agent = {
        source = GetPlayerServerId(PlayerId()),
        id_group = LocalPlayer.state.radio_id_group or "",
        citizenid = PlayerData.citizenid,
        fullname = ("%s %s (%s)"):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname,
            PlayerData.metadata.badge_number or "000"),
        divisions = PlayerData.metadata.divisions or {},
        rank = PlayerData.job.grade.name,
        status = LocalPlayer.state.radio_status ~= false,
        isMuted = LocalPlayer.state.radio_isMuted == true,
        color = color,
    }
    return agent
end)

exports("leaveChannel", function(data)
    local channelId = data.id
    local zone = data.zone
    disconnectFromRadioVoice()
    local success = lib.callback.await('jj_policedispatch:callback:leaveChannel', false, channelId, zone)
    return success
end)

exports("joinChannel", function(data)
    local channelId = data.id
    local frequency = data.freq
    local zone = data.zone
    connectToRadioVoice(frequency, zone)
    local success = lib.callback.await('jj_policedispatch:callback:joinChannel', false, channelId, zone)
    return success
end)

exports("moveMember", function(data)
    local success = lib.callback.await('jj_policedispatch:callback:moveMember', false, data.citizenid, data.lastId,
        data.newId, data.newFreq, data.zone)
    return success
end)

exports("directTalkDown", function(data)
    return handleDirectTalkDown(data)
end)

exports("directTalkUp", function(data)
    return handleDirectTalkUp(data)
end)

exports("setStatus", function(data)
    if not cache.vehicle then
        TriggerServerEvent('jj_policedispatch:server:setMemberStatus', data.status)
    else
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 2.0, true)
        local playersServerId = {}
        for k, v in pairs(players) do
            playersServerId[#playersServerId + 1] = GetPlayerServerId(v.id)
        end
        TriggerServerEvent('jj_policedispatch:server:setMemberStatusGroup', data.status, playersServerId)
    end
    return 'ok'
end)

exports("setMuted", function(data)
    local isMuted = data.isMuted
    local zone = data.zone
    local freq = data.freq
    muteRadioVoice(freq, isMuted, zone)
    return true
end)

exports("globalTalkDown", function(data)
    startGlobalRadioTalk()
    return 'ok'
end)

exports("globalTalkUp", function(data)
    stopGlobalRadioTalk()
    return 'ok'
end)

exports("mandoTalkDown", function(data)
    startMandoRadioTalk()
    return 'ok'
end)

exports("mandoTalkUp", function(data)
    stopMandoRadioTalk()
    return 'ok'
end)
