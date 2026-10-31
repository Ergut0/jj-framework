if not lib.checkDependency('jj-framework', '0.2.0', true) then return end

RegisterNetEvent('jj:client:playerDataUpdated', function(key, value)
    if source == '' or key ~= 'job' or not PlayerData.loaded then return end
    client.setPlayerData('groups', { [value.name] = value.grade })
end)

-- jj-framework no gestiona hambre ni sed: un recurso de estados puede escuchar este evento
---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    TriggerEvent('jj:client:statusRequested', values)
end
