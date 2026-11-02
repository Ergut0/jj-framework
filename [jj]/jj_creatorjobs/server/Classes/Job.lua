--[[
    Clase Job - Representa un trabajo creado con el Job Creator.
    Gestiona dinero de la sociedad, experiencia, nivel y estado (abierto/cerrado)
    con persistencia en la tabla `jobscreator_jobs`.
]]

Job = {}
Job.__index = Job

local INVOICE_UNPAID = 1

--- oxmysql devuelve las columnas TINYINT(1) como booleanos, y el código propio usa 1 y 0.
function IsTrue(value)
    return value == true or tonumber(value) == 1
end

-- La cuenta de la sociedad está en fd_banking. Sin ese recurso se usa la columna money
function UsesBank()
    return Config.UseBanking == true and GetResourceState('fd_banking') == 'started'
end

--- Crea una instancia de Job a partir de una fila de la base de datos.
--- @param data table Fila de jobscreator_jobs
--- @return table
function Job.New(data)
    local self = setmetatable({}, Job)
    self.id = tonumber(data.id)
    self.name = data.name
    self.label = data.label
    self.img = data.img
    self.open = IsTrue(data.open)
    self.level = tonumber(data.level) or 1
    self.experience = tonumber(data.experience) or 0
    self.money = tonumber(data.money) or 0
    return self
end

--- Guarda el estado actual del trabajo en la base de datos.
function Job:Save()
    MySQL.update('UPDATE jobscreator_jobs SET label = ?, img = ?, open = ?, level = ?, experience = ?, money = ? WHERE name = ?', {
        self.label,
        self.img,
        self.open and 1 or 0,
        self.level,
        self.experience,
        self.money,
        self.name
    })
end

--- Devuelve el dinero de la sociedad.
--- @return number
function Job:GetMoney()
    if UsesBank() then
        return tonumber(exports.fd_banking:GetAccount(self.name)) or 0
    end
    return self.money
end

--- Añade dinero a la sociedad.
--- @param amount number
--- @param reason? string
--- @return boolean success
function Job:AddMoney(amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    if UsesBank() then
        return exports.fd_banking:AddMoney(self.name, amount, reason or 'Job Creator') == true
    end

    self.money = self.money + amount
    self:Save()
    return true
end

--- Quita dinero de la sociedad.
--- @param amount number
--- @param reason? string
--- @return boolean success True si había fondos suficientes.
function Job:RemoveMoney(amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or self:GetMoney() < amount then return false end

    if UsesBank() then
        return exports.fd_banking:RemoveMoney(self.name, amount, reason or 'Job Creator') == true
    end

    self.money = self.money - amount
    self:Save()
    return true
end

--- Crea una factura en fd_banking para que el personaje la pague desde el banco.
--- El dinero llega a la cuenta de la empresa cuando la paga.
--- @param identifier string Personaje al que se factura
--- @param amount number
--- @param concept string
--- @return boolean success
function Job:AddInvoice(identifier, amount, concept)
    local account = exports.fd_banking:getBusinessAccount(self.name)
    if not account then return false end

    local ok, reason = pcall(function()
        exports.fd_banking:addInvoice(identifier, account.name, INVOICE_UNPAID, amount, concept, account.id, true)
    end)
    if not ok then
        print(('[jj_creatorjobs] No se ha podido crear la factura de %s: %s'):format(self.name, tostring(reason)))
    end
    return ok
end

--- Añade experiencia al trabajo y sube de nivel si corresponde.
--- @param amount number Cantidad de experiencia a añadir.
--- @return boolean leveledUp
function Job:AddExp(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local leveledUp = false
    self.experience = self.experience + amount

    while self.experience >= Config.MaxExp do
        if self.level >= Config.MaxLevel then
            self.experience = Config.MaxExp
            break
        end
        self.experience = self.experience - Config.MaxExp
        self.level = self.level + 1
        leveledUp = true
    end

    self:Save()
    return leveledUp
end

--- Cambia el estado abierto/cerrado del negocio.
--- @param open boolean
function Job:SetOpen(open)
    self.open = open and true or false
    self:Save()
    TriggerClientEvent('jj_creatorjobs:client:syncBlipStatus', -1, self.name, self.open)
end

--- Actualiza los datos básicos del trabajo.
--- @param data table { label, img, level, experience }
function Job:Update(data)
    if data.label then self.label = data.label end
    if data.img then self.img = data.img end
    if data.level then self.level = math.max(1, math.min(tonumber(data.level) or self.level, Config.MaxLevel)) end
    if data.experience then self.experience = math.max(0, math.min(tonumber(data.experience) or self.experience, Config.MaxExp)) end
    self:Save()
end
