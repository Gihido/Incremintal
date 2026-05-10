local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientContext = {}

local function waitForRemote(remotesFolder, remoteName)
	return remotesFolder:WaitForChild(remoteName)
end

function ClientContext.Create()
	local player = Players.LocalPlayer
	local remotesFolder = ReplicatedStorage:WaitForChild("IncrementalRemotes")
	local data = player:WaitForChild("PlayerData", 30)
	if not data then
		warn("PlayerData was not created within 30 seconds for " .. player.Name)
	end

	return {
		player = player,
		playerGui = player:WaitForChild("PlayerGui"),
		data = data,
		remotesFolder = remotesFolder,
		notifyRemote = waitForRemote(remotesFolder, "Notify"),
		leaderboardRemote = waitForRemote(remotesFolder, "LeaderboardRequest"),
		adminRemote = waitForRemote(remotesFolder, "AdminAction"),
		purchaseUpgradeRemote = waitForRemote(remotesFolder, "PurchaseUpgrade"),
		purchaseRebirthRemote = waitForRemote(remotesFolder, "PurchaseRebirth"),
		factoryRemote = waitForRemote(remotesFolder, "FactoryAction"),
		passiveRemote = waitForRemote(remotesFolder, "PassiveAction"),
		runeRemote = waitForRemote(remotesFolder, "RuneAction"),
		xpRemote = waitForRemote(remotesFolder, "XPAction"),
		_refreshCallbacks = {},
	}
end

function ClientContext.AddRefresh(context, callback)
	if type(callback) ~= "function" then
		return
	end
	context._refreshCallbacks = context._refreshCallbacks or {}
	context._refreshCallbacks[#context._refreshCallbacks + 1] = callback
end

return ClientContext
