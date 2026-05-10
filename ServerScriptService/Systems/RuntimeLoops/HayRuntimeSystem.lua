local Players = game:GetService("Players")

local HayRuntimeSystem = {}

function HayRuntimeSystem.Start(updateHayCollection)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				updateHayCollection(player, now)
			end
		end
	end)
end

return HayRuntimeSystem
