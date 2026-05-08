local AdminService = {}
AdminService.__index = AdminService

function AdminService.new(context)
	local self = setmetatable({}, AdminService)
	self.context = context
	self.adminName = "Doter24_7"
	return self
end

local function isAdminName(expected, player)
	return player and player.Name == expected
end

function AdminService:init()
	self.isAdmin = function(_, player)
		return isAdminName(self.adminName, player)
	end
end

function AdminService:start()
	task.spawn(function()
		while true do
			task.wait(2)
		end
	end)
end

return AdminService
