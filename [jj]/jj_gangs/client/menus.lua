local function showResult(result)
    if result and result.message then
        Notify(result.message, result.ok and 'success' or 'error')
    end
end

-- Gestión de la banda: desde el punto de jefe

local function openMemberMenu(data, member)
    local options = {}

    if data.canPromote then
        options[#options + 1] = {
            title = 'Cambiar rango',
            icon = 'ranking-star',
            onSelect = function()
                Async(function()
                    local ranks = {}
                    for rank = 0, Config.TopRank do
                        if rank < data.rank or Config.Ranks[data.rank].isBoss then
                            ranks[#ranks + 1] = { value = rank, label = Config.Ranks[rank].name }
                        end
                    end
                    local input = lib.inputDialog(member.name, {
                        { type = 'select', label = 'Rango', options = ranks, required = true, default = member.rank },
                    })
                    if input then
                        showResult(lib.callback.await('jj_gangs:server:setRank', false, member.identifier, input[1]))
                    end
                    OpenBossMenu()
                end)
            end,
        }
    end

    if data.canKick then
        options[#options + 1] = {
            title = 'Expulsar',
            icon = 'user-xmark',
            iconColor = '#f87171',
            onSelect = function()
                Async(function()
                    local choice = lib.alertDialog({
                        header = ('Expulsar a %s'):format(member.name),
                        content = '¿Seguro que quieres expulsarle de la banda?',
                        centered = true,
                        cancel = true,
                    })
                    if choice == 'confirm' then
                        showResult(lib.callback.await('jj_gangs:server:kick', false, member.identifier))
                    end
                    OpenBossMenu()
                end)
            end,
        }
    end

    lib.registerContext({ id = 'jj_gangs_member', title = member.name, menu = 'jj_gangs_boss', options = options })
    lib.showContext('jj_gangs_member')
end

function OpenBossMenu()
    local data = lib.callback.await('jj_gangs:server:getRoster', false)
    if not data then
        Notify('No puedes gestionar la banda desde aquí', 'error')
        return
    end

    local options = {}
    if data.canInvite then
        options[#options + 1] = {
            title = 'Invitar a un jugador',
            icon = 'user-plus',
            description = 'Tiene que estar cerca de ti',
            onSelect = function()
                Async(function()
                    local input = lib.inputDialog('Invitar', {
                        { type = 'number', label = 'ID del jugador', required = true, min = 1 },
                    })
                    if input then
                        showResult(lib.callback.await('jj_gangs:server:invite', false, input[1]))
                    end
                end)
            end,
        }
    end

    for _, member in ipairs(data.roster) do
        local manageable = not member.isSelf and (data.canPromote or data.canKick)
            and (member.rank < data.rank or Config.Ranks[data.rank].isBoss)
        options[#options + 1] = {
            title = member.name,
            icon = member.online and 'circle-check' or 'circle',
            iconColor = member.online and '#4ade80' or '#71717a',
            description = ('%s%s'):format(Config.Ranks[member.rank].name, member.online and ', conectado' or ''),
            arrow = manageable,
            disabled = not manageable,
            onSelect = manageable and function() openMemberMenu(data, member) end or nil,
        }
    end

    lib.registerContext({ id = 'jj_gangs_boss', title = data.label, options = options })
    lib.showContext('jj_gangs_boss')
end

RegisterNetEvent('jj_gangs:client:invite', function(label, inviter)
    Async(function()
        local choice = lib.alertDialog({
            header = ('Invitación a %s'):format(label),
            content = ('%s te invita a unirte a su banda. ¿Aceptas?'):format(inviter),
            centered = true,
            cancel = true,
            labels = { confirm = 'Aceptar', cancel = 'Rechazar' },
        })
        TriggerServerEvent('jj_gangs:server:answerInvite', choice == 'confirm')
    end)
end)

-- /banda: tu banda y la opción de salir

RegisterCommand('banda', function()
    if not MyGang then
        Notify('No estás en ninguna banda')
        return
    end

    lib.registerContext({
        id = 'jj_gangs_mine',
        title = MyGang.label,
        options = {
            { title = ('Rango: %s'):format(Config.Ranks[MyGang.rank].name), icon = 'id-badge', readOnly = true },
            {
                title = 'Salir de la banda',
                icon = 'door-open',
                iconColor = '#f87171',
                onSelect = function()
                    Async(function()
                        local choice = lib.alertDialog({
                            header = 'Salir de la banda',
                            content = ('¿Seguro que quieres salir de %s?'):format(MyGang.label),
                            centered = true,
                            cancel = true,
                        })
                        if choice == 'confirm' then
                            showResult(lib.callback.await('jj_gangs:server:leave', false))
                        end
                    end)
                end,
            },
        },
    })
    lib.showContext('jj_gangs_mine')
end, false)

TriggerEvent('chat:addSuggestion', '/bandas', 'Crear y editar bandas')
TriggerEvent('chat:addSuggestion', '/banda', 'Tu banda')
TriggerEvent('chat:addSuggestion', '/graffiti', 'Pinta el grafiti de tu banda donde apuntas')
