local Players = game:GetService("Players")

local RuneService = {}
RuneService.__index = RuneService

function RuneService.new(context)
	local self = setmetatable({}, RuneService)
	self.context = context
	return self
end

function RuneService:syncPlayerRunes(player)
	local state = self.context.services.GameState:get(player)
	local data = player:FindFirstChild("PlayerData")
	if not data then return end
	local upgrades = data:FindFirstChild("RuneUpgrades")
	if not upgrades then return end
	if upgrades:FindFirstChild("RuneLuckLevel") then upgrades.RuneLuckLevel.Value = state.RuneLuck or 0 end
	if upgrades:FindFirstChild("RuneBulkLevel") then upgrades.RuneBulkLevel.Value = state.RuneBulk or 0 end
	if upgrades:FindFirstChild("RuneSpeedLevel") then upgrades.RuneSpeedLevel.Value = state.RuneSpeed or 0 end
end

function RuneService:init()
	Players.PlayerAdded:Connect(function(player)
		self.context.services.GameState:onChanged(player, function()
			self:syncPlayerRunes(player)
		end)
		self:syncPlayerRunes(player)
	end)
end

return RuneService
