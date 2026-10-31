if not Framework.JJ() then return end

local client = client

local JJ = exports["jj-framework"]:GetCoreObject()

local PlayerData = nil

-- jj-framework no tiene bandas: las restricciones de banda nunca coinciden
client.job = { name = "unemployed", grade = { level = 0 } }
client.gang = { name = "none", grade = { level = 0 } }

local function setClientJob(job)
    client.job = {
        name = job.name,
        label = job.label,
        onduty = job.onDuty,
        isboss = job.isBoss,
        grade = { level = job.grade, name = job.gradeLabel },
    }
end

function Framework.UpdatePlayerData()
    PlayerData = JJ.GetPlayerData()
    if PlayerData then
        setClientJob(PlayerData.job)
        client.citizenid = PlayerData.identifier
    end
end

function Framework.GetPlayerGender()
    local charinfo = PlayerData and PlayerData.charinfo
    if charinfo and charinfo.gender == 1 then
        return "Female"
    end
    return "Male"
end

function Framework.HasTracker()
    return false
end

function Framework.CheckPlayerMeta()
    local metadata = PlayerData and PlayerData.metadata or {}
    return metadata.isdead or metadata.inlaststand or LocalPlayer.state.isCuffed
end

function Framework.IsPlayerAllowed(identifier)
    return identifier == client.citizenid
end

function Framework.GetRankInputValues(rankType)
    local rankValues = {}
    if rankType == "gang" then
        return rankValues
    end
    for level, grade in pairs(JJ.Config.Jobs[client.job.name].grades) do
        rankValues[#rankValues + 1] = { label = grade.label, value = level }
    end
    return rankValues
end

function Framework.GetJobGrade()
    return client.job.grade.level
end

function Framework.GetGangGrade()
    return client.gang.grade.level
end

function Framework.CachePed()
    return nil
end

function Framework.RestorePlayerArmour() end

-- Un personaje sin aspecto guardado abre el creador nada más aparecer
AddEventHandler("jj:client:playerSpawned", function()
    Framework.UpdatePlayerData()
    if PlayerData and PlayerData.skin then
        InitAppearance()
    else
        InitializeCharacter(Framework.GetGender(true))
    end
end)

AddEventHandler("jj:client:playerDataChanged", function(key)
    Framework.UpdatePlayerData()
    if key == "job" then
        ResetBlips()
    end
end)

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler("onResourceStart", function(resource)
    if resource == "jj-framework" then
        JJ = exports["jj-framework"]:GetCoreObject()
    end
end)
