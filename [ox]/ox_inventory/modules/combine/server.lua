
local Inventory = require 'modules.inventory.server'
local CombineData = lib.load('data.combine') or {}

---@type table<string, table> recipe id -> recipe
local Recipes = {}

if CombineData.enabled and CombineData.recipes then
    for i = 1, #CombineData.recipes do
        local recipe = CombineData.recipes[i]
        local id = recipe.id or recipe.result

        if id and recipe.result and recipe.ingredients then
            Recipes[id] = recipe
        else
            warn(('combine: skipping invalid recipe at index %d (needs result + ingredients)'):format(i))
        end
    end
end

---@param source number player source / inventory id
---@param recipeId string
---@param count number how many times to run the recipe
---@return boolean success, string? reason
lib.callback.register('ox_inventory:combineItem', function(source, recipeId, count)
    if not CombineData.enabled then return false, 'disabled' end

    local recipe = Recipes[recipeId]
    if not recipe then return false, 'unknown_recipe' end

    count = math.floor(tonumber(count) or 1)
    if count < 1 then count = 1 end

    local ingredients = recipe.ingredients
    local resultItem = recipe.result
    local resultCount = (recipe.count or 1) * count

    for i = 1, #ingredients do
        local ing = ingredients[i]
        local need = (ing.count or 1) * count

        if need > 0 and Inventory.GetItemCount(source, ing.item) < need then
            return false, 'missing_ingredients'
        end
    end

    if not Inventory.CanCarryItem(source, resultItem, resultCount) then
        return false, 'cannot_carry'
    end

    for i = 1, #ingredients do
        local ing = ingredients[i]
        local need = (ing.count or 1) * count

        if need > 0 then
            local removed = Inventory.RemoveItem(source, ing.item, need)

            if not removed then
                return false, 'remove_failed'
            end
        end
    end

    local success = Inventory.AddItem(source, resultItem, resultCount, recipe.metadata or nil)

    if not success then
        return false, 'add_failed'
    end

    return true
end)
