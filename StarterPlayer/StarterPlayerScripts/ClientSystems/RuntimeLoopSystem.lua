local RuntimeLoopSystem = {}

local LEADERBOARD_BOARDS = {"Coins", "Wood", "Paper", "Hay", "XP"}
local REFRESH_INTERVAL = 0.35
local LEADERBOARD_INTERVAL = 2.5

function RuntimeLoopSystem.Start(context)
	if context._runtimeLoopStarted then
		return
	end
	context._runtimeLoopStarted = true

	task.spawn(function()
		while true do
			for _, callback in ipairs(context._refreshCallbacks or {}) do
				callback()
			end
			task.wait(REFRESH_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			for _, boardName in ipairs(LEADERBOARD_BOARDS) do
				context.leaderboardRemote:FireServer(boardName, 5)
			end
			task.wait(LEADERBOARD_INTERVAL)
		end
	end)
end

function RuntimeLoopSystem.StartLeaderboardPolling(context)
	RuntimeLoopSystem.Start(context)
end

return RuntimeLoopSystem
