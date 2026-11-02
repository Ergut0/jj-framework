local ESX
local QBCore
local Ox
local accountCache = {}
local playerInfoCache = {}

local function trim(value)
    return value and value:match('^%s*(.-)%s*$') or ''
end

local function getInventoryItemCount(name)
    if type(PlayerData?.inventory) ~= 'table' then return 0 end

    for _, item in pairs(PlayerData.inventory) do
        if item?.name == name then
            return item.count or 0
        end
    end

    return 0
end

local function getESX()
    if ESX then return ESX end

    local ok, obj = pcall(function()
        return exports.es_extended:getSharedObject()
    end)

    if ok and obj then ESX = obj end

    return ESX
end

local function getQBCore()
    if QBCore then return QBCore end

    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok and obj then QBCore = obj end

    return QBCore
end

local function getOx()
    if Ox then return Ox end

    local ok, obj = pcall(require, '@ox_core.lib.init')

    if ok and obj then Ox = obj end

    return Ox
end

local function getAccountMoney(playerData, accountName)
    if accountCache[accountName] then return accountCache[accountName] end
    if type(playerData?.accounts) ~= 'table' then return 0 end

    for name, account in pairs(playerData.accounts) do
        if name == accountName and type(account) == 'number' then
            return account
        end

        if account?.name == accountName then
            return account.money or 0
        end
    end

    return 0
end

local function formatESXJob(job)
    if type(job) ~= 'table' then return '' end

    local label = job.label or job.name or ''
    local grade = job.grade_label or job.grade_name or ''

    if label == '' then
        for name, rank in pairs(job) do
            label = tostring(name)
            grade = type(rank) == 'number' and tostring(rank) or ''
            break
        end
    end

    if label ~= '' and grade ~= '' then
        return ('%s - %s'):format(label, grade)
    end

    return label
end

local function applyESXInfo(info)
    local esx = getESX()
    local playerData = esx and esx.GetPlayerData and esx.GetPlayerData() or {}

    if info.cash == 0 then
        info.cash = playerData.money or getAccountMoney(playerData, 'money')
    end

    info.bank = getAccountMoney(playerData, 'bank')
    info.citizenLabel = 'Job'
    info.citizenId = formatESXJob(playerData.job or PlayerData?.groups)

    if playerData.firstName or playerData.lastName then
        info.name = trim(('%s %s'):format(playerData.firstName or '', playerData.lastName or ''))
    else
        info.name = playerData.name or PlayerData?.name or ''
    end
end

local function applyQBInfo(info)
    local core = shared.framework == 'qbx' and nil or getQBCore()
    local ok, playerData = pcall(function()
        if shared.framework == 'qbx' then
            return exports['qbx_core']:GetPlayerData()
        end

        return core and core.Functions.GetPlayerData()
    end)

    playerData = ok and playerData or {}

    if playerData.money then
        info.cash = playerData.money.cash or info.cash
        info.bank = playerData.money.bank or 0
    end

    info.citizenId = playerData.citizenid or PlayerData?.identifier or ''

    if playerData.charinfo then
        info.name = trim(('%s %s'):format(playerData.charinfo.firstname or '', playerData.charinfo.lastname or ''))
    else
        info.name = playerData.name or PlayerData?.name or ''
    end
end

local function applyNDInfo(info)
    local player = NDCore and NDCore.getPlayer and NDCore.getPlayer() or {}

    info.cash = player.cash or info.cash
    info.bank = player.bank or playerInfoCache.bank or 0
    info.citizenId = player.id or player.identifier or PlayerData?.identifier or ''
    info.name = trim(('%s %s'):format(player.firstname or '', player.lastname or ''))

    if info.name == '' then
        info.name = player.name or PlayerData?.name or ''
    end
end

local function applyOxInfo(info)
    local ox = getOx()
    local player = ox and ox.GetPlayer and ox.GetPlayer() or {}

    info.cash = playerInfoCache.cash or info.cash
    info.bank = playerInfoCache.bank or 0
    info.citizenId = player.charId or player.stateId or playerInfoCache.citizenId or PlayerData?.identifier or ''
    info.name = player.name or playerInfoCache.name or PlayerData?.name or ''
end

local function applyJJInfo(info)
    local ok, playerData = pcall(function()
        return exports['jj-framework']:GetCoreObject().GetPlayerData()
    end)

    playerData = ok and playerData or {}

    if playerData.accounts then
        info.cash = playerData.accounts.cash or info.cash
        info.bank = playerData.accounts.bank or 0
    end

    info.citizenId = playerData.identifier or PlayerData?.identifier or ''
    info.name = playerData.name or PlayerData?.name or ''
end

local function GetPlayerInfo()
    local info = {
        cash = getInventoryItemCount('money'),
        bank = 0,
        playerId = cache.serverId or 0,
        citizenId = PlayerData?.identifier or '',
        citizenLabel = nil,
        name = PlayerData?.name or '',
    }

    if shared.framework == 'esx' then
        applyESXInfo(info)
    elseif shared.framework == 'qb' or shared.framework == 'qbx' then
        applyQBInfo(info)
    elseif shared.framework == 'nd' then
        applyNDInfo(info)
    elseif shared.framework == 'ox' then
        applyOxInfo(info)
    elseif shared.framework == 'jj' then
        applyJJInfo(info)
    end

    return info
end

local function SendPlayerInfo()
    SendNUIMessage({ action = 'setPlayerInfo', data = GetPlayerInfo() })
end

AddStateBagChangeHandler('invOpen', nil, function(bagName, _, value)
    if bagName ~= ('player:%s'):format(cache.serverId) then return end
    if value then SendPlayerInfo() end
end)

AddEventHandler('esx:setPlayerData', function()
    SendPlayerInfo()
end)

RegisterNetEvent('esx:setAccountMoney', function(account)
    if account?.name then
        accountCache[account.name] = account.money or 0
    end

    SendPlayerInfo()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    SendPlayerInfo()
end)

RegisterNetEvent('qbx_core:client:onMoneyChange', function()
    SendPlayerInfo()
end)

RegisterNetEvent('ND:updateCharacter', function(character)
    if character then
        playerInfoCache.bank = character.bank
        playerInfoCache.name = trim(('%s %s'):format(character.firstname or '', character.lastname or ''))
        playerInfoCache.citizenId = character.id or character.identifier
    end

    SendPlayerInfo()
end)

RegisterNetEvent('ox:setGroup', function()
    SendPlayerInfo()
end)

AddEventHandler('jj:client:playerDataChanged', function()
    SendPlayerInfo()
end)

RegisterNetEvent('ox_inventory:updateInventory', function()
    SendPlayerInfo()
end)

RegisterNUICallback('getPlayerInfo', function(_, cb)
    cb(GetPlayerInfo())
end)
