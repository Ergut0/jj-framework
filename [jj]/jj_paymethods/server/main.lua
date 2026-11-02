local COMPANY_JOBS = { police = true, sheriff = true }

-- Paga con la cuenta elegida. El importe lo decide el recurso que cobra, y solo sale del dinero del propio jugador.
-- coins es el precio en CP, para lo que también se pueda pagar con monedas de donación
local function pay(source, amount, method, coins)
    local player = JJ.GetPlayer(source)
    local value = JJ.Utils.ToAmount(amount)
    if not player or not value then return false end

    if method == 'bank' or method == 'cash' then
        return player.removeMoney(method, value, 'jj_paymethods')
    end

    if method == 'cp' then
        local price = JJ.Utils.ToAmount(coins)
        return price ~= nil and price > 0 and JJ.RemoveCP(source, price, 'jj_paymethods') ~= nil
    end

    if method == 'company' then
        local job = player.getJob()
        if not COMPANY_JOBS[job.name] or not job.onDuty then return false end
        -- jj-framework no tiene cuentas de empresa: el pago se aprueba y se avisa por si otro recurso lo contabiliza
        TriggerEvent('jj_paymethods:server:companyPayment', source, job.name, value)
        return true
    end

    return false
end

-- Desde el cliente no se paga con CP: ese precio lo pone siempre el servidor que cobra
lib.callback.register('jj_paymethods:payMethod', function(source, amount, method)
    if method == 'cp' then return false end
    return pay(source, amount, method)
end)

-- Para cobrar desde el servidor, cuando el precio no puede depender del cliente
exports('Pay', pay)
