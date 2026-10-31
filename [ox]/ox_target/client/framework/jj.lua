local utils = require 'client.utils'
local JJ = exports['jj-framework']:GetCoreObject()
local playerData = JJ.GetPlayerData()
local job = playerData and playerData.job

RegisterNetEvent('jj:client:playerLoaded', function(data)
    if source == '' then return end
    job = data.job
end)

RegisterNetEvent('jj:client:playerDataUpdated', function(key, value)
    if source == '' or key ~= 'job' then return end
    job = value
end)

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    if not job then return false end

    if type(filter) == 'string' then
        return filter == job.name
    end

    if type(filter) ~= 'table' then return false end

    -- Lista de trabajos
    for i = 1, #filter do
        if filter[i] == job.name then
            return true
        end
    end

    -- Trabajos con su grado mínimo
    local minGrade = filter[job.name]
    return minGrade ~= nil and job.grade >= minGrade
end
