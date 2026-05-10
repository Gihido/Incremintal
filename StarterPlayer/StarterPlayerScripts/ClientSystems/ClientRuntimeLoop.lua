local ClientRuntimeLoop = {}

local leaderboardBoards = {"Coins", "Wood", "Paper", "Hay", "XP"}

function ClientRuntimeLoop.StartLeaderboardPolling(context)
	if context._leaderboardPollStarted then
		return
	end
	context._leaderboardPollStarted = true

	task.spawn(function()
		while true do
			for _, boardName in ipairs(leaderboardBoards) do
				context.leaderboardRemote:FireServer(boardName, 5)
			end
			task.wait(2.5)
		end
	end)
end

return ClientRuntimeLoop
