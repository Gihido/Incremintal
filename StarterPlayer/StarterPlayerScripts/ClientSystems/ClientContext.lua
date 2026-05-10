local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientContext = {}

local REMOTE_WAIT_TIMEOUT = 15

local function waitForRequiredChild(parent, childName, timeoutSeconds)
	local child = parent:WaitForChild(childName, timeoutSeconds or REMOTE_WAIT_TIMEOUT)
	if not child then
		error(childName .. " was not created under " .. parent:GetFullName() .. " within " .. tostring(timeoutSeconds or REMOTE_WAIT_TIMEOUT) .. " seconds")
	end
	return child
end

local function waitForRemote(remotesFolder, remoteName)
	return waitForRequiredChild(remotesFolder, remoteName, REMOTE_WAIT_TIMEOUT)
end

function ClientContext.Create()
	local player = Players.LocalPlayer
	local remotesFolder = waitForRequiredChild(ReplicatedStorage, "IncrementalRemotes", REMOTE_WAIT_TIMEOUT)
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
