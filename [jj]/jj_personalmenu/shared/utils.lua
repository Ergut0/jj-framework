function table.copy(x)
  local copy = {}
  for k, v in pairs(x) do
    if type(v) == 'table' then
        copy[k] = table.copy(v)
    else
        copy[k] = v
    end
  end
  return copy
end

function protect(t)
  local fn = function (_, k)
    error('Key `' .. tostring(k) .. '` is not supported.')
  end

  return setmetatable(t, {
    __index = fn,
    __newindex = fn
  })
end

function CreateGamepadMetatable(keyboard, gamepad)
  return setmetatable({}, {
    __index = function (t, k)
      local src = IsGamepadControl() and gamepad or keyboard
      return src[k]
    end
  })
end

function Clamp(x, min, max)
  return math.min(math.max(x, min), max)
end

function ClampCameraRotation(rotX, rotY, rotZ)
  local x = Clamp(rotX, -90.0, 90.0)
  local y = rotY % 360
  local z = rotZ % 360
  return x, y, z
end

function IsGamepadControl()
  return not IsInputDisabled(2)
end

function GetSmartControlNormal(control)
    if type(control) == 'table' then
      local normal1 = GetDisabledControlNormal(0, control[1])
      local normal2 = GetDisabledControlNormal(0, control[2])
      return normal1 - normal2
    end

    return GetDisabledControlNormal(0, control)
end

function EulerToMatrix(rotX, rotY, rotZ)
  local radX = math.rad(rotX)
  local radY = math.rad(rotY)
  local radZ = math.rad(rotZ)

  local sinX = math.sin(radX)
  local sinY = math.sin(radY)
  local sinZ = math.sin(radZ)
  local cosX = math.cos(radX)
  local cosY = math.cos(radY)
  local cosZ = math.cos(radZ)

  local vecX = {}
  local vecY = {}
  local vecZ = {}

  vecX.x = cosY * cosZ
  vecX.y = cosY * sinZ
  vecX.z = -sinY

  vecY.x = cosZ * sinX * sinY - cosX * sinZ
  vecY.y = cosX * cosZ - sinX * sinY * sinZ
  vecY.z = cosY * sinX

  vecZ.x = -cosX * cosZ * sinY + sinX * sinZ
  vecZ.y = -cosZ * sinX + cosX * sinY * sinZ
  vecZ.z = cosX * cosY

  vecX = vector3(vecX.x, vecX.y, vecX.z)
  vecY = vector3(vecY.x, vecY.y, vecY.z)
  vecZ = vector3(vecZ.x, vecZ.y, vecZ.z)

  return vecX, vecY, vecZ
end


local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2
local INPUT_DUCK = 36
local INPUT_SPRINT = 21
local INPUT_MOVE_UD = 31
local INPUT_MOVE_LR = 30
local INPUT_VEH_ACCELERATE = 71
local INPUT_VEH_BRAKE = 72
local INPUT_PARACHUTE_BRAKE_LEFT = 152
local INPUT_PARACHUTE_BRAKE_RIGHT = 153

local INPUT_MOVE_UP = 172
local INPUT_MOVE_DOWN = 173
local INPUT_MOVE_LEFT = 174
local INPUT_MOVE_RIGHT = 175
local INPUT_ZOOM_IN = 20 
local INPUT_ZOOM_OUT = 45 

--------------------------------------------------------------------------------

local BASE_CONTROL_MAPPING = protect({
  -- Rotation
  LOOK_X = INPUT_LOOK_LR,
  LOOK_Y = INPUT_LOOK_UD,

  -- Position
  MOVE_X = INPUT_MOVE_LR,
  MOVE_Y = INPUT_MOVE_UD,
  MOVE_Z = { INPUT_PARACHUTE_BRAKE_LEFT, INPUT_PARACHUTE_BRAKE_RIGHT },

  -- Multiplier
  MOVE_FAST = INPUT_SPRINT,
  MOVE_SLOW = INPUT_DUCK,

  -- Zoom and rotate
  MOVE_ZOOMOUT = INPUT_ZOOM_OUT,
  MOVE_ZOOMIN = INPUT_ZOOM_IN,
  MOVE_FORWARD = INPUT_MOVE_UP,
  MOVE_BACKWARD = INPUT_MOVE_DOWN,
  MOVE_LEFT = INPUT_MOVE_LEFT,
  MOVE_RIGHT = INPUT_MOVE_RIGHT,
})

--------------------------------------------------------------------------------

local BASE_CONTROL_SETTINGS = protect({
  -- Rotation
  LOOK_SENSITIVITY_X = 3,
  LOOK_SENSITIVITY_Y = 3,

  -- Position
  BASE_MOVE_MULTIPLIER = 1,
  FAST_MOVE_MULTIPLIER = 10,
  SLOW_MOVE_MULTIPLIER = 15,

  -- Zoom and rotate
  ZOOM_SENSITIVITY = 0.5,
  ROTATE_SENSITIVITY = 0.5,
})

--------------------------------------------------------------------------------

local BASE_CAMERA_SETTINGS = protect({
  --Camera
  FOV = 45.0,

  -- On enable/disable
  ENABLE_EASING = true,
  EASING_DURATION = 1000,

  -- Keep position/rotation
  KEEP_POSITION = false,
  KEEP_ROTATION = false
})

--------------------------------------------------------------------------------

_G.KEYBOARD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)
_G.GAMEPAD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)

-- Swap up/down movement (LB for down, RB for up)
_G.GAMEPAD_CONTROL_MAPPING.MOVE_Z[1] = INPUT_PARACHUTE_BRAKE_LEFT
_G.GAMEPAD_CONTROL_MAPPING.MOVE_Z[2] = INPUT_PARACHUTE_BRAKE_RIGHT

-- Use LT and RT for speed
_G.GAMEPAD_CONTROL_MAPPING.MOVE_FAST = INPUT_VEH_ACCELERATE
_G.GAMEPAD_CONTROL_MAPPING.MOVE_SLOW = INPUT_VEH_BRAKE

protect(_G.KEYBOARD_CONTROL_MAPPING)
protect(_G.GAMEPAD_CONTROL_MAPPING)

--------------------------------------------------------------------------------

_G.KEYBOARD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)
_G.GAMEPAD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)

-- Gamepad sensitivity can be reduced by BASE.
_G.GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_X = 2
_G.GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_Y = 2

protect(_G.KEYBOARD_CONTROL_SETTINGS)
protect(_G.GAMEPAD_CONTROL_SETTINGS)

--------------------------------------------------------------------------------

_G.CAMERA_SETTINGS = table.copy(BASE_CAMERA_SETTINGS)
protect(_G.CAMERA_SETTINGS)

--------------------------------------------------------------------------------

-- Create some convenient variables.
-- Allows us to access controls and config without a gamepad switch.
_G.CONTROL_MAPPING  = CreateGamepadMetatable(_G.KEYBOARD_CONTROL_MAPPING,  _G.GAMEPAD_CONTROL_MAPPING)
_G.CONTROL_SETTINGS = CreateGamepadMetatable(_G.KEYBOARD_CONTROL_SETTINGS, _G.GAMEPAD_CONTROL_SETTINGS)
