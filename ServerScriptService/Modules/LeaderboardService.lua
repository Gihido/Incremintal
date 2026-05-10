local ServerScriptService = game:GetService("ServerScriptService")
local Systems = ServerScriptService:WaitForChild("Systems")
local LeaderboardSystem = require(Systems:WaitForChild("LeaderboardSystem"))

local LeaderboardService = {}

function LeaderboardService:FormatValue(value)
	local n = tonumber(value) or 0
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(math.floor(n + 0.5))
end

function LeaderboardService:BuildLeaderboardEntries(players, valueGetter, formatter)
	local formatValue = formatter or function(value)
		return self:FormatValue(value)
	end
	return LeaderboardSystem:BuildLeaderboardEntries(players, valueGetter, formatValue)
end

function LeaderboardService:BuildEntries(players, valueGetter, formatter)
	return self:BuildLeaderboardEntries(players, valueGetter, formatter)
end

function LeaderboardService:GetTopPlayers(playersOrEntries, topCount, valueGetter, formatter)
	local source = playersOrEntries or {}
	local first = source[1]
	local entries = source
	if first and first.player == nil then
		entries = self:BuildEntries(source, valueGetter, formatter)
	end
	return LeaderboardSystem:GetTopPlayers(entries, topCount or 10)
end

return LeaderboardService
