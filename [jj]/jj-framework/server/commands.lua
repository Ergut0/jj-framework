local function reply(src, message)
    if src == 0 then
        print(message)
    else
        JJ.Notify(src, message)
    end
end

local function registerAdminCommand(name, handler)
    RegisterCommand(name, function(src, args)
        if not JJ.IsAdmin(src) then
            reply(src, JJ.T('no_permission'))
            return
        end
        handler(src, args)
    end, false)
end

RegisterCommand('dinero', function(src)
    if src == 0 then
        reply(src, JJ.T('console_only_player'))
        return
    end
    local player = JJ.GetPlayer(src)
    if not player then
        reply(src, JJ.T('not_loaded'))
        return
    end
    for name, account in pairs(Config.Accounts) do
        reply(src, JJ.T('balance_line', account.label, player.getMoney(name)))
    end
end, false)

RegisterCommand('trabajo', function(src)
    if src == 0 then
        reply(src, JJ.T('console_only_player'))
        return
    end
    local player = JJ.GetPlayer(src)
    if not player then
        reply(src, JJ.T('not_loaded'))
        return
    end
    local job = player.getJob()
    reply(src, JJ.T('job_info', job.label, job.gradeLabel))
end, false)

local function registerMoneyCommand(name, method)
    registerAdminCommand(name, function(src, args)
        if #args < 3 then
            reply(src, JJ.T('usage_money', name))
            return
        end
        local target = JJ.GetPlayer(args[1])
        if not target then
            reply(src, JJ.T('player_not_found'))
            return
        end
        local account = args[2]
        if not Config.Accounts[account] then
            reply(src, JJ.T('invalid_account'))
            return
        end
        if not JJ.Utils.ToAmount(args[3], method == 'setMoney') then
            reply(src, JJ.T('invalid_amount'))
            return
        end
        if not target[method](account, args[3], 'admin_command') then
            reply(src, JJ.T(method == 'removeMoney' and 'insufficient_funds' or 'invalid_amount'))
            return
        end
        reply(src, JJ.T('money_updated', target.getName(), account, target.getMoney(account)))
    end)
end

registerMoneyCommand('addmoney', 'addMoney')
registerMoneyCommand('removemoney', 'removeMoney')
registerMoneyCommand('setmoney', 'setMoney')

registerAdminCommand('setjob', function(src, args)
    if #args < 3 then
        reply(src, JJ.T('usage_setjob'))
        return
    end
    local target = JJ.GetPlayer(args[1])
    if not target then
        reply(src, JJ.T('player_not_found'))
        return
    end
    if not target.setJob(args[2], args[3]) then
        reply(src, JJ.T('invalid_job'))
        return
    end
    local job = target.getJob()
    reply(src, JJ.T('job_updated', target.getName(), job.label, job.gradeLabel))
end)

registerAdminCommand('saveall', function(src)
    reply(src, JJ.T('saved_all', JJInternal.SaveAll()))
end)
