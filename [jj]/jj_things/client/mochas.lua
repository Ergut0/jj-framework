local function setOneTimeFlags()
    SetPedSuffersCriticalHits(cache.ped, false)            -- enable or disable 1 shot headshot
end

lib.onCache('ped', function()
    Wait(100)
    setOneTimeFlags()
end)

SetTimeout(100, function()
    setOneTimeFlags()
end)

AddEventHandler('jj:client:playerSpawned', function()
    Wait(3000)
    setOneTimeFlags()
end)