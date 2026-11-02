--[[
    Servidor principal: arranque, exports, facturas, sociedad, compraventa,
    mercado, lonja y nóminas.
]]

local BILL_TIMEOUT = 120
local DEAL_TIMEOUT = 120
local MAX_DEAL_PRICE = 100000000
local SEARCH_DISTANCE = 5.0
local INVOICE_CHECK_INTERVAL = 60000
local MAX_CONCEPT = 200
local TUNING_DISTANCE = 15.0

-- Facturas pendientes de aceptar: PendingBills[targetSource] = { sender, amount, concept, time }
local PendingBills = {}
-- Compraventas pendientes de aceptar: PendingDeals[targetSource] = { kind, plate, price, employee, job, vehicle, time }
local PendingDeals = {}

-- =============================================================
-- Arranque
-- =============================================================

local function StartJobs()
    -- Con un jj-framework anterior no se pueden crear trabajos: mejor un aviso claro que un error en cada acción
    if not JJ.GetJobs or not JJ.RegisterJob or not JJ.RemoveJob then
        print('^1[jj_creatorjobs] Tu jj-framework está anticuado. Sube server/player.lua y shared/main.lua de jj-framework y reinicia el servidor entero.^7')
        return
    end

    LoadJobs()
    RegisterJobStashes()
    RegisterJobGarages()

    for _, src in ipairs(JJ.GetPlayers()) do
        RegisterPersonalStash(src)
    end

    -- Si fd_banking ya está arrancado, crea las cuentas que falten
    SyncBankAccounts()
end

MySQL.ready(function()
    CreateTables()
    StartJobs()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'jj-framework' then
        -- jj-framework vuelve a su configuración al reiniciarse: hay que registrar otra vez los trabajos
        Wait(1000)
        JJ = exports['jj-framework']:GetCoreObject()
        if not JobsReady then
            StartJobs()
            return
        end
        for _, job in pairs(Jobs) do
            RegisterJobInCore(job)
        end
    elseif resource == 'jj_garages' then
        Wait(1000)
        RegisterJobGarages()
    end
end)

-- =============================================================
-- Exports
-- =============================================================

--- fd_banking espera a esto para no borrar las cuentas de trabajos que aún no se han cargado.
exports('isReady', function()
    return JobsReady
end)

-- jj_tuneos lo usa para saber si un mecánico puede guardar el tuneo de un vehículo ajeno
exports('isAtTuningPoint', function(src)
    local player, jobName, job, jobData = GetPlayerContext(src)
    if not player or not job or not jobData.onDuty then return false end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local points = MySQL.query.await("SELECT x, y, z FROM jobscreator_points WHERE job = ? AND typePoint = 'Tuneo'", { jobName }) or {}
    for _, point in ipairs(points) do
        if #(coords - vector3(point.x, point.y, point.z)) <= TUNING_DISTANCE then
            return true
        end
    end
    return false
end)

exports('GetAccount', function(jobName)
    local job = Jobs[jobName]
    return job and job:GetMoney() or 0
end)

exports('RemoveMoney', function(jobName, amount, reason)
    local job = Jobs[jobName]
    return job and job:RemoveMoney(amount, reason) or false
end)

-- Para comprobar que el registro llega a Discord
RegisterCommand('testlogs', function(source)
    if not IsAdmin(source) then return end

    local sent = SendTestLogs(source > 0 and GetPlayerName(source) or 'Consola')

    if source > 0 then
        Notify(source, sent > 0 and ('Prueba enviada a %d canales de Discord'):format(sent) or 'Faltan los webhooks en server/logs.lua', 'inform')
    end
end, false)

-- =============================================================
-- Taquilla personal del ropero
-- =============================================================

function RegisterPersonalStash(src)
    local player = JJ.GetPlayer(src)
    if player then
        exports.ox_inventory:RegisterStash(player.identifier .. '-personal', 'Taquilla personal', 30, 50000, player.identifier)
    end
end

AddEventHandler('jj:server:playerLoaded', RegisterPersonalStash)

-- =============================================================
-- Servicio
-- =============================================================

