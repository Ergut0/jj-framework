local utils = require("client.utils.functions")

lib.addKeybind({
    name = "policetablet_keybind",
    description = "Abrir tablet policial",
    defaultKey = "HOME",
    onPressed = function(self)
        local PlayerData = GetPlayerData()
        if not PlayerData.job or PlayerData.job.name ~= "police" then
            return
        end
        utils.openTablet()
    end,
})

exports("useCad", function()
    if GetPlayerData().job.name == "police" then
        utils.openTablet()
    end
end)

RegisterNUICallback("closeTablet", function(_, cb)
    SetNuiFocus(false, false)
    utils.stopTabletAnim()
    cb('ok')
end)

RegisterNUICallback("getRanks", function(data, cb)
    local result = lib.callback.await('jj_policetablet:callback:getRanks', false)
    cb(result)
end)
