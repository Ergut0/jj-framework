if not lib.checkDependency('ox_core', '0.21.3', true) then return end

local Ox = require '@ox_core.lib.init' --[[@as OxClient]]
local player = Ox.GetPlayer()

RegisterNetEvent('ox:playerLoaded', client.onLogin)
RegisterNetEvent('ox:playerLogout', client.onLogout)

RegisterNetEvent('ox:setGroup', function(name, grade)
    PlayerData.groups[name] = grade
    OnPlayerData('groups')
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    for name, value in pairs(values) do
        if value > 100 or value < -100 then
            if (name == 'hunger' or name == 'thirst') then
                value = -value
            end

            value = value * 0.0001
        end

        ---@diagnostic disable-next-line: undefined-global
        player.addStatus(name, value)
    end
end
