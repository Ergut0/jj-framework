JJ = {}
JJ.Config = Config
JJ.Utils = {}

local MAX_AMOUNT = 1000000000000
local locale = Locales[Config.Locale] or Locales.es

function JJ.T(key, ...)
    local text = locale[key]
    if not text then
        return key
    end
    if select('#', ...) > 0 then
        return text:format(...)
    end
    return text
end

-- Normaliza una cantidad de dinero. Devuelve nil si no es válida (NaN, negativa, enorme...)
function JJ.Utils.ToAmount(value, allowZero)
    local number = tonumber(value)
    if not number or number ~= number or number < 0 or number > MAX_AMOUNT then
        return nil
    end
    local amount = math.floor(number)
    if amount == 0 and not allowZero then
        return nil
    end
    return amount
end

function JJ.Utils.WithinLimit(amount)
    return amount <= MAX_AMOUNT
end

function JJ.Utils.Round(value, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor(value * factor + 0.5) / factor
end

-- Los trabajos actuales, también los creados en marcha. Úsalo en vez de JJ.Config.Jobs,
-- que en otro recurso es una copia del momento en que pidió el objeto del framework
function JJ.GetJobs()
    return Config.Jobs
end

-- Devuelve los datos públicos de un trabajo y grado, o nil si no existen
function JJ.Utils.BuildJob(name, grade)
    local job = Config.Jobs[name]
    local number = tonumber(grade)
    local gradeId = number and math.tointeger(number)
    local gradeData = job and gradeId and job.grades[gradeId]
    if not gradeData then
        return nil
    end
    return {
        name = name,
        label = job.label,
        grade = gradeId,
        gradeLabel = gradeData.label,
        salary = gradeData.salary,
        isBoss = gradeData.isBoss == true
    }
end
