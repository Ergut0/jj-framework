
local CombineData = lib.load('data.combine') or {}

local Combine = {}

local combineAnim = CombineData.animation
if combineAnim == nil then
    combineAnim = {
        dict = 'amb@prop_human_parking_meter@male@base',
        clip = 'base',
        flag = 49,
    }
end
local animPlaying = false

local function startCombineAnim()
    if not combineAnim or animPlaying then return end
    animPlaying = true

    CreateThread(function()
        lib.requestAnimDict(combineAnim.dict)

        if animPlaying then
            TaskPlayAnim(cache.ped, combineAnim.dict, combineAnim.clip, 4.0, -4.0, -1, combineAnim.flag or 49, 0.0, false, false, false)
        end

        RemoveAnimDict(combineAnim.dict)
    end)
end

local function stopCombineAnim()
    if not animPlaying then return end
    animPlaying = false

    if cache.ped then
        StopAnimTask(cache.ped, combineAnim.dict, combineAnim.clip, 4.0)
    end
end

local function buildUIData()
    if not (CombineData.enabled and CombineData.recipes) then
        return { enabled = false, categories = {}, recipes = {} }
    end

    local recipes = {}

    for i = 1, #CombineData.recipes do
        local r = CombineData.recipes[i]
        local id = r.id or r.result

        if id and r.result and r.ingredients then
            recipes[#recipes + 1] = {
                id = id,
                result = r.result,
                count = r.count or 1,
                category = r.category,
                label = r.label,
                duration = r.duration,
                ingredients = r.ingredients,
                layout = r.layout,
            }
        end
    end

    return {
        enabled = true,
        categories = CombineData.categories or {},
        recipes = recipes,
    }
end

Combine.uiData = buildUIData()

RegisterNUICallback('combineItem', function(payload, cb)
    if type(payload) ~= 'table' or not payload.recipe then
        return cb(false)
    end

    local success = lib.callback.await('ox_inventory:combineItem', false, payload.recipe, payload.count or 1)
    cb(success or false)
end)

RegisterNUICallback('combineAnim', function(data, cb)
    if type(data) == 'table' and data.active then
        startCombineAnim()
    else
        stopCombineAnim()
    end

    cb(1)
end)

RegisterNUICallback('combineAnimStop', function(_, cb)
    stopCombineAnim()
    cb(1)
end)

return Combine
