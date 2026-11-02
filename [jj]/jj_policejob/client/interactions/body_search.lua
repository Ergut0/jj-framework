local targetsAdded = false

local function canSearch(entity)
    if IsOnDuty('police', 'sheriff') then return true end

    local index = NetworkGetPlayerIndexFromPed(entity)
    local state = index and index ~= -1 and Player(GetPlayerServerId(index)).state
    return state and (state.isCuffed or state.isDead)
end

local function searchPlayer(entity)
    local index = NetworkGetPlayerIndexFromPed(entity)
    if not index or index == -1 then return end

    RpAction('Cachea a la persona con cuidado')

    if lib.progressBar({
            duration = 5000,
            label = 'Cacheando a la persona',
            useWhileDead = false,
            canCancel = true,
            anim = {
                dict = 'anim@gangops@facility@servers@bodysearch@',
                clip = 'player_search',
                flags = 16,
            },
            disable = {
                car = true,
                combat = true,
            },
        }) then
        TriggerServerEvent('jj_policejob:server:searchPlayer', GetPlayerServerId(index))
    end
end

local function searchTarget()
    if targetsAdded then return end
    targetsAdded = true

    Target:addGlobalPlayer({
        {
            name = 'cachear_player',
            icon = 'fa-solid fa-magnifying-glass',
            label = 'Cachear',
            distance = 1.5,
            canInteract = canSearch,
            onSelect = function(data)
                searchPlayer(data.entity)
            end,
        },
    })
end

OnPlayerLoaded(function()
    searchTarget()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() and IsLoggedIn() then
        searchTarget()
    end
end)
