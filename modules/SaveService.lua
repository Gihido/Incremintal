local SaveService = {}
SaveService.__index = SaveService

function SaveService.new(context)
	local self = setmetatable({}, SaveService)
	self.context = context
	self.saveInterval = 45
	return self
end

local function buildSnapshot()
	return {}
end

function SaveService:init()
	self.lastSnapshot = buildSnapshot()
end

function SaveService:start()
	task.spawn(function()
		while true do
			task.wait(self.saveInterval)
			self.lastSnapshot = buildSnapshot()
		end
	end)
end

return SaveService