-- Se registra aquí para contar todos los cambios: el punto de servicio, la zona de trabajo y los de otros recursos
AddEventHandler('jj:server:dutyChanged', function(src, onDuty)
    local _, jobName, job = GetPlayerContext(src)
    if job then
        Log(src, 'servicio', jobName, onDuty and 'Ha entrado de servicio' or 'Ha salido de servicio', 'fichaje')
    end
end)

RegisterNetEvent('jj_creatorjobs:server:setDuty', function(onDuty)
    local player, _, job = GetPlayerContext(source)
    if player and job and type(onDuty) == 'boolean' then
        player.setDuty(onDuty)
    end
end)

-- =============================================================
-- Cobros
-- =============================================================

--- Cobra primero del banco y, si no llega, del efectivo.
local function ChargePlayer(player, amount, reason)
    return player.removeMoney('bank', amount, reason) == true or player.removeMoney('cash', amount, reason) == true
end

local function GetCharacterFirstName(player)
    local charinfo = player.getCharInfo()
    return charinfo and charinfo.firstname or player.getName()
end

-- =============================================================
-- Facturas
-- =============================================================

-- La experiencia se gana cuando la factura se paga, no al enviarla
function AddBillExp(job, amount)
    local exp = math.floor((amount / Config.MaxMoneyBillLevel) * Config.ExpBill)
    return job:AddExp(math.max(1, math.min(exp, Config.ExpBill)))
end

RegisterNetEvent('jj_creatorjobs:sendBill', function(targetId, amount, concept)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job or not HasJobOption(jobName, 'Facturar') then return end

    local target = JJ.GetPlayer(tonumber(targetId) or -1)
    amount = math.floor(tonumber(amount) or 0)
    concept = tostring(concept or '')

    if #concept > MAX_CONCEPT then
        Notify(src, 'El concepto de la factura es demasiado largo', 'error')
        return
    end

    if not target then
        Notify(src, 'El jugador no está conectado', 'error')
        return
    end
    -- Un administrador sí puede, para probar las facturas
    if target.source == src and not IsAdmin(src) then
        Notify(src, 'No puedes facturarte a ti mismo', 'error')
        return
    end
    if amount <= 0 or amount > 1000000 then
        Notify(src, 'Cantidad de la factura no válida', 'error')
        return
    end
    if concept == '' then
        Notify(src, 'Debes indicar un concepto para la factura', 'error')
        return
    end

    if UsesBank() then
        if not job:AddInvoice(target.identifier, amount, concept) then
            Notify(src, ('%s no tiene cuenta de empresa en el banco'):format(job.label), 'error')
            SyncBankAccounts()
            return
        end
        Log(src, 'facturas', jobName, ('Ha enviado una factura de $%d a %s: %s'):format(amount, target.getName(), concept))
        Notify(src, ('Factura de $%d enviada a %s'):format(amount, GetCharacterFirstName(target)), 'success')
        Notify(target.source, ('Tienes una factura de $%d de %s: págala en el banco'):format(amount, job.label), 'inform')
        return
    end

    -- Sin banco, el cliente la paga en el momento
    PendingBills[target.source] = {
        sender = src,
        job = jobName,
        amount = amount,
        concept = concept,
        time = os.time(),
    }

    Log(src, 'facturas', jobName, ('Ha enviado una factura de $%d a %s: %s'):format(amount, target.getName(), concept))
    TriggerClientEvent('jj_creatorjobs:client:receiveBill', target.source, amount, concept, job.label)
    Notify(src, ('Factura de $%d enviada a %s'):format(amount, GetCharacterFirstName(target)), 'success')
end)

