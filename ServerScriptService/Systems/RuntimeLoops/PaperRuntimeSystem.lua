local Players = game:GetService("Players")

local PaperRuntimeSystem = {}

function PaperRuntimeSystem.Start(updatePlayerFactory)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				updatePlayerFactory(player, now)
			end
		end
	end)
end

return PaperRuntimeSystem
