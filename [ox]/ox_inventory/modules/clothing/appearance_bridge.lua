
local AppearanceBridge = {}

local function detectResource()
    local priority = { 'illenium-appearance', 'fivem-appearance', 'rcore_clothing', 'esx_skin' }
    for _, name in ipairs(priority) do
        if GetResourceState(name) ~= 'missing' then
            return name
        end
    end
    return '_default'
end

AppearanceBridge.resource = detectResource()

if AppearanceBridge.resource == 'illenium-appearance' then

    function AppearanceBridge.getAppearance(ped)
        local ok, result = pcall(function()
            return exports['illenium-appearance']:getPedAppearance(ped)
        end)
        return ok and type(result) == 'table' and result or nil
    end

    function AppearanceBridge.setComponent(ped, componentId, drawable, texture)
        pcall(function()
            exports['illenium-appearance']:setPedComponent(ped, {
                component_id = componentId,
                drawable     = drawable,
                texture      = texture,
            })
        end)
    end

    function AppearanceBridge.setProp(ped, propId, drawable, texture)
        pcall(function()
            exports['illenium-appearance']:setPedProp(ped, {
                prop_id  = propId,
                drawable = drawable ~= nil and drawable or -1,
                texture  = texture or 0,
            })
        end)
    end

    function AppearanceBridge.applyFullAppearance(ped, appearance)
        if not appearance then return end
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(ped, appearance)
        end)
    end

    function AppearanceBridge.saveAppearance(ped)
        pcall(function()
            local appearance = exports['illenium-appearance']:getPedAppearance(ped)
            if appearance then
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            end
        end)
    end

elseif AppearanceBridge.resource == 'fivem-appearance' then

    local function faGet(ped)
        local ok, result = pcall(function()
            return exports['fivem-appearance']:getPedAppearance(ped)
        end)
        return ok and type(result) == 'table' and result or nil
    end

    function AppearanceBridge.getAppearance(ped)
        return faGet(ped)
    end

    function AppearanceBridge.setComponent(ped, componentId, drawable, texture)
        local appearance = faGet(ped)
        if appearance then
            for _, c in ipairs(appearance.components or {}) do
                if c.component_id == componentId then
                    c.drawable = drawable
                    c.texture  = texture
                    break
                end
            end
            pcall(function()
                exports['fivem-appearance']:setPedAppearance(ped, appearance)
            end)
        else
            SetPedComponentVariation(ped, componentId, drawable, texture, 0)
        end
    end

    function AppearanceBridge.setProp(ped, propId, drawable, texture)
        local appearance = faGet(ped)
        if appearance then
            for _, p in ipairs(appearance.props or {}) do
                if p.prop_id == propId then
                    p.drawable = drawable ~= nil and drawable or -1
                    p.texture  = texture or 0
                    break
                end
            end
            pcall(function()
                exports['fivem-appearance']:setPedAppearance(ped, appearance)
            end)
        else
            if drawable == nil or drawable < 0 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, drawable, texture or 0, false)
            end
        end
    end

    function AppearanceBridge.applyFullAppearance(ped, appearance)
        if not appearance then return end
        pcall(function()
            exports['fivem-appearance']:setPedAppearance(ped, appearance)
        end)
    end

    function AppearanceBridge.saveAppearance(ped)
    end

elseif AppearanceBridge.resource == 'rcore_clothing' then

    local function nativeSnapshot(ped)
        if not ped or ped == 0 then return nil end
        local components, props = {}, {}
        for i = 0, 11 do
            components[i + 1] = {
                component_id = i,
                drawable     = GetPedDrawableVariation(ped, i),
                texture      = GetPedTextureVariation(ped, i),
            }
        end
        for i = 0, 13 do
            props[i + 1] = {
                prop_id  = i,
                drawable = GetPedPropIndex(ped, i),
                texture  = GetPedPropTextureIndex(ped, i),
            }
        end
        return { components = components, props = props }
    end

    function AppearanceBridge.getAppearance(ped)
        local ok, skin = pcall(function()
            return exports['rcore_clothing']:getPlayerSkin(false)
        end)
        if ok and type(skin) == 'table' then
            local comps = skin.components
            if type(comps) == 'table' and comps[1] and comps[1].component_id ~= nil then
                return skin
            end
        end
        return nativeSnapshot(ped)
    end

    function AppearanceBridge.setComponent(ped, componentId, drawable, texture)
        SetPedComponentVariation(ped, componentId, drawable, texture, 0)
    end

    function AppearanceBridge.setProp(ped, propId, drawable, texture)
        if drawable == nil or drawable < 0 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawable, texture or 0, false)
        end
    end

    function AppearanceBridge.applyFullAppearance(ped, appearance)
        if not appearance then return end
        if ped == cache.ped then
            local ok = pcall(function()
                exports['rcore_clothing']:setPlayerSkin(appearance, false)
            end)
            if ok then return end
        end
        for _, c in ipairs(appearance.components or {}) do
            if c.component_id ~= nil then
                SetPedComponentVariation(ped, c.component_id, c.drawable or 0, c.texture or 0, 0)
            end
        end
        for _, p in ipairs(appearance.props or {}) do
            if p.prop_id ~= nil then
                if (p.drawable or -1) < 0 then
                    ClearPedProp(ped, p.prop_id)
                else
                    SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture or 0, false)
                end
            end
        end
    end

    function AppearanceBridge.saveAppearance(_ped)
        TriggerEvent('rcore_clothing:saveCurrentSkin')
    end