RegisterNetEvent('jj_creatorjobs:server:payBill', function(accepted)
    local src = source
    local bill = PendingBills[src]
    PendingBills[src] = nil

    if not bill or os.time() - bill.time > BILL_TIMEOUT then return end

    local target = JJ.GetPlayer(src)
    local job = Jobs[bill.job]
    if not target or not job then return end

    if not accepted then
        Notify(bill.sender, 'El cliente ha rechazado la factura', 'error')
        return
    end

    local reason = 'factura-' .. bill.job
    if not ChargePlayer(target, bill.amount, reason) then
        Notify(src, 'No tienes suficiente dinero para pagar la factura', 'error')
        Notify(bill.sender, 'El cliente no tiene suficiente dinero', 'error')
        return
    end

    if not job:AddMoney(bill.amount, reason) then
        target.addMoney('bank', bill.amount, 'devolucion-' .. reason)
        Notify(src, 'No se ha podido cobrar la factura: te hemos devuelto el dinero', 'error')
        Notify(bill.sender, 'La empresa no tiene una cuenta donde ingresar el dinero', 'error')
        return
    end

    Log(src, 'facturas', bill.job, ('Ha pagado una factura de $%d: %s'):format(bill.amount, bill.concept))
    Notify(src, ('Has pagado la factura de $%d a %s'):format(bill.amount, job.label), 'success')
    Notify(bill.sender, ('%s ha pagado la factura de $%d'):format(GetCharacterFirstName(target), bill.amount), 'success')

    if AddBillExp(job, bill.amount) then
        Notify(bill.sender, ('¡%s ha subido al nivel %d!'):format(job.label, job.level), 'success')
    end
end)

-- =============================================================
-- Sociedad
-- =============================================================

RegisterNetEvent('jj_creatorjobs:server:AddSocietyMoney', function(amount)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        Notify(src, 'Cantidad no válida', 'error')
        return
    end

    if player.removeMoney('cash', amount, 'deposito-sociedad') ~= true then
        Notify(src, 'No tienes suficiente dinero en efectivo', 'error')
        return
    end

    if not job:AddMoney(amount, 'Ingreso de ' .. player.getName()) then
        player.addMoney('cash', amount, 'devolucion-deposito')
        Notify(src, ('%s no tiene cuenta de empresa'):format(jobName), 'error')
        return
    end

    Log(src, 'dinero', jobName, ('Ha ingresado $%d en la sociedad'):format(amount), 'caja')
    Notify(src, ('Has depositado $%d en la sociedad'):format(amount), 'success')
end)

RegisterNetEvent('jj_creatorjobs:server:WithdrawnSocietyMoney', function(amount)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job then return end

    if not HasGradePermission(player, jobName) then
        Notify(src, 'No tienes permisos para retirar dinero', 'error')
        return
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        Notify(src, 'Cantidad no válida', 'error')
        return
    end

    if not job:RemoveMoney(amount, 'Retirada de ' .. player.getName()) then
        Notify(src, 'La sociedad no tiene suficientes fondos', 'error')
        return
    end

    player.addMoney('cash', amount, 'retiro-sociedad')
    Log(src, 'dinero', jobName, ('Ha retirado $%d de la sociedad'):format(amount), 'caja')
    Notify(src, ('Has retirado $%d de la sociedad'):format(amount), 'success')
end)

-- =============================================================
-- Abrir/cerrar negocio y anuncios
-- =============================================================

local function SetBusinessOpen(src, open)
    local player, jobName, job = GetPlayerContext(src)
    if not player then return end

    if not job then
        Notify(src, 'Tu trabajo no es un negocio del creador de trabajos', 'error')
        return
    end

    if not HasGradePermission(player, jobName) and not HasJobOption(jobName, 'Abrir/Cerrar Negocio') then
        Notify(src, 'No tienes permisos para abrir o cerrar el negocio', 'error')
        return
    end

    if job.open == open then
        Notify(src, open and 'El negocio ya está abierto' or 'El negocio ya está cerrado', 'error')
        return
    end

    job:SetOpen(open)
    Log(src, 'negocio', jobName, open and 'Ha abierto el negocio' or 'Ha cerrado el negocio')
    TriggerClientEvent('jj_creatorjobs:client:notiyStatus', -1, job.label, job.open and 'open' or 'close')
end

RegisterCommand('abrirnegocio', function(source)
    if source > 0 then SetBusinessOpen(source, true) end
end, false)

RegisterCommand('cerrarnegocio', function(source)
    if source > 0 then SetBusinessOpen(source, false) end
end, false)

RegisterNetEvent('jj_creatorjobs:server:AbrirCerrarNegocio', function()
    local src = source
    local _, _, job = GetPlayerContext(src)
    if job then
        SetBusinessOpen(src, not job.open)
    end
end)

