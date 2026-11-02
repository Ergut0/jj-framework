RegisterCommand('createjob', function()
  if lib.callback.await('jj_creatorjobs:callback:canOpen', false) then
    CJ.toggleNuiFrame(true)
  end
end, false)

RegisterKeyMapping('createjob', 'Abrir gestión de trabajos', 'keyboard', 'F9')

RegisterNUICallback('hideFrame', function(_, cb)
  CJ.toggleNuiFrame(false)
  cb({})
end)

RegisterNUICallback('getPanel', function(_, cb)
  cb(lib.callback.await('jj_creatorjobs:callback:getPanel', false) or false)
end)

RegisterNUICallback('getJob', function(jobName, cb)
  cb(lib.callback.await('jj_creatorjobs:callback:getJob', false, jobName) or false)
end)

RegisterNUICallback('getLogs', function(jobName, cb)
  cb(lib.callback.await('jj_creatorjobs:callback:getLogs', false, jobName) or {})
end)

RegisterNUICallback('getGlobalTeleports', function(_, cb)
  cb(lib.callback.await('jj_creatorjobs:callback:getGlobalTeleportsAdmin', false) or {})
end)

-- Solo el cliente sabe qué modelos de vehículo existen
local function isValidVehicle(model)
  local hash = joaat(tostring(model or ''):lower())
  return IsModelInCdimage(hash) and IsModelAVehicle(hash)
end

RegisterNUICallback('action', function(data, cb)
  if data.name == 'insertVehicle' and not isValidVehicle(data.data and data.data.name) then
    lib.notify({ description = 'Ese vehículo no existe', type = 'error' })
    return cb(false)
  end
  cb(lib.callback.await('jj_creatorjobs:callback:action', false, data.name, data.data) or false)
end)

RegisterNUICallback('getCoords', function(_, cb)
  local coords = GetEntityCoords(cache.ped)
  cb({ x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(cache.ped) })
end)

RegisterNUICallback('tp', function(data, cb)
  if data and data.x and data.y and data.z then
    SetEntityCoords(cache.ped, tonumber(data.x), tonumber(data.y), tonumber(data.z), false, false, false, false)
  end
  cb({})
end)

AddEventHandler('onResourceStop', function(resource)
  if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