elseif AppearanceBridge.resource == 'esx_skin' then

    local COMPONENT_NAME = {
        [1]  = 'mask',
        [3]  = 'arms',
        [4]  = 'pants',
        [5]  = 'bags',
        [6]  = 'shoes',
        [7]  = 'chain',
        [8]  = 'tshirt',
        [9]  = 'bproof',
        [10] = 'decals',
        [11] = 'torso',
    }

    local PROP_NAME = {
        [0] = 'helmet',
        [1] = 'glasses',
        [2] = 'ears',
        [6] = 'watches',
        [7] = 'bracelets',
    }

    local function nativeSnapshot(ped)
        if not ped or ped == 0 then return nil end
        local components, props = {}, {}
        for i = 0, 11 do
            components[i + 1] = {
                component_id = i,
                drawable     = GetPedDrawableVariation(ped, i),
                texture      = GetPedTextureVariation(ped, i),
            }
        end
        for i = 0, 13 do
            props[i + 1] = {
                prop_id  = i,
                drawable = GetPedPropIndex(ped, i),
                texture  = GetPedPropTextureIndex(ped, i),
            }
        end
        return { components = components, props = props }
    end

    local function toEsxSkin(appearance)
        local skin = {}
        for _, c in ipairs(appearance.components or {}) do
            local name = COMPONENT_NAME[c.component_id]
            if name then
                skin[name .. '_1'] = c.drawable or 0
                skin[name .. '_2'] = c.texture  or 0
            end
        end
        for _, p in ipairs(appearance.props or {}) do
            local name = PROP_NAME[p.prop_id]
            if name then
                skin[name .. '_1'] = p.drawable ~= nil and p.drawable or -1
                skin[name .. '_2'] = p.texture  or 0
            end
        end
        return skin
    end

    function AppearanceBridge.getAppearance(ped)
        return nativeSnapshot(ped)
    end

    function AppearanceBridge.setComponent(ped, componentId, drawable, texture)
        SetPedComponentVariation(ped, componentId, drawable, texture, 0)
    end

    function AppearanceBridge.setProp(ped, propId, drawable, texture)
        if drawable == nil or drawable < 0 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawable, texture or 0, false)
        end
    end

    function AppearanceBridge.applyFullAppearance(ped, appearance)
        if not appearance then return end
        if ped == cache.ped then
            TriggerEvent('skinchanger:loadSkin', toEsxSkin(appearance))
            return
        end
        for _, c in ipairs(appearance.components or {}) do
            if c.component_id ~= nil then
                SetPedComponentVariation(ped, c.component_id, c.drawable or 0, c.texture or 0, 0)
            end
        end
        for _, p in ipairs(appearance.props or {}) do
            if p.prop_id ~= nil then
                if (p.drawable or -1) < 0 then
                    ClearPedProp(ped, p.prop_id)
                else
                    SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture or 0, false)
                end
            end
        end
    end

    function AppearanceBridge.saveAppearance(ped)
        local appearance = nativeSnapshot(ped)
        if appearance then
            TriggerServerEvent('skinchanger:save', toEsxSkin(appearance))
        end
    end

else

    function AppearanceBridge.getAppearance(ped)
        if not ped or ped == 0 then return nil end
        local components, props = {}, {}
        for i = 0, 11 do
            components[i + 1] = {
                component_id = i,
                drawable     = GetPedDrawableVariation(ped, i),
                texture      = GetPedTextureVariation(ped, i),
            }
        end
        for i = 0, 13 do
            props[i + 1] = {
                prop_id  = i,
                drawable = GetPedPropIndex(ped, i),
                texture  = GetPedPropTextureIndex(ped, i),
            }
        end
        return { components = components, props = props }
    end

    function AppearanceBridge.setComponent(ped, componentId, drawable, texture)
        SetPedComponentVariation(ped, componentId, drawable, texture, 0)
    end

    function AppearanceBridge.setProp(ped, propId, drawable, texture)
        if drawable == nil or drawable < 0 then
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, drawable, texture or 0, false)
        end
    end

    function AppearanceBridge.applyFullAppearance(ped, appearance)
        if not appearance then return end
        for _, c in ipairs(appearance.components or {}) do
            if c.component_id ~= nil then
                SetPedComponentVariation(ped, c.component_id, c.drawable or 0, c.texture or 0, 0)
            end
        end
        for _, p in ipairs(appearance.props or {}) do
            if p.prop_id ~= nil then
                if (p.drawable or -1) < 0 then
                    ClearPedProp(ped, p.prop_id)
                else
                    SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture or 0, false)
                end
            end
        end
    end

    function AppearanceBridge.saveAppearance(_ped)

    end

end

return AppearanceBridge
