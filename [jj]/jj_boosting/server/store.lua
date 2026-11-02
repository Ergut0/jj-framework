-- Tienda con stock controlado por la base de datos
Store = {}

local items = {}
local startedAt = os.time()
local nextReference = 0

local function reference(prefix, identifier)
    nextReference += 1
    return ('%s:%s:%d:%d'):format(prefix, identifier:sub(-12), os.time(), nextReference)
end

-- Quita los artículos que no existen en el inventario y repone el stock
function Store.Init()
    items = {}
    for _, item in ipairs(Config.Store.items) do
        if item.type == 'item' and not Bridge.ItemExists(item.item) then
            print(('^3[jj_boosting] El objeto %s no existe en ox_inventory: no sale en la tienda^7'):format(item.item))
        elseif item.price and item.price >= 0 then
            items[item.id] = item
        end
    end
    Store.ResetStock()
end

function Store.ResetStock()
    for id, item in pairs(items) do
        if item.stock then DB.SetStock(id, item.stock) end
    end
    startedAt = os.time()
end

-- Unidades compradas por el jugador desde el último reinicio de stock
local function purchasedByItem(identifier)
    local totals = {}
    for _, row in ipairs(DB.GetPurchasedSince(identifier, startedAt)) do
        totals[row.item_id] = tonumber(row.total) or 0
    end
    return totals
end

local function isDisabled(id)
    return Settings.Get('store_disabled_' .. id) == true
end

Security.Register('getStore', {}, function(_, player, identifier)
    local profile = Progression.GetProfile(player)
    local stock = {}
    for _, row in ipairs(DB.GetStock()) do stock[row.item_id] = row.remaining end
    local bought = purchasedByItem(identifier)

    local list = {}
    for _, item in ipairs(Config.Store.items) do
        if items[item.id] and not isDisabled(item.id) then
            list[#list + 1] = {
                id = item.id,
                label = item.label,
                description = item.description,
                price = item.price,
                stock = item.stock and (stock[item.id] or 0) or nil,
                maxPerPlayer = item.maxPerPlayer,
                bought = bought[item.id] or 0,
                pickup = item.pickup == true,
                requiredClass = item.requiredClass,
                locked = item.requiredClass ~= nil and not Boost.IsClassUnlocked(item.requiredClass, profile.xp) or nil,
                icon = item.icon,
            }
        end
    end

    local pending = {}
    for index, row in ipairs(DB.GetPendingPurchases(identifier)) do
        pending[index] = { id = row.id, quantity = row.quantity, label = items[row.item_id] and items[row.item_id].label or row.item_id }
    end

    return { ok = true, items = list, pending = pending, crypto = profile.crypto, pickupPoint = Config.Store.pickupPoint.label }
end)

Security.Register('buyItem', { delay = Config.RateLimit.store, lock = true }, function(src, player, identifier, data)
    local item = type(data.id) == 'string' and items[data.id]
    local quantity = Security.ToInt(data.quantity or 1, 1, 50)
    if not item or not quantity or isDisabled(item.id) then
        return { ok = false, message = Boost.T('store_unknown') }
    end

    local profile = Progression.GetProfile(player)
    if item.requiredClass and not Boost.IsClassUnlocked(item.requiredClass, profile.xp) then
        return { ok = false, message = Boost.T('store_locked') }
    end

    if item.maxPerPlayer then
        local bought = purchasedByItem(identifier)[item.id] or 0
        if bought + quantity > item.maxPerPlayer then
            return { ok = false, message = Boost.T('store_limit') }
        end
    end

    local direct = item.type == 'item' and not item.pickup
    if direct and not Bridge.CanCarry(src, item.item, quantity) then
        return { ok = false, message = Boost.T('store_no_space') }
    end

    if item.stock and not DB.TakeStock(item.id, quantity) then
        return { ok = false, message = Boost.T('store_no_stock') }
    end

    local price = item.price * quantity
    local ref = reference('store', identifier)
    if not Economy.Spend(identifier, price, 'Tienda: ' .. item.label, ref) then
        if item.stock then DB.ReturnStock(item.id, quantity) end
        return { ok = false, message = Boost.T('no_crypto') }
    end

    if item.type == 'service' then
        Progression.AddService(identifier, item.service, (item.uses or 1) * quantity)
        DB.InsertPurchase(ref, identifier, item.id, quantity, price, 'delivered')
    elseif item.pickup then
        DB.InsertPurchase(ref, identifier, item.id, quantity, price, 'pending')
        DB.Log('store', identifier, nil, 'buy_pickup', { item = item.id, quantity = quantity, price = price })
        return { ok = true, message = Boost.T('store_pickup') }
    elseif Bridge.GiveItem(src, item.item, quantity) then
        DB.InsertPurchase(ref, identifier, item.id, quantity, price, 'delivered')
    else
        -- No se ha podido entregar: se deja en el punto de recogida para que no pierda lo pagado
        DB.InsertPurchase(ref, identifier, item.id, quantity, price, 'pending')
        return { ok = true, message = Boost.T('store_pickup') }
    end

    DB.Log('store', identifier, nil, 'buy', { item = item.id, quantity = quantity, price = price })
    return { ok = true, message = Boost.T('store_bought') }
end)

Security.Register('collectPurchase', { delay = Config.RateLimit.store, lock = true }, function(src, _, identifier, data)
    local id = Security.ToInt(data.id, 1, 2147483647)
    local purchase = id and DB.GetPurchase(id, identifier)
    local item = purchase and items[purchase.item_id]
    if not item then return { ok = false, message = Boost.T('store_unknown') } end

    local position = GetEntityCoords(GetPlayerPed(src))
    if #(position - Config.Store.pickupPoint.coords) > Config.Distances.pickup then
        return { ok = false, message = Boost.T('pickup_far') }
    end

    if not Bridge.CanCarry(src, item.item, purchase.quantity) then
        return { ok = false, message = Boost.T('store_no_space') }
    end

    if not DB.MarkCollected(purchase.id) then
        return { ok = false, message = Boost.T('store_unknown') }
    end

    if not Bridge.GiveItem(src, item.item, purchase.quantity) then
        DB.RevertCollected(purchase.id)
        return { ok = false, message = Boost.T('store_no_space') }
    end

    DB.Log('store', identifier, nil, 'collect', { item = item.id, quantity = purchase.quantity })
    return { ok = true, message = Boost.T('store_bought') }
end)
