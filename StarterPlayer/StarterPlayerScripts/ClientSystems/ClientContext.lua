local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientContext = {}

function ClientContext.Create()
	local player = Players.LocalPlayer
	local remotesFolder = ReplicatedStorage:FindFirstChild("IncrementalRemotes")
		or ReplicatedStorage:FindFirstChild("Remotes")
		or ReplicatedStorage:WaitForChild("IncrementalRemotes")
	return {
		player = player,
		playerGui = player:WaitForChild("PlayerGui"),
		remotesFolder = remotesFolder,
		notifyRemote = remotesFolder:WaitForChild("Notify"),
		leaderboardRemote = remotesFolder:WaitForChild("LeaderboardRequest"),
		adminRemote = remotesFolder:WaitForChild("AdminAction"),
	}
end

return ClientContext
