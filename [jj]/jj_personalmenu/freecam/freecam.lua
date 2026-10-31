local SETTINGS = _G.CONTROL_SETTINGS
local CONTROLS = _G.CONTROL_MAPPING
activeLoop2 = false 

-------------------------------------------------------------------------------

local function GetSpeedMultiplier()
  local fastNormal = GetSmartControlNormal(CONTROLS.MOVE_FAST)
  local slowNormal = GetSmartControlNormal(CONTROLS.MOVE_SLOW)

  local baseSpeed = SETTINGS.BASE_MOVE_MULTIPLIER
  if activeLoop2 then 
    SETTINGS.BASE_MOVE_MULTIPLIER = 8 
  else
    SETTINGS.BASE_MOVE_MULTIPLIER = SETTINGS.BASE_MOVE_MULTIPLIER
  end
  local fastSpeed = 1 + ((SETTINGS.FAST_MOVE_MULTIPLIER - 1) * fastNormal)
  local slowSpeed = 1 + ((SETTINGS.SLOW_MOVE_MULTIPLIER - 1) * slowNormal)

  local frameMultiplier = GetFrameTime() * 60
  local speedMultiplier = baseSpeed * fastSpeed / slowSpeed

  return speedMultiplier * frameMultiplier
end



local function UpdateCamera()
  if not IsFreecamActive() or IsPauseMenuActive() then
    return
  end

  if not IsFreecamFrozen() then
      local vecX, vecY = GetFreecamMatrix()
      local vecZ = vector3(0, 0, 1)

      local pos = GetFreecamPosition()
      local rot = GetFreecamRotation()

      -- Get speed multiplier for movement
      local speedMultiplier = GetSpeedMultiplier()

      -- Get rotation input
      local lookX = GetSmartControlNormal(CONTROLS.LOOK_X)
      local lookY = GetSmartControlNormal(CONTROLS.LOOK_Y)

      -- Get position input
      local moveX = GetSmartControlNormal(CONTROLS.MOVE_X)
      local moveY = GetSmartControlNormal(CONTROLS.MOVE_Y)
      local moveZ = GetSmartControlNormal(CONTROLS.MOVE_Z)

      -- Calculate new rotation.
      local rotX = rot.x + (-lookY * SETTINGS.LOOK_SENSITIVITY_X)
      local rotZ = rot.z + (-lookX * SETTINGS.LOOK_SENSITIVITY_Y)
      local rotY = rot.y

      -- Adjust position relative to camera rotation.
      pos = pos + (vecX * moveX * speedMultiplier)
      pos = pos + (vecY * -moveY * speedMultiplier)
      pos = pos + (vecZ * moveZ * speedMultiplier)

      -- Adjust new rotation
      rot = vector3(rotX, rotY, rotZ)

      -- Zoom in/out the camera
      local zoomIn = GetSmartControlNormal(CONTROLS.MOVE_FORWARD)
      local zoomOut = GetSmartControlNormal(CONTROLS.MOVE_BACKWARD) 
      local zoomSpeed = SETTINGS.ZOOM_SENSITIVITY

      local zoomDelta = (zoomIn - zoomOut) * zoomSpeed

      -- Adjust camera FOV
      local fovDelta = -zoomDelta * SETTINGS.ZOOM_SENSITIVITY
      local newFov = GetFreecamFov() + fovDelta
      SetFreecamFov(newFov)

      -- Rotate the camera
      local rotateX = 0
      local rotateY = GetSmartControlNormal(CONTROLS.MOVE_RIGHT) - GetSmartControlNormal(CONTROLS.MOVE_LEFT)
      local rotateZ = 0
      local rotateSpeed = SETTINGS.ROTATE_SENSITIVITY

      rot = rot + vector3(rotateX, rotateY, rotateZ) * rotateSpeed

      -- Update camera
      SetFreecamPosition(pos.x, pos.y, pos.z)
      SetFreecamRotation(rot.x, rot.y, rot.z)
  end

  -- Trigger a tick event. Resources depending on the freecam position can
  -- make use of this event.
  TriggerEvent('freecam:onTick')
end

-------------------------------------------------------------------------------
local activeLoop = false 


RegisterCommand("jjeditor", function(source, args, rawCommand)
  activeLoop = not activeLoop
  ToggleFreecam()
end, false) 


function ToggleFreecam()
  local isActive = IsFreecamActive()
  LocalPlayer.state.freecam = not isActive
  SetFreecamActive(not isActive)  
  local waitTime
    while activeLoop do
      if IsFreecamActive() and not IsPauseMenuActive() and not IsFreecamFrozen() then
        waitTime = 0
        UpdateCamera()
      else
        waitTime = 500
      end

      if IsControlPressed(0, 194) or IsDisabledControlPressed(0, 194) then 
        SetFreecamActive(false) 
        LocalPlayer.state.freecam = false
        activeLoop = false 
      end

      if IsEntityDead(PlayerPedId())  then 
        SetFreecamActive(false) 
        LocalPlayer.state.freecam = false
        activeLoop = false
      end

      Citizen.Wait(waitTime)
    end
end

RegisterNetEvent('jj_personalmenu:ToggleAdminFreecam', function()
  activeLoop2 = not activeLoop2

  local isActive = IsFreecamActive()
  SetFreecamActive(not isActive)  
  local waitTime = 0 

  while activeLoop2 do
      if IsFreecamActive() and not IsPauseMenuActive() and not IsFreecamFrozen() then
        waitTime = 0
        UpdateCamera()
      else
        waitTime = 500
      end

      if IsControlPressed(0, 194) or IsDisabledControlPressed(0, 194) then 
        SetFreecamActive(false) 
        activeLoop2 = false 
      end

      if IsEntityDead(PlayerPedId())  then 
        SetFreecamActive(false) 
        activeLoop2 = false
      end
      Citizen.Wait(waitTime)
  end
end)


--------------------------------------------------------------------------------

-- When the resource is stopped, make sure to return the camera to the player.
AddEventHandler('onResourceStop', function (resourceName)
  if resourceName == GetCurrentResourceName() then
    SetFreecamActive(false)
  end
end)
