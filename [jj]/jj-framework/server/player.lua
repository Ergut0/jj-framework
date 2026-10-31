local players = {}
local sourceByIdentifier = {}
local sourceByLicense = {}

local function validPosition(position)
    return type(position) == 'table'
        and type(position.x) == 'number'
        and type(position.y) == 'number'
        and type(position.z) == 'number'
end

-- Los métodos son closures (se llaman con punto) para que funcionen desde otros recursos,
-- ya que las metatablas y el self no sobreviven al pasar por un export.
function JJInternal.CreatePlayer(src, identifier, row)
    local name = row.charinfo and row.name or GetPlayerName(src)
    local charinfo = row.charinfo
    local skin = row.skin
    local accounts = row.accounts
    local metadata = row.metadata
    local job = JJ.Utils.BuildJob(row.job, row.job_grade) or JJ.Utils.BuildJob(Config.DefaultJob, 0)
    local position = validPosition(row.position) and row.position or Config.DefaultSpawn
    local spawned = false

    -- El servicio no se guarda: al conectarse o cambiar de trabajo se empieza de servicio
    job.onDuty = true

    local self = {
        source = src,
        identifier = identifier,
        license = row.license
    }

    local function sync(key, value)
        TriggerClientEvent('jj:client:playerDataUpdated', src, key, value)
    end

    local function moneyChanged(account, action, amount, reason)
        sync('accounts', accounts)
        TriggerEvent('jj:server:moneyChanged', src, account, action, amount, accounts[account], reason)
    end

    function self.getData()
        return {
            id = row.id,
            source = src,
            identifier = identifier,
            license = row.license,
            name = name,
            charinfo = charinfo,
            skin = skin,
            accounts = accounts,
            job = job,
            metadata = metadata,
            position = position
        }
    end

    function self.getName()
        return name
    end

    function self.getCharInfo()
        return charinfo
    end

    function self.getSkin()
        return skin
    end

    -- Aspecto del personaje en JSON, por ejemplo el que genera un recurso de ropa
    function self.setSkin(value)
        if type(value) ~= 'string' then
            return false
        end
        skin = value
        MySQL.update('UPDATE jj_players SET skin = ? WHERE identifier = ?', { skin, identifier })
        return true
    end

    function self.getMoney(account)
        return accounts[account]
    end

    function self.getAccounts()
        return accounts
    end

    function self.addMoney(account, value, reason)
        local amount = JJ.Utils.ToAmount(value)
        if not accounts[account] or not amount or not JJ.Utils.WithinLimit(accounts[account] + amount) then
            return false
        end
        accounts[account] = accounts[account] + amount
        moneyChanged(account, 'add', amount, reason)
        return true
    end

    function self.removeMoney(account, value, reason)
        local amount = JJ.Utils.ToAmount(value)
        if not accounts[account] or not amount or accounts[account] < amount then
            return false
        end
        accounts[account] = accounts[account] - amount
        moneyChanged(account, 'remove', amount, reason)
        return true
    end

    function self.setMoney(account, value, reason)
        local amount = JJ.Utils.ToAmount(value, true)
        if not accounts[account] or not amount then
            return false
        end
        accounts[account] = amount
        moneyChanged(account, 'set', amount, reason)
        return true
    end

    function self.getJob()
        return job
    end

    function self.setJob(jobName, grade)
        local newJob = JJ.Utils.BuildJob(jobName, grade)
        if not newJob then
            return false
        end
        newJob.onDuty = true
        local oldJob = job
        job = newJob
        sync('job', job)
        TriggerEvent('jj:server:jobChanged', src, job, oldJob)
        return true
    end

    function self.setDuty(onDuty)
        job.onDuty = onDuty == true
        sync('job', job)
        TriggerEvent('jj:server:dutyChanged', src, job.onDuty)
        return true
    end

    function self.getMetadata(key)
        if key == nil then
            return metadata
        end
        return metadata[key]
    end

    function self.setMetadata(key, value)
        if type(key) ~= 'string' then
            return false
        end
        metadata[key] = value
        sync('metadata', metadata)
        return true
    end

    function self.isSpawned()
        return spawned
    end

    function self.setSpawned()
        spawned = true
    end

    -- Hasta que el jugador aparece, su ped no está en su posición real y no se debe guardar
    function self.updatePosition()
        if not spawned then
            return
        end
        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then
            return
        end
        local coords = GetEntityCoords(ped)
        if coords.x == 0 and coords.y == 0 and coords.z == 0 then
            return
        end
        position = {
            x = JJ.Utils.Round(coords.x, 2),
            y = JJ.Utils.Round(coords.y, 2),
            z = JJ.Utils.Round(coords.z, 2),
            heading = JJ.Utils.Round(GetEntityHeading(ped), 2)
        }
    end

    function self.notify(message)
        JJ.Notify(src, message)
    end

    function self.kick(reason)
        DropPlayer(src, reason)
    end

    return self
end

function JJInternal.AddPlayer(player)
    players[player.source] = player
    sourceByIdentifier[player.identifier] = player.source
    if player.license then
        sourceByLicense[player.license] = player.source
    end
end

function JJInternal.RemovePlayer(src)
    local player = players[src]
    if player then
        sourceByIdentifier[player.identifier] = nil
        if player.license then
            sourceByLicense[player.license] = nil
        end
        players[src] = nil
    end
end

function JJInternal.EachPlayer()
    return pairs(players)
end

function JJ.GetPlayer(src)
    return players[tonumber(src)]
end

function JJ.GetPlayerByIdentifier(identifier)
    local src = sourceByIdentifier[identifier]
    return src and players[src] or nil
end

function JJ.GetPlayerByLicense(license)
    local src = sourceByLicense[license]
    return src and players[src] or nil
end

-- Devuelve los source de los jugadores cargados
function JJ.GetPlayers()
    local sources = {}
    for src in pairs(players) do
        sources[#sources + 1] = src
    end
    return sources
end

function JJ.Notify(src, message)
    TriggerClientEvent('jj:client:notify', src, message)
end

function JJ.IsAdmin(src)
    return src == 0 or IsPlayerAceAllowed(tostring(src), Config.AdminAce)
end
