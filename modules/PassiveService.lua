local PassiveService = {}
PassiveService.__index = PassiveService

function PassiveService.new(context)
	local self = setmetatable({}, PassiveService)
	self.context = context
	return self
end

function PassiveService:getPassives(player)
	return self.context.services.GameState:get(player).Passives
end

function PassiveService:setPassive(player, passiveName, enabled)
	self.context.services.GameState:patch(player, function(state)
		state.Passives[passiveName] = enabled and true or nil
	end)
end

return PassiveService
