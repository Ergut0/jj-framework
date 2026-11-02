local BoneMapping = {
    [31086] = 'HEAD',
    [39317] = 'NECK',
    [7019]  = 'HEAD',
    [52301] = 'RFOOT',
    [14201] = 'LFOOT',
    [57005] = 'RHAND',
    [60309] = 'RHAND',
    [18905] = 'LHAND',
    [36864] = 'RLEG',
    [51826] = 'RLEG',
    [63931] = 'LLEG',
    [58271] = 'LLEG',
    [28252] = 'RARM',
    [40269] = 'RARM',
    [2992]  = 'RARM',
    [61163] = 'LARM',
    [45509] = 'LARM',
    [32139] = 'LARM',
    [23553] = 'UPPER_BODY',
    [24816] = 'UPPER_BODY',
    [24817] = 'UPPER_BODY',
    [24818] = 'UPPER_BODY',
    [10706] = 'UPPER_BODY',
    [64729] = 'UPPER_BODY',
}

local Injuries = {}

local function UpdateInventoryInjuries()
    local injuryList = {}
    for boneName, isInjured in pairs(Injuries) do
        if isInjured then
            injuryList[#injuryList + 1] = boneName
        end
    end
    SendNUIMessage({ action = 'setInjuries', data = injuryList })
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end

    local victim = data[1]
    if tonumber(victim) ~= tonumber(cache.ped) then return end

    local weaponHash = data[7]
    if weaponHash == -842959696 or weaponHash == 3452007600 then
        Injuries['LLEG'] = true
        Injuries['RLEG'] = true
        UpdateInventoryInjuries()
        return
    end

    local found, lastBone = GetPedLastDamageBone(cache.ped)
    if found and lastBone ~= 0 then
        local boneName = BoneMapping[lastBone]
        if boneName then
            Injuries[boneName] = true
            UpdateInventoryInjuries()
            ClearEntityLastWeaponDamage(cache.ped)
        end
        return
    end

    CreateThread(function()
        for i = 1, 10 do
            Wait(100)
            found, lastBone = GetPedLastDamageBone(cache.ped)
            if found and lastBone ~= 0 then break end
        end
        if found and lastBone ~= 0 then
            local boneName = BoneMapping[lastBone]
            if boneName then
                Injuries[boneName] = true
                UpdateInventoryInjuries()
                ClearEntityLastWeaponDamage(cache.ped)
            end
        end
    end)
end)

local lastHealth = 0

SetInterval(function()
    if not cache.ped then return end
    local health = GetEntityHealth(cache.ped)
    local maxHealth = GetEntityMaxHealth(cache.ped)
    if health >= (maxHealth - 2) and lastHealth < (maxHealth - 2) then
        Injuries = {}
        UpdateInventoryInjuries()
    end
    lastHealth = health
end, 1000)

RegisterNUICallback('getInjuries', function(_, cb)
    local injuryList = {}
    for boneName, isInjured in pairs(Injuries) do
        if isInjured then injuryList[#injuryList + 1] = boneName end
    end
    cb(injuryList)
end)

AddStateBagChangeHandler('invOpen', nil, function(bagName, key, value)
    if bagName ~= ('player:%s'):format(cache.serverId) then return end
    if value then UpdateInventoryInjuries() end
end)

local TestBodyParts = { 'HEAD', 'NECK', 'UPPER_BODY', 'RARM', 'RHAND', 'LARM', 'LHAND', 'RLEG', 'RFOOT', 'LLEG', 'LFOOT', 'SPINE' }
local testIndex = 1

RegisterCommand('testinjury', function()
    if testIndex > #TestBodyParts then
        Injuries = {}
        UpdateInventoryInjuries()
        testIndex = 1
        print('[ox_inventory] injury test: reset')
        return
    end
    Injuries = { [TestBodyParts[testIndex]] = true }
    UpdateInventoryInjuries()
    print(('[ox_inventory] injury test: %s (%d/%d)'):format(TestBodyParts[testIndex], testIndex, #TestBodyParts))
    testIndex = testIndex + 1
end, false)
