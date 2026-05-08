local UpgradeService = {}
UpgradeService.__index = UpgradeService

function UpgradeService.new(context)
	local self = setmetatable({}, UpgradeService)
	self.context = context
	return self
end

function UpgradeService:setUnlock(player, unlockKey, unlocked)
	self.context.services.GameState:patch(player, function(state)
		state.Unlocks[unlockKey] = unlocked and true or nil
	end)
end

function UpgradeService:setMultiplier(player, key, value)
	self.context.services.GameState:patch(player, function(state)
		state.Multipliers[key] = tonumber(value) or 1
	end)
end

return UpgradeService