RegisterNetEvent('jj_creatorjobs:server:EnviarAnuncio', function(mensaje)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job or not HasJobOption(jobName, 'Enviar anuncio') then return end

    mensaje = tostring(mensaje or '')
    if mensaje == '' or #mensaje > 280 then
        Notify(src, 'Mensaje de anuncio no válido', 'error')
        return
    end

    Log(src, 'negocio', jobName, ('Ha enviado un anuncio: %s'):format(mensaje))
    TriggerClientEvent('jj_creatorjobs:client:sendAnuncio', -1, job.label, mensaje)
end)

-- =============================================================
-- Cachear e incautar
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:search', function(source, targetId)
    local player, jobName, job, jobData = GetPlayerContext(source)
    if not player or not job or not jobData.onDuty or not HasJobOption(jobName, 'Cachear') then return false end

    local target = JJ.GetPlayer(tonumber(targetId) or -1)
    if not target or target.source == source then return false end
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(target.source))) > SEARCH_DISTANCE then return false end

    exports.ox_inventory:forceOpenInventory(source, 'player', target.source)
    Log(source, 'empleados', jobName, ('Ha cacheado a %s'):format(target.getName()))
    return true
end)

-- Un vehículo con dueño va al depósito. Si no tiene dueño, el cliente lo borra
lib.callback.register('jj_creatorjobs:callback:impound', function(source, plate)
    local player, jobName, job, jobData = GetPlayerContext(source)
    if not player or not job or not jobData.onDuty or not HasJobOption(jobName, 'Incautar') then return false end
    if GetResourceState('jj_garages') ~= 'started' then return false end
    if exports.jj_garages:impoundVehicle(plate, 0) ~= true then return false end
    Log(source, 'vehiculos', jobName, ('Ha incautado el vehículo %s'):format(tostring(plate)))
    return true
end)

-- =============================================================
-- Mercado y lonja
-- =============================================================

RegisterNetEvent('jj_creatorjobs:server:buyItem', function(infoItem)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job or type(infoItem) ~= 'table' then return end

    local marketId = tonumber(infoItem.id)
    local amount = math.floor(tonumber(infoItem.amount) or 0)
    if not marketId or amount <= 0 then return end

    local validLonja = false
    for _, lonja in ipairs(Config.Lonja) do
        if lonja.nameLonja == infoItem.typeLonja then validLonja = true end
    end
    if not validLonja then return end

    local marketRow = MySQL.single.await('SELECT name, price FROM jobscreator_market WHERE id = ? AND job = ?', { marketId, jobName })
    if not marketRow then
        Notify(src, 'Ese producto no está disponible en el mercado', 'error')
        return
    end

    local total = marketRow.price * amount
    if total > 0 and not job:RemoveMoney(total, 'Compra en el mercado') then
        Notify(src, ('La sociedad no tiene fondos suficientes ($%d necesarios)'):format(total), 'error')
        return
    end

    local itemData = exports.ox_inventory:Items(marketRow.name)
    local label = itemData and itemData.label or marketRow.name
    MySQL.insert.await('INSERT INTO jobscreator_lonja (job, name, label, amount, price, typeLonja) VALUES (?, ?, ?, ?, ?, ?)', {
        jobName, marketRow.name, label, amount, marketRow.price, infoItem.typeLonja,
    })

    Log(src, 'dinero', jobName, ('Ha pedido %dx %s por $%d'):format(amount, label, total), 'caja')
    Notify(src, ('Pedido realizado: %dx %s. Recógelo en %s'):format(amount, label, infoItem.typeLonja), 'success')
end)

RegisterNetEvent('jj_creatorjobs:server:removeItemLonja', function(infoItem)
    local src = source
    local player, jobName, job = GetPlayerContext(src)
    if not player or not job or type(infoItem) ~= 'table' then return end

    local id = tonumber(infoItem.id)
    local amount = math.floor(tonumber(infoItem.amount) or 0)
    if not id or amount <= 0 then return end

    local row = MySQL.single.await('SELECT name, amount FROM jobscreator_lonja WHERE id = ? AND job = ?', { id, jobName })
    if not row then
        Notify(src, 'Ese pedido ya no existe', 'error')
        return
    end

    if amount > row.amount then
        Notify(src, 'No hay suficiente cantidad en el pedido', 'error')
        return
    end

    if not exports.ox_inventory:CanCarryItem(src, row.name, amount) then
        Notify(src, 'No puedes llevar tanto peso encima', 'error')
        return
    end

    if not exports.ox_inventory:AddItem(src, row.name, amount) then
        Notify(src, 'No se pudo añadir el objeto a tu inventario', 'error')
        return
    end

    if amount == row.amount then
        MySQL.query.await('DELETE FROM jobscreator_lonja WHERE id = ?', { id })
    else
        MySQL.update.await('UPDATE jobscreator_lonja SET amount = amount - ? WHERE id = ?', { amount, id })
    end

    Log(src, 'negocio', jobName, ('Ha recogido %dx %s de la lonja'):format(amount, row.name))
    Notify(src, ('Has recogido %dx %s'):format(amount, row.name), 'success')
end)

