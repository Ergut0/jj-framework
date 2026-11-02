local utils = require "client.utils.functions"

RegisterNuiCallback("getVehicles", function(data, cb)
    local vehicles = lib.callback.await("jj_policetablet:callback:getVehicles", false)
    cb(vehicles)
end)

RegisterNuiCallback("getVehiclesByFilter", function(data, cb)
    local vehicles = lib.callback.await("jj_policetablet:callback:getVehiclesByFilter", false, data.filter)
    cb(vehicles)
end)

RegisterNuiCallback("getVehicleByPlate", function(data, cb)
    local vehicle = lib.callback.await("jj_policetablet:callback:getVehicleByPlate", false, data.plate)
    cb(vehicle)
end)

RegisterNuiCallback("toggleVehicleIncautedStatus", function(data, cb)
    lib.callback.await("jj_policetablet:callback:toggleVehicleIncautedStatus", false, data)
    cb({ success = true })
end)

RegisterNuiCallback("toggleVehicleWantedStatus", function(data, cb)
    lib.callback.await("jj_policetablet:callback:toggleVehicleWantedStatus", false, data)
    cb({ success = true })
end)

RegisterNuiCallback("updateVehicleImageUrl", function(data, cb)
    lib.callback.await("jj_policetablet:callback:updateVehicleImageUrl", false, data)
    cb({ success = true })
end)

RegisterNuiCallback("takeVehiclePicture", function(data, cb)
    local image = utils.cameraLoop()
    if image and image.data and image.data.url then
        lib.callback.await('jj_policetablet:callback:updateVehicleImageUrl', false,
            { vehiclePlate = data.vehiclePlate, imageUrl = image.data.url })
        cb(image.data.url)
    else
        cb(false)
    end
end)

RegisterNuiCallback("addVehicleNote", function(data, cb)
    local noteInfo = lib.callback.await("jj_policetablet:callback:addVehicleNote", false, data)
    cb(noteInfo)
end)

RegisterNuiCallback("deleteVehicleNote", function(data, cb)
    lib.callback.await("jj_policetablet:callback:deleteVehicleNote", false, data.noteId)
    cb({ success = true })
end)

RegisterNuiCallback("toggleVehicleNotePingedStatus", function(data, cb)
    lib.callback.await("jj_policetablet:callback:toggleVehicleNotePingedStatus", false, data)
    cb({ success = true })
end)
