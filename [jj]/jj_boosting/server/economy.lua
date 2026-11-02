-- Criptomoneda interna. Cada movimiento lleva una referencia única: repetirla no tiene efecto
Economy = {}

-- amount positivo suma y negativo gasta. Devuelve true si se ha aplicado
function Economy.Apply(identifier, amount, reason, reference)
    if math.type(amount) ~= 'integer' or amount == 0 then return false end

    if not DB.InsertTransaction(reference, identifier, amount, reason) then
        DB.Log('security', identifier, nil, 'duplicate_transaction', { reference = reference })
        return false
    end

    if not DB.ApplyCrypto(identifier, amount) then
        DB.DeleteTransaction(reference)
        return false
    end

    return true
end

function Economy.Reward(identifier, amount, reason, reference)
    if amount <= 0 then return true end
    return Economy.Apply(identifier, amount, reason, reference)
end

function Economy.Spend(identifier, amount, reason, reference)
    if amount <= 0 then return true end
    return Economy.Apply(identifier, -amount, reason, reference)
end

Security.Register('getTransactions', {}, function(_, player, identifier)
    Progression.GetProfile(player)
    return { ok = true, transactions = DB.GetTransactions(identifier, 50) }
end)
