local ANIM_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local PROP_MODEL = `prop_cs_tablet`

local isOpen = false
local tabletProp
local jobNames = {}
local items

local function getItems()
    items = items or exports.ox_inventory:Items()
    return items
end

AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'ox_inventory' then items = nil end
end)

-- El servidor solo conoce el nombre y el precio: la etiqueta y la imagen salen del inventario del jugador
local function hydrateItem(item)
    local data = getItems()[item.name]
    if not data then return nil end

    local image = data.client and data.client.image or (item.name .. '.png')
    if not image:find('://', 1, true) then
        image = 'nui://ox_inventory/web/images/' .. image
    end

    return { name = item.name, price = item.price, label = data.label or item.name, image = image }
end

local function hydrateList(list)
    local result = {}
    for _, item in ipairs(list or {}) do
        result[#result + 1] = hydrateItem(item)
    end
    return result
end

function HydrateBusiness(business)
    business.market = hydrateList(business.market)

    for _, category in ipairs(business.categories or {}) do
        category.items = hydrateList(category.items)
    end

    local promotions = {}
    for _, promotion in ipairs(business.promotions or {}) do
        promotion.item = hydrateItem(promotion.item)
        if promotion.item then
            promotions[#promotions + 1] = promotion
        end
    end
    business.promotions = promotions

    return business
end

local function startAnimation()
    lib.requestAnimDict(ANIM_DICT)
    lib.requestModel(PROP_MODEL)

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(PROP_MODEL, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(PROP_MODEL)

    TaskPlayAnim(ped, ANIM_DICT, 'base', 3.0, 3.0, -1, 49, 0, false, false, false)
end

local function stopAnimation()
    if tabletProp then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end

    StopAnimTask(cache.ped, ANIM_DICT, 'base', 1.0)
    RemoveAnimDict(ANIM_DICT)
end

local function openTablet()
    if isOpen then return true end

    local data = lib.callback.await('jj_bizztablet:getData', false)
    if not data then return false end

    jobNames = {}
    for _, business in ipairs(data.jobs) do
        HydrateBusiness(business)
        jobNames[business.name] = true
    end

    isOpen = true
    SendNui('tablet:open', data)
    SetNuiFocus(true, true)
    startAnimation()

    return true
end

exports('openTablet', function()
    openTablet()
end)

exports('openEvents', function()
    if openTablet() then
        SendNui('tablet:setRoute', '/tablet/events')
    end
end)

exports('openJobPage', function(job)
    if not job or not openTablet() or not jobNames[job] then return false end

    SendNui('tablet:setRoute', '/tablet/businesses/' .. job)
    return true
end)

NuiOn('tablet:close', function()
    isOpen = false
    SetNuiFocus(false, false)
    stopAnimation()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
        stopAnimation()
    end
end)
