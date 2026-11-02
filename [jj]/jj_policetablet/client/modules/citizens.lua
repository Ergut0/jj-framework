local utils = require "client.utils.functions"

local inventoryOpen = false

RegisterNetEvent('jj_policetablet:closedInventory', function()
    if inventoryOpen then
        inventoryOpen = false
        utils.openTablet()
    end
end)

RegisterNuiCallback("openCitizenInventory", function(data, cb)
    inventoryOpen = true
    utils.closeTablet()
    local success = lib.callback.await("jj_policetablet:callback:openCitizenInventory", false, data.citizenid)
    cb(success)
end)

RegisterNuiCallback('getPlayerData', function(data, cb)
    local playerData = lib.callback.await('jj_policetablet:callback:getPlayerData', false)
    cb(playerData)
end)

RegisterNuiCallback('getCitizens', function(data, cb)
    local citizens = lib.callback.await('jj_policetablet:callback:getCitizens', false)
    cb(citizens)
end)

RegisterNuiCallback('getCitizenById', function(data, cb)
    local citizenData = lib.callback.await('jj_policetablet:callback:getCitizenById', false, data)
    cb(citizenData)
end)

RegisterNuiCallback('getCitizensByFilter', function(data, cb)
    local citizens = lib.callback.await('jj_policetablet:callback:getCitizensByFilter', false, data)
    cb(citizens)
end)

RegisterNuiCallback('toggleWantedStatus', function(data, cb)
    lib.callback.await('jj_policetablet:callback:toggleWantedStatus', false, data)
    cb({ success = true })
end)

RegisterNuiCallback('toggleDangerousStatus', function(data, cb)
    lib.callback.await('jj_policetablet:callback:toggleDangerousStatus', false, data)
    cb({ success = true })
end)

RegisterNuiCallback('updateCitizenImage', function(data, cb)
    lib.callback.await('jj_policetablet:callback:updateCitizenImage', false, data)
    cb({ success = true })
end)

RegisterNuiCallback('addCitizenNote', function(data, cb)
    local noteInfo = lib.callback.await('jj_policetablet:callback:addCitizenNote', false, data)
    cb(noteInfo)
end)

RegisterNuiCallback('deleteCitizenNote', function(data, cb)
    local success = lib.callback.await('jj_policetablet:callback:deleteCitizenNote', false, data)
    cb({ success = success })
end)

RegisterNuiCallback('togglePingedStatus', function(data, cb)
    lib.callback.await('jj_policetablet:callback:togglePingedStatus', false, data)
    cb({ success = true })
end)

RegisterNuiCallback('addCitizenBills', function(data, cb)
    local billsInfo = lib.callback.await('jj_policetablet:callback:addCitizenBills', false, data.citizenid,
        data.bills)
    cb(billsInfo)
end)

RegisterNuiCallback('deleteCitizenBill', function(data, cb)
    local success = lib.callback.await('jj_policetablet:callback:deleteCitizenBill', false, data.billId)
    cb({ success = success })
end)

RegisterNuiCallback('takeCitizenPhoto', function(data, cb)
    local image = utils.cameraLoop()
    if image and image.data and image.data.url then
        lib.callback.await('jj_policetablet:callback:updateCitizenImage', false,
            { citizenid = data.citizenid, imageUrl = image.data.url })
        cb(image.data.url)
    else
        cb(false)
    end
end)

RegisterNuiCallback('callPhoneNumber', function(data, cb)
    if data and data.phoneNumber then
        utils.closeTablet()
        if GetResourceState('lb-phone') == 'started' then
            exports["lb-phone"]:CreateCall({
                number = tostring(data.phoneNumber)
            })
        end
    end
    cb({ success = true })
end)

RegisterNuiCallback('getDebtors', function(data, cb)
    local debtors = lib.callback.await('jj_policetablet:callback:getDebtors', false)
    cb(debtors)
end)

RegisterNuiCallback('getDebtorsByFilter', function(data, cb)
    local debtors = lib.callback.await('jj_policetablet:callback:getDebtorsByFilter', false, data.minDebt)
    cb(debtors)
end)
