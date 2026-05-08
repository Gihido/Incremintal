local RuneService = {}
RuneService.__index = RuneService

function RuneService.new(context)
	local self = setmetatable({}, RuneService)
	self.context = context
	self.rollStates = {}
	return self
end

local function stopRoll(state)
	state.rolling = false
end

function RuneService:init()
	self.rollStates.default = {rolling = false}
end

function RuneService:start()
	task.spawn(function()
		while true do
			task.wait(0.25)
			local state = self.rollStates.default
			if state and not state.rolling then
				stopRoll(state)
			end
		end
	end)
end

return RuneService
