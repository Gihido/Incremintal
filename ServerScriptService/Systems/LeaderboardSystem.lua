local LeaderboardSystem = {}

local function defaultFormatter(value)
	return tostring(value)
end

local function defaultValueGetter()
	return 0
end

local function normalizeValue(value)
	return tonumber(value) or 0
end

local function sortEntries(entries)
	table.sort(entries, function(a, b)
		if a.value == b.value then
			return tostring(a.player and a.player.Name or "") < tostring(b.player and b.player.Name or "")
		end
		return a.value > b.value
	end)
end

function LeaderboardSystem:BuildLeaderboardEntries(players, valueGetter, formatter)
	local getValue = valueGetter or defaultValueGetter
	local formatValue = formatter or defaultFormatter
	local entries = {}

	for _, player in ipairs(players or {}) do
		local value = normalizeValue(getValue(player))
		entries[#entries + 1] = {
			player = player,
			value = value,
		}
	end

	sortEntries(entries)

	for index, entry in ipairs(entries) do
		entry.rank = index
		entry.formattedValue = formatValue(entry.value)
	end

	return entries
end

function LeaderboardSystem:BuildEntries(players, valueGetter, formatter)
	return self:BuildLeaderboardEntries(players, valueGetter, formatter)
end

function LeaderboardSystem:GetTopPlayers(entries, topCount)
	local result = {}
	local sourceEntries = entries or {}
	local limit = math.max(1, tonumber(topCount) or 10)

	for i = 1, math.min(limit, #sourceEntries) do
		result[i] = sourceEntries[i]
	end

	return result
end

return LeaderboardSystem