-- =============================================================
-- Compraventa de vehículos
-- =============================================================

local function NormalizePlate(plate)
    return (tostring(plate or ''):gsub('%s+', ''):upper())
end

-- El empleado propone el trato. El precio y la matrícula quedan aquí: el cliente solo acepta o rechaza
local function ProposeDeal(src, kind, targetId, matricula, precio)
    local player, jobName, job, jobData = GetPlayerContext(src)
    if not player or not job or not jobData.onDuty or not HasJobOption(jobName, 'Compraventa') then return end

    local target = JJ.GetPlayer(tonumber(targetId) or -1)
    if not target then
        Notify(src, 'El jugador no está conectado', 'error')
        return
    end

    local price = math.floor(tonumber(precio) or 0)
    if price <= 0 or price > MAX_DEAL_PRICE then
        Notify(src, 'Precio no válido', 'error')
        return
    end

    local plate = NormalizePlate(matricula)
    local vehicle
    if kind == 'buy' then
        vehicle = MySQL.scalar.await('SELECT model FROM jj_vehicles WHERE owner = ? AND plate = ? AND state <> 2', { target.identifier, plate })
        if not vehicle then
            Notify(src, 'Ese jugador no tiene ningún vehículo disponible con esa matrícula', 'error')
            return
        end
    else
        vehicle = MySQL.scalar.await('SELECT vehicle FROM jobscreator_compraventa WHERE plate = ? AND job = ?', { plate, jobName })
        if not vehicle then
            Notify(src, 'No hay ningún vehículo con esa matrícula en el stock', 'error')
            return
        end
    end

    PendingDeals[target.source] = {
        kind = kind,
        plate = plate,
        price = price,
        employee = src,
        job = jobName,
        vehicle = vehicle,
        time = os.time(),
    }

    TriggerClientEvent('jj_creatorjobs:client:confirmDeal', target.source, kind, plate, price, vehicle)
end

RegisterNetEvent('jj_creatorjobs:server:sendMenuCarBuy', function(targetId, matricula, precio)
    ProposeDeal(source, 'buy', targetId, matricula, precio)
end)

RegisterNetEvent('jj_creatorjobs:server:sendMenuCarSell', function(targetId, matricula, precio)
    ProposeDeal(source, 'sell', targetId, matricula, precio)
end)

-- El propietario vende su vehículo a la compraventa
local function CompleteVehiclePurchase(src, seller, deal, job)
    local row = MySQL.single.await('SELECT model, props, state FROM jj_vehicles WHERE owner = ? AND plate = ?', { seller.identifier, deal.plate })
    if not row or row.state == 2 then
        Notify(src, 'No se ha encontrado tu vehículo', 'error')
        return
    end

    if not job:RemoveMoney(deal.price, 'Compra de vehículo') then
        Notify(src, 'La compraventa no tiene fondos suficientes', 'error')
        Notify(deal.employee, 'La sociedad no tiene fondos suficientes para esta compra', 'error')
        return
    end

    MySQL.query.await('DELETE FROM jj_vehicles WHERE plate = ?', { deal.plate })
    -- Si el vehículo está en la calle, queda marcado como sacado en la compraventa
    MySQL.insert.await('INSERT INTO jobscreator_compraventa (job, vehicle, plate, price, mods, state) VALUES (?, ?, ?, ?, ?, ?)', {
        deal.job, row.model, deal.plate, deal.price, row.props, row.state == 0 and 1 or 0
    })

    seller.addMoney('cash', deal.price, 'venta-vehiculo-compraventa')
    Log(deal.employee, 'vehiculos', deal.job, ('Ha comprado un %s (%s) a %s por $%d'):format(row.model, deal.plate, seller.getName(), deal.price), 'compraventa')
    Notify(src, ('Has vendido tu %s por $%d'):format(row.model, deal.price), 'success')
    Notify(deal.employee, ('Has comprado un %s (%s) por $%d'):format(row.model, deal.plate, deal.price), 'success')
