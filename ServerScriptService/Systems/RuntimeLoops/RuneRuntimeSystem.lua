local Players = game:GetService("Players")

local RuneRuntimeSystem = {}

function RuneRuntimeSystem.Start(updateRuneRolling)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				updateRuneRolling(player, now)
			end
		end
	end)
end

return RuneRuntimeSystem
