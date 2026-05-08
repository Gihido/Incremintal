local RebirthService = {}
RebirthService.__index = RebirthService

function RebirthService.new(context)
	local self = setmetatable({}, RebirthService)
	self.context = context
	return self
end

function RebirthService:getRebirthCount(player)
	return self.context.services.GameState:get(player).Rebirths or 0
end

function RebirthService:addRebirth(player, amount)
	self.context.services.GameState:patch(player, function(state)
		state.Rebirths = math.max(0, (state.Rebirths or 0) + (tonumber(amount) or 1))
	end)
end

return RebirthService
