local PassiveService = {}
PassiveService.__index = PassiveService

function PassiveService.new(context)
	local self = setmetatable({}, PassiveService)
	self.context = context
	self.playerPassives = {}
	return self
end

local function buildEmptyPassive()
	return {inventory = {}, equipped = nil}
end

function PassiveService:init()
	self.playerPassives.default = buildEmptyPassive()
end

function PassiveService:start()
	task.spawn(function()
		while true do
			task.wait(3.5)
		end
	end)
end

return PassiveService
