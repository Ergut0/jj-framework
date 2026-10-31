if not Framework.JJ() then return end

local JJ = exports["jj-framework"]:GetCoreObject()

function Framework.GetPlayerID(src)
    local player = JJ.GetPlayer(src)
    return player and player.identifier
end

function Framework.HasMoney(src, type, money)
    local player = JJ.GetPlayer(src)
    return player ~= nil and player.getMoney(type) >= money
end

function Framework.RemoveMoney(src, type, money)
    if money <= 0 then
        return true
    end
    local player = JJ.GetPlayer(src)
    return player ~= nil and player.removeMoney(type, money, "illenium-appearance")
end

function Framework.GetJob(src)
    local player = JJ.GetPlayer(src)
    local job = player and player.getJob()
    return job and { name = job.name, grade = { level = job.grade } } or { name = "none", grade = { level = 0 } }
end

-- jj-framework no tiene bandas
function Framework.GetGang()
    return { name = "none", grade = { level = 0 } }
end

-- El aspecto se guarda en el personaje (jj_players.skin), donde también lo lee jj_multicharacter
function Framework.SaveAppearance(appearance, identifier)
    local player = identifier and JJ.GetPlayerByIdentifier(identifier)
    if player and type(appearance) == "table" then
        player.setSkin(json.encode(appearance))
    end
end

function Framework.GetAppearance(identifier, model)
    local player = identifier and JJ.GetPlayerByIdentifier(identifier)
    local skin = player and player.getSkin()
    if type(skin) ~= "string" then
        return nil
    end

    local ok, appearance = pcall(json.decode, skin)
    if not ok or type(appearance) ~= "table" then
        return nil
    end
    if model ~= nil and appearance.model ~= model then
        return nil
    end
    return appearance
end

AddEventHandler("onResourceStart", function(resource)
    if resource == "jj-framework" then
        JJ = exports["jj-framework"]:GetCoreObject()
    end
end)
