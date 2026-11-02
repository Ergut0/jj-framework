local MAX_BUTTONS = 2

local JJ = exports['jj-framework']:GetCoreObject()

-- El objeto obtenido con GetCoreObject deja de ser válido al reiniciar jj-framework
AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'jj-framework' then
        JJ = exports['jj-framework']:GetCoreObject()
    end
end)

local function isSpawned()
    return LocalPlayer.state.isLoggedIn == true or JJ.IsSpawned()
end

local function getCharacterName(data)
    local charinfo = data and data.charinfo
    if charinfo then
        return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
    end
    return data and data.name or GetPlayerName(PlayerId())
end

local function buildText()
    local data = JJ.GetPlayerData()
    local template = isSpawned() and Config.Text or Config.TextBeforeSpawn
    -- Con una tabla, un nombre con % o { } se escribe tal cual
    local text = template:gsub('{(%w+)}', {
        id = tostring(GetPlayerServerId(PlayerId())),
        players = tostring(GlobalState.jjPlayerCount or 1),
        max = tostring(GlobalState.jjMaxPlayers or 48),
        name = getCharacterName(data),
        job = data and data.job and data.job.label or '',
    })
    return text
end

local function setupApplication()
    if Config.AppId == '' then return end

    SetDiscordAppId(Config.AppId)

    if Config.LargeImage ~= '' then
        SetDiscordRichPresenceAsset(Config.LargeImage)
        SetDiscordRichPresenceAssetText(Config.LargeImageText)
    end
    if Config.SmallImage ~= '' then
        SetDiscordRichPresenceAssetSmall(Config.SmallImage)
        SetDiscordRichPresenceAssetSmallText(Config.SmallImageText)
    end

    for index, button in ipairs(Config.Buttons) do
        if index > MAX_BUTTONS then break end
        SetDiscordRichPresenceAction(index - 1, button.label, button.url)
    end
end

CreateThread(function()
    setupApplication()
    while true do
        SetRichPresence(buildText())
        Wait(Config.Interval * 1000)
    end
end)
