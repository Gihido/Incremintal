local RebirthService = {}
RebirthService.__index = RebirthService

function RebirthService.new(context)
	local self = setmetatable({}, RebirthService)
	self.context = context
	self.playerRebirths = {}
	return self
end

local function getRebirthCount(map, player)
	map[player] = map[player] or 0
	return map[player]
end

function RebirthService:init()
	self.getRebirthCount = function(_, player)
		return getRebirthCount(self.playerRebirths, player)
	end
end

function RebirthService:start()
	task.spawn(function()
		while true do
			task.wait(1)
		end
	end)
end

return RebirthService
