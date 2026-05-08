local LeaderboardService = {}

local function defaultFormatter(value)
	return tostring(value)
end

function LeaderboardService:BuildEntries(players, valueGetter, formatter)
	local getValue = valueGetter or function() return 0 end
	local formatValue = formatter or defaultFormatter
	local entries = {}
	for _, player in ipairs(players or {}) do
		table.insert(entries, {
			player = player,
			value = getValue(player),
		})
	end
	table.sort(entries, function(a, b)
		if a.value == b.value then
			return tostring(a.player and a.player.Name or "") < tostring(b.player and b.player.Name or "")
		end
		return a.value > b.value
	end)
	for index, entry in ipairs(entries) do
		entry.rank = index
		entry.formattedValue = formatValue(entry.value)
	end
	return entries
end

function LeaderboardService:GetTopPlayers(entries, topCount)
	local result = {}
	local limit = math.max(1, tonumber(topCount) or 10)
	for i = 1, math.min(limit, #entries) do
		result[i] = entries[i]
	end
	return result
end

return LeaderboardService
