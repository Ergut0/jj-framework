local paySelected = nil 

-- Muestra el diálogo y devuelve el método elegido, o nil si se cancela.
-- Con coins se ofrece también pagar con CP
local SelectMethod = function(amountMoney, allowCompany, coins)

    local options = {
        {label = "Banco", value = "bank"},
        {label = "Efectivo", value = "cash"},
    }

    local PlayerData = GetPlayerData()

    if allowCompany ~= false and PlayerData.job and (PlayerData.job.name == 'police' or PlayerData.job.name == 'sheriff') and PlayerData.job.onDuty then
        table.insert(options, {label = "Tarjeta de empresa", value = "company"})
    end

    local title = 'Método de pago $' .. amountMoney
    if coins and coins > 0 then
        local balance = tonumber(LocalPlayer.state.cp) or 0
        table.insert(options, {label = ('CP: %d (tienes %d)'):format(coins, balance), value = "cp"})
        title = ('%s o %d CP'):format(title, coins)
    end

    local input = lib.inputDialog(title, {
        { icon = "fa-solid fa-dollar-sign", type = 'select', label = 'Tipo', options = options, description = "Selecciona el método de pago", required = true },
    })

    return input and input[1] or nil
end

local PayMethods = function(amountMoney, instantRemove)
    local method = SelectMethod(amountMoney)

    if method then
        paySelected = method
        if instantRemove then
            return lib.callback.await('jj_paymethods:payMethod', false, amountMoney, paySelected)
        end
        return true
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

exports('SelectMethod', SelectMethod)
exports('PayMethods', PayMethods)
exports('PayLater', PayLater)
exports('CheckMoney', CheckMoney)