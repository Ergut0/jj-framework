
function server.hasGroup(inv, group)
	if type(group) == 'table' then
		for name, rank in pairs(group) do
			local groupRank = inv.player.groups[name]
			if groupRank and groupRank >= (rank or 0) then
				return name, groupRank
			end
		end
	else
		local groupRank = inv.player.groups[group]
		if groupRank then
			return group, groupRank
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
	if not player.groups then
		warn(("server.setPlayerData did not receive any groups for '%s'"):format(player?.name or GetPlayerName(player)))
	end

	return {
		source = player.source,
		name = player.name,
		groups = player.groups or {},
		sex = player.sex,
		dateofbirth = player.dateofbirth,
	}
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense()
	warn('Licenses are not supported for the current framework.')
end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local function normaliseCurrency(currency)
	if type(currency) == 'string' then
		currency = currency:lower()
	else
		currency = 'money'
	end

	if currency == 'cash' then
		return 'money'
	end

	return currency
end

server.normaliseCurrency = normaliseCurrency

---@param inv OxInventory | number
---@param currency string
---@return number
function server.getCurrencyBalance(inv, currency)
	currency = normaliseCurrency(currency)
	return Inventory.GetItemCount(inv, currency)
end

---@param inv OxInventory | number
---@param currency string
---@param amount number
---@param context? string
function server.removeCurrency(inv, currency, amount, context)
	currency = normaliseCurrency(currency)
	return Inventory.RemoveItem(inv, currency, amount)
end

---@param currency string
---@param amount number
---@return string
function server.formatCurrencyLabel(currency, amount)
	local normalised = normaliseCurrency(currency)

	if normalised == 'money' then
		return ('%s%s'):format(locale('$'), math.groupdigits(amount))
	end

	if normalised == 'bank' then
		return ('%s %s'):format(math.groupdigits(amount), locale('bank_account') or 'Bank')
	end

	local label = Items(normalised)?.label or currency
	return ('%s %s'):format(math.groupdigits(amount), label)
end

function server.playerDropped(source)
	local inv = Inventory(source) --[[@as OxInventory]]

	if inv?.player then
		inv:closeInventory()
		Inventory.Remove(inv)
	end
end

local success, result = pcall(lib.load, ('modules.bridge.%s.server'):format(shared.framework))

if not success then
    lib = nil
    error(result, 0)
end

if server.convertInventory then exports('ConvertItems', server.convertInventory) end
