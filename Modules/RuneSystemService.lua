local RuneSystemService = {}

local DEFAULT_STATE = {
	luck = 1,
	speed = 1,
	bulk = 1,
	sessions = 0,
	totalRolls = 0,
	runeStats = {},
}

local function copyState()
	local state = {}
	for key, value in pairs(DEFAULT_STATE) do
		if type(value) == "table" then
			state[key] = {}
		else
			state[key] = value
		end
	end
	return state
end

function RuneSystemService:GetState(player)
	if not player then return copyState() end
	self._playerState = self._playerState or {}
	if not self._playerState[player] then
		self._playerState[player] = copyState()
	end
	return self._playerState[player]
end

function RuneSystemService:GetLuck(player)
	return self:GetState(player).luck
end

function RuneSystemService:GetSpeed(player)
	return self:GetState(player).speed
end

function RuneSystemService:GetBulk(player)
	return self:GetState(player).bulk
end

function RuneSystemService:RecordRuneRoll(player, runeName, count)
	local state = self:GetState(player)
	local amount = math.max(1, tonumber(count) or 1)
	state.totalRolls += amount
	state.runeStats[runeName] = (state.runeStats[runeName] or 0) + amount
end

function RuneSystemService:BeginSession(player)
	local state = self:GetState(player)
	state.sessions += 1
	return state.sessions
end

function RuneSystemService:GetRuneStats(player)
	return self:GetState(player).runeStats
end

function RuneSystemService:UpdateRuneBoard(player)
	local state = self:GetState(player)
	return {
		luck = state.luck,
		speed = state.speed,
		bulk = state.bulk,
		totalRolls = state.totalRolls,
		sessions = state.sessions,
	}
end

return RuneSystemService
