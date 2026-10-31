if not lib.checkDependency('jj-framework', '0.2.0', true) then return end

local Inventory = require 'modules.inventory.server'
local db = require 'modules.mysql.server'

db.setup({
    user = { table = 'jj_players', col = 'identifier' },
    vehicle = { table = 'jj_vehicles', col = 'plate' },
})

local JJ = exports['jj-framework']:GetCoreObject()

-- Cuenta del framework que representa cada objeto físico del inventario
local itemAccounts = { money = 'cash', black_money = 'black' }
local accountItems = { cash = 'money', black = 'black_money' }

server.accounts.black_money = 0

local loading = {}
local syncing = {}
-- Objetos que no cupieron en el inventario: hasta colocarlos, manda el saldo del framework
local pendingItems = {}

local function getGroups(job)
    return { [job.name] = job.grade }
end

local function pushBalance(src, item, balance)
    syncing[src] = true
    local success = Inventory.SetItem(src, item, balance)
    syncing[src] = nil

    pendingItems[src] = pendingItems[src] or {}
    pendingItems[src][item] = success == false or nil
end

local function setupPlayer(src)
    local player = JJ.GetPlayer(src)
    if not player then return end

    local data = player.getData()
    local inventory = Inventory(src)

    -- Al reiniciar jj-framework el inventario sigue activo y no se puede cargar otra vez
    if inventory and inventory.player then
        inventory.player.groups = getGroups(data.job)
    else
        -- El saldo del framework es el válido: se ignora la sincronización inicial del inventario
        loading[src] = true
        local success, response = pcall(server.setPlayerInventory, {
            source = src,
            identifier = data.identifier,
            name = data.name,
            groups = getGroups(data.job),
            sex = data.charinfo and data.charinfo.gender,
            dateofbirth = data.charinfo and data.charinfo.birthdate
        })
        loading[src] = nil

        if not success then
            warn(('[jj-framework] No se pudo cargar el inventario de %s: %s'):format(src, response))
            return
        end
    end

    for item, account in pairs(itemAccounts) do
        pushBalance(src, item, player.getMoney(account))
    end
end

AddEventHandler('jj:server:playerLoaded', setupPlayer)

AddEventHandler('jj:server:playerDropped', function(src)
    pendingItems[src] = nil
end)

AddEventHandler('jj:server:moneyChanged', function(src, account, _, _, balance)
    local item = accountItems[account]
    if item and not loading[src] and Inventory(src) then
        pushBalance(src, item, balance)
    end
end)

AddEventHandler('jj:server:jobChanged', function(src, job)
    local inventory = Inventory(src)
    if inventory and inventory.player then
        inventory.player.groups = getGroups(job)
    end
end)

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

SetTimeout(500, function()
    for _, src in pairs(JJ.GetPlayers()) do
        setupPlayer(src)
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.syncInventory(inv)
    if loading[inv.id] or syncing[inv.id] then return end

    local player = JJ.GetPlayer(inv.id)
    local accounts = Inventory.GetAccountItemCounts(inv)
    if not player or not accounts then return end

    for item, amount in pairs(accounts) do
        local account = itemAccounts[item]
        if account then
            local balance = player.getMoney(account)
            local pending = pendingItems[inv.id]

            if pending and pending[item] then
                pushBalance(inv.id, item, balance)
            elseif balance ~= amount then
                player.setMoney(account, amount, 'inventory_sync')
            end
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, name)
    local player = JJ.GetPlayer(inv.id)
    if not player then return end

    local licenses = player.getMetadata('licenses')
    return licenses and licenses[name]
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    local player = JJ.GetPlayer(inv.id)
    if not player then return end

    if server.hasLicense(inv, license.name) then
        return false, 'already_have'
    elseif Inventory.GetItemCount(inv, 'money') < license.price then
        return false, 'can_not_afford'
    end

    Inventory.RemoveItem(inv, 'money', license.price)

    local licenses = player.getMetadata('licenses') or {}
    licenses[license.name] = true
    player.setMetadata('licenses', licenses)

    return true, 'have_purchased'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(_, group, grade)
    local job = JJ.Utils.BuildJob(group, grade)
    return job and job.isBoss
end
