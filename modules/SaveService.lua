local Players = game:GetService("Players")

local SaveService = {}
SaveService.__index = SaveService

function SaveService.new(context)
	local self = setmetatable({}, SaveService)
	self.context = context
	self.saveInterval = 45
	self.lastSnapshot = {}
	return self
end

function SaveService:buildSnapshot()
	local snapshot = {}
	for _, player in ipairs(Players:GetPlayers()) do
		snapshot[player.UserId] = self.context.services.GameState:get(player)
	end
	return snapshot
end

function SaveService:start()
	task.spawn(function()
		while true do
			task.wait(self.saveInterval)
			self.lastSnapshot = self:buildSnapshot()
		end
	end)
end

return SaveService