end

-- El cliente compra un vehículo del stock de la compraventa
local function CompleteVehicleSale(src, buyer, deal, job)
    local stock = MySQL.single.await('SELECT id, vehicle, mods, state FROM jobscreator_compraventa WHERE plate = ? AND job = ?', { deal.plate, deal.job })
    if not stock then
        Notify(src, 'Ese vehículo ya no está disponible', 'error')
        return
    end

    local reason = 'compra-vehiculo-compraventa'
    if not ChargePlayer(buyer, deal.price, reason) then
        Notify(src, 'No tienes suficiente dinero', 'error')
        return
    end

    if not job:AddMoney(deal.price, 'Venta de vehículo') then
        buyer.addMoney('bank', deal.price, 'devolucion-' .. reason)
        Notify(src, 'No se ha podido completar la compra: te hemos devuelto el dinero', 'error')
        Notify(deal.employee, 'La empresa no tiene una cuenta donde ingresar el dinero', 'error')
        return
    end

    MySQL.query.await('DELETE FROM jobscreator_compraventa WHERE id = ?', { stock.id })

    -- Fuera en la calle (0) si el vehículo ya está sacado; si no, en el garaje público
    local inWorld = tonumber(stock.state) == 1
    MySQL.insert.await('INSERT INTO jj_vehicles (plate, owner, model, props, state) VALUES (?, ?, ?, ?, ?)', {
        deal.plate, buyer.identifier, stock.vehicle, stock.mods or json.encode({}), inWorld and 0 or 1,
    })

    Log(deal.employee, 'vehiculos', deal.job, ('Ha vendido un %s (%s) a %s por $%d'):format(stock.vehicle, deal.plate, buyer.getName(), deal.price), 'compraventa')
    Notify(src, ('Has comprado un %s por $%d'):format(stock.vehicle, deal.price), 'success')
    Notify(deal.employee, ('Has vendido un %s (%s) por $%d'):format(stock.vehicle, deal.plate, deal.price), 'success')
end

RegisterNetEvent('jj_creatorjobs:server:respondDeal', function(accepted)
    local src = source
    local deal = PendingDeals[src]
    PendingDeals[src] = nil

    if not deal or os.time() - deal.time > DEAL_TIMEOUT then return end

    local client = JJ.GetPlayer(src)
    local employee = JJ.GetPlayer(deal.employee)
    local job = Jobs[deal.job]
    if not client or not job or not employee or employee.getJob().name ~= deal.job then return end

    if not accepted then
        Notify(deal.employee, 'El cliente ha rechazado el trato', 'error')
        return
    end

    if deal.kind == 'buy' then
        CompleteVehiclePurchase(src, client, deal, job)
    else
        CompleteVehicleSale(src, client, deal, job)
    end
end)

lib.callback.register('jj_creatorjobs:callback:takeStockVehicle', function(source, plate)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job then return false end

    plate = NormalizePlate(plate)
    local row = MySQL.single.await('SELECT vehicle, mods FROM jobscreator_compraventa WHERE plate = ? AND job = ? AND state = 0', { plate, jobName })
    if not row then return false end

    MySQL.update.await('UPDATE jobscreator_compraventa SET state = 1 WHERE plate = ? AND job = ?', { plate, jobName })
    if GetResourceState('jj_keysystem') == 'started' then
        exports.jj_keysystem:addTempKey(source, plate)
    end
    return { vehicle = row.vehicle, mods = row.mods, plate = plate }
end)

RegisterNetEvent('jj_creatorjobs:server:saveVehicle', function(plate, mods)
    local player, jobName, job = GetPlayerContext(source)
    if not player or not job or not plate then return end

    MySQL.update.await('UPDATE jobscreator_compraventa SET mods = ?, state = 0 WHERE plate = ? AND job = ?', {
        json.encode(mods or {}), NormalizePlate(plate), jobName
    })
end)

