if not lib then return end

local Utils = {}

local webHook = GetConvar('inventory:webhook', '')

if webHook ~= '' then
	local validHosts = {
		['i.imgur.com'] = true,
	}

	local validExtensions = {
		['png'] = true,
		['apng'] = true,
		['webp'] = true,
	}

	local headers = { ['Content-Type'] = 'application/json' }

	function Utils.IsValidImageUrl(url)
		local isUri = url:match("^nui://.+")

		if isUri then
			local extension = url:match('%.([%l]+)$')
			return extension and validExtensions[extension]
		end

		local host, extension = url:match('^https?://([^/]+).+%.([%l]+)')
		return host and extension and validHosts[host] and validExtensions[extension]
	end

	---@param title string
	---@param message string
	---@param image string
	function Utils.DiscordEmbed(title, message, image, color)
		PerformHttpRequest(webHook, function() end, 'POST', json.encode({
			username = 'ox_inventory', embeds = {
				{
					title = title,
					color = color,
					footer = {
						text = os.date('%c'),
					},
					description = message,
					thumbnail = {
						url = image,
						width = 100,
					}
				}
			}
		}), headers)
	end
end

---@param source number | string
---@param event string
---@param message string
---@param shouldDrop? boolean
function Utils.LogExploit(source, event, message, shouldDrop)
	local logMessage = ('%s triggered %s: %s'):format(source, event, message)

	warn(logMessage)

	if webHook ~= '' and Utils.DiscordEmbed then
		Utils.DiscordEmbed('Exploit attempt detected', logMessage, '', 16711680)
	end

	if shouldDrop and type(source) == 'number' then
		DropPlayer(source, 'Invalid inventory interaction')
	end
end

return Utils
