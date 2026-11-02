Utils = {}

function Utils.IsFiniteNumber(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

function Utils.Round(value, decimals)
    local factor = 10 ^ (decimals or 4)
    return math.floor(value * factor + 0.5) / factor
end

function Utils.Copy(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = Utils.Copy(item) end
    return copy
end

function Utils.Count(list)
    local count = 0
    for _ in pairs(list or {}) do count = count + 1 end
    return count
end

-- Los hashes de modelo pueden llegar con signo. Se guardan siempre sin signo
function Utils.ModelHash(model)
    if type(model) == 'string' then model = GetHashKey(model) end
    if not Utils.IsFiniteNumber(model) then return nil end
    model = math.tointeger(model)
    if not model then return nil end
    return model & 0xFFFFFFFF
end

-- Nombre de modelo limpio: solo letras, números y guiones bajos, en minúsculas
function Utils.ModelName(name)
    if type(name) ~= 'string' then return nil end
    name = name:lower():gsub('[^%w_]', '')
    if name == '' or #name > 32 then return nil end
    return name
end

function Utils.Trim(text, maxLength)
    if type(text) ~= 'string' then return nil end
    text = text:gsub('[%c]', ''):match('^%s*(.-)%s*$')
    if text == '' then return nil end
    return text:sub(1, maxLength or 64)
end
