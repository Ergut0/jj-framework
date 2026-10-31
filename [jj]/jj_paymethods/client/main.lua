local paySelected = nil 

local PayMethods = function(amountMoney, instantRemove)

    local options = {
        {label = "Banco", value = "bank"},
        {label = "Efectivo", value = "cash"},
    }

    local PlayerData = GetPlayerData()

    if PlayerData.job and (PlayerData.job.name == 'police' or PlayerData.job.name == 'sheriff') and PlayerData.job.onDuty then
        table.insert(options, {label = "Tarjeta de empresa", value = "company"})
    end

    local input = lib.inputDialog('Método de pago $' .. amountMoney, {
        { icon = "fa-solid fa-dollar-sign", type = 'select', label = 'Tipo', options = options, description = "Selecciona el método de pago", required = true },
    })

    if input then
        paySelected = input[1]
        if input[1] and instantRemove then
            return lib.callback.await('jj_paymethods:payMethod', false, amountMoney, paySelected)
        elseif not instantRemove then 
            return true 
        end
    end
end

local PayLater = function(amountMoney)
    return lib.callback.await('jj_paymethods:payMethod', false, amountMoney, paySelected)
end

local CheckMoney = function(amountMoney)
    local PlayerData = GetPlayerData()
    if paySelected == "bank" then
        return PlayerData.accounts.bank
    elseif paySelected == "cash" then
        return PlayerData.accounts.cash
    elseif paySelected == "company" then
        return 100000000000
    end
end

exports('PayMethods', PayMethods)
exports('PayLater', PayLater)
exports('CheckMoney', CheckMoney)