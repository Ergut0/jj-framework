-- Puertas con JJ Framework: permisos por trabajo y grado
local JJ = exports['jj-framework']:GetCoreObject()

AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then JJ = exports['jj-framework']:GetCoreObject() end
end)

function GetPlayer(playerId)
    return JJ.GetPlayer(playerId)
end

function GetCharacterId(player)
    return player.identifier
end

---@param player table
---@param filter string | string[] | table<string, number>
---@return string?, number?
function IsPlayerInGroup(player, filter)
    local job = player.getJob()
    local kind = type(filter)

    if kind == 'string' then
        if job.name == filter then return job.name, job.grade end
    elseif kind == 'table' then
        if table.type(filter) == 'array' then
            for i = 1, #filter do
                if job.name == filter[i] then return job.name, job.grade end
            end
        else
            local grade = filter[job.name]
            if grade and grade <= job.grade then return job.name, job.grade end
        end
    end
end