-- Vehículo de empresa: la matrícula y la llave las da el servidor
lib.callback.register('jj_creatorjobs:callback:takeJobVehicle', function(source, id)
    local player, jobName, job, jobData = GetPlayerContext(source)
    if not player or not job or not jobData.onDuty then return false end

    local row = MySQL.single.await('SELECT name, livery FROM jobscreator_vehicles WHERE id = ? AND job = ?', { tonumber(id), jobName })
    if not row then return false end

    local plate = lib.string.random('SPB.....'):upper()
    if GetResourceState('jj_keysystem') == 'started' then
        exports.jj_keysystem:addTempKey(source, plate)
    end
    Log(source, 'vehiculos', jobName, ('Ha sacado el vehículo %s (%s)'):format(row.name, plate))
    return { model = row.name, livery = tonumber(row.livery) or 0, plate = plate }
end)

-- =============================================================
-- Teleports globales: la contraseña y el mundo los decide el servidor
-- =============================================================

lib.callback.register('jj_creatorjobs:callback:useGlobalTeleport', function(source, id, side, password)
    local row = MySQL.single.await('SELECT password, bucket FROM jobscreator_global_teleports WHERE id = ?', { tonumber(id) })
    if not row then return false end

    if row.password and row.password ~= '' and row.password ~= password then
        return false
    end

    SetPlayerRoutingBucket(source, side == 'entrance' and (tonumber(row.bucket) or 0) or 0)
    return true
end)

-- =============================================================
-- Experiencia por las facturas pagadas en fd_banking
-- =============================================================

-- El banco no avisa cuando se paga una factura: se comprueba cada minuto.
-- Estados de fd_banking: 2 = pagada, 4 = cobrada a la fuerza
local function RewardPaidInvoices()
    local rows = MySQL.query.await([[
        SELECT i.id, i.amount, a.business
        FROM fd_advanced_banking_invoices i
        INNER JOIN fd_advanced_banking_accounts a ON a.id = i.transfer_to
        LEFT JOIN jobscreator_invoice_exp e ON e.invoice_id = i.id
        WHERE i.status IN (2, 4) AND a.is_society = 1 AND e.invoice_id IS NULL
    ]]) or {}

    for _, row in ipairs(rows) do
        MySQL.insert.await('INSERT IGNORE INTO jobscreator_invoice_exp (invoice_id) VALUES (?)', { row.id })
        local job = Jobs[row.business]
        if job then
            AddBillExp(job, tonumber(row.amount) or 0)
            Log(nil, 'facturas', row.business, ('Han pagado una factura de $%s'):format(row.amount))
        end
    end
end

CreateThread(function()
    while true do
        Wait(INVOICE_CHECK_INTERVAL)
        if JobsReady and UsesBank() then
            pcall(RewardPaidInvoices)
        end
    end
end)

-- =============================================================
-- Nóminas pagadas desde la cuenta de la sociedad
-- =============================================================

if Config.SocietyPaycheck then
    CreateThread(function()
        while true do
            -- Espera hasta el próximo minuto :00 o :30 de la hora del servidor
            local now = os.date('*t')
            local secondsToNext = (30 - (now.min % 30)) * 60 - now.sec
            Wait(secondsToNext * 1000)

            for _, src in ipairs(JJ.GetPlayers()) do
                local player, jobName, job, jobData = GetPlayerContext(src)

                if job and jobData.onDuty and player.isSpawned() then
                    local payment = tonumber(MySQL.scalar.await('SELECT salary FROM jobscreator_grades WHERE job_name = ? AND id = ?', { jobName, jobData.grade })) or 0

                    if payment > 0 then
                        if job:RemoveMoney(payment, 'Sueldo de ' .. player.getName()) then
                            player.addMoney('bank', payment, 'sueldo-' .. jobName)
                            Notify(src, ('Has cobrado tu sueldo de $%d'):format(payment), 'success')
                            -- fd_banking actualiza el saldo en segundo plano
                            Wait(250)
                        else
                            Notify(src, ('%s no tiene fondos para pagar tu sueldo'):format(job.label), 'error')
                        end
                    end
                end
            end
        end
    end)
end
